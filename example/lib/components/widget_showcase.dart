import 'package:flutter/material.dart';
import 'package:dynamic_flutter/dynamic_flutter.dart';
import 'animated_list_detail.dart';
import 'asset_override_detail.dart';
import 'automatic_keep_alive_detail.dart';
import 'button_detail.dart';
import 'color_filtered_detail.dart';
import '../base/patch_config.dart';
import 'compare_pane.dart';
import 'container_detail.dart';
import 'custom_paint_detail.dart';
import 'dialog_detail.dart';
import 'dismissible_detail.dart';
import 'drag_detail.dart';
import 'drawer_detail.dart';
import 'fade_in_image_detail.dart';
import 'focus_detail.dart';
import 'grid_detail.dart';
import 'image_detail.dart';
import 'input_detail.dart';
import 'key_detail.dart';
import 'layout_detail.dart';
import 'list_view_detail.dart';
import 'media_query_detail.dart';
import 'method_channel_detail.dart';
import 'notifier_card.dart';
import 'page_view_detail.dart';
import 'progress_detail.dart';
import 'reorder_list_detail.dart';
import 'scaffold_detail.dart';
import 'scroll_detail.dart';
import 'sliver_detail.dart';
import 'stateless_card.dart';
import 'tab_detail.dart';
import 'text_detail.dart';
import 'timetable_picker_detail.dart';
import '../grammar/alias_detail.dart';
import '../grammar/array_detail.dart';
import '../grammar/async_detail.dart';
import '../grammar/basic_api_detail.dart';
import '../grammar/callable_detail.dart';
import '../grammar/collection_detail.dart';
import '../grammar/constructor_detail.dart';
import '../grammar/cycle_import_detail.dart';
import '../grammar/enum_detail.dart';
import '../grammar/expression_detail.dart';
import '../grammar/extension_detail.dart';
import '../grammar/function_detail.dart';
import '../grammar/generic_detail.dart';
import '../grammar/generator_detail.dart';
import '../grammar/inheritance_detail.dart';
import '../grammar/map_detail.dart';
import '../grammar/mixin_detail.dart';
import '../grammar/null_safety_detail.dart';
import '../grammar/operator_detail.dart';
import '../grammar/pattern_detail.dart';
import '../grammar/record_detail.dart';
import '../grammar/statement_detail.dart';
import '../grammar/stream_detail.dart';
import 'hero_detail.dart';
import 'image_filtered_detail.dart';
import 'image_icon_detail.dart';
import 'keyboard_listener_detail.dart';
import 'layout_more_detail.dart';
import 'nested_scroll_view_detail.dart';
import 'orientation_builder_detail.dart';
import 'overlay_detail.dart';
import 'overlay_portal_detail.dart';
import 'pop_scope_detail.dart';
import 'preferred_size_detail.dart';
import 'radio_group_detail.dart';
import 'safe_area_detail.dart';
import 'sliver_fill_viewport_detail.dart';
import 'sliver_fill_remaining_detail.dart';
import 'sliver_persistent_header_detail.dart';
import 'spacer_detail.dart';
import 'visibility_detail.dart';
import 'tween_animation_builder_detail.dart';
import 'value_listenable_builder_detail.dart';
import 'explicit_animation_detail.dart';
import 'implicit_animation_detail.dart';
import 'rich_text_detail.dart';

/// 常用组件导航列表页（普通页面，无 @PatchEntry 注解）：
/// 分组列出 Flutter 常用组件，点击条目进入对应详情页。
/// 详情页是 @PatchEntry 注解组件（components 下各自的 *_detail.dart），同一份代码
/// 原生可直接用、也可由 JsUiWidget 加载 JS 产物热更（原生 vs JS 同屏）。
class WidgetShowcase extends StatelessWidget {
  const WidgetShowcase({super.key});

