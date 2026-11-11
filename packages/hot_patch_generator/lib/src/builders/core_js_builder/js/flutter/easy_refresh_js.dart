// easy_refresh 能力的 JS 片段（随 flutter.js 发布）。
//
// EasyRefresh 的「手势 / 物理 / 指示器」都在宿主侧，而 onRefresh / onLoad 由
// JS 补丁实现。这类回调返回 `Future`，**不需要**本能力自己开回传入口：
// 统一走通用「需要结果的事件调用」——宿主 `JsRuntimeManager.invokeAwait(句柄
// id, 参数)` → JS `__jsui.invokeAwait` → await 结果 → `jsuiEventResult` 回传
// token（见 mini_react_js.dart）。Dismissible 的 confirmDismiss 用的也是它。
//
// 本片段只负责 EasyRefreshController：JS 实例与宿主真实 controller 按句柄 id
// 绑定（句柄层见 controller_base_js.dart）。
const String easyRefreshJsSource = r'''
  // 与 ScrollController 同款句柄层（基类见 controller_base_js.dart）：JS 实例与
  // 宿主真实 EasyRefreshController 按句柄 id 绑定。控制方法把**原始实参数组**
  // 原样下发（`__handleOp 'call'`），由宿主按 Dart 形参的类型/顺序还原：
  // 生成器对方法调用的具名实参是位置化扁平（JS 无具名参数），所以这里不臆造
  // 形参名，交给宿主按类型判别（数值 → overOffset、Duration 值 → duration、
  // 曲线名 → curve、布尔 → force）。
  // 宿主侧桥接见 capabilities/easy_refresh/easy_refresh_bridge.dart。
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
''';
