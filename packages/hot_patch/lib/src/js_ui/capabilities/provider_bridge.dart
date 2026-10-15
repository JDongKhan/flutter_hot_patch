// ===== 能力：provider 宿主映射（ChangeNotifierProvider / Consumer / ListenableBuilder）=====
//
// provider 的**状态与订阅**全部下沉到 Dart 侧：
//   - JS 端 `ChangeNotifierProvider` 只负责造/取 VM，然后把宿主结点
//     `ChangeNotifierProvider {model, vm}` 交给宿主（见 ui_component_generator
//     的 widget_module_builder）——JS 侧不再有 `__provides` 之类的提供者记账；
//   - JS 端 `context.watch<T>()` 只是「沿 `__parent` 找最近的 provider 宿主结点
//     取 VM 实例」+ 用原生 `vm.addListener` 订阅（UI 更新仍由 JS 侧重建产生，
//     这是同步取值约束决定的、无法消除的一步）。
//
// 宿主侧映射的职责：把 JS 下发的 `{model, vm 句柄}` 还原成真实的 Dart
// provider 子树——VM 是 capabilities/vm_bridge.dart 的**通用镜像**（不认识业务
// 类，只记 JS 端类型 + 转发 notify）。
//
// **刻意不依赖 `provider` 包**：宿主映射用 Flutter 内建的 InheritedNotifier
// 实现等价语义，基座不绑定第三方版本；将来若要换成真正的 `provider`，只需把
// 下面三个 renderer 的实现替换掉，扩展点（宿主 type 名）不变。
import 'package:flutter/widgets.dart';

import '../js_widget_registry.dart';
import 'vm_bridge.dart';

/// 宿主侧 `ChangeNotifierProvider` 的映射实现。
///
/// `InheritedNotifier` 自带「notifier 变更 → 依赖者重建」语义，等价于
/// provider 包的 `ChangeNotifierProvider`（提供者结点 + 依赖通知）。Dart 侧
/// 消费者用 [JsVmProvider.maybeOf] 建立依赖，VM notify 时只重建该子树。
class JsVmProvider extends InheritedNotifier<JsVm> {
  const JsVmProvider({super.key, required JsVm vm, required super.child})
      : super(notifier: vm);

  /// 取祖先最近的 VM（Dart 侧消费者用；JS 侧 consumer 走 findVm，不经过这里）。
  static JsVm? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<JsVmProvider>()?.notifier;
}

/// 注册 provider 宿主映射（由 js_ui_capabilities.registerAllJsWidgets 聚合调用）。
void registerProviderWidgets(JsWidgetRegistry r) {
  // 提供者结点：JS 已把 create/value 解析成 VM，宿主只做映射。
  // VM 句柄取不到（JS 侧未登记/已释放）时退化为纯透传，不阻断渲染。
  r.register('ChangeNotifierProvider', (c) {
    final child = c.child() ?? const SizedBox.shrink();
    final vm = jsVmOfProp(c.props['vm']);
    if (vm == null) return child;
    return JsVmProvider(vm: vm, child: child);
  });

  // Consumer / ListenableBuilder：JS 侧决定「哪个 VM、哪段子树」，宿主侧把这段
  // 子树包成 Dart 的监听边界（notify 只重建该子树，即 P2 的重建粒度）。
  r.register('Consumer', (c) => _listenBoundary(c));
  r.register('ListenableBuilder', (c) => _listenBoundary(c));
}

Widget _listenBoundary(JsRenderContext c) {
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
