// ===== 能力：ScrollController 代理 =====
//
// 与 capabilities/scroll_controller/ 的桥接表同一能力域：JS 片段（代理类）走
// [jsFragments]，句柄通道走 [ensureChannels]，宿主组件（ListView / GridView /
// SingleChildScrollView 等）走 [registerWidgets]。
import '../../js_widget_registry.dart';
import '../js_ui_library.dart';
import 'scroll_controller_bridge.dart';
import 'scroll_controller_js.dart';

/// ScrollController 能力接入声明。
class ScrollControllerLibrary extends JsUiLibrary {
  const ScrollControllerLibrary();

  @override
  String get id => 'scroll-controller';

  @override
  List<String> get jsFragments => const [scrollControllerJsSource];

  @override
  void ensureChannels() => ensureScrollControllerChannels();

  @override
  void registerWidgets(JsWidgetRegistry r) => registerScrollWidgets(r);

  /// 子项尺寸由**容器强制**、零尺寸占位布局中性的滚动容器（子项可延迟到
  /// 宿主 inflate 时才挂载 → initState 与 Flutter 一致）：
  ///   - PageView / SliverFillViewport：子项被强制成 视口×`viewportFraction`；
  ///   - GridView / SliverGrid：子项被格尺寸强制（按 delegate 参数算出）；
  ///   - SliverFixedExtentList / ListView(itemExtent:)：`itemExtent` 强制。
  ///
  /// **不在此列**：按内容量尺寸的 `ListView`（无 itemExtent）/ `SliverList` /
  /// `ReorderableListView`（零尺寸占位会让视口把全部 item 判可见，懒加载反而
  /// 失效）；`CustomScrollView`（它的 sliver 子项 Flutter 本来就全部 inflate）。
  @override
  Map<String, List<String>> get lazyChildHostTypes => const {
        'PageView': [],
        'GridView': [],
        'SliverGrid': [],
        'SliverFixedExtentList': [],
        'SliverFillViewport': [],
        // 只有带 itemExtent 时才懒：那时子项尺寸才被容器强制
        //（`ListView.separated` 在 SDK 里不接受 itemExtent → 该 props 只可能
        // 来自普通/`.builder` 形态，故按「带 itemExtent 即懒」判定是安全的）。
        'ListView': ['itemExtent'],
      };
}
