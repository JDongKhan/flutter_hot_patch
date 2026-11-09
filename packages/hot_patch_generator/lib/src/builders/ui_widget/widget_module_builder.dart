/// package 模块 builder：把**每个 package** 的全部已注册 widget 类型产出为
/// 一个共享 JS 模块 `patch/<package>.js`（工厂函数 + 逻辑组件类，全局唯一
/// 一份，消除各组件产物里内联同类工厂函数造成的重复与文件爆炸）。
library;

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';

import '../shared/color_constants.dart';
import '../shared/ctor_signatures.dart';
import '../shared/js_format.dart';
import '../shared/js_class_defs.dart';
import '../shared/paths.dart';
import '../runtime/js/animation_js.dart';
import '../runtime/js/asset_bundle_js.dart';
import '../runtime/js/canvas_js.dart';
import '../runtime/js/change_notifier_js.dart';
import '../runtime/js/color_js.dart';
import '../runtime/js/component_js.dart';
import '../runtime/js/controller_base_js.dart';
import '../runtime/js/dart_core_js.dart';
import '../runtime/js/dart_errors_js.dart';
import '../runtime/js/dart_values_js.dart';
import '../runtime/js/dialogs_js.dart';
import '../runtime/js/drag_js.dart';
import '../runtime/js/easy_refresh_js.dart';
import '../runtime/js/focus_js.dart';
import '../runtime/js/future_js.dart';
import '../runtime/js/iterable_js.dart';
import '../runtime/js/key_js.dart';
import '../runtime/js/enum_values_js.dart';
import '../runtime/js/icon_values_js.dart';
import '../runtime/js/keyboard_listener_js.dart';
import '../runtime/js/media_query_js.dart';
import '../runtime/js/navigator_js.dart';
import '../runtime/js/overlay_portal_js.dart';
import '../runtime/js/scroll_controller_js.dart';
import '../runtime/js/state_handle_js.dart';
import '../runtime/js/stream_js.dart';
import '../runtime/js/style_values_js.dart';
import '../runtime/js/tab_controller_js.dart';
import '../runtime/js/text_editing_controller_js.dart';
import '../runtime/js/timer_js.dart';

/// Dart 值类区源码（`patch/flutter.js` 尾部，从 runtime.js 迁入）。
///
/// 收录标准：**Dart / Flutter 值类型与 Controller 的 JS 镜像**——
/// `Duration` / `Size` / `Offset` / `EdgeInsets` / `TextStyle` / `Color` /
/// `ChangeNotifier` / `AnimationController` / 各 Controller / `Key` / `Timer`…
/// 翻译层对它们一律发射 `new X({...})`（一比一），跨桥靠各自 `toJSON()`。
///
/// **拼接顺序有意义**：值类与语言镜像在前（`__positionalArgs` / `__durationMs`
/// 等工具、Dart 异常、基础值类），控制器在后（依赖 dart 值工具与 `G.__core` 的
/// 句柄机制、`ControllerBase`）。片段内的 `function` 声明会提升，故同区内可以
/// 前后互引。依赖方向单向：flutter.js → runtime.js，反方向禁止。
String flutterValueClassesSource() => [
  dartValuesJsSource,
  // dart:core 里 JS 无同名内建的类型（DateTime / RegExp / StringBuffer）
  // 与小写静态命名空间（int / double / num）：依赖 __positionalArgs，
  // 故紧随基础值类之后。
  dartCoreJsSource,
  // 绘制值类（Rect / RRect / Path / Paint / Canvas）与 CustomPainter 句柄：
  // 依赖基础值类工具（__positionalArgs）与 core 句柄机制，故紧随其后。
  canvasJsSource,
  // Dart 内置异常（StateError / ArgumentError / …）：产物 `throw`/`catch`
  // 的落点，按名 import；runtime.js 自身不构造异常，故归值类区。
  dartErrorsJsSource,
  // dart:async 的 Future 同名镜像（Future.delayed / value / wait …）：
  // 依赖基础值类工具（__positionalArgs / __durationMs）与 dartErrors 的
  // StateError（仅 Future.any 的实参校验用），故排在两者之后。
  futureJsSource,
  // rootBundle（assets 读取）：方法返回 Future，紧随其定义之后。
  assetBundleJsSource,
  // Dart `Iterable` 的惰性载体：`__iterMap` / `__iterWhere` / … 与
  // `LazyIterable`（Array 立即求值，语义不同；生成器按静态类型改写）。
  iterableJsSource,
  // dart:async 的 Stream / StreamController / StreamSubscription：依赖
  // Future（Future.__wrap 包装终止操作）与 __durationMs（periodic），
  // 故紧随 Future 之后。
  streamJsSource,
  // 控制器基类（句柄层）：各 Controller 继承它，必须排在它们之前。
  controllerBaseJsSource,
  // SDK 枚举值类（按源码 `enum` 声明自动生成）：翻译层已改为对
  // `Owner.member` 原样引用，这些类就是那些引用的落点。
  enumValuesJsSource(),
  // IconData / Icons：同口径，`Icons.edit` 原样引用。
  iconValuesJsSource(),
  styleValuesJsSource,
  colorJsSource,
  changeNotifierSource,
  animationJsSource,
  scrollControllerJsSource,
  textEditingControllerJsSource,
  focusJsSource,
  keyboardListenerJsSource,
  mediaQueryJsSource,
  // 命令式弹层（showDialog 系列）+ 面板根机制 + Navigator 的落点：
  // Flutter SDK 的 API 面放这里，runtime.js 不留任何弹层知识。
  dialogsJsSource,
  navigatorJsSource,
  // 拖拽：data 身份表与事件详情还原（Draggable / DragTarget 的组件类
  // 在同一模块里引用这里的函数）。
  dragJsSource,
  // OverlayPortal：LayerLink / OverlayPortalController 两个跨语言对象
  // （句柄即身份，show/hide 命令发往宿主）。
  overlayPortalJsSource,
  tabControllerJsSource,
  keyJsSource,
  easyRefreshJsSource,
  timerJsSource,
].join('\n');

/// 有 JS 类的类型 → (package → {type})：由静态登记推导（[jsClassWidgetTypes]
/// 与 [widgetPackageOf]），作为 package 模块产物清单（每个包一个文件）的唯一来源。
Map<String, Set<String>> registeredWidgetPackages() {
  final out = <String, Set<String>>{};
  for (final t in jsClassWidgetTypes) {
    (out[widgetPackageOf(t)] ??= <String>{}).add(t);
  }
  return out;
}

