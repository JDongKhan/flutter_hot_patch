import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

import '../base/canvas_image.dart';

/// CustomPaint 演示：图元 / 变换 / 裁剪 / Path / 渐变 shader / saveLayer /
/// 文字 / 图片（含旋转）。
///
/// 约定：`CustomPainter` 在 JS 侧是值类（句柄 `canvasPainter`），`paint(canvas, size)`
/// 里对 `Canvas` 的调用被**录制**成 JSON ops，再由宿主用 dart:ui 的 Canvas 重放：
///   - `TextPainter` 只录制 span 与 layout 约束，排版/字体由宿主完成；
///   - 图片经 `CanvasImage.load` 拿到句柄，`drawImage*` 只记录句柄；
///   - 文字/图片的旋转由 `save / translate / rotate` 的矩阵自然生效。
@PatchEntry('CustomPaintDetail')
class CustomPaintDetail extends StatefulWidget {
  const CustomPaintDetail({super.key});

  @override
  State<CustomPaintDetail> createState() => _CustomPaintDetailState();
}

class _CustomPaintDetailState extends State<CustomPaintDetail> {
  /// 宿主加载回来的图片句柄（JS 侧是 `{__handle, width, height}`）。
  ui.Image? _photo;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  Future<void> _loadPhoto() async {
    final img = await CanvasImage.load(
      'assets/images/photo-1504280390367-361c6d9f38f4.jpg',
    );
    setState(() => _photo = img);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'CustomPaint · 图元 / 变换 / 裁剪 / Path / 渐变 / saveLayer',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Center(
          child: SizedBox(
            width: 360,
            height: 240,
            child: CustomPaint(painter: _BoardPainter()),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '文字排版 + 图片（含旋转 / 裁剪）',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Center(
          child: SizedBox(
            width: 360,
            height: 200,
            child: CustomPaint(painter: _MediaPainter(image: _photo)),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'foregroundPainter：画在 child 之上（边框 + 红点）',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 72,
          child: CustomPaint(
            foregroundPainter: _FramePainter(),
            child: const Center(child: Text('child 内容在两层绘制之间')),
          ),
        ),
      ],
    );
  }
}

class _BoardPainter extends CustomPainter {
  const _BoardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // 背景
    final bg = Paint();
    bg.color = const Color(0xFF102027);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    // 网格
    final grid = Paint();
    grid.color = const Color(0xFF37474F);
    grid.strokeWidth = 1;
    for (int i = 1; i < 8; i++) {
      final x = size.width / 8 * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (int j = 1; j < 6; j++) {
      final y = size.height / 6 * j;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // save / translate / rotate + 圆 + 圆环
    canvas.save();
    canvas.translate(90, 78);
    canvas.rotate(0.5);
    final fill = Paint();
    fill.color = const Color(0xFF4DD0E1);
    canvas.drawCircle(const Offset(0, 0), 30, fill);
    final ring = Paint();
    ring.color = const Color(0xFFFFB300);
    ring.style = PaintingStyle.stroke;
    ring.strokeWidth = 4;
    canvas.drawCircle(const Offset(0, 0), 42, ring);
    canvas.restore();

    // 弧
    final arc = Paint();
    arc.color = const Color(0xFF81C784);
    arc.style = PaintingStyle.stroke;
    arc.strokeWidth = 6;
    arc.strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromLTWH(150, 24, 150, 110), 0.2, 2.4, false, arc);

    // clipRRect + 圆
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(170, 150, 140, 70),
        const Radius.circular(18),
      ),
    );
    final clipFill = Paint();
    clipFill.color = const Color(0x66FF5252);
    canvas.drawCircle(const Offset(240, 170), 60, clipFill);
    canvas.restore();

    // Path 曲线
    final path = Path();
    path.moveTo(10, 190);
    path.quadraticBezierTo(40, 150, 70, 190);
    path.cubicTo(100, 230, 140, 150, 170, 190);
    path.close();
    final pathPaint = Paint();
    pathPaint.color = const Color(0xFFB388FF);
    pathPaint.style = PaintingStyle.stroke;
    pathPaint.strokeWidth = 3;
    canvas.drawPath(path, pathPaint);

    // 渐变 shader
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [const Color(0xFF1A237E), const Color(0xFF00BCD4)],
    );
    final shader = gradient.createShader(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );
    final shaderPaint = Paint();
    shaderPaint.shader = shader;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8, 196, 84, 30),
        const Radius.circular(10),
      ),
      shaderPaint,
    );

    // saveLayer：半透明覆盖层
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    final overlay = Paint();
    overlay.color = const Color(0x33FFFFFF);
    canvas.drawRect(Rect.fromLTWH(150, 150, 160, 70), overlay);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FramePainter extends CustomPainter {
  const _FramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint();
    border.color = const Color(0xFF00E676);
    border.style = PaintingStyle.stroke;
    border.strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(12),
      ),
      border,
    );
    final dot = Paint();
    dot.color = const Color(0xFFFF1744);
    canvas.drawCircle(Offset(size.width - 16, 16), 5, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 文字 + 图片（含旋转）演示。
///
/// `TextPainter` / `drawImageRect` 在 JS 侧都只录制，排版与像素合成由宿主完成；
/// 旋转完全复用 `save / translate / rotate` 的矩阵能力（无需新协议）。
class _MediaPainter extends CustomPainter {
  _MediaPainter({this.image, this.angle = 0.25});

  /// 宿主返回的图片句柄（未加载完时为 null）。
  final ui.Image? image;

  /// 右上图片的旋转弧度。
  final double angle;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint();
    bg.color = const Color(0xFF102027);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    // 文字：居中标题（layout 约束由 JS 录制，排版由宿主完成）。
    final title = TextPainter(
      text: TextSpan(
        text: 'Canvas 文字排版',
        style: TextStyle(
          color: const Color(0xFFE0F7FA),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 1,
    );
    title.layout(maxWidth: size.width);
    title.paint(canvas, Offset(0, 12));

    // 旋转文字：save / translate / rotate 复用已有矩阵。
    canvas.save();
    canvas.translate(size.width / 2, 60);
    canvas.rotate(-0.22);
    final tag = TextPainter(
      text: TextSpan(
        text: '旋转文字 -12.6°',
        style: TextStyle(
          color: const Color(0xFFFFD54F),
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tag.layout(maxWidth: 240);
    tag.paint(canvas, Offset(-72, -12));
    canvas.restore();

    final line = Paint();
    line.color = const Color(0xFF546E7A);
    line.strokeWidth = 1;
    canvas.drawLine(Offset(16, 96), Offset(size.width - 16, 96), line);

    final img = image;
    if (img == null) {
      final waiting = TextPainter(
        text: TextSpan(
          text: '图片加载中…',
          style: TextStyle(color: const Color(0xFF90A4AE), fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
      );
      waiting.layout(maxWidth: size.width);
      waiting.paint(canvas, Offset(16, 132));
      return;
    }

    final imgPaint = Paint();

    // 原图：整图铺进左侧矩形（drawImageRect 同时完成缩放）。
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      Rect.fromLTWH(16, 108, 150, 80),
      imgPaint,
    );

    // 旋转 + 裁剪：取原图中部一块，旋转后画在右侧。
    canvas.save();
    canvas.translate(276, 148);
    canvas.rotate(angle);
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(
        img.width / 3,
        img.height / 4,
        img.width / 3,
        img.height / 3,
      ),
      Rect.fromLTWH(-45, -45, 90, 90),
      imgPaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MediaPainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.angle != angle;
}
