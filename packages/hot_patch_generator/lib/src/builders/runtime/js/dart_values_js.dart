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
  export class Duration {
    constructor(opts) {
      opts = __posArgs(opts, ['microseconds', 'milliseconds', 'seconds',
        'minutes', 'hours', 'days']);
      var ms = (opts.milliseconds || 0) + (opts.seconds || 0) * 1000 +
        (opts.minutes || 0) * 60000 + (opts.hours || 0) * 3600000 +
        (opts.days || 0) * 86400000;
      ms += (opts.microseconds || 0) / 1000;
      this.inMilliseconds = Math.round(ms);
      this.inMicroseconds = Math.round(ms * 1000);
    }
  }
  Duration.prototype.toJSON = function () {
    return { __duration: this.inMilliseconds };
  };
  G.Duration = Duration;

  export class Size {
    constructor(props) {
      props = __posArgs(props, ['width', 'height']);
      this.width = props.width;
      this.height = props.height;
    }
  }
  Size.prototype.toJSON = function () {
    return { width: this.width, height: this.height };
  };
  // Dart `Size` 的命名构造 / 静态常量（产物按统一规则发射 `Size.fromHeight({…})`）。
  // **无界维度是 +∞**：跨桥时 `JSON.stringify(Infinity)` 得到 null，宿主侧按 ∞
  // 还原（见 js_widget_registry 的 PreferredSize / layout 约束的 null 约定）。
  Size.fromHeight = function (props) {
    props = __posArgs(props, ['height']);
    return new Size({ width: Infinity, height: props.height });
  };
  Size.fromWidth = function (props) {
    props = __posArgs(props, ['width']);
    return new Size({ width: props.width, height: Infinity });
  };
  Size.square = function (props) {
    props = __posArgs(props, ['dimension']);
    return new Size({ width: props.dimension, height: props.dimension });
  };
  Size.copy = function (props) {
    props = __posArgs(props, ['source']);
    return new Size({ width: props.source.width, height: props.source.height });
  };
  Size.zero = { width: 0, height: 0 };
  Size.infinite = { width: Infinity, height: Infinity };
  G.Size = Size;

  export class Offset {
    constructor(props) {
      props = __posArgs(props, ['dx', 'dy']);
      this.dx = props.dx != null ? props.dx : 0;
      this.dy = props.dy != null ? props.dy : 0;
    }
  }
  Offset.prototype.toJSON = function () {
    return { dx: this.dx, dy: this.dy };
  };
  G.Offset = Offset;

  // Alignment：产物在**值位置**（LinearGradient 的 begin/end、Container 的
  // alignment 等）可能直接引用 `Alignment.topLeft`（不是所有位置都会经过
  // 构建期的枚举转换器，如静态字段初值就是通用表达式翻译）。Dart 侧它是
  // 常量对象，但跨桥协议是**成员名**（宿主 alignmentFromJson 只认字符串），
  // 因此静态常量直接就是该字符串——与 Dart 里「同一常量是同一值」的语义一致
  //（比较、传参、判等全部成立）。
  export class Alignment {
    constructor(props) {
      props = __posArgs(props, ['x', 'y']);
      this.x = props.x != null ? props.x : 0;
      this.y = props.y != null ? props.y : 0;
    }
  }
  Alignment.prototype.toJSON = function () { return { x: this.x, y: this.y }; };
  ['topLeft', 'topCenter', 'topRight', 'centerLeft', 'center',
    'centerRight', 'bottomLeft', 'bottomCenter', 'bottomRight'
  ].forEach(function (n) { Alignment[n] = n; });
  G.Alignment = Alignment;

  export class Radius {
    constructor(props) {
      props = __posArgs(props, ['radius']);
      var r = props.radius != null ? props.radius : (props.x != null ? props.x : 0);
      this.x = r;
      this.y = r;
    }
  }
  Radius.circular = function (props) { return new Radius(props); };
  Radius.prototype.toJSON = function () { return { radius: this.x }; };
  G.Radius = Radius;

  // BoxConstraints：布局约束值对象（LayoutBuilder 的 builder 第二参）。宿主按
  // {minWidth, maxWidth, minHeight, maxHeight} 下发，无界维度发 null（JSON 不能
  // 表达 Infinity），这里还原成 +∞（见【18.8】）。
  export class BoxConstraints {
    constructor(props) {
      props = __posArgs(props, ['minWidth', 'maxWidth', 'minHeight', 'maxHeight']);
      this.minWidth = props.minWidth != null ? props.minWidth : 0;
      this.maxWidth = props.maxWidth != null ? props.maxWidth : Infinity;
      this.minHeight = props.minHeight != null ? props.minHeight : 0;
      this.maxHeight = props.maxHeight != null ? props.maxHeight : Infinity;
    }
  }
  __defineProtoGetter(BoxConstraints.prototype, 'biggest', function () {
    return new Size({ width: this.maxWidth, height: this.maxHeight });
  });
  __defineProtoGetter(BoxConstraints.prototype, 'smallest', function () {
    return new Size({ width: this.minWidth, height: this.minHeight });
  });
  __defineProtoGetter(BoxConstraints.prototype, 'isTight', function () {
    return this.minWidth >= this.maxWidth && this.minHeight >= this.maxHeight;
  });
  __defineProtoGetter(BoxConstraints.prototype, 'hasBoundedWidth', function () {
    return this.maxWidth < Infinity;
  });
  __defineProtoGetter(BoxConstraints.prototype, 'hasBoundedHeight', function () {
    return this.maxHeight < Infinity;
  });
  // 无界维度回 null：与宿主下发协议同形，保证跨语言往返一致。
  BoxConstraints.prototype.toJSON = function () {
    return {
      minWidth: this.minWidth,
      maxWidth: this.maxWidth === Infinity ? null : this.maxWidth,
      minHeight: this.minHeight,
      maxHeight: this.maxHeight === Infinity ? null : this.maxHeight,
    };
  };
  G.BoxConstraints = BoxConstraints;

  // TextSpan：Dart 富文本子树的值对象（RichText 的 `text`）。产物按统一规则
  // 发射 `new TextSpan({text, style, children, semanticsLabel})`；这里镜像字段，
  // 跨桥时由 JSON.stringify 递归序列化成普通对象，宿主 textSpanFromJson 再
  // 还原成真正的 TextSpan 树。
  export class TextSpan {
    constructor(props) {
      props = __posArgs(props, ['text']);
      this.text = props.text;
      if (props.style != null) { this.style = props.style; }
      if (props.children != null) { this.children = props.children; }
      if (props.semanticsLabel != null) { this.semanticsLabel = props.semanticsLabel; }
    }
  }
  G.TextSpan = TextSpan;

  // ---------------------------------------------------------------------------
  // 渐变与装饰：绘制层值对象（`LinearGradient` / `RadialGradient` /
  // `SweepGradient` / `BoxDecoration`）。
  //
  // 来历与 Duration / Size 完全相同：Dart 里它们是普通的 const 构造，翻译层
  // 按统一规则原样发射 `new LinearGradient({begin, end, colors})`，因此运行时
  // **必须**有同名类——缺一个就是模块求值期的 `Can't find variable`，整页挂载
  // 失败（静态字段初值在类定义时就执行，比任何方法体都早）。
  //
  // 跨桥协议见宿主 painting_from_json：
  //   gradient → {kind:'linear'|'radial'|'sweep', colors, begin/end/center, radius, stops}
  //   decoration → {color, border, borderRadius, boxShadow, gradient, image, shape}
  // colors 里是 Color 实例：JSON.stringify 会递归调用其 toJSON 得到 '#AARRGGBB'，
  // 宿主 colorFromJson 据此还原，无需在这里逐个转换。
  // names[0] 恒为 colors（构造首位置实参，单独兜底成数组），其余从 1 开始。
  function __gradientProps(props, names) {
    props = __posArgs(props, names);
    var out = { colors: props.colors != null ? props.colors : [] };
    for (var i = 1; i < names.length; i++) {
      if (props[names[i]] != null) { out[names[i]] = props[names[i]]; }
    }
    return out;
  }
  function __gradientJson(kind, self) {
    var json = { kind: kind, colors: self.colors };
    if (self.begin != null) { json.begin = self.begin; }
    if (self.end != null) { json.end = self.end; }
    if (self.center != null) { json.center = self.center; }
    if (self.radius != null) { json.radius = self.radius; }
    if (self.stops != null) { json.stops = self.stops; }
    return json;
  }

  export class LinearGradient {
    constructor(props) {
      var p = __gradientProps(props, ['colors', 'begin', 'end', 'stops', 'tileMode']);
      for (var k in p) { this[k] = p[k]; }
    }
  }
  LinearGradient.prototype.toJSON = function () { return __gradientJson('linear', this); };
  G.LinearGradient = LinearGradient;

  export class RadialGradient {
    constructor(props) {
      var p = __gradientProps(props,
        ['colors', 'center', 'radius', 'stops', 'focal', 'focalRadius', 'tileMode']);
      for (var k in p) { this[k] = p[k]; }
    }
  }
  RadialGradient.prototype.toJSON = function () { return __gradientJson('radial', this); };
  G.RadialGradient = RadialGradient;

  export class SweepGradient {
    constructor(props) {
      var p = __gradientProps(props,
        ['colors', 'center', 'startAngle', 'endAngle', 'stops', 'tileMode']);
      for (var k in p) { this[k] = p[k]; }
    }
  }
  SweepGradient.prototype.toJSON = function () { return __gradientJson('sweep', this); };
  G.SweepGradient = SweepGradient;

  // BoxDecoration：字段名与 Dart 构造具名实参一致，toJSON 直出宿主协议
  //（值为 null 的键不下发——宿主对 null 与缺省同义，少发更干净）。
  export class BoxDecoration {
    constructor(props) {
      props = __posArgs(props, ['color', 'image', 'border', 'borderRadius',
        'boxShadow', 'gradient', 'backgroundBlendMode', 'shape']);
      for (var k in props) {
        if (props[k] != null) { this[k] = props[k]; }
      }
    }
  }
  BoxDecoration.prototype.toJSON = function () {
    var json = {};
    for (var k in this) {
      if (this[k] != null) { json[k] = this[k]; }
    }
    return json;
  };
  G.BoxDecoration = BoxDecoration;

  // ----- 枚举镜像 ---------------------------------------------------------
  // Dart 枚举 → JS class + static 字段，值 = 成员名字符串：跨语言只有 name 能
  // 表达（宿主也按 name 下发/回传），这样源码级比较
  // `direction == DismissDirection.endToStart` 在 JS 侧语义不变。
  // 需要运行时存在「枚举类」的枚举在此登记（只做字符串转换的仍由翻译层下发名字）。
  export class DismissDirection {
    static horizontal = "horizontal";
    static vertical = "vertical";
    static startToEnd = "startToEnd";
    static endToStart = "endToStart";
    static up = "up";
    static down = "down";
  }
  G.DismissDirection = DismissDirection;
''';
