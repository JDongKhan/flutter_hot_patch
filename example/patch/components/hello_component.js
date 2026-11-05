// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/hello_component.dart 自动生成
// 重新生成：dart run build_runner build

import { User } from '../hot_module_base.js';
import { AccountCenter } from '../hot_module_base.js';
import { Network } from '../hot_module_base.js';
import { Color, Colors, Column, Duration, ElevatedButton, FontWeight, Future, Row, StateError, StatefulWidget, Text, TextStyle } from '../flutter.js';

// 模型 PanelColors
export class PanelColors {
  static background = new Color({value: 0xFFFF0000});
  static adult = new Color({value: 0xFF4CAF50});
  static primary = new Color({value: 0xFF6750A4});
  static tagline = "demo";
  constructor() {
  }
}

// 组件 HelloCard
export class HelloCard extends StatefulWidget {
  constructor(args) {
    super(args);
    this._count = 0;
    this._user = null;
  }
  initState() {
    this._m$TestMixin2$initState();
    debugPrint("[HelloCard] initState");
  }
  didChangeDependencies() {
    super.didChangeDependencies();
    debugPrint("[HelloCard] didChangeDependencies");
  }
  didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint("[HelloCard] didUpdateWidget: old=" + oldWidget);
  }
  deactivate() {
    super.deactivate();
    debugPrint("[HelloCard] deactivate");
  }
  activate() {
    super.activate();
    debugPrint("[HelloCard] activate");
  }
  dispose() {
    debugPrint("[HelloCard] dispose");
    super.dispose();
  }
  inc() {
    debugPrint("inc: count=" + this._count);
    this.setState(() => {
      this._count += 1;
    });
  }
  async loadUser() {
    var name = await AccountCenter.getUserName();
    var userMap = await Network.post({ "url": "hello", "params": {"name": name} });
    print("用户信息:" + userMap["code"]);
    await Future.delayed({duration: new Duration({seconds: 1})});
    this.setState(() => {
      this._user = new User({name: "Alice", age: 18});
    });
  }
  reset() {
    this.setState(() => {
      this._count = 0;
    });
  }
  demoTryCatchAssert() {
    try {
      if ((this._count < 0)) {
        throw new StateError({message: "count 不能为负数"});
      }
      debugPrint("try ok: count=" + this._count);
    } catch (e) {
      debugPrint("caught: " + e);
    } finally {
      debugPrint("finally");
    }
    assert((this._count >= 0), "count 不能为负数");
    debugPrint("assert passed: count=" + this._count);
  }
  showNative() {
    _app_host_.invoke("nativeToast", { message: "Hello from native (JS-driven)" });
  }
  build(context) {
    var isAdult = ((this._user != null) && (this._user.age >= 18));
    var debugActive = kDebugMode;
    var android = Platform.isAndroid;
    debugPrint("build: count=" + this._count + " debug=" + debugActive + " android=" + android);
    var stage = (() => { switch (this._count) {
        case 0: return "起步";
        default: return "推进中";
      } })();
    return new Column({
      "children": [
        new Text({
          "style": (this.__k0 || (this.__k0 = new TextStyle({
            "color": Colors.blue,
            "fontSize": 24,
            "fontWeight": FontWeight.bold
          }))),
          "data": "Hello from JS logic 4"
        }),
        new Text({
          "data": "count = " + this._count
        }),
        new Text({
          "data": "阶段：" + stage
        }),
        new Text({
          "data": "user: " + (this._user?.name ?? "加载中")
        }),
        new Text({
          "data": "age: " + (this._user?.age ?? "-")
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
              "onPressed": () => this.inc(),
              "style": ElevatedButton.styleFrom({ "backgroundColor": (isAdult ? PanelColors.adult : PanelColors.background), "foregroundColor": Colors.white }),
              "child": (this.__k1 || (this.__k1 = new Text({
                "data": "+1"
              })))
            }),
            new ElevatedButton({
              "onPressed": () => { return this.reset(); },
              "child": (this.__k2 || (this.__k2 = new Text({
                "data": "Reset"
              })))
            }),
            new ElevatedButton({
              "onPressed": () => this.showNative(),
              "child": (this.__k3 || (this.__k3 = new Text({
                "data": "Native"
              })))
            }),
            new ElevatedButton({
              "onPressed": () => this.loadUser(),
              "child": (this.__k4 || (this.__k4 = new Text({
                "data": "Load User"
              })))
            }),
            new ElevatedButton({
              "onPressed": () => this.demoTryCatchAssert(),
              "child": (this.__k5 || (this.__k5 = new Text({
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
    print("--混入代码 2");
  }
  // ---- mixin TestMixin ----
  _m$TestMixin$initState() {
    this.testLog();
    super.initState();
  }
  _m$TestMixin$testLog() {
    print("--混入代码 1");
  }
}

