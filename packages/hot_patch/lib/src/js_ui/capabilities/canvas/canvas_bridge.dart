// ===== 能力：CustomPaint（宿主渲染 + JS 绘制录制重放）=====
//
// 架构（见生成器 `runtime/js/canvas_js.dart`）：
//   - JS 侧 `CustomPainter` 是**值类 + 句柄**（`canvasPainter`，sync:false）；
//     `CustomPaint(painter: …)` 的 `painter` 跨桥后是 `{'__handle': id}`；
//   - 宿主把该 id 包成 [_JsPainter]。paint 阶段**同步**求值
//     `__jsui.call(id, 'call', {method:'__record', args:[size]})` 取回
//     `{v:1, ops:[…]}`，再用真实 Canvas 逐条重放；
//   - 录制结果按 (size) 缓存在当前 [_JsPainter] 实例上：同一尺寸重复绘制不重复
//     求值，尺寸变化（窗口缩放）时重新录制。
//
// 不支持的能力在 JS 侧抛错（evaluate 会记 HotPatchLog.error）或在这里报错，
// 不做任何静默降级。
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../services/js_runtime_manager.dart';
import '../../../utils/hot_patch_log.dart';
import '../../js_widget_registry.dart';
import '../core/from_json/dart_values_from_json.dart';
import 'canvas_from_json.dart';
import 'canvas_image_registry.dart';

/// CustomPaint 宿主组件注册（能力库钩子）。
void registerCanvasWidgets(JsWidgetRegistry r) {
  r.register('CustomPaint', (c) {
    return CustomPaint(
      painter: _painterFromProp(c.props['painter'], 'painter'),
      foregroundPainter: _painterFromProp(c.props['foregroundPainter'], 'foregroundPainter'),
      size: sizeFromJson(c.props['size']) ?? Size.zero,
      isComplex: c.bool_('isComplex') ?? false,
      willChange: c.bool_('willChange') ?? false,
      child: c.children['child'] as Widget?,
    );
  });
}

/// `painter` / `foregroundPainter` prop（`{'__handle': id}`）→ 宿主 painter。
CustomPainter? _painterFromProp(Object? raw, String name) {
  if (raw == null) return null;
  if (raw is Map) {
    final id = raw['__handle'];
    if (id is String && id.isNotEmpty) return _JsPainter(id);
  }
  HotPatchLog.error('CustomPaint: $name 不是 CustomPainter 句柄: $raw');
  return null;
}

/// JS `CustomPainter` 句柄的宿主代理：录制 + 重放。
class _JsPainter extends CustomPainter {
  _JsPainter(this.handleId);

  /// JS 侧句柄 id（`js:canvasPainter#N`）。
  final String handleId;

  final Map<String, List<List<dynamic>>> _opsBySize = {};
  bool _failed = false;

  @override
  void paint(Canvas canvas, Size size) {
    final ops = _record(size);
    if (ops == null) return;
    _replay(canvas, ops);
  }

  @override
  bool shouldRepaint(covariant _JsPainter oldDelegate) =>
      oldDelegate.handleId != handleId;

  /// 同步取回录制结果（按 size 缓存）。
  List<List<dynamic>>? _record(Size size) {
    final cacheKey = '${size.width}x${size.height}';
    final cached = _opsBySize[cacheKey];
    if (cached != null) return cached;
    if (_failed) return null;

    final code =
        'JSON.stringify(__jsui.call(${jsonEncode(handleId)}, "call", '
        '{"method":"__record","args":[{"width":${size.width},'
        '"height":${size.height}}]}))';
    final result = JsRuntimeManager.instance.evaluate(code);
    if (result.isError) {
      // evaluate 已记日志；标记失败避免每帧刷屏。
      _failed = true;
      return null;
    }
    final text = result.stringResult;
    if (text.isEmpty || text == 'undefined' || text == 'null') {
      _failed = true;
      HotPatchLog.error('CustomPaint: painter($handleId) 录制失败（句柄可能已释放）');
      return null;
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } catch (e) {
      _failed = true;
      HotPatchLog.error('CustomPaint: 录制结果不是合法 JSON: $e');
      return null;
    }
    if (decoded is! Map) {
      _failed = true;
      HotPatchLog.error('CustomPaint: 录制结果形态非法: $text');
      return null;
    }
    final ops = decoded['ops'];
    if (ops is! List) {
      _failed = true;
      HotPatchLog.error('CustomPaint: 录制结果缺少 ops: $text');
      return null;
    }
    final list = <List<dynamic>>[];
    for (final op in ops) {
      if (op is List && op.isNotEmpty) {
        list.add(op);
      } else {
        HotPatchLog.error('CustomPaint: 绘制指令形态非法: $op');
      }
    }
    _opsBySize[cacheKey] = list;
    return list;
  }

