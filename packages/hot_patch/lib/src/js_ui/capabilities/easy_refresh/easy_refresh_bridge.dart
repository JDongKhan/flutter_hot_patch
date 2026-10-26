// ===== 能力：EasyRefresh 下拉刷新（通道 + 桥接组件 + 组件注册）=====
//
// 一个能力 = 通道 + 桥接组件 + 组件注册，全部内聚在本文件。
//
// EasyRefresh（三方包 flutter_easy_refresh）的**手势 / 物理 / 指示器**全在宿主
// 侧，回调 onRefresh / onLoad 由 JS 补丁实现，所以需要一次「宿主发起 → JS 异步
// 完成」的往返：
//   1. 宿主 → JS：用户下拉后按事件句柄触发 [jsFragments] 里的 `__jsuiAwaitRun`
//      （见 easy_refresh_js.dart）；
//   2. JS → 宿主：JS 侧 await 完任务后经宿主通道 [awaitDoneChannel] 回传 token；
//   3. 本文件把 token ↔ Completer，交给 EasyRefresh 的 onRefresh/onLoad，
//      指示器在 JS 任务**真正结束**时才收起。
//
// 为什么不直接复用 [JsUiWidgetState._invoke]：它是单向的——宿主调完 JS 即返回，
// 而 JS 的 Promise 在 iOS/JavaScriptCore 上无法回传 Dart，拿不到完成信号，
// 指示器会瞬间消失（用户看不到任何加载反馈）。
import 'dart:async';
import 'dart:convert';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/widgets.dart';

import '../../../services/js_runtime_manager.dart';
import '../../../utils/hot_patch_log.dart';
import '../../js_widget_registry.dart';
import '../animation/animation_from_json.dart';
import '../core/controller_bridge.dart';
import '../core/from_json/dart_values_from_json.dart';

/// 完成信号通道：JS 侧 await 完事件后回传 token（见 easy_refresh_js.dart）。
const String awaitDoneChannel = 'jsuiAwaitDone';

/// token → 等待中的刷新/加载任务；JS 回传后结算并摘除（避免条目滞留）。
final Map<String, Completer<void>> _pendingTasks = {};

int _tokenSeq = 0;

bool _channelsRegistered = false;

/// 幂等登记本能力的宿主通道（由 js_ui_capabilities 聚合调用）。
void ensureEasyRefreshChannels() {
  if (_channelsRegistered) return;
  _channelsRegistered = true;
  _easyRefreshBridge.ensure();
  JsRuntimeManager.registerHostMethod(awaitDoneChannel, (String token) {
    _pendingTasks.remove(token)?.complete();
  });
}