/// widget 模块 builder：把**每个 package** 的全部已注册 widget 类型产出为
/// 一个共享 JS 模块 `patch/<package>.js`（工厂函数 + 逻辑组件类，全局唯一
/// 一份，消除各组件产物里内联同类工厂函数造成的重复与文件爆炸）。
///
/// 输出挂在包根伪资产 `$package$` 下（与 `ui_host_register` / `ui_patch_manifest`
/// 同款输入：整包一个输入，输出路径静态、无需任何种子文件）；输出名从
/// [registeredWidgetPackages] 静态推导，构建时按包名渲染整包即可。
class WidgetModuleBuilder implements Builder {
  const WidgetModuleBuilder();

  @override
  Map<String, List<String>> get buildExtensions {
    final pkgs = <String>{
      // 基础包 flutter（Component / 宿主包装类）即使未注册任何 flutter widget 也要产出。
      nodeHelperPackage,
      ...registeredWidgetPackages().keys,
    }.toList()..sort();
    return {
      // `$package$`：整包伪资产，输入一个包、产出该包的全部 package 模块。
      r'$package$': [for (final p in pkgs) packageModulePath(p)],
    };
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    final packages = registeredWidgetPackages();
    for (final out in buildStep.allowedOutputs) {
      // 输出路径形如 patch/<package>.js → 反推 package
      final segs = out.path.split('/');
      if (segs.length != 2 || segs[0] != 'patch' || !segs[1].endsWith('.js')) {
        continue;
      }
      final pkg = segs[1].substring(0, segs[1].length - '.js'.length);
      await buildStep.writeAsString(
        out,
        canonicalizeJsIndent(
          renderPackageModule(pkg, packages[pkg] ?? const <String>{}),
        ),
      );
    }
  }
}

/// JS 侧**镜像值类**名（从 flutter.js 的值类区源码自动抽取 `export class X`）。
///
/// 用途：判定「静态工厂的落点」——源码里声明的静态方法**返回类型**是镜像值类
/// 时（`ElevatedButton.styleFrom` → `ButtonStyle`），JS 侧落点就是构造该值类。
/// 抽取自产物源码本身，生成器不维护任何类型表。
Set<String> get mirrorValueClasses => _mirrorValueClasses ??= {
  for (final m in _exportClassDecl.allMatches(flutterValueClassesSource()))
    m.group(1)!,
};
Set<String>? _mirrorValueClasses;
final RegExp _exportClassDecl = RegExp(
  r'^[ \t]*export class[ \t]+([A-Za-z_$][\w$]*)',
  multiLine: true,
);

/// 包装类的**静态方法**（Dart 命名构造 / 静态方法的 1:1 落点）。
///
/// 翻译层对命名构造与静态调用都是 1:1 发射（`A.b(...)` → `A.b({...})`），所以
/// JS 类上必须有同名静态方法：
///   - **命名构造**（`SizedBox.shrink` / `ListView.separated`）：静态方法把构造名
///     写进 `props.factory`——这是**宿主选择原生工厂的唯一依据**（宿主 renderer
///     按 `factory` 还原）。构造名从源码自动抽取（[CtorSignatures.ctorNamesOf]）。
///   - **静态方法**（`ElevatedButton.styleFrom`）：源码里声明的静态方法若返回
///     **镜像值类**（[mirrorValueClasses]），落点就是构造该值类
///     （`static styleFrom(props) { return new ButtonStyle(props); }`）。
///     返回组件自身、非镜像类型、或形参含 `BuildContext`（`X.of(context)` /
///     `Divider.createBorderSide(context, …)` 这类运行期上下文查找）、以及私有
///     静态方法（应用代码不可见）一律不生成。
///
/// 两条判据都只来自源码事实，SDK / 依赖包新增构造或静态工厂后重构建即自动补齐，
/// 无需登记任何类名或方法名。
String namedCtorStatics(String type, {Iterable<String> extra = const []}) {
  final sigs = CtorSignatures.instance;
  final names = <String>{...?sigs?.ctorNamesOf(type), ...extra};
  final factories = <String, String>{};
  final statics =
      sigs?.staticMethodsOf(type) ?? const <String, StaticMethodInfo>{};
  for (final e in statics.entries) {
    final info = e.value;
    final ret = info.returnType;
    if (!e.key.startsWith('_') &&
        !info.takesContext &&
        ret != null &&
        ret != type &&
        mirrorValueClasses.contains(ret)) {
      factories[e.key] = ret;
    }
  }
  if (names.isEmpty && factories.isEmpty) return '';
  final b = StringBuffer();
  for (final n in names.toList()..sort()) {
    b.writeln(
      '  static $n(props) { '
      "return new $type(Object.assign({}, props, { factory: '$n' })); }",
    );
  }
  for (final f in factories.entries) {
    b.writeln('  static ${f.key}(props) { return new ${f.value}(props); }');
  }
  return b.toString();
}

/// 逻辑组件的**命名构造静态方法**（`ChangeNotifierProvider.value(props)`）。
///
/// 与包装类同一条口径：翻译层对命名构造 1:1 发射（`A.b(...)` → `A.b({...})`），
/// 静态方法把构造名写进 `props.factory`，构造名从源码自动抽取
/// （[CtorSignatures.ctorNamesOf]），SDK / 依赖包新增命名构造后重构建即自动补齐，
/// 不需要任何类名或构造名登记。产出的是**类体内**的 `static` 成员
/// （由 [withClassStatics] 插进类体末尾）。
String logicCtorStatics(String type) {
  final names = CtorSignatures.instance?.ctorNamesOf(type) ?? const <String>{};
  if (names.isEmpty) return '';
  final b = StringBuffer();
  for (final n in names.toList()..sort()) {
    b.writeln(
      '  static $n(props) { '
      "return new $type(Object.assign({}, props, { factory: '$n' })); }",
    );
  }
  return b.toString();
}

