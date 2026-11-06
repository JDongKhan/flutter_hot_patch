/// 「有 JS 类的 widget」定义：逻辑组件（provider 状态处理 / Builder 委托）、
/// sliver builder 代理的**类型集合**，以及 package 模块路径规则。
///
/// 这些类型在 JS 侧有真实的类实现（元素 type 用**类引用**），与宿主 widget
/// （Text/Column/... 元素 type 是字符串字面量）区分开。本文件只保留
/// package 模块渲染（ui_widget/widget_module_builder.dart）与组件产物渲染
/// （patch_entry/component_builder.dart）**共用**的部分——类型集合与路径规则；
/// 各类型的 **JS 类源码**只被 package 模块渲染使用，放在那个 builder 自己的
/// 文件里（见 `ui_widget/widget_module_builder.dart`）。
library;

import 'ctor_signatures.dart';
import 'host_types.dart';
import 'package_sources.dart';
import 'runtime_global_types.dart';
import 'source_index.dart';

export 'host_types.dart';

/// 共享结点工厂 `__h` 的宿主 package：并入基础包 flutter 的模块
/// （`patch/flutter.js`）。其它 package 模块与组件产物统一从它
/// `import { __h }`，使 `__h` 全局只定义一次。
const String nodeHelperPackage = 'flutter';

/// package 模块产物路径（**一个 package 一个文件**）。
///
///   - 内建 package 模块（`flutter` 等，由 `ui_widget` 产出）→ `patch/<package>.js`；
///   - 宿主维护的三方 JS（`js/<package>.js`，由 `ui_third_party_js` 拷贝）→
///     `patch/packages/<package>.js`。
///
/// 两类都是 **package 级**，与 lib 源码目录无关；业务产物按同一路径规则 import。
String packageModulePath(String package) => thirdPartyJsPackages.contains(package)
    ? thirdPartyJsModulePath(package)
    : 'patch/$package.js';

/// 有 **builder 命名构造**（`.builder` / `.separated`）的组件类型。
///
/// 只登记「构造名本身就是 builder 形态」的类型：`.builder` / `.separated` 形态
/// 走生成的 JS 代理类循环调用拥有者方法展开子树（构造名由代理类的静态方法
/// 写进 `props.factory`）；普通构造与 `delegate:` 形态都是宿主节点，由 delegate
/// 描述消费，不经过代理类。
///
/// 这份表是**产物组织信息**（决定 `patch/<package>.js` 里生成哪些代理类），
/// 不是运行时行为白名单：运行时只看产物里的 `factory` / `__delegate` 协议，
/// 不再按类型名判断。新增带 `.builder` 的滚动容器时在此登记即可。
const Set<String> builderFormTypes = {
  'ListView',
  'GridView',
  'ReorderableListView',
  'SliverList',
  'SliverGrid',
  'PageView',
  // 普通构造里就带 builder 回调（`AnimatedList(itemBuilder:, initialItemCount:)`）。
  // 与 ListView.builder 同一协议：闭包在代理类里展开成有序子结点，不进宿主 props。
  'AnimatedList',
};

/// builder 形态的「项数」props 键：默认 `itemCount`，Dart 侧形参名不同的类型
/// 在此登记（`AnimatedList` 是 `initialItemCount`）。
///
/// 这是**产物协议配置**（JS 代理展开时读取哪个形参），不是运行时类型表。
const Map<String, String> builderCountPropKeys = {
  'AnimatedList': 'initialItemCount',
};

/// 某类型的「项数」props 键。
String builderCountPropKey(String type) =>
    builderCountPropKeys[type] ?? 'itemCount';

/// 随**组件**下发的 State 代理类源码（键 = 宿主类型名，与组件一起写进该包模块）。
///
/// `GlobalKey.currentState` 的方法签名属于具体组件（`AnimatedListState.insertItem`
/// 不是框架通用概念），因此类定义与登记都放在 flutter.js 里、紧挨对应组件，
/// 运行时只保留通用的 `StateHandle.__op` 与按 runtimeType 取类的登记表。
/// 新增同类组件 = 在这里加一段源码，运行时与翻译器都不动。
const Map<String, String> stateProxySources = {
  'AnimatedList': '''
export class AnimatedListState extends StateHandle {
  insertItem(index, duration) {
    this.__op('insertItem', { index: index, duration: duration });
  }
  // 与 Dart 同形（`removeItem(index, builder, {duration})`）：`builder` 是 Dart
  // 闭包，跨语言无法执行——宿主复用「被移除的原项」当退场项，这里只告警一次。
  removeItem(index, builder, duration) {
    if (typeof builder === 'function' && !AnimatedListState.__warnedRemoval) {
      AnimatedListState.__warnedRemoval = true;
      __warn('[AnimatedList] 退场 builder 不可跨语言执行，已回退为「被移除的原项」（样式与普通项一致）');
    }
    this.__op('removeItem', { index: index, duration: duration });
  }
}
StateHandle.registerProxy('AnimatedListState', AnimatedListState);''',
};