/// EasyRefreshController 句柄桥（与 ScrollController 同一套通用层，见
/// capabilities/core/controller_bridge.dart）：
///   JS 侧 `new EasyRefreshController({controlFinish*: …})` 经通用句柄通道同步到
///   宿主，按 meta 里的构造参数创建真实 controller；EasyRefresh(controller:
///   {__handle: id}) 渲染时按 id 取同一实例挂上。控制方法走通用 op（call），
///   释放走通用 release → 本桥 onRelease 调包内 dispose（解绑 EasyRefresh）。
final JsControllerBridge<EasyRefreshController> _easyRefreshBridge =
    JsControllerBridge<EasyRefreshController>(
  kind: 'ctrl/EasyRefresh',
  // 真实 controller 由宿主带 controlFinish* 创建（同 PageController /
  // TabController 模式：构造参数随句柄下发，不能预建默认实例）。
  create: (_, meta) {
    final m = meta is Map ? meta : const <Object?, Object?>{};
    return EasyRefreshController(
      controlFinishRefresh: m['controlFinishRefresh'] == true,
      controlFinishLoad: m['controlFinishLoad'] == true,
    );
  },
  onOp: (c, op, payload) {
    if (op != 'call') return null;
    final method = payload['method']?.toString() ?? '';
    final args = payload['args'] is List ? payload['args'] as List : const [];
    // 时长/曲线/偏移/force 共用同一份按类型还原的结果；控制完成类方法只认
    // 「枚举名 + force」两个位置实参。
    switch (method) {
      case 'callRefresh':
        final a = _callArgs(args);
        return c.callRefresh(
          overOffset: a.overOffset,
          duration: a.duration ?? const Duration(milliseconds: 200),
          curve: a.curve ?? Curves.linear,
          force: a.force ?? false,
        );
      case 'callLoad':
        final a = _callArgs(args);
        return c.callLoad(
          overOffset: a.overOffset,
          duration: a.duration ?? const Duration(milliseconds: 300),
          curve: a.curve ?? Curves.linear,
          force: a.force ?? false,
        );
      case 'openHeaderSecondary':
      case 'closeHeaderSecondary':
      case 'openFooterSecondary':
      case 'closeFooterSecondary':
        final a = _callArgs(args);
        final duration = a.duration ?? const Duration(milliseconds: 200);
        final curve = a.curve ?? Curves.linear;
        switch (method) {
          case 'openHeaderSecondary':
            return c.openHeaderSecondary(duration: duration, curve: curve);
          case 'closeHeaderSecondary':
            return c.closeHeaderSecondary(duration: duration, curve: curve);
          case 'openFooterSecondary':
            return c.openFooterSecondary(duration: duration, curve: curve);
          default:
            return c.closeFooterSecondary(duration: duration, curve: curve);
        }
      case 'resetHeader':
        c.resetHeader();
        return null;
      case 'resetFooter':
        c.resetFooter();
        return null;
      case 'finishRefresh':
        final f = _finishArgs(args);
        c.finishRefresh(f.result, f.force);
        return null;
      case 'finishLoad':
        final f = _finishArgs(args);
        c.finishLoad(f.result, f.force);
        return null;
    }
    return null;
  },
  // 包内 dispose 即解绑 EasyRefresh（非 ChangeNotifier，通用层不会调）。
  onRelease: (c) => c.dispose(),
);

/// EasyRefreshController 普通控制方法的实参还原。
///
/// JS 侧下发的是**原始 arguments**（生成器把方法调用的具名实参位置化扁平，
/// 拿不到形参名），因此按 Dart 形参的类型签名判别：Duration 值 → duration、
/// 曲线名 → curve、数值 → overOffset、布尔 → force。
({double? overOffset, Duration? duration, Curve? curve, bool? force})
_callArgs(List<Object?> args) {
  double? overOffset;
  Duration? duration;
  Curve? curve;
  bool? force;
  for (final a in args) {
    if (a is bool) {
      force ??= a;
    } else if (a is num) {
      overOffset ??= a.toDouble();
    } else if (a is String) {
      curve ??= curveFromJson(a);
    } else if (a is Map) {
      final d = durationFromJson(a);
      if (d != null) {
        duration ??= d;
      } else if (a['__handle'] != null) {
        // scrollController: 未支持——不静默吞掉，给出明确日志。
        HotPatchLog.warn(
          'EasyRefreshController: scrollController 实参未支持（已忽略）：$a',
        );
      }
    }
  }
  return (
    overOffset: overOffset,
    duration: duration,
    curve: curve,
    force: force,
  );
}

/// finishRefresh / finishLoad 的实参还原：`IndicatorResult` 枚举名 + force。
({IndicatorResult result, bool force}) _finishArgs(List<Object?> args) {
  var result = IndicatorResult.success;
  var force = false;
  for (final a in args) {
    if (a is String) {
      result = switch (a) {
        'none' => IndicatorResult.none,
        'fail' => IndicatorResult.fail,
        'noMore' => IndicatorResult.noMore,
        _ => IndicatorResult.success,
      };
    } else if (a is bool) {
      force = a;
    }
  }
  return (result: result, force: force);
}

