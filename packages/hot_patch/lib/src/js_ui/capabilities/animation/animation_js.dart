// ===== 能力：动画（JS 侧片段）=====
//
// 生成器把 Dart 的动画值/控制器按「统一翻译」原样发射为构造调用：
//   `AnimationController(duration: …)` → `new AnimationController({…})`
//   `Curves.easeInOut`                 → `"easeInOut"`（枚举成员名口径，见
//                                        value_forms 的兜底分派）
//
// 本片段因此必须补上动画专属的**值/代理类**（Curves / CrossFadeState /
// Tween / CurvedAnimation / AnimationController），否则产物一执行就是
// ReferenceError，整页挂载失败。
//
// 公共值类（Duration / Size / Offset / Radius）不在这里：它们跨能力复用，
// 由基础能力 `capabilities/core/dart_values_js.dart` 更早注入（本片段可直接
// 引用其 `__durationMs`）。
//
// 显式动画的 AnimationController 是**跨语言对象**：真实控制器在宿主侧（带
// Ticker，按 vsync 推进），JS 侧只持镜像 + 句柄（`ctrl/Flash`）。每帧宿主把
// value 回传到 JS 镜像 → 触发 listeners（AnimatedBuilder 等 JS 逻辑组件据此
// 只重建自己的子树）；同时隐式/过渡动画由宿主原生组件自行插值，无需逐帧过桥。
// 三件套基座（listeners / 回传句柄 / 句柄登记 / dispose / toJSON）由通用工厂
// defineController 提供（见【1c】），本片段只写差异。
const String animationJsSource = r'''
  // ===== 【10.9】Curve 名字表（与 Dart `Curves.<name>` 同口径）=====
  // 只用于 JS 侧推导（AnimatedBuilder 读 value 时宿主已完成真实插值）；
  // 宿主侧按同名表还原真实 Curve（见 flutter_from_json.curveFromJson）。
  function __animCurveFn(name) {
    switch (name) {
      case 'linear': return function (t) { return t; };
      case 'ease': case 'easeInOut': return function (t) {
        return t < 0.5 ? 2 * t * t : 1 - Math.pow(-2 * t + 2, 2) / 2;
      };
      case 'easeIn': return function (t) { return t * t; };
      case 'easeOut': return function (t) { return 1 - (1 - t) * (1 - t); };
      case 'fastOutSlowIn': return function (t) { return t * t * (3 - 2 * t); };
      default:
        if (typeof console !== 'undefined' && console.warn) {
          console.warn('[patch] 未登记的曲线 "' + name + '"，JS 侧按 linear 估算');
        }
        return function (t) { return t; };
    }
  }

  // ===== 【10.9】SDK 常量类镜像（Curves / CrossFadeState）=====
  // 生成器对 `Curves.easeOut` 这类「类名.成员」有两种落点（props 位会翻成
  // 成员名字符串，其它位置原样引用），运行时提供同名对象后两边口径一致。
  // 值一律是**成员名字符串**，宿主按名字查真实曲线 / 枚举（见
  // flutter_from_json 的 curveFromJson / crossFadeStateFromJson）。
  var __CURVE_NAMES = [
    'linear', 'ease', 'easeIn', 'easeOut', 'easeInOut', 'easeInToLinear',
    'easeInSine', 'easeOutSine', 'easeInOutSine',
    'easeInQuad', 'easeOutQuad', 'easeInOutQuad',
    'easeInCubic', 'easeOutCubic', 'easeInOutCubic',
    'easeInQuart', 'easeOutQuart', 'easeInOutQuart',
    'easeInQuint', 'easeOutQuint', 'easeInOutQuint',
    'easeInExpo', 'easeOutExpo', 'easeInOutExpo',
    'easeInCirc', 'easeOutCirc', 'easeInOutCirc',
    'easeInBack', 'easeOutBack', 'easeInOutBack',
    'fastOutSlowIn', 'slowMiddle', 'decelerate',
    'bounceIn', 'bounceOut', 'bounceInOut',
    'elasticIn', 'elasticOut', 'elasticInOut',
    'fastLinearToSlowEaseIn', 'fastEaseInToSlowEaseOut'
  ];
  var Curves = {};
  for (var __ci = 0; __ci < __CURVE_NAMES.length; __ci++) {
    Curves[__CURVE_NAMES[__ci]] = __CURVE_NAMES[__ci];
  }
  G.Curves = Curves;

  G.CrossFadeState = { showFirst: 'showFirst', showSecond: 'showSecond' };

  // ===== 【10.10】Tween / CurvedAnimation（JS 侧值对象）=====
  // 只在 JS 侧推导 value；作为组件 props 下发时经 toJSON 带上 `__curve`，
  // 宿主用父控制器驱动同一条曲线（见 animation_bridge 的 jsDoubleAnimationOf）。
  function Tween(opts) {
    opts = opts || {};
    this.begin = opts.begin;
    this.end = opts.end;
  }
  Tween.prototype.lerp = function (t) {
    var b = this.begin, e = this.end;
    if (typeof b === 'number' && typeof e === 'number') { return b + (e - b) * t; }
    if (b && e && typeof b.dx === 'number' && typeof e.dx === 'number') {
      return new Offset(b.dx + (e.dx - b.dx) * t, b.dy + (e.dy - b.dy) * t);
    }
    return t < 0.5 ? b : e;
  };
  G.Tween = Tween;

  function CurvedAnimation(opts) {
    opts = opts || {};
    this.parent = opts.parent;
    this.curve = opts.curve;
  }
  Object.defineProperty(CurvedAnimation.prototype, 'value', {
    get: function () {
      var t = (this.parent && typeof this.parent.value === 'number') ? this.parent.value : 0;
      return __animCurveFn(this.curve)(t);
    }
  });
  CurvedAnimation.prototype.addListener = function (f) {
    if (this.parent && typeof this.parent.addListener === 'function') {
      this.parent.addListener(f);
    }
  };
  CurvedAnimation.prototype.removeListener = function (f) {
    if (this.parent && typeof this.parent.removeListener === 'function') {
      this.parent.removeListener(f);
    }
  };
  CurvedAnimation.prototype.toJSON = function () {
    return {
      __handle: this.parent ? this.parent.__id : null,
      __curve: this.curve,
      value: this.value
    };
  };
  G.CurvedAnimation = CurvedAnimation;

  // ===== 【10.11】AnimationController 代理类 =====
  // 真实控制器在宿主（Ticker 驱动）；本镜像只保存 value 与时长：
  //   - forward/reverse/repeat/stop/reset → `handleOp('call')`（载荷带 value 与
  //     时长，宿主据此对齐状态后再驱动）；
  //   - 宿主每帧回传 value → onHost 更新镜像 + __notify（JS listeners 据此重建）。
  var AnimationController = defineController('ctrl/Flash', {
    init: function (opts) {
      opts = opts || {};
      this._value = (typeof opts.value === 'number') ? opts.value : 0;
      this.lowerBound = (typeof opts.lowerBound === 'number') ? opts.lowerBound : 0;
      this.upperBound = (typeof opts.upperBound === 'number') ? opts.upperBound : 1;
      this.durationMs = __durationMs(opts.duration);
      if (this.durationMs == null) { this.durationMs = 300; }
    },
    onHost: function (self, p) {
      if (p != null && typeof p === 'number') {
        self._value = p;
        self.__notify();
      }
    },
    extraJSON: function (self) {
      return { value: self._value, durationMs: self.durationMs };
    }
  });
  Object.defineProperty(AnimationController.prototype, 'value', {
    get: function () { return this._value; },
    set: function (v) {
      var n = (typeof v === 'number') ? v : 0;
      if (this._value === n) { return; }
      this._value = n;
      if (this.__id != null) {
        handleOp(this.__id, 'set', { name: 'value', value: n });
      }
      this.__notify();
    }
  });
  AnimationController.prototype.__play = function (method, opts) {
    if (this.__id == null) { return; }
    // 生成器把命名实参摊平为位置实参（`repeat(reverse: true)` → `repeat(true)`），
    // 故 opts 可能是布尔（reverse）/ 数字（duration 毫秒）/ 对象三种形态，这里统一归一。
    var o = opts;
    if (o === true || o === false) { o = { reverse: o }; }
    else if (typeof o === 'number') { o = { duration: o }; }
    else { o = o || {}; }
    var ms = (o.duration != null) ? __durationMs(o.duration) : this.durationMs;
    handleOp(this.__id, 'call', {
      // id 一并下发：宿主基座的 onOp 不带 id，而「挂逐帧回传」需要它。
      id: this.__id,
      method: method,
      durationMs: ms,
      reverse: !!o.reverse,
      value: this._value
    });
  };
  AnimationController.prototype.forward = function (opts) {
    this.__play('forward', opts);
  };
  AnimationController.prototype.reverse = function (opts) {
    this.__play('reverse', opts);
  };
  AnimationController.prototype.repeat = function (opts) {
    this.__play('repeat', opts);
  };
  AnimationController.prototype.stop = function () {
    this.__play('stop', null);
  };
  AnimationController.prototype.reset = function () {
    this.__play('reset', null);
  };
  G.AnimationController = AnimationController;
''';
