// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/phone_label.dart 自动生成
// 重新生成：dart run build_runner build

import { PhoneText } from 'phone_text.js';
import { Colors, Icon, Icons, MainAxisSize, Row, SizedBox, StatelessWidget } from '../flutter.js';

// 组件 PhoneLabel
export class PhoneLabel extends StatelessWidget {
  constructor(args) {
    super(args);
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.text = (args && args.text !== undefined) ? args.text : '';
    this.color = (args && args.color !== undefined) ? args.color : Colors.deepPurple;
  }
  build(context) {
    return new Row({
      "mainAxisSize": MainAxisSize.min,
      "children": [
        (this.__k0 || (this.__k0 = new Icon({
          "icon": Icons.phone_iphone,
          "size": 14
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "width": 4
        }))),
        new PhoneText({
          "text": this.text,
          "color": this.color
        })
      ]
    });
  }
}

