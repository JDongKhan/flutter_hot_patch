// ===== 能力：Key 句柄桥 =====
//
// Key 是**值**（元素 props 的 `key`），不是结点：JS 侧由 capabilities/key_js.dart
// 的代理类产出，随 props 序列化下发（`{__vkey:…}` / `{__okey:…}` / `{__handle:…}`），
// 宿主在渲染结点时还原成真实 Flutter Key（见 js_ui_widget 的 _JsNodeState）。
//
// 与 ScrollController 共用同一套通用句柄层（capabilities/handle_registry.dart）：
//   - GlobalKey / UniqueKey：JS 侧 `reg(this, 'key/Global'|'key/Unique')` 登记，
//     通用通道 `jsHandle` 的 create 落到本文件描述符 → 创建**真实** GlobalKey() /
//     UniqueKey() 并按句柄 id 复用（GlobalKey 身份跨帧稳定）；scope=page，页面
//     销毁随句柄释放（onRelease 摘除映射）。
//   - ValueKey / ObjectKey：不登记句柄（纯值），宿主按值现造——
//     Flutter 的 ValueKey 相等即**值**相等，无需映射表（否则每次 build 都造新
//     实例，表会无限增长）；ObjectKey 跨语言保不住对象同一性，用身份 token 的
//     字符串等价复现（同一对象 token 相同、不同对象不同）。
import 'package:flutter/widgets.dart';

import 'handle_registry.dart';

/// 句柄 id → 宿主侧真实 Key（GlobalKey / UniqueKey）。页面销毁时由句柄释放摘除。
final Map<String, Key> _jsKeys = {};

bool _keyKindRegistered = false;

/// 幂等注册 Key 句柄 kind（由 js_ui_capabilities.ensureJsUiCapabilities 聚合调用）。
void ensureKeyChannels() {
  if (_keyKindRegistered) return;
  _keyKindRegistered = true;
  registerHandleKind('key/Global', JsHandleKind(
    onCreate: (id, meta) {
      // putIfAbsent：create 消息与首帧渲染（props 里的 key）到达顺序不定，
      // 同一句柄 id 必须始终对应同一个 GlobalKey 实例（换实例即丢 State）。
      _jsKeys.putIfAbsent(id, () => GlobalKey(debugLabel: _labelOf(meta)));
    },
    onRelease: (id) => _jsKeys.remove(id),
  ));
  registerHandleKind('key/Unique', JsHandleKind(
    onCreate: (id, meta) => _jsKeys.putIfAbsent(id, () => UniqueKey()),
    onRelease: (id) => _jsKeys.remove(id),
  ));
}

String? _labelOf(Object? meta) {
  final label = meta is Map ? meta['debugLabel'] : null;
  return label is String && label.isNotEmpty ? label : null;
}

/// 结点 props 里的序列化 key → 宿主真实 Key；无法识别（缺 key / 句柄已释放）
/// 返回 null，调用方退回 `ValueKey(结点 id)`（见 js_ui_widget）。
Key? jsKeyOf(Object? prop) {
  if (prop is! Map) return null;
  // ValueKey(对象值)：跨语言保不住对象同一性，JS 侧序列化成身份 token（与
  // Dart 的 `==` 对 Map/List 即同一性一致），这里用 token 串等价复现。
  final vtok = prop['__vtok'];
  if (vtok != null) return ValueKey<String>('vo:$vtok');
  if (prop.containsKey('__vkey')) return ValueKey<Object?>(prop['__vkey']);
  final okey = prop['__okey'];
  // ObjectKey：身份 token 串等价复现（Dart 侧 identical 语义，见文件头）。
  if (okey != null) return ValueKey<String>('ok:$okey');
  final handle = prop['__handle'];
  if (handle is String) return _jsKeys[handle];
  return null;
}
