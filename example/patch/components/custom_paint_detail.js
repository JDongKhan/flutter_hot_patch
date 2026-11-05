// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/custom_paint_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { CanvasImage } from '../base/canvas_image.js';
import { Alignment, Canvas, Center, Color, Column, CrossAxisAlignment, CustomPaint, CustomPainter, FontWeight, LinearGradient, MainAxisSize, Offset, Paint, PaintingStyle, Path, RRect, Radius, Rect, SizedBox, StatefulWidget, StrokeCap, Text, TextAlign, TextDirection, TextPainter, TextSpan, TextStyle } from '../flutter.js';

// 模型 _FramePainter
export class _FramePainter extends CustomPainter {
  constructor(args) {
    super(args);
  }
  paint(canvas, size) {
    const border = new Paint();
    border.color = new Color({value: 0xFF00E676});
    border.style = PaintingStyle.stroke;
    border.strokeWidth = 2;
    canvas.drawRRect(RRect.fromRectAndRadius({rect: Rect.fromLTWH({left: 0, top: 0, width: size.width, height: size.height}), radius: Radius.circular({radius: 12})}), border);
    const dot = new Paint();
    dot.color = new Color({value: 0xFFFF1744});
    canvas.drawCircle(new Offset({dx: (size.width - 16), dy: 16}), 5, dot);
  }
  shouldRepaint(oldDelegate) {
    return false;
  }
}

// 模型 _MediaPainter
export class _MediaPainter extends CustomPainter {
  constructor(args) {
    super(args);
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.image = (args && args.image !== undefined) ? args.image : null;
    this.angle = (args && args.angle !== undefined) ? args.angle : 0.25;
  }
  paint(canvas, size) {
    const bg = new Paint();
    bg.color = new Color({value: 0xFF102027});
    canvas.drawRect(Rect.fromLTWH({left: 0, top: 0, width: size.width, height: size.height}), bg);
    const title = new TextPainter({text: new TextSpan({text: "Canvas 文字排版", style: new TextStyle({color: new Color({value: 0xFFE0F7FA}), fontSize: 18, fontWeight: FontWeight.bold})}), textDirection: TextDirection.ltr, textAlign: TextAlign.center, maxLines: 1});
    title.layout({ "maxWidth": size.width });
    title.paint(canvas, new Offset({dx: 0, dy: 12}));
    canvas.save();
    canvas.translate((size.width / 2), 60);
    canvas.rotate((-0.22));
    const tag = new TextPainter({text: new TextSpan({text: "旋转文字 -12.6°", style: new TextStyle({color: new Color({value: 0xFFFFD54F}), fontSize: 15, fontWeight: FontWeight.bold})}), textDirection: TextDirection.ltr});
    tag.layout({ "maxWidth": 240 });
    tag.paint(canvas, new Offset({dx: (-72), dy: (-12)}));
    canvas.restore();
    const line = new Paint();
    line.color = new Color({value: 0xFF546E7A});
    line.strokeWidth = 1;
    canvas.drawLine(new Offset({dx: 16, dy: 96}), new Offset({dx: (size.width - 16), dy: 96}), line);
    const img = this.image;
    if ((__nn(img) == null)) {
      const waiting = new TextPainter({text: new TextSpan({text: "图片加载中…", style: new TextStyle({color: new Color({value: 0xFF90A4AE}), fontSize: 14})}), textDirection: TextDirection.ltr});
      waiting.layout({ "maxWidth": size.width });
      waiting.paint(canvas, new Offset({dx: 16, dy: 132}));
      return;
    }
    const imgPaint = new Paint();
    canvas.drawImageRect(img, Rect.fromLTWH({left: 0, top: 0, width: img.width.toDouble(), height: img.height.toDouble()}), Rect.fromLTWH({left: 16, top: 108, width: 150, height: 80}), imgPaint);
    canvas.save();
    canvas.translate(276, 148);
    canvas.rotate(this.angle);
    canvas.drawImageRect(img, Rect.fromLTWH({left: (img.width / 3), top: (img.height / 4), width: (img.width / 3), height: (img.height / 3)}), Rect.fromLTWH({left: (-45), top: (-45), width: 90, height: 90}), imgPaint);
    canvas.restore();
  }
  shouldRepaint(oldDelegate) {
    return ((__nn(oldDelegate.image) !== __nn(this.image)) || (oldDelegate.angle !== this.angle));
  }
}

