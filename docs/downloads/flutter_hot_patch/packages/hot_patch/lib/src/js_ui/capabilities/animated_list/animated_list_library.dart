// ===== 能力：AnimatedList =====
import '../../js_widget_registry.dart';
import '../js_ui_library.dart';
import 'animated_list_bridge.dart';

/// AnimatedList 能力接入声明。
class AnimatedListLibrary extends JsUiLibrary {
  const AnimatedListLibrary();

  @override
  String get id => 'animated-list';

  @override
  void registerWidgets(JsWidgetRegistry r) => registerAnimatedListWidgets(r);
}
