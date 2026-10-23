// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/list_item.dart 自动生成
// 重新生成：dart run build_runner build

import { Text } from '../flutter.js';

// 组件 CommonListItem
export class CommonListItem {
  constructor(args) {
    this.props = args || {};
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.index = (args && args.index !== undefined) ? args.index : 0;
  }
  initState() {
    console.log("listItem initState - " + __str(this.index));
  }
  didUpdateWidget(oldWidget) {
    console.log("listItem didUpdateWidget- " + __str(this.index));
  }
  build(context) {
    return new Text({
        "data": "builder item " + this.index
      });
  }
}

