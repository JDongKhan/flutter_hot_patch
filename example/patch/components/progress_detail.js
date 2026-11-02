// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/progress_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { CircularProgressIndicator, Colors, Column, CrossAxisAlignment, FontWeight, LinearProgressIndicator, Row, SizedBox, StatefulWidget, Text, TextStyle } from '../flutter.js';

// 组件 ProgressDetail
export class ProgressDetail extends StatefulWidget {
  constructor(args) {
    super(args);
    this._progress = 0.65;
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "CircularProgressIndicator",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new Row({
          "children": [
            new CircularProgressIndicator({
              "value": this._progress,
              "color": Colors.deepPurple,
              "backgroundColor": Colors.deepPurple.shade50,
              "strokeWidth": 6
            }),
            (this.__k2 || (this.__k2 = new SizedBox({
              "width": 24
            }))),
            (this.__k3 || (this.__k3 = new CircularProgressIndicator({})))
          ]
        }),
        (this.__k4 || (this.__k4 = new SizedBox({
          "height": 16
        }))),
        (this.__k5 || (this.__k5 = new Text({
          "data": "LinearProgressIndicator",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new LinearProgressIndicator({
          "value": this._progress,
          "color": Colors.deepPurple,
          "backgroundColor": Colors.deepPurple.shade50,
          "minHeight": 8
        }),
        (this.__k6 || (this.__k6 = new SizedBox({
          "height": 4
        }))),
        (this.__k7 || (this.__k7 = new LinearProgressIndicator({}))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new Text({
          "style": (this.__k8 || (this.__k8 = new TextStyle({
            "color": Colors.grey,
            "fontSize": 14
          }))),
          "data": "进度值：" + this._progress
        })
      ]
    });
  }
}

