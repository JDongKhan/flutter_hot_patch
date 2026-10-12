import 'package:analyzer/dart/ast/ast.dart';

import 'js_translator.dart';

// ===========================================================================
// 统一「Dart 类 → JS 类」转换处理器
//
// 不按用途分流：任何普通 Dart 类（value object 如 User、ChangeNotifier 状态
// 对象如 MyModel、静态单例如 MyColors）都按同一套「如何声明 +
// 如何被 State 字段 / 构建 / 方法引用」处理。
//
//   - 实例字段    → constructor 里 this.x（this.x 形参取值 / 字段初始化器）
//   - static 字段 → JS 属性（纯 static 类渲染成 const 对象）
//   - 实例方法    → class 方法；getter → get 访问器
//   - extends ChangeNotifier → extends ChangeNotifier（运行时注入同名 JS 基类）
//
// 表达式/语句翻译统一以 [FieldScope] 为键：组件动作（字段=State 属性表）与
// 模型方法（字段=模型自身实例字段）走同一套 translator。
// ===========================================================================

/// getter 表达式体 → JS 返回值表达式（`int get n => _n` → `this._n`）。
String? _getterReturnJs(ClassInfo info, ClassMethod m) {
  Expression? e;
  final body = m.body;
  if (body is ExpressionFunctionBody) {
    e = body.expression;
  } else if (body is BlockFunctionBody) {
    for (final s in body.block.statements) {
      if (s is ReturnStatement) {
        e = s.expression;
        break;
      }
    }
  }
  if (e == null) return 'null';
  final scope = FieldScope(instanceFields: info.instanceFieldNames);
  return exprToJs(e, scope, const {}) ?? 'null';
}

/// 类声明 → JS（export 可选）。含 constructor / 方法 / getter / extends 基类，
/// 并数据驱动地追加 build()/builder 子方法（[ClassInfo.tree] 非空）。
/// 普通类与组件共用这一条渲染路径——**没有对外工厂函数**：元素的 type 就是
/// 类本身（宿主 widget 则是类型名字符串），由渲染层统一写成
/// `__h(type, props, children)`，JS 侧不存在「factory」这层包装。
///
/// [widgetCtx]：可选。传入后，方法体里返回 Widget 构造表达式
/// （如 `return Container(...)`）会走 widget 树翻译路径，而不是被当作普通
/// 方法调用丢弃（model 类里的 `getWidget()` 方法也能用）。
/// [treeCtx]：可选。[ClassInfo.tree] 非空（组件）时渲染 build/builders 必需。
/// 两者都只需满足 [WidgetExprRenderer]（widget2js 的 WidgetTranslateContext
/// 实现它），因此本文件不依赖 widget2js。
String renderClassDecl(
  ClassInfo info,
  Map<String, ClassInfo> classes, {
  bool exported = false,
  Map<String, Map<String, String>> hostMethods = const {},
  WidgetExprRenderer? widgetCtx,
  WidgetExprRenderer? treeCtx,
}) {
  final b = StringBuffer();
  b.write(exported ? 'export class ' : 'class ');
  b.write(info.name);
  final base = sdkBaseName(info);
  if (base != null) b.write(' extends $base');
  b.write(' {\n');

  // constructor：有无 this.x 构造形参决定形态（组件与普通类同一规则）：
  // 无参 → `constructor()`（JS 侧多传实参无害）；有参 → `constructor(args)`
  // 并逐字段按 `args.x ?? 默认值` 取值。
  b.write(info.ctorParams.isEmpty ? '  constructor() {\n' : '  constructor(args) {\n');
  if (base != null) b.write('    super();\n');
  for (final f in info.instanceFields) {
    final def = f.jsInitial ??
        (f.initializer != null
            ? (literalToJs(f.initializer) ?? 'undefined')
            : 'undefined');
    if (info.ctorParams.contains(f.name)) {
      b.write(
        '    this.${f.name} = (args && args.${f.name} !== undefined) '
        '? args.${f.name} : $def;\n',
      );
    } else {
      b.write('    this.${f.name} = $def;\n');
    }
  }
  b.write('  }\n');

  // 方法 + getter
  for (final m in info.methods) {
    if (m.isGetter) {
      b.write('  get ${m.name}() { return ${_getterReturnJs(info, m)}; }\n');
    } else {
      final fn = m.isAsync ? 'async ' : '';
      final body = m.bodyJs ??
          translateClassMethodBody(info, m, classes,
              hostMethods: hostMethods, widgetCtx: widgetCtx);
      b.write('  $fn${m.name}(${m.params.join(', ')}) { $body }\n');
    }
  }

  // build()：tree 非空即渲染（数据驱动，组件与普通类同一逻辑）。
  if (info.tree != null) {
    final ctx = treeCtx!;
    b.write('  build() {\n');
    for (final d in info.localDecls) {
      b.write('$d\n');
    }
    b.write('    return ${ctx.renderJs(info.tree, 2)};\n');
    b.write('  }\n');
    // 响应式 builder 闭包子树（ListenableBuilder/Consumer）→ 实例方法
    // `_lbBuilderN()` / `_consumerBuilderN(value)`。运行时时模型 notify 后
    // 重新调用本方法拿到最新子树（含已求值的 this._model.n / value.count），
    // 做「仅此节点」的局部重建。方法名与形参由 translator 声明。
    for (var i = 0; i < info.builders.length; i++) {
      final name =
          i < info.builderNames.length ? info.builderNames[i] : '_lbBuilder$i';
      final param = i < info.builderParams.length ? info.builderParams[i] : null;
      final prelude =
          i < info.builderPreludes.length ? info.builderPreludes[i] : '';
      b.write('  $name(${param ?? ''}) {\n');
      if (prelude.isNotEmpty) b.write('      $prelude\n');
      b.write('      return ${ctx.renderJs(info.builders[i], 2)};\n');
      b.write('  }\n');
    }
  }

  b.write('}');
  return b.toString();
}