/// 把类体静态成员 [statics] 插到单类源码 [classSource] 的类体末尾。
///
/// 逻辑组件的 JS 源码都是**单个类定义**（[logicWidgetSources]，类体外没有其它
/// 顶层语句），故最后一个 `}` 即类体闭合；找不到时出声（不静默丢静态方法）。
String withClassStatics(String classSource, String statics) {
  if (statics.isEmpty) return classSource;
  final i = classSource.lastIndexOf('}');
  if (i < 0) {
    throw StateError('[hot_patch_generator] 逻辑组件源码缺少类体闭合花括号：\n$classSource');
  }
  final head = classSource.substring(0, i).trimRight();
  return '$head\n$statics${classSource.substring(i)}';
}

/// 宿主包装类源码：类名 = 宿主类型名，构造即宿主元素（`__host=true`，type 名取类名）。
/// 宿主结点的实例化由宿主注册表完成，reconciler 从不 `new` 这个类。
///
/// 同一份源码也用于 `@PatchIgnore(isComponent: true)` 的组件包装类（生成在
/// 该组件**自己的源文件产物**里）：[exported] 为 false 时生成产物内可见的
/// `class`（私有类只可能在本产物里使用）。
String hostWrapperSource(String type, {bool exported = true}) {
  final rule = lazyChildHostTypes[type];
  final lazyLine = rule == null
      ? ''
      : '  static __lazy = ${rule.isEmpty ? 'true' : '[${rule.map(jsonEncode).join(', ')}]'};\n';
  // 函数形参名单（构建期源码事实）：runtime 只查这几个键，避免遍历全部 props。
  // 空名单不写（未声明 = undefined = 无回调）；null = 找不到源码签名 → runtime
  // 回退全量扫描（不静默漏回调）。
  final fnParams = CtorSignatures.instance?.functionParamsOf(type);
  final fnLine = fnParams == null
      ? '  static __fnProps = null;\n'
      : fnParams.isEmpty
      ? ''
      : '  static __fnProps = [${(fnParams.toList()..sort()).map(jsonEncode).join(', ')}];\n';
  return '''
${exported ? 'export ' : ''}class $type extends Component {
  // 宿主包装类：实例**自身**就是宿主元素。类型名直接取类名（`__type.name`），
  // props 由基类构造期统一拆分；懒规则通过覆盖 `__lazy` 声明。
$lazyLine$fnLine${namedCtorStatics(type)}}''';
}

/// builder 命名构造（`X.builder(...)` / `X.separated(...)`）的 JS 侧代理类
/// 源码（类名 = Dart 类型名）：`.separated` 由 `separatorBuilder` 的存在区分
/// （静态方法把构造名写进 `props.factory`，宿主据此还原原生命名构造），回调按
/// Flutter 该命名构造的形参名下发——`itemBuilder`、`separatorBuilder`、
/// `itemCount`。`delegate:` 形态不经过本类（直接是宿主节点，由
/// `children.delegate` 描述消费）。
///
/// build 时**不展开**子结点，只写入延迟展开描述
/// `children.__builder = {item, sep, count, ctx}`：容器是否懒由元素上的
/// `lazyChildren` 标记决定（生成期按 `lazyChildHostTypes` 打到元素上）。
/// 懒容器下 `itemBuilder` 推迟到宿主 inflate 到该项时才调用（与 Flutter
/// `ListView.builder` 只构造可见项一致），非懒容器由运行时立刻按描述展开。
///
/// 被委托方法的第一个实参是 **build 的 `context` 形参**（运行时统一
/// `inst.build(__contextOf(inst))` 传入，锚点就是本代理组件自身的结点，与 Dart 侧
/// `ListView.builder(itemBuilder: (context, i) => …)` 的形参同源），随描述一起
/// 带上，展开时原样传入，保持与原实现一致的上下文语义。
String builderProxySource(String type) {
  final countKey = builderCountPropKey(type);
  final rule = lazyChildHostTypes[type];
  final lazyJs = rule == null
      ? 'false'
      : (rule.isEmpty ? 'true' : '[${rule.map(jsonEncode).join(', ')}]');
  return '''
export class $type extends Component {
  constructor(props) {
    super(props);
    // 普通构造形态（没有 builder 回调，如 `SliverGrid(delegate: …)` /
    // `PageView(children: […])`）：与其它宿主类型同一协议，直接产出元素。
    if (!this.__hasBuilder()) {
      return Component.host('$type', this.props, $lazyJs);
    }
  }
  __hasBuilder() {
    return typeof this.props.itemBuilder === 'function';
  }
  build(context) {
    var item = this.props.itemBuilder;
    // builder 协议只有**一种形态：闭包（函数）**。非函数说明调用方漏了闭包化，
    // 出声后按普通构造渲染（宁可空列表也不静默）。
    if (!this.__hasBuilder()) {
      __warn('[$type] itemBuilder 不是闭包，按普通构造渲染');
      return Component.host('$type', this.props, $lazyJs);
    }
    // props 原样透传（含 itemCount/factory）；**builder 回调从 props 摘除**——
    // 它只用于展开，函数不能进宿主 props（要跨桥序列化）。
    var p = this.__propsExcept(['itemBuilder', 'separatorBuilder']);
    // 展开描述走内部键 __builder，由运行时归入 children，宿主 renderer 不感知。
    p.__builder = {
      item: item,
      sep: this.props.separatorBuilder || null,
      count: this.props.$countKey || 0,
      ctx: context
    };
    return Component.host('$type', p, $lazyJs);
  }
${namedCtorStatics(type, extra: const ['builder', 'separated'])}
}''';
}

/// 「逻辑 widget」类型 → JS 类源码（在本模块里内联一个普通类，类名 = Dart 名）。
///
/// 与宿主 type 节点不同：这些 widget 的**状态/订阅逻辑必须跑在 JS 里**，
/// 因此元素写成 `Component.host(<类名>, props, children)`（类引用，由本模块 export），
/// 运行时 `new` 该组件类并按组件路径挂载，由组件 `build()` 自行消费 props
/// （provider 提供/消费 VM、Builder 委托拥有者方法返回子树）。运行时会给普通
/// 类实例补挂 `props/setState/context`
/// （见 js_ui/runtime_js.dart）。键集合与 js_class_defs 的
/// `logicWidgetTypes` 一致。
const Map<String, String> logicWidgetSources = {
  'Builder': jsBuilderComponent,
  'ListenableBuilder': jsListenableBuilderComponent,
  'ValueListenableBuilder': jsValueListenableBuilderComponent,
  'TweenAnimationBuilder': jsTweenAnimationBuilderComponent,
  'AnimatedBuilder': jsAnimatedBuilderComponent,
  'NestedScrollView': jsNestedScrollViewComponent,
  'LayoutBuilder': jsLayoutBuilderComponent,
  'OrientationBuilder': jsOrientationBuilderComponent,
  'SliverPersistentHeader': jsSliverPersistentHeaderComponent,
  'Overlay': jsOverlayComponent,
  'Draggable': jsDraggableComponent,
  'LongPressDraggable': jsLongPressDraggableComponent,
  'DragTarget': jsDragTargetComponent,
  'OverlayPortal': jsOverlayPortalComponent,
};

