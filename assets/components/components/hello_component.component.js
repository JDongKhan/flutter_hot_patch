// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/components/hello_component.dart 自动生成
// 重新生成：dart run build_runner build

import { User } from '../model/user.model.js';

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
          "type": "Row",
          "children": [
            {
              "type": "Button",
              "props": {
                "kind": "elevated",
                "label": "+1",
                "event": "inc",
                "style": {
                  "backgroundColor": '#4CAF50',
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