/// 「逻辑 widget」类型名：状态/订阅逻辑必须跑在 JS 里的 widget（Builder 委托 /
/// 订阅式局部重建）。对应的 JS 类源码见 `ui_widget/widget_module_builder.dart`
/// 的 `logicWidgetSources`（键集合与本表一致）。
///
/// 三方库（provider 等）的 JS 类**不在本表**：由宿主在自己的 `js/<package>.js`
/// 维护，生成器只按「类声明所在包 + 该包是否有宿主 JS 模块」自动归属。
const Set<String> logicWidgetTypes = {
  'Builder',
  'ListenableBuilder',
  'ValueListenableBuilder',
  // 隐式动画：`tween` 变化时从当前值过渡到新 end，动画进度由 JS 侧控制器镜像
  // 驱动（宿主逐帧回传 value），不需要新增宿主 widget。
  'TweenAnimationBuilder',
  // 显式动画：JS 侧按 animation 当前 value 展开 builder 子树（局部重建）。
  'AnimatedBuilder',
  // `headerSliverBuilder` 是**返回 sliver 列表的闭包**，跨语言无法执行：
  // JS 侧调用它把头部 slivers 展开成有序子结点，宿主只消费插槽。
  'NestedScrollView',
  // 父约束 builder：`builder(context, constraints)` 必须在 JS 里执行，而约束由
  // 宿主在**布局阶段**下发（JS 侧取不到同步约束）。
  'LayoutBuilder',
  // 方向 builder：与 Flutter 源码一致，由 LayoutBuilder + 父约束推方向。
  'OrientationBuilder',
  // 持久化头部：`delegate.build(context, shrinkOffset, overlapsContent)` 在
  // **布局阶段**同步执行，而 delegate 只存在于 JS——与 LayoutBuilder 同一方案，
  // 把 build 登记成句柄、宿主布局时回调，子树经 patch 回填。
  'SliverPersistentHeader',
  // Overlay：条目表（initialEntries / insert / remove）与每个
  // `OverlayEntry.builder` 都是 JS 闭包，宿主无法执行——条目在 JS 侧展开成
  // 兄弟结点，`Overlay.of(context)` 沿作用域取最近的本实例。
  'Overlay',
  // 拖拽：`data` 是任意 JS 值（模型/闭包/数组），跨桥只能是快照——JS 侧建
  // 按身份索引的引用表，宿主只拿 id 与原生拖动系统对齐；`DragTarget.builder`
  // （候选/被拒数据）与 Draggable 的四个生命周期回调都必须在 JS 里执行。
  'Draggable',
  'LongPressDraggable',
  'DragTarget',
  // OverlayPortal：`overlayChildBuilder` 是 JS 闭包，宿主执行不了——JS 侧先展开
  // 成子结点，宿主只负责「挂到 Overlay 并在 controller 要求时显示」。
  'OverlayPortal',
};

/// 「JS 值类」类型名：**不是 widget**、不产出元素，但构造与静态引用在 JS 侧
/// 需要真实类（`OverlayEntry`：条目的载体，`builder` 是 JS 闭包）。
///
/// 只影响「元素 type 用类引用 / import 登记」这一件事（并进
/// [jsClassWidgetTypes]）；类源码见 widget_module_builder 的 `valueClassSources`。
const Set<String> valueClassTypes = {'OverlayEntry'};

/// 懒容器类型 → 触发懒的 props 键（空列表 = 无条件懒）。
///
/// **这是懒加载语义的唯一事实源**（构建期配置）：生成器把它写进 `flutter.js`，
/// 由 `__h` 给元素打 `lazyChildren` 标记；运行时只认元素标记，不认识任何类型，
/// 也不维护任何类型表 —— 新增懒容器（包括 carousel_slider 这类三方组件）只改
/// 这里 + 重出产物，运行时代码零改动。
///
/// **为什么只有一部分容器可以懒**：Flutter 侧只有「子项尺寸由容器强制、
/// 不由内容决定」的容器，零尺寸占位才是布局中性的（子项可延迟到宿主 inflate
/// 时才挂载，initState 与 Flutter 一致）：
///   - PageView / TabBarView：子项被 `SliverFillViewport` 强制成整屏；
///   - GridView / SliverGrid：子项被格尺寸强制（按 delegate 参数算出）；
///   - SliverFixedExtentList / ListView(itemExtent:)：`itemExtent` 强制。
///
/// 按**内容**量尺寸的 ListView（无 itemExtent）/ SliverList /
/// ReorderableListView **不在此列**：零尺寸占位会让视口把全部 item 判为
/// 可见 → 懒加载反而失效。CustomScrollView 的 sliver 子项 Flutter 本来就
/// 全部 inflate，无需声明。
const Map<String, List<String>> lazyChildHostTypes = {
  'TabBarView': [],
  'PageView': [],
  'GridView': [],
  'SliverGrid': [],
  'SliverFixedExtentList': [],
  'SliverFillViewport': [],
  // 只有带 itemExtent 时才懒（`ListView.separated` 在 SDK 里不接受 itemExtent，
  // 故该 props 只可能来自普通 / `.builder` 形态）。
  'ListView': ['itemExtent'],
};

