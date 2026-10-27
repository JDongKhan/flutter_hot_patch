// ===== JSON → Flutter 绘制类值（跨组件共用）=====
//
// 边框 / 圆角 / 阴影 / 渐变 / 装饰 / 形状：容器类组件的视觉参数。
import 'package:flutter/material.dart';

import 'dart_values_from_json.dart';
import 'layout_from_json.dart';
import 'widget_enum_from_json.dart';

/// JSON → ColorFilter（{kind:'mode', color, blendMode} /
/// {kind:'matrix', matrix:[20 个数字]} / {kind:'linearToSrgbGamma'} /
/// {kind:'srgbToLinearGamma'}）。
///
/// 矩阵长度必须为 20（Flutter 侧矩阵滤镜的硬约束），不满足时返回 null，
/// 由调用方决定降级方式。
ColorFilter? colorFilterFromJson(Object? v) {
  if (v is! Map) return null;
  switch ('${v['kind']}') {
    case 'mode':
      final color = colorFromJson(v['color']);
      final mode = blendModeFromJson(v['blendMode']);
      if (color == null || mode == null) return null;
      return ColorFilter.mode(color, mode);
    case 'matrix':
      final raw = v['matrix'];
      if (raw is! List || raw.length != 20) return null;
      final matrix = <double>[];
      for (final e in raw) {
        final n = e is num ? e.toDouble() : double.tryParse('$e');
        if (n == null) return null;
        matrix.add(n);
      }
      return ColorFilter.matrix(matrix);
    case 'linearToSrgbGamma':
      return const ColorFilter.linearToSrgbGamma();
    case 'srgbToLinearGamma':
      return const ColorFilter.srgbToLinearGamma();
  }
  return null;
}

/// JSON → BorderSide（{'color':..,'width':..,'style':..}）。
BorderSide? borderSideFromJson(Object? v) {
  if (v is! Map) return null;
  final c = colorFromJson(v['color']);
  final w = (v['width'] as num?)?.toDouble();
  return BorderSide(
    color: c ?? const Color(0xFF000000),
    width: w ?? 1.0,
    style: v['style'] == 'none' ? BorderStyle.none : BorderStyle.solid,
  );
}

/// JSON → BorderRadius（{radius: n} 统一圆角，或
/// {topLeft, topRight, bottomLeft, bottomRight} 四角独立；缺省角 = 0）。
BorderRadius? borderRadiusFromJson(Map<String, dynamic>? json) {
  if (json == null) return null;
  double? v(Object? x) {
    if (x is num) return x.toDouble();
    return double.tryParse('$x');
  }

  final r = v(json['radius']);
  if (r != null) return BorderRadius.circular(r);
  final tl = v(json['topLeft']);
  final tr = v(json['topRight']);
  final bl = v(json['bottomLeft']);
  final br = v(json['bottomRight']);
  if (tl == null && tr == null && bl == null && br == null) return null;
  return BorderRadius.only(
    topLeft: Radius.circular(tl ?? 0),
    topRight: Radius.circular(tr ?? 0),
    bottomLeft: Radius.circular(bl ?? 0),
    bottomRight: Radius.circular(br ?? 0),
  );
}

/// JSON → Border（{'all': borderSide} 四边统一，或
/// {'top': ..., 'right': ..., 'bottom': ..., 'left': ...} 四边独立）。
Border? borderFromJson(Map<String, dynamic>? json) {
  if (json == null || json.isEmpty) return null;
  final all = borderSideFromJson(json['all']);
  if (all != null) return Border.fromBorderSide(all);
  return Border(
    top: borderSideFromJson(json['top']) ?? BorderSide.none,
    right: borderSideFromJson(json['right']) ?? BorderSide.none,
    bottom: borderSideFromJson(json['bottom']) ?? BorderSide.none,
    left: borderSideFromJson(json['left']) ?? BorderSide.none,
  );
}

/// JSON → BoxShadow（{'color': c, 'dx': n, 'dy': n, 'blur': n, 'spread': n,
/// 'blurStyle': s}）。
BoxShadow? boxShadowFromJson(Object? v) {
  if (v is! Map) return null;
  double d(Object? x) {
    if (x is num) return x.toDouble();
    return double.tryParse('$x') ?? 0;
  }

  return BoxShadow(
    color: colorFromJson(v['color']) ?? const Color(0xFF000000),
    offset: Offset(d(v['dx']), d(v['dy'])),
    blurRadius: d(v['blur']),
    spreadRadius: d(v['spread']),
    blurStyle: switch (v['blurStyle']) {
      'solid' => BlurStyle.solid,
      'outer' => BlurStyle.outer,
      'inner' => BlurStyle.inner,
      _ => BlurStyle.normal,
    },
  );
}

