// ===== 自定义能力：EasyRefresh 下拉刷新（通道 + 桥接组件 + 组件注册）=====
//
// 一个能力 = 通道 + 桥接组件 + 组件注册，全部内聚在本文件。
//
// EasyRefresh 来自三方包 `easy_refresh`，不是运行时内建能力：宿主桥接放在本
// 工程 `lib/custom/easy_refresh/`，JS 类放在工程根 `js/easy_refresh.js`（构建
// 期拷贝为 `patch/packages/easy_refresh.js`），dynamic_flutter 包零改动。
//
// EasyRefresh（三方包 easy_refresh）的**手势 / 物理 / 指示器**全在宿主
// 侧，回调 onRefresh / onLoad 由 JS 补丁实现，所以需要一次「宿主发起 → JS 异步
// 完成」的往返：
//   1. 宿主 → JS：用户下拉后按事件句柄调用通用入口
//      `JsRuntimeManager.invokeAwait(handler)`；
//   2. JS → 宿主：JS 侧 await 完任务（含普通回调）后经通用回传通道
//      `jsuiEventResult` 交回 token 与结果（见 mini_react_js.dart）；
//   3. 本文件按 Future 完成时刻收起指示器。
//
// 这是**通用**机制，不是本能力专属：Dismissible 的 confirmDismiss、以后任何
// 返回 `Future<T>` 的事件（如 async 的 onPressed）都走同一条通道；
// `__jsui.invoke` 仍是「发了就走」的单向调用。
import 'dart:async';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/widgets.dart';
import 'package:dynamic_flutter/dynamic_flutter.dart';

bool _channelsRegistered = false;

/// 本能力只需登记 controller 句柄桥；onRefresh / onLoad 的「等结果」走
/// [JsRuntimeManager.invokeAwait] 的通用通道（见 js_runtime_manager.dart）。
void ensureEasyRefreshChannels() {
  if (_channelsRegistered) return;
  _channelsRegistered = true;
  _easyRefreshBridge.ensure();
}

/// EasyRefreshController 句柄桥（与 ScrollController 同一套通用层，见
/// capabilities/core/object_bridge.dart）：
///   JS 侧 `new EasyRefreshController({controlFinish*: …})` 经通用句柄通道同步到
///   宿主，按 meta 里的构造参数创建真实 controller；EasyRefresh(controller:
///   {__handle: id}) 渲染时按 id 取同一实例挂上。控制方法走通用 op（call），
///   释放走通用 release → 本桥 onRelease 调包内 dispose（解绑 EasyRefresh）。
final JsObjectBridge<EasyRefreshController> _easyRefreshBridge =
    JsObjectBridge<EasyRefreshController>(
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
        JsLog.warn(
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

/// 宿主发起一次「JS 侧异步事件」，返回 JS 侧的结果。
///
/// [handler] 是 JS 侧事件句柄（`{'__fn': id}`，由生成器在构建期产出）。
/// 句柄缺失 / 形态不对时立即完成：等价于「无事可做」，不阻塞指示器收起。
///
/// 返回值必须**原样交给 EasyRefresh**：它的 `_onTask` 检查 `res is
/// IndicatorResult`，非枚举一律按 `success` 处理。JS 侧的枚举跨桥是成员名
/// （`IndicatorResult.fail` → `'fail'`），这里还原成枚举；JS 回调是无返回值 /
/// 非枚举时返回 null，由包内按 success 兜底（与原生 `Future<void>` 一致）。
Future<Object?> _runAwaitableEvent(Object? handler) async {
  // 指示器的收起时机 = JS 任务真正结束时刻（invokeAwait 自带 30s 兜底超时，
  // 运行时销毁时不会永远转圈）。
  final value = await JsRuntimeManager.invokeAwait(handler);
  return switch (value) {
    'none' => IndicatorResult.none,
    'success' => IndicatorResult.success,
    'fail' => IndicatorResult.fail,
    'noMore' => IndicatorResult.noMore,
    _ => null,
  };
}

/// EasyRefresh 桥接组件（对应注册 key 'EasyRefresh'）。
///
/// JS 侧写法：
/// ```js
/// new EasyRefresh({ onRefresh: () => this._load(), child: new CustomScrollView({ ... }) })
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
    super.key,
    required this.controller,
    required this.onRefresh,
    required this.onLoad,
    required this.refreshOnStart,
    required this.triggerAxis,
    required this.child,
  });

  /// 与 JS 侧 `new EasyRefreshController()` 绑定的宿主实例；null = JS 未传。
  final EasyRefreshController? controller;

  /// JS 侧事件句柄（`{'__fn': id}`）；null = 该方向禁用。
  final Object? onRefresh;
  final Object? onLoad;

  /// 挂载即触发一次刷新（对应 Dart 的 `refreshOnStart`，缺省同包内 false）。
  final bool refreshOnStart;

  /// 触发刷新的滚动方向；null = 沿用 package 默认（不限制方向）。
  final Axis? triggerAxis;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final axis = triggerAxis;
    return EasyRefresh(
      controller: controller,
      onRefresh: onRefresh == null ? null : () => _runAwaitableEvent(onRefresh),
      onLoad: onLoad == null ? null : () => _runAwaitableEvent(onLoad),
      refreshOnStart: refreshOnStart,
      triggerAxis: axis,
      // 只有业务显式声明触发轴时才隔离物理：刷新物理会被 ScrollConfiguration
      // 下发到整个子树，嵌套的横向滚动（banner / PageView / 横向列表）也会被
      // 驱动，ClassicHeader 随 metrics.axis 切到横向模式（竖排刷新文案）。
      // triggerAxis 只拦「任务触发 / infinite 模式」，不拦指示器偏移，所以再在
      // 物理层按 metrics.axis 分流：触发轴用刷新物理，其它轴用平台默认物理。
      scrollBehaviorBuilder: axis == null
          ? null
          : (physics) => _TriggerAxisScrollBehavior(axis, physics),
      child: child,
    );
  }
}

