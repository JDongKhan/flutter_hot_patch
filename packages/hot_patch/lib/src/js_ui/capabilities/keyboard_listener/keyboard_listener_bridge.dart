// ===== 能力：KeyboardListener（原始按键事件）=====
//
// KeyboardListener 的**焦点 / 事件分发**全在宿主侧，JS 侧只负责接收事件：
//   - 值：`autofocus`；`focusNode` 是 FocusNode 句柄（复用 focus 能力的同一条
//     句柄桥，真实节点由 JS 侧 `new FocusNode(...)` 下发 meta 创建）；
//   - 子树：`child`；
//   - 事件：`onKeyEvent(KeyEvent)`。
//
// 事件的坑在**形态**：KeyEvent 是类实例（`logicalKey` / `character` /
// `isKeyDownEvent`），`__jsui.invoke` 只传 JSON，因此由宿主把原生 KeyEvent
// 归一成 JSON，交给 JS 侧 `__jsuiKeyEvent` 还原成实例再调句柄（JS 片段见
// 生成器 keyboard_listener_js.dart）。`LogicalKeyboardKey` 在 JS 侧按 keyId
// 归一成同一实例，`event.logicalKey == LogicalKeyboardKey.enter` 等比较与
// Dart 一比一。
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show KeyDownEvent, KeyRepeatEvent;

import '../../../services/js_runtime_manager.dart';
import '../../js_widget_registry.dart';
import '../core/controller_bridge.dart';
import '../focus/focus_bridge.dart';

/// 原生 KeyEvent → JSON（JS 侧 `__jsuiKeyEvent` 还原成 KeyEvent 实例）。
Map<String, Object?> _keyEventJson(KeyEvent event) {
  final kind = event is KeyDownEvent
      ? 'down'
      : event is KeyRepeatEvent
          ? 'repeat'
          : 'up';
  return {
    'kind': kind,
    'character': event.character,
    'timeStampUs': event.timeStamp.inMicroseconds,
    'logicalKeyId': event.logicalKey.keyId,
    'logicalKeyLabel': event.logicalKey.keyLabel,
    'physicalKeyUsb': event.physicalKey.usbHidUsage,
    'physicalKeyLabel': event.physicalKey.debugName,
  };
}

/// 把一次按键发给 JS 事件句柄（[handler] 是 `{'__fn': id}` 形态）。
///
/// args 与 invoke 相同：内层 JSON 文本，外层字符串字面量。
void _dispatchKeyEvent(Object? handler, KeyEvent event) {
  final id = handler is Map ? handler['__fn'] : null;
  if (id is! String) return;
  JsRuntimeManager.instance.evaluate(
    '__jsuiKeyEvent(${jsonEncode(id)}, ${jsonEncode(jsonEncode(_keyEventJson(event)))});',
  );
}

/// JS 侧漏传 `focusNode` 时的兜底节点（单例，避免每次 build 残留未释放的监听）。
final FocusNode _fallbackNode = FocusNode(debugLabel: 'keyboard-listener');

/// KeyboardListener 能力：宿主组件注册。
void registerKeyboardListenerWidgets(JsWidgetRegistry r) {
  r.register('KeyboardListener', (c) {
    final handler = c.props['onKeyEvent'];
    final autofocus = c.bool_('autofocus') ?? false;
    final child = (c.children['child'] as Widget?) ?? const SizedBox.shrink();

    // Dart 侧 `focusNode` 是 `required`（非空）。JS 侧漏传句柄时用单例兜底节点：
    // 每次 build 新建 FocusNode 会残留未释放的监听，单例不会。
    Widget build(FocusNode node) => KeyboardListener(
          focusNode: node,
          autofocus: autofocus,
          // Dart 侧回调可空，未传时传 null（不伪造事件处理）。
          onKeyEvent: handler == null
              ? null
              : (event) => _dispatchKeyEvent(handler, event),
          child: child,
        );

    final id = JsControllerBridge.idOf(c.props['focusNode']);
    if (id == null) return build(_fallbackNode);
    return JsControllerHost<FocusNode>(
      bridge: focusNodeBridge,
      id: id,
      create: () => FocusNode(),
      // 与 Focus 同一套回传：JS 侧 FocusNode 镜像的 hasFocus 保持准确
      // （`node.hasFocus` / addListener 在 KeyboardListener 里同样可用）。
      forward: (node, fn) => c.invoke(fn, [node.hasFocus]),
      buildChild: build,
    );
  });
}
