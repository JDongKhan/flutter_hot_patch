import 'host_methods/asset_host_methods.dart';
import 'host_methods/basic_message_channel_host_methods.dart';
import 'host_methods/builtin_host_method_group.dart';
import 'host_methods/event_channel_host_methods.dart';
import 'host_methods/js_ui_commit_host_methods.dart';
import 'host_methods/js_ui_frame_host_methods.dart';
import 'host_methods/log_host_methods.dart';
import 'host_methods/method_channel_host_methods.dart';
import 'host_methods/native_toast_host_methods.dart';
import 'js_runtime_manager.dart';

// ===========================================================================
// 框架内建宿主方法（通道）注册
//
// 与业务 @HostInjected 方法共用唯一入口 JsRuntimeManager.registerHostMethod
// 与唯一处理器表；JS 侧也只有唯一出口 `_app_host_.invoke`。
//
// 组织方式：一个能力域一个 [BuiltinHostMethodGroup] 子类，子类用
// `Map<String, Function> get methods` 声明本组的「通道名 → 实现」；每个子类
// 单独一个文件（`host_methods/`），本文件只维护实例列表。新增通道 = 改一个
// 子类文件，diff 天然按能力域隔离，便于 review。
//
//   - log_host_methods.dart                  `log`
//   - native_toast_host_methods.dart         `nativeToast`
//   - js_ui_commit_host_methods.dart         `jsuiCommit`
//   - js_ui_frame_host_methods.dart          `jsuiRequestFrame` / `jsuiEndOfFrame`
//   - asset_host_methods.dart                `assetLoadString`
//   - method_channel_host_methods.dart       `methodChannel` /
//                                            `methodChannelHandler`
//   - basic_message_channel_host_methods.dart
//                                            `basicMessageChannelSend` /
//                                            `basicMessageChannelHandler`
//   - event_channel_host_methods.dart        `eventChannelListen` /
//                                            `eventChannelCancel`
//
// 通道语义：
//   - `log`               ← Dart 日志全局（JS 侧 print/debugPrint → __log →
//                           _app_host_.invoke('log', [..])）
//   - `nativeToast`       ← 生成器把 SnackBar 形式动作译为
//                           `_app_host_.invoke('nativeToast', {message})`
//   - `jsuiCommit`        ← JS 增量补丁，payload 带页面 key，路由到对应 JsUiStore
//   - `jsuiRequestFrame`  ← JS 侧 setState 后请求一帧；宿主在 begin frame 统一
//                           flush，把同一帧内的多次 setState 合并成一次 build
//                           （与 Flutter 的 setState 语义一致）；flush 后同帧回调
//                           JS 的持久帧回调（`__jsui.frameTick`）
//   - `jsuiEndOfFrame`    ← JS 侧 `WidgetsBinding.instance.endOfFrame` 的宿主落点
//                           （复用 Flutter 的帧末 Future）
//   - `assetLoadString`   ← JS 侧 `rootBundle.loadString(key)` 的宿主落点
//   - `methodChannel`     ← JS 侧 `MethodChannel.invokeMethod` 的宿主落点：
//                           一个通用入口承接所有 channel（name / codec 是参数，
//                           不是注册项），宿主按 `name#codec` 缓存 Dart 侧实例，
//                           再调用真正的 Flutter MethodChannel → 原生
//   - `basicMessageChannel*` / `eventChannel*` 同理，都是通用入口 + 参数化
//                           channel 身份，不为单个 channel 注册。
//
// 幂等（全局一次）：由 JsUiWidget 启动时调用。
// ===========================================================================

/// 组实例列表：新增能力域时只在这里加一行实例（顺序 = 注册顺序）。
final List<BuiltinHostMethodGroup> _builtinGroups = [
  const LogHostMethods(),
  const NativeToastHostMethods(),
  const JsUiCommitHostMethods(),
  JsUiFrameHostMethods(),
  const AssetHostMethods(),
  MethodChannelHostMethods(),
  BasicMessageChannelHostMethods(),
  EventChannelHostMethods(),
];

bool _registered = false;

/// 注册框架内建宿主方法（全局一次，幂等）。
void registerBuiltinHostMethods() {
  if (_registered) return;
  _registered = true;
  for (final group in _builtinGroups) {
    group.methods.forEach(JsRuntimeManager.registerHostMethod);
  }
}