/// EasyRefresh 能力域组件注册。
void registerEasyRefreshWidgets(JsWidgetRegistry r) {
  r.register('EasyRefresh', (c) {
    // controller 跨桥形态只有 `{__handle: id}`：真实 EasyRefreshController 在
    // JS 构造时按 create 的 meta（controlFinishRefresh / controlFinishLoad）建好，
    // 这里只按 id 取。没传 controller → 由 EasyRefresh 自己管理内部控制器；
    // 传了句柄却取不到对象 = 协议违约（已释放 / 未构造），出声报错不兜底。
    final id = JsObjectBridge.idOf(c.props['controller']);
    final EasyRefreshController? controller;
    if (id == null) {
      controller = null;
    } else {
      controller = _easyRefreshBridge.require(id);
    }
    return _JsEasyRefresh(
      key: c.key,
      controller: controller,
      onRefresh: c.props['onRefresh'],
      onLoad: c.props['onLoad'],
      refreshOnStart: c.bool_('refreshOnStart') ?? false,
      // 只透传业务显式声明的值：JS 枚举跨桥是成员名（`Axis.vertical` →
      // `'vertical'`），未传（null）时沿用 package 默认，桥接不替业务做决定。
      triggerAxis: switch (c.str('triggerAxis')) {
        'vertical' => Axis.vertical,
        'horizontal' => Axis.horizontal,
        _ => null,
      },
      // `child:` 统一进 children（生成器的子结点约定）→ 取第一个子结点。
      child: ((c.children['child'] as Widget?) ?? const SizedBox.shrink()),
    );
  });
}

// ---------------------------------------------------------------------------
// 刷新物理按轴隔离
// ---------------------------------------------------------------------------

/// 只让**触发轴**继承 EasyRefresh 的刷新物理。
///
/// 包内默认 `ERScrollBehavior` 会把刷新物理下发给整个子树，嵌套的横向滚动
/// 因此也被接管（状态切换、指示器偏移、任务触发）。`triggerAxis` 只作用于
/// 「任务触发 / infinite 模式」，不拦 [applyBoundaryConditions] 里的指示器
/// 偏移，所以这里在物理层按 `metrics.axis` 分流：触发轴用刷新物理，其它轴
/// 退回平台默认物理（横向滚动的手感、回弹保持系统行为）。
class _TriggerAxisScrollBehavior extends ERScrollBehavior {
  const _TriggerAxisScrollBehavior(this.triggerAxis, this.refreshPhysics);

  final Axis triggerAxis;
  final ScrollPhysics? refreshPhysics;

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // 平台默认物理（Clamping / Bouncing，含 AlwaysScrollable）。
    final fallback = super.getScrollPhysics(context);
    final refresh = refreshPhysics;
    if (refresh == null) return fallback;
    return _TriggerAxisScrollPhysics(
      triggerAxis: triggerAxis,
      refresh: refresh,
      fallback: fallback,
    );
  }
}

/// 按 `ScrollMetrics.axis` 在「刷新物理 / 平台默认物理」间分流。
class _TriggerAxisScrollPhysics extends ScrollPhysics {
  const _TriggerAxisScrollPhysics({
    required this.triggerAxis,
    required this.refresh,
    required this.fallback,
    super.parent,
  });

  final Axis triggerAxis;
  final ScrollPhysics refresh;
  final ScrollPhysics fallback;

  ScrollPhysics _for(ScrollMetrics position) =>
      position.axis == triggerAxis ? refresh : fallback;

  @override
  _TriggerAxisScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      _TriggerAxisScrollPhysics(
        triggerAxis: triggerAxis,
        refresh: refresh,
        fallback: fallback,
        parent: buildParent(ancestor),
      );

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) =>
      _for(position).applyPhysicsToUserOffset(position, offset);

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) =>
      _for(position).applyBoundaryConditions(position, value);

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) =>
      _for(position).createBallisticSimulation(position, velocity);
}
