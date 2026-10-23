// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/list_item.dart 自动生成
// 重新生成：dart run build_runner build

import { Text } from '../flutter.js';

const _listItemPalette = ['#607D8B', '#009688', '#3F51B5', '#FF5722', '#9C27B0', '#795548'];

// 组件 CommonListItem
export class CommonListItem {
  constructor(args) {
    this.props = args || {};
    this.__applyProps(args);
    this._updateCount = 0;
  }
  __applyProps(args) {
    this.index = (args && args.index !== undefined) ? args.index : 0;
    this.salt = (args && args.salt !== undefined) ? args.salt : 0;
  }
  initState() {
    console.log("listItem initState - " + __str(this.index));
  }
  didUpdateWidget(oldWidget) {
    this._updateCount += 1;
    console.log("listItem didUpdateWidget- " + __str(this.index) + " -" + __str(this._updateCount));
  }
  build(context) {
    return new Text({
        "style": {
          "color": _listItemPalette[(((this.index + this.salt)) % _listItemPalette.length)],
          "fontWeight": "w600"
        },
        "data": "builder item " + this.index + " · u" + this._updateCount
      });
  }
}

