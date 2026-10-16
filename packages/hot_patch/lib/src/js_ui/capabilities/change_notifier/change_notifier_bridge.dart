// ===== 能力：JS 侧 ChangeNotifier 的宿主镜像 =====
//
// 与 capabilities/change_notifier/change_notifier_js.dart **对称**：模型的真实对象
// 只存在于 JS 端（`class CounterVm extends ChangeNotifier`），宿主侧按句柄 id
// 持一个**通用** ChangeNotifier 镜像——它不认识任何具体业务类，只做两件事：
//   1. **记下它的 JS 端类型**（meta.type，即 JS 侧类名）——`context.watch<T>()`
//      的类型实参一路传下来，Dart 侧据此按类型查找（见 provider_bridge.dart）；
//   2. 收到 JS 侧 `notify` op 时 `notifyListeners()` ——驱动 Dart 侧
//      `ChangeNotifierProvider` 子树刷新（P2：重建粒度为 provider 子树）。
//
// 为什么镜像必须存在：Dart 端 `ChangeNotifierProvider` 需要真实的 Listenable
// 才能工作（否则 InheritedNotifier 无从订阅）。JS 侧的 notifyListeners 走
// **双路**派发：本端 `_listeners`（JS 逻辑）+ 本通道（Dart UI）。
import 'package:flutter/foundation.dart';

import '../core/controller_bridge.dart';

/// JS 侧 ChangeNotifier 实例在宿主侧的**通用**镜像。
///
/// 不是业务类：只承载「类型名 + 通知」两件事，故新增任何模型（含 ValueNotifier
/// 这类 SDK 子类）都不需要动宿主。
class JsChangeNotifier extends ChangeNotifier {
  JsChangeNotifier(this.jsType, this.jsHandle);

  /// JS 侧类名（如 `CounterVm`）——`context.watch<T>()` 的 `T`。
  final String jsType;

  /// JS 侧对象的句柄 id（`js:notifier/ChangeNotifier#N`）。
  final String jsHandle;

  /// JS 侧 `notifyListeners` 的第二路入口（跨语言桥调用）。
  /// `notifyListeners` 是 protected，只有子类内部能调，故在这里开一个内部门。
  void notifyFromJs() => notifyListeners();

  @override
  String toString() => 'JsChangeNotifier($jsType, $jsHandle)';
}

/// ChangeNotifier 镜像桥（通用层见 capabilities/core/controller_bridge.dart）：
/// 只用 controllers 一张表——无回传句柄 / Host（镜像被 Dart 侧订阅，方向与
/// 控制器相反：JS notify → 宿主镜像 notifyListeners → Dart 子树刷新）。
///
/// 句柄 kind 字符串 `notifier/ChangeNotifier` 是**双端协议**（JS 片段
/// change_notifier_js.dart 里 `reg(this, 'notifier/ChangeNotifier', …)` 与之
/// 配对），改动须两端同时改并重产 patch。
final JsControllerBridge<JsChangeNotifier> _notifierBridge =
    JsControllerBridge<JsChangeNotifier>(
  kind: 'notifier/ChangeNotifier',
  create: (id, meta) {
    final type = meta is Map ? meta['type'] : null;
    return JsChangeNotifier(
      type is String && type.isNotEmpty ? type : 'ChangeNotifier',
      id,
    );
  },
  onOp: (notifier, op, payload) {
    // JS 侧 notifyListeners 的第二路：镜像转发给 Dart 侧订阅者。
    // 已被释放（页面卸载竞态）时通用层按 id 解不出镜像，静默丢弃。
    if (op == 'notify') notifier.notifyFromJs();
    return null;
  },
);

/// 幂等注册 ChangeNotifier 句柄 kind（由各能力的 `ensureChannels()` 聚合调用，
/// 见 change_notifier_library.dart）。
void ensureChangeNotifierChannels() => _notifierBridge.ensure();

/// 按句柄 id 取 Dart 侧通用镜像；未登记/已释放返回 null。
JsChangeNotifier? jsChangeNotifierOf(String id) => _notifierBridge.controllers[id];
