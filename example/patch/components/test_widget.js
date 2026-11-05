// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/test_widget.dart 自动生成
// 重新生成：dart run build_runner build

import { StatelessCard } from 'stateless_card.js';
import { Center, Column, MainAxisSize, SizedBox, StatelessWidget, Text } from '../flutter.js';

// 组件 TestWidget
export class TestWidget extends StatelessWidget {
  constructor(args) {
    super(args);
  }
  build(context) {
    let text = (this.__k0 || (this.__k0 = new Text({
      "data": "局部变量 widget"
    })));
    let card = (this.__k1 || (this.__k1 = new StatelessCard({
      "badge": "VAR",
      "subtitle": "StatelessCard 变量",
      "title": "局部自定义组件"
    })));
    const items = [(this.__k2 || (this.__k2 = new Text({
        "data": "列表项 A"
      }))), (this.__k3 || (this.__k3 = new Text({
        "data": "列表项 B"
      })))];
    return new Center({
      "child": new Column({
        "mainAxisSize": MainAxisSize.min,
        "children": [
          text,
          (this.__k4 || (this.__k4 = new SizedBox({
            "height": 8
          }))),
          card,
          (this.__k4 || (this.__k4 = new SizedBox({
            "height": 8
          }))),
          ...items
        ]
      })
    });
  }
}

