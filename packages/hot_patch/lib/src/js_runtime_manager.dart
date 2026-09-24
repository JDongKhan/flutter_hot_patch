import 'package:flutter/widgets.dart';
import 'package:flutter_js/flutter_js.dart';

import 'native_service.dart';

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
/// ## 消息通道：统一由 [NativeService] 注册
///
/// JS → Flutter 的所有消息统一走「通道注册 + 两套处理器表」。
/// **对外扩展只有一种能力：实现 [NativeService]（channel + handle），
/// 用 [register]（页面级）或 [registerGlobal]（全局级）注册。**
/// 框架内部机制（如 setState）同样实现为 NativeService，由
/// HotPatchWidget 的页面级内部实现列表统一 [register]，不设特例方法。
///
/// **通道接线由注册动作驱动**：每次 [register] / [registerGlobal] 都会把
/// 对应 channel 注册到**所有活跃 manager** 的 runtime 上（[ensureChannels]
/// 幂等）——注册的处理器一定有回调可路由，不会出现「通道没注册 →
/// 消息黑洞」。之后新建的 manager 构造时自动补齐已注册过的全部通道。
/// [evaluate] 是纯求值入口，不掺注册副作用。
///
/// ### 页面级 [pageMessageHandlers]（跟页面 key 绑定）
///
/// 例：setState、绑定页面状态的内部实现、页面隔离的服务。
/// 消息**必须携带页面 key**：`sendMessage(channel, { key: 'hp_123', ... })`。
/// 分发：`pageMessageHandlers[key]?[channel]`；key 形如 `主key::组件`
/// （嵌套实例）时 miss 回退主 key。页面销毁用 [dispose] 一次性移除
/// 该 key 下的全部注册。
/// 页面级 handler 的 context 由 InstanceNativeService 自持
/// （[InstanceNativeService.state] 的 context），本类不持有 BuildContext。
///
/// ### 全局级 [globalMessageHandlers]（与页面无关）
///
/// 例：日志、toast。全局一份处理器，不需要页面 key 隔离。
/// 消息不带 key，或页面级查不到时回退到这里。
/// 全局 handler 的 context 由 [navigatorKey] 提供。
///
/// ### 分发规则（统一）
///
/// 1. 消息带 key → 先查页面级（`key`，miss 回退 `key.split('::').first`）；
/// 2. 页面级查不到或消息不带 key → 查全局级。
///
/// [pageMessageHandlers] / [globalMessageHandlers] 必须是 static 全局唯一：
/// flutter_js 0.8.7（iOS/JavaScriptCore）的消息桥是库级全局的，
/// `sendMessage` 的 Dart 回调是 static 字段（由最后创建的 runtime 覆盖
/// 赋值），通道表也是 static Map（key=engineId）。若处理器表是实例级的，
/// 消息到达某个 manager 的通道回调后查不到属于另一个 manager 的页面
/// key，就会串台/丢消息。
class JsRuntimeManager {
  /// 全局默认实例（static 共享）：大多数场景直接用这个。
  static final JsRuntimeManager instance = JsRuntimeManager();

  /// 全局导航 key（可选）：全局级服务（如 toast 弹 SnackBar）用它定位
  /// ScaffoldMessenger。业务方在 MaterialApp.navigatorKey 传入。
  static GlobalKey<NavigatorState>? navigatorKey;

  /// 所有活跃 manager（static 跟踪）：注册处理器时对所有实例接线通道。
  static final Set<JsRuntimeManager> _instances = {};

  /// 已注册过的全部通道名（static）：新建 manager 构造时补齐接线。
  static final Set<String> _registeredChannels = {};

  // ---------------------------------------------------------------------
  // 全局共享（static）：两套消息处理器表
  // ---------------------------------------------------------------------

  /// 页面级处理器表（全局唯一）：页面 key → (方法 → 处理器)。
  /// [register] 注册的服务在这里；页面销毁时 [dispose] 移除。
  static final Map<String, Map<String, void Function(dynamic args)>>
      pageMessageHandlers = {};

