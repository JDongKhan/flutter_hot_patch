// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/media_query_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { BorderRadius, BoxDecoration, Colors, Column, Container, CrossAxisAlignment, EdgeInsets, Expanded, FontWeight, MediaQuery, Padding, Radius, Row, SizedBox, StatelessWidget, Text, TextScaler, TextStyle, double } from '../flutter.js';

// 组件 MediaQueryDetail
export class MediaQueryDetail extends StatelessWidget {
  constructor(args) {
    super(args);
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.start,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "MediaQuery",
          "style": new TextStyle({
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 4
        }))),
        (this.__k2 || (this.__k2 = new Text({
          "data": "下面逐项显示 MediaQuery.of(context) 的全部字段：原生模式与 JS 热更模式各看一次即可对比。",
          "style": new TextStyle({
            "fontSize": 12,
            "color": Colors.black54
          })
        }))),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 8
        }))),
        (this.__k4 || (this.__k4 = new _MediaQueryDump({
          "accent": Colors.orange,
          "label": "外层 MediaQuery.of(context)"
        }))),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 8
        }))),
        new Container({
          "color": Colors.grey.shade300,
          "child": MediaQuery.removePadding({
            "context": context,
            "removeTop": true,
            "removeBottom": true,
            "removeLeft": true,
            "removeRight": true,
            "child": (this.__k5 || (this.__k5 = new _MediaQueryDump({
              "accent": Colors.teal,
              "label": "removePadding 四边移除"
            })))
          })
        }),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 8
        }))),
        new Container({
          "color": Colors.grey.shade300,
          "child": MediaQuery.removePadding({
            "context": context,
            "removeTop": true,
            "child": (this.__k6 || (this.__k6 = new _MediaQueryDump({
              "accent": Colors.indigo,
              "label": "removePadding 仅移除 top"
            })))
          })
        }),
        (this.__k7 || (this.__k7 = new SizedBox({
          "height": 12
        }))),
        (this.__k8 || (this.__k8 = new Text({
          "data": "MediaQuery(data: ...)：覆盖子树读到的数据",
          "style": new TextStyle({
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 4
        }))),
        (this.__k9 || (this.__k9 = new Text({
          "data": "下面这段文字被 MediaQuery 覆盖了 textScaler（1.6x），其余字段沿用外层；下方 dump 里可看到 textScaler 变化。",
          "style": new TextStyle({
            "fontSize": 12,
            "color": Colors.black54
          })
        }))),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 8
        }))),
        new MediaQuery({
          "data": MediaQuery.of(context).copyWith({ "textScaler": TextScaler.linear({textScaleFactor: 1.6}) }),
          "child": new Column({
            "crossAxisAlignment": CrossAxisAlignment.start,
            "children": [
              new Text({
                "data": "被 MediaQuery 放大的文字（1.6x）"
              }),
              new SizedBox({
                "height": 8
              }),
              new _MediaQueryDump({
                "label": "MediaQuery(textScaler: 1.6)",
                "accent": Colors.purple
              })
            ]
          })
        })
      ]
    });
  }
}

// 组件 _MediaQueryDump
export class _MediaQueryDump extends StatelessWidget {
  constructor(args) {
    super(args);
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.label = (args && args.label !== undefined) ? args.label : '';
    this.accent = (args && args.accent !== undefined) ? args.accent : null;
  }
  build(context) {
    const mq = MediaQuery.of(context);
    return new Container({
      "width": double.infinity,
      "padding": (this.__k0 || (this.__k0 = EdgeInsets.all({
        "value": 8
      }))),
      "decoration": new BoxDecoration({
        "color": this.accent.withValues({ "alpha": 0.08 }),
        "borderRadius": (this.__k1 || (this.__k1 = BorderRadius.all({
          "radius": Radius.circular({
            "radius": 6
          })
        })))
      }),
      "child": new Column({
        "crossAxisAlignment": CrossAxisAlignment.start,
        "children": [
          new Text({
            "style": new TextStyle({
              "fontSize": 12,
              "fontWeight": FontWeight.bold,
              "color": this.accent
            }),
            "data": this.label
          }),
          (this.__k2 || (this.__k2 = new SizedBox({
            "height": 4
          }))),
          this._row("size", mq.size.width.toStringAsFixed(1) + " × " + mq.size.height.toStringAsFixed(1)),
          this._row("padding", this._edges(mq.padding)),
          this._row("viewPadding", this._edges(mq.viewPadding)),
          this._row("viewInsets", this._edges(mq.viewInsets)),
          this._row("devicePixelRatio", mq.devicePixelRatio.toStringAsFixed(2)),
          this._row("textScaler", mq.textScaler.scale(1).toStringAsFixed(2)),
          this._row("orientation", this._enumText("" + mq.orientation)),
          this._row("platformBrightness", this._enumText("" + mq.platformBrightness)),
          this._row("navigationMode", this._enumText("" + mq.navigationMode)),
          this._row("alwaysUse24HourFormat", "" + mq.alwaysUse24HourFormat),
          this._row("accessibleNavigation", "" + mq.accessibleNavigation),
          this._row("disableAnimations", "" + mq.disableAnimations),
          this._row("invertColors", "" + mq.invertColors),
          this._row("highContrast", "" + mq.highContrast),
          this._row("boldText", "" + mq.boldText)
        ]
      })
    });
  }
  _edges(e) {
    return "L" + e.left.toStringAsFixed(1) + " T" + e.top.toStringAsFixed(1) + " " + "R" + e.right.toStringAsFixed(1) + " B" + e.bottom.toStringAsFixed(1);
  }
  _enumText(s) {
    const dot = s.indexOf(".");
    return ((dot >= 0) ? s.substring((dot + 1)) : s);
  }
  _row(name, value) {
    return new Padding({
      "padding": (this.__k3 || (this.__k3 = EdgeInsets.only({
        "top": 2
      }))),
      "child": new Row({
        "crossAxisAlignment": CrossAxisAlignment.start,
        "children": [
          new SizedBox({
            "width": 150,
            "child": new Text({
              "style": (this.__k4 || (this.__k4 = new TextStyle({
                "color": Colors.black54,
                "fontSize": 11
              }))),
              "data": name
            })
          }),
          new Expanded({
            "child": new Text({
              "style": (this.__k5 || (this.__k5 = new TextStyle({
                "fontSize": 11
              }))),
              "data": value
            })
          })
        ]
      })
    });
  }
}

