// ===== 能力：Focus（焦点控制）=====
//
// Focus / FocusNode 分两层：
//   - **FocusNode**：JS 侧代理类（见生成器 focus_js.dart）经句柄 `ctrl/Focus` 与
//     宿主真实 FocusNode 一一绑定；`requestFocus` / `unfocus` 走通用 op（call），
//     `hasFocus` 读镜像——镜像由宿主 Focus 的 onFocusChange 回传（见下）；
//   - **Focus**：宿主组件注册，`focusNode` 是句柄时用 [JsControllerHost] 绑定
//     真实节点并挂 `addListener` 转发 `hasFocus`，于是 JS 侧
//     `node.addListener(fn)` 能感知焦点变化（与 Dart ChangeNotifier 同语义）。
//
// 与 Dart 一比一：`FocusNode(debugLabel: …)` 的构造参数经句柄 meta 下发到宿主，
// 真实节点属性一致；`Focus(onFocusChange: …)` 是 `ValueChanged<bool>?`，
// 由生成器按**形参类型**识别为事件 → JS 侧拿到的就是 `bool` 实参。
//
// 未映射（超出跨语言表达，宿主按 Flutter 默认值渲染）：
//   - `onKeyEvent`（KeyEvent 值对象）；`focusNode` 的 `skipTraversal` 等
//     运行时可变属性（只在构造时生效，与 Dart 侧一般用法一致）。
import 'package:flutter/material.dart';

import '../../js_widget_registry.dart';
import '../core/controller_bridge.dart';

/// FocusNode 句柄桥：真实节点由 `meta` 里的构造参数创建（请求/失焦走 op）。
final JsControllerBridge<FocusNode> _focusBridge = JsControllerBridge<FocusNode>(
  kind: 'ctrl/Focus',
  create: (_, meta) {
    final m = meta is Map ? meta : const {};
    return FocusNode(
      debugLabel: m['debugLabel']?.toString(),
      skipTraversal: m['skipTraversal'] == true,
      canRequestFocus: m['canRequestFocus'] != false,
      descendantsAreFocusable: m['descendantsAreFocusable'] != false,
    );
  },
  onOp: (node, op, payload) {
    if (op == 'call') {
      final method = payload['method']?.toString() ?? '';
      if (method == 'requestFocus') {
        node.requestFocus();
      } else if (method == 'unfocus') {
        node.unfocus();
      }
    }
    return null;
  },
);

/// 幂等注册 FocusNode 句柄 kind（由 js_ui_capabilities 聚合调用）。
void ensureFocusChannels() => _focusBridge.ensure();

/// Focus 能力：宿主组件注册。
void registerFocusWidgets(JsWidgetRegistry r) {
  r.register('Focus', (c) {
    final child = (c.children['child'] as Widget?) ?? const SizedBox.shrink();
    final onFocusChange = c.on1<bool>('onFocusChange');
    final autofocus = c.bool_('autofocus') ?? false;
    final canRequestFocus = c.bool_('canRequestFocus') ?? true;
    final skipTraversal = c.bool_('skipTraversal') ?? false;
    final descendantsAreFocusable = c.bool_('descendantsAreFocusable') ?? true;
    final descendantsAreTraversable = c.bool_('descendantsAreTraversable') ?? true;

    Widget build(FocusNode? node) => Focus(
      focusNode: node,
      autofocus: autofocus,
      canRequestFocus: canRequestFocus,
      skipTraversal: skipTraversal,
      descendantsAreFocusable: descendantsAreFocusable,
      descendantsAreTraversable: descendantsAreTraversable,
      onFocusChange: onFocusChange,
      child: child,
    );

    final id = JsControllerBridge.idOf(c.props['focusNode']);
    if (id == null) return build(null);
    return JsControllerHost<FocusNode>(
      bridge: _focusBridge,
      id: id,
      create: () => FocusNode(),
      // 焦点变化 → JS 实例镜像 hasFocus → 触发其 addListener 的闭包
      // （与 ScrollController 回传 metrics 同一套 Host 机制）。
      forward: (node, handler) => c.invoke(handler, [node.hasFocus]),
      buildChild: build,
    );
  });
}
