// 三方库 JS（宿主维护）：easy_refresh
//
// 生成器不生成该模块 —— EasyRefresh 来自三方包 `easy_refresh`，不是运行时内建
// 能力：JS 类由本工程维护在 `js/easy_refresh.js`，构建时由 `ui_third_party_js`
// 原样拷贝到 `patch/packages/easy_refresh.js`。文件名即 Dart 包名
// （`js/easy_refresh.js` ↔ `package:easy_refresh`），业务产物按
// `import { EasyRefresh, EasyRefreshController } from '<...>/packages/easy_refresh.js'`
// 取用；它**不会**进 `flutter.js`（框架产物只承载内建宿主组件）。
//
// 手势 / 物理 / 指示器全在宿主侧，宿主桥接见
// `example/lib/custom/easy_refresh/easy_refresh_bridge.dart`。onRefresh / onLoad
// 返回 Future，走通用「需要结果的事件调用」（`__jsui.invokeAwait` →
// `jsuiEventResult` 回传 token），本模块不需要自己的回传入口。
//
// 属性透传：除 `__fnProps` 里的函数形参外，其余 props 由 Component 原样下发，
// 不需要在类里逐个声明。宿主桥接只透传业务显式声明的值（目前支持
// child / onRefresh / onLoad / controller / refreshOnStart / triggerAxis），
// 未传时沿用 easy_refresh 自己的默认值——桥接不补默认值，避免与原生不一致。
// 需要横滑不触发刷新时，由业务显式传 `triggerAxis: Axis.vertical`。
import { Component, ControllerBase } from '../flutter.js';

var G = typeof globalThis !== 'undefined' ? globalThis : Function('return this')();
var __handleOp = G.__core.__handleOp;

// 宿主包装类：实例**自身**就是宿主元素。类型名直接取类名（`__type.name`），
// props 由基类构造期统一拆分。
export class EasyRefresh extends Component {
  // 函数形参名单：这几个 props 会跨桥换成句柄 / 闭包，其余按普通 props 下发。
  static __fnProps = ["childBuilder", "frictionFactor", "onLoad", "onRefresh", "scrollBehaviorBuilder"];
  static builder(props) { return new EasyRefresh(Object.assign({}, props, { factory: 'builder' })); }
}

// EasyRefreshController：与 ScrollController 同款句柄层（基类见
// controller_base_js.dart，随 flutter.js 发布）。JS 实例与宿主真实 controller
// 按句柄 id 绑定；控制方法把**原始实参数组**原样下发（`__handleOp 'call'`），
// 由宿主按 Dart 形参的类型/顺序还原：数值 → overOffset、Duration 值 → duration、
// 曲线名 → curve、布尔 → force。
export class EasyRefreshController extends ControllerBase {
  constructor(opts) {
    super();
    var o = opts || {};
    this.controlFinishRefresh = !!o.controlFinishRefresh;
    this.controlFinishLoad = !!o.controlFinishLoad;
    this.__bindHandle('ctrl/EasyRefresh', {
      // 构造参数随句柄 create 下发：宿主据此创建真实 controller（putIfAbsent——
      // 创建消息与首帧渲染谁先到都复用同一实例）。
      meta: function (self) {
        return {
          controlFinishRefresh: self.controlFinishRefresh,
          controlFinishLoad: self.controlFinishLoad
        };
      },
      // 组件渲染时 controller 经 toJSON 跨桥（`{__handle, controlFinish*}`），
      // Host 在渲染期兜底创建时同样读得到构造参数。
      extraJSON: function (self) {
        return {
          controlFinishRefresh: self.controlFinishRefresh,
          controlFinishLoad: self.controlFinishLoad
        };
      }
    });
  }
  __op(method, args) {
    if (this.__id == null) { return undefined; }
    return __handleOp(this.__id, 'call', { method: method, args: args });
  }
  callRefresh() {
    return this.__op('callRefresh', Array.prototype.slice.call(arguments));
  }
  callLoad() {
    return this.__op('callLoad', Array.prototype.slice.call(arguments));
  }
  openHeaderSecondary() {
    return this.__op('openHeaderSecondary', Array.prototype.slice.call(arguments));
  }
  closeHeaderSecondary() {
    return this.__op('closeHeaderSecondary', Array.prototype.slice.call(arguments));
  }
  openFooterSecondary() {
    return this.__op('openFooterSecondary', Array.prototype.slice.call(arguments));
  }
  closeFooterSecondary() {
    return this.__op('closeFooterSecondary', Array.prototype.slice.call(arguments));
  }
  resetHeader() { return this.__op('resetHeader', []); }
  resetFooter() { return this.__op('resetFooter', []); }
  finishRefresh() {
    return this.__op('finishRefresh', Array.prototype.slice.call(arguments));
  }
  finishLoad() {
    return this.__op('finishLoad', Array.prototype.slice.call(arguments));
  }
}