/// 「元素 type 是 JS 类」的 widget 类型集合 = 有 JS 类的类型（唯一事实源：
/// 逻辑 widget 表 + builder 代理表 + 值类表）。渲染层据此决定元素 type 用类
/// 引用还是类型名字符串；宿主 widget 不在其中，零 import。
Set<String> get jsClassWidgetTypes => {
  ...builderFormTypes,
  ...logicWidgetTypes,
  ...valueClassTypes,
};

/// 类型 → 持有其 JS 类的 package（默认基础包 [nodeHelperPackage]）。
///
/// 三方库不在这里登记：宿主在 `js/<package>.js` 提供 JS 模块后，生成器按
/// **类声明所在的 Dart 包**（[CtorSignatures.declaringPackagesOf]）自动判定归属；
/// 只有「该包确实有宿主 JS 模块」时才返回该包，其余（SDK / 项目类）一律归
/// 基础包 flutter。
String? thirdPartyPackageOf(String type) => _thirdPartyPackageCache.putIfAbsent(
      type,
      () => _resolveThirdPartyPackage(type),
    );

final Map<String, String?> _thirdPartyPackageCache = {};

String? _resolveThirdPartyPackage(String type) {
  final modules = thirdPartyJsPackages;
  if (modules.isEmpty) return null;
  final packages =
      CtorSignatures.instance?.declaringPackagesOf(type) ?? const <String>{};
  final hits = packages.where(modules.contains).toSet();
  // 同名类在多个三方包都有声明时无法判定归属：不猜，交回基础包并出声。
  if (hits.length > 1) {
    // ignore: avoid_print - 构建期日志
    print('[hot_patch_generator] 类型 $type 同时声明在多个三方包 '
        '${hits.join(' / ')}，无法判定 JS 模块归属，按 flutter 处理');
    return null;
  }
  return hits.isEmpty ? null : hits.first;
}

/// 类型的 package 归属（默认 [nodeHelperPackage]）。
///
/// 内建类型（宿主包装类 / 逻辑组件 / builder 代理）固定归 flutter；其余才按
/// 三方源码归属判定（避免对每个 flutter 类型都走一遍类索引）。
String widgetPackageOf(String type) {
  if (jsClassWidgetTypes.contains(type) || hostWrapperTypes.contains(type)) {
    return nodeHelperPackage;
  }
  return thirdPartyPackageOf(type) ?? nodeHelperPackage;
}

/// 类型在 JS 侧**没有类**、且本应有宿主 JS 模块时，返回缺失的 Dart 包名
/// （null = 不是「三方包缺 JS 模块」这种情况）。
///
/// 判据全部是源码事实，不看库名 / 类型名：
///   - 类声明所在包（[CtorSignatures.declaringPackagesOf]）；
///   - 该包是不是 pub 依赖（非本项目 / 非本地依赖包）；
///   - 宿主 `js/` 是否提供了该包的模块（[thirdPartyJsPackages]）。
///
/// 以下情形一律不算缺失（各有自己的 JS 来源，不归宿主 `js/`）：
///   - 本项目包（类有自己的产物文件）；
///   - 本地依赖包（跨包翻译产物 `patch/packages/<pkg>/<rel>.js`）；
///   - 框架包（[nonTranslatedPackages]，JS 侧由宿主注入实现）；
///   - `dart:` 核心库；
///   - 运行时已提供同名类（`runtime.js` 注入全局 / `flutter.js` 值类区）。
String? missingHostJsPackageOf(String type) {
  final sources = PackageSources.instance;
  if (sources == null) return null;
  // 运行时已提供同名类：`new X(...)` 由注入全局 / 值类区承接，不需要模块。
  if (runtimeGlobalTypes().contains(type) ||
      flutterExportTypes().contains(type)) {
    return null;
  }
  final packages =
      CtorSignatures.instance?.declaringPackagesOf(type) ?? const <String>{};
  for (final pkg in packages) {
    if (pkg == sources.projectName) continue;
    if (pkg.startsWith('dart:')) continue;
    if (nonTranslatedPackages.contains(pkg)) continue;
    if (sources.isLocalPackage(pkg)) continue;
    if (thirdPartyJsPackages.contains(pkg)) continue;
    return pkg;
  }
  return null;
}

/// 需要在 flutter.js 生成**宿主包装类**的类型：宿主 widget，排除已有 JS 类的
/// 类型（逻辑组件 / builder 代理，它们的类由各自 package 模块产出，类名不能
/// 重复）。
///
/// 宿主 widget 清单**从运行时源码自动抽取**（见 `host_types.dart` 的
/// `r.register('X', …)`），生成器不维护任何组件表。值对象（`InputDecoration` /
/// `BottomNavigationBarItem` / `DropdownMenuItem` 等）不是宿主元素，由
/// `style_values_js` 在值类区导出普通类，不在此生成。包装类让翻译层把所有
/// widget 构造统一写成 `new Text({...})`，包装类实例自身即宿主元素。
Set<String> get hostWrapperTypes => {
  ...hostWidgetTypes().where((t) => !jsClassWidgetTypes.contains(t)),
};
