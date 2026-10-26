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
  // 显式动画：JS 侧按 animation 当前 value 展开 builder 子树（局部重建）。
  'AnimatedBuilder',
};

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
/// 逻辑 widget 表 + builder 代理表）。渲染层据此决定元素 type 用类引用还是
/// 类型名字符串；宿主 widget 不在其中，零 import。
Set<String> get jsClassWidgetTypes => {
  ...builderFormTypes,
  ...logicWidgetTypes,
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

/// 宿主侧「内建 widget」类型名登记（= 运行时 `JsWidgetRegistry` 注册表的镜像）。
///
/// 用途：翻译期区分「内建 widget」与「业务类」——字段类型判定与依赖扫描遇到
/// 内建 widget 时不再当模型类处理（它们由宿主 / JS 类渲染，没有可翻译的类体）。
/// 这份登记替代了原先由 translator 注册表推导的做法。
///
/// **同步维护**：新增内建组件时，运行时（`js_widget_registry.dart` 与各
/// `capabilities/*/**.dart` 的 `r.register(...)`）与本表两侧都要加。
const Set<String> builtinWidgetTypes = {
  // 基础视觉 / 布局
  'Text', 'Column', 'Row', 'Stack', 'IndexedStack', 'Wrap', 'Container',
  'Padding', 'Center', 'Align', 'SizedBox', 'Expanded', 'Flexible',
  'Positioned', 'Spacer', 'ClipRRect', 'ClipOval', 'Material', 'Transform',
  'Card', 'Icon', 'Image', 'CircleAvatar', 'Divider', 'Chip', 'ListTile',
  'SafeArea', 'Opacity', 'ConstrainedBox', 'AspectRatio',
  'FractionallySizedBox', 'DecoratedBox', 'CircularProgressIndicator',
  'LinearProgressIndicator', 'Drawer', 'DrawerHeader',
  // 按钮 / 交互
  'ElevatedButton', 'TextButton', 'FilledButton', 'OutlinedButton',
  'IconButton', 'FloatingActionButton', 'InkWell', 'GestureDetector',
  'Switch', 'Checkbox', 'Slider', 'Radio', 'DropdownButton',
  'DropdownMenuItem', 'BottomNavigationBar', 'BottomNavigationBarItem',
  // 页面骨架
  'Scaffold', 'AppBar',
  // Tab 家族
  'DefaultTabController', 'TabBar', 'Tab', 'TabBarView',
  // 滚动 / sliver 家族
  'ListView', 'GridView', 'ReorderableListView', 'CustomScrollView',
  'SliverList', 'SliverGrid', 'SliverAppBar', 'SliverPadding',
  'SliverToBoxAdapter', 'SliverFillRemaining', 'SliverFixedExtentList',
  'SliverFillViewport', 'SliverOpacity', 'SliverOffstage',
  'SliverIgnorePointer', 'SliverSafeArea', 'SliverVisibility',
  'SingleChildScrollView', 'PageView', 'NotificationListener',
  // 逻辑组件（JS 类）与能力包
  'Builder', 'ChangeNotifierProvider', 'Consumer', 'MultiProvider',
  'ListenableBuilder', 'ValueListenableBuilder', 'AnimatedBuilder', 'TextField',
  'CachedNetworkImage', 'EasyRefresh',
  // 动画（隐式动画 / 过渡动画，宿主映射见 capabilities/animation）
  'AnimatedContainer', 'AnimatedOpacity', 'AnimatedPadding', 'AnimatedAlign',
  'AnimatedScale', 'AnimatedRotation', 'AnimatedSlide', 'AnimatedSize',
  'AnimatedSwitcher', 'AnimatedCrossFade', 'AnimatedDefaultTextStyle',
  'AnimatedPositioned',
  'FadeTransition', 'ScaleTransition', 'RotationTransition', 'SizeTransition',
};

/// 非 Widget 的「值对象」构造类型（元素描述由父 renderer 以 JsRenderContext
/// 消费，不作为子树挂载）。与运行时 `js_widget_registry.dart` 的
/// `_dataCarrierTypes` **同步维护**。
const Set<String> jsDataCarrierTypes = {'InputDecoration'};

/// 需要在 flutter.js 生成**宿主包装类**的类型：宿主 widget + 非 Widget 值对象，
/// 排除已有 JS 类的类型（逻辑组件 / builder 代理，它们的类由各自 package 模块
/// 产出，类名不能重复）。
///
/// 包装类让翻译层把所有 widget 构造统一写成 `new Text({...})`，宿主包装类
/// 在构造里直接 `return __h('Text', props)`，产物不再出现 `__h('Text', ...)`。
Set<String> get hostWrapperTypes => {
  ...builtinWidgetTypes.where((t) => !jsClassWidgetTypes.contains(t)),
  ...jsDataCarrierTypes,
};

/// 「构造名 → 位置实参的 Flutter 形参名」登记（运行时读取键名的镜像）。
///
/// 统一翻译把位置实参按**Flutter 自己声明的形参名**放进 props，产物自解释：
/// `Text('你好')` → `{data: '你好'}`、`Icon(Icons.star)` → `{icon: 'star'}`，
/// 而不是不透明的下标数组。键是**构造名**（`类型名` 或 `类型名.命名构造名`，
/// 后者优先，如 `Image.network` 的位置实参是 `src`、`Image.asset` 的是 `name`）。
///
/// 生成器只有语法树（无类型解析），拿不到任意 widget 的形参名，故取本表；未登记
/// 的类型遇到位置实参时**构建期告警并丢弃**（不再有 `$pos` 下标数组兜底）。
/// 新增带位置实参的组件时，必须在此登记其形参名。
///
/// **同步维护**：与运行时各 renderer 读取的键名一致（`js_widget_registry.dart`）。
const Map<String, List<String>> widgetPositionalArgNames = {
  'Text': ['data'],
  // Text.rich 的首个位置实参是 InlineSpan（富文本，运行时暂不支持）。
  'Text.rich': ['textSpan'],
  'Icon': ['icon'],
  'Image': ['image'],
  'Image.network': ['src'],
  'Image.asset': ['name'],
  'Image.file': ['file'],
  'Image.memory': ['bytes'],
};
