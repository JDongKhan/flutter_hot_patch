import 'package:flutter_js/flutter_js.dart';

/// JS 运行时管理器：全局共享一个默认 [JavascriptRuntime]（default 实例），
/// 所有 JS 求值与消息通道统一从这里走，避免每个 HotPatchWidget 各自
/// 创建 runtime 的性能开销。
///
/// - **默认**：HotPatchWidget 不传 `sharedRuntime` 时使用 [defaultRuntime]，
///   所有组件共享同一个 JS 环境（`__components`/`__instances` 共享）。
/// - **共享组**：业务方创建 runtime 传入多个 HotPatchWidget，这些组件
///   共享该 runtime 的 JS 状态；与 default 组互不影响。
///
/// 消息通道说明（flutter_js 0.8.7，iOS/JavaScriptCore）：
/// `sendMessage` 桥是 static 全局的，JS 消息实际路由到「最后创建的那个
/// runtime」的通道表；且同一 runtime 上同 channel 的 `onMessage` 重复
/// 注册会被忽略。因此通道在**每个实际使用的 runtime** 上只注册一次，
/// 回调统一查 [setStateHandlers] / [serviceHandlers] 全局表、按消息里的
/// 实例 key 分发——这是「点击 A 实例却重建 B 实例」这类串台问题的根治点。
class JsRuntimeManager {
  JsRuntimeManager._();

  /// 全局单例。
  static final JsRuntimeManager instance = JsRuntimeManager._();

  JavascriptRuntime? _default;
  final Map<int, JavascriptRuntime> _shared = {};

  /// 默认 runtime（首次访问时惰性创建，全局唯一）。
  JavascriptRuntime get defaultRuntime => _default ??= getJavascriptRuntime();

  /// 登记一个外部传入的 runtime（同一 runtime 的 HotPatchWidget 共享状态）。
  JavascriptRuntime registerShared(JavascriptRuntime runtime) {
    _shared[runtime.hashCode] = runtime;
    return runtime;
  }

  /// 所有 JS 求值的统一入口。`code` 内部应带实例 key 寻址
  /// （如 `__instances["hp_x"].method()`），由调用方保证 key 唯一。
  JsEvalResult evaluate(JavascriptRuntime runtime, String code) =>
      runtime.evaluate(code);

  // -------------------------------------------------------------------------
  // 消息通道（per-runtime 幂等注册 + 全局 handler 表按 key 分发）
  // -------------------------------------------------------------------------

  final Set<int> _wiredRuntimes = {};
  final Set<String> _wiredServiceChannels = {};

  /// setState 重建回调表：主实例 key → 重建回调。
  /// 嵌套实例消息 key 形如 `主key::组件名`，分发时回退到主 key。
  final Map<String, void Function()> setStateHandlers = {};

  /// native 服务回调表：channel → 处理器（实现已绑定自身 context）。
  final Map<String, void Function(dynamic args)> serviceHandlers = {};

  /// 在 runtime 上注册基础通道（setState），每个 runtime 只注册一次。
  void ensureChannels(JavascriptRuntime runtime) {
    if (!_wiredRuntimes.add(runtime.hashCode)) return;
    runtime.onMessage('setState', (dynamic args) {
      final key = (args is Map ? args['key'] : null)?.toString() ?? '';
      final mainKey = key.split('::').first;
      final handler = setStateHandlers[mainKey];
      if (handler != null) handler();
    });
    // ignore: avoid_print
    print('[js_runtime_manager] setState channel wired: ${runtime.hashCode}');
  }

  /// 在 runtime 上注册 native 服务通道（每个 runtime × channel 一次）。
  void ensureServiceChannels(
    JavascriptRuntime runtime,
    Iterable<String> channels,
  ) {
    ensureChannels(runtime);
    for (final channel in channels) {
      final id = '${runtime.hashCode}:$channel';
      if (!_wiredServiceChannels.add(id)) continue;
      runtime.onMessage(channel, (dynamic args) {
        final handler = serviceHandlers[channel];
        if (handler != null) handler(args);
      });
    }
  }

  /// 移除某实例注册的所有 handler（widget dispose 时调用）。
  void unregister(String instanceKey) {
    setStateHandlers.remove(instanceKey);
    // 服务 handler 是 channel 级的（可能被多个实例覆盖），
    // 由 HotPatchWidget dispose 时自行覆盖/清理，这里不动 serviceHandlers。
  }
}
