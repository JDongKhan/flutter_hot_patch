// ===== 能力：动画（宿主侧桥 + 组件注册）=====
//
// 两类动画，落点不同：
//   1. **隐式动画 / 过渡动画**（AnimatedContainer / FadeTransition …）：完全是
//      宿主组件，由 Flutter 自己的 AnimationController 插值；JS 只下发 props
//      （duration / curve / 目标值）。这里只需把 JSON 值还原成 Dart 值。
//   2. **显式动画**（AnimationController）：真实控制器带 Ticker 跑在宿主，
//      JS 侧是镜像 + 句柄（`ctrl/Flash`）。每帧把 value 经 `__jsui.invoke`
//      回传到 JS 镜像 → 触发 AnimatedBuilder 等 JS 逻辑组件只重建自己的子树。
//      隐式/过渡动画的插值仍由宿主完成，不逐帧过桥。
//
// 句柄桥复用通用层（capabilities/core/controller_bridge.dart）：onCreate 建
// 真实控制器、onOp 分派 forward/reverse/repeat/stop/reset、onRelease 释放。
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../json/flutter_from_json.dart';
import '../../../services/js_runtime_manager.dart';
import '../../../utils/hot_patch_log.dart';
import '../../js_widget_registry.dart';
import '../core/controller_bridge.dart';

/// 显式动画的 Ticker 来源：控制器真实对象在宿主侧（见文件头）。
///
/// vsync 只是一个 Ticker 工厂；AnimationController 的 `dispose` 会自行释放其
/// 内部 Ticker，故本对象无状态、进程内单例即可。
class _JsAnimationVsync implements TickerProvider {
  _JsAnimationVsync._();

