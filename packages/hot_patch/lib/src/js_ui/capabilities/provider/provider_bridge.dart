// ===== 能力：provider 宿主映射（ChangeNotifierProvider / Consumer）=====
//
// provider 的**状态与订阅**全部下沉到 Dart 侧：
//   - JS 端 `ChangeNotifierProvider` 只负责造/取模型实例，然后把宿主结点
//     `ChangeNotifierProvider {model, notifier}` 交给宿主（见 hot_patch_generator
//     的 widget_module_builder）——JS 侧没有 provider 专用记账，只在结点上按
//     **类型名**声明作用域（`__provides`，注册见 provider_js.dart）；
//   - JS 端 `context.watch<T>()` 只是「按**类型名**沿 `__parent` 向上取最近作用域
//     的值」+ 用原生 `addListener` 订阅（UI 更新仍由 JS 侧重建产生，
//     这是同步取值约束决定的、无法消除的一步）。
//
// 宿主侧映射的职责：把 JS 下发的 `{model, notifier 句柄}` 还原成真实的 Dart
// provider 子树——notifier 是 change_notifier_bridge.dart 的**通用镜像**（不
// 认识业务类，只记 JS 端类型 + 转发 notify）。
//
// **本文件属于三方库层**（provider 的接入实现，见 provider_library.dart），核心
// 不 import 它：核心把 `context.watch/read` 的 op 分发给本库注册的处理器
// （见 context_ops.dart），再经 [jsChangeNotifierOfTypeAt] 按类型名取出「可订阅对象」。
//
// **刻意不依赖 `provider` 包**：宿主映射用 Flutter 内建的 InheritedNotifier
// 实现等价语义，基座不绑定第三方版本；将来若要换成真正的 `provider`，只需把
// 下面三个 renderer 的实现替换掉，扩展点（宿主 type 名）不变。
import 'package:flutter/widgets.dart';

import '../../js_widget_registry.dart';
import '../change_notifier/change_notifier_bridge.dart';
import '../change_notifier/listenable_builder_bridge.dart';

/// 宿主侧 `ChangeNotifierProvider` 的映射实现。
///
/// `InheritedNotifier` 自带「notifier 变更 → 依赖者重建」语义，等价于
/// provider 包的 `ChangeNotifierProvider`（提供者结点 + 依赖通知）。Dart 侧的
/// 消费者用 [maybeOf] 建立依赖，notify 时只重建该子树。
///
/// 生产链路上 JS 的 `context.watch<T>()` 走的是 [jsChangeNotifierOfTypeAt]
/// （**按类型**精确匹配，不能取「最近的那个」）；[maybeOf] 是给**宿主侧 Dart
/// 消费者**用的常规入口（如测试里模拟依赖者、将来宿主 widget 直接消费 JS
/// 提供的模型）。
class JsChangeNotifierProvider extends InheritedNotifier<JsChangeNotifier> {
  const JsChangeNotifierProvider({
    super.key,
    required JsChangeNotifier notifier,
    required super.child,
  }) : super(notifier: notifier);

  /// 取祖先最近的模型镜像（**宿主侧 Dart 消费者**用；JS 侧的 context 走
  /// [jsChangeNotifierOfTypeAt] 按类型精确解析，见 build_context_bridge 的
  /// `context.watch/read` op）。
  static JsChangeNotifier? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<JsChangeNotifierProvider>()
      ?.notifier;
}

/// 在**真实 element 树**上按 JS 端类型名找 provider。
///
/// JS 侧 `context.watch<T>()` / `context.read<T>()` 把 `T` 传下来后，Dart 侧据此
/// 做**权威查找**：从该位置的 `BuildContext` 沿祖先链上溯，取第一个
/// `jsType == type` 的 [JsChangeNotifierProvider]（Dart 侧通用镜像的 `jsType`
/// 记的就是 JS 端类名，见 change_notifier_bridge.dart）。找不到返回 null ——
/// 说明 JS 侧解析出的位置不在该类型 provider 的子树内（消费点被放到了 provider
/// 之外）。
///
/// 为什么不用 [JsChangeNotifierProvider.maybeOf]：它只能取「最近的那个」
/// provider，嵌套了多个不同类型的 provider 时，`watch<A>` 需要的未必是最近的
/// 那个，故必须按 `jsType` 过滤——与 JS 侧的判据一字不差。
JsChangeNotifier? jsChangeNotifierOfTypeAt(BuildContext context, String type) {
  if (context is! Element || !context.mounted) return null;
  JsChangeNotifier? found;
  context.visitAncestorElements((element) {
    final widget = element.widget;
    if (widget is JsChangeNotifierProvider && widget.notifier?.jsType == type) {
      found = widget.notifier;
      return false;
    }
    return true;
  });
  return found;
}

/// 注册 provider 宿主映射（由 js_ui_capabilities.registerAllJsWidgets 聚合调用）。
void registerProviderWidgets(JsWidgetRegistry r) {
  // 提供者结点：JS 已把 create/value 解析成模型实例，宿主只做映射。
  // 句柄取不到（JS 侧未登记/已释放）时退化为纯透传，不阻断渲染。
  r.register('ChangeNotifierProvider', (c) {
    final child = (c.children['child'] as Widget?) ?? const SizedBox.shrink();
    final notifier = jsChangeNotifierOfProp(c.props['notifier']);
    if (notifier == null) return child;
    return JsChangeNotifierProvider(notifier: notifier, child: child);
  });

  // Consumer：JS 侧决定「哪个 ChangeNotifier、哪段子树」，宿主侧把这段子树包成 Dart 的
  // 监听边界（notify 只重建该子树，即 P2 的重建粒度）。
  // 边界实现与 ListenableBuilder / ValueListenableBuilder 共用一份——它们对宿主
  // 的要求完全相同，那两个组件的注册在 change_notifier
  // （见 listenable_builder_bridge.dart）。
  r.register('Consumer', (c) => listenableBoundary(c));
}
