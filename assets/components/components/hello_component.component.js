// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/components/hello_component.dart 自动生成
// 重新生成：dart run build_runner build

import { User } from '../model/user.model.js';

// 同文件静态单例类 PanelColors（仅本产物内可见）
const PanelColors = {
  background: '#ffff0000',
  adult: '#ff4caf50',
  primary: '#ff6750a4',
  tagline: 'demo'
};

export class HelloCard {
  constructor() {
    this._count = 0;
    this._user = null;
  }
  inc() { this.setState(function(){ this._count += 1; }); }
  async loadUser() { await new Promise(function(r){ setTimeout(r, 1000); }); this.setState(function(){ this._user = new User({name: "Alice", age: 18}); }); }
  reset() { this.setState(function(){ this._count = 0; }); }
  showNative() { sendMessage("nativeToast", JSON.stringify({ key: this._key, message: "Hello from native (JS-driven)" })); }
  build() {
    var isAdult = ((this._user != null) && (this._user.age >= 18));
    return {
      "type": "Column",
      "children": [
        {
          "type": "Text",
          "props": {
            "data": "Hello from JS logic",
            "style": {
              "fontSize": 24,
              "fontWeight": "bold",
              "color": '#2196F3'
            }
          }
        },
        {
          "type": "Text",
          "props": {
            "data": "count = " + this._count
          }
        },
        {
          "type": "Text",
          "props": {
            "data": "user: " + ((this._user == null ? null : this._user.name) ?? "加载中")
          }
        },
        {
          "type": "Text",
          "props": {
            "data": "age: " + ((this._user == null ? null : this._user.age) ?? "-")
          }
        },
        {
          "type": "Text",
          "props": {
            "data": ((this._count > 3) ? "count 已经大于 3，点 Reset 归零" : "count 还小，继续 +1")
          }
        },
        ...((this._count > 0) ? [{ "type": "Text", "props": { "data": "当前 count 是正数（if 条件渲染）" } }] : []),
        ...((this._user != null) ? [{ "type": "Text", "props": { "data": "用户已加载（if + else 渲染）" } }] : [{ "type": "Text", "props": { "data": "用户未加载，点 Load User" } }]),
        ...(function(){ var out = []; for (var i = 0; (i < 3); (i++)) { out.push.apply(out, [{ "type": "Text", "props": { "data": "循环第 " + i + " 个" } }]); } return out; })(),
        {
          "type": "Row",
          "children": [
            {
              "type": "Button",
              "props": {
                "kind": "elevated",
                "label": "+1",
                "event": "inc",
                "style": {
                  "backgroundColor": (isAdult ? PanelColors.adult : PanelColors.background),
                  "foregroundColor": '#FFFFFF'
                }
              }
            },
            {
              "type": "Button",
              "props": {
                "kind": "elevated",
                "label": "Reset",
                "event": "reset"
              }
            },
            {
              "type": "Button",
              "props": {
                "kind": "elevated",
                "label": "Native",
                "event": "showNative"
              }
            },
            {
              "type": "Button",
              "props": {
                "kind": "elevated",
                "label": "Load User",
                "event": "loadUser"
              }
            }
          ]
        }
      ]
    };
  }
}

export class HelloPanel {
  constructor() {
    this._taps = 0;
  }
  tap() { this.setState(function(){ this._taps += 1; }); }
  clear() { this.setState(function(){ this._taps = 0; }); }
  build() {
    return {
      "type": "Column",
      "children": [
        {
          "type": "Text",
          "props": {
            "data": "HelloPanel (JS)",
            "style": {
              "fontSize": 20
            }
          }
        },
        {
          "type": "Text",
          "props": {
            "data": "taps = " + this._taps
          }
        },
        {
          "type": "Row",
          "children": [
            {
              "type": "Button",
              "props": {
                "kind": "elevated",
                "label": "Tap",
                "event": "tap"
              }
            },
            {
              "type": "Button",
              "props": {
                "kind": "elevated",
                "label": "Clear",
                "event": "clear"
              }
            }
          ]
        }
      ]
    };
  }
}