/// 值类（**不是 widget**、不产出元素）→ JS 类源码：同样内联在包模块里。
///
/// 与 [logicWidgetSources] 的区别只在语义：值类由业务代码 `new` 出来当普通对象
/// 传递（props 里的载体），元素树里不会出现它的 type。运行时对两者的处理相同
/// （都是模块导出的普通类，使用方 `new X({...})`）。
const Map<String, String> valueClassSources = {
  'OverlayEntry': jsOverlayEntryClass,
};

/// Overlay：条目表 + `Overlay.of(context)` 的 JS 实现。
///
/// 为什么逻辑必须在 JS 侧：`OverlayEntry.builder` 是 JS 闭包，宿主执行不了。
/// 因此条目在 JS 里逐条展开成**兄弟结点**，宿主只看到 `Stack` 插槽：
///   - 声明式：`Overlay(initialEntries: [...])` 的条目直接进表；
///   - 命令式：`Overlay.of(context)` 沿继承链取最近的**本实例**
///     （构造函数里登记 `OverlayState` 继承结点），
///     之后 `insert` / `remove` / `markNeedsBuild` 与 Dart 的 OverlayState 同义。
///
/// 语义与 Flutter 对齐：条目按整块区域叠放（`fit: expand` + `topLeft`，与
/// `_RenderTheater` 相同）；被 `remove()` 过的条目立即退出渲染。
const String jsOverlayComponent = '''
export class Overlay extends Component {
  constructor(props) {
    super(props);
    // 条目表：声明式与命令式共用一张表（Dart 侧同样是 _entries）。
    this.__entries = [];
    // 继承结点声明：本实例即「OverlayState」，子孙 `Overlay.of(context)` 取到它。
    __inheritElement(this, 'OverlayState');
    var init = this.props.initialEntries;
    if (Array.isArray(init)) {
      for (var i = 0; i < init.length; i++) { this.__attach(init[i]); }
    }
  }
  // 条目归属：同一个条目被别的 Overlay 占用时先摘除（Dart 语义：一个条目只能
  // 属于一个 Overlay）；重复 insert 不重复展开。
  __attach(entry) {
    if (!entry || entry.__owner === this) { return; }
    if (entry.__owner) { entry.__owner.remove(entry); }
    entry.__owner = this;
    entry.__removed = false;
    this.__entries.push(entry);
  }
  // ── 与 OverlayState 同名同义的命令式 API ────────────────────────────────
  insert(entry) {
    this.__attach(entry);
    this.setState(function () {});
  }
  insertAll(entries) {
    if (Array.isArray(entries)) {
      for (var i = 0; i < entries.length; i++) { this.__attach(entries[i]); }
    }
    this.setState(function () {});
  }
  remove(entry) {
    if (!entry || entry.__owner !== this) { return; }
    entry.__owner = null;
    entry.__removed = true;
    for (var i = 0; i < this.__entries.length; i++) {
      if (this.__entries[i] === entry) { this.__entries.splice(i, 1); break; }
    }
    this.setState(function () {});
  }
  markNeedsBuild(entry) {
    if (entry && entry.__owner === this) { this.setState(function () {}); }
  }
  build(context) {
    var kids = [];
    for (var i = 0; i < this.__entries.length; i++) {
      var e = this.__entries[i];
      if (!e || e.__removed) { continue; }
      var w = e.__build(context);
      // 与 Dart 一致：null 条目（builder 返回 null）不占位。
      if (w != null) { kids.push(w); }
    }
    return Component.host('Stack', { alignment: 'topLeft', fit: 'expand', children: kids });
  }
  dispose() {
    for (var i = 0; i < this.__entries.length; i++) {
      if (this.__entries[i]) { this.__entries[i].__owner = null; }
    }
    this.__entries = [];
  }
}
Overlay.of = function (context) {
  return context.getInheritedWidgetOfExactType({ typeArguments: { T: 'OverlayState' } });
};''';

/// OverlayEntry：条目的载体（值类，不是元素）。
///
/// `builder` / `opaque` / `maintainState` 与 Dart 字段一一对应；`mounted` 是
/// getter（所在 Overlay 已登记且未移除）；`remove()` / `markNeedsBuild()` 转发给
/// 所属 Overlay。
const String jsOverlayEntryClass = '''
export class OverlayEntry {
  constructor(props) {
    this.props = props || {};
    this.builder = this.props.builder;
    this.opaque = !!this.props.opaque;
    this.maintainState = this.props.maintainState !== false;
    this.__owner = null;
    this.__removed = false;
  }
  get mounted() { return this.__owner != null && !this.__removed; }
  remove() {
    // 幂等：Dart 对**已移除**的条目在 remove 时断言（`_overlay != null`），
    // JS 侧改为静默 no-op——重复移除不该把整个事件回调炸掉。
    if (this.__removed) { return; }
    if (this.__owner) { this.__owner.remove(this); }
  }
  markNeedsBuild() {
    if (this.__owner) { this.__owner.markNeedsBuild(this); }
  }
  __build(context) {
    return typeof this.builder === 'function' ? this.builder(context) : null;
  }
}''';

/// Builder：无状态委托组件——调用拥有者组件上的 `props.builder` 方法
/// （`_builderN(context)`，含 `var model = context.watch(...)` 前置语句）拿子树。
/// 传下去的 context 就是 **build 收到的形参**（本组件自身的 BuildContext 代理，
/// 与 Dart 侧 `Builder(builder: (context) => …)` 的形参一致）。
const String jsBuilderComponent = '''
export class Builder extends Component {
  build(context) {
    // builder 协议唯一形态：闭包。闭包由组件 build 期生成（箭头函数，this 已绑定）。
    var fn = this.props.builder;
    if (typeof fn !== 'function') {
      __warn('[Builder] builder 不是闭包');
      return null;
    }
    return fn(context);
  }
}''';

