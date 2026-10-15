// ===== 能力：JS VM（ChangeNotifier）通用镜像 =====
//
// 与 capabilities/../../js/js/change_notifier_js.dart **对称**：模型的真实对象
// 只存在于 JS 端（`class CounterVm extends ChangeNotifier`），宿主侧按句柄 id
// 持一个**通用** ChangeNotifier 镜像——它不认识任何具体业务类，只做两件事：
//   1. **记下它的 JS 端类型**（meta.type，即 JS 侧类名）——`context.watch<T>()`
//      的类型实参一路传下来，Dart 侧据此在 VM 树上按类型查找；
//   2. 收到 JS 侧 `notify` op 时 `notifyListeners()` ——驱动 Dart 侧
//      `ChangeNotifierProvider` 子树刷新（P2：重建粒度为 provider 子树）。
//
// 为什么镜像必须存在：Dart 端 `ChangeNotifierProvider` 需要真实的 Listenable
// 才能工作（否则 FutureBuilder/InheritedNotifier 无从订阅）。JS 侧的
// notifyListeners 走**双路**派发：本端 `_listeners`（JS 逻辑）+ 本通道（Dart UI）。
import 'package:flutter/foundation.dart';

import '../core/handle_registry.dart';

/// 句柄 id → Dart 侧的通用 VM 镜像（与 JS 对象 1:1）。
final Map<String, JsVm> _jsVms = {};

bool _vmKindRegistered = false;

/// JS 侧 VM 在宿主侧的**通用**镜像。
///
/// 不是业务类：只承载「类型名 + 通知」两件事，故新增任何 VM 都不需要动宿主。
class JsVm extends ChangeNotifier {
  JsVm(this.jsType, this.jsHandle);

  /// JS 侧类名（如 `CounterVm`）——`context.watch<T>()` 的 `T`。
  final String jsType;

  /// JS 侧对象的句柄 id（`js:vm/ChangeNotifier#N`）。
  final String jsHandle;

  /// JS 侧 `notifyListeners` 的第二路入口（跨语言桥调用）。
  /// `notifyListeners` 是 protected，只有子类内部能调，故在这里开一个内部门。
  void notifyFromJs() => notifyListeners();

  @override
  String toString() => 'JsVm($jsType, $jsHandle)';
}

/// 幂等注册 VM 句柄 kind（由 js_ui_capabilities.ensureJsUiCapabilities 聚合调用）。
void ensureVmChannels() {
  if (_vmKindRegistered) return;
  _vmKindRegistered = true;
  registerHandleKind('vm/ChangeNotifier', JsHandleKind(
    onCreate: (id, meta) {
      final type = (meta is Map ? meta['type'] : null);
      _jsVms[id] = JsVm(
        type is String && type.isNotEmpty ? type : 'ChangeNotifier',
        id,
      );
    },
    onOp: (id, op, payload) {
      if (op == 'notify') {
        // JS 侧 notifyListeners 的第二路：镜像转发给 Dart 侧订阅者。
        // 已被释放（页面卸载竞态）时静默丢弃。
        _jsVms[id]?.notifyFromJs();
      }
      return null;
    },
    onRelease: (id) {
      final vm = _jsVms.remove(id);
      vm?.dispose();
    },
  ));
}

/// 按句柄 id 取 Dart 侧通用 VM 镜像；未登记/已释放返回 null。
JsVm? jsVmOf(String id) => _jsVms[id];
