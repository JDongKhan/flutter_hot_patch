// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/components/hello_component.dart 自动生成
// 重新生成：dart run build_runner build

import { User } from '../model/user.js';
import { __h } from '../flutter.js';

// 静态单例类 PanelColors
export const PanelColors = {
  background: '#ffff0000',
  adult: '#ff4caf50',
  primary: '#ff6750a4',
  tagline: 'demo'
};

// 组件 HelloCard
export class HelloCard {
  constructor() {
    this._count = 0;
    this._user = null;
  }
  initState() {
    console.debug("[HelloCard] initState");
  }
  didChangeDependencies() {
    console.debug("[HelloCard] didChangeDependencies");
  }
  didUpdateWidget(oldWidget) {
    console.debug("[HelloCard] didUpdateWidget: old=" + __str(oldWidget));
  }
  deactivate() {
    console.debug("[HelloCard] deactivate");
  }
  activate() {
    console.debug("[HelloCard] activate");
  }
  dispose() {
    console.debug("[HelloCard] dispose");
  }
  inc() {
    console.debug("inc: count=" + __str(this._count));
    this.setState(function(){ this._count += 1; });
  }
  async loadUser() {
    var name = await __jsui.host("getUserName", []);
    var userMap = await __jsui.host("post", {"params": {"name": name}});
    console.log("用户信息:" + __str(userMap["code"]));
    await new Promise(function(r){ setTimeout(r, 1000); });
    this.setState(function(){ this._user = new User({name: "Alice", age: 18}); });
  }
  reset() {
    this.setState(function(){ this._count = 0; });
  }
  showNative() {
    __jsui.host("nativeToast", { message: "Hello from native (JS-driven)" });
  }
  build() {
    var isAdult = ((this._user != null) && (this._user.age >= 18));
    var debugActive = kDebugMode;
    var android = Platform.isAndroid;
    console.debug("build: count=" + __str(this._count) + " debug=" + __str(debugActive) + " android=" + __str(android));
    var stage = (() => { switch (this._count) {
    case 0: return "起步";
    default: return "推进中";
} })();
    return __h('Column', {}, [
        __h('Text', {
            "data": "Hello from JS logic 4",
            "style": {
              "fontSize": 24,
              "fontWeight": "bold",
              "color": '#2196F3'
            }
          }),
        __h('Text', {
            "data": "count = " + __str(this._count)
          }),
        __h('Text', {
            "data": "阶段：" + __str(stage)
          }),
        __h('Text', {
            "data": "user: " + __str(((this._user == null ? null : this._user.name) ?? "加载中"))
          }),
        __h('Text', {
            "data": "age: " + __str(((this._user == null ? null : this._user.age) ?? "-"))
          }),
        __h('Text', {
            "data": ((this._count > 3) ? "count 已经大于 3，点 Reset 归零" : "count 还小，继续 +1")
          }),
        ...((this._count > 0) ? [__h('Text', { "data": "当前 count 是正数（if 条件渲染）" })] : []),
        ...((this._user != null) ? [__h('Text', { "data": "用户已加载（if + else 渲染）" })] : [__h('Text', { "data": "用户未加载，点 Load User" })]),
        ...(() => { var out = []; for (let i = 0; (i < 3); (i++)) { out.push.apply(out, [__h('Text', { "data": "循环第 " + __str(i) + " 个" })]); } return out; })(),
        __h('Row', {}, [
            __h('Button', {
                "kind": "elevated",
                "label": "+1",
                "event": this.__bind("inc"),
                "style": {
                  "backgroundColor": (isAdult ? PanelColors.adult : PanelColors.background),
                  "foregroundColor": '#FFFFFF'
                }
              }),
            __h('Button', {
                "kind": "elevated",
                "label": "Reset",
                "event": this.__bind("this.reset()")
              }),
            __h('Button', {
                "kind": "elevated",
                "label": "Native",
                "event": this.__bind("showNative")
              }),
            __h('Button', {
                "kind": "elevated",
                "label": "Load User",
                "event": this.__bind("loadUser")
              })
          ])
      ]);
  }
}