/// 拖拽三件套：`data` 是**任意 JS 值**（模型 / 闭包 / 数组），跨桥只能是快照，
/// 因此换成本侧身份 id（见 drag_js 的 DragData），宿主只拿 id 与原生拖动系统对齐。
///
/// Draggable / LongPressDraggable 各自持一份 `__sourceProps`（同一段源码由
/// [dragSourcePropsMethodSource] 插入），build 里给出宿主类型名（不按类名判断）。
const String jsDraggableComponent =
    '''
export class Draggable extends Component {
$dragSourcePropsMethodSource
  build(context) {
    return Component.host('Draggable', this.__sourceProps());
  }
}''';

const String jsLongPressDraggableComponent =
    '''
export class LongPressDraggable extends Component {
$dragSourcePropsMethodSource
  build(context) {
    return Component.host('LongPressDraggable', this.__sourceProps());
  }
}''';

/// DragTarget：`builder(context, candidateData, rejectedData)` 只能在 JS 里执行
/// （候选/被拒数据只在悬停时由宿主产生，且候选里是**任意 JS 值**）。与
/// LayoutBuilder 同一方案：登记句柄，宿主回调时带回 id 列表，本侧换回原值后
/// 执行 builder，结果作为 `child` 插槽随下一次 patch 回填。
const String jsDragTargetComponent =
    '''
export class DragTarget extends Component {
$dragTargetPropsMethodSource
  build(context) {
    var props = this.__targetProps(context);
    if (props == null) { return null; }
    return Component.host('DragTarget', props);
  }
}''';

/// OverlayPortal：`overlayChildBuilder` 是 JS 闭包，宿主执行不了，故在本侧执行
/// 后把结果作为 `overlayChild` 插槽下发；宿主只负责「挂到 Overlay 上并在需
/// 要时显示」——显示与否由 controller 句柄命令驱动（见 overlay_portal_js）。
const String jsOverlayPortalComponent = '''
export class OverlayPortal extends Component {
  build(context) {
    var src = this.props;
    // 闭包不能进宿主 props（要跨桥序列化），展开后摘除。
    var p = this.__propsExcept(['overlayChildBuilder']);
    // SDK 的命名构造 `OverlayPortal.targetsRootOverlay`（已废弃）等价于挂到根
    // Overlay。`factory` 是命名构造的通用标记（由自动生成的同名静态方法写入），
    // 这里只补它对应的构造语义，不涉及任何类名/属性名白名单。
    if (p.factory === 'targetsRootOverlay') { p.overlayLocation = 'rootOverlay'; }
    var oc = null;
    if (typeof src.overlayChildBuilder === 'function') {
      oc = src.overlayChildBuilder(context);
    } else {
      __warn('[OverlayPortal] overlayChildBuilder 不是闭包');
    }
    if (oc != null) { p.overlayChild = oc; }
    return Component.host('OverlayPortal', p);
  }
}''';

/// NestedScrollView：**头部 slivers 由 JS 侧展开**。
///
/// Dart 的 `headerSliverBuilder` 是返回 sliver 列表的闭包，跨语言无法执行；
/// 因此本类在 build 里调用它（第二参 `innerBoxIsScrolled` 传 false，与 Flutter
/// 首帧语义一致），把结果与 `body` 一起作为插槽交给宿主结点——宿主只按
/// `headerSlivers` / `body` 两个键取子树，不感知 builder 的存在。
const String jsNestedScrollViewComponent = '''
export class NestedScrollView extends Component {
  build(context) {
    var src = this.props;
    // builder 只在本类里执行，不往宿主 props 里传（函数不能跨语言）。
    var p = this.__propsExcept(['headerSliverBuilder']);
    var fn = src.headerSliverBuilder;
    p.headerSlivers = typeof fn === 'function' ? (fn(context, false) || []) : [];
    return Component.host('NestedScrollView', p);
  }
}''';

/// OrientationBuilder：`builder(context, orientation)` 必须在 JS 里执行。
///
/// 与 Flutter 源码 1:1——原生实现就是
/// `LayoutBuilder(builder: (context, c) => builder(context, c.maxWidth > c.maxHeight
///   ? Orientation.landscape : Orientation.portrait))`，
/// 这里同样**基于 LayoutBuilder 类**委托，不自己取窗口方向。
const String jsOrientationBuilderComponent = '''
export class OrientationBuilder extends Component {
  build(context) {
    var builder = this.props.builder;
    if (typeof builder !== 'function') {
      __warn('[OrientationBuilder] builder 不是闭包');
      return null;
    }
    return Component.host(LayoutBuilder, {
      'builder': function (context, constraints) {
        return builder(context, constraints.maxWidth > constraints.maxHeight
          ? Orientation.landscape
          : Orientation.portrait);
      },
    });
  }
}''';

/// LayoutBuilder：`builder(context, constraints)` 在 JS 里执行，约束由宿主下发。
///
/// 与 Dart 的关系：Flutter 的 LayoutBuilder 在**布局阶段**执行 builder 决定子树，
/// 而 builder 闭包只存在于 JS、约束也只有布局阶段才知道。所以本类把 builder
/// **登记成跨语言句柄**放进宿主结点的 props（`builder`，键名与 Dart 形参一致）；
/// 宿主用真实 `LayoutBuilder` 承载该结点，布局时 `invoke(句柄, [约束 JSON])`
/// 回调本类 —— 本类用约束执行 builder，把结果作为子结点下发（patch 增量子树）。
///
/// 约束按值去重：宿主每次布局都会回调，同值不重建（避免布局→重建→再布局自激）。
/// 首帧（还没有约束）子树为空，与 Flutter LayoutBuilder 自身的首帧语义一致。
const String jsLayoutBuilderComponent = '''
export class LayoutBuilder extends Component {
  // 宿主下发的约束 JSON → BoxConstraints（无界维度发 null，还原成 +∞）。
  __constraintsOf(json) {
    json = json || {};
    return new BoxConstraints({
      minWidth: json.minWidth == null ? 0 : json.minWidth,
      maxWidth: json.maxWidth == null ? Infinity : json.maxWidth,
      minHeight: json.minHeight == null ? 0 : json.minHeight,
      maxHeight: json.maxHeight == null ? Infinity : json.maxHeight,
    });
  }
  build(context) {
    var builder = this.props.builder;
    if (typeof builder !== 'function') {
      __warn('[LayoutBuilder] builder 不是闭包');
      return null;
    }
    var self = this;
    // 宿主在布局阶段调用：实参是本结点的**父约束** JSON，不是事件参数。
    // 这里只下发普通函数：宿主 props 下发的边界会把函数换成句柄，并按结点
    // 复用同一个 id（见 runtime 的 `__hostProps`），重建不会新增句柄。
    var handle = function (json) {
      var c = self.__constraintsOf(json);
      var prev = self.__constraints;
      if (prev && prev.minWidth === c.minWidth && prev.maxWidth === c.maxWidth &&
          prev.minHeight === c.minHeight && prev.maxHeight === c.maxHeight) {
        return;
      }
      self.__constraints = c;
      // 字段名不能叫 `__child`：那是 reconciler 记录「本实例挂出的子宿主结点」
      // 的内部字段（见 mini_react 的 `ci.__child = __mount(...)`），mount 之后会
      // 被覆盖成宿主实例（带 __parent/__el，序列化时成环），props 里再塞它
      // 就变成循环引用。
      self.__lbChild = builder(context, c);
      self.setState(function () {});
    };
    var props = { 'builder': handle };
    if (this.__lbChild != null) { props.child = this.__lbChild; }
    return Component.host('LayoutBuilder', props);
  }
}''';

