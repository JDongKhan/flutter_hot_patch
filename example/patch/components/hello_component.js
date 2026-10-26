// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/hello_component.dart 自动生成
// 重新生成：dart run build_runner build

import { User } from '../model/user.js';
import { Column, ElevatedButton, Row, Text } from '../flutter.js';

// 静态单例类 PanelColors
export const PanelColors = {
  background: '#ffff0000',
  adult: '#ff4caf50',
  primary: '#ff6750a4',
  tagline: 'demo'
};

// 组件 HelloCard
export class HelloCard {
  constructor(args) {
    this.props = args || {};
    this._count = 0;
    this._user = null;
  }
  initState() {
    this._m$TestMixin2$initState();
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
    this.setState(() => { this._count += 1; });
  }
  async loadUser() {
    var name = await _app_host_.invoke("getUserName", []);
    var userMap = await _app_host_.invoke("post", {"url": "hello", "params": {"name": name}});
    console.log("用户信息:" + __str(userMap["code"]));
    await new Promise(function(r){ setTimeout(r, 1000); });
    this.setState(() => { this._user = new User({name: "Alice", age: 18}); });
  }
  reset() {
    this.setState(() => { this._count = 0; });
  }
  demoTryCatchAssert() {
    try {
      if ((this._count < 0)) {
        throw new StateError({message: "count 不能为负数"});
      }
      console.debug("try ok: count=" + __str(this._count));
    } catch (e) {
      console.debug("caught: " + __str(e));
    } finally {
      console.debug("finally");
    }
    assert((this._count >= 0), "count 不能为负数");
    console.debug("assert passed: count=" + __str(this._count));
  }
  showNative() {
    _app_host_.invoke("nativeToast", { message: "Hello from native (JS-driven)" });
  }
  build(context) {
    var isAdult = ((this._user != null) && (this._user.age >= 18));
    var debugActive = kDebugMode;
    var android = Platform.isAndroid;
    console.debug("build: count=" + __str(this._count) + " debug=" + __str(debugActive) + " android=" + __str(android));
    var stage = (() => { switch (this._count) {
    case 0: return "起步";
    default: return "推进中";
} })();
    return new Column({
        "children": [
          new Text({
              "style": {
                "fontSize": 24,
                "fontWeight": "bold",
                "color": '#2196F3'
              },
              "data": "Hello from JS logic 4"
            }),
          new Text({
              "data": "count = " + this._count
            }),
          new Text({
              "data": "阶段：" + stage
            }),
          new Text({
              "data": "user: " + ((this._user == null ? null : this._user.name) ?? "加载中")
            }),
          new Text({
              "data": "age: " + ((this._user == null ? null : this._user.age) ?? "-")
            }),
          new Text({
              "data": (this._count > 3) ? "count 已经大于 3，点 Reset 归零" : "count 还小，继续 +1"
            }),
          ...((this._count > 0) ? [new Text({
            "data": "当前 count 是正数（if 条件渲染）"
          })] : []),
          ...((this._user != null) ? [new Text({
            "data": "用户已加载（if + else 渲染）"
          })] : [new Text({
            "data": "用户未加载，点 Load User"
          })]),
          ...(() => { var out = []; for (let i = 0; (i < 3); (i++)) { out.push.apply(out, [new Text({
            "data": "循环第 " + i + " 个"
          })]); } return out; })(),
          new Row({
              "children": [
                new ElevatedButton({
                    "onPressed": this.__bindFn(0, [], (...__a) => this.inc(...__a)),
                    "style": {
                      "backgroundColor": (isAdult ? PanelColors.adult : PanelColors.background),
                      "foregroundColor": '#FFFFFF'
                    },
                    "child": (this.__k0 || (this.__k0 = new Text({
                        "data": "+1"
                      })))
                  }),
                new ElevatedButton({
                    "onPressed": this.__bindFn(1, [], () => this.reset()),
                    "child": (this.__k1 || (this.__k1 = new Text({
                        "data": "Reset"
                      })))
                  }),
                new ElevatedButton({
                    "onPressed": this.__bindFn(2, [], (...__a) => this.showNative(...__a)),
                    "child": (this.__k2 || (this.__k2 = new Text({
                        "data": "Native"
                      })))
                  }),
                new ElevatedButton({
                    "onPressed": this.__bindFn(3, [], (...__a) => this.loadUser(...__a)),
                    "child": (this.__k3 || (this.__k3 = new Text({
                        "data": "Load User"
                      })))
                  }),
                new ElevatedButton({
                    "onPressed": this.__bindFn(4, [], (...__a) => this.demoTryCatchAssert(...__a)),
                    "child": (this.__k4 || (this.__k4 = new Text({
                        "data": "Try/Catch"
                      })))
                  })
              ]
            })
        ]
      });
  }
  // ---- mixin TestMixin2 ----
  _m$TestMixin2$initState() {
    this.testLog();
    this._m$TestMixin$initState();
  }
  testLog() {
    console.log("--混入代码 2");
  }
  // ---- mixin TestMixin ----
  _m$TestMixin$initState() {
    this.testLog();
  }
  _m$TestMixin$testLog() {
    console.log("--混入代码 1");
  }
}