  /// 用 dart:ui 的 Canvas 逐条重放录制指令。
  void _replay(Canvas canvas, List<List<dynamic>> ops) {
    for (final op in ops) {
      final name = '${op[0]}';
      switch (name) {
        case 'save':
          canvas.save();
        case 'restore':
          canvas.restore();
        case 'saveLayer':
          canvas.saveLayer(
            rectFromJson(op[1]),
            paintFromJson(op[2]) ?? Paint(),
          );
        case 'translate':
          final dx = _num(op[1]);
          final dy = _num(op[2]);
          if (dx != null && dy != null) {
            canvas.translate(dx, dy);
          } else {
            _badOp(name, op);
          }
        case 'scale':
          final sx = _num(op[1]);
          final sy = _num(op[2]);
          if (sx != null && sy != null) {
            canvas.scale(sx, sy);
          } else {
            _badOp(name, op);
          }
        case 'rotate':
          final radians = _num(op[1]);
          if (radians != null) {
            canvas.rotate(radians);
          } else {
            _badOp(name, op);
          }
        case 'clipRect':
          final rect = rectFromJson(op[1]);
          if (rect == null) {
            _badOp(name, op);
          } else {
            canvas.clipRect(
              rect,
              clipOp: clipOpFromJson(op[2]),
              doAntiAlias: op[3] != false,
            );
          }
        case 'clipRRect':
          final rrect = rrectFromJson(op[1]);
          if (rrect == null) {
            _badOp(name, op);
          } else {
            // dart:ui 的 clipRRect 没有 clipOp（只支持 intersect 语义）。
            if (op[2] == 'difference') {
              HotPatchLog.error('CustomPaint: Canvas.clipRRect 不支持 clipOp=difference');
            }
            canvas.clipRRect(rrect, doAntiAlias: op[3] != false);
          }
        case 'clipPath':
          final path = pathFromJson(op[1]);
          if (path == null) {
            _badOp(name, op);
          } else {
            // dart:ui 的 clipPath 没有 clipOp（只支持 intersect 语义）。
            if (op[2] == 'difference') {
              HotPatchLog.error('CustomPaint: Canvas.clipPath 不支持 clipOp=difference');
            }
            canvas.clipPath(path, doAntiAlias: op[3] != false);
          }
        case 'drawRect':
          final rect = rectFromJson(op[1]);
          final paint = paintFromJson(op[2]);
          if (rect == null || paint == null) {
            _badOp(name, op);
          } else {
            canvas.drawRect(rect, paint);
          }
        case 'drawRRect':
          final rrect = rrectFromJson(op[1]);
          final paint = paintFromJson(op[2]);
          if (rrect == null || paint == null) {
            _badOp(name, op);
          } else {
            canvas.drawRRect(rrect, paint);
          }
        case 'drawPath':
          final path = pathFromJson(op[1]);
          final paint = paintFromJson(op[2]);
          if (path == null || paint == null) {
            _badOp(name, op);
          } else {
            canvas.drawPath(path, paint);
          }
        case 'drawLine':
          final p1 = offsetFromJson(op[1]);
          final p2 = offsetFromJson(op[2]);
          final paint = paintFromJson(op[3]);
          if (p1 == null || p2 == null || paint == null) {
            _badOp(name, op);
          } else {
            canvas.drawLine(p1, p2, paint);
          }
        case 'drawCircle':
          final center = offsetFromJson(op[1]);
          final radius = _num(op[2]);
          final paint = paintFromJson(op[3]);
          if (center == null || radius == null || paint == null) {
            _badOp(name, op);
          } else {
            canvas.drawCircle(center, radius, paint);
          }
        case 'drawOval':
          final rect = rectFromJson(op[1]);
          final paint = paintFromJson(op[2]);
          if (rect == null || paint == null) {
            _badOp(name, op);
          } else {
            canvas.drawOval(rect, paint);
          }
        case 'drawArc':
          final rect = rectFromJson(op[1]);
          final startAngle = _num(op[2]);
          final sweepAngle = _num(op[3]);
          final paint = paintFromJson(op[5]);
          if (rect == null || startAngle == null || sweepAngle == null || paint == null) {
            _badOp(name, op);
          } else {
            canvas.drawArc(rect, startAngle, sweepAngle, op[4] == true, paint);
          }
        case 'drawPaint':
          final paint = paintFromJson(op[1]);
          if (paint == null) {
            _badOp(name, op);
          } else {
            canvas.drawPaint(paint);
          }
        case 'drawText':
          // JS TextPainter 只录制 span + 排版选项；这里重建真实 TextPainter
          // 完成排版并绘制（offset 是 TextPainter.paint 的实参）。
          final painter = textPainterFromJson(op[1], op[3]);
          final offset = offsetFromJson(op[2]);
          if (painter == null || offset == null) {
            _badOp(name, op);
          } else {
            painter.paint(canvas, offset);
            painter.dispose();
          }
        case 'drawImage':
          final image = canvasImageFromJson(op[1]);
          final offset = offsetFromJson(op[2]);
          final paint = paintFromJson(op[3]);
          if (image == null || offset == null || paint == null) {
            _badOp(name, op);
          } else {
            canvas.drawImage(image, offset, paint);
          }
        case 'drawImageRect':
          final image = canvasImageFromJson(op[1]);
          final src = rectFromJson(op[2]);
          final dst = rectFromJson(op[3]);
          final paint = paintFromJson(op[4]);
          if (image == null || src == null || dst == null || paint == null) {
            _badOp(name, op);
          } else {
            canvas.drawImageRect(image, src, dst, paint);
          }
        default:
          HotPatchLog.error('CustomPaint: 未知绘制指令 "$name"');
      }
    }
  }

  /// 数字实参（number / 数字字符串）。
  double? _num(Object? v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  void _badOp(String name, List<dynamic> op) {
    HotPatchLog.error('CustomPaint: 绘制指令 "$name" 实参非法: $op');
  }
}