  /// 全局级处理器表（全局唯一）：方法 → 处理器。
  /// [registerGlobal] 注册的服务在这里，全局一份。
  static final Map<String, void Function(dynamic args)> globalMessageHandlers =
      {};

  /// 为页面 key 注册一个**页面级** [NativeService]。
  ///
  /// 消息 `sendMessage(channel, { key: 页面key, ... })` 触发；
  /// handle 的 context 由服务自身提供：InstanceNativeService 经
  /// [InstanceNativeService.build] 注入页面 state 后取 `state.context`。
  /// **本类不持有任何 BuildContext**（避免页面销毁后的泄漏）。
  /// 注册即接线通道：所有活跃 manager 的 runtime 上都注册该 channel。
  static void register(String pageKey, NativeService service) {
    (pageMessageHandlers[pageKey] ??= {})[service.channel] = (dynamic args) {
      final ctx = service is InstanceNativeService
          ? service.state?.context
          : null;
      if (ctx == null || !ctx.mounted) return;
      service.handle(ctx, args);
    };
    _wireChannel(service.channel);
  }

  /// 注册一个**全局级** [NativeService]（与页面无关，全局一份）。
  ///
  /// 例：日志、toast。消息 `sendMessage(channel, { ... })` 触发；
  /// handle 的 context 由框架取 [navigatorKey] 提供。
  static void registerGlobal(NativeService service) {
    globalMessageHandlers[service.channel] = (dynamic args) {
      final ctx = navigatorKey?.currentContext;
      if (ctx == null || !ctx.mounted) {
        // ignore: avoid_print
        print('[js_runtime_manager] ${service.channel} ignored: '
            'navigatorKey not configured / context not ready');
        return;
      }
      service.handle(ctx, args);
    };
    _wireChannel(service.channel);
  }

  /// 移除页面 key 下的**全部**页面级注册（页面/组件销毁时调用）。
  static void dispose(String pageKey) {
    pageMessageHandlers.remove(pageKey);
  }

  /// 内部：把 channel 登记进全局注册表并接线到所有活跃 manager。
  static void _wireChannel(String channel) {
    _registeredChannels.add(channel);
    for (final m in _instances) {
      m.ensureChannels([channel]);
    }
  }

  // ---------------------------------------------------------------------
  // 实例状态：与 JavascriptRuntime 一对一
  // ---------------------------------------------------------------------

  /// 本 manager 独占的底层运行时（对外不可见，全部内部消化）。
  final JavascriptRuntime _runtime = getJavascriptRuntime();

  /// 本 manager 已注册的通道（per-manager × channel 一次）。
  final Set<String> _wiredChannels = {};

  JsRuntimeManager() {
    _instances.add(this);
    // 补齐历史上已注册过的通道：新 manager 也能接收既有消息。
    ensureChannels(_registeredChannels);
  }

  /// 所有 JS 求值的统一入口（纯求值，无注册副作用）。
  /// code 内部应带实例 key 寻址，如 `__instances["hp_x"].method()`。
  JsEvalResult evaluate(String code) => _runtime.evaluate(code);

  /// 注册消息通道（每个 manager × channel 一次，幂等）。
  ///
  /// 通道回调统一查两套 static 全局表分发（规则见类注释）：
  /// 消息 args 的 `key` 定位页面层，通道名定位方法层；页面级 miss 或
  /// 无 key 时回退全局级。因此无论消息路由到哪个 manager 的通道，
  /// 都能找到正确处理器。
  void ensureChannels(Iterable<String> channels) {
    for (final channel in channels) {
      if (!_wiredChannels.add(channel)) continue;
      _runtime.onMessage(channel, (dynamic args) {
        final key =
            (args is Map && args['key'] != null) ? args['key'].toString() : '';
        void Function(dynamic args)? handler;
        if (key.isNotEmpty) {
          final mainKey = key.split('::').first;
          handler = (pageMessageHandlers[key] ??
                  pageMessageHandlers[mainKey])?[channel];
        }
        handler ??= globalMessageHandlers[channel];
        if (handler != null) handler(args);
      });
      // ignore: avoid_print
      print('[js_runtime_manager] channel wired: $channel (${_runtime.hashCode})');
    }
  }
}
