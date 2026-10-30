// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/key_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { KeyTile } from 'key_tile.js';
import { AppBar, BorderRadius, BoxDecoration, Colors, Column, Container, CrossAxisAlignment, EdgeInsets, FontWeight, GlobalKey, ListTile, ListView, ObjectKey, Padding, PageStorageKey, Row, Scaffold, SizedBox, Text, TextButton, TextStyle, UniqueKey, ValueKey } from '../flutter.js';

// 组件 KeyDetail
export class KeyDetail {
  constructor(args) {
    this.props = args || {};
    this._names = ["A", "B", "C", "D"];
    this._stableObj = [1];
    this._rebuildSeq = 0;
    this._uniqueSeq = 0;
    this._storeA = true;
    this._targetKey = new GlobalKey();
    this._measureText = "未测量";
  }
  _rotateNames() {
    this.setState(() => { var head = this._names[0]; this._names.removeAt(0); this._names.add(head); });
  }
  _resetNames() {
    this.setState(() => { this._names.clear(); this._names.add("A"); this._names.add("B"); this._names.add("C"); this._names.add("D"); });
  }
  _valueKeyRows() {
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "① 带 key：key: ValueKey(name)",
          "style": new TextStyle({
            "fontSize": 13,
            "fontWeight": FontWeight.bold
          })
        }))),
        ...(() => { var out = []; for (let i = 0; (i < this._names.length); (i++)) { out.push.apply(out, [new KeyTile({
                "index": i,
                "label": this._names[i] + "（key）",
                "key": new ValueKey({value: this._names[i]})
              })]); } return out; })(),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 10
        }))),
        (this.__k2 || (this.__k2 = new Text({
          "data": "② 不带 key：按位置匹配",
          "style": new TextStyle({
            "fontSize": 13,
            "fontWeight": FontWeight.bold
          })
        }))),
        ...(() => { var out = []; for (let i = 0; (i < this._names.length); (i++)) { out.push.apply(out, [new KeyTile({
                "index": i,
                "label": this._names[i] + "（无 key）"
              })]); } return out; })()
      ]
    });
  }
  _rebuildParent() {
    this.setState(() => { this._rebuildSeq += 1; });
  }
  _objectKeyRows() {
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        new KeyTile({
          "index": 0,
          "label": "A · ObjectKey(字段实例) · 父级已重建 " + this._rebuildSeq + " 次",
          "key": new ObjectKey({value: this._stableObj})
        }),
        new KeyTile({
          "index": 1,
          "label": "B · ObjectKey(每帧新造 [1]) · 父级已重建 " + this._rebuildSeq + " 次",
          "key": new ObjectKey({value: [1]})
        })
      ]
    });
  }
  _bumpUnique() {
    this.setState(() => { this._uniqueSeq += 1; });
  }
  _flipStore() {
    this.setState(() => { this._storeA = (!this._storeA); });
  }
  _storageView() {
    if (this._storeA) {
      return new SizedBox({
        "height": 150,
        "child": new ListView({
          "children": [
            ...(() => { var out = []; for (let i = 0; (i < 12); (i++)) { out.push.apply(out, [new ListTile({
                    "dense": true,
                    "title": new Text({
                      "data": "A 行 " + i
                    })
                  })]); } return out; })()
          ],
          "key": new PageStorageKey({value: "key-page-a"})
        })
      });
    }
    return new SizedBox({
      "height": 150,
      "child": new ListView({
        "children": [
          ...(() => { var out = []; for (let i = 0; (i < 12); (i++)) { out.push.apply(out, [new ListTile({
                  "dense": true,
                  "title": new Text({
                    "data": "B 行 " + i
                  })
                })]); } return out; })()
        ],
        "key": new PageStorageKey({value: "key-page-b"})
      })
    });
  }
  async _measureTarget() {
    var ctx = this._targetKey.currentContext;
    if ((ctx == null)) {
      return;
    }
    var box = ctx.findRenderObject();
    if ((box == null)) {
      return;
    }
    var rect = await box.measure();
    if ((rect == null)) {
      this.setState(() => { this._measureText = "量不到（未布局）"; });
      return;
    }
    this.setState(() => { this._measureText = "x=" + rect.dx.toStringAsFixed(1) + " y=" + rect.dy.toStringAsFixed(1) + " · " + rect.width.toStringAsFixed(0) + " × " + rect.height.toStringAsFixed(0); });
  }
  _scrollToTarget() {
    var ctx = this._targetKey.currentContext;
    if ((ctx == null)) {
      return;
    }
    var target = ctx.findRenderObject();
    if ((target == null)) {
      return;
    }
    target.showOnScreen();
  }
  _cardValueKey() {
    return new Container({
      "margin": (this.__k3 || (this.__k3 = EdgeInsets.fromLTRB({
        "bottom": 6,
        "left": 12,
        "right": 12,
        "top": 6
      }))),
      "padding": (this.__k4 || (this.__k4 = EdgeInsets.all({
        "value": 12
      }))),
      "decoration": new BoxDecoration({
        "color": Colors.grey.shade100,
        "borderRadius": BorderRadius.circular({
          "radius": 10
        })
      }),
      "child": new Column({
        "crossAxisAlignment": CrossAxisAlignment.stretch,
        "children": [
          (this.__k5 || (this.__k5 = new Text({
            "data": "ValueKey · 列表按值匹配",
            "style": new TextStyle({
              "fontSize": 15,
              "fontWeight": FontWeight.bold,
              "color": Colors.deepPurple
            })
          }))),
          (this.__k6 || (this.__k6 = new SizedBox({
            "height": 4
          }))),
          (this.__k7 || (this.__k7 = new Text({
            "data": "换序后看两列计数：① 的状态跟着「行（值）」走，② 的状态留在「位置」上——" + "reconciler 取 keySig（v:值）做「带 key 优先、无 key 按位置」的匹配。",
            "style": new TextStyle({
              "fontSize": 12,
              "color": Colors.grey
            })
          }))),
          (this.__k8 || (this.__k8 = new SizedBox({
            "height": 8
          }))),
          this._valueKeyRows(),
          (this.__k8 || (this.__k8 = new SizedBox({
            "height": 8
          }))),
          new Row({
            "children": [
              new TextButton({
                "onPressed": this.__bindFn(0, [], (...__a) => this._rotateNames(...__a)),
                "child": (this.__k9 || (this.__k9 = new Text({
                  "data": "轮换顺序（A→末尾）"
                })))
              }),
              (this.__k10 || (this.__k10 = new SizedBox({
                "width": 8
              }))),
              new TextButton({
                "onPressed": this.__bindFn(1, [], (...__a) => this._resetNames(...__a)),
                "child": (this.__k11 || (this.__k11 = new Text({
                  "data": "重置"
                })))
              })
            ]
          })
        ]
      })
    });
  }
  _cardObjectKey() {
    return new Container({
      "margin": (this.__k3 || (this.__k3 = EdgeInsets.fromLTRB({
        "bottom": 6,
        "left": 12,
        "right": 12,
        "top": 6
      }))),
      "padding": (this.__k4 || (this.__k4 = EdgeInsets.all({
        "value": 12
      }))),
      "decoration": new BoxDecoration({
        "color": Colors.grey.shade100,
        "borderRadius": BorderRadius.circular({
          "radius": 10
        })
      }),
      "child": new Column({
        "crossAxisAlignment": CrossAxisAlignment.stretch,
        "children": [
          (this.__k12 || (this.__k12 = new Text({
            "data": "ObjectKey · 按对象身份相等",
            "style": new TextStyle({
              "fontSize": 15,
              "fontWeight": FontWeight.bold,
              "color": Colors.deepPurple
            })
          }))),
          (this.__k6 || (this.__k6 = new SizedBox({
            "height": 4
          }))),
          (this.__k13 || (this.__k13 = new Text({
            "data": "ObjectKey 的判据是 identical（是不是**同一个对象实例**），不是值相等。" + "A 行包的是字段里那个实例（跨帧恒定）→ 父级重建后元素复用、计数保留；" + "B 行每次 build 都新造一个 [1]（值一样但身份不同）→ 元素不匹配、销毁重建、计数归零。" + "注意：B 的计数是**被销毁**而不是被藏起来——归零之后回不来。",
            "style": new TextStyle({
              "fontSize": 12,
              "color": Colors.grey
            })
          }))),
          (this.__k8 || (this.__k8 = new SizedBox({
            "height": 8
          }))),
          this._objectKeyRows(),
          (this.__k8 || (this.__k8 = new SizedBox({
            "height": 8
          }))),
          (this.__k14 || (this.__k14 = new Text({
            "data": "操作：先给 A、B 各点几次 +1，再点下面的「父级重建」，对比两行的计数。" + "选型场景：数据源没有稳定 ID、但你跨帧持有同一批对象实例时用它。",
            "style": new TextStyle({
              "fontSize": 12,
              "color": Colors.grey
            })
          }))),
          (this.__k15 || (this.__k15 = new SizedBox({
            "height": 6
          }))),
          (this.__k16 || (this.__k16 = new Text({
            "data": "补充：Dart 里 ValueKey 按 == 比较、ObjectKey 按 identical 比较。" + "本例的 [1] 是 List，没有重写 ==（Dart 的 == 对 List 本就是身份比较），" + "所以这里两者结果相同——本案例要看的是「key 的身份稳不稳定」这件事本身。",
            "style": new TextStyle({
              "fontSize": 11,
              "color": Colors.grey
            })
          }))),
          (this.__k8 || (this.__k8 = new SizedBox({
            "height": 8
          }))),
          new Row({
            "children": [
              new TextButton({
                "onPressed": this.__bindFn(2, [], (...__a) => this._rebuildParent(...__a)),
                "child": (this.__k17 || (this.__k17 = new Text({
                  "data": "父级重建（setState 一次）"
                })))
              })
            ]
          })
        ]
      })
    });
  }
  _cardUniqueKey() {
    return new Container({
      "margin": (this.__k3 || (this.__k3 = EdgeInsets.fromLTRB({
        "bottom": 6,
        "left": 12,
        "right": 12,
        "top": 6
      }))),
      "padding": (this.__k4 || (this.__k4 = EdgeInsets.all({
        "value": 12
      }))),
      "decoration": new BoxDecoration({
        "color": Colors.grey.shade100,
        "borderRadius": BorderRadius.circular({
          "radius": 10
        })
      }),
      "child": new Column({
        "crossAxisAlignment": CrossAxisAlignment.stretch,
        "children": [
          (this.__k18 || (this.__k18 = new Text({
            "data": "UniqueKey · 每次都是新身份",
            "style": new TextStyle({
              "fontSize": 15,
              "fontWeight": FontWeight.bold,
              "color": Colors.deepPurple
            })
          }))),
          (this.__k6 || (this.__k6 = new SizedBox({
            "height": 4
          }))),
          (this.__k19 || (this.__k19 = new Text({
            "data": "点「重建」触发 setState：子树的 UniqueKey 每次都是新实例（身份新 → 元素不匹配），" + "整棵子树重建、内部计数归零。",
            "style": new TextStyle({
              "fontSize": 12,
              "color": Colors.grey
            })
          }))),
          (this.__k8 || (this.__k8 = new SizedBox({
            "height": 8
          }))),
          new KeyTile({
            "index": 0,
            "label": "唯一身份行 #" + this._uniqueSeq,
            "key": new UniqueKey()
          }),
          (this.__k8 || (this.__k8 = new SizedBox({
            "height": 8
          }))),
          new Row({
            "children": [
              new TextButton({
                "onPressed": this.__bindFn(3, [], (...__a) => this._bumpUnique(...__a)),
                "child": (this.__k20 || (this.__k20 = new Text({
                  "data": "重建（setState 一次）"
                })))
              })
            ]
          })
        ]
      })
    });
  }
  _cardStorageKey() {
    return new Container({
      "margin": (this.__k3 || (this.__k3 = EdgeInsets.fromLTRB({
        "bottom": 6,
        "left": 12,
        "right": 12,
        "top": 6
      }))),
      "padding": (this.__k4 || (this.__k4 = EdgeInsets.all({
        "value": 12
      }))),
      "decoration": new BoxDecoration({
        "color": Colors.grey.shade100,
        "borderRadius": BorderRadius.circular({
          "radius": 10
        })
      }),
      "child": new Column({
        "crossAxisAlignment": CrossAxisAlignment.stretch,
        "children": [
          (this.__k21 || (this.__k21 = new Text({
            "data": "PageStorageKey · 滚动位置持久化",
            "style": new TextStyle({
              "fontSize": 15,
              "fontWeight": FontWeight.bold,
              "color": Colors.deepPurple
            })
          }))),
          (this.__k6 || (this.__k6 = new SizedBox({
            "height": 4
          }))),
          (this.__k22 || (this.__k22 = new Text({
            "data": "把 A 列表滚到中间 → 切到 B → 切回 A：位置应回到原处。" + "值本体走值 codec（__psk），宿主造真实 PageStorageKey，位置由宿主端 PageStorage 存取。",
            "style": new TextStyle({
              "fontSize": 12,
              "color": Colors.grey
            })
          }))),
          (this.__k8 || (this.__k8 = new SizedBox({
            "height": 8
          }))),
          this._storageView(),
          (this.__k8 || (this.__k8 = new SizedBox({
            "height": 8
          }))),
          new Row({
            "children": [
              new TextButton({
                "onPressed": this.__bindFn(4, [], (...__a) => this._flipStore(...__a)),
                "child": new Text({
                  "data": this._storeA ? "切到 B 列表" : "切回 A 列表"
                })
              })
            ]
          })
        ]
      })
    });
  }
  _cardGlobalKey() {
    return new Container({
      "margin": (this.__k3 || (this.__k3 = EdgeInsets.fromLTRB({
        "bottom": 6,
        "left": 12,
        "right": 12,
        "top": 6
      }))),
      "padding": (this.__k4 || (this.__k4 = EdgeInsets.all({
        "value": 12
      }))),
      "decoration": new BoxDecoration({
        "color": Colors.grey.shade100,
        "borderRadius": BorderRadius.circular({
          "radius": 10
        })
      }),
      "child": new Column({
        "crossAxisAlignment": CrossAxisAlignment.stretch,
        "children": [
          (this.__k23 || (this.__k23 = new Text({
            "data": "GlobalKey · 宿主端量测 / 定位",
            "style": new TextStyle({
              "fontSize": 15,
              "fontWeight": FontWeight.bold,
              "color": Colors.deepPurple
            })
          }))),
          (this.__k6 || (this.__k6 = new SizedBox({
            "height": 4
          }))),
          (this.__k24 || (this.__k24 = new Text({
            "data": "currentContext → findRenderObject 这条链两端同形，但「值」只能在宿主算：" + "位置与尺寸经异步桥回填（box.measure()），定位用真实 RenderObject 的 showOnScreen。",
            "style": new TextStyle({
              "fontSize": 12,
              "color": Colors.grey
            })
          }))),
          (this.__k8 || (this.__k8 = new SizedBox({
            "height": 8
          }))),
          new Container({
            "padding": (this.__k25 || (this.__k25 = EdgeInsets.all({
              "value": 10
            }))),
            "decoration": new BoxDecoration({
              "color": Colors.teal.shade50,
              "borderRadius": BorderRadius.circular({
                "radius": 6
              })
            }),
            "child": (this.__k26 || (this.__k26 = new Text({
              "data": "目标盒子（GlobalKey 挂在这里）",
              "style": new TextStyle({
                "fontSize": 13
              })
            }))),
            "key": this._targetKey
          }),
          (this.__k8 || (this.__k8 = new SizedBox({
            "height": 8
          }))),
          new Text({
            "style": (this.__k27 || (this.__k27 = new TextStyle({
              "color": Colors.teal,
              "fontSize": 13
            }))),
            "data": "测量：" + this._measureText
          }),
          (this.__k6 || (this.__k6 = new SizedBox({
            "height": 4
          }))),
          new Row({
            "children": [
              new TextButton({
                "onPressed": this.__bindFn(5, [], (...__a) => this._measureTarget(...__a)),
                "child": (this.__k28 || (this.__k28 = new Text({
                  "data": "测量位置与尺寸"
                })))
              }),
              (this.__k10 || (this.__k10 = new SizedBox({
                "width": 8
              }))),
              new TextButton({
                "onPressed": this.__bindFn(6, [], (...__a) => this._scrollToTarget(...__a)),
                "child": (this.__k29 || (this.__k29 = new Text({
                  "data": "定位（showOnScreen）"
                })))
              })
            ]
          })
        ]
      })
    });
  }
  build(context) {
    return new Scaffold({
      "backgroundColor": Colors.grey.shade50,
      "appBar": new AppBar({
        "title": (this.__k30 || (this.__k30 = new Text({
          "data": "Key 家族 · 全部用例"
        }))),
        "backgroundColor": Colors.deepPurple,
        "foregroundColor": Colors.white
      }),
      "body": new ListView({
        "children": [
          (this.__k31 || (this.__k31 = new Padding({
            "child": new Text({
              "style": new TextStyle({
                "fontSize": 12,
                "color": Colors.grey
              }),
              "data": "每一张卡片一种 key 的语义；「计数」是 KeyTile 的内部 State，" + "用它来观察状态是跟着行走还是跟着位置走。"
            }),
            "padding": EdgeInsets.fromLTRB({
              "left": 12,
              "top": 12,
              "right": 12,
              "bottom": 0
            })
          }))),
          this._cardValueKey(),
          this._cardObjectKey(),
          this._cardUniqueKey(),
          this._cardStorageKey(),
          this._cardGlobalKey(),
          (this.__k32 || (this.__k32 = new SizedBox({
            "height": 24
          })))
        ]
      })
    });
  }
}

