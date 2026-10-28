// ===== 能力：MediaQuery =====
//
// 纯宿主侧能力：无句柄 kind、无 JS 片段（JS 侧片段随运行时产物发布，见生成器
// media_query_js.dart），只把 `mediaQuery` 这个 context op 注册进核心的分发缝
// —— JS 的 `MediaQuery.of(context)` 等经它与 Flutter 的 `MediaQuery.of` 对齐。
import '../js_ui_library.dart';
import 'media_query_bridge.dart';

/// MediaQuery 能力接入声明。
class MediaQueryLibrary extends JsUiLibrary {
  const MediaQueryLibrary();

  @override
  String get id => 'media_query';

  @override
  void ensureChannels() => ensureMediaQueryContextOps();
}
