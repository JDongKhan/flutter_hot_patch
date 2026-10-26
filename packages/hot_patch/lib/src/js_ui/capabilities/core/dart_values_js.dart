// ===== 基础能力：Dart 值类镜像（JS 侧片段）=====
//
// 生成器把 Dart 的值对象按「统一翻译」原样发射为构造调用：
//   `Duration(milliseconds: 300)` → `new Duration({milliseconds: 300})`
//   `Size(10, 20)`                → `new Size(10, 20)`
//   `Offset(0, 1)`                → `new Offset(0, 1)`
//   `Radius.circular(8)`          → `new Radius(8)`
//
// 运行时因此必须补上这些**值类**，否则产物一执行就是 ReferenceError，整页
// 挂载失败。值类只做两件事：镜像 Dart 字段 + `toJSON` 成宿主 `fromJson` 认得
// 的 JSON 形态（duration → `{__duration: ms}`，size/offset/radius → 字面字段）。
//
// 放在 core（而非某个能力目录）的原因：它们是**跨能力的公共值对象**——动画、
// 布局、手势等模块都可能下发/读取，任何能力都不应独占。
const String dartValuesJsSource = r'''
  // ===== 【0.1】Dart 值类（Duration / Size / Offset / Radius）=====
  // Duration 产物键是 Dart 的命名实参（milliseconds / seconds / …），换算成
  // 毫秒后经 toJSON 下发；宿主 durationFromJson 只认 `{__duration: ms}` 与裸数字。
  function __durationMs(d) {
    if (d == null) { return null; }
    if (typeof d === 'number') { return d; }
    if (typeof d === 'object') {
      if (typeof d.__duration === 'number') { return d.__duration; }
      if (typeof d.inMilliseconds === 'number') { return d.inMilliseconds; }
    }
    return null;
  }
  function Duration(opts) {
    opts = opts || {};
    var ms = (opts.milliseconds || 0) + (opts.seconds || 0) * 1000 +
      (opts.minutes || 0) * 60000 + (opts.hours || 0) * 3600000 +
      (opts.days || 0) * 86400000;
    ms += (opts.microseconds || 0) / 1000;
    this.inMilliseconds = Math.round(ms);
    this.inMicroseconds = Math.round(ms * 1000);
  }
  Duration.prototype.toJSON = function () {
    return { __duration: this.inMilliseconds };
  };
  G.Duration = Duration;

  function Size(width, height) {
    this.width = width;
    this.height = height;
  }
  Size.prototype.toJSON = function () {
    return { width: this.width, height: this.height };
  };
  G.Size = Size;

  function Offset(dx, dy) {
    this.dx = dx;
    this.dy = dy;
  }
  Offset.prototype.toJSON = function () {
    return { dx: this.dx, dy: this.dy };
  };
  G.Offset = Offset;

  function Radius(circular) {
    this.x = circular;
    this.y = circular;
  }
  Radius.circular = function (r) { return new Radius(r); };
  Radius.prototype.toJSON = function () { return { radius: this.x }; };
  G.Radius = Radius;
''';
