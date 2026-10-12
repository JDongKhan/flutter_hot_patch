import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

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

// ===========================================================================
// 建模层：Dart 类 → ClassInfo（含依赖发现）
//
// 组件（@UIComponent widget）与普通类（模型 / 状态类 / 静态单例）都是 Dart 类，
// 走**同一处**建模：字段、方法、构造参数，以及**依赖发现**（本类引用到的其它
// 类名）都在这里求出来挂在 ClassInfo.dependencies 上。builder 不再关心「依赖
// 怎么算」，只按名字递归翻译 / 决定同文件内联还是跨文件 import。
// ===========================================================================

/// 提取 ClassDeclaration → ClassInfo（统一入口）。
///
/// getter/setter 只保留 getter；static 方法不翻译（Dart static 方法无 JS
/// 等价物，通常业务不用）；构造收集 this.x 形参名。
/// [dependencies]：本类引用到的其它类名（由 [referencedClassNames] 与类表求交）。
/// [isComponent]：该类是 widget/组件类（@UIComponent 或 Stateful/Stateless/
/// State 子类）——类表据此把它与普通模型类区分开（组件不作为模型内联、组件
/// 类型字段不当模型构造翻译）。
ClassInfo classInfoOf(
  ClassDeclaration decl,
  String sourceFile, {
  Set<String> dependencies = const {},
  bool isComponent = false,
}) {
  final instanceFields = <ClassField>[];
  final staticFields = <ClassField>[];
  final methods = <ClassMethod>[];
  final ctorParams = <String>{};

  // 构造器 this.x 形参（DefaultFormalParameter 解包）
  for (final m in decl.members) {
    if (m is ConstructorDeclaration) {
      for (final p in m.parameters.parameters) {
        final inner = p is DefaultFormalParameter ? p.parameter : p;
        if (inner is FieldFormalParameter) ctorParams.add(inner.name.lexeme);
      }
    }
  }

  for (final m in decl.members) {
    if (m is FieldDeclaration) {
      final typeName = m.fields.type?.toSource() ?? 'dynamic';
      for (final v in m.fields.variables) {
        final f = ClassField(
          name: v.name.lexeme,
          typeName: typeName,
          initializer: v.initializer,
          isStatic: m.isStatic,
        );
        if (m.isStatic) {
          staticFields.add(f);
        } else {
          instanceFields.add(f);
        }
      }
    } else if (m is MethodDeclaration) {
      if (m.isGetter) {
        methods.add(ClassMethod(
          name: m.name.lexeme,
          params: const [],
          isGetter: true,
          body: m.body,
        ));
      } else if (m.isSetter || m.isStatic) {
        // static 方法 / setter：暂不翻译
      } else {
        methods.add(ClassMethod(
          name: m.name.lexeme,
          params: jsMethodParams(m),
          isAsync: m.body.isAsynchronous,
          isVoid: isVoidReturn(m),
          returnsWidget: returnsWidgetOf(m),
          body: m.body,
        ));
      }
    }
  }

  String? superType;
  final ext = decl.extendsClause;
  if (ext != null) superType = ext.superclass.toSource();

  return ClassInfo(
    name: decl.name.lexeme,
    sourceFile: sourceFile,
    superType: superType,
    instanceFields: instanceFields,
    staticFields: staticFields,
    methods: methods,
    ctorParams: ctorParams,
    isComponent: isComponent,
    dependencies: dependencies,
  );
}

/// 字段类型：优先显式类型注解；无注解时从初始化器推断
/// （`final _model = MyModel();` 在无 resolution 解析下 type 为 null，
/// 会退化成 dynamic 被当基础类型，需从构造名推回 MyModel）。
String fieldTypeName(FieldDeclaration member, VariableDeclaration variable) {
  final t = member.fields.type?.toSource();
  if (t != null && t.isNotEmpty) return t;
  final init = variable.initializer;
  if (init is InstanceCreationExpression) {
    return init.constructorName.type.name2.lexeme;
  }
  if (init is MethodInvocation &&
      init.target == null &&
      init.typeArguments == null) {
    final n = init.methodName.name;
    if (n.isNotEmpty && n[0] == n[0].toUpperCase()) return n;
  }
  return 'dynamic';
}

/// 一个类引用到的其它类名：**实例字段类型** + **方法体内构造调用** 的并集。
///
/// 依赖发现是「类 → ClassInfo」这一层的产物：组件与普通类共用同一处，builder
/// 只按名字递归翻译依赖组件、并按 ClassInfo.sourceFile 决定同文件内联还是跨
/// 文件 import。基础类型与 widget 构造名由调用方与类表求交后自然丢弃
/// （类表里只有真正的 Dart 类）。
///
/// [methods]：限定扫描的方法集（组件路径传过滤后的可翻译方法）；缺省扫描全部。
Set<String> referencedClassNames(
  ClassDeclaration decl, {
  List<MethodDeclaration>? methods,
}) {
  final names = <String>{};
  final collector = _CtorNameCollector();
  for (final m in methods ?? decl.members.whereType<MethodDeclaration>()) {
    m.body.accept(collector);
  }
  names.addAll(collector.names);
  for (final member in decl.members.whereType<FieldDeclaration>()) {
    if (member.isStatic) continue;
    for (final v in member.fields.variables) {
      final t = eraseType(fieldTypeName(member, v));
      if (!isBasicType(t) && t.isNotEmpty) names.add(t);
    }
  }
  return names;
}

