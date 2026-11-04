// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/app/widgets/load_error_view.dart 自动生成
// 重新生成：dart run build_runner build

import { Center, Color, Column, EdgeInsets, FontWeight, Icon, Icons, MainAxisSize, Padding, SizedBox, StatelessWidget, Text, TextAlign, TextButton, TextOverflow, TextStyle } from '../../flutter.js';

// 组件 LoadErrorView
export class LoadErrorView extends StatelessWidget {
  constructor(args) {
    super(args);
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.message = (args && args.message !== undefined) ? args.message : '';
    this.onRetry = (args && args.onRetry !== undefined) ? args.onRetry : null;
  }
  build(context) {
    return new Center({
      "child": new Padding({
        "padding": (this.__k0 || (this.__k0 = EdgeInsets.symmetric({
          "horizontal": 32
        }))),
        "child": new Column({
          "mainAxisSize": MainAxisSize.min,
          "children": [
            (this.__k1 || (this.__k1 = new Icon({
              "color": new Color({
                "value": 0xFF9AA0AC
              }),
              "icon": Icons.cloud_off_outlined,
              "size": 40
            }))),
            (this.__k2 || (this.__k2 = new SizedBox({
              "height": 10
            }))),
            (this.__k3 || (this.__k3 = new Text({
              "data": "加载失败",
              "style": new TextStyle({
                "fontSize": 14,
                "fontWeight": FontWeight.w600,
                "color": new Color({
                  "value": 0xFF4D5462
                })
              })
            }))),
            (this.__k4 || (this.__k4 = new SizedBox({
              "height": 6
            }))),
            new Text({
              "maxLines": 4,
              "overflow": TextOverflow.ellipsis,
              "textAlign": TextAlign.center,
              "style": (this.__k5 || (this.__k5 = new TextStyle({
                "color": new Color({
                  "value": 0xFF8A909E
                }),
                "fontSize": 12,
                "height": 1.4
              }))),
              "data": this.message
            }),
            (this.__k6 || (this.__k6 = new SizedBox({
              "height": 8
            }))),
            new TextButton({
              "onPressed": this.onRetry,
              "child": (this.__k7 || (this.__k7 = new Text({
                "data": "重试"
              })))
            })
          ]
        })
      })
    });
  }
}