/// 宿主发起一次「JS 侧异步事件」，返回等待其完成的 Future。
///
/// [handler] 是 JS 侧事件句柄（`{'__fn': id}`，由生成器在构建期产出）。
/// 句柄缺失 / 形态不对时立即完成：等价于「无事可做」，不阻塞指示器收起。
Future<void> _runAwaitableEvent(Object? handler) {
  final id = handler is Map ? handler['__fn'] : null;
  if (id is! String) return Future<void>.value();
  final token = 'er${++_tokenSeq}';
  final completer = Completer<void>();
  _pendingTasks[token] = completer;
  JsRuntimeManager.instance.evaluate(
    '__jsuiAwaitRun(${jsonEncode(id)}, ${jsonEncode(token)});',
  );
  // 兜底超时：JS 运行时被销毁 / 句柄在任务中释放时回传永不到达，指示器不能
  // 永远转圈，也不能让条目滞留在 _pendingTasks。
  return completer.future.timeout(
    const Duration(seconds: 30),
    onTimeout: () => _pendingTasks.remove(token),
  );
}

/// EasyRefresh 桥接组件（对应注册 key 'EasyRefresh'）。
///
/// JS 侧写法：
/// ```js
/// __h('EasyRefresh', { onRefresh: this.__bindFn(3, [], () => this._load()), child: __h('CustomScrollView', ...) })
/// ```
/// 用户下拉 → 宿主触发 JS `_load()` → JS 侧 await 其 Promise → 回传完成 →
/// 指示器收起。onRefresh / onLoad 为 null 时对应方向禁用（包的
/// NotRefreshHeader / NotLoadFooter 语义）。
///
/// 指示器样式统一用包内默认（ClassicHeader / ClassicFooter）：样式对象
/// （Header/Footer）在 JS 侧没有等价物，且属「视觉细节」而非页面逻辑，不做
/// 翻译。控制器例外——它是页面逻辑的抓手（主动触发刷新/加载、完成指示器），
/// 按 ScrollController 同一套句柄层支持（见 [_easyRefreshBridge]）。
class _JsEasyRefresh extends StatelessWidget {
  const _JsEasyRefresh({
    required this.controller,
    required this.onRefresh,
    required this.onLoad,
    required this.refreshOnStart,
    required this.child,
  });

  /// 与 JS 侧 `new EasyRefreshController()` 绑定的宿主实例；null = JS 未传。
  final EasyRefreshController? controller;

  /// JS 侧事件句柄（`{'__fn': id}`）；null = 该方向禁用。
  final Object? onRefresh;
  final Object? onLoad;

  /// 挂载即触发一次刷新（对应 Dart 的 `refreshOnStart: true`）。
  final bool refreshOnStart;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return EasyRefresh(
      controller: controller,
      onRefresh: onRefresh == null ? null : () => _runAwaitableEvent(onRefresh),
      onLoad: onLoad == null ? null : () => _runAwaitableEvent(onLoad),
      refreshOnStart: refreshOnStart,
      child: child,
    );
  }
}

/// EasyRefresh 能力域组件注册。
void registerEasyRefreshWidgets(JsWidgetRegistry r) {
  r.register('EasyRefresh', (c) {
    // controller 跨桥形态见 JS 侧 extraJSON：`{__handle: id, controlFinish*}`。
    // handle 缺失时（旧调用）不挂控制器；渲染期兜底创建（创建消息与首帧渲染
    // 谁先到都复用同一实例）。
    final handle = c.props['controller'];
    final id = JsControllerBridge.idOf(handle);
    final controller = id == null
        ? null
        : _easyRefreshBridge.controllerOf(
            id,
            () => EasyRefreshController(
              controlFinishRefresh: handle is Map &&
                  handle['controlFinishRefresh'] == true,
              controlFinishLoad:
                  handle is Map && handle['controlFinishLoad'] == true,
            ),
          );
    return _JsEasyRefresh(
      controller: controller,
      onRefresh: c.props['onRefresh'],
      onLoad: c.props['onLoad'],
      refreshOnStart: c.bool_('refreshOnStart') ?? false,
      // `child:` 统一进 children（生成器的子结点约定）→ 取第一个子结点。
      child: ((c.children['child'] as Widget?) ?? const SizedBox.shrink()),
    );
  });
}
