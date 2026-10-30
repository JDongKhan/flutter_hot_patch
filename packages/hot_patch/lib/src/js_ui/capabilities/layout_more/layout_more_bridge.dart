// ===== 能力：布局 / 交互补充 =====
//
// 一批「只有一个 child + 少量标量参数」的常用包装组件：纯映射，无新机制。
// 参数名与 Flutter 构造一致，缺省值取 Flutter 自身默认。
//
//   Tooltip / IgnorePointer / AbsorbPointer / RepaintBoundary / Baseline /
//   FittedBox / RotatedBox / IntrinsicWidth / IntrinsicHeight / LimitedBox /
//   InteractiveViewer
//
// InteractiveViewer 的三个交互回调把宿主侧的 `ScaleStart/Update/EndDetails`
// 折算成 JSON（`{scale, focalPoint, localFocalPoint}`），用户回调留在 JS；
// 它自带的 `transformationController` / `interactionEndFrictionCoefficient` 等
// 细粒度参数不参与翻译（保持 Flutter 默认）。
import 'package:flutter/gestures.dart' show kDefaultMouseScrollToScaleFactor;
import 'package:flutter/material.dart' show Tooltip;
import 'package:flutter/widgets.dart';

import '../../js_widget_registry.dart';
import '../../ui_fallback.dart';
import '../base_widget/text_from_json.dart';
import '../core/from_json/dart_values_from_json.dart';
import '../core/from_json/layout_from_json.dart';
import '../core/from_json/painting_from_json.dart';

void registerLayoutMoreWidgets(JsWidgetRegistry r) {
  r.register(
    'Tooltip',
    (c) => Tooltip(
      message: c.str('message') ?? '',
      waitDuration: durationFromJson(c.props['waitDuration']),
      showDuration: durationFromJson(c.props['showDuration']),
      padding: edgeInsetsFromJson(c.map('padding')),
      margin: edgeInsetsFromJson(c.map('margin')),
      verticalOffset: c.num_('verticalOffset') ?? 24,
      preferBelow: c.bool_('preferBelow'),
      excludeFromSemantics: c.bool_('excludeFromSemantics') ?? false,
      enableTapToDismiss: c.bool_('enableTapToDismiss') ?? true,
      decoration: boxDecorationFromJson(c.map('decoration')),
      textStyle: textStyleFromJson(c.map('textStyle')),
      child: c.children['child'] as Widget?,
    ),
  );

  r.register(
    'IgnorePointer',
    (c) => IgnorePointer(
      ignoring: c.bool_('ignoring') ?? true,
      child: c.children['child'] as Widget?,
    ),
  );

  r.register(
    'AbsorbPointer',
    (c) => AbsorbPointer(
      absorbing: c.bool_('absorbing') ?? true,
      child: c.children['child'] as Widget?,
    ),
  );

  r.register(
    'RepaintBoundary',
    (c) => RepaintBoundary(child: c.children['child'] as Widget?),
  );

  r.register(
    'Baseline',
    (c) => Baseline(
      baseline: c.num_('baseline') ?? 0,
      baselineType: _textBaselineFromJson(c.props['baselineType']) ?? TextBaseline.alphabetic,
      child: c.children['child'] as Widget?,
    ),
  );

  r.register(
    'FittedBox',
    (c) => FittedBox(
      fit: boxFitFromJson(c.props['fit']) ?? BoxFit.contain,
      alignment: alignmentFromJson(c.props['alignment']) ?? Alignment.center,
      clipBehavior: clipBehaviorFromJson(c.props['clipBehavior']) ?? Clip.none,
      child: c.children['child'] as Widget?,
    ),
  );

  r.register(
    'RotatedBox',
    (c) => RotatedBox(
      quarterTurns: c.int_('quarterTurns') ?? 0,
      child: c.children['child'] as Widget?,
    ),
  );

  r.register(
    'IntrinsicWidth',
    (c) => IntrinsicWidth(
      stepWidth: c.num_('stepWidth'),
      stepHeight: c.num_('stepHeight'),
      child: c.children['child'] as Widget?,
    ),
  );

  r.register(
    'IntrinsicHeight',
    (c) => IntrinsicHeight(child: c.children['child'] as Widget?),
  );

  r.register(
    'LimitedBox',
    (c) => LimitedBox(
      maxWidth: c.num_('maxWidth') ?? double.infinity,
      maxHeight: c.num_('maxHeight') ?? double.infinity,
      child: c.children['child'] as Widget?,
    ),
  );

  r.register('InteractiveViewer', (c) {
    final child = c.children['child'] as Widget?;
    if (child == null) {
      return uiFallback('InteractiveViewer.child 缺失');
    }
    final start = c.on1<Map<String, dynamic>>('onInteractionStart');
    final update = c.on1<Map<String, dynamic>>('onInteractionUpdate');
    final end = c.on1<Map<String, dynamic>>('onInteractionEnd');
    return InteractiveViewer(
      minScale: c.num_('minScale') ?? 0.8,
      maxScale: c.num_('maxScale') ?? 2.5,
      panEnabled: c.bool_('panEnabled') ?? true,
      scaleEnabled: c.bool_('scaleEnabled') ?? true,
      scaleFactor: c.num_('scaleFactor') ?? kDefaultMouseScrollToScaleFactor,
      constrained: c.bool_('constrained') ?? true,
      boundaryMargin: edgeInsetsFromJson(c.map('boundaryMargin')),
      onInteractionStart: start == null ? null : (d) => start(_scaleJson(d)),
      onInteractionUpdate: update == null ? null : (d) => update(_scaleJson(d)),
      onInteractionEnd: end == null ? null : (d) => end(_scaleJson(d)),
      child: child,
    );
  });
}

/// 三种 `Scale*Details` 共有的字段（用户回调在 JS 侧只关心这几个）。
Map<String, dynamic> _scaleJson(dynamic d) {
  final focal = d.focalPoint as Offset;
  final local = d.localFocalPoint as Offset;
  return <String, dynamic>{
    'focalPoint': <String, double>{'dx': focal.dx, 'dy': focal.dy},
    'localFocalPoint': <String, double>{'dx': local.dx, 'dy': local.dy},
    // ScaleStartDetails 只有 focalPoint（没有 scale 倍率），其余两个有。
    'scale': d.scale is double ? d.scale as double : 1.0,
    'horizontalScale': d.horizontalScale is double ? d.horizontalScale as double : 1.0,
    'verticalScale': d.verticalScale is double ? d.verticalScale as double : 1.0,
    'rotation': d.rotation is double ? d.rotation as double : 0.0,
  };
}

TextBaseline? _textBaselineFromJson(Object? raw) {
  switch ('$raw') {
    case 'alphabetic':
      return TextBaseline.alphabetic;
    case 'ideographic':
      return TextBaseline.ideographic;
  }
  return null;
}
