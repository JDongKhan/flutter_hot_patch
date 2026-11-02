// ===== 能力：Canvas 绘制协议 → dart:ui 值（JSON 还原）=====
//
// JS 侧 `Canvas` 把每次调用录制为数组 op，本文件负责把这些 JSON 还原成
// dart:ui 的 Rect / RRect / Path / Paint / Shader，供宿主逐条重放。
//
// **禁止静默**：无法解析的值、未知 Paint 属性、未知 Path 指令一律
// `HotPatchLog.error`（调用方据此跳过该条，而不是猜一个默认值）。
import 'dart:ui' show ClipOp;

import 'package:flutter/material.dart';

import '../../../utils/hot_patch_log.dart';
import '../core/from_json/dart_values_from_json.dart';
import '../core/from_json/painting_from_json.dart';
import '../core/from_json/widget_enum_from_json.dart';

/// JSON 数字（number / 数字字符串）→ double；无法解析返回 null。
double? _d(Object? v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

/// JSON → Rect（JS `Rect.toJSON` 输出 `[left, top, right, bottom]`）。
Rect? rectFromJson(Object? v) {
  if (v is! List || v.length != 4) return null;
  final l = _d(v[0]);
  final t = _d(v[1]);
  final r = _d(v[2]);
  final b = _d(v[3]);
  if (l == null || t == null || r == null || b == null) return null;
  return Rect.fromLTRB(l, t, r, b);
}

/// JSON → RRect（JS `RRect.toJSON` 输出 12 项：矩形 + 四角半径）。
RRect? rrectFromJson(Object? v) {
  if (v is! List || v.length != 12) return null;
  final rect = rectFromJson([
    v[0], v[1], v[2], v[3],
  ]);
  if (rect == null) return null;
  Radius radius(int i) => Radius.elliptical(_d(v[i]) ?? 0, _d(v[i + 1]) ?? 0);
  return RRect.fromRectAndCorners(
    rect,
    topLeft: radius(4),
    topRight: radius(6),
    bottomRight: radius(8),
    bottomLeft: radius(10),
  );
}

/// JSON → ClipOp（缺省/无法识别时由调用方按 Flutter 默认 `intersect` 处理）。
ClipOp clipOpFromJson(Object? v) => v == 'difference' ? ClipOp.difference : ClipOp.intersect;

/// JSON → PaintingStyle（缺省 `fill`）。
PaintingStyle paintingStyleFromJson(Object? v) =>
    v == 'stroke' ? PaintingStyle.stroke : PaintingStyle.fill;

/// JSON → StrokeCap（缺省 `butt`）。
StrokeCap strokeCapFromJson(Object? v) => switch ('$v') {
  'round' => StrokeCap.round,
  'square' => StrokeCap.square,
  _ => StrokeCap.butt,
};

/// JSON → StrokeJoin（缺省 `miter`）。
StrokeJoin strokeJoinFromJson(Object? v) => switch ('$v') {
  'round' => StrokeJoin.round,
  'bevel' => StrokeJoin.bevel,
  _ => StrokeJoin.miter,
};

/// JSON → Shader。
///
/// 目前唯一的跨桥形态是 `Gradient.createShader(rect)`：
/// `{__gradient: {kind, colors, …}, rect: [left, top, right, bottom]}`。
Shader? shaderFromJson(Object? v) {
  if (v is! Map) return null;
  final gradientJson = v['__gradient'];
  if (gradientJson is! Map) {
    HotPatchLog.error('CustomPaint: Paint.shader 暂只支持 Gradient.createShader（收到 $v）');
    return null;
  }
  final rect = rectFromJson(v['rect']);
  final gradient = gradientFromJson(gradientJson.cast<String, dynamic>());
  if (rect == null || gradient == null) {
    HotPatchLog.error('CustomPaint: 渐变 shader 还原失败（rect=$rect）');
    return null;
  }
  return gradient.createShader(rect);
}

/// Paint 已支持的属性名（其余非空键一律报错）。
const Set<String> _paintKeys = {
  'color',
  'style',
  'strokeWidth',
  'strokeCap',
  'strokeJoin',
  'strokeMiterLimit',
  'isAntiAlias',
  'antiAlias',
  'blendMode',
  'shader',
};

/// JSON → Paint。缺省属性保持 Flutter 默认值。
Paint? paintFromJson(Object? v) {
  if (v is! Map) return null;
  final paint = Paint();
  for (final entry in v.entries) {
    final key = '${entry.key}';
    final value = entry.value;
    if (value == null) continue;
    switch (key) {
      case 'color':
        final color = colorFromJson(value);
        if (color != null) {
          paint.color = color;
        } else {
          HotPatchLog.error('CustomPaint: Paint.color 无法解析: $value');
        }
      case 'style':
        paint.style = paintingStyleFromJson(value);
      case 'strokeWidth':
        final w = _d(value);
        if (w != null) {
          paint.strokeWidth = w;
        } else {
          HotPatchLog.error('CustomPaint: Paint.strokeWidth 无法解析: $value');
        }
      case 'strokeCap':
        paint.strokeCap = strokeCapFromJson(value);
      case 'strokeJoin':
        paint.strokeJoin = strokeJoinFromJson(value);
      case 'strokeMiterLimit':
        final m = _d(value);
        if (m != null) {
          paint.strokeMiterLimit = m;
        } else {
          HotPatchLog.error('CustomPaint: Paint.strokeMiterLimit 无法解析: $value');
        }
      case 'isAntiAlias':
      case 'antiAlias':
        paint.isAntiAlias = value == true;
      case 'blendMode':
        final mode = blendModeFromJson(value);
        if (mode != null) {
          paint.blendMode = mode;
        } else {
          HotPatchLog.error('CustomPaint: Paint.blendMode 无法解析: $value');
        }
      case 'shader':
        final shader = shaderFromJson(value);
        if (shader != null) paint.shader = shader;
      default:
        if (!_paintKeys.contains(key)) {
          HotPatchLog.error('CustomPaint: Paint 属性 "$key" 暂不支持');
        }
    }
  }
  return paint;
}

/// JSON → Path（JS `Path.toJSON` 输出 `{ops: [[指令, …实参], …]}`）。
Path? pathFromJson(Object? v) {
  if (v is! Map) return null;
  final ops = v['ops'];
  if (ops is! List) return null;
  final path = Path();
  for (final raw in ops) {
    if (raw is! List || raw.isEmpty) {
      HotPatchLog.error('CustomPaint: Path 指令形态非法: $raw');
      continue;
    }
    final name = '${raw[0]}';
    switch (name) {
      case 'moveTo':
        final x = _d(raw[1]);
        final y = _d(raw[2]);
        if (x == null || y == null) {
          HotPatchLog.error('CustomPaint: Path.moveTo 实参非法: $raw');
        } else {
          path.moveTo(x, y);
        }
      case 'lineTo':
        final x = _d(raw[1]);
        final y = _d(raw[2]);
        if (x == null || y == null) {
          HotPatchLog.error('CustomPaint: Path.lineTo 实参非法: $raw');
        } else {
          path.lineTo(x, y);
        }
      case 'relativeMoveTo':
        final dx = _d(raw[1]);
        final dy = _d(raw[2]);
        if (dx == null || dy == null) {
          HotPatchLog.error('CustomPaint: Path.relativeMoveTo 实参非法: $raw');
        } else {
          path.relativeMoveTo(dx, dy);
        }
      case 'relativeLineTo':
        final dx = _d(raw[1]);
        final dy = _d(raw[2]);
        if (dx == null || dy == null) {
          HotPatchLog.error('CustomPaint: Path.relativeLineTo 实参非法: $raw');
        } else {
          path.relativeLineTo(dx, dy);
        }
      case 'quadraticBezierTo':
        final a = [
          for (var i = 1; i <= 4; i++) _d(raw[i]),
        ];
        if (a.contains(null)) {
          HotPatchLog.error('CustomPaint: Path.quadraticBezierTo 实参非法: $raw');
        } else {
          path.quadraticBezierTo(a[0]!, a[1]!, a[2]!, a[3]!);
        }
      case 'cubicTo':
        final a = [
          for (var i = 1; i <= 6; i++) _d(raw[i]),
        ];
        if (a.contains(null)) {
          HotPatchLog.error('CustomPaint: Path.cubicTo 实参非法: $raw');
        } else {
          path.cubicTo(a[0]!, a[1]!, a[2]!, a[3]!, a[4]!, a[5]!);
        }
      case 'arcTo':
        final rect = rectFromJson(raw[1]);
        final start = _d(raw[2]);
        final sweep = _d(raw[3]);
        if (rect == null || start == null || sweep == null) {
          HotPatchLog.error('CustomPaint: Path.arcTo 实参非法: $raw');
        } else {
          path.arcTo(rect, start, sweep, raw[4] == true);
        }
      case 'close':
        path.close();
      case 'addRect':
        final rect = rectFromJson(raw[1]);
        if (rect == null) {
          HotPatchLog.error('CustomPaint: Path.addRect 矩形非法: $raw');
        } else {
          if (raw[2] == false) {
            HotPatchLog.error('CustomPaint: Path.addRect 暂不支持 clockwise=false');
          }
          path.addRect(rect);
        }
      case 'addOval':
        final rect = rectFromJson(raw[1]);
        if (rect == null) {
          HotPatchLog.error('CustomPaint: Path.addOval 矩形非法: $raw');
        } else {
          if (raw[2] == false) {
            HotPatchLog.error('CustomPaint: Path.addOval 暂不支持 clockwise=false');
          }
          path.addOval(rect);
        }
      case 'addRRect':
        final rrect = rrectFromJson(raw[1]);
        if (rrect == null) {
          HotPatchLog.error('CustomPaint: Path.addRRect 圆角矩形非法: $raw');
        } else {
          if (raw[2] == false) {
            HotPatchLog.error('CustomPaint: Path.addRRect 暂不支持 clockwise=false');
          }
          path.addRRect(rrect);
        }
      case 'addPolygon':
        final points = raw[1];
        if (points is! List) {
          HotPatchLog.error('CustomPaint: Path.addPolygon 点集非法: $raw');
        } else {
          final offsets = <Offset>[];
          for (final p in points) {
            final o = offsetFromJson(p);
            if (o == null) {
              HotPatchLog.error('CustomPaint: Path.addPolygon 点非法: $p');
              continue;
            }
            offsets.add(o);
          }
          path.addPolygon(offsets, raw[2] == true);
        }
      default:
        HotPatchLog.error('CustomPaint: 未知 Path 指令 "$name"');
    }
  }
  return path;
}
