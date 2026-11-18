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
// 句柄桥复用通用层（capabilities/core/object_bridge.dart）：onCreate 建
// 真实控制器、onOp 分派 forward/reverse/repeat/stop/reset、onRelease 释放。
import 'package:flutter/material.dart';

import '../../../utils/dynamic_flutter_log.dart';
import '../../js_widget_registry.dart';
import '../base_widget/text_from_json.dart';
import '../core/object_bridge.dart';
import '../core/ticker_mode_binding.dart';
import '../core/from_json/dart_values_from_json.dart';
import '../core/from_json/layout_from_json.dart';
import '../core/from_json/painting_from_json.dart';
import 'animation_from_json.dart';

// vsync 走 `core/ticker_mode_binding.dart`（与 Tab 同一套）：控制器在 JS 构造时
// 创建、可能被多个视图共享，没有「某个 State 的 TickerMode」可依；该模块默认把
// Ticker 绑到渲染位置的 TickerMode，开关见 `jsTickerModeBindingEnabled`。

/// AnimationController 句柄桥（kind `ctrl/Flash`）。
final JsObjectBridge<AnimationController> _animationBridge =
    JsObjectBridge<AnimationController>(
  kind: 'ctrl/Flash',
  // 构造参数随 create 的 meta 下发：value / lowerBound / upperBound / duration
  // 在 JS 构造时就落到真实控制器（不再先建 300ms 默认再靠首个 op 对齐）。
  create: (id, meta) {
    final m = meta is Map ? meta : const {};
    double numOf(String key, double fallback) =>
        m[key] is num ? (m[key] as num).toDouble() : fallback;
    final lower = numOf('lowerBound', 0.0);
    final upper = numOf('upperBound', 1.0);
    final ms = m['durationMs'] is num ? (m['durationMs'] as num).toInt() : 300;
    return AnimationController(
      vsync: jsTickerProviderFor(id),
      value: numOf('value', lower).clamp(lower, upper),
      lowerBound: lower,
      upperBound: upper,
      duration: Duration(milliseconds: ms > 0 ? ms : 300),
    );
  },
  // 每帧 value → JS 镜像（onHost 更新 _value + __notify → AnimatedBuilder 等
  // 只重建自己的子树）。listener 在 onCreate 挂一次：控制器只在 value 变化时
  // 通知，因此不跑动画就没有回传，开销为 0。
  forward: (controller) => [controller.value],
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
        JsLog.warn('AnimationController: 未支持的调用 "$method"');
    }
    return null;
  },
);

/// 曲线派生动画缓存（挂在控制器实例上，随控制器回收）：曲线名 → 该控制器驱动的
/// `Animation<double>`。CurvedAnimation 会向父控制器注册 listener，每次 build
/// 现建会持续泄漏。
final Expando<Map<String, Animation<double>>> _curvedAnimations =
    Expando<Map<String, Animation<double>>>('jsAnimCurved');

/// props 里的动画值（`{__handle:id}` / JS CurvedAnimation 的
/// `{__handle:id, __curve:name}`）→ 宿主 `Animation<double>`。
///
/// 返回 null 表示该 prop 不是可解析的动画（调用方按「无动画」出声兜底）。
Animation<double>? jsDoubleAnimationOf(Object? prop, {BuildContext? context}) {
  final id = JsObjectBridge.idOf(prop);
  if (id == null) return null;
  final controller = _animationBridge.controllerAt(id);
  if (controller == null) {
    // 句柄已释放（页面卸载竞态）：按「无动画」出声兜底，不现场补建——补建会
    // 丢掉 JS 侧构造参数（duration / bounds），并与 JS 实例 lifetime 脱钩。
    JsLog.warn('Animation: 句柄 $id 已释放，该 prop 按无动画处理');
    return null;
  }
  _animationBridge.forwardOnNextFrame(id);
  // 登记挂载点：让 Ticker 跟随这棵子树被 TickerMode 遮住时暂停（可选能力，
  // 关闭时该调用是空操作）。
  jsBindTickerMode(id, context);
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
  final d = c.duration('duration');
  if (d == null) {
    JsLog.warn('$type: 缺少 duration，按 Duration.zero 处理（动画不会执行）');
    return Duration.zero;
  }
  return d;
}

/// 显式动画里「本能力不支持」的 props（如 AnimatedSwitcher 的 transitionBuilder）：
/// 出声而不是静默丢弃。
void _warnUnsupportedProps(JsRenderContext c, String type, List<String> keys) {
  final hit = keys.where((k) => c.props.containsKey(k) && c.props[k] != null);
  if (hit.isEmpty) return;
  JsLog.warn('$type: 暂不支持 props ${hit.join(', ')}（已忽略）');
}