/// 收集表达式树里全部类型构造调用名（与类发现共用：字段类型 + 构造调用）。
class _CtorNameCollector extends RecursiveAstVisitor<void> {
  final names = <String>{};

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    names.add(node.constructorName.type.name2.lexeme);
    super.visitInstanceCreationExpression(node);
  }

  /// 无 `new`/`const` 的构造调用（parseString 下是 MethodInvocation）：
  /// `MyModel()` / `(_) => MyModel()` 里的模型构造。仅收 UpperCamel 且无
  /// target/泛型的形态（与 [fieldTypeName] 同启发式），widget 构造（Text/Column
  /// 等）也会被收进来，但与类表求交后自然丢弃。
  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target == null && node.typeArguments == null) {
      final n = node.methodName.name;
      if (n.isNotEmpty && n[0] == n[0].toUpperCase()) names.add(n);
    }
    super.visitMethodInvocation(node);
  }
}

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
/// 并数据驱动地追加响应式 builder 子方法（[ClassInfo.builders] 非空）。
///
/// 组件与普通类共用这一条渲染路径——方法体翻译**只有这一处**：所有方法
/// （含 build）都交给 [translateClassMethodBody]，`return Text(...)` 这类返回
/// widget 的表达式统一走 widget 层渲染，不存在「是不是 build」的判断。
/// **没有对外工厂函数**：元素的 type 就是类本身（宿主 widget 则是类型名字符串），
/// 由渲染层统一写成 `__h(type, props, children)`。
///
/// [widgetCtx]：方法体里返回 Widget 的表达式（如 `return Container(...)`）与
/// builder 子方法的渲染上下文。只需满足 [WidgetExprRenderer]（widget2js 的
/// WidgetTranslateContext 实现它），因此本文件不依赖 widget2js。
String renderClassDecl(
  ClassInfo info,
  Map<String, ClassInfo> classes, {
  bool exported = false,
  WidgetExprRenderer? widgetCtx,
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
      // 方法体多行可读：语句各自成行、按方法体深度缩进（翻译器已带缩进），
      // 大括号独占行。
      final body = (m.bodyJs ??
              translateClassMethodBody(info, m, classes,
                  hostMethods: info.hostMethods, widgetCtx: widgetCtx))
          .trimRight();
      b.write('  $fn${m.name}(${m.params.join(', ')}) {\n');
      if (body.isNotEmpty) b.write('$body\n');
      b.write('  }\n');
    }
  }

  // 响应式 builder 闭包子方法（ListenableBuilder/Consumer）→ 实例方法
  // `_lbBuilderN()` / `_consumerBuilderN(value)`。运行时时模型 notify 后
  // 重新调用本方法拿到最新子树（含已求值的 this._model.n / value.count），
  // 做「仅此节点」的局部重建。方法名与形参由 translator 在翻译期声明。
  if (info.builders.isNotEmpty && widgetCtx != null) {
    for (var i = 0; i < info.builders.length; i++) {
      final name =
          i < info.builderNames.length ? info.builderNames[i] : '_lbBuilder$i';
      final param = i < info.builderParams.length ? info.builderParams[i] : null;
      final prelude =
          i < info.builderPreludes.length ? info.builderPreludes[i] : '';
      b.write('  $name(${param ?? ''}) {\n');
      if (prelude.isNotEmpty) b.write('      $prelude\n');
      b.write('      return ${widgetCtx.renderJs(info.builders[i], 2)};\n');
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
/// 驱动（类名、方法体、builder 子方法、字段的 JS 初值）。
///
/// 因此新增一种「类结构能力」只需改这一处，组件与普通类同时生效。表达式/语句/
/// 字面量语法见 [js_translator]，widget 相关见 [widget2js]。
///
/// 参数：
///   - [exported]：类声明是否 `export`。
///   - [classes]：方法体内构造调用（`new X({...})`）用的类表。
///   - [widgetCtx]：类方法体里 `return Container(...)` 与 builder 子方法的
///     widget 翻译上下文。
///   - [singletonValueRenderer]：纯 static 类的字段值渲染器（颜色/字面量求值）。
///
/// `@HostInjected` 通道表不在参数里：它随 [ClassInfo.hostMethods] 一起由
/// [translateClass] 在翻译期算好挂在模型上（组件与普通类同一份数据）。
/// ===========================================================================
String dart2js(
  ClassInfo info, {
  bool exported = false,
  Map<String, ClassInfo> classes = const {},
  WidgetExprRenderer? widgetCtx,
  String Function(ClassField field)? singletonValueRenderer,
}) {
  if (info.isStaticOnly && singletonValueRenderer != null) {
    return renderStaticConst(info,
        valueRenderer: singletonValueRenderer, exported: exported);
  }
  return renderClassDecl(info, classes,
      exported: exported,
      widgetCtx: widgetCtx);
}