// 模型 _BoardPainter
export class _BoardPainter extends CustomPainter {
  constructor(args) {
    super(args);
  }
  paint(canvas, size) {
    const bg = new Paint();
    bg.color = new Color({value: 0xFF102027});
    canvas.drawRect(Rect.fromLTWH({left: 0, top: 0, width: size.width, height: size.height}), bg);
    const grid = new Paint();
    grid.color = new Color({value: 0xFF37474F});
    grid.strokeWidth = 1;
    for (let i = 1; (i < 8); (i++)) {
      const x = ((size.width / 8) * i);
      canvas.drawLine(new Offset({dx: x, dy: 0}), new Offset({dx: x, dy: size.height}), grid);
    }
    for (let j = 1; (j < 6); (j++)) {
      const y = ((size.height / 6) * j);
      canvas.drawLine(new Offset({dx: 0, dy: y}), new Offset({dx: size.width, dy: y}), grid);
    }
    canvas.save();
    canvas.translate(90, 78);
    canvas.rotate(0.5);
    const fill = new Paint();
    fill.color = new Color({value: 0xFF4DD0E1});
    canvas.drawCircle(new Offset({dx: 0, dy: 0}), 30, fill);
    const ring = new Paint();
    ring.color = new Color({value: 0xFFFFB300});
    ring.style = PaintingStyle.stroke;
    ring.strokeWidth = 4;
    canvas.drawCircle(new Offset({dx: 0, dy: 0}), 42, ring);
    canvas.restore();
    const arc = new Paint();
    arc.color = new Color({value: 0xFF81C784});
    arc.style = PaintingStyle.stroke;
    arc.strokeWidth = 6;
    arc.strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromLTWH({left: 150, top: 24, width: 150, height: 110}), 0.2, 2.4, false, arc);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius({rect: Rect.fromLTWH({left: 170, top: 150, width: 140, height: 70}), radius: Radius.circular({radius: 18})}));
    const clipFill = new Paint();
    clipFill.color = new Color({value: 0x66FF5252});
    canvas.drawCircle(new Offset({dx: 240, dy: 170}), 60, clipFill);
    canvas.restore();
    const path = new Path();
    path.moveTo(10, 190);
    path.quadraticBezierTo(40, 150, 70, 190);
    path.cubicTo(100, 230, 140, 150, 170, 190);
    path.close();
    const pathPaint = new Paint();
    pathPaint.color = new Color({value: 0xFFB388FF});
    pathPaint.style = PaintingStyle.stroke;
    pathPaint.strokeWidth = 3;
    canvas.drawPath(path, pathPaint);
    const gradient = new LinearGradient({begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [new Color({value: 0xFF1A237E}), new Color({value: 0xFF00BCD4})]});
    const shader = gradient.createShader(Rect.fromLTWH({left: 0, top: 0, width: size.width, height: size.height}));
    const shaderPaint = new Paint();
    shaderPaint.shader = shader;
    canvas.drawRRect(RRect.fromRectAndRadius({rect: Rect.fromLTWH({left: 8, top: 196, width: 84, height: 30}), radius: Radius.circular({radius: 10})}), shaderPaint);
    canvas.saveLayer(Rect.fromLTWH({left: 0, top: 0, width: size.width, height: size.height}), new Paint());
    const overlay = new Paint();
    overlay.color = new Color({value: 0x33FFFFFF});
    canvas.drawRect(Rect.fromLTWH({left: 150, top: 150, width: 160, height: 70}), overlay);
    canvas.restore();
  }
  shouldRepaint(oldDelegate) {
    return false;
  }
}

// 组件 CustomPaintDetail
export class CustomPaintDetail extends StatefulWidget {
  constructor(args) {
    super(args);
    this._photo = null;
  }
  initState() {
    super.initState();
    this._loadPhoto();
  }
  async _loadPhoto() {
    const img = await CanvasImage.load("assets/images/photo-1504280390367-361c6d9f38f4.jpg");
    this.setState(() => {
      this._photo = img;
    });
  }
  build(context) {
    return new Column({
      "mainAxisSize": MainAxisSize.min,
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "CustomPaint · 图元 / 变换 / 裁剪 / Path / 渐变 / saveLayer",
          "style": new TextStyle({
            "fontSize": 13,
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new Center({
          "child": new SizedBox({
            "width": 360,
            "height": 240,
            "child": new CustomPaint({
              "painter": new _BoardPainter({})
            })
          })
        }),
        (this.__k2 || (this.__k2 = new SizedBox({
          "height": 12
        }))),
        (this.__k3 || (this.__k3 = new Text({
          "data": "文字排版 + 图片（含旋转 / 裁剪）",
          "style": new TextStyle({
            "fontSize": 13,
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new Center({
          "child": new SizedBox({
            "width": 360,
            "height": 200,
            "child": new CustomPaint({
              "painter": new _MediaPainter({
                "image": this._photo
              })
            })
          })
        }),
        (this.__k2 || (this.__k2 = new SizedBox({
          "height": 12
        }))),
        (this.__k4 || (this.__k4 = new Text({
          "data": "foregroundPainter：画在 child 之上（边框 + 红点）",
          "style": new TextStyle({
            "fontSize": 13,
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new SizedBox({
          "height": 72,
          "child": new CustomPaint({
            "foregroundPainter": new _FramePainter({}),
            "child": (this.__k5 || (this.__k5 = new Center({
              "child": new Text({
                "data": "child 内容在两层绘制之间"
              })
            })))
          })
        })
      ]
    });
  }
}

