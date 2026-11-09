// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/grammar/part_library.dart 自动生成
// 重新生成：dart run build_runner build

import { Column, CrossAxisAlignment, FontWeight, SizedBox, StatelessWidget, Text, TextStyle } from '../flutter.js';

export const partTag = "part-tag";
const _privateValue = "private-part";
export const partSummary = (model) => { return partTag + ":" + model.value + "/" + _privateValue; };
const _privatePartLabel = () => { return "private-fn(partTag=" + partTag + ")"; };

// 模型 PartModel
export class PartModel {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.value = (args && args.value !== undefined) ? args.value : 0;
  }
}

// 组件 PartLibrary
export class PartLibrary extends StatelessWidget {
  constructor(args) {
    super(args);
  }
  build(context) {
    const model = new PartModel({
      "value": 3
    });
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "part / part of：同库共享命名空间与一份产物",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new Text({
          "data": partSummary(model)
        }),
        new Text({
          "data": "跨 part 私有函数：" + _privatePartLabel()
        })
      ]
    });
  }
}

