// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/components/hello_component.dart 自动生成
// 重新生成：dart run build_runner build

import { User } from '../model/user.js';
import { Button, Column, Row, Text, __h } from '../flutter.js';

// 同文件静态单例类 PanelColors（export，供跨文件 import）
export const PanelColors = {
  background: '#ffff0000',
  adult: '#ff4caf50',
  primary: '#ff6750a4',
  tagline: 'demo'
};

class HelloCardComponent {
  constructor() {
    this._count = 0;
    this._user = null;
  }
  inc() { console.debug("inc: count=" + this._count); this.setState(function(){ this._count += 1; }); }
  async loadUser() { await new Promise(function(r){ setTimeout(r, 1000); }); this.setState(function(){ this._user = new User({name: "Alice", age: 18}); }); }
  reset() { this.setState(function(){ this._count = 0; }); }
  showNative() { sendMessage("nativeToast", JSON.stringify({ key: this._key, message: "Hello from native (JS-driven)" })); }
  build() {
    var isAdult = ((this._user != null) && (this._user.age >= 18));
    var debugActive = kDebugMode;
    var android = Platform.isAndroid;
    console.debug("build: count=" + this._count + " debug=" + debugActive + " android=" + android);
    return Column({}, [
        Text({
            "data": "Hello from JS logic",
            "style": {
              "fontSize": 24,
              "fontWeight": "bold",
              "color": '#2196F3'
            }
          }),
        Text({
            "data": "count = " + this._count
          }),
        Text({
            "data": "user: " + ((this._user == null ? null : this._user.name) ?? "加载中")
          }),
        Text({
            "data": "age: " + ((this._user == null ? null : this._user.age) ?? "-")
          }),
        Text({
            "data": ((this._count > 3) ? "count 已经大于 3，点 Reset 归零" : "count 还小，继续 +1")
          }),
        ...((this._count > 0) ? [Text({ "data": "当前 count 是正数（if 条件渲染）" })] : []),
        ...((this._user != null) ? [Text({ "data": "用户已加载（if + else 渲染）" })] : [Text({ "data": "用户未加载，点 Load User" })]),
        ...(function(){ var out = []; for (var i = 0; (i < 3); (i++)) { out.push.apply(out, [Text({ "data": "循环第 " + i + " 个" })]); } return out; })(),
        Row({}, [
            Button({
                "kind": "elevated",
                "label": "+1",
                "event": this.__bind("inc"),
                "style": {
                  "backgroundColor": (isAdult ? PanelColors.adult : PanelColors.background),
                  "foregroundColor": '#FFFFFF'
                }
              }),
            Button({
                "kind": "elevated",
                "label": "Reset",
                "event": this.__bind("reset")
              }),
            Button({
                "kind": "elevated",
                "label": "Native",
                "event": this.__bind("showNative")
              }),
            Button({
                "kind": "elevated",
                "label": "Load User",
                "event": this.__bind("loadUser")
              })
          ])
      ]);
  }
}
export function HelloCard(props, children) {
  return __h(HelloCardComponent, props, children);
}

class HelloPanelComponent {
  constructor() {
    this._taps = 0;
  }
  tap() { this.setState(function(){ this._taps += 1; }); }
  clear() { this.setState(function(){ this._taps = 0; }); }
  build() {
    return Column({}, [
        Text({
            "data": "HelloPanel (JS)",
            "style": {
              "fontSize": 20
            }
          }),
        Text({
            "data": "taps = " + this._taps
          }),
        Row({}, [
            Button({
                "kind": "elevated",
                "label": "Tap",
                "event": this.__bind("tap")
              }),
            Button({
                "kind": "elevated",
                "label": "Clear",
                "event": this.__bind("clear")
              })
          ])
      ]);
  }
}
export function HelloPanel(props, children) {
  return __h(HelloPanelComponent, props, children);
}

