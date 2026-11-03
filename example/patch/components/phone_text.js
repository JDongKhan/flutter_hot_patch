// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/phone_text.dart 自动生成
// 重新生成：dart run build_runner build

import { Colors, StatelessWidget, Text, TextStyle } from '../flutter.js';

// 组件 PhoneText
export class PhoneText extends StatelessWidget {
  constructor(args) {
    super(args);
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.text = (args && args.text !== undefined) ? args.text : '';
    this.color = (args && args.color !== undefined) ? args.color : Colors.deepPurple;
  }
  build(context) {
    return new Text({
      "style": new TextStyle({
        "fontSize": 14,
        "color": this.color
      }),
      "data": this.text
    });
  }
}