  static final _JsAnimationVsync instance = _JsAnimationVsync._();

  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

/// AnimationController 句柄桥（kind `ctrl/Flash`）。
final JsControllerBridge<AnimationController> _animationBridge =
    JsControllerBridge<AnimationController>(
  kind: 'ctrl/Flash',
  create: (id, meta) => AnimationController(
    vsync: _JsAnimationVsync.instance,
    duration: const Duration(milliseconds: 300),
  ),
  onOp: (c, op, payload) {
    if (op == 'set') {
      if (payload['name'] == 'value' && payload['value'] is num) {
        final target = (payload['value'] as num).toDouble().clamp(
              c.lowerBound,
              c.upperBound,
            );
        if (c.value != target) c.value = target;
      }
      return null;
    }
    if (op != 'call') return null;
    final method = payload['method']?.toString() ?? '';
    // 本帧起的逐帧回传在这里挂：create 阶段回传句柄还没进 binding cache（
    // putIfAbsent 先 create 后落 meta），那时挂必然失败；而「不 forward 就不会
    // 有值变化」，故此处挂足够且不漏帧。id 由 JS 随载荷下发（基座 onOp 不带 id）。
    _attachValueMirror(payload['id']?.toString(), c);
    // JS 镜像的 value 与宿主控制器对齐：`reverse()` 只有在当前 value 为
    // upperBound 时才真正动起来，镜像滞后会让按钮「按了没反应」。
    final rawValue = payload['value'];
    if (rawValue is num) {
      final target = rawValue.toDouble().clamp(c.lowerBound, c.upperBound);
      if (c.value != target) c.value = target;
    }
    final rawMs = payload['durationMs'];
    if (rawMs is num && rawMs > 0) {
      final d = Duration(milliseconds: rawMs.toInt());
      if (c.duration != d) c.duration = d;
    }
    switch (method) {
      case 'forward':
        c.forward();
      case 'reverse':
        c.reverse();
      case 'repeat':
        c.repeat(reverse: payload['reverse'] == true);
      case 'stop':
        c.stop();
      case 'reset':
        c.reset();
      default:
        HotPatchLog.warn('AnimationController: 未支持的调用 "$method"');
    }
    return null;
  },
);

/// 逐帧 value 回传的挂载（同一 id 只挂一次；去重标记由句柄桥的 meta 维护）。
///
/// 回传句柄（meta.fn）随 JS 的 create 消息到达；`markAttachedOnFirst` 同时
/// 负责「句柄未到 / 已挂过」两种短路，因此多视图共享同一控制器也只回传一份。
void _attachValueMirror(String? id, AnimationController controller) {
  if (id == null) return;
  if (!_animationBridge.markAttachedOnFirst(id)) return;
  final handle = _animationBridge.fnHandleOf(id);
  final fnId = handle is Map ? handle['__fn'] : null;
  if (fnId is! String) return;
  controller.addListener(() {
    // 与 JsUiWidget._invoke 同一编码：参数数组的 JSON 文本再包成 JS 字符串，
    // JS 侧 invoke 解析一次还原为数组（能力句柄按位置形参收值）。
    JsRuntimeManager.evaluateAll(
      '__jsui.invoke(${jsonEncode(fnId)}, ${jsonEncode(jsonEncode([controller.value]))});',
    );
  });
}

/// 曲线派生动画缓存（挂在控制器实例上，随控制器回收）：曲线名 → 该控制器驱动的
/// `Animation<double>`。CurvedAnimation 会向父控制器注册 listener，每次 build
/// 现建会持续泄漏。
final Expando<Map<String, Animation<double>>> _curvedAnimations =
    Expando<Map<String, Animation<double>>>('jsAnimCurved');

/// props 里的动画值（`{__handle:id}` / JS CurvedAnimation 的
/// `{__handle:id, __curve:name}`）→ 宿主 `Animation<double>`。
///
/// 返回 null 表示该 prop 不是可解析的动画（调用方按「无动画」出声兜底）。
Animation<double>? jsDoubleAnimationOf(Object? prop) {
  final id = JsControllerBridge.idOf(prop);
  if (id == null) return null;
  final controller = _animationBridge.controllerOf(
    id,
    () => AnimationController(
      vsync: _JsAnimationVsync.instance,
      duration: const Duration(milliseconds: 300),
    ),
  );
  _attachValueMirror(id, controller);
  final curveName = prop is Map ? prop['__curve'] : null;
  if (curveName is String) {
    final cache = _curvedAnimations[controller] ??= {};
    return cache.putIfAbsent(
      curveName,
      () => controller.drive(CurveTween(curve: curveFromJson(curveName))),
    );
  }
  return controller;
}

/// 必填 duration 缺失时出声（Flutter 侧 duration 非空，零时长等于不动画）。
Duration _animationDuration(JsRenderContext c, String type) {
  final d = durationFromJson(c.props['duration']);
  if (d == null) {
    HotPatchLog.warn('$type: 缺少 duration，按 Duration.zero 处理（动画不会执行）');
    return Duration.zero;
  }
  return d;
}

/// 显式动画里「本能力不支持」的 props（如 AnimatedSwitcher 的 transitionBuilder）：
/// 出声而不是静默丢弃。
void _warnUnsupportedProps(JsRenderContext c, String type, List<String> keys) {
  final hit = keys.where((k) => c.props.containsKey(k) && c.props[k] != null);
  if (hit.isEmpty) return;
  HotPatchLog.warn('$type: 暂不支持 props ${hit.join(', ')}（已忽略）');
}

/// 幂等注册 AnimationController 句柄 kind（由 js_ui_capabilities 聚合调用）。
void ensureAnimationChannels() => _animationBridge.ensure();

/// 动画能力域组件注册（隐式动画 / 过渡动画 / JS 逻辑组件的宿主外壳）。
void registerAnimationWidgets(JsWidgetRegistry r) {
  // ── 隐式动画：目标值进 props，插值全在宿主完成 ──
  r.register('AnimatedContainer', (c) {
    final deco = boxDecorationFromJson(c.map('decoration'));
    return AnimatedContainer(
      duration: _animationDuration(c, 'AnimatedContainer'),
      curve: curveFromJson(c.props['curve']),
      width: c.num_('width'),
      height: c.num_('height'),
      // color 与 decoration 同传会断言：与 Container 同口径，decoration 优先。
      color: deco == null ? colorFromJson(c.props['color']) : null,
      decoration: deco,
      padding: edgeInsetsFromJson(c.map('padding')),
      margin: edgeInsetsFromJson(c.map('margin')),
      alignment: alignmentFromJson(c.props['alignment']),
      constraints: boxConstraintsFromJson(c.map('constraints')),
      clipBehavior:
          deco == null ? Clip.none : (clipBehaviorFromJson(c.props['clipBehavior']) ?? Clip.none),
      child: (c.children['child'] as Widget?),
    );
  });

  r.register(
    'AnimatedOpacity',
    (c) => AnimatedOpacity(
      opacity: c.num_('opacity') ?? 1,
      duration: _animationDuration(c, 'AnimatedOpacity'),
      curve: curveFromJson(c.props['curve']),
      onEnd: c.on('onEnd'),
      child: (c.children['child'] as Widget?),
    ),
  );

  r.register(
    'AnimatedPadding',
    (c) => AnimatedPadding(
      padding: edgeInsetsFromJson(c.map('padding')),
      duration: _animationDuration(c, 'AnimatedPadding'),
      curve: curveFromJson(c.props['curve']),
      child: (c.children['child'] as Widget?),
    ),
  );

  r.register(
    'AnimatedAlign',
    (c) => AnimatedAlign(
      alignment: alignmentFromJson(c.props['alignment']) ?? Alignment.center,
      duration: _animationDuration(c, 'AnimatedAlign'),
      curve: curveFromJson(c.props['curve']),
      child: (c.children['child'] as Widget?),
    ),
  );

  r.register(
    'AnimatedScale',
    (c) => AnimatedScale(
      scale: c.num_('scale') ?? 1,
      duration: _animationDuration(c, 'AnimatedScale'),
      curve: curveFromJson(c.props['curve']),
      alignment: alignmentFromJson(c.props['alignment']) ?? Alignment.center,
      child: (c.children['child'] as Widget?),
    ),
  );

  r.register(
    'AnimatedRotation',
    (c) => AnimatedRotation(
      turns: c.num_('turns') ?? 0,
      duration: _animationDuration(c, 'AnimatedRotation'),
      curve: curveFromJson(c.props['curve']),
      alignment: alignmentFromJson(c.props['alignment']) ?? Alignment.center,
      child: (c.children['child'] as Widget?),
    ),
  );

  r.register(
    'AnimatedSlide',
    (c) => AnimatedSlide(
      offset: offsetFromJson(c.props['offset']) ?? Offset.zero,
      duration: _animationDuration(c, 'AnimatedSlide'),
      curve: curveFromJson(c.props['curve']),
      child: (c.children['child'] as Widget?),
    ),
  );

  r.register(
    'AnimatedSize',
    (c) => AnimatedSize(
      duration: _animationDuration(c, 'AnimatedSize'),
      curve: curveFromJson(c.props['curve']),
      alignment: alignmentFromJson(c.props['alignment']) ?? Alignment.center,
      clipBehavior: clipBehaviorFromJson(c.props['clipBehavior']) ?? Clip.hardEdge,
      child: (c.children['child'] as Widget?),
    ),
  );

  r.register('AnimatedSwitcher', (c) {
    // transitionBuilder 是返回 widget 的闭包（生成器抽成方法名），本能力的宿主
    // 映射无法回调它——出声而不是静默丢弃（默认过渡仍由 Flutter 提供）。
    _warnUnsupportedProps(c, 'AnimatedSwitcher', const ['transitionBuilder']);
    return AnimatedSwitcher(
      duration: _animationDuration(c, 'AnimatedSwitcher'),
      reverseDuration: durationFromJson(c.props['reverseDuration']),
      switchInCurve: curveFromJson(c.props['switchInCurve']),
      switchOutCurve: curveFromJson(c.props['switchOutCurve']),
      child: (c.children['child'] as Widget?),
    );
  });

  r.register('AnimatedCrossFade', (c) {
    final first = (c.children['firstChild'] as Widget?) ?? const SizedBox.shrink();
    final second = (c.children['secondChild'] as Widget?) ?? const SizedBox.shrink();
    return AnimatedCrossFade(
      firstChild: first,
      secondChild: second,
      crossFadeState: crossFadeStateFromJson(c.props['crossFadeState']),
      duration: _animationDuration(c, 'AnimatedCrossFade'),
      firstCurve: curveFromJson(c.props['firstCurve']),
      secondCurve: curveFromJson(c.props['secondCurve']),
      sizeCurve: curveFromJson(c.props['sizeCurve']),
      alignment: alignmentFromJson(c.props['alignment']) ?? Alignment.topCenter,
      reverseDuration: durationFromJson(c.props['reverseDuration']),
    );
  });

  r.register('AnimatedDefaultTextStyle', (c) {
    final style = textStyleFromJson(c.map('style'));
    return AnimatedDefaultTextStyle(
      style: style,
      duration: _animationDuration(c, 'AnimatedDefaultTextStyle'),
      curve: curveFromJson(c.props['curve']),
      textAlign: textAlignFromJson(c.props['textAlign']),
      softWrap: c.bool_('softWrap') ?? true,
      overflow: overflowFromJson(c.props['overflow']) ?? TextOverflow.clip,
      maxLines: c.int_('maxLines'),
      child: (c.children['child'] as Widget?) ?? const SizedBox.shrink(),
    );
  });

  r.register(
    'AnimatedPositioned',
    (c) => AnimatedPositioned(
      left: c.num_('left'),
      top: c.num_('top'),
      right: c.num_('right'),
      bottom: c.num_('bottom'),
      width: c.num_('width'),
      height: c.num_('height'),
      duration: _animationDuration(c, 'AnimatedPositioned'),
      curve: curveFromJson(c.props['curve']),
      child: (c.children['child'] as Widget?) ?? const SizedBox.shrink(),
    ),
  );

  // ── 过渡动画：宿主直接消费 Animation 句柄，逐帧由 Flutter 原生插值 ──
  r.register('FadeTransition', (c) {
    final animation = jsDoubleAnimationOf(c.props['opacity']);
    final child = c.children['child'] as Widget?;
    if (animation == null) {
      HotPatchLog.warn('FadeTransition: opacity 不是 Animation 句柄，已退化为直接渲染子树');
      return child ?? const SizedBox.shrink();
    }
    return FadeTransition(
      opacity: animation,
      alwaysIncludeSemantics: c.bool_('alwaysIncludeSemantics') ?? false,
      child: child,
    );
  });

  r.register('ScaleTransition', (c) {
    final animation = jsDoubleAnimationOf(c.props['scale']);
    final child = c.children['child'] as Widget?;
    if (animation == null) {
      HotPatchLog.warn('ScaleTransition: scale 不是 Animation 句柄，已退化为直接渲染子树');
      return child ?? const SizedBox.shrink();
    }
    return ScaleTransition(
      scale: animation,
      alignment: alignmentFromJson(c.props['alignment']) ?? Alignment.center,
      child: child,
    );
  });

  r.register('RotationTransition', (c) {
    final animation = jsDoubleAnimationOf(c.props['turns']);
    final child = c.children['child'] as Widget?;
    if (animation == null) {
      HotPatchLog.warn('RotationTransition: turns 不是 Animation 句柄，已退化为直接渲染子树');
      return child ?? const SizedBox.shrink();
    }
    return RotationTransition(
      turns: animation,
      alignment: alignmentFromJson(c.props['alignment']) ?? Alignment.center,
      child: child,
    );
  });

  r.register('SizeTransition', (c) {
    final animation = jsDoubleAnimationOf(c.props['sizeFactor']);
    final child = c.children['child'] as Widget?;
    if (animation == null) {
      HotPatchLog.warn('SizeTransition: sizeFactor 不是 Animation 句柄，已退化为直接渲染子树');
      return child ?? const SizedBox.shrink();
    }
    return SizeTransition(
      sizeFactor: animation,
      axis: axisFromJson(c.props['axis']) ?? Axis.vertical,
      axisAlignment: c.num_('axisAlignment') ?? 0,
      child: child,
    );
  });

  // ── JS 逻辑组件的宿主外壳：子树已由 JS 侧按当前 value 展开 ──
  r.register(
    'AnimatedBuilder',
    (c) => (c.children['child'] as Widget?) ?? const SizedBox.shrink(),
  );
}