  static const List<_Group> groups = [
    _Group('文本展示', [
      _Entry('Text', '文案 / TextStyle / 截断 / 对齐 / 装饰', 'TextDetail'),
      _Entry(
        'RichText',
        'TextSpan 树：嵌套子串、不同样式、maxLines + ellipsis',
        'RichTextDetail',
      ),
    ]),
    _Group('按钮操作', [
      _Entry(
        'Button',
        'Elevated / Text / Outlined + ButtonStyle 全属性',
        'ButtonDetail',
      ),
    ]),
    _Group('布局', [
      _Entry(
        'Row / Column / Stack',
        'Expanded / Flexible / Wrap / Align / Padding / Center / SizedBox',
        'LayoutDetail',
      ),
      _Entry(
        'Spacer',
        'Row/Column 弹性空隙：flex 切 1/2/3，Column 里把按钮顶到底',
        'SpacerDetail',
      ),
      _Entry(
        'Visibility / Offstage',
        '显隐控制：不占位 / 占位 / 仍可点 / replacement；Offstage 退出布局',
        'VisibilityDetail',
      ),
    ]),
    _Group('图片图标', [
      _Entry('Image / Icon / CircleAvatar', '网络图片、图标、圆形头像', 'ImageDetail'),
      _Entry(
        'Asset 覆盖',
        'assets 图片 / JSON：补丁包同名资源优先，缺失回退项目 assets',
        'AssetOverrideDetail',
      ),
      _Entry(
        'ImageIcon',
        '图片当图标：size / color(srcIn) / semanticLabel / 与 Icon 对照',
        'ImageIconDetail',
      ),
      _Entry(
        'FadeInImage',
        '占位图 → 目标图淡入（assetNetwork / 普通构造）',
        'FadeInImageDetail',
      ),
    ]),
    _Group('容器装饰', [
      _Entry(
        'Container / Card / Divider',
        '颜色、圆角、Padding、卡片、分割线',
        'ContainerDetail',
      ),
      _Entry(
        'ColorFiltered',
        '颜色滤镜：mode(multiply/modulate) 与 20 项矩阵灰度',
        'ColorFilteredDetail',
      ),
      _Entry(
        'CustomPaint',
        '自绘：图元 / 文字 / 图片 / 旋转 / 裁剪 / Path / 渐变',
        'CustomPaintDetail',
      ),
    ]),
    _Group('列表滚动', [
      _Entry(
        'ListView',
        'children / builder / separated / itemExtent 懒加载（含 initState / dispose 日志）',
        'ListViewDetail',
      ),
      _Entry(
        'SingleChildScrollView',
        '横向滚动 + ScrollController 监听 / 跳转',
        'ScrollDetail',
      ),
      _Entry(
        'AnimatedList',
        '增删补间：GlobalKey.currentState 的 insertItem / removeItem',
        'AnimatedListDetail',
      ),
      _Entry(
        'Dismissible',
        '滑动删除：background / secondaryBackground + confirmDismiss 方向确认',
        'DismissibleDetail',
      ),
      _Entry(
        'ReorderableListView',
        '长按拖拽重排：onReorder 双参事件，重排 / 添加列表项',
        'ReorderListDetail',
      ),
    ]),
    _Group('Key 家族', [
      _Entry(
        'Key / ValueKey / ObjectKey / UniqueKey / PageStorageKey / GlobalKey',
        '列表匹配 / 对象身份 / 强制重建 / 滚动位置持久化 / 宿主端量测',
        'KeyDetail',
        fillPane: true,
      ),
    ]),
    _Group('Sliver 滚动', [
      _Entry(
        'CustomScrollView',
        'Sliver 全家桶整页',
        'SliverDetail',
        fillPane: true,
      ),
      _Entry('GridView', 'GridView 懒加载验证', 'GridDetail', fillPane: true),
      _Entry(
        'NestedScrollView',
        '头部 slivers 与内层 body 联动：pinned 折叠 / floating 浮出',
        'NestedScrollViewDetail',
      ),
      _Entry(
        'SliverFillViewport',
        '每屏占视口 fraction：切 1.0/0.8/0.5，padEnds 对比',
        'SliverFillViewportDetail',
        fillPane: true,
      ),
      _Entry(
        'SliverFillRemaining',
        '填满视口剩余高度：hasScrollBody / fillOverscroll / 贴底',
        'SliverFillRemainingDetail',
        fillPane: true,
      ),
      _Entry(
        'SliverPersistentHeader',
        '滚动折叠 / 浮出的头部：pinned + floating 两个 delegate',
        'SliverPersistentHeaderDetail',
        fillPane: true,
      ),
    ]),
    _Group('页面骨架', [
      _Entry(
        'Scaffold / AppBar / Center',
        '页面级组件：AppBar + body + FAB 整页骨架',
        'ScaffoldDetail',
        fillPane: true,
      ),
      _Entry(
        'Drawer / endDrawer',
        '抽屉 + AppBar 汉堡按钮',
        'DrawerDetail',
        fillPane: true,
      ),
      _Entry(
        'OrientationBuilder / MediaQuery',
        '方向与窗口尺寸驱动布局（拉高窗口切 portrait）',
        'OrientationBuilderDetail',
      ),
      _Entry(
        'Overlay / OverlayEntry',
        '声明式 initialEntries + 命令式 insert / remove 浮层',
        'OverlayDetail',
      ),
      _Entry(
        'PopScope',
        '拦截返回：canPop 开关 + onPopInvokedWithResult 两参回调',
        'PopScopeDetail',
      ),
      _Entry(
        'PreferredSize',
        '自定义顶栏高度：任意子树声明成 PreferredSizeWidget',
        'PreferredSizeDetail',
        fillPane: true,
      ),
      _Entry(
        'RadioGroup',
        '子级 Radio 共用选中值与回调（不再传 groupValue/onChanged）',
        'RadioGroupDetail',
      ),
      _Entry(
        'SafeArea',
        '系统安全区内边距：四边开关 + minimum 强制留白 + viewPadding',
        'SafeAreaDetail',
      ),
      _Entry(
        'MediaQuery.removePadding',
        '按方向移除安全区 padding：外层 / 移除后子树的 padding 数值对照',
        'MediaQueryDetail',
      ),
    ]),
    _Group('Tab 切换', [
      _Entry(
        'TabBar / TabBarView',
        'DefaultTabController + 显式 TabController 驱动切页',
        'TabDetail',
      ),
    ]),
    _Group('分页视图', [_Entry('PageView', '分页切换 + 页码回传', 'PageViewDetail')]),
    _Group('表单输入', [
      _Entry(
        'TextField / Radio / Dropdown',
        '输入框、单选、下拉、开关、勾选、滑块',
        'InputDetail',
      ),
      _Entry(
        'TimetableDatePicker',
        '时刻表日期选择：年 / 月 / 日 / 周四列联动滚轮',
        'TimetablePickerDetail',
      ),
    ]),
    _Group('焦点交互', [
      _Entry(
        'Focus / FocusNode',
        'requestFocus / unfocus、onFocusChange、hasFocus、canRequestFocus',
        'FocusDetail',
      ),
      _Entry('Hero', '跨路由共享元素：点卡片飞向目标页，返回时飞回', 'HeroDetail'),
      _Entry(
        'ImageFiltered',
        '整棵子树图片滤镜：blur / dilate / matrix / compose',
        'ImageFilteredDetail',
      ),
      _Entry(
        'KeyboardListener',
        '原始按键事件：KeyDown/Repeat/Up、logicalKey 比较、focusNode',
        'KeyboardListenerDetail',
      ),
    ]),
    _Group('拖拽', [
      _Entry(
        'Draggable / DragTarget',
        '任意 JS 负载往返、长按拖拽、悬停高亮',
        'DragDetail',
      ),
    ]),
    _Group('布局补充', [
      _Entry(
        'Tooltip / FittedBox / RotatedBox / Intrinsic / InteractiveViewer',
        '提示气泡、缩放适配、旋转、等高布局、可缩放可拖动画布',
        'LayoutMoreDetail',
      ),
    ]),
    _Group('弹层', [
      _Entry(
        'OverlayPortal / CompositedTransform',
        '弹层挂载点 + LayerLink 锚定跟随：引导气泡（hot_module_base 封装）',
        'OverlayPortalDetail',
      ),
      _Entry(
        'showDialog / 底部弹层 / Cupertino',
        '命令式弹层全家桶：builder 在 JS 侧建树挂独立根，返回值经 Future 回传',
        'DialogDetail',
      ),
    ]),
    _Group('平台通道', [
      _Entry(
        'MethodChannel × 2',
        '两个独立三方库插件各自 channel：设备信息 / 原生计数（原生与 JS 同链路）',
        'MethodChannelDetail',
      ),
    ]),
    _Group('进度指示', [
      _Entry('ProgressIndicator', '圆形 / 线性进度条', 'ProgressDetail'),
    ]),
    _Group('状态管理', [
      _Entry(
        'ChangeNotifier',
        'ListenableBuilder 局部重建（跨文件模型 + dispose）',
        'NotifierCard',
      ),
      _Entry(
        'ValueListenableBuilder',
        'ValueNotifier 订阅：值变化只重建该子树，赋相同值不重建，可切订阅对象',
        'ValueListenableBuilderDetail',
      ),
      _Entry(
        'AutomaticKeepAlive',
        '切页保活：wantKeepAlive 声明决定离屏 State 是否销毁',
        'AutomaticKeepAliveDetail',
      ),
    ]),
    _Group('无状态组件', [
      _Entry(
        'StatelessWidget',
        '无 State，build 在 widget 类自身，props 走构造参数',
        'StatelessCard',
      ),
    ]),
    _Group('动画', [
      _Entry(
        '隐式动画',
        'AnimatedContainer / Opacity / Scale / Rotation / Slide / CrossFade / Size / Switcher（宿主插值）',
        'ImplicitAnimationDetail',
      ),
      _Entry(
        '显式动画',
        'AnimationController + AnimatedBuilder + *Transition（宿主 Ticker 驱动）',
        'ExplicitAnimationDetail',
      ),
      _Entry(
        'TweenAnimationBuilder',
        '隐式动画：tween 目标变化自动过渡，可切目标/时长/曲线，onEnd 计数',
        'TweenAnimationBuilderDetail',
      ),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        for (final g in groups) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              g.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ),
          for (final e in g.entries)
            ListTile(
              leading: const Icon(Icons.widgets_outlined),
              title: Text(e.title),
              subtitle: Text(e.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => WidgetDetailPage(
                    component: e.component,
                    fillPane: e.fillPane,
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _Group {
  final String title;
  final List<_Entry> entries;
  const _Group(this.title, this.entries);
}

class _Entry {
  final String title;
  final String subtitle;
  final String component;

  /// 详情页对比时外层不再套 [SingleChildScrollView]，组件铺满一栏。
  /// 用于自带滚动容器的 demo（CustomScrollView / GridView）与 Scaffold 根整页。
  final bool fillPane;

  const _Entry(
    this.title,
    this.subtitle,
    this.component, {
    this.fillPane = false,
  });
}

/// 详情容器页：原生组件 ↔ JS 热更版本同屏对比。
///
/// 普通组件两栏各套滚动容器；[fillPane] 为 true 的整页 demo（自带滚动的
/// CustomScrollView / GridView、Scaffold 根页面）两栏直接铺满，避免嵌套滚动
/// 与无界高度。
///
/// 窄屏（手机）默认只显示 JS 热更版，右上角开关可切到原生组件对照。
class WidgetDetailPage extends StatefulWidget {
  const WidgetDetailPage({
    super.key,
    required this.component,
    this.fillPane = false,
  });

  /// 详情组件名（components 下对应源文件里的 @PatchEntry 类名）。
  final String component;

  /// 整页 demo（自带滚动 / Scaffold 根）：对比时外层不加滚动容器，铺满一栏。
  final bool fillPane;

  @override
  State<WidgetDetailPage> createState() => _WidgetDetailPageState();
}

class _WidgetDetailPageState extends State<WidgetDetailPage> {
  /// 组件名 → 产物入口（`patch/<源文件镜像路径>.js`）。
  ///
  /// 每个组件各自一个源文件，产物路径由 build_runner 镜像源码路径生成
  /// （见 build.yaml 的 patch_entry）。
  static const Map<String, String> _jsEntries = {
    'AnimatedListDetail': 'components/animated_list_detail.js',
    'AssetOverrideDetail': 'components/asset_override_detail.js',
    'AutomaticKeepAliveDetail': 'components/automatic_keep_alive_detail.js',
    'ButtonDetail': 'components/button_detail.js',
    'ColorFilteredDetail': 'components/color_filtered_detail.js',
    'ContainerDetail': 'components/container_detail.js',
    'CustomPaintDetail': 'components/custom_paint_detail.js',
    'DismissibleDetail': 'components/dismissible_detail.js',
    'DialogDetail': 'components/dialog_detail.js',
    'DragDetail': 'components/drag_detail.js',
    'DrawerDetail': 'components/drawer_detail.js',
    'FadeInImageDetail': 'components/fade_in_image_detail.js',
    'FocusDetail': 'components/focus_detail.js',
    'GridDetail': 'components/grid_detail.js',
    'HeroDetail': 'components/hero_detail.js',
    'ImageDetail': 'components/image_detail.js',
    'ImageFilteredDetail': 'components/image_filtered_detail.js',
    'ImageIconDetail': 'components/image_icon_detail.js',
    'InputDetail': 'components/input_detail.js',
    'KeyDetail': 'components/key_detail.js',
    'KeyboardListenerDetail': 'components/keyboard_listener_detail.js',
    'LayoutDetail': 'components/layout_detail.js',
    'LayoutMoreDetail': 'components/layout_more_detail.js',
    'ListViewDetail': 'components/list_view_detail.js',
    'MediaQueryDetail': 'components/media_query_detail.js',
    'MethodChannelDetail': 'components/method_channel_detail.js',
    'NestedScrollViewDetail': 'components/nested_scroll_view_detail.js',
    'NotifierCard': 'components/notifier_card.js',
    'OrientationBuilderDetail': 'components/orientation_builder_detail.js',
    'OverlayDetail': 'components/overlay_detail.js',
    'OverlayPortalDetail': 'components/overlay_portal_detail.js',
    'PageViewDetail': 'components/page_view_detail.js',
    'PopScopeDetail': 'components/pop_scope_detail.js',
    'PreferredSizeDetail': 'components/preferred_size_detail.js',
    'ProgressDetail': 'components/progress_detail.js',
    'RadioGroupDetail': 'components/radio_group_detail.js',
    'ReorderListDetail': 'components/reorder_list_detail.js',
    'SafeAreaDetail': 'components/safe_area_detail.js',
    'ScaffoldDetail': 'components/scaffold_detail.js',
    'ScrollDetail': 'components/scroll_detail.js',
    'SliverDetail': 'components/sliver_detail.js',
    'SliverFillViewportDetail': 'components/sliver_fill_viewport_detail.js',
    'SliverFillRemainingDetail': 'components/sliver_fill_remaining_detail.js',
    'SliverPersistentHeaderDetail':
        'components/sliver_persistent_header_detail.js',
    'SpacerDetail': 'components/spacer_detail.js',
    'StatelessCard': 'components/stateless_card.js',
    'TabDetail': 'components/tab_detail.js',
    'TextDetail': 'components/text_detail.js',
    'TimetablePickerDetail': 'components/timetable_picker_detail.js',
    'VisibilityDetail': 'components/visibility_detail.js',
    'TweenAnimationBuilderDetail':
        'components/tween_animation_builder_detail.js',
    'ValueListenableBuilderDetail':
        'components/value_listenable_builder_detail.js',
    'RichTextDetail': 'components/rich_text_detail.js',
    'ImplicitAnimationDetail': 'components/implicit_animation_detail.js',
    'ExplicitAnimationDetail': 'components/explicit_animation_detail.js',
    // 基础语法 demo（每个语法一个源文件，产物镜像源文件路径）：
    'MixinDetail': 'grammar/mixin_detail.js',
    'ExtensionDetail': 'grammar/extension_detail.js',
    'InheritanceDetail': 'grammar/inheritance_detail.js',
    'BasicApiDetail': 'grammar/basic_api_detail.js',
    'EnumDetail': 'grammar/enum_detail.js',
    'ConstructorDetail': 'grammar/constructor_detail.js',
    'NullSafetyDetail': 'grammar/null_safety_detail.js',
    'PatternDetail': 'grammar/pattern_detail.js',
    'RecordDetail': 'grammar/record_detail.js',
    'OperatorDetail': 'grammar/operator_detail.js',
    'CallableDetail': 'grammar/callable_detail.js',
    'FunctionDetail': 'grammar/function_detail.js',
    'ExpressionDetail': 'grammar/expression_detail.js',
    'StatementDetail': 'grammar/statement_detail.js',
    'CollectionDetail': 'grammar/collection_detail.js',
    'AsyncDetail': 'grammar/async_detail.js',
    'GeneratorDetail': 'grammar/generator_detail.js',
    'StreamDetail': 'grammar/stream_detail.js',
    'GenericDetail': 'grammar/generic_detail.js',
    'AliasDetail': 'grammar/alias_detail.js',
    'CycleImportDetail': 'grammar/cycle_import_detail.js',
    'ArrayDetail': 'grammar/array_detail.js',
    'MapDetail': 'grammar/map_detail.js',
  };

  String get _jsEntry => _jsEntries[widget.component]!;

  /// 拼接补丁 URL（地址由 patch_config 按 debug / release 选择）。
  String get _jsAsset => patchUrl(widget.component, _jsEntry);

  Widget _native() {
    return switch (widget.component) {
      'TextDetail' => const TextDetail(),
      'RichTextDetail' => const RichTextDetail(),
      'TimetablePickerDetail' => const TimetablePickerDetail(),
      'ButtonDetail' => const ButtonDetail(),
      'LayoutDetail' => const LayoutDetail(),
      'ImageDetail' => const ImageDetail(),
      'ContainerDetail' => const ContainerDetail(),
      'CustomPaintDetail' => const CustomPaintDetail(),
      'ScrollDetail' => const ScrollDetail(),
      'AnimatedListDetail' => const AnimatedListDetail(),
      'AssetOverrideDetail' => const AssetOverrideDetail(),
      'AutomaticKeepAliveDetail' => const AutomaticKeepAliveDetail(),
      'ColorFilteredDetail' => const ColorFilteredDetail(),
      'DismissibleDetail' => const DismissibleDetail(),
      'DialogDetail' => const DialogDetail(),
      'DragDetail' => const DragDetail(),
      'FadeInImageDetail' => const FadeInImageDetail(),
      'FocusDetail' => const FocusDetail(),
      'HeroDetail' => const HeroDetail(),
      'ImageFilteredDetail' => const ImageFilteredDetail(),
      'ImageIconDetail' => const ImageIconDetail(),
      'KeyboardListenerDetail' => const KeyboardListenerDetail(),
      'LayoutMoreDetail' => const LayoutMoreDetail(),
      'ListViewDetail' => const ListViewDetail(),
      'MediaQueryDetail' => const MediaQueryDetail(),
      'MethodChannelDetail' => const MethodChannelDetail(channelTag: '_native'),
      'NestedScrollViewDetail' => const NestedScrollViewDetail(),
      'OrientationBuilderDetail' => const OrientationBuilderDetail(),
      'OverlayDetail' => const OverlayDetail(),
      'OverlayPortalDetail' => const OverlayPortalDetail(),
      'PopScopeDetail' => const PopScopeDetail(),
      'PreferredSizeDetail' => const PreferredSizeDetail(),
      'RadioGroupDetail' => const RadioGroupDetail(),
      'SafeAreaDetail' => const SafeAreaDetail(),
      'SliverFillViewportDetail' => const SliverFillViewportDetail(),
      'SliverFillRemainingDetail' => const SliverFillRemainingDetail(),
      'SliverPersistentHeaderDetail' => const SliverPersistentHeaderDetail(),
      'SpacerDetail' => const SpacerDetail(),
      'VisibilityDetail' => const VisibilityDetail(),
      'TweenAnimationBuilderDetail' => const TweenAnimationBuilderDetail(),
      'ValueListenableBuilderDetail' => const ValueListenableBuilderDetail(),
      'ReorderListDetail' => const ReorderListDetail(),
      'SliverDetail' => const SliverDetail(),
      'GridDetail' => const GridDetail(),
      'KeyDetail' => const KeyDetail(),
      'ScaffoldDetail' => const ScaffoldDetail(),
      'DrawerDetail' => const DrawerDetail(),
      'TabDetail' => const TabDetail(),
      'PageViewDetail' => const PageViewDetail(),
      'InputDetail' => const InputDetail(),
      'ProgressDetail' => const ProgressDetail(),
      'NotifierCard' => const NotifierCard(),
      'StatelessCard' => const StatelessCard(
        title: 'Hello Stateless',
        subtitle: '原生直接渲染，无需 State',
        badge: 'FLUTTER',
      ),
      'ImplicitAnimationDetail' => const ImplicitAnimationDetail(),
      'ExplicitAnimationDetail' => const ExplicitAnimationDetail(),
      'MixinDetail' => const MixinDetail(),
      'ExtensionDetail' => const ExtensionDetail(),
      'InheritanceDetail' => const InheritanceDetail(),
      'BasicApiDetail' => const BasicApiDetail(),
      'EnumDetail' => const EnumDetail(),
      'ConstructorDetail' => const ConstructorDetail(),
      'NullSafetyDetail' => const NullSafetyDetail(),
      'PatternDetail' => const PatternDetail(),
      'RecordDetail' => const RecordDetail(),
      'OperatorDetail' => const OperatorDetail(),
      'CallableDetail' => const CallableDetail(),
      'FunctionDetail' => const FunctionDetail(),
      'ExpressionDetail' => const ExpressionDetail(),
      'StatementDetail' => const StatementDetail(),
      'CollectionDetail' => const CollectionDetail(),
      'AsyncDetail' => const AsyncDetail(),
      'GeneratorDetail' => const GeneratorDetail(),
      'StreamDetail' => const StreamDetail(),
      'GenericDetail' => const GenericDetail(),
      'AliasDetail' => const AliasDetail(),
      'CycleImportDetail' => const CycleImportDetail(),
      'ArrayDetail' => const ArrayDetail(),
      'MapDetail' => const MapDetail(),
      _ => const Text('未知组件'),
    };
  }

  /// JS 热更侧构造参数：只有依赖构造参数的组件（如 StatelessCard 的
  /// title/subtitle/badge）需要在此传入；StatefulWidget 的初始状态
  /// 硬编码在 JS 构造函数里，不需要传 props。
  Map<String, dynamic> _jsProps() {
    return switch (widget.component) {
      'StatelessCard' => const {
        'title': 'Hello Stateless',
        'subtitle': '原生直接渲染，无需 State',
        'badge': 'FLUTTER',
      },
      // Hero 两侧必须在同一路由里用**不同 tag**（同 tag 会触发重复 Hero 断言）。
      'HeroDetail' => const {'tag': 'hero-js', 'label': 'JS 热更 Hero'},
      // EventChannel：同名平台通道只能有一个活跃流，原生 / JS 两栏各用独立 channel 名。
      'MethodChannelDetail' => const {'channelTag': '_js'},
      _ => const {},
    };
  }

  @override
  Widget build(BuildContext context) {
    // 宽屏左右双栏 / 窄屏单栏 + 标题栏切换，统一由 ComparePane 提供；
    // 本页只负责「组件名 → 原生实例 / JS 产物路径 / JS 构造参数」这三张表。
    return ComparePane(
      title: widget.component,
      left: _native(),
      right: JsUiWidget(jsAsset: _jsAsset, params: _jsProps()),
      fillPane: widget.fillPane,
    );
  }
}
