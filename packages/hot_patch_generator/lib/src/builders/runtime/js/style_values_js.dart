// ===== 样式 / 布局 / 文字 / 形状值类镜像（JS 侧片段，flutter.js 值类区）=====
//
// 与 dart_values_js 同一条规则：Dart 构造**一比一**发射，运行时必须有同名类。
// 产物形态：
//   `EdgeInsets.all(12)`                 → `EdgeInsets.all({value: 12})`
//   `EdgeInsets.symmetric(vertical: 4)`  → `EdgeInsets.symmetric({vertical: 4})`
//   `BorderRadius.circular(8)`           → `BorderRadius.circular({radius: 8})`
//   `TextStyle(fontSize: 16)`            → `new TextStyle({fontSize: 16})`
//
// 每个类只做两件事：镜像 Dart 字段 + `toJSON` 直出宿主 `from_json` 已认的协议
// （值是类实例时由 JSON.stringify 递归调用各自的 toJSON）。
//
// 具名构造 / 静态工厂由类上的同名 `static` 承接——翻译层不认类名、不认构造名，
// 只是把 `A.b(...)` 原样发成 `A.b({...})`。
const String styleValuesJsSource = r'''
  // 单值构造的取值：位置实参的形参名因类而异（`value` / `radius` / `index` /
  // `textScaleFactor` …），值都是「唯一那个数」；裸数字也接受。
  function __one(props) {
    if (props == null) { return 0; }
    if (typeof props === 'number' || typeof props === 'string') { return props; }
    for (var k in props) {
      if (k !== '__pos' && props[k] != null) { return props[k]; }
    }
    return 0;
  }

  // ----- 边距 ---------------------------------------------------------------
  // 宿主协议：{left, top, right, bottom}（layout_from_json.edgeInsetsFromJson）。
  export class EdgeInsets {
    constructor(props) {
      props = __posArgs(props, ['left', 'top', 'right', 'bottom']);
      this.left = props.left != null ? props.left : 0;
      this.top = props.top != null ? props.top : 0;
      this.right = props.right != null ? props.right : 0;
      this.bottom = props.bottom != null ? props.bottom : 0;
    }
    get horizontal() { return this.left + this.right; }
    get vertical() { return this.top + this.bottom; }
    get isEmpty() {
      return this.left === 0 && this.top === 0 && this.right === 0 && this.bottom === 0;
    }
    toJSON() {
      return { left: this.left, top: this.top, right: this.right, bottom: this.bottom };
    }
    static zero = new EdgeInsets({});
    static all(props) {
      var v = __one(props);
      return new EdgeInsets({ left: v, top: v, right: v, bottom: v });
    }
    static only(props) { return new EdgeInsets(props); }
    static symmetric(props) {
      var h = props.horizontal != null ? props.horizontal : 0;
      var v = props.vertical != null ? props.vertical : 0;
      return new EdgeInsets({ left: h, top: v, right: h, bottom: v });
    }
    static fromLTRB(props) {
      props = __posArgs(props, ['left', 'top', 'right', 'bottom']);
      return new EdgeInsets(props);
    }
    static fromSTEB(props) {
      props = __posArgs(props, ['start', 'top', 'end', 'bottom']);
      return new EdgeInsets({
        left: props.start != null ? props.start : 0,
        top: props.top != null ? props.top : 0,
        right: props.end != null ? props.end : 0,
        bottom: props.bottom != null ? props.bottom : 0,
      });
    }
  }

  // ----- 圆角 / 边框 -----------------------------------------------------------
  // 宿主协议：BorderRadius → {radius} 或四角数字；Border → {all} 或四边 side。
  function __radiusOf(v) {
    if (v instanceof Radius) { return v; }
    return new Radius({ radius: typeof v === 'number' ? v : __one(v) });
  }

  export class BorderRadius {
    constructor(props) {
      props = __posArgs(props, ['topLeft', 'topRight', 'bottomLeft', 'bottomRight']);
      this.topLeft = __radiusOf(props.topLeft);
      this.topRight = __radiusOf(props.topRight);
      this.bottomLeft = __radiusOf(props.bottomLeft);
      this.bottomRight = __radiusOf(props.bottomRight);
    }
    toJSON() {
      var tl = this.topLeft.x, tr = this.topRight.x;
      var bl = this.bottomLeft.x, br = this.bottomRight.x;
      if (tl === tr && tr === bl && bl === br) { return { radius: tl }; }
      return { topLeft: tl, topRight: tr, bottomLeft: bl, bottomRight: br };
    }
    get horizontal() { return this.topLeft.x + this.bottomLeft.x; }
    get vertical() { return this.topLeft.x + this.bottomLeft.x; }
    static zero = new BorderRadius({});
    static all(props) {
      var r = __radiusOf(props.radius);
      return new BorderRadius({ topLeft: r, topRight: r, bottomLeft: r, bottomRight: r });
    }
    static circular(props) { return BorderRadius.all({ radius: __one(props) }); }
    static only(props) { return new BorderRadius(props); }
    static vertical(props) {
      var r = __radiusOf(__one(props));
      return new BorderRadius({ topLeft: r, topRight: r });
    }
    static horizontal(props) {
      var r = __radiusOf(__one(props));
      return new BorderRadius({ topLeft: r, bottomLeft: r });
    }
  }

  export class BorderSide {
    constructor(props) {
      props = __posArgs(props, ['color', 'width', 'style', 'strokeAlign']);
      this.color = props.color != null ? props.color : null;
      this.width = props.width != null ? props.width : 1;
      this.style = props.style != null ? props.style : 'solid';
      if (props.strokeAlign != null) { this.strokeAlign = props.strokeAlign; }
    }
    toJSON() {
      return { color: this.color, width: this.width, style: this.style };
    }
    static none = new BorderSide({ width: 0, style: 'none' });
  }

  export class Border {
    constructor(props) {
      props = __posArgs(props, ['top', 'right', 'bottom', 'left']);
      if (props.all != null) { this.all = props.all; }
      if (props.top != null) { this.top = props.top; }
      if (props.right != null) { this.right = props.right; }
      if (props.bottom != null) { this.bottom = props.bottom; }
      if (props.left != null) { this.left = props.left; }
    }
    // `Border.all(color:.., width:..)` 的实参与 BorderSide 同形。
    static all(props) { return new Border({ all: new BorderSide(props) }); }
    static fromBorderSide(props) {
      props = __posArgs(props, ['side']);
      return new Border({ all: props.side });
    }
    toJSON() {
      if (this.all != null) { return { all: this.all }; }
      return { top: this.top, right: this.right, bottom: this.bottom, left: this.left };
    }
  }

  export class BoxShadow {
    constructor(props) {
      props = __posArgs(props, ['color', 'offset', 'blurRadius', 'spreadRadius', 'blurStyle']);
      this.color = props.color != null ? props.color : null;
      this.offset = props.offset != null ? props.offset : new Offset({ dx: 0, dy: 0 });
      this.blurRadius = props.blurRadius != null ? props.blurRadius : 0;
      this.spreadRadius = props.spreadRadius != null ? props.spreadRadius : 0;
      this.blurStyle = props.blurStyle != null ? props.blurStyle : 'normal';
    }
    toJSON() {
      return {
        color: this.color,
        dx: this.offset.dx,
        dy: this.offset.dy,
        blur: this.blurRadius,
        spread: this.spreadRadius,
        blurStyle: this.blurStyle,
      };
    }
  }

  // ----- 文字 ---------------------------------------------------------------
  // 宿主协议：TextStyle 直取同名字段；FontWeight → 'bold'/'w600'；
  // TextDecoration → 成员名；TextScaler → {linear} / 'noScaling'。
  export class TextDecoration {
    constructor(props) { this.name = __one(props); }
    toJSON() { return this.name; }
    static none = new TextDecoration('none');
    static underline = new TextDecoration('underline');
    static overline = new TextDecoration('overline');
    static lineThrough = new TextDecoration('lineThrough');
  }

  export class FontWeight {
    constructor(props) { this.value = __one(__posArgs(props, ['index'])); }
    toJSON() {
      if (this.value === 400) { return 'normal'; }
      if (this.value === 700) { return 'bold'; }
      return 'w' + this.value;
    }
    static w100 = new FontWeight(100);
    static w200 = new FontWeight(200);
    static w300 = new FontWeight(300);
    static w400 = new FontWeight(400);
    static w500 = new FontWeight(500);
    static w600 = new FontWeight(600);
    static w700 = new FontWeight(700);
    static w800 = new FontWeight(800);
    static w900 = new FontWeight(900);
    static normal = FontWeight.w400;
    static bold = FontWeight.w700;
  }

  export class TextScaler {
    constructor(props) {
      this.__none = props === null;
      if (!this.__none) { this.factor = __one(props); }
    }
    toJSON() { return this.__none ? 'noScaling' : { linear: this.factor }; }
    static noScaling = new TextScaler(null);
    static linear(props) {
      props = __posArgs(props, ['textScaleFactor']);
      return new TextScaler(
        props.textScaleFactor != null ? props.textScaleFactor : __one(props));
    }
  }

  export class TextStyle {
    constructor(props) {
      props = props || {};
      // TextStyle 的构造参数全是具名参（源码里没有位置参、也没有命名构造），
      // 产物只可能下发 Dart 实参本身，不存在 `__pos` / `factory` 这类协议键，
      // 因此按原名直接拷贝，不做协议键过滤。
      for (var k in props) {
        if (props[k] != null) { this[k] = props[k]; }
      }
    }
    toJSON() {
      var j = {};
      for (var k in this) {
        if (this[k] != null) { j[k] = this[k]; }
      }
      return j;
    }
  }

  // ----- 形状 ---------------------------------------------------------------
  // 宿主协议：shapeFromJson → {kind:'rounded'|'stadium'|'circle'|'beveled'|
  // 'continuous', borderRadius, side}。
  class __OutlinedBorder {
    constructor(kind, props) {
      props = __posArgs(props, ['borderRadius', 'side']);
      this.__kind = kind;
      if (props.borderRadius != null) { this.borderRadius = props.borderRadius; }
      if (props.side != null) { this.side = props.side; }
    }
    toJSON() {
      var j = { kind: this.__kind };
      if (this.borderRadius != null) { j.borderRadius = this.borderRadius; }
      if (this.side != null) { j.side = this.side; }
      return j;
    }
  }
  export class RoundedRectangleBorder extends __OutlinedBorder {
    constructor(props) { super('rounded', props); }
  }
  export class CircleBorder extends __OutlinedBorder {
    constructor(props) { super('circle', props); }
  }
  export class StadiumBorder extends __OutlinedBorder {
    constructor(props) { super('stadium', props); }
  }
  export class BeveledRectangleBorder extends __OutlinedBorder {
    constructor(props) { super('beveled', props); }
  }
  export class ContinuousRectangleBorder extends __OutlinedBorder {
    constructor(props) { super('continuous', props); }
  }

  // ----- 图片 ---------------------------------------------------------------
  // AssetImage / NetworkImage 的跨桥形态就是**源字符串**（构造名由静态方法写进
  // `props.factory` 只在元素层起作用，值对象本身不带 factory）；宿主
  // `_imageProvider` 按 'http' 前缀区分网络图与资源图。DecorationImage →
  // {source, fit}。
  export class AssetImage {
    constructor(props) {
      props = __posArgs(props, ['assetName']);
      this.assetName = props.assetName != null ? props.assetName : __one(props);
    }
    toJSON() { return this.assetName; }
  }

  export class NetworkImage {
    constructor(props) {
      props = __posArgs(props, ['url', 'scale', 'headers']);
      this.url = props.url != null ? props.url : __one(props);
      if (props.scale != null) { this.scale = props.scale; }
      if (props.headers != null) { this.headers = props.headers; }
    }
    toJSON() { return this.url; }
  }

  export class DecorationImage {
    constructor(props) {
      props = props || {};
      for (var k in props) {
        if (k !== '__pos' && props[k] != null) { this[k] = props[k]; }
      }
    }
    toJSON() {
      var j = { source: this.image };
      if (this.fit != null) { j.fit = this.fit; }
      return j;
    }
  }

  // ----- 滤镜 ---------------------------------------------------------------
  // 宿主协议：ImageFilter → {kind:'blur'|'dilate'|'erode'|'matrix'|'compose',…}；
  // ColorFilter → {kind:'mode'|'matrix'|'linearToSrgbGamma'|'srgbToLinearGamma',…}。
  class __KindValue {
    constructor(kind, props) {
      this.__kind = kind;
      props = props || {};
      for (var k in props) {
        if (k !== '__pos' && props[k] != null) { this[k] = props[k]; }
      }
    }
    toJSON() {
      var j = { kind: this.__kind };
      for (var k in this) {
        if (k !== '__kind' && this[k] != null) { j[k] = this[k]; }
      }
      return j;
    }
  }

  export class ImageFilter extends __KindValue {
    constructor(props) { super('blur', props); }
    static blur(props) {
      props = __posArgs(props, ['sigmaX', 'sigmaY', 'tileMode']);
      return new __KindValue('blur', props);
    }
    static dilate(props) {
      props = __posArgs(props, ['radiusX', 'radiusY']);
      return new __KindValue('dilate', props);
    }
    static erode(props) {
      props = __posArgs(props, ['radiusX', 'radiusY']);
      return new __KindValue('erode', props);
    }
    static matrix(props) {
      props = __posArgs(props, ['matrix']);
      return new __KindValue('matrix', props);
    }
    static compose(props) {
      props = __posArgs(props, ['outer', 'inner']);
      return new __KindValue('compose', props);
    }
  }

  export class ColorFilter extends __KindValue {
    constructor(props) { super('mode', props); }
    static mode(props) {
      props = __posArgs(props, ['color', 'blendMode']);
      return new __KindValue('mode', props);
    }
    static matrix(props) {
      props = __posArgs(props, ['matrix']);
      return new __KindValue('matrix', props);
    }
    static linearToSrgbGamma = new __KindValue('linearToSrgbGamma', {});
    static srgbToLinearGamma = new __KindValue('srgbToLinearGamma', {});
  }

  // ----- 数值列表 -----------------------------------------------------------
  // `Float64List.fromList([...])`：ImageFilter.matrix 的入参（宿主只校验 16 个）。
  export class Float64List {
    constructor(props) {
      props = __posArgs(props, ['elements']);
      this.elements = props.elements != null ? props.elements : (props.__pos || []);
    }
    get length() { return this.elements.length; }
    toJSON() { return this.elements; }
    static fromList(props) {
      props = __posArgs(props, ['elements']);
      var list = props.elements != null ? props.elements : props;
      return new Float64List({ elements: list });
    }
  }

  // ----- 栅格代理 -----------------------------------------------------------
  // 宿主协议：键名与 Dart 构造具名实参同名（scroll_controller_bridge 直接读）。
  class __GridDelegate {
    constructor(props) {
      props = props || {};
      for (var k in props) {
        if (k !== '__pos' && props[k] != null) { this[k] = props[k]; }
      }
    }
    toJSON() {
      var j = {};
      for (var k in this) {
        if (this[k] != null) { j[k] = this[k]; }
      }
      return j;
    }
  }
  export class SliverGridDelegateWithFixedCrossAxisCount extends __GridDelegate {
    constructor(props) {
      super(__posArgs(props, ['crossAxisCount', 'mainAxisSpacing',
        'crossAxisSpacing', 'childAspectRatio', 'mainAxisExtent']));
    }
  }
  export class SliverGridDelegateWithMaxCrossAxisExtent extends __GridDelegate {
    constructor(props) {
      super(__posArgs(props, ['maxCrossAxisExtent', 'mainAxisSpacing',
        'crossAxisSpacing', 'childAspectRatio', 'mainAxisExtent']));
    }
  }

  // ----- 滚动物理 -----------------------------------------------------------
  // 宿主协议：scrollPhysicsFromJson 认**类名字符串**——每个物理类 toJSON 即自身
  // 类名，与 Dart 里「同一类实例同一个物理」语义一致。
  class __ScrollPhysics {
    constructor(name, props) {
      this.__name = name;
      if (props && props.parent != null) { this.parent = props.parent; }
    }
    toJSON() { return this.__name; }
  }
  export class BouncingScrollPhysics extends __ScrollPhysics {
    constructor(props) { super('BouncingScrollPhysics', props); }
  }
  export class ClampingScrollPhysics extends __ScrollPhysics {
    constructor(props) { super('ClampingScrollPhysics', props); }
  }
  export class NeverScrollableScrollPhysics extends __ScrollPhysics {
    constructor(props) { super('NeverScrollableScrollPhysics', props); }
  }
  export class AlwaysScrollableScrollPhysics extends __ScrollPhysics {
    constructor(props) { super('AlwaysScrollableScrollPhysics', props); }
  }

  // ----- 按钮样式 -----------------------------------------------------------
  // 宿主协议：buttonStyleFromJson 直取同名字段（padding / minimumSize / side /
  // shape / textStyle 等由各自类 toJSON 递归）。
  export class ButtonStyle {
    constructor(props) {
      props = props || {};
      // 与 TextStyle 同理：构造参数全是具名参，直接按原名拷贝。
      for (var k in props) {
        if (props[k] != null) { this[k] = props[k]; }
      }
    }
    toJSON() {
      var j = {};
      for (var k in this) {
        if (this[k] != null) { j[k] = this[k]; }
      }
      return j;
    }
  }
''';
