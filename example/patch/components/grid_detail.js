// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/grid_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Alignment, AppBar, BorderRadius, BoxDecoration, Colors, Column, Container, CrossAxisAlignment, EdgeInsets, Expanded, FloatingActionButton, FontWeight, GridView, Icon, Icons, Padding, Scaffold, ScrollController, SliverGridDelegateWithFixedCrossAxisCount, SliverGridDelegateWithMaxCrossAxisExtent, StatefulWidget, Text, TextStyle } from '../flutter.js';

// 组件 GridDetail
export class GridDetail extends StatefulWidget {
  constructor(args) {
    super(args);
    this._controller = new ScrollController();
    this._offset = 0;
  }
  initState() {
    super.initState();
    this._controller.addListener(() => { this.setState(() => { this._offset = this._controller.offset; }); });
  }
  dispose() {
    this._controller.dispose();
    super.dispose();
  }
  _jumpBottom() {
    this._controller.jumpTo(this._controller.position.maxScrollExtent);
  }
  build(context) {
    return new Scaffold({
      "backgroundColor": Colors.grey.shade50,
      "appBar": new AppBar({
        "title": (this.__k0 || (this.__k0 = new Text({
          "data": "GridView 懒加载验证"
        }))),
        "backgroundColor": Colors.teal,
        "foregroundColor": Colors.white
      }),
      "floatingActionButton": new FloatingActionButton({
        "onPressed": this.__bindFn(0, [], (...__a) => this._jumpBottom(...__a)),
        "backgroundColor": Colors.teal,
        "foregroundColor": Colors.white,
        "tooltip": "跳到底",
        "child": (this.__k1 || (this.__k1 = new Icon({
          "icon": Icons.arrow_downward
        })))
      }),
      "body": new Column({
        "crossAxisAlignment": CrossAxisAlignment.stretch,
        "children": [
          new Padding({
            "padding": (this.__k2 || (this.__k2 = EdgeInsets.all({
              "value": 12
            }))),
            "child": new Text({
              "style": (this.__k3 || (this.__k3 = new TextStyle({
                "color": Colors.grey,
                "fontSize": 13
              }))),
              "data": "controller offset: " + this._offset.toStringAsFixed(1)
            })
          }),
          (this.__k4 || (this.__k4 = new Padding({
            "child": new Text({
              "style": new TextStyle({
                "fontSize": 14,
                "fontWeight": FontWeight.bold
              }),
              "data": "GridView.builder · 固定 3 列 · 30 项（懒加载）"
            }),
            "padding": EdgeInsets.symmetric({
              "horizontal": 12
            })
          }))),
          new Expanded({
            "flex": 5,
            "child": GridView.builder({
              "controller": this._controller,
              "gridDelegate": (this.__k5 || (this.__k5 = new SliverGridDelegateWithFixedCrossAxisCount({
                "childAspectRatio": 1,
                "crossAxisCount": 3,
                "crossAxisSpacing": 8,
                "mainAxisSpacing": 8
              }))),
              "itemCount": 30,
              "itemBuilder": (context, index) => new Container({
                "decoration": new BoxDecoration({
                  "color": Colors.teal.shade100,
                  "borderRadius": BorderRadius.circular({
                    "radius": 8
                  })
                }),
                "alignment": Alignment.center,
                "child": new Text({
                  "style": (this.__k6 || (this.__k6 = new TextStyle({
                    "fontWeight": FontWeight.bold
                  }))),
                  "data": "格 " + index
                })
              })
            })
          }),
          (this.__k7 || (this.__k7 = new Padding({
            "child": new Text({
              "style": new TextStyle({
                "fontSize": 14,
                "fontWeight": FontWeight.bold
              }),
              "data": "GridView.builder · MaxCrossAxisExtent 120 · 20 项（懒加载）"
            }),
            "padding": EdgeInsets.symmetric({
              "horizontal": 12,
              "vertical": 8
            })
          }))),
          new Expanded({
            "flex": 4,
            "child": GridView.builder({
              "gridDelegate": (this.__k8 || (this.__k8 = new SliverGridDelegateWithMaxCrossAxisExtent({
                "childAspectRatio": 1,
                "crossAxisSpacing": 8,
                "mainAxisSpacing": 8,
                "maxCrossAxisExtent": 120
              }))),
              "itemCount": 20,
              "itemBuilder": (context, index) => new Container({
                "decoration": new BoxDecoration({
                  "color": Colors.orange.shade100,
                  "borderRadius": BorderRadius.circular({
                    "radius": 8
                  })
                }),
                "alignment": Alignment.center,
                "child": new Text({
                  "style": (this.__k6 || (this.__k6 = new TextStyle({
                    "fontWeight": FontWeight.bold
                  }))),
                  "data": "项 " + index
                })
              })
            })
          })
        ]
      })
    });
  }
}

