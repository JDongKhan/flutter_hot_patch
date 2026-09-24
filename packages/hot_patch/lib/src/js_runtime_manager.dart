import 'package:flutter_js/flutter_js.dart';

/// JS 运行时管理器：与底层 [JavascriptRuntime] **一对一**。
///
/// 每个 [JsRuntimeManager] 内部持有一个 [JavascriptRuntime]，所有与
/// JavascriptRuntime 相关的操作（创建、求值、通道注册、生命周期）都在
/// 本类内部消化；HotPatchWidget 等使用方只接触 [JsRuntimeManager]，
/// 完全不感知底层运行时对象。
///
/// - **默认实例**：使用 [instance]（全局唯一，static 共享）。大多数场景
///   直接用默认实例即可，多个 HotPatchWidget 共享同一个 JS 环境。
/// - **分组隔离**：业务方可以 `JsRuntimeManager()` 自行创建实例，把同一
///   个实例传给一组 HotPatchWidget（共享该组的 JS 状态），与其他组的
///   状态互不影响。
/// - **生命周期**：默认实例由本类持有（app 生命周期内常驻）；
///   业务方自建的实例由业务方管理（不再需要时置空引用即可，
///   不要 dispose 底层 runtime，避免其他仍在使用该 runtime 的组件失效）。
///
/// ## 为什么 handler 表是 static（跨实例共享）
///
/// flutter_js 0.8.7（iOS/JavaScriptCore）的消息桥是库级全局的：
/// `sendMessage` 的 Dart 回调是 static 字段，由「最后创建的那个 runtime」
/// 构造时覆盖赋值；通道表也是 static Map（key=engineId）。因此 JS 消息
/// 实际路由到「最后创建的 runtime」的通道表，与消息来自哪个实例无关。
/// 若 handler 表是实例级的，消息到达某个 manager 的通道回调后，
/// 查不到属于另一个 manager 的实例 key，就会串台/丢消息。
/// 所以 [setStateHandlers] / [serviceHandlers] 必须是 static 全局唯一，
/// 任何 manager 的通道回调都查同一张表、按实例 key 分发。
class JsRuntimeManager {
  /// 全局默认实例（static 共享）：大多数场景直接用这个。
  static final JsRuntimeManager instance = JsRuntimeManager();

  // ---------------------------------------------------------------------
  // 全局共享（static）：跨实例分发的 handler 表
  // ---------------------------------------------------------------------

  /// setState 重建回调表（全局唯一）：主实例 key → 重建回调。
  /// 嵌套实例消息 key 形如 `主key::组件名`，分发时回退到主 key。
  static final Map<String, void Function()> setStateHandlers = {};

  /// native 服务回调表（全局唯一）：channel → 处理器（实现已绑定自身 context）。
  static final Map<String, void Function(dynamic args)> serviceHandlers = {};

  // ---------------------------------------------------------------------
  // 实例状态：与 JavascriptRuntime 一对一
  // ---------------------------------------------------------------------

  /// 本 manager 独占的底层运行时（对外不可见，全部内部消化）。
  final JavascriptRuntime _runtime = getJavascriptRuntime();

  /// 本 manager 的基础通道（setState）是否已注册（per-manager 一次）。
  bool _wired = false;

  /// 本 manager 已注册的 native 服务通道（per-manager × channel 一次）。
  final Set<String> _wiredServiceChannels = {};

  /// 所有 JS 求值的统一入口（code 内部应带实例 key 寻址，
  /// 如 `__instances["hp_x"].method()`，由调用方保证 key 唯一）。
  ///
  /// 求值前惰性注册本 manager 的通道：flutter_js 的 sendMessage 桥是
  /// 库级 static 的，消息路由到最后创建的 runtime 的通道表——若某个
  /// runtime 从未注册通道，会成为全部消息的黑洞（No channel 报错）。
  JsEvalResult evaluate(String code) {
    ensureChannels();
    return _runtime.evaluate(code);
  }

  /// 注册本 manager 的基础通道（setState），每个 manager 只注册一次。
  /// 回调统一查 static 全局 [setStateHandlers] 表、按消息 key 分发，
  /// 因此无论消息路由到哪个 manager 的通道，都能找到正确实例。
  void ensureChannels() {
    if (_wired) return;
    _wired = true;
    _runtime.onMessage('setState', (dynamic args) {
      final key = (args is Map ? args['key'] : null)?.toString() ?? '';
      final mainKey = key.split('::').first;
      final handler = setStateHandlers[mainKey];
      if (handler != null) handler();
    });
    // ignore: avoid_print
    print('[js_runtime_manager] setState channel wired: ${_runtime.hashCode}');
  }

  /// 在本 manager 的 runtime 上注册 native 服务通道
  /// （每个 manager × channel 一次）。
  void ensureServiceChannels(Iterable<String> channels) {
    ensureChannels();
    for (final channel in channels) {
      if (!_wiredServiceChannels.add(channel)) continue;
      _runtime.onMessage(channel, (dynamic args) {
        final handler = serviceHandlers[channel];
        if (handler != null) handler(args);
      });
    }
  }

  /// 移除某实例注册的所有 handler（widget dispose 时调用）。
  /// 服务 handler 是 channel 级的（可能被多个实例覆盖），
  /// 由 HotPatchWidget dispose 时自行覆盖/清理，这里不动 serviceHandlers。
  void unregister(String instanceKey) {
    setStateHandlers.remove(instanceKey);
  }
}
