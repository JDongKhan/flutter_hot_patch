// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/grammar/array_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Colors, Column, CrossAxisAlignment, FontWeight, SizedBox, StatefulWidget, Text, TextStyle } from '../flutter.js';

// 模型 Bucket
export class Bucket {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.nums = (args && args.nums !== undefined) ? args.nums : [];
  }
}

// 模型 Coord
export class Coord {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.x = (args && args.x !== undefined) ? args.x : 0;
    this.y = (args && args.y !== undefined) ? args.y : 0;
  }
  __op$eq(other) {
    return (((other instanceof Coord) && (other.x === this.x)) && (other.y === this.y));
  }
  get hashCode() {
    return ((this.x * 31) + this.y);
  }
}

// 组件 ArrayDetail
export class ArrayDetail extends StatefulWidget {
  constructor(args) {
    super(args);
  }
  build(context) {
    const nums = [10, 9, 1];
    const sortedDefault = (() => { const _t = [...nums]; _t._sort(); return _t; })();
    const sortedDesc = (() => { const _t = [...nums]; _t._sort((a, b) => { return (b - a); }); return _t; })();
    const letters = ["a", "b", "c"];
    const joinedDefault = letters._join();
    const joinedDash = letters._join("-");
    const coords = [(this.__k0 || (this.__k0 = new Coord({
        "x": 1,
        "y": 2
      }))), (this.__k1 || (this.__k1 = new Coord({
        "x": 3,
        "y": 4
      }))), (this.__k0 || (this.__k0 = new Coord({
        "x": 1,
        "y": 2
      })))];
    const idxEqual = coords._indexOf((this.__k0 || (this.__k0 = new Coord({
      "x": 1,
      "y": 2
    }))));
    const idxFrom = coords._indexOf((this.__k0 || (this.__k0 = new Coord({
      "x": 1,
      "y": 2
    }))), 2);
    const idxMiss = coords._indexOf((this.__k2 || (this.__k2 = new Coord({
      "x": 5,
      "y": 6
    }))));
    const bag = [1, 2, 2, 3];
    const hasTwo = bag.contains(2);
    const removed = (() => { const _t = [...bag]; _t.remove(2); return _t; })();
    const filtered = (() => { const _t = [...bag]; _t.removeWhere((v) => { return v.isEven; }); return _t; })();
    const inserted = (() => { const _t = [...bag]; _t.insert(1, 9); return _t; })();
    const appended = (() => { const _t = [...bag]; _t.addAll([7, 8]); return _t; })();
    const removedAt = (() => { const _t = [...bag]; _t.removeAt(0); return _t; })();
    const total = bag.fold(0, (sum, v) => { return (sum + v); });
    const hasLarge = bag.any((v) => { return (v > 2); });
    const allPositive = bag.every((v) => { return (v > 0); });
    const doubled = bag.expand((v) => { return [v, v]; }).toList();
    const firstTwo = bag.take(2);
    const skipped = bag.skip(1);
    const found = bag.firstWhere((v) => { return (v > 5); }, { "orElse": () => { return (-1); } });
    const atOne = bag.elementAt(1);
    const sub = bag.sublist(1, 3);
    const filled = (() => { const _t = [0, 0, 0]; _t.fillRange(0, 2, 7); return _t; })();
    const map = bag.asMap();
    const growable = [1, 2];
    growable._setLength(4);
    const growableText = growable._join("-");
    const bucket = new Bucket({
      "nums": [
        3,
        1,
        2
      ]
    });
    bucket.nums._sort();
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        (this.__k3 || (this.__k3 = new Text({
          "data": "数组 · List 语义",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k4 || (this.__k4 = new SizedBox({
          "height": 8
        }))),
        (this.__k5 || (this.__k5 = new Text({
          "data": "JS 侧同名成员由运行时补齐；同名但语义不一致的走构建期映射表" + "（sort → _sort、join → _join、indexOf → _indexOf、length 写 → _setLength），" + "只对可判定为 List 的接收者生效。",
          "style": new TextStyle({
            "fontSize": 13,
            "color": Colors.black54
          })
        }))),
        (this.__k6 || (this.__k6 = new SizedBox({
          "height": 12
        }))),
        new Text({
          "data": "sort() 默认 → " + sortedDefault._join("-")
        }),
        new Text({
          "data": "sort((a, b) => b - a) → " + sortedDesc._join("-")
        }),
        new Text({
          "data": "join() 默认 → \"" + joinedDefault + "\""
        }),
        new Text({
          "data": "join(\"-\") → \"" + joinedDash + "\""
        }),
        (this.__k4 || (this.__k4 = new SizedBox({
          "height": 8
        }))),
        new Text({
          "data": "indexOf(Coord(1, 2)) → " + idxEqual
        }),
        new Text({
          "data": "indexOf(Coord(1, 2), start: 2) → " + idxFrom
        }),
        new Text({
          "data": "indexOf(Coord(5, 6)) → " + idxMiss
        }),
        new Text({
          "data": "contains(2) → " + hasTwo
        }),
        (this.__k4 || (this.__k4 = new SizedBox({
          "height": 8
        }))),
        new Text({
          "data": "remove(2) → " + removed._join("-")
        }),
        new Text({
          "data": "removeWhere(偶数) → " + filtered._join("-")
        }),
        new Text({
          "data": "insert(1, 9) → " + inserted._join("-")
        }),
        new Text({
          "data": "addAll([7, 8]) → " + appended._join("-")
        }),
        new Text({
          "data": "removeAt(0) → " + removedAt._join("-")
        }),
        (this.__k4 || (this.__k4 = new SizedBox({
          "height": 8
        }))),
        new Text({
          "data": "fold(0, +) → " + total
        }),
        new Text({
          "data": "any(> 2) → " + hasLarge + " / every(> 0) → " + allPositive
        }),
        new Text({
          "data": "expand((v) => [v, v]) → " + doubled.join("-")
        }),
        new Text({
          "data": "take(2) → " + firstTwo.join("-") + " / skip(1) → " + skipped.join("-")
        }),
        new Text({
          "data": "firstWhere(> 5, orElse: -1) → " + found
        }),
        (this.__k4 || (this.__k4 = new SizedBox({
          "height": 8
        }))),
        new Text({
          "data": "elementAt(1) → " + atOne
        }),
        new Text({
          "data": "sublist(1, 3) → " + sub.join("-")
        }),
        new Text({
          "data": "fillRange(0, 2, 7) → " + filled._join("-")
        }),
        new Text({
          "data": "asMap()[1] → " + map[1]
        }),
        new Text({
          "data": "length = 4 → " + growableText
        }),
        new Text({
          "data": "bucket.nums.sort() → " + bucket.nums.join("-")
        })
      ]
    });
  }
}

