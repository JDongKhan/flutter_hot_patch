// ===== 自定义组件能力：VisibilityDetector =====
//
// 接入方式（完全不改 dynamic_flutter 包）：
//   - 子类在 [registerWidgets] 里登记 `type → Flutter widget`；
//   - App 在 `main()` 的 runApp 之前 `registerJsUiLibrary(...)`。
//
// 可见性判定在宿主侧（render object + 帧间通知），JS 侧只接收回传；实现见
// custom_visibility_detector_bridge.dart。
import 'package:dynamic_flutter/dynamic_flutter.dart';

import 'custom_visibility_detector_bridge.dart';

/// VisibilityDetector 自定义能力接入声明。
class CustomVisibilityDetectorLibrary extends JsUiLibrary {
  const CustomVisibilityDetectorLibrary();

  @override
  String get id => 'visibility_detector';

  @override
  void registerWidgets(JsWidgetRegistry r) =>
      registerVisibilityDetectorWidgets(r);
}