/// 幂等注册 AnimationController 句柄 kind（由 js_ui_capabilities 聚合调用）。
void ensureAnimationChannels() => _animationBridge.ensure();

/// 动画能力域组件注册（隐式动画 / 过渡动画 / JS 逻辑组件的宿主外壳）。
void registerAnimationWidgets(JsWidgetRegistry r) {
  // ── 隐式动画：目标值进 props，插值全在宿主完成 ──
  r.register('AnimatedContainer', (c) {
    final deco = c.boxDecoration('decoration');
    return AnimatedContainer(
      key: c.key,
      duration: _animationDuration(c, 'AnimatedContainer'),
      curve: c.curve('curve'),
      width: c.double_('width'),
      height: c.double_('height'),
      // color 与 decoration 同传会断言：与 Container 同口径，decoration 优先。
      color: deco == null ? c.color('color') : null,
      decoration: deco,
      // 与 Container 一致：padding / margin 可选，缺省走 Flutter 默认（null）。
      padding: c.edgeInsets('padding'),
      margin: c.edgeInsets('margin'),
      alignment: c.alignment('alignment'),
      constraints: c.boxConstraints('constraints'),
      clipBehavior:
          deco == null ? Clip.none : (c.clipBehavior('clipBehavior') ?? Clip.none),
      child: (c.children['child'] as Widget?),
    );
  });

  r.register(
    'AnimatedOpacity',
    (c) => AnimatedOpacity(
      key: c.key,
      opacity: c.double_('opacity') ?? 1,
      duration: _animationDuration(c, 'AnimatedOpacity'),
      curve: c.curve('curve'),
      onEnd: c.on('onEnd'),
      child: (c.children['child'] as Widget?),
    ),
  );

  r.register(
    'AnimatedPadding',
    (c) => AnimatedPadding(
      key: c.key,
      padding: c.edgeInsets('padding') ?? EdgeInsets.zero,
      duration: _animationDuration(c, 'AnimatedPadding'),
      curve: c.curve('curve'),
      child: (c.children['child'] as Widget?),
    ),
  );

  r.register(
    'AnimatedAlign',
    (c) => AnimatedAlign(
      key: c.key,
      alignment: c.alignment('alignment') ?? Alignment.center,
      duration: _animationDuration(c, 'AnimatedAlign'),
      curve: c.curve('curve'),
      child: (c.children['child'] as Widget?),
    ),
  );

  r.register(
    'AnimatedScale',
    (c) => AnimatedScale(
      key: c.key,
      scale: c.double_('scale') ?? 1,
      duration: _animationDuration(c, 'AnimatedScale'),
      curve: c.curve('curve'),
      alignment: c.alignment('alignment') ?? Alignment.center,
      child: (c.children['child'] as Widget?),
    ),
  );

  r.register(
    'AnimatedRotation',
    (c) => AnimatedRotation(
      key: c.key,
      turns: c.double_('turns') ?? 0,
      duration: _animationDuration(c, 'AnimatedRotation'),
      curve: c.curve('curve'),
      alignment: c.alignment('alignment') ?? Alignment.center,
      child: (c.children['child'] as Widget?),
    ),
  );

  r.register(
    'AnimatedSlide',
    (c) => AnimatedSlide(
      key: c.key,
      offset: c.offset('offset') ?? Offset.zero,
      duration: _animationDuration(c, 'AnimatedSlide'),
      curve: c.curve('curve'),
      child: (c.children['child'] as Widget?),
    ),
  );

  r.register(
    'AnimatedSize',
    (c) => AnimatedSize(
      key: c.key,
      duration: _animationDuration(c, 'AnimatedSize'),
      curve: c.curve('curve'),
      alignment: c.alignment('alignment') ?? Alignment.center,
      clipBehavior: c.clipBehavior('clipBehavior') ?? Clip.hardEdge,
      child: (c.children['child'] as Widget?),
    ),
  );

  r.register('AnimatedSwitcher', (c) {
    // transitionBuilder 是返回 widget 的闭包（生成器抽成方法名），本能力的宿主
    // 映射无法回调它——出声而不是静默丢弃（默认过渡仍由 Flutter 提供）。
    _warnUnsupportedProps(c, 'AnimatedSwitcher', const ['transitionBuilder']);
    return AnimatedSwitcher(
      key: c.key,
      duration: _animationDuration(c, 'AnimatedSwitcher'),
      reverseDuration: c.duration('reverseDuration'),
      switchInCurve: c.curve('switchInCurve'),
      switchOutCurve: c.curve('switchOutCurve'),
      child: (c.children['child'] as Widget?),
    );
  });

  r.register('AnimatedCrossFade', (c) {
    final first = (c.children['firstChild'] as Widget?) ?? const SizedBox.shrink();
    final second = (c.children['secondChild'] as Widget?) ?? const SizedBox.shrink();
    return AnimatedCrossFade(
      key: c.key,
      firstChild: first,
      secondChild: second,
      crossFadeState: c.crossFadeState('crossFadeState'),
      duration: _animationDuration(c, 'AnimatedCrossFade'),
      firstCurve: c.curve('firstCurve'),
      secondCurve: c.curve('secondCurve'),
      sizeCurve: c.curve('sizeCurve'),
      alignment: c.alignment('alignment') ?? Alignment.topCenter,
      reverseDuration: c.duration('reverseDuration'),
    );
  });

  r.register('AnimatedDefaultTextStyle', (c) {
    final style = c.textStyle('style');
    return AnimatedDefaultTextStyle(
      key: c.key,
      style: style ?? const TextStyle(),
      duration: _animationDuration(c, 'AnimatedDefaultTextStyle'),
      curve: c.curve('curve'),
      textAlign: c.textAlign('textAlign'),
      softWrap: c.bool_('softWrap') ?? true,
      overflow: c.overflow('overflow') ?? TextOverflow.clip,
      maxLines: c.int_('maxLines'),
      child: (c.children['child'] as Widget?) ?? const SizedBox.shrink(),
    );
  });

  r.register(
    'AnimatedPositioned',
    (c) => AnimatedPositioned(
      key: c.key,
      left: c.double_('left'),
      top: c.double_('top'),
      right: c.double_('right'),
      bottom: c.double_('bottom'),
      width: c.double_('width'),
      height: c.double_('height'),
      duration: _animationDuration(c, 'AnimatedPositioned'),
      curve: c.curve('curve'),
      child: (c.children['child'] as Widget?) ?? const SizedBox.shrink(),
    ),
  );

  // ── 过渡动画：宿主直接消费 Animation 句柄，逐帧由 Flutter 原生插值 ──
  r.register('FadeTransition', (c) {
    final animation = jsDoubleAnimationOf(c.props['opacity'], context: c.context);
    final child = c.children['child'] as Widget?;
    if (animation == null) {
      JsLog.warn('FadeTransition: opacity 不是 Animation 句柄，已退化为直接渲染子树');
      return child ?? const SizedBox.shrink();
    }
    return FadeTransition(
      key: c.key,
      opacity: animation,
      alwaysIncludeSemantics: c.bool_('alwaysIncludeSemantics') ?? false,
      child: child,
    );
  });

  r.register('ScaleTransition', (c) {
    final animation = jsDoubleAnimationOf(c.props['scale'], context: c.context);
    final child = c.children['child'] as Widget?;
    if (animation == null) {
      JsLog.warn('ScaleTransition: scale 不是 Animation 句柄，已退化为直接渲染子树');
      return child ?? const SizedBox.shrink();
    }
    return ScaleTransition(
      key: c.key,
      scale: animation,
      alignment: c.alignment('alignment') ?? Alignment.center,
      child: child,
    );
  });

  r.register('RotationTransition', (c) {
    final animation = jsDoubleAnimationOf(c.props['turns'], context: c.context);
    final child = c.children['child'] as Widget?;
    if (animation == null) {
      JsLog.warn('RotationTransition: turns 不是 Animation 句柄，已退化为直接渲染子树');
      return child ?? const SizedBox.shrink();
    }
    return RotationTransition(
      key: c.key,
      turns: animation,
      alignment: c.alignment('alignment') ?? Alignment.center,
      child: child,
    );
  });

  r.register('SizeTransition', (c) {
    final animation = jsDoubleAnimationOf(c.props['sizeFactor'], context: c.context);
    final child = c.children['child'] as Widget?;
    if (animation == null) {
      JsLog.warn('SizeTransition: sizeFactor 不是 Animation 句柄，已退化为直接渲染子树');
      return child ?? const SizedBox.shrink();
    }
    return SizeTransition(
      key: c.key,
      sizeFactor: animation,
      axis: c.axis('axis') ?? Axis.vertical,
      axisAlignment: c.double_('axisAlignment') ?? 0,
      child: child,
    );
  });

  // ── JS 逻辑组件的宿主外壳：子树已由 JS 侧按当前 value 展开 ──
  r.register(
    'AnimatedBuilder',
    (c) => (c.children['child'] as Widget?) ?? const SizedBox.shrink(),
  );
}
