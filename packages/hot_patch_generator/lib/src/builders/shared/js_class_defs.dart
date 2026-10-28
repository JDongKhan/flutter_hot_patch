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

import 'host_types.dart';

export 'host_types.dart';

/// 共享结点工厂 `__h` 的宿主 package：并入基础包 flutter 的模块
/// （`patch/flutter.js`）。其它 package 模块与组件产物统一从它
/// `import { __h }`，使 `__h` 全局只定义一次。
const String nodeHelperPackage = 'flutter';

/// package 模块产物路径：`patch/<package>.js`（**一个 package 一个文件**）。
///
/// 这类产物是 **package 级**（`flutter` / `provider` 等，与 lib 源码目录无关），
/// 因此直接落在 patch 根下；而组件/模型产物落在 `patch/` 下镜像 lib 源码路径。
/// 同包的 widget 工厂/逻辑组件集中在一个文件里，避免按类型拆成大量小文件难以
/// 维护，也天然只保留一份实现。
String packageModulePath(String package) => 'patch/$package.js';

/// 有 **builder 命名构造**（`.builder` / `.separated`）的组件类型。
///
/// 只登记「构造名本身就是 builder 形态」的类型：产物带 `factory` 时走生成的
/// JS 代理类循环调用拥有者方法展开子树，宿主据此还原原生命名构造；普通构造
/// 与 `delegate:` 形态都是宿主节点，由 delegate 描述消费，不经过代理类。
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
/// 运行时只保留通用的 `__StateHandle.__op` 与按 runtimeType 取类的登记表。
/// 新增同类组件 = 在这里加一段源码，运行时与翻译器都不动。
const Map<String, String> stateProxySources = {
  'AnimatedList': '''
export class AnimatedListState extends __StateHandle {
  insertItem(index, duration) {
    this.__op('insertItem', { index: index, duration: duration });
  }
  // 与 Dart 同形（`removeItem(index, builder, {duration})`）：`builder` 是 Dart
  // 闭包，跨语言无法执行——宿主复用「被移除的原项」当退场项，这里只告警一次。
  removeItem(index, builder, duration) {
    if (typeof builder === 'function' && !AnimatedListState.__warnedRemoval) {
      AnimatedListState.__warnedRemoval = true;
      console.warn('[AnimatedList] 退场 builder 不可跨语言执行，已回退为「被移除的原项」（样式与普通项一致）');
    }
    this.__op('removeItem', { index: index, duration: duration });
  }
}
__registerStateProxy('AnimatedListState', AnimatedListState);''',
};

/// 「逻辑 widget」类型名：状态/订阅逻辑必须跑在 JS 里的 widget（provider 提供/
/// 消费 VM、Builder 委托）。对应的 JS 类源码见 `ui_widget/widget_module_builder.dart`
/// 的 `logicWidgetSources`（键集合与本表一致）。
const Set<String> logicWidgetTypes = {
  'Builder',
  'ChangeNotifierProvider',
  'MultiProvider',
  'Consumer',
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

/// 类型 → package 模块：决定该类型的 JS 工厂/类落在哪个 `patch/<package>.js`
/// （未登记的类型一律归基础包 [nodeHelperPackage]）。
///
/// 这份登记替代了原先「由 translator 的 `packageName` 推导」的做法——它是**产物
/// 组织信息**（哪个模块持有该类型的 JS 类），与翻译策略无关。
const Map<String, String> widgetPackages = {
  // provider 三件套：状态处理逻辑自成一个模块 patch/provider.js。
  'ChangeNotifierProvider': 'provider',
  'Consumer': 'provider',
  'MultiProvider': 'provider',
};

/// 类型的 package 归属（默认 [nodeHelperPackage]）。
String widgetPackageOf(String type) =>
    widgetPackages[type] ?? nodeHelperPackage;

/// 需要在 flutter.js 生成**宿主包装类**的类型：宿主 widget + 非 Widget 值对象，
/// 排除已有 JS 类的类型（逻辑组件 / builder 代理，它们的类由各自 package 模块
/// 产出，类名不能重复）。
///
/// 宿主 widget / 数据载体清单**从运行时源码自动抽取**（见 `host_types.dart`：
/// `r.register('X', …)` 与 `_dataCarrierTypes`），生成器不维护任何组件表。
/// 包装类让翻译层把所有 widget 构造统一写成 `new Text({...})`，宿主包装类
/// 在构造里直接 `return __h('Text', props)`，产物不再出现 `__h('Text', ...)`。
Set<String> get hostWrapperTypes => {
  ...hostWidgetTypes().where((t) => !jsClassWidgetTypes.contains(t)),
  ...hostDataCarrierTypes(),
};
