/// 渲染层：ClassInfo → JS 类声明字符串。
///
/// 只做字符串拼装：不遍历 AST、不做表达式翻译、不收集依赖。字段初值、方法体、
/// getter、builder 子树都已由 analyze_dart_class 预渲染进 [ClassInfo]。
library;

import 'package:build/build.dart' show log;

import 'class_info.dart';
import 'js_value.dart';

/// 类声明 → JS（export 可选）。含 constructor / 方法 / getter / extends 基类，
/// 并数据驱动地追加响应式 builder 子方法（[ClassInfo.builderBodies] 非空）。
///
/// 组件与普通类共用这一条渲染路径。方法体、getter、builder 子树都已由
/// analyze_dart_class 预渲染成 JS 字符串——本函数只负责拼装，不再遍历 AST。
/// **没有对外工厂函数**：元素的 type 就是类本身（宿主 widget 则是类型名字符串），
/// 由渲染层统一写成 `__h(type, props, children)`。
String renderClassDecl(
  ClassInfo info, {
  bool exported = false,
}) {
  final b = StringBuffer();
  b.write(exported ? 'export class ' : 'class ');
  b.write(info.name);
  final base = sdkBaseName(info);
  if (base != null) b.write(' extends $base');
  b.write(' {\n');

  // constructor：有无 this.x 构造形参决定形态（组件与普通类同一规则）：
  // 无参 → `constructor()`（JS 侧多传实参无害）；有参 → `constructor(args)`，
  // 构造参数**统一经 `__applyProps(args)` 派生**（构造参数 → 实例字段只有这一处
  // 映射，构造函数首行调用）。
  //
  // 为什么单独成方法：运行时 patch 复用组件实例时（props 变了）**不会重跑构造
  // 函数**，只更新实例的 `this.props`；参数↔字段映射若只写在构造函数里，子组件
  // 就会永远拿着旧 props 派生的字段（表现为「切换排序/筛选后列表内容不更新」）。
  // 运行时在 patch 的复用路径上会再调一次 `__applyProps(el.props)` 同步字段
  // （见 mini_react_js 的 patch）。
  //
  // 参数先于其它字段派生：Dart 里 `this.x` 形参在构造体开头即已可用，状态字段
  // 可能依赖它（如 `_status = widget.initialStatus ?? kOrderStatus.first`）。
  b.write(info.ctorParams.isEmpty ? '  constructor() {\n' : '  constructor(args) {\n');
  if (base != null) b.write('    super();\n');
  if (info.ctorParams.isNotEmpty) b.write('    this.__applyProps(args);\n');
  // mixin 来源的字段集中尾部、按来源注释分隔（类自身字段在前，注释只标
  // mixin 段），定位问题时一眼分清「类自己的状态 / 混入的状态」。
  String? lastFieldOrigin;
  for (final f in info.instanceFields) {
    if (info.ctorParams.contains(f.name)) continue;
    if (f.mixinOrigin != lastFieldOrigin) {
      if (f.mixinOrigin != null) {
        b.write('    // ---- mixin ${f.mixinOrigin} ----\n');
      }
      lastFieldOrigin = f.mixinOrigin;
    }
    b.write('    this.${f.name} = ${_fieldDefaultJs(f)};\n');
  }
  b.write('  }\n');

  // 构造参数 → 实例字段的唯一映射：构造函数首行调用；实例被 patch 复用
  // （props 变更）时由运行时再调一次 `__applyProps`，保证字段与最新 props 同步。
  if (info.ctorParams.isNotEmpty) {
    b.write('  __applyProps(args) {\n');
    for (final f in info.instanceFields) {
      if (!info.ctorParams.contains(f.name)) continue;
      b.write(
        '    this.${f.name} = (args && args.${f.name} !== undefined) '
        '? args.${f.name} : ${_fieldDefaultJs(f)};\n',
      );
    }
    b.write('  }\n');
  }

  // 方法 + getter：方法体（含 getter、builder）已在收集阶段预渲染为 [bodyJs]，
  // 这里只拼装。缺失说明收集层漏译，出声告警而不是静默产出空方法体。
  // mixin 来源的方法集中尾部（classInfoOf 合并时已排好序）、按来源注释分隔。
  String? lastMethodOrigin;
  for (final m in info.methods) {
    if (m.mixinOrigin != lastMethodOrigin) {
      if (m.mixinOrigin != null) {
        b.write('  // ---- mixin ${m.mixinOrigin} ----\n');
      }
      lastMethodOrigin = m.mixinOrigin;
    }
    final fn = m.isAsync ? 'async ' : '';
    // 方法体多行可读：语句各自成行、按方法体深度缩进（翻译器已带缩进），
    // 大括号独占行。
    final raw = m.bodyJs;
    if (raw == null) {
      log.warning(
        '[hot_patch_generator] ${info.name}.${m.name} 缺少预渲染方法体'
        '（收集阶段应产出 bodyJs），已渲染为空方法体。',
      );
    }
    final body = (raw ?? '').trimRight();
    if (m.isGetter) {
      b.write('  get ${m.name}() {\n');
      if (body.isNotEmpty) b.write('$body\n');
      b.write('  }\n');
    } else {
      b.write('  $fn${m.name}(${m.params.join(', ')}) {\n');
      if (body.isNotEmpty) b.write('$body\n');
      b.write('  }\n');
    }
  }

  // 响应式 builder 闭包子方法（ListenableBuilder/Consumer）→ 实例方法
  // `_lbBuilderN()` / `_consumerBuilderN(value)`。运行时时模型 notify 后
  // 重新调用本方法拿到最新子树（含已求值的 this._model.n / value.count），
  // 做「仅此节点」的局部重建。方法名与形参由 translator 在翻译期声明。
  if (info.builderBodies.isNotEmpty) {
    for (var i = 0; i < info.builderBodies.length; i++) {
      final name =
          i < info.builderNames.length ? info.builderNames[i] : '_lbBuilder$i';
      final param = i < info.builderParams.length ? info.builderParams[i] : null;
      final prelude =
          i < info.builderPreludes.length ? info.builderPreludes[i] : '';
      b.write('  $name(${param ?? ''}) {\n');
      if (prelude.isNotEmpty) b.write('      $prelude\n');
      b.write('      return ${info.builderBodies[i]};\n');
      b.write('  }\n');
    }
  }

  b.write('}');
  return b.toString();
}

