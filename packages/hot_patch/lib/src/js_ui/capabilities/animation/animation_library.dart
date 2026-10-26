// ===== 能力：动画 =====
//
// 三部分内聚在本目录：
//   - [animationJsSource]：JS 侧值类（Duration / Size / Offset / Radius）、
//     Curve 名字表、Tween / CurvedAnimation、AnimationController 镜像；
//   - [ensureAnimationChannels]：AnimationController 句柄桥（`ctrl/Flash`）；
//   - [registerAnimationWidgets]：隐式动画 / 过渡动画的宿主映射。
import '../../js_widget_registry.dart';
import '../js_ui_library.dart';
import 'animation_bridge.dart';
import 'animation_js.dart';

/// 动画能力接入声明。
class AnimationLibrary extends JsUiLibrary {
  const AnimationLibrary();

  @override
  String get id => 'animation';

  @override
  List<String> get jsFragments => const [animationJsSource];

  @override
  void ensureChannels() => ensureAnimationChannels();

  @override
  void registerWidgets(JsWidgetRegistry r) => registerAnimationWidgets(r);
}
