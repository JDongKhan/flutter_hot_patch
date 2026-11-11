// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/media_query_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { BorderRadius, BoxDecoration, Colors, Column, Container, CrossAxisAlignment, EdgeInsets, FontWeight, MediaQuery, Radius, SizedBox, StatelessWidget, Text, TextStyle, double } from '../flutter.js';

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
          "data": "MediaQuery.removePadding",
          "style": new TextStyle({
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 4
        }))),
        (this.__k2 || (this.__k2 = new Text({
          "data": "按方向移除安全区 padding，子树读到的是移除后的 MediaQueryData；本机 padding 全 0，移动端可见差异",
          "style": new TextStyle({
            "fontSize": 12,
            "color": Colors.black54
          })
        }))),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 8
        }))),
        (this.__k4 || (this.__k4 = new _PaddingReadout({
          "accent": Colors.orange,
          "label": "外层（原始 padding）"
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
            "child": (this.__k5 || (this.__k5 = new _PaddingReadout({
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
            "child": (this.__k6 || (this.__k6 = new _PaddingReadout({
              "accent": Colors.indigo,
              "label": "removePadding 仅移除 top"
            })))
          })
        })
      ]
    });
  }
}

// 组件 _PaddingReadout
export class _PaddingReadout extends StatelessWidget {
  constructor(args) {
    super(args);
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.label = (args && args.label !== undefined) ? args.label : '';
    this.accent = (args && args.accent !== undefined) ? args.accent : null;
  }
  build(context) {
    const p = MediaQuery.paddingOf(context);
    return new Container({
      "width": double.infinity,
      "padding": (this.__k0 || (this.__k0 = EdgeInsets.all({
        "value": 8
      }))),
      "decoration": new BoxDecoration({
        "color": this.accent.withValues({ "alpha": 0.12 }),
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
            "style": (this.__k2 || (this.__k2 = new TextStyle({
              "fontSize": 12
            }))),
            "data": this.label + ": L" + p.left.toStringAsFixed(0) + " T" + p.top.toStringAsFixed(0) + " " + "R" + p.right.toStringAsFixed(0) + " B" + p.bottom.toStringAsFixed(0)
          }),
          (this.__k3 || (this.__k3 = new SizedBox({
            "height": 4
          }))),
          new Container({
            "width": double.infinity,
            "height": (p.top === 0) ? 4 : p.top,
            "color": this.accent
          })
        ]
      })
    });
  }
}