/// JSON → BoxShadow 列表。
List<BoxShadow>? boxShadowListFromJson(Object? v) {
  if (v is! List) return null;
  final list = [for (final e in v) boxShadowFromJson(e)].nonNulls.toList();
  return list.isEmpty ? null : list;
}

/// JSON → Gradient（{kind:'linear'|'radial'|'sweep', colors, begin/end/center,
/// radius, stops}）。
Gradient? gradientFromJson(Map<String, dynamic>? json) {
  if (json == null) return null;
  final colors = (json['colors'] as List?)
      ?.map(colorFromJson)
      .nonNulls
      .toList();
  if (colors == null || colors.length < 2) return null;
  final stops = (json['stops'] as List?)
      ?.map((x) => x is num ? x.toDouble() : double.tryParse('$x'))
      .nonNulls
      .toList();
  double? radius() {
    final r = json['radius'];
    return r is num ? r.toDouble() : double.tryParse('$r');
  }

  return switch (json['kind']) {
    'radial' => RadialGradient(
        colors: colors,
        stops: stops,
        center: alignmentFromJson(json['center']) ?? Alignment.center,
        radius: radius() ?? 0.5,
      ),
    'sweep' => SweepGradient(
        colors: colors,
        stops: stops,
        center: alignmentFromJson(json['center']) ?? Alignment.center,
      ),
    _ => LinearGradient(
        colors: colors,
        stops: stops,
        begin: alignmentFromJson(json['begin']) ?? Alignment.centerLeft,
        end: alignmentFromJson(json['end']) ?? Alignment.centerRight,
      ),
  };
}

/// JSON → DecorationImage（{source, fit}）。
DecorationImage? decorationImageFromJson(Map<String, dynamic>? json) {
  if (json == null) return null;
  final source = json['source'];
  if (source is! String || source.isEmpty) return null;
  return DecorationImage(
    image: source.startsWith('http')
        ? NetworkImage(source)
        : AssetImage(source) as ImageProvider,
    fit: boxFitFromJson(json['fit']),
  );
}

/// JSON → OutlinedBorder（{kind:'rounded'|'stadium'|'circle'|'beveled'|
/// 'continuous', borderRadius?, side?}）。
OutlinedBorder? shapeFromJson(Object? v) {
  if (v is! Map) return null;
  final radius = borderRadiusFromJson(
    v['borderRadius'] is Map
        ? (v['borderRadius'] as Map).cast<String, dynamic>()
        : null,
  );
  final side = borderSideFromJson(v['side']) ?? BorderSide.none;
  return switch (v['kind']) {
    'stadium' => StadiumBorder(side: side),
    'circle' => CircleBorder(side: side),
    'beveled' => BeveledRectangleBorder(
        borderRadius: radius ?? BorderRadius.zero, side: side),
    'continuous' => ContinuousRectangleBorder(
        borderRadius: radius ?? BorderRadius.zero, side: side),
    _ => RoundedRectangleBorder(
        borderRadius: radius ?? BorderRadius.zero, side: side),
  };
}

/// JSON → BoxDecoration（{color, borderRadius, border, boxShadow, gradient,
/// shape, image}）。
BoxDecoration? boxDecorationFromJson(Map<String, dynamic>? json) {
  if (json == null || json.isEmpty) return null;
  return BoxDecoration(
    color: colorFromJson(json['color']),
    borderRadius: borderRadiusFromJson(
      json['borderRadius'] is Map
          ? (json['borderRadius'] as Map).cast<String, dynamic>()
          : null,
    ),
    border: borderFromJson(
      json['border'] is Map
          ? (json['border'] as Map).cast<String, dynamic>()
          : null,
    ),
    boxShadow: boxShadowListFromJson(json['boxShadow']),
    gradient: gradientFromJson(
      json['gradient'] is Map
          ? (json['gradient'] as Map).cast<String, dynamic>()
          : null,
    ),
    shape: switch (json['shape']) {
      'circle' => BoxShape.circle,
      _ => BoxShape.rectangle,
    },
    image: decorationImageFromJson(
      json['image'] is Map
          ? (json['image'] as Map).cast<String, dynamic>()
          : null,
    ),
  );
}