/// 实例字段的 JS 默认值：翻译期预渲染好的 [ClassField.jsInitial] 优先，
/// 否则由字段初始化器字面量求值，都没有则 `undefined`。
///
/// 构造函数（非构造参数字段）与 `__applyProps`（构造参数字段在实参缺省时）
/// 共用这一处默认值口径，避免两处走样。
String _fieldDefaultJs(ClassField f) =>
    f.jsInitial ??
    (f.initializer != null
        ? (literalToJs(f.initializer) ?? 'undefined')
        : 'undefined');

/// 纯 static 类 → JS const 对象：`const MyColors = { a: v, b: v };`。
/// [valueRenderer] 由调用方提供（颜色/字符串/字面量统一求值）。
String _renderStaticConst(
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
/// （@PatchEntry widget，widget 与 state 已在建模期合并为同一 [ClassInfo]）
/// 全部走这里，没有任何按用途分叉的模式开关——所有差异都由 [ClassInfo] 数据
/// 驱动（类名、方法体、builder 子方法、字段的 JS 初值）。
///
/// 因此新增一种「类结构能力」只需改这一处，组件与普通类同时生效。
///
/// 参数：
///   - [exported]：类声明是否 `export`。
///   - [singletonValueRenderer]：纯 static 类的字段值渲染器（颜色/字面量求值）。
///
/// `@HostInjected` 通道表不在参数里：它随 [ClassInfo.hostMethods] 一起由
/// analyze_dart_class 在收集期算好挂在模型上（组件与普通类同一份数据）。
/// ===========================================================================
String dart2js(
  ClassInfo info, {
  bool exported = false,
  String Function(ClassField field)? singletonValueRenderer,
}) {
  if (info.isStaticOnly && singletonValueRenderer != null) {
    return _renderStaticConst(info,
        valueRenderer: singletonValueRenderer, exported: exported);
  }
  return renderClassDecl(info, exported: exported);
}
