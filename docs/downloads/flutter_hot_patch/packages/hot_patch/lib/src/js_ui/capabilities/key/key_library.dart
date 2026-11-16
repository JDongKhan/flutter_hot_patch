// ===== 能力：Key 代理（值对象）=====
//
// Key 是元素 props 的值，不是结点：JS 片段提供 ValueKey/ObjectKey/UniqueKey/
// GlobalKey 代理类，句柄通道提供「JS 句柄 → 宿主真值 Key」的登记；宿主侧无
// 专属组件注册（key 由核心在建结点时读取）。
import '../js_ui_library.dart';
import 'key_bridge.dart';

/// Key 能力接入声明。
class KeyLibrary extends JsUiLibrary {
  const KeyLibrary();

  @override
  String get id => 'key';

  @override
  void ensureChannels() => ensureKeyChannels();
}