/// SliverPersistentHeader：`delegate.build(context, shrinkOffset, overlapsContent)`
/// 在**布局阶段**同步执行，而 delegate 只存在于 JS。
///
/// 与 LayoutBuilder 同一方案：
///   - `minExtent` / `maxExtent` 是 delegate 的**同步 getter**，在 JS 里直接读，
///     随 props 下发（header 的高度插值由 Flutter 原生负责，不跨语言）；
///   - `build` 登记成跨语言句柄（`builder`），宿主在布局阶段把
///     `{shrinkOffset, overlapsContent}` 交给它；本类执行 delegate.build 后把
///     子树作为子结点 patch 下发，宿主下一帧用新子树重排。
///   - 因此滚动过程中**内容**晚一帧跟随（高度不受影响）；首帧子树为空。
const String jsSliverPersistentHeaderComponent = '''
export class SliverPersistentHeader extends Component {
  build(context) {
    var delegate = this.props.delegate;
    if (!delegate || typeof delegate.build !== 'function') {
      __warn('[SliverPersistentHeader] delegate.build 不是闭包');
      return null;
    }
    var self = this;
    // 首帧：宿主要到**布局阶段**才回调句柄，而 pinned 头的 paintExtent 由子级
    // 实际高度决定（`min(childExtent, …)`），零高占位会触发「layoutExtent 超过
    // paintExtent」的断言。所以这里先按 (0, false) 展一次——与 Flutter 首次布局
    // 时 scrollOffset=0 的入参一致，只是把那次调用提前到 build 阶段。
    if (this.__sphDelegate !== delegate) {
      this.__sphDelegate = delegate;
      this.__sphSig = { shrinkOffset: 0, overlaps: false };
      this.__sphChild = delegate.build(context, 0, false);
    }
    // 宿主在布局阶段调用：实参是 {shrinkOffset, overlapsContent}，不是事件参数。
    // 普通函数即可：宿主 props 下发边界会换成句柄并按结点复用（见 __hostProps）。
    var handle = function (json) {
      var prev = self.__sphSig;
      if (prev && prev.shrinkOffset === json.shrinkOffset &&
          prev.overlaps === json.overlapsContent) {
        return;
      }
      self.__sphSig = { shrinkOffset: json.shrinkOffset, overlaps: json.overlapsContent };
      // 字段名不能叫 `__child`（reconciler 内部字段，见 LayoutBuilder 处的说明）。
      self.__sphChild = delegate.build(context, json.shrinkOffset, json.overlapsContent);
      self.setState(function () {});
    };
    var props = {
      'minExtent': delegate.minExtent,
      'maxExtent': delegate.maxExtent,
      'builder': handle
    };
    // pinned / floating 原样透传给宿主（默认 false 由宿主兜底）。
    if (this.props.pinned !== undefined) { props.pinned = this.props.pinned; }
    if (this.props.floating !== undefined) { props.floating = this.props.floating; }
    if (this.__sphChild != null) { props.child = this.__sphChild; }
    return Component.host('SliverPersistentHeader', props);
  }
}''';

/// ListenableBuilder：局部重建——订阅 `listenable`（**产物下发的是 listenable
/// 实例本身**，如 `this._model`，不是字段名）、模型 notify 时仅重建本结点子树
/// （`setState` 只标记本结点 dirty）。子树抽在拥有者组件的 `props.builder`
/// 方法（`_lbBuilderN()`）里。与 Consumer 同理：JS 订阅是 UI 更新源，宿主映射
/// 只提供 Dart 侧边界。
const String jsListenableBuilderComponent = '''
export class ListenableBuilder extends __ListenableSubscriber {
  initState() {
    this.__listen(this.props.listenable);
  }
  build(context) {
    var fn = this.props.builder;
    if (typeof fn !== 'function') {
      __warn('[ListenableBuilder] builder 不是闭包');
      return null;
    }
    return Component.host('ListenableBuilder', { notifier: this.props.listenable, child: fn(context) });
  }
}''';

/// ValueListenableBuilder：与 ListenableBuilder 完全同构（同一订阅/局部重建
/// 机制），只多一步——把 `valueListenable.value` 作为 builder 的第二个实参传下去
/// （`builder(context, value, child)`），与 Dart 的
/// `builder: (context, value, child) => …` 形参语义一致。
///
/// 订阅对象是 ValueNotifier（JS 侧 extends ChangeNotifier，句柄 kind 复用
/// `notifier/ChangeNotifier`），故 `addListener` / 宿主映射与 ListenableBuilder 同一套。
const String jsValueListenableBuilderComponent = '''
export class ValueListenableBuilder extends __ListenableSubscriber {
  initState() {
    this.__listen(this.props.valueListenable);
  }
  didUpdateWidget() {
    var next = this.props.valueListenable;
    if (next !== this.__listenable) { this.__listen(next); }
  }
  build(context) {
    var fn = this.props.builder;
    if (typeof fn !== 'function') {
      __warn('[ValueListenableBuilder] builder 不是闭包');
      return null;
    }
    var l = this.props.valueListenable;
    var value = (l && l.value !== undefined) ? l.value : null;
    return Component.host('ValueListenableBuilder', {
      notifier: l,
      child: fn(context, value, this.props.child)
    });
  }
}''';

