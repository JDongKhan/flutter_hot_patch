// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/app/floors/floor_status.dart 自动生成
// 重新生成：dart run build_runner build

import { Center, CircularProgressIndicator, Color, EdgeInsets, Flexible, MainAxisSize, Padding, Row, SizedBox, StatelessWidget, Text, TextButton, TextOverflow, TextStyle } from '../../flutter.js';

// 组件 FloorLoadingView
export class FloorLoadingView extends StatelessWidget {
  constructor(args) {
    super(args);
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.height = (args && args.height !== undefined) ? args.height : 120;
  }
  build(context) {
    return new SizedBox({
      "height": this.height,
      "child": (this.__k0 || (this.__k0 = new Center({
        "child": new CircularProgressIndicator({})
      })))
    });
  }
}

// 组件 FloorErrorView
export class FloorErrorView extends StatelessWidget {
  constructor(args) {
    super(args);
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.message = (args && args.message !== undefined) ? args.message : '';
    this.onRetry = (args && args.onRetry !== undefined) ? args.onRetry : null;
    this.height = (args && args.height !== undefined) ? args.height : 120;
  }
  build(context) {
    return new SizedBox({
      "height": this.height,
      "child": new Center({
        "child": new Padding({
          "padding": (this.__k0 || (this.__k0 = EdgeInsets.symmetric({
            "horizontal": 16
          }))),
          "child": new Row({
            "mainAxisSize": MainAxisSize.min,
            "children": [
              new Flexible({
                "child": new Text({
                  "maxLines": 2,
                  "overflow": TextOverflow.ellipsis,
                  "style": (this.__k1 || (this.__k1 = new TextStyle({
                    "color": new Color({
                      "value": 0xFF8A909E
                    }),
                    "fontSize": 12
                  }))),
                  "data": "楼层加载失败：" + this.message
                })
              }),
              new TextButton({
                "onPressed": this.onRetry,
                "child": (this.__k2 || (this.__k2 = new Text({
                  "data": "重试"
                })))
              })
            ]
          })
        })
      })
    });
  }
}

