/// 渲染层：ClassInfo → JS 类声明字符串。
///
/// 只做字符串拼装：不遍历 AST、不做表达式翻译、不收集依赖。字段初值、方法体、
/// getter、builder 子树都已由 analyze_dart_class 预渲染进 [ClassInfo]。
library;

import 'package:build/build.dart' show log;

import '../class_info.dart';
import 'js_value.dart';

/// 类声明 → JS（export 可选）。含 constructor / 方法 / getter / extends 基类，
/// 并数据驱动地追加方法。
///
/// 组件与普通类共用这一条渲染路径。方法体、getter、builder 子树都已由
/// analyze_dart_class 预渲染成 JS 字符串——本函数只负责拼装，不再遍历 AST。
/// **没有对外工厂函数**：元素的 type 就是类本身（宿主 widget 则是类型名字符串），
/// 由渲染层统一写成 `__h(type, props, children)`。
/// [baseClass]：JS 基类名（见 `jsBaseClassOf`）；null = 不继承。项目类与 SDK
/// 基类都走原生 `extends`，`super` 链由引擎维护。
String renderClassDecl(
  ClassInfo info, {
  bool exported = false,
  String? baseClass,
}) {
  final b = StringBuffer();
  b.write(exported ? 'export class ' : 'class ');
  b.write(info.name);
  final base = baseClass ?? sdkBaseName(info);
  if (base != null) b.write(' extends $base');
  b.write(' {\n');

  // static 字段 → 类体内 `static f = <init>;`（与 Dart 源码同一形态）。
  // 求值时机由引擎保证：类定义时按源码声明序初始化，晚于方法定义，故字段
  // 初始化器里可以引用同类的静态方法。
  _writeStaticFields(b, info);

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
  // 组件类与普通类同样是「构造即实例」：字段初始化照常写在构造里。
  // 翻译层发射 `new X(props)`，元素携带该实例；reconciler mount **直接复用**
  // 这个实例（不再 `new` 第二次），patch 复用旧实例、丢弃重建产生的新实例。
  // 组件实例必须保留 props（patch 复用实例时据此同步最新值）。
  if (info.isComponent) {
    b.write('  constructor(args) {\n');
    b.write('    this.props = args || {};\n');
  } else if (base != null) {
    // 有基类 → 构造统一收 args 并原样转发：父类构造里的 `__applyProps(args)`
    // 才能把同一份构造参数映射到父类字段（Dart 隐式/显式 super(...) 的等价物）。
    // 多传实参对无参父类无害。
    b.write('  constructor(args) {\n');
  } else {
    b.write(info.ctorParams.isEmpty ? '  constructor() {\n' : '  constructor(args) {\n');
  }
  if (base != null) b.write('    super(args);\n');
  if (info.ctorParams.isNotEmpty) b.write('    this.__applyProps(args);\n');
  _writeFieldAssignments(b, info);
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
    // static 成员（Dart 的 static 与实例成员同一名字空间）：JS 侧挂在类上。
    final st = m.isStatic ? 'static ' : '';
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
      b.write('  ${st}get ${m.name}() {\n');
      if (body.isNotEmpty) b.write('$body\n');
      b.write('  }\n');
    } else {
      b.write('  $st$fn${m.name}(${m.params.join(', ')}) {\n');
      if (body.isNotEmpty) b.write('$body\n');
      b.write('  }\n');
    }
  }

  // 响应式 builder（ListenableBuilder/Consumer 等）现在一律以**内联闭包**
  // 下发（builder 协议唯一形态），因此不再生成实例子方法。

  b.write('}');
  return b.toString();
}

/// 静态字段 → 类体内 `static f = <init>;`。
///
/// 与实例字段同一个默认值口径（[ClassField.jsInitial] 已预渲染）：无初始化器
/// 时发射 `static f;`（Dart 里也等价于 null/零值，JS 侧为 undefined）。
void _writeStaticFields(StringBuffer b, ClassInfo info) {
  for (final f in info.staticFields) {
    final v = f.jsInitial ?? (f.initializer == null ? null : literalToJs(f.initializer));
    b.write('  static ${f.name}${v == null ? '' : ' = $v'};\n');
  }
}

/// 非构造参数字段的赋值语句（组件与普通类构造函数共用）。
/// mixin 来源的字段集中尾部、按来源注释分隔（类自身字段在前）。
void _writeFieldAssignments(StringBuffer b, ClassInfo info) {
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

/// ===========================================================================
/// 把类按「基类在前」稳定排序（DFS 后序）。
///
/// `class` 声明有 TDZ：`class A extends B` 必须在 B 求值之后。Dart 不要求基类
/// 先声明，构建期做这一次排序即可，产物里的类顺序与源码顺序无关。
List<ClassInfo> orderClassesByBase(
  List<ClassInfo> classes,
  String? Function(ClassInfo cls) baseOf,
) {
  final byName = {for (final c in classes) c.name: c};
  final out = <ClassInfo>[];
  final done = <String>{};
  final visiting = <String>{};
  void visit(ClassInfo c) {
    // visiting 命中 = 循环继承（Dart 里不合法），直接返回避免无限递归。
    if (done.contains(c.name) || !visiting.add(c.name)) return;
    if (byName[baseOf(c)] case final base?) visit(base);
    visiting.remove(c.name);
    if (done.add(c.name)) out.add(c);
  }

  for (final c in classes) {
    visit(c);
  }
  return out;
}

/// 统一入口：Dart 类 → JS 源码。
///
/// 只有这一处决定「类 → JS」的渲染：普通类（模型/状态类）与组件
/// （@PatchEntry widget，widget 与 state 已在建模期合并为同一 [ClassInfo]）
/// 全部走这里，没有任何按用途分叉的模式开关——所有差异都由 [ClassInfo] 数据
/// 驱动（类名、方法体、builder 子方法、字段的 JS 初值）。
///
/// 因此新增一种「类结构能力」只需改这一处，组件与普通类同时生效。
///
/// 参数：
///   - [exported]：类声明是否 `export`。
///   - [baseClass]：JS 基类名（`jsBaseClassOf` 解析），null = 不继承。
///
/// `@HostInjected` 通道表不在参数里：它随 [ClassInfo.hostMethods] 一起由
/// analyze_dart_class 在收集期算好挂在模型上（组件与普通类同一份数据）。
/// ===========================================================================
String dart2js(
  ClassInfo info, {
  bool exported = false,
  String? baseClass,
}) {
  return renderClassDecl(info, exported: exported, baseClass: baseClass);
}
