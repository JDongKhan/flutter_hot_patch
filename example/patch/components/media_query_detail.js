// GENERATED CODE - DO NOT EDIT
// 由 dynamic_flutter_generator 从 lib/components/media_query_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { BorderRadius, BoxDecoration, Colors, Column, Container, CrossAxisAlignment, EdgeInsets, Expanded, FontWeight, MediaQuery, Orientation, OutlinedButton, Padding, Radius, Row, SizedBox, StatefulWidget, StatelessWidget, Text, TextScaler, TextStyle, double } from '../flutter.js';

// 组件 MediaQueryDetail
export class MediaQueryDetail extends StatefulWidget {
  constructor(args) {
    super(args);
    this._scaled = false;
  }
  _line(s) {
    return new Padding({
      "padding": (this.__k0 || (this.__k0 = EdgeInsets.only({
        "bottom": 2
      }))),
      "child": new Text({
        "style": (this.__k1 || (this.__k1 = new TextStyle({
          "fontSize": 12
        }))),
        "data": s
      })
    });
  }
  build(context) {
    const mq = MediaQuery.of(context);
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.start,
      "children": [
        (this.__k2 || (this.__k2 = new Text({
          "data": "MediaQuery",
          "style": new TextStyle({
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 4
        }))),
        (this.__k4 || (this.__k4 = new Text({
          "data": "下面逐项显示 MediaQuery.of(context) 的全部字段：原生模式与 JS 热更模式各看一次即可对比。",
          "style": new TextStyle({
            "fontSize": 12,
            "color": Colors.black54
          })
        }))),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 8
        }))),
        this._line("orientation：" + ((mq.orientation === Orientation.portrait) ? "portrait" : "landscape")),
        this._line("size：" + mq.size.width.toStringAsFixed(0) + " x " + "" + mq.size.height.toStringAsFixed(0)),
        this._line("devicePixelRatio：" + mq.devicePixelRatio.toStringAsFixed(2)),
        this._line("padding.top：" + mq.padding.top.toStringAsFixed(0)),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 8
        }))),
        (this.__k6 || (this.__k6 = new _MediaQueryDump({
          "accent": Colors.orange,
          "label": "外层 MediaQuery.of(context)"
        }))),
        (this.__k5 || (this.__k5 = new SizedBox({
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
            "child": (this.__k7 || (this.__k7 = new _MediaQueryDump({
              "accent": Colors.teal,
              "label": "removePadding 四边移除"
            })))
          })
        }),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 8
        }))),
        new Container({
          "color": Colors.grey.shade300,
          "child": MediaQuery.removePadding({
            "context": context,
            "removeTop": true,
            "child": (this.__k8 || (this.__k8 = new _MediaQueryDump({
              "accent": Colors.indigo,
              "label": "removePadding 仅移除 top"
            })))
          })
        }),
        (this.__k9 || (this.__k9 = new SizedBox({
          "height": 12
        }))),
        (this.__k10 || (this.__k10 = new Text({
          "data": "MediaQuery(data: ...)：覆盖子树读到的数据",
          "style": new TextStyle({
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 4
        }))),
        (this.__k11 || (this.__k11 = new Text({
          "data": "下面这段文字被 MediaQuery 覆盖了 textScaler（1.6x），其余字段沿用外层；下方 dump 里可看到 textScaler 变化。",
          "style": new TextStyle({
            "fontSize": 12,
            "color": Colors.black54
          })
        }))),
        (this.__k5 || (this.__k5 = new SizedBox({
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
        }),
        (this.__k12 || (this.__k12 = new SizedBox({
          "height": 14
        }))),
        (this.__k13 || (this.__k13 = new Text({
          "data": "aspect 粒度：无关字段变化不重建",
          "style": new TextStyle({
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 4
        }))),
        (this.__k14 || (this.__k14 = new Text({
          "data": "切换 textScaler 时，只读 size 的探针 build 次数不应增加，只读 textScaler 的探针应 +1；原生与 JS 两侧计数应一致。",
          "style": new TextStyle({
            "fontSize": 12,
            "color": Colors.black54
          })
        }))),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 8
        }))),
        new OutlinedButton({
          "onPressed": () => { this.setState(() => {
              this._scaled = (!this._scaled);
            }); },
          "child": new Text({
            "data": "切换 textScaler（当前 " + (this._scaled ? "1.60" : "1.00") + "）"
          })
        }),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 8
        }))),
        new MediaQuery({
          "data": mq.copyWith({ "textScaler": TextScaler.linear({textScaleFactor: (this._scaled ? 1.6 : 1.0)}) }),
          "child": (this.__k15 || (this.__k15 = new Column({
            "children": [
              new _SizeProbe({}),
              new _TextScalerProbe({})
            ],
            "crossAxisAlignment": CrossAxisAlignment.start
          })))
        })
      ]
    });
  }
}

// 组件 _TextScalerProbe
export class _TextScalerProbe extends StatefulWidget {
  constructor(args) {
    super(args);
    this._builds = 0;
  }
  build(context) {
    this._builds += 1;
    const scale = MediaQuery.textScalerOf(context).scale(1).toStringAsFixed(2);
    return new Padding({
      "padding": (this.__k0 || (this.__k0 = EdgeInsets.only({
        "top": 2
      }))),
      "child": new Text({
        "style": (this.__k1 || (this.__k1 = new TextStyle({
          "fontSize": 12
        }))),
        "data": "只读 textScaler   值=" + scale + "   build=" + this._builds
      })
    });
  }
}

// 组件 _SizeProbe
export class _SizeProbe extends StatefulWidget {
  constructor(args) {
    super(args);
    this._builds = 0;
  }
  build(context) {
    this._builds += 1;
    const size = MediaQuery.sizeOf(context);
    return new Padding({
      "padding": (this.__k0 || (this.__k0 = EdgeInsets.only({
        "top": 2
      }))),
      "child": new Text({
        "style": (this.__k1 || (this.__k1 = new TextStyle({
          "fontSize": 12
        }))),
        "data": "只读 size   值=" + size.width.toStringAsFixed(0) + " × " + size.height.toStringAsFixed(0) + "   build=" + this._builds
      })
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