/// AnimatedBuilder：与 ListenableBuilder 同一套「订阅 → 局部重建」机制（Animation
/// 是 Listenable，JS 侧 `AnimationController` 镜像由宿主逐帧回传 value 后
/// `__notify`），区别只是订阅键是 `animation`：
///   - 订阅 `props.animation`，动画帧到达时只重建本结点子树；
///   - builder 形参是 `(context, child)`，子树抽在 `props.builder` 方法里，child
///     作为独立子结点由宿主映射直传（与 Dart 侧 `child:` 语义一致）。
const String jsAnimatedBuilderComponent = '''
export class AnimatedBuilder extends __ListenableSubscriber {
  initState() {
    this.__listen(this.props.animation);
  }
  build(context) {
    var fn = this.props.builder;
    if (typeof fn !== 'function') {
      __warn('[AnimatedBuilder] builder 不是闭包');
      return null;
    }
    return Component.host('AnimatedBuilder', { child: fn(context, this.props.child) });
  }
}''';

/// TweenAnimationBuilder：**隐式动画**，语义与 Flutter 的
/// `_TweenAnimationBuilderState` 一一对应：
///   - 首帧价值显示 `tween.begin`（begin 为 null 时取 end）；begin != end 时
///     **立刻 forward**（Flutter 的 initState 就是这么做的），begin == end 才
///     静止在那里；
///   - `tween.end` 变化 → begin 改成「当前显示值」、进度归零后 forward，所以
///     动画途中改目标不会跳变；
///   - 每帧按 `curve` 弯曲进度，再用 `tween.lerp` 求值，只重建本结点子树；
///   - 进度到 1 调 `onEnd` 一次（对应 Flutter 的 status.isCompleted）。
///
/// 动画进度由 JS 侧的 `AnimationController` 镜像驱动（宿主逐帧回传 value，
/// 与 AnimatedBuilder 同一机制），因此不新增任何宿主 widget。
const String jsTweenAnimationBuilderComponent = '''
export class TweenAnimationBuilder extends __ListenableSubscriber {
  // 值相等判定：数字直接比；Offset 这类值对象按分量比（每次 build 都会新建
  // 实例，不能靠引用相等，否则每帧都被当成「目标变了」重新起动画）。
  __sameValue(a, b) {
    if (a === b) { return true; }
    if (a && b && typeof a.dx === 'number' && typeof b.dx === 'number') {
      return a.dx === b.dx && a.dy === b.dy;
    }
    return false;
  }
  initState() {
    var p = this.props;
    var self = this;
    this.__tween = p.tween || new Tween({});
    this.__tweenValue = this.__tween.begin != null
      ? this.__tween.begin
      : this.__tween.end;
    var ctrl = new AnimationController({ duration: p.duration, value: 0 });
    this.__tweenCtrl = ctrl;
    this.__tweenCurved = new CurvedAnimation({
      parent: ctrl,
      curve: p.curve || 'linear'
    });
    // 每帧：弯曲后的进度 → tween 求值 → 只重建本结点子树；到 1 时调 onEnd 一次。
    this.__listen(ctrl, function () {
      self.__tweenValue = self.__tween.lerp(self.__tweenCurved.value);
      self.setState(function () {});
      if (ctrl.value >= 1 && !self.__tweenEnded) {
        self.__tweenEnded = true;
        __invokeCallback(self.props.onEnd, []);
      }
    });
    // 与 Flutter 的 initState 一致：begin != end 时进入即播（如 Tween(0 → 1)
    // 进场就有动画，onEnd 也会在到位时触发一次）。
    if (!this.__sameValue(this.__tween.begin, this.__tween.end)) {
      this.__tweenEnded = false;
      ctrl.forward();
    }
  }
  didUpdateWidget() {
    var p = this.props;
    var next = p.tween || new Tween({});
    var prev = this.__tween || new Tween({});
    var ms = __durationMs(p.duration);
    if (ms != null && ms !== this.__tweenCtrl.durationMs) {
      this.__tweenCtrl.durationMs = ms;
    }
    // 同一段动画进行中父级重建时，目标没变就继续用原 tween——换成新实例会把
    // begin 退回源值，正在跑的进度就会跳变。
    if (!this.__sameValue(next.end, prev.end)) {
      next.begin = this.__tweenValue;
      this.__tween = next;
      this.__tweenEnded = false;
      this.__tweenCtrl.reset();
      this.__tweenCtrl.forward();
    }
  }
  build(context) {
    var fn = this.props.builder;
    if (typeof fn !== 'function') {
      __warn('[TweenAnimationBuilder] builder 不是闭包');
      return null;
    }
    return fn(context, this.__tweenValue, this.props.child);
  }
  dispose() {
    this.__unlisten();
    if (this.__tweenCtrl) { this.__tweenCtrl.dispose(); }
  }
}''';

