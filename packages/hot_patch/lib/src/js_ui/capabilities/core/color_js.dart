// ===== 基础能力：Color 类族（JS 侧片段）=====
//
// 翻译层把颜色完全当普通表达式处理：
//   `Color(0xFF112233)`      → `new Color({ value: ... })`
//   `Color.fromARGB(a,r,g,b)` → `Color.fromARGB({ a, r, g, b })`
//   `Colors.red` / `.shade300` / `[400]` → 原样字段/下标访问
//
// 跨桥序列化只有一条约定：任何 Color 实例 `toJSON()` 输出 `'#AARRGGBB'`，
// 宿主 `colorFromJson` 按 6/8 位 hex 还原。`Colors` 常量本身由构建期从
// Flutter SDK `colors.dart` 自动生成（见 generator 的 color_constants.dart），
// 这里只提供类，不含任何色值表。
const String colorJsSource = r'''
  // ===== 【0.3】Color / MaterialColor / ColorSwatch =====
  function __toHex(v) {
    var n = (v >>> 0).toString(16).toUpperCase();
    while (n.length < 8) { n = '0' + n; }
    return '#' + n;
  }

  function Color(props) {
    props = __posArgs(props, ['value']);
    this.value = props.value != null ? (props.value >>> 0) : 0;
  }
  // 序列化：宿主 colorFromJson 只认 '#RRGGBB' / '#AARRGGBB'。
  Color.prototype.toJSON = function () { return __toHex(this.value); };
  Color.prototype.toString = function () { return __toHex(this.value); };
  Color.prototype.withAlpha = function (a) {
    return new Color({ value: ((a & 0xFF) << 24) | (this.value & 0x00FFFFFF) });
  };
  Color.prototype.withOpacity = function (o) {
    var a = Math.round(Math.max(0, Math.min(1, o)) * 255);
    return this.withAlpha(a);
  };
  Color.prototype.withValues = function (opts) {
    opts = __posArgs(opts, []);
    var a = opts.alpha != null ? Math.round(opts.alpha * 255) : this.alpha;
    var r = opts.red != null ? opts.red : this.red;
    var g = opts.green != null ? opts.green : this.green;
    var b = opts.blue != null ? opts.blue : this.blue;
    return Color.fromARGB({ a: a, r: r, g: g, b: b });
  };
  Object.defineProperty(Color.prototype, 'alpha', {
    get: function () { return (this.value >> 24) & 0xFF; }
  });
  Object.defineProperty(Color.prototype, 'red', {
    get: function () { return (this.value >> 16) & 0xFF; }
  });
  Object.defineProperty(Color.prototype, 'green', {
    get: function () { return (this.value >> 8) & 0xFF; }
  });
  Object.defineProperty(Color.prototype, 'blue', {
    get: function () { return this.value & 0xFF; }
  });
  Color.fromARGB = function (props) {
    props = __posArgs(props, ['a', 'r', 'g', 'b']);
    return new Color({ value: ((props.a & 0xFF) << 24) | ((props.r & 0xFF) << 16) |
      ((props.g & 0xFF) << 8) | (props.b & 0xFF) });
  };
  Color.fromRGBO = function (props) {
    props = __posArgs(props, ['r', 'g', 'b', 'opacity']);
    var o = props.opacity != null ? props.opacity : 1;
    return Color.fromARGB({ a: Math.round(o * 255), r: props.r, g: props.g, b: props.b });
  };
  Color.lerp = function (props) {
    props = __posArgs(props, ['a', 'b', 't']);
    var a = props.a || new Color({ value: 0 });
    var b = props.b || new Color({ value: 0 });
    var t = props.t == null ? 0.5 : props.t;
    function mix(x, y) { return Math.round(x + (y - x) * t); }
    return Color.fromARGB({
      a: mix(a.alpha, b.alpha), r: mix(a.red, b.red),
      g: mix(a.green, b.green), b: mix(a.blue, b.blue)
    });
  };
  G.Color = Color;

  // MaterialColor / MaterialAccentColor / ColorSwatch：值仍是 Color（主色），
  // 额外持各档位。档位同时挂在 `shadeNN` 与数字下标上，故 Dart 的
  // `Colors.red[400]` / `Colors.red.shade400` 在 JS 里都能原样求值。
  function __swatch(base, shades) {
    base.__shades = shades || {};
    return base;
  }
  function __swatchBase(props) {
    props = __posArgs(props, ['primary', 'swatch']);
    var v = props.value != null ? props.value : props.primary;
    return { value: v, swatch: props.swatch };
  }
  function MaterialColor(props) {
    var p = __swatchBase(props);
    Color.call(this, { value: p.value });
    __swatch(this, p.swatch);
  }
  MaterialColor.prototype = Object.create(Color.prototype);
  MaterialColor.prototype.constructor = MaterialColor;
  G.MaterialColor = MaterialColor;

  function MaterialAccentColor(props) {
    var p = __swatchBase(props);
    Color.call(this, { value: p.value });
    __swatch(this, p.swatch);
  }
  MaterialAccentColor.prototype = Object.create(Color.prototype);
  MaterialAccentColor.prototype.constructor = MaterialAccentColor;
  G.MaterialAccentColor = MaterialAccentColor;

  function ColorSwatch(props) {
    var p = __swatchBase(props);
    Color.call(this, { value: p.value });
    __swatch(this, p.swatch);
  }
  ColorSwatch.prototype = Object.create(Color.prototype);
  ColorSwatch.prototype.constructor = ColorSwatch;
  G.ColorSwatch = ColorSwatch;
''';
