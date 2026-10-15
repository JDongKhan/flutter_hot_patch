// ===== 能力：Listenable 响应式组件的宿主映射 =====
//
// `ListenableBuilder` / `ValueListenableBuilder` 都是 Flutter SDK 的**通用**
// Listenable 消费者（与 provider 无关），故归本能力（change_notifier）：
//   - JS 侧组件类订阅模型、notify 时只重建本结点子树（UI 更新源）；
//   - 宿主侧把这段子树包成 Dart 的监听边界——notify 只重建该子树（P2 粒度）。
//
// **为什么不用 Flutter 原生的 ValueListenableBuilder**：宿主侧的 [JsVm] 是
// ChangeNotifier 镜像（不是 ValueListenable），故两类组件共用同一个
// `ListenableBuilder` 边界即可——两者对宿主的要求完全相同（订阅 + 重建子树），
// 与 `value` 是否参与宿主 builder 无关（builder 由 JS 侧持有并已展开子树）。
import 'package:flutter/widgets.dart';

import '../../js_widget_registry.dart';
import 'vm_bridge.dart';

/// 注册 Listenable 响应式组件的宿主映射。
void registerListenableWidgets(JsWidgetRegistry r) {
  r.register('ListenableBuilder', (c) => listenableBoundary(c));
  r.register('ValueListenableBuilder', (c) => listenableBoundary(c));
}

/// 把一段 JS 子树包成 Dart 的监听边界：结点 props 的 `vm`（`{__handle:id}`）
/// 取到通用镜像就订阅它，notify 只重建 `c.child()` 那段子树。
///
/// **共用实现**：provider 的 `Consumer` 与这里的两个组件对宿主的要求完全相同
/// （订阅 + 重建子树），故对外公开、由 provider_bridge 复用一份。
Widget listenableBoundary(JsRenderContext c) {
  final subtree = c.child() ?? const SizedBox.shrink();
  final vm = jsVmOfProp(c.props['vm']);
  if (vm == null) return subtree;
  return ListenableBuilder(
    listenable: vm,
    builder: (context, child) => child ?? const SizedBox.shrink(),
    child: subtree,
  );
}

/// 结点 props 里的 VM（JS 侧 `toJSON` 成 `{__handle:id}`）→ Dart 侧的通用镜像。
JsVm? jsVmOfProp(Object? prop) {
  if (prop is! Map) return null;
  final id = prop['__handle'];
  return id is String ? jsVmOf(id) : null;
}
