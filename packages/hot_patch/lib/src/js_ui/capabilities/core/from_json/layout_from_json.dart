// ===== JSON → Flutter 布局类值（跨组件共用）=====
//
// 边距 / 对齐 / 轴向 / 尺寸约束 / 适配 / 裁剪等纯布局语义的还原。
import 'package:flutter/material.dart';

/// JSON → EdgeInsets（{left,top,right,bottom}；缺省 0）。
EdgeInsets edgeInsetsFromJson(Map<String, dynamic>? json) {
  if (json == null || json.isEmpty) return EdgeInsets.zero;
  double v(Object? x) {
    if (x is num) return x.toDouble();
    return double.tryParse('$x') ?? 0;
  }

  return EdgeInsets.only(
    left: v(json['left']),
    top: v(json['top']),
    right: v(json['right']),
    bottom: v(json['bottom']),
  );
}

/// 缺省 → null（保持 Flutter 组件默认语义）：[edgeInsetsFromJson] 对 null 返回
/// EdgeInsets.zero，但 Chip / ListView / SingleChildScrollView 等组件的
/// padding 是可选参数，null 时应走组件/主题默认值（如 Chip 默认
/// EdgeInsets.all(8.0)）——若用 zero 覆盖，JS 侧渲染会比原生窄。
EdgeInsets? nullableEdgeInsets(Map<String, dynamic>? json) =>
    json == null || json.isEmpty ? null : edgeInsetsFromJson(json);

/// JSON → Alignment（'center'/'topLeft'/...）。
Alignment? alignmentFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'center' => Alignment.center,
    'topLeft' => Alignment.topLeft,
    'topCenter' => Alignment.topCenter,
    'topRight' => Alignment.topRight,
    'centerLeft' => Alignment.centerLeft,
    'centerRight' => Alignment.centerRight,
    'bottomLeft' => Alignment.bottomLeft,
    'bottomCenter' => Alignment.bottomCenter,
    'bottomRight' => Alignment.bottomRight,
    _ => null,
  };
}

/// JSON → MainAxisAlignment。
MainAxisAlignment? mainAxisAlignmentFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'start' => MainAxisAlignment.start,
    'end' => MainAxisAlignment.end,
    'center' => MainAxisAlignment.center,
    'spaceBetween' => MainAxisAlignment.spaceBetween,
    'spaceAround' => MainAxisAlignment.spaceAround,
    'spaceEvenly' => MainAxisAlignment.spaceEvenly,
    _ => null,
  };
}

/// JSON → CrossAxisAlignment。
CrossAxisAlignment? crossAxisAlignmentFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'start' => CrossAxisAlignment.start,
    'end' => CrossAxisAlignment.end,
    'center' => CrossAxisAlignment.center,
    'stretch' => CrossAxisAlignment.stretch,
    'baseline' => CrossAxisAlignment.baseline,
    _ => null,
  };
}

/// JSON → TextBaseline（'alphabetic'/'ideographic'）。
///
/// Flex（Row / Column）用 `CrossAxisAlignment.baseline` 时必须有 textBaseline，
/// 否则 Flutter 断言（`textBaseline is required ...`）。
TextBaseline? textBaselineFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'alphabetic' => TextBaseline.alphabetic,
    'ideographic' => TextBaseline.ideographic,
    _ => null,
  };
}

/// JSON → MainAxisSize（'min'/'max'）。
MainAxisSize? mainAxisSizeFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'min' => MainAxisSize.min,
    'max' => MainAxisSize.max,
    _ => null,
  };
}

/// JSON → Axis（'horizontal'/'vertical'）。
Axis? axisFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'horizontal' => Axis.horizontal,
    'vertical' => Axis.vertical,
    _ => null,
  };
}

/// JSON → BoxFit（'cover'/'contain'/...）。
BoxFit? boxFitFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'cover' => BoxFit.cover,
    'contain' => BoxFit.contain,
    'fill' => BoxFit.fill,
    'fitWidth' => BoxFit.fitWidth,
    'fitHeight' => BoxFit.fitHeight,
    'none' => BoxFit.none,
    'scaleDown' => BoxFit.scaleDown,
    _ => null,
  };
}

/// JSON → StackFit（'loose'/'expand'/'passthrough'）。
StackFit? stackFitFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'loose' => StackFit.loose,
    'expand' => StackFit.expand,
    'passthrough' => StackFit.passthrough,
    _ => null,
  };
}

/// JSON → BoxConstraints（{minWidth, maxWidth, minHeight, maxHeight}）。
BoxConstraints? boxConstraintsFromJson(Map<String, dynamic>? json) {
  if (json == null || json.isEmpty) return null;
  double? v(Object? x) {
    if (x is num) return x.toDouble();
    return double.tryParse('$x');
  }

  return BoxConstraints(
    minWidth: v(json['minWidth']) ?? 0,
    maxWidth: v(json['maxWidth']) ?? double.infinity,
    minHeight: v(json['minHeight']) ?? 0,
    maxHeight: v(json['maxHeight']) ?? double.infinity,
  );
}

/// JSON → WrapAlignment。
WrapAlignment? wrapAlignmentFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'start' => WrapAlignment.start,
    'end' => WrapAlignment.end,
    'center' => WrapAlignment.center,
    'spaceBetween' => WrapAlignment.spaceBetween,
    'spaceAround' => WrapAlignment.spaceAround,
    'spaceEvenly' => WrapAlignment.spaceEvenly,
    _ => null,
  };
}

/// JSON → WrapCrossAlignment。
WrapCrossAlignment? wrapCrossAlignmentFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'start' => WrapCrossAlignment.start,
    'end' => WrapCrossAlignment.end,
    'center' => WrapCrossAlignment.center,
    _ => null,
  };
}

/// JSON → VisualDensity（'compact'/'standard'/'comfortable'）。
VisualDensity? visualDensityFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'compact' => VisualDensity.compact,
    'standard' => VisualDensity.standard,
    'comfortable' => VisualDensity.comfortable,
    _ => null,
  };
}

/// JSON → HitTestBehavior（'deferToChild'/'opaque'/'translucent'）。
HitTestBehavior? hitTestBehaviorFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'deferToChild' => HitTestBehavior.deferToChild,
    'opaque' => HitTestBehavior.opaque,
    'translucent' => HitTestBehavior.translucent,
    _ => null,
  };
}

/// JSON → ImageRepeat（'repeat'/'repeatX'/'repeatY'/'noRepeat'）。
ImageRepeat? imageRepeatFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'repeat' => ImageRepeat.repeat,
    'repeatX' => ImageRepeat.repeatX,
    'repeatY' => ImageRepeat.repeatY,
    'noRepeat' => ImageRepeat.noRepeat,
    _ => null,
  };
}

/// JSON → ClipBehavior（'hardEdge'/'antiAlias'/'antiAliasWithSaveLayer'/'none'）。
Clip? clipBehaviorFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'hardEdge' => Clip.hardEdge,
    'antiAlias' => Clip.antiAlias,
    'antiAliasWithSaveLayer' => Clip.antiAliasWithSaveLayer,
    'none' => Clip.none,
    _ => null,
  };
}
