// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/list_item.dart 自动生成
// 重新生成：dart run build_runner build

import { Colors, FontWeight, StatefulWidget, Text, TextStyle } from '../flutter.js';

const _listItemPalette = [Colors.blueGrey, Colors.teal, Colors.indigo, Colors.deepOrange, Colors.purple, Colors.brown];

// 组件 CommonListItem
export class CommonListItem extends StatefulWidget {
  constructor(args) {
    super(args);
    this.__applyProps(args);
    this._updateCount = 0;
  }
  __applyProps(args) {
    this.index = (args && args.index !== undefined) ? args.index : 0;
    this.salt = (args && args.salt !== undefined) ? args.salt : 0;
  }
  initState() {
    super.initState();
    print("listItem initState - " + this.index);
  }
  didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    this._updateCount += 1;
    print("listItem didUpdateWidget- " + this.index + " -" + this._updateCount);
  }
  build(context) {
    return new Text({
      "style": new TextStyle({
        "color": _listItemPalette[__mod(((this.index + this.salt)), _listItemPalette.length)],
        "fontWeight": FontWeight.w600
      }),
      "data": "builder item " + this.index + " · u" + this._updateCount
    });
  }
}

