// ===== JSON → Flutter 绘制类值（跨组件共用）=====
//
// 边框 / 圆角 / 阴影 / 渐变 / 装饰 / 形状：容器类组件的视觉参数。
import 'dart:typed_data';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'dart_values_from_json.dart';
import 'layout_from_json.dart';
import 'widget_enum_from_json.dart';

/// JSON → ImageFilter（{kind:'blur', sigmaX, sigmaY, tileMode} /
/// {kind:'dilate'|'erode', radiusX, radiusY} /
/// {kind:'matrix', matrix4:[16 个数字]}（键名与 SDK 构造形参一致）/
/// {kind:'compose', outer, inner}）。
///
/// 矩阵长度必须为 16（4×4），不满足时返回 null；[compose] 递归还原内外两层。
ImageFilter? imageFilterFromJson(Object? v) {
  if (v is! Map) return null;
  double? num_(Object? x) {
    if (x is num) return x.toDouble();
    return double.tryParse('$x');
  }

  switch ('${v['kind']}') {
    case 'blur':
      final sx = num_(v['sigmaX']);
      final sy = num_(v['sigmaY']);
      if (sx == null || sy == null) return null;
      return ImageFilter.blur(sigmaX: sx, sigmaY: sy, tileMode: _tileModeFromJson(v['tileMode']));
    case 'dilate':
      final rx = num_(v['radiusX']);
      final ry = num_(v['radiusY']);
      if (rx == null || ry == null) return null;
      return ImageFilter.dilate(radiusX: rx, radiusY: ry);
    case 'erode':
      final rx = num_(v['radiusX']);
      final ry = num_(v['radiusY']);
      if (rx == null || ry == null) return null;
      return ImageFilter.erode(radiusX: rx, radiusY: ry);
    case 'matrix':
      // `ImageFilter.matrix(Float64List matrix4)` 的位置形参名就是 `matrix4`
      // （见 SDK 的 factory 签名），翻译层按形参名原样下发，故这里读同名键。
      final raw = v['matrix4'];
      if (raw is! List || raw.length != 16) return null;
      final matrix = <double>[];
      for (final e in raw) {
        final n = num_(e);
        if (n == null) return null;
        matrix.add(n);
      }
      return ImageFilter.matrix(Float64List.fromList(matrix));
    case 'compose':
      final outer = imageFilterFromJson(v['outer']);
      final inner = imageFilterFromJson(v['inner']);
      if (outer == null || inner == null) return null;
      return ImageFilter.compose(outer: outer, inner: inner);
  }
  return null;
}

/// `TileMode` 枚举名 → 枚举值（缺省 null = Flutter 默认 `clamp`）。
TileMode? _tileModeFromJson(Object? v) => switch ('$v') {
  'clamp' => TileMode.clamp,
  'repeated' => TileMode.repeated,
  'mirror' => TileMode.mirror,
  'decal' => TileMode.decal,
  _ => null,
};

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

/// JSON → DecorationImage（{source, fit}）。`source` 是 provider 值的跨桥形态
/// （源字符串），按 `http` 前缀还原网络图 / 资源图。
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
