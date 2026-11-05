// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/inherited_widget_demo.dart 自动生成
// 重新生成：dart run build_runner build

import { Builder, Card, Column, EdgeInsets, ElevatedButton, InheritedWidget, MainAxisAlignment, MainAxisSize, Padding, Row, SizedBox, StatefulWidget, StatelessWidget, Text } from '../flutter.js';

// 组件 InheritedCard
export class InheritedCard extends StatefulWidget {
  constructor(args) {
    super(args);
    this._count = 0;
    this._mode = "A";
    this._lastRead = (-1);
  }
  build(context) {
    return new _DemoScope({
      "count": this._count,
      "mode": this._mode,
      "child": new Card({
        "child": new Padding({
          "padding": (this.__k0 || (this.__k0 = EdgeInsets.all({
            "value": 16
          }))),
          "child": new Column({
            "mainAxisSize": MainAxisSize.min,
            "children": [
              (this.__k1 || (this.__k1 = new Text({
                "data": "InheritedWidget · 祖先数据共享"
              }))),
              new _CountLabel({}),
              new _ModeLabel({}),
              new Text({
                "data": "read 快照 = " + this._lastRead
              }),
              (this.__k2 || (this.__k2 = new SizedBox({
                "height": 8
              }))),
              new Row({
                "mainAxisAlignment": MainAxisAlignment.center,
                "children": [
                  new ElevatedButton({
                    "onPressed": () => { this.setState(() => {
                        this._count += 1;
                      }); },
                    "child": (this.__k3 || (this.__k3 = new Text({
                      "data": "count +1"
                    })))
                  }),
                  (this.__k4 || (this.__k4 = new SizedBox({
                    "width": 12
                  }))),
                  new ElevatedButton({
                    "onPressed": () => { this.setState(() => {
                        this._mode = ((this._mode === "A") ? "B" : "A");
                      }); },
                    "child": (this.__k5 || (this.__k5 = new Text({
                      "data": "切换 mode"
                    })))
                  }),
                  (this.__k4 || (this.__k4 = new SizedBox({
                    "width": 12
                  }))),
                  new Builder({
                    "builder": (context) => new ElevatedButton({
                      "onPressed": () => { this.setState(() => {
                          this._lastRead = (_DemoScope.read(context)?.count ?? (-1));
                        }); },
                      "child": (this.__k6 || (this.__k6 = new Text({
                        "data": "read"
                      })))
                    })
                  })
                ]
              })
            ]
          })
        })
      })
    });
  }
}

// 组件 _ModeLabel
export class _ModeLabel extends StatelessWidget {
  constructor(args) {
    super(args);
  }
  build(context) {
    const scope = _DemoScope.of(context);
    return new Text({
      "data": "mode = " + scope.mode
    });
  }
}

// 组件 _CountLabel
export class _CountLabel extends StatelessWidget {
  constructor(args) {
    super(args);
  }
  build(context) {
    const scope = _DemoScope.of(context);
    return new Text({
      "data": "count = " + scope.count
    });
  }
}

// 组件 _DemoScope
export class _DemoScope extends InheritedWidget {
  constructor(args) {
    super(args);
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.count = (args && args.count !== undefined) ? args.count : 0;
    this.mode = (args && args.mode !== undefined) ? args.mode : '';
  }
  static of(context) {
    const scope = context.dependOnInheritedWidgetOfExactType({ typeArguments: {"0": "_DemoScope"} });
    return scope;
  }
  static read(context) {
    return context.getInheritedWidgetOfExactType({ typeArguments: {"0": "_DemoScope"} });;
  }
  updateShouldNotify(oldWidget) {
    return ((this.count !== oldWidget.count) || (this.mode !== oldWidget.mode));
  }
}

