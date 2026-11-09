// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/grammar/map_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Colors, Column, CrossAxisAlignment, FontWeight, SizedBox, StatefulWidget, Text, TextStyle } from '../flutter.js';

// 组件 MapDetail
export class MapDetail extends StatefulWidget {
  constructor(args) {
    super(args);
  }
  build(context) {
    const scores = new Map([["语文", 88], ["数学", 96], ["英语", 79]]);
    const count = scores.length;
    const keys = scores._keys.toList();
    const values = scores._values.toList();
    const entries = scores._entries.toList();
    const entryText = entries.map((e) => { return e.key + "=" + e.value; }).join("，");
    const visited = [];
    scores.forEach(((__v, __k) => ((k, v) => { return visited.add(k + "=" + v); })(__k, __v)));
    const hasMath = scores.containsKey("数学");
    const hasHundred = scores.containsValue(100);
    const removed = new Map(scores);
    const removedEnglish = removed.remove("英语");
    const removedChem = removed.remove("化学");
    const cached = new Map(scores);
    const cachedMath = cached.putIfAbsent("数学", () => { return 0; });
    const cachedArt = cached.putIfAbsent("美术", () => { return 60; });
    const updated = new Map(scores);
    const mathPlus = updated.update("数学", (v) => { return (v + 2); });
    const artAdded = updated.update("美术", (v) => { return v; }, { "ifAbsent": () => { return 70; } });
    const merged = new Map(scores);
    merged.addAll(new Map([["物理", 66], ["化学", 54]]));
    merged.removeWhere((k, v) => { return (v < 80); });
    const cleared = new Map(scores);
    const sizeBefore = cleared.length;
    cleared.clear();
    const emptyAfter = cleared.isEmpty;
    const nonEmptyBefore = scores.isNotEmpty;
    const math = __nn(__idx(scores, "数学"));
    const missing = (__idx(scores, "化学") ?? (-1));
    __idxSet(scores, "物理", 66);
    const copied = new Map(scores);
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "Map · 映射语义",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        (this.__k2 || (this.__k2 = new Text({
          "data": "Map 字面量是原生 JS Map（new Map([[...]])）：成员由运行时在 Map.prototype " + "补齐，keys / values / entries 改名为 _keys / _values / _entries；下标读写按" + "接收者类型改写，只对可判定为 Map 的接收者生效。",
          "style": new TextStyle({
            "fontSize": 13,
            "color": Colors.black54
          })
        }))),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 12
        }))),
        new Text({
          "data": "length → " + count
        }),
        new Text({
          "data": "keys → " + keys.join("/")
        }),
        new Text({
          "data": "values → " + values.join("/")
        }),
        new Text({
          "data": "entries → " + entryText
        }),
        new Text({
          "data": "forEach → " + visited._join("/")
        }),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new Text({
          "data": "containsKey(数学) → " + hasMath + " / containsValue(100) → " + hasHundred
        }),
        new Text({
          "data": "remove(英语) → " + (removedEnglish ?? "null") + "，" + "remove(化学) → " + (removedChem ?? "null")
        }),
        new Text({
          "data": "putIfAbsent → 数学=" + cachedMath + " / 美术=" + cachedArt
        }),
        new Text({
          "data": "update → 数学=" + mathPlus + " / 美术(ifAbsent)=" + artAdded
        }),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new Text({
          "data": "addAll + removeWhere(< 80) → " + merged._keys.join("/")
        }),
        new Text({
          "data": "clear → " + sizeBefore + " → " + emptyAfter + "（isEmpty）" + " / 原 Map isNotEmpty=" + nonEmptyBefore
        }),
        new Text({
          "data": "scores[数学]=" + (math ?? "null") + " / scores[化学]??-1=" + missing
        }),
        new Text({
          "data": "copied（Map.from）→ " + copied._keys.join("/")
        })
      ]
    });
  }
}