/// package 模块产物：把该 package 里**有 JS 类**的 widget 类型导出为 JS 类
/// （逻辑组件：Builder 委托 / 订阅式局部重建；sliver builder 代理）。
///
/// 三方库（provider 等）的 JS 类不在这里生成：由宿主放在 `js/<package>.js`，
/// 构建时原样拷贝到 `patch/packages/<package>.js`（见 `ui_third_party_js`）。
///
/// 宿主 widget（Text/Column/...）**不产出任何代码**：它们的元素 type 就是类型名
/// 字符串（`Component.host('Text', {...})`），由宿主注册表映射成 Flutter widget；
/// 本模块只在有 JS 逻辑时才有存在意义。
///
/// 一个 package 一个文件（文件名即包名）。共享 `Component` 基类 / 宿主包装类只在
/// 其宿主包（[nodeHelperPackage]）里定义一次，其它包从
/// `<host>.js` 相对 import。
/// 产物自包含（不依赖运行时 `__jsui`），宿主既有渲染路径与 JS 运行时都能
/// 消费同一份产物。
String renderPackageModule(String package, Set<String> types) {
  final sorted = types.toList()..sort();
  final b = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT EDIT')
    ..writeln('// package 模块（package: $package）：由 hot_patch_generator 生成')
    ..writeln('// 本包内有 JS 类的 widget（逻辑组件 / sliver 代理）集中于此文件')
    ..writeln();
  if (package == nodeHelperPackage) {
    // 核心符号统一从 `G.__core` 解构（跨模块只走 G，见 runtime_js.dart【11.5】）。
    // 必须写在组件 / 包装类定义之前：它们直接引用这些核心函数，
    // 模块求值期（Colors / 值类构造）也可能用到。
    b
      ..writeln('const G = globalThis;')
      ..writeln('const {')
      ..writeln(
        '  __handleOp, __registerHandle, __releaseHandle, __handleObjectOf,',
      )
      ..writeln('  __createFnHandle, __objectToken, __inheritElement,')
      ..writeln('  __contextOf, __isElement, __isElementList, __descriptorOf,')
      ..writeln(
        '  __openRoot, __closeRoot, __invokeHostMethod, __roots, JsBuildContext,',
      )
      ..writeln('} = G.__core;')
      ..writeln()
      // 框架内日志 / 值展开：runtime 的两个内部入口经 __core 交接（release 零跨桥）。
      ..writeln('const __log = G.__core.log;')
      ..writeln('const __str = G.__core.str;')
      ..writeln('function __warn(text) { __log("warn", text); }')
      ..writeln('function __error(text) { __log("error", text); }')
      ..writeln()
      // Component 基类：必须早于下面的逻辑组件 / 宿主包装类（它们 `extends
      // Component`，class 有 TDZ）。同时它也是翻译产物 `extends StatelessWidget /
      // StatefulWidget` 的落点。
      ..writeln(componentJsSource)
      ..writeln()
      // State 句柄（GlobalKey.currentState 的承载）：必须早于下面 sorted 里
      // 随组件下发的 State 代理类（`extends StateHandle` 在模块求值期即生效）。
      ..writeln(stateHandleJsSource)
      ..writeln();
    // 宿主包装类：`new Text({...})` → `Component.host('Text', {...})`。翻译层因此可以对
    // 所有 widget 构造统一发射 `new Type(props)`，产物里不再出现 `Component.host('X', …)`。
    for (final t in hostWrapperTypes.toList()..sort()) {
      b
        ..writeln()
        ..writeln(hostWrapperSource(t));
    }
  } else {
    final nodeRel = relativeProduct(
      packageModulePath(package),
      packageModulePath(nodeHelperPackage),
    );
    b
      ..writeln("import { Component } from '$nodeRel';")
      ..writeln();
  }
  for (final t in sorted) {
    // 值类（不是 widget、不产出元素）：只导出普通类，使用方 `new X({...})`。
    final value = valueClassSources[t];
    if (value != null) {
      b
        ..writeln()
        ..writeln(value);
      continue;
    }
    // 逻辑 widget（provider 状态处理 / Builder 委托）：状态与订阅逻辑全部在
    // JS 侧，本包导出普通类，元素 type 即该类，宿主零感知。
    final logic = logicWidgetSources[t];
    if (logic != null) {
      b
        ..writeln()
        ..writeln(withClassStatics(logic, logicCtorStatics(t)));
      continue;
    }
    // builder 命名构造代理（`.builder` / `.separated`）：元素 type 是类引用，
    // build 时循环调用拥有者方法收集子树；普通构造与 `delegate:` 形态由渲染层
    // 直接产出宿主节点（`Component.host('SliverList', ...)`），不经过本类。
    if (builderFormTypes.contains(t)) {
      b
        ..writeln()
        ..writeln(builderProxySource(t));
    }
  }
  // 随组件下发的 State 代理类（`GlobalKey.currentState` 的方法属于具体组件）：
  // 紧挨该组件的包装类写出，运行时只负责按 runtimeType 取类。
  for (final t in sorted) {
    final src = stateProxySources[t];
    if (src == null) continue;
    b
      ..writeln()
      ..writeln(src);
  }
  // -----------------------------------------------------------------------
  // Dart 值类区：**固定在产物最末**（所有 widget / 逻辑组件包装类之后）。
  //
  // 分区判据是「这是不是 Dart / Flutter 的值类型」——`Duration` / `Size` /
  // `Offset` / `Color` / `TextStyle` / `ChangeNotifier` / 各 Controller / `Key` /
  // 枚举镜像 / `Colors` 常量表。它们是产物里 `new X({...})` 的落点，与上面的
  // widget 包装类**用途不同**（包装类产出元素描述，值类承载数据），因此单独
  // 成区并置于末尾：读产物时先看到 UI 结构，再看数据类型。
  //
  // 顺序约束（区内）：值类 → 枚举镜像 → Colors。`__mc` 在求值期就
  // `new MaterialColor(...)`，而 MaterialColor 的原型在值类区赋值——晚于实例
  // 创建就会丢 toJSON。
  //
  // 本区同时承载 **Flutter SDK 的 API 面**：`showDialog` 系列 / `Navigator`（见
  // dialogs_js.dart / navigator_js.dart）——它们只做「Dart 一比一调用形状」，
  // 不属 mini-react 核心。
  //
  // 与 runtime 的唯一耦合面是 `G.__core`（原型补丁 / 句柄表 / reconciler 的
  // 独立根挂载 / 通用语法工具），见 runtime_js.dart 的【11.5】——跨模块只走 G，
  // 不假设同一 IIFE 作用域；反向（runtime 引用 flutter 的类）禁止。
  if (package == nodeHelperPackage) {
    b
      ..writeln()
      ..writeln('// ===== Dart 值类（值对象 / Controller / 动画 / Key / 枚举）=====')
      ..writeln('// 翻译层对它们一律 `new X({...})` / `X.member`；')
      ..writeln('// 跨桥经各自 toJSON 输出宿主协议（不在这里做任何 JSON 拍平）。')
      ..writeln()
      ..writeln(flutterValueClassesSource());
    // Colors 常量（SDK colors.dart 自动抽取）：`Colors.red` / `Colors.red[400]`
    // 在 JS 侧原样求值，翻译层不含任何色值表；新增颜色重构建即生效。
    final colors = colorsJsSource();
    if (colors != null) {
      b
        ..writeln()
        ..writeln(colors);
    } else {
      // ignore: avoid_print - 构建期日志
      print(
        '[hot_patch_generator] 未能定位 Flutter SDK colors.dart，'
        'Colors 常量未注入（产物里 Colors.* 会解析失败）',
      );
    }
  }
  return b.toString();
}