/// 纯 static 类 → JS const 对象：`const MyColors = { a: v, b: v };`。
/// [valueRenderer] 由调用方提供（颜色/字符串/字面量统一求值）。
String renderStaticConst(
  ClassInfo info, {
  required String Function(ClassField field) valueRenderer,
  bool exported = false,
}) {
  final prefix = exported ? 'export const ' : 'const ';
  final entries =
      info.staticFields.map((f) => '  ${f.name}: ${valueRenderer(f)}').join(',\n');
  return '$prefix${info.name} = {\n$entries\n};';
}

/// ===========================================================================
/// 统一入口：Dart 类 → JS 源码。
///
/// 只有这一处决定「类 → JS」的渲染：普通类（模型/状态类/静态单例）与组件
/// （@UIComponent widget，widget 与 state 已在建模期合并为同一 [ClassInfo]）
/// 全部走这里，没有任何按用途分叉的模式开关——所有差异都由 [ClassInfo] 数据
/// 驱动（类名、build 树、builder 子方法、字段/方法的预渲染值）。
///
/// 因此新增一种「类结构能力」（如 build、getter、注解 …）只需改这一处，
/// 组件与普通类同时生效。表达式/语句/字面量语法见 [js_translator]，
/// widget 相关见 [widget2js]。
///
/// 参数：
///   - [exported]：类声明是否 `export`。
///   - [classes]：方法体内构造调用（`new X({...})`）用的类表。
///   - [hostMethods]：@HostInjected 方法表。
///   - [widgetCtx]：类方法体里 `return Container(...)` 走的 widget 翻译上下文。
///   - [treeCtx]：[ClassInfo.tree] 非空（组件）时渲染 build/builders 必需。
///   - [singletonValueRenderer]：纯 static 类的字段值渲染器（颜色/字面量求值）。
/// ===========================================================================
String dart2js(
  ClassInfo info, {
  bool exported = false,
  Map<String, ClassInfo> classes = const {},
  Map<String, Map<String, String>> hostMethods = const {},
  WidgetExprRenderer? widgetCtx,
  WidgetExprRenderer? treeCtx,
  String Function(ClassField field)? singletonValueRenderer,
}) {
  if (info.isStaticOnly && singletonValueRenderer != null) {
    return renderStaticConst(info,
        valueRenderer: singletonValueRenderer, exported: exported);
  }
  return renderClassDecl(info, classes,
      exported: exported,
      hostMethods: hostMethods,
      widgetCtx: widgetCtx,
      treeCtx: treeCtx);
}

