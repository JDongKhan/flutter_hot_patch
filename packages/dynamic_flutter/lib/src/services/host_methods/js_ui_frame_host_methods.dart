import 'package:flutter/widgets.dart';

import '../js_runtime_manager.dart';
import 'builtin_host_method_group.dart';

/// JS 帧调度：`jsuiRequestFrame`（脏组件 flush / 持久帧回调）与
/// `jsuiEndOfFrame`（帧末 Future）。
final class JsUiFrameHostMethods extends BuiltinHostMethodGroup {
  /// 是否已调度了一帧级 flush（同一帧内重复请求只调度一次）。
  bool _flushScheduled = false;

  @override
  Map<String, Function> get methods => {
    'jsuiRequestFrame': _requestFrame,
    'jsuiEndOfFrame': _endOfFrame,
  };

  /// `jsuiRequestFrame`：JS 侧有脏组件，请求在下一帧统一 flush。
  ///
  /// 用 transient frame callback（动画同款）：它在 begin frame 的 **build 之前**
  /// 执行（早于 `drawFrame` 的持久回调），JS 下发的 ops 能在本帧生效——与 Flutter
  /// `setState` → 下一帧 build 的时序一致。
  void _requestFrame() {
    if (_flushScheduled) return;
    _flushScheduled = true;
    WidgetsBinding.instance.scheduleFrameCallback((Duration timeStamp) {
      _flushScheduled = false;
      JsRuntimeManager.flushJsUiPending();
      // flush 之后再回传帧回调：JS 侧持久帧回调看到的是本帧已应用的树；回调里的
      // setState 会再次请求下一帧（见 widgets_binding_js 的 frameTick）。
      JsRuntimeManager.tickJsUiFrames(timeStamp);
    });
  }

  /// `jsuiEndOfFrame`：JS 侧 `WidgetsBinding.instance.endOfFrame` 的宿主落点。
  ///
  /// 直接复用 Flutter 的 `WidgetsBinding.instance.endOfFrame`：当前帧结束时完成，
  /// 空闲时自动催一帧——与 Dart 的 `endOfFrame` 语义一致；帧末之后桥回填 Promise。
  Future<Object?> _endOfFrame() async {
    await WidgetsBinding.instance.endOfFrame;
    return null;
  }
}
