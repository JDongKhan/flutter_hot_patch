// ===== 基础能力：Dart 值类镜像（JS 侧片段）=====
//
// 生成器把 Dart 的值对象按「统一翻译」原样发射为构造调用：
//   `Duration(milliseconds: 300)` → `new Duration({milliseconds: 300})`
//   `Size(10, 20)`                → `new Size({width: 10, height: 20})`
//   `Offset(0, 1)`                → `new Offset({dx: 0, dy: 1})`
//   `Radius.circular(8)`          → `Radius.circular({radius: 8})`
//
// 位置实参在构建期按源码构造签名映射成形参名；签名缺失时落 `__pos` 下标数组，
// 这里统一按 [__posArgs] 展开，运行时不需要知道任何类名。
//
// 运行时因此必须补上这些**值类**，否则产物一执行就是 ReferenceError，整页
// 挂载失败。值类只做两件事：镜像 Dart 字段 + `toJSON` 成宿主 `fromJson` 认得
// 的 JSON 形态（duration → `{__duration: ms}`，size/offset/radius → 字面字段）。
//
// 放在 core（而非某个能力目录）的原因：它们是**跨能力的公共值对象**——动画、
// 布局、手势等模块都可能下发/读取，任何能力都不应独占。
const String dartValuesJsSource = r'''
  // ===== 【0.0】位置实参兜底 =====
  // 构建期查不到构造签名时，位置实参以 `__pos: [...]` 下发；这里按形参名顺序
  // 展开。任何类都可复用，不含类名判断。
  function __posArgs(props, names) {
    if (!props || !props.__pos) { return props || {}; }
    var out = {};
    for (var k in props) {
      if (k !== '__pos') { out[k] = props[k]; }
    }
    for (var i = 0; i < names.length && i < props.__pos.length; i++) {
      out[names[i]] = props.__pos[i];
    }
    return out;
  }
  G.__posArgs = __posArgs;

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
    opts = __posArgs(opts, ['microseconds', 'milliseconds', 'seconds',
      'minutes', 'hours', 'days']);
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

  function Size(props) {
    props = __posArgs(props, ['width', 'height']);
    this.width = props.width;
    this.height = props.height;
  }
  Size.prototype.toJSON = function () {
    return { width: this.width, height: this.height };
  };
  G.Size = Size;

  function Offset(props) {
    props = __posArgs(props, ['dx', 'dy']);
    this.dx = props.dx != null ? props.dx : 0;
    this.dy = props.dy != null ? props.dy : 0;
  }
  Offset.prototype.toJSON = function () {
    return { dx: this.dx, dy: this.dy };
  };
  G.Offset = Offset;

  function Radius(props) {
    props = __posArgs(props, ['radius']);
    var r = props.radius != null ? props.radius : (props.x != null ? props.x : 0);
    this.x = r;
    this.y = r;
  }
  Radius.circular = function (props) { return new Radius(props); };
  Radius.prototype.toJSON = function () { return { radius: this.x }; };
  G.Radius = Radius;
''';
