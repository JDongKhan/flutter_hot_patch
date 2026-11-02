// ===== 基础能力：Canvas / Paint / Path 值类镜像（JS 侧片段）=====
//
// `CustomPaint(painter: ...)` 的 `CustomPainter.paint(canvas, size)` 在宿主
// 绘制阶段**没有异步桥可用**（paint 是同步的），因此采用「录制 + 重放」：
//
//   1. 宿主在 paint 时用 `__jsui.call(id, 'call', {method:'__record', args:[size]})`
//      **同步**求值一次 `__record(size)`；
//   2. `__record` 新建一个录制型 [Canvas]，调用用户 `paint(canvas, size)`，
//      返回 `{v:1, ops:[...]}`（每个 op 是一个数组，首项是方法名）；
//   3. 宿主解析 ops，用 dart:ui 的真实 Canvas 逐条重放，并按 (handle, size) 缓存。
//
// 值类镜像的职责只有「记录参数 + toJSON 成宿主认得的 JSON」：
//   Rect   → [left, top, right, bottom]
//   RRect  → [left, top, right, bottom, tlX, tlY, trX, trY, brX, brY, blX, blY]
//   Path   → {ops: [[method, ...args], ...]}（参数里可含 Rect / RRect）
//   Paint  → 自身非空属性（color → '#AARRGGBB'，枚举 → 成员名，shader → 协议对象）
//
// 文字 / 图片：
//   - `TextPainter` 在 JS 侧只记录**构造参数 + layout 约束**（JS 无法同步测量
//     文本），`paint(canvas, offset)` 压入 `['drawText', span, offset, layout]`；
//     宿主用真实 `TextPainter` 排版并绘制。
//   - `Canvas.drawImage` / `drawImageRect` 的 image 实参是**宿主返回值里的图片
//     句柄**（`{__handle, width, height}`）：JS 从不持有像素，只按 id 回传给宿主。
//     旋转由 `save/translate/rotate` 的矩阵自然生效，无需额外协议。
//
// 不支持的能力**必须出声**：`drawImageNine` / `drawParagraph` / `toImage` 等直接
// 抛异常，由宿主 JsRuntimeManager.evaluate 记 HotPatchLog.error（禁止静默降级）。
const String canvasJsSource = r'''
  // ---------------------------------------------------------------------------
  // Rect：`Rect.fromLTWH(...)` 等命名构造在 JS 侧是 `Rect.fromLTWH({left, …})`
  //（位置实参已由构建期按 dart:ui 构造签名映射成形参名）。
  export class Rect {
    constructor(props) {
      props = __positionalArgs(props, ['left', 'top', 'right', 'bottom']);
      this.left = props.left != null ? props.left : 0;
      this.top = props.top != null ? props.top : 0;
      this.right = props.right != null ? props.right : 0;
      this.bottom = props.bottom != null ? props.bottom : 0;
    }
    get width() { return this.right - this.left; }
    get height() { return this.bottom - this.top; }
    get center() { return new Offset({ dx: (this.left + this.right) / 2, dy: (this.top + this.bottom) / 2 }); }
    contains(offset) {
      return offset.dx >= this.left && offset.dx <= this.right &&
        offset.dy >= this.top && offset.dy <= this.bottom;
    }
    toJSON() { return [this.left, this.top, this.right, this.bottom]; }
    static fromLTWH(props) {
      props = __positionalArgs(props, ['left', 'top', 'width', 'height']);
      var l = props.left || 0, t = props.top || 0;
      var w = props.width || 0, h = props.height || 0;
      return new Rect({ left: l, top: t, right: l + w, bottom: t + h });
    }
    static fromLTRB(props) {
      props = __positionalArgs(props, ['left', 'top', 'right', 'bottom']);
      return new Rect(props);
    }
    static fromCircle(props) {
      props = __positionalArgs(props, ['center', 'radius']);
      var c = props.center, r = props.radius || 0;
      return new Rect({ left: c.dx - r, top: c.dy - r, right: c.dx + r, bottom: c.dy + r });
    }
    static fromCenter(props) {
      props = __positionalArgs(props, ['center', 'width', 'height']);
      var c = props.center, w = props.width || 0, h = props.height || 0;
      return new Rect({
        left: c.dx - w / 2, top: c.dy - h / 2,
        right: c.dx + w / 2, bottom: c.dy + h / 2
      });
    }
    static zero = new Rect({});
  }

  // ---------------------------------------------------------------------------
  // RRect：四角圆角半径按 Dart 的 Radius 值对象读取（Radius.circular 已有镜像）。
  export class RRect {
    constructor(props) {
      props = __positionalArgs(props, []);
      var rect = props.rect || new Rect({});
      this.left = rect.left != null ? rect.left : 0;
      this.top = rect.top != null ? rect.top : 0;
      this.right = rect.right != null ? rect.right : 0;
      this.bottom = rect.bottom != null ? rect.bottom : 0;
      this.tlX = props.topLeft ? (props.topLeft.x || 0) : 0;
      this.tlY = props.topLeft ? (props.topLeft.y || 0) : 0;
      this.trX = props.topRight ? (props.topRight.x || 0) : 0;
      this.trY = props.topRight ? (props.topRight.y || 0) : 0;
      this.brX = props.bottomRight ? (props.bottomRight.x || 0) : 0;
      this.brY = props.bottomRight ? (props.bottomRight.y || 0) : 0;
      this.blX = props.bottomLeft ? (props.bottomLeft.x || 0) : 0;
      this.blY = props.bottomLeft ? (props.bottomLeft.y || 0) : 0;
    }
    toJSON() {
      return [
        this.left, this.top, this.right, this.bottom,
        this.tlX, this.tlY, this.trX, this.trY,
        this.brX, this.brY, this.blX, this.blY
      ];
    }
    static fromRectAndRadius(props) {
      props = __positionalArgs(props, ['rect', 'radius']);
      var r = props.radius;
      return new RRect({
        rect: props.rect,
        topLeft: r, topRight: r, bottomRight: r, bottomLeft: r
      });
    }
    static fromLTRBR(props) {
      props = __positionalArgs(props, ['left', 'top', 'right', 'bottom', 'radius']);
      var r = props.radius;
      return new RRect({
        rect: new Rect({ left: props.left, top: props.top, right: props.right, bottom: props.bottom }),
        topLeft: r, topRight: r, bottomRight: r, bottomLeft: r
      });
    }
    static fromRectAndCorners(props) {
      props = __positionalArgs(props, ['rect']);
      return new RRect(props);
    }
  }

  // ---------------------------------------------------------------------------
  // Path：只记录构造指令，重放交给宿主 dart:ui 的 Path。
  export class Path {
    constructor(props) {
      __positionalArgs(props, []);
      this.ops = [];
    }
    moveTo(x, y) { this.ops.push(['moveTo', x, y]); }
    lineTo(x, y) { this.ops.push(['lineTo', x, y]); }
    quadraticBezierTo(x1, y1, x2, y2) { this.ops.push(['quadraticBezierTo', x1, y1, x2, y2]); }
    cubicTo(x1, y1, x2, y2, x3, y3) { this.ops.push(['cubicTo', x1, y1, x2, y2, x3, y3]); }
    relativeMoveTo(dx, dy) { this.ops.push(['relativeMoveTo', dx, dy]); }
    relativeLineTo(dx, dy) { this.ops.push(['relativeLineTo', dx, dy]); }
    arcTo(rect, startAngle, sweepAngle, forceMoveTo) {
      this.ops.push(['arcTo', rect, startAngle, sweepAngle, forceMoveTo]);
    }
    close() { this.ops.push(['close']); }
    addRect(rect, opts) {
      this.ops.push(['addRect', rect, (opts && opts.clockwise === false) ? false : true]);
    }
    addOval(rect, opts) {
      this.ops.push(['addOval', rect, (opts && opts.clockwise === false) ? false : true]);
    }
    addRRect(rrect, opts) {
      this.ops.push(['addRRect', rrect, (opts && opts.clockwise === false) ? false : true]);
    }
    addPolygon(points, close) {
      this.ops.push(['addPolygon', points, close === true]);
    }
    reset() { this.ops = []; }
    toJSON() { return { ops: this.ops }; }
  }

  // ---------------------------------------------------------------------------
  // Paint：Dart 的 setter 语义在这里被「赋值即可」——toJSON 把全部非空自有
  // 属性原样下发，宿主逐个还原（缺省 = Flutter 默认值）。
  export class Paint {
    constructor(props) {
      props = __positionalArgs(props, []);
      for (var k in props) {
        if (props[k] !== undefined) { this[k] = props[k]; }
      }
    }
    toJSON() {
      var out = {};
      for (var k in this) {
        if (this[k] !== undefined && this[k] !== null) { out[k] = this[k]; }
      }
      return out;
    }
  }

  // ---------------------------------------------------------------------------
  // Canvas：录制型。每个方法把「方法名 + 实参」压进 ops；实参里的值对象
  // （Rect / RRect / Path / Paint / Offset）由 JSON.stringify 递归调用各自 toJSON。
  export class Canvas {
    constructor() { this.ops = []; }
    save() { this.ops.push(['save']); }
    restore() { this.ops.push(['restore']); }
    saveLayer(bounds, paint) {
      this.ops.push(['saveLayer', bounds != null ? bounds : null, paint != null ? paint : null]);
    }
    translate(dx, dy) { this.ops.push(['translate', dx, dy]); }
    scale(sx, sy) { this.ops.push(['scale', sx, sy != null ? sy : sx]); }
    rotate(radians) { this.ops.push(['rotate', radians]); }
    clipRect(rect, opts) {
      opts = opts || {};
      this.ops.push([
        'clipRect', rect,
        opts.clipOp != null ? opts.clipOp : 'intersect',
        opts.doAntiAlias != null ? opts.doAntiAlias : true
      ]);
    }
    clipRRect(rrect, opts) {
      opts = opts || {};
      this.ops.push([
        'clipRRect', rrect,
        opts.clipOp != null ? opts.clipOp : 'intersect',
        opts.doAntiAlias != null ? opts.doAntiAlias : true
      ]);
    }
    clipPath(path, opts) {
      opts = opts || {};
      this.ops.push([
        'clipPath', path,
        opts.clipOp != null ? opts.clipOp : 'intersect',
        opts.doAntiAlias != null ? opts.doAntiAlias : true
      ]);
    }
    drawRect(rect, paint) { this.ops.push(['drawRect', rect, paint]); }
    drawRRect(rrect, paint) { this.ops.push(['drawRRect', rrect, paint]); }
    drawPath(path, paint) { this.ops.push(['drawPath', path, paint]); }
    drawLine(p1, p2, paint) { this.ops.push(['drawLine', p1, p2, paint]); }
    drawCircle(center, radius, paint) { this.ops.push(['drawCircle', center, radius, paint]); }
    drawOval(rect, paint) { this.ops.push(['drawOval', rect, paint]); }
    drawArc(rect, startAngle, sweepAngle, useCenter, paint) {
      this.ops.push(['drawArc', rect, startAngle, sweepAngle, useCenter, paint]);
    }
    drawPaint(paint) { this.ops.push(['drawPaint', paint]); }
    // image 是宿主返回值里的图片句柄（`{__handle, width, height}`），
    // JS 不持有像素；宿主重放时按 id 还原成真实 ui.Image。
    drawImage(image, offset, paint) {
      if (image == null) {
        throw new Error('CustomPaint: Canvas.drawImage 需要图片句柄（宿主 loadCanvasImage 的返回值），收到 null');
      }
      this.ops.push(['drawImage', image, offset, paint]);
    }
    drawImageRect(image, src, dst, paint) {
      if (image == null) {
        throw new Error('CustomPaint: Canvas.drawImageRect 需要图片句柄（宿主 loadCanvasImage 的返回值），收到 null');
      }
      this.ops.push(['drawImageRect', image, src, dst, paint]);
    }

    // 未支持：显式抛错（宿主 evaluate 会记 HotPatchLog.error，不静默）。
    drawImageNine() { throw new Error('CustomPaint: Canvas.drawImageNine 暂不支持'); }
    drawAtlas() { throw new Error('CustomPaint: Canvas.drawAtlas 暂不支持'); }
    drawVertices() { throw new Error('CustomPaint: Canvas.drawVertices 暂不支持'); }
    drawPoints() { throw new Error('CustomPaint: Canvas.drawPoints 暂不支持'); }
    drawParagraph() { throw new Error('CustomPaint: Canvas.drawParagraph 暂不支持'); }
    drawPicture() { throw new Error('CustomPaint: Canvas.drawPicture 暂不支持'); }
    drawShadow() { throw new Error('CustomPaint: Canvas.drawShadow 暂不支持'); }
    drawColor() { throw new Error('CustomPaint: Canvas.drawColor 暂不支持'); }
    toImage() { throw new Error('CustomPaint: Canvas.toImage 暂不支持'); }
    toImageSync() { throw new Error('CustomPaint: Canvas.toImageSync 暂不支持'); }
    getSaveCount() { throw new Error('CustomPaint: Canvas.getSaveCount 暂不支持'); }
    getTransform() { throw new Error('CustomPaint: Canvas.getTransform 暂不支持'); }
    getLocalClipBounds() { throw new Error('CustomPaint: Canvas.getLocalClipBounds 暂不支持'); }
    getDestinationClipBounds() { throw new Error('CustomPaint: Canvas.getDestinationClipBounds 暂不支持'); }

    toJSON() { return { v: 1, ops: this.ops }; }
  }

  // ---------------------------------------------------------------------------
  // TextPainter：只记录构造参数与 layout 约束，真正的排版/绘制由宿主完成。
  //
  // 构造实参按原名保存（`new TextPainter({text, textDirection, textAlign, …})`），
  // 交给宿主逐项还原：宿主只支持 text / textDirection / textAlign / maxLines /
  // ellipsis，其余键（textScaler / strutStyle / locale …）会在重放时报错，不静默。
  //
  // `layout(minWidth, maxWidth)` 的具名实参在 JS 侧是尾参对象
  // （`layout({maxWidth: 200})`），这里两种形态都接受；`Infinity` 序列化成 null，
  // 宿主按 Dart 默认值（minWidth 0 / maxWidth infinity）处理。
  //
  // `width` / `height` / `size` 需要同步测量，JS 侧无法做到——访问即抛错（
  // 显式失败优于返回一个假尺寸）；需要居中时请用布局已知的常量或自己算偏移。
  export class TextPainter {
    constructor(props) {
      this.__props = props || {};
      this.__layout = null;
    }
    layout(minWidth, maxWidth) {
      if (minWidth != null && typeof minWidth === 'object') {
        var o = minWidth;
        minWidth = o.minWidth;
        maxWidth = o.maxWidth;
      }
      this.__layout = {
        minWidth: (minWidth != null && minWidth !== Infinity) ? minWidth : null,
        maxWidth: (maxWidth != null && maxWidth !== Infinity) ? maxWidth : null
      };
    }
    paint(canvas, offset) {
      if (this.__layout == null) {
        throw new Error('Canvas 文字：TextPainter 需先 layout() 再 paint()');
      }
      // 构造实参里除 text（已单独作为 span 下发）外都作为排版选项；layout
      // 里为 null 的项表示「用 Dart 默认值」（minWidth 0 / maxWidth infinity）。
      var opts = {};
      for (var k in this.__props) {
        if (k !== 'text') { opts[k] = this.__props[k]; }
      }
      if (this.__layout.minWidth != null) { opts.minWidth = this.__layout.minWidth; }
      if (this.__layout.maxWidth != null) { opts.maxWidth = this.__layout.maxWidth; }
      canvas.ops.push(['drawText', this.__props.text, offset, opts]);
    }
    get width() {
      throw new Error('Canvas 文字：TextPainter.width 需要同步测量，暂不支持；请用已知常量计算偏移');
    }
    get height() {
      throw new Error('Canvas 文字：TextPainter.height 需要同步测量，暂不支持；请用已知常量计算偏移');
    }
    get size() {
      throw new Error('Canvas 文字：TextPainter.size 需要同步测量，暂不支持；请用已知常量计算偏移');
    }
  }

  // ---------------------------------------------------------------------------
  // CustomPainter：值类 + 句柄（`canvasPainter`）。
  //
  // **不同步宿主**（sync:false）：宿主不需要真实对象，只需要按 id 调 `__record`
  // 取回录制结果；句柄只用于「宿主 → JS 同步求值」的寻址。
  // 归属：在组件 build / 构造中创建 → instance scope，随组件卸载释放。
  export class CustomPainter {
    constructor(props) {
      props = __positionalArgs(props, []);
      if (props.repaint != null) {
        console.warn('CustomPainter.repaint 暂不支持（组件重建即重绘）');
      }
      this.__id = registerHandle(this, 'canvasPainter', {
        sync: false,
        meta: { type: (this.constructor && this.constructor.name) || 'CustomPainter' }
      });
    }
    paint(canvas, size) {}
    shouldRepaint(oldDelegate) { return true; }
    toJSON() { return { __handle: this.__id }; }
    // 宿主入口：以 size 录制一遍 paint，返回 `{v:1, ops:[...]}`。
    __record(sizeJson) {
      var canvas = new Canvas();
      var size = new Size(sizeJson);
      this.paint(canvas, size);
      return canvas;
    }
  }
''';
