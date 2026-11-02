// 能力接入：CustomPaint（宿主渲染 + JS 绘制录制重放）。
//
// 无需句柄 kind：painter 句柄以 `sync:false` 登记，宿主只按 id 同步求值
// `__record`，不创建真实对象（见生成器 canvas_js.dart / canvas_bridge.dart）。
import '../../js_widget_registry.dart';
import '../js_ui_library.dart';
import 'canvas_bridge.dart';

class CanvasLibrary extends JsUiLibrary {
  const CanvasLibrary();

  @override
  String get id => 'canvas';

  @override
  void registerWidgets(JsWidgetRegistry r) => registerCanvasWidgets(r);
}
