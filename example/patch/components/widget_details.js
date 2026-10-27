// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/widget_details.dart 自动生成
// 重新生成：dart run build_runner build

import { CounterVm } from '../model/counter_vm.js';
import { CommonListItem } from 'list_item.js';
import { Align, AppBar, AspectRatio, BottomNavigationBar, BottomNavigationBarItem, CachedNetworkImage, Card, Center, Checkbox, Chip, CircleAvatar, CircularProgressIndicator, ClipRRect, Column, ConstrainedBox, Container, CustomScrollView, DecoratedBox, DefaultTabController, Divider, Drawer, DrawerHeader, DropdownButton, DropdownMenuItem, ElevatedButton, Expanded, FilledButton, FloatingActionButton, FractionallySizedBox, GridView, Icon, IconButton, Image, InputDecoration, LinearProgressIndicator, ListTile, ListView, ListenableBuilder, NotificationListener, Opacity, OutlinedButton, Padding, PageView, Positioned, Radio, ReorderableListView, Row, SafeArea, Scaffold, SingleChildScrollView, SizedBox, Slider, SliverAppBar, SliverFillRemaining, SliverFixedExtentList, SliverGrid, SliverList, SliverOpacity, SliverPadding, SliverSafeArea, SliverToBoxAdapter, Spacer, Stack, Switch, Tab, TabBar, TabBarView, Text, TextButton, TextField, Wrap } from '../flutter.js';

// 组件 TextDetail
export class TextDetail {
  constructor(args) {
    this.props = args || {};
    this._count = 0;
  }
  bump() {
    this.setState(() => { this._count += 1; });
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": "stretch",
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "基础文案 + TextStyle",
          "style": {
            "fontSize": 16,
            "fontWeight": "bold"
          }
        }))),
        new Text({
          "style": {
            "color": Colors.blue,
            "fontSize": 16
          },
          "data": "普通文本，count = " + this._count + "（状态插值）"
        }),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 6
        }))),
        new Text({
          "maxLines": 1,
          "overflow": "ellipsis",
          "data": "maxLines+overflow 测试：这是一段很长的文字会被截断成省略号显示"
        }),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 6
        }))),
        new Text({
          "textScaler": {
            "linear": 1.6
          },
          "data": "textScaler.linear(1.6) 放大"
        }),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 6
        }))),
        new Text({
          "textAlign": "center",
          "style": {
            "decoration": "underline",
            "decorationColor": Colors.orange,
            "decorationStyle": "wavy"
          },
          "data": "textAlign 居中,He said \"hi\""
        }),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 6
        }))),
        new Text({
          "softWrap": false,
          "style": {
            "fontSize": 12,
            "color": Colors.grey,
            "wordSpacing": 2,
            "letterSpacing": 1,
            "backgroundColor": new Color({value: 0xFFFFE082})
          },
          "data": "softWrap=false 不换行测试"
        }),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 6
        }))),
        new TextButton({
          "onPressed": this.__bindFn(0, [], (...__a) => this.bump(...__a)),
          "child": (this.__k2 || (this.__k2 = new Text({
            "data": "Bump count"
          })))
        })
      ]
    });
  }
}

// 组件 ButtonDetail
export class ButtonDetail {
  constructor(args) {
    this.props = args || {};
    this._pressed = 0;
  }
  onTap() {
    this.setState(() => { this._pressed += 1; });
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": "stretch",
      "children": [
        new Text({
          "style": {
            "fontSize": 16,
            "fontWeight": "bold"
          },
          "data": "点击次数 = " + this._pressed
        }),
        (this.__k0 || (this.__k0 = new SizedBox({
          "height": 8
        }))),
        new ElevatedButton({
          "onPressed": this.__bindFn(0, [], (...__a) => this.onTap(...__a)),
          "style": {
            "minimumSize": {
              "width": 180,
              "height": 48
            },
            "maximumSize": {
              "width": 240,
              "height": 56
            },
            "padding": {
              "left": 24.0,
              "top": 12.0,
              "right": 24.0,
              "bottom": 12.0
            },
            "elevation": 6,
            "shadowColor": Colors.deepPurple,
            "textStyle": {
              "fontSize": 18,
              "fontWeight": "bold",
              "letterSpacing": 2
            },
            "backgroundColor": Colors.teal,
            "foregroundColor": Colors.white
          },
          "child": (this.__k1 || (this.__k1 = new Text({
            "data": "Elevated · Styled"
          })))
        }),
        (this.__k0 || (this.__k0 = new SizedBox({
          "height": 8
        }))),
        new TextButton({
          "onPressed": this.__bindFn(1, [], (...__a) => this.onTap(...__a)),
          "style": {
            "minimumSize": {
              "width": 120,
              "height": 40
            },
            "padding": {
              "left": 16.0,
              "top": 0.0,
              "right": 16.0,
              "bottom": 0.0
            },
            "textStyle": {
              "fontSize": 14,
              "letterSpacing": 1
            },
            "foregroundColor": Colors.indigo
          },
          "child": (this.__k2 || (this.__k2 = new Text({
            "data": "TextButton"
          })))
        }),
        (this.__k0 || (this.__k0 = new SizedBox({
          "height": 8
        }))),
        new OutlinedButton({
          "onPressed": this.__bindFn(2, [], (...__a) => this.onTap(...__a)),
          "style": {
            "side": {
              "color": Colors.orange,
              "width": 2
            },
            "minimumSize": {
              "width": 120,
              "height": 40
            },
            "shape": {
              "kind": "rounded",
              "borderRadius": {
                "radius": 20.0
              }
            },
            "foregroundColor": Colors.deepOrange
          },
          "child": (this.__k3 || (this.__k3 = new Text({
            "data": "OutlinedButton"
          })))
        }),
        (this.__k0 || (this.__k0 = new SizedBox({
          "height": 8
        }))),
        (this.__k4 || (this.__k4 = new ElevatedButton({
          "child": new Text({
            "data": "Disabled"
          })
        })))
      ]
    });
  }
}

// 组件 LayoutDetail
export class LayoutDetail {
  constructor(args) {
    this.props = args || {};
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": "stretch",
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "Row + Expanded / Flexible / Spacer",
          "style": {
            "fontSize": 16,
            "fontWeight": "bold"
          }
        }))),
        new Row({
          "children": [
            new Expanded({
              "flex": 1,
              "child": new Container({
                "color": Colors.blue.shade100,
                "padding": {
                  "left": 8.0,
                  "top": 8.0,
                  "right": 8.0,
                  "bottom": 8.0
                },
                "child": (this.__k1 || (this.__k1 = new Text({
                  "data": "A",
                  "textAlign": "center"
                })))
              })
            }),
            (this.__k2 || (this.__k2 = new Spacer({
              "flex": 1
            }))),
            new Expanded({
              "flex": 2,
              "child": new Container({
                "color": Colors.green.shade100,
                "padding": {
                  "left": 8.0,
                  "top": 8.0,
                  "right": 8.0,
                  "bottom": 8.0
                },
                "child": (this.__k3 || (this.__k3 = new Text({
                  "data": "B（flex=2）",
                  "textAlign": "center"
                })))
              })
            })
          ]
        }),
        (this.__k4 || (this.__k4 = new SizedBox({
          "height": 12
        }))),
        (this.__k5 || (this.__k5 = new Text({
          "data": "Center / Align / Padding / SizedBox",
          "style": {
            "fontSize": 16,
            "fontWeight": "bold"
          }
        }))),
        new Center({
          "child": new Container({
            "color": Colors.amber.shade100,
            "padding": {
              "left": 12.0,
              "top": 12.0,
              "right": 12.0,
              "bottom": 12.0
            },
            "child": (this.__k6 || (this.__k6 = new Text({
              "data": "Center 居中"
            })))
          })
        }),
        (this.__k7 || (this.__k7 = new SizedBox({
          "height": 8
        }))),
        new Align({
          "alignment": "centerLeft",
          "child": new Container({
            "color": Colors.purple.shade50,
            "padding": {
              "left": 8.0,
              "top": 8.0,
              "right": 8.0,
              "bottom": 8.0
            },
            "child": (this.__k8 || (this.__k8 = new Text({
              "data": "Align centerLeft"
            })))
          })
        }),
        (this.__k7 || (this.__k7 = new SizedBox({
          "height": 8
        }))),
        new Padding({
          "padding": {
            "left": 8.0,
            "top": 4.0,
            "right": 8.0,
            "bottom": 4.0
          },
          "child": (this.__k9 || (this.__k9 = new Text({
            "data": "Padding 包裹文案"
          })))
        }),
        (this.__k4 || (this.__k4 = new SizedBox({
          "height": 12
        }))),
        (this.__k10 || (this.__k10 = new Text({
          "data": "Stack + Positioned",
          "style": {
            "fontSize": 16,
            "fontWeight": "bold"
          }
        }))),
        new SizedBox({
          "height": 100,
          "child": new Stack({
            "fit": "expand",
            "clipBehavior": "hardEdge",
            "children": [
              new Container({
                "color": Colors.grey.shade200
              }),
              Positioned.fill({
                "child": new Center({
                  "child": new Text({
                    "style": {
                      "color": Colors.white,
                      "fontWeight": "bold"
                    },
                    "data": "FILL"
                  })
                })
              }),
              (this.__k11 || (this.__k11 = new Positioned({
                "child": new Text({
                  "data": "TL"
                }),
                "left": 12,
                "top": 12
              }))),
              (this.__k12 || (this.__k12 = new Positioned({
                "bottom": 12,
                "child": new Text({
                  "data": "BR"
                }),
                "right": 12
              })))
            ]
          })
        }),
        (this.__k4 || (this.__k4 = new SizedBox({
          "height": 12
        }))),
        (this.__k13 || (this.__k13 = new Text({
          "data": "Wrap · 自动换行",
          "style": {
            "fontSize": 16,
            "fontWeight": "bold"
          }
        }))),
        new Wrap({
          "direction": "horizontal",
          "spacing": 8,
          "runSpacing": 8,
          "alignment": "start",
          "runAlignment": "center",
          "crossAxisAlignment": "center",
          "children": [
            ...(() => { var out = []; for (let i = 1; (i <= 5); (i++)) { out.push.apply(out, [new Chip({
                    "label": new Text({
                      "data": "chip " + i
                    }),
                    "backgroundColor": Colors.teal.shade50
                  })]); } return out; })()
          ]
        }),
        (this.__k4 || (this.__k4 = new SizedBox({
          "height": 12
        }))),
        (this.__k14 || (this.__k14 = new Text({
          "data": "Opacity / ConstrainedBox / AspectRatio / FractionallySizedBox",
          "style": {
            "fontSize": 16,
            "fontWeight": "bold"
          }
        }))),
        new Opacity({
          "opacity": 0.5,
          "child": new Container({
            "color": Colors.red,
            "padding": {
              "left": 8.0,
              "top": 8.0,
              "right": 8.0,
              "bottom": 8.0
            },
            "child": (this.__k15 || (this.__k15 = new Text({
              "data": "50% 透明"
            })))
          })
        }),
        (this.__k7 || (this.__k7 = new SizedBox({
          "height": 8
        }))),
        new ConstrainedBox({
          "constraints": {
            "minWidth": 120,
            "maxWidth": 200
          },
          "child": new Container({
            "color": Colors.orange.shade100,
            "padding": {
              "left": 8.0,
              "top": 8.0,
              "right": 8.0,
              "bottom": 8.0
            },
            "child": (this.__k16 || (this.__k16 = new Text({
              "data": "ConstrainedBox 宽度 120-200"
            })))
          })
        }),
        (this.__k7 || (this.__k7 = new SizedBox({
          "height": 8
        }))),
        new AspectRatio({
          "aspectRatio": 1.78,
          "child": new Container({
            "color": Colors.indigo.shade100,
            "alignment": "center",
            "child": (this.__k17 || (this.__k17 = new Text({
              "data": "16:9 比例"
            })))
          })
        }),
        (this.__k7 || (this.__k7 = new SizedBox({
          "height": 8
        }))),
        new FractionallySizedBox({
          "widthFactor": 0.6,
          "alignment": "center",
          "child": new Container({
            "color": Colors.pink.shade100,
            "padding": {
              "left": 8.0,
              "top": 8.0,
              "right": 8.0,
              "bottom": 8.0
            },
            "child": (this.__k18 || (this.__k18 = new Text({
              "data": "60% 宽度",
              "textAlign": "center"
            })))
          })
        })
      ]
    });
  }
}

// 组件 ImageDetail
export class ImageDetail {
  constructor(args) {
    this.props = args || {};
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": "stretch",
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "Image · 网络图片",
          "style": {
            "fontSize": 16,
            "fontWeight": "bold"
          }
        }))),
        new ClipRRect({
          "borderRadius": {
            "radius": 12.0
          },
          "child": Image.network({
            "height": 120,
            "fit": "cover",
            "src": "https://picsum.photos/seed/hotpatch/400/160"
          })
        }),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 12
        }))),
        (this.__k2 || (this.__k2 = new Text({
          "data": "CachedNetworkImage · 磁盘缓存网络图",
          "style": {
            "fontSize": 16,
            "fontWeight": "bold"
          }
        }))),
        new ClipRRect({
          "borderRadius": {
            "radius": 12.0
          },
          "child": new CachedNetworkImage({
            "imageUrl": "https://picsum.photos/seed/hotpatchcache/400/160",
            "height": 120,
            "fit": "cover"
          })
        }),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 12
        }))),
        (this.__k3 || (this.__k3 = new Text({
          "data": "Icon / CircleAvatar",
          "style": {
            "fontSize": 16,
            "fontWeight": "bold"
          }
        }))),
        new Row({
          "children": [
            (this.__k4 || (this.__k4 = new Icon({
              "color": Colors.amber,
              "icon": "star",
              "size": 28
            }))),
            (this.__k5 || (this.__k5 = new SizedBox({
              "width": 12
            }))),
            (this.__k6 || (this.__k6 = new Icon({
              "color": Colors.blue,
              "icon": "home",
              "size": 28
            }))),
            (this.__k5 || (this.__k5 = new SizedBox({
              "width": 12
            }))),
            (this.__k7 || (this.__k7 = new Icon({
              "color": Colors.red,
              "icon": "favorite",
              "size": 28
            }))),
            (this.__k5 || (this.__k5 = new SizedBox({
              "width": 12
            }))),
            new CircleAvatar({
              "radius": 20,
              "backgroundColor": Colors.teal,
              "child": new Text({
                "style": {
                  "color": Colors.white
                },
                "data": "AV"
              })
            })
          ]
        })
      ]
    });
  }
}

// 组件 ContainerDetail
export class ContainerDetail {
  constructor(args) {
    this.props = args || {};
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": "stretch",
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "Container · 颜色/圆角/Padding",
          "style": {
            "fontSize": 16,
            "fontWeight": "bold"
          }
        }))),
        new Container({
          "padding": {
            "left": 16.0,
            "top": 16.0,
            "right": 16.0,
            "bottom": 16.0
          },
          "decoration": {
            "color": Colors.teal,
            "borderRadius": {
              "radius": 12.0
            }
          },
          "child": (this.__k1 || (this.__k1 = new Text({
            "data": "容器内容（teal 圆角）",
            "style": {
              "color": Colors.white
            }
          })))
        }),
        (this.__k2 || (this.__k2 = new SizedBox({
          "height": 12
        }))),
        (this.__k3 || (this.__k3 = new Text({
          "data": "Container · 边框 + 阴影 + 渐变",
          "style": {
            "fontSize": 16,
            "fontWeight": "bold"
          }
        }))),
        new Container({
          "padding": {
            "left": 16.0,
            "top": 16.0,
            "right": 16.0,
            "bottom": 16.0
          },
          "decoration": {
            "gradient": {
              "kind": "linear",
              "colors": [
                Colors.blue,
                Colors.purple
              ],
              "begin": "topLeft",
              "end": "bottomRight"
            },
            "borderRadius": {
              "radius": 16.0
            },
            "border": {
              "all": {
                "color": Colors.white,
                "width": 2
              }
            },
            "boxShadow": [
              {
                "color": new Color({value: 0x66000000}),
                "dx": 0,
                "dy": 4,
                "blur": 12,
                "spread": 1
              }
            ]
          },
          "child": (this.__k4 || (this.__k4 = new Text({
            "data": "渐变 + 边框 + 阴影",
            "style": {
              "color": Colors.white
            }
          })))
        }),
        (this.__k2 || (this.__k2 = new SizedBox({
          "height": 12
        }))),
        (this.__k5 || (this.__k5 = new Text({
          "data": "DecoratedBox · 纯装饰",
          "style": {
            "fontSize": 16,
            "fontWeight": "bold"
          }
        }))),
        new DecoratedBox({
          "decoration": {
            "color": Colors.amber.shade100,
            "border": {
              "all": {
                "color": Colors.amber,
                "width": 2
              }
            },
            "borderRadius": {
              "radius": 8.0
            }
          },
          "child": (this.__k6 || (this.__k6 = new Padding({
            "child": new Text({
              "data": "DecoratedBox 内容"
            }),
            "padding": {
              "bottom": 12.0,
              "left": 12.0,
              "right": 12.0,
              "top": 12.0
            }
          })))
        }),
        (this.__k2 || (this.__k2 = new SizedBox({
          "height": 12
        }))),
        (this.__k7 || (this.__k7 = new Text({
          "data": "Card · shape / clipBehavior",
          "style": {
            "fontSize": 16,
            "fontWeight": "bold"
          }
        }))),
        new Card({
          "elevation": 4,
          "shadowColor": Colors.deepPurple,
          "shape": {
            "kind": "rounded",
            "borderRadius": {
              "radius": 16.0
            },
            "side": {
              "color": Colors.deepPurple,
              "width": 1
            }
          },
          "clipBehavior": "antiAlias",
          "child": (this.__k8 || (this.__k8 = new Padding({
            "child": new Text({
              "data": "圆角卡片 + 描边 + 阴影"
            }),
            "padding": {
              "bottom": 16.0,
              "left": 16.0,
              "right": 16.0,
              "top": 16.0
            }
          })))
        }),
        (this.__k2 || (this.__k2 = new SizedBox({
          "height": 12
        }))),
        (this.__k9 || (this.__k9 = new Divider({}))),
        (this.__k2 || (this.__k2 = new SizedBox({
          "height": 12
        }))),
        (this.__k10 || (this.__k10 = new Text({
          "data": "SizedBox · 尺寸约束",
          "style": {
            "fontSize": 16,
            "fontWeight": "bold"
          }
        }))),
        new Container({
          "width": 120,
          "height": 48,
          "alignment": "center",
          "color": Colors.blueGrey.shade100,
          "child": (this.__k11 || (this.__k11 = new Text({
            "data": "固定 120×48"
          })))
        })
      ]
    });
  }
}

// 组件 ScrollDetail
export class ScrollDetail {
  constructor(args) {
    this.props = args || {};
    this._offset = 0;
    this._ctrlOffset = 0;
    this._scrollController = new ScrollController();
    this._listSalt = 0;
  }
  initState() {
    this._scrollController.addListener(() => { this.setState(() => { this._ctrlOffset = this._scrollController.offset; }); });
  }
  dispose() {
    this._scrollController.dispose();
  }
  _onListScroll(n) {
    this.setState(() => { this._offset = n.metrics.pixels; });
    return false;
  }
  _scrollToEnd() {
    this._scrollController.jumpTo(this._scrollController.position.maxScrollExtent);
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": "stretch",
      "children": [
        new Text({
          "style": {
            "fontSize": 16,
            "fontWeight": "bold"
          },
          "data": "ListView.builder · 懒构建列表（offset: " + this._offset + "）"
        }),
        new NotificationListener({
          "onNotification": this.__bindFn(0, [], (...__a) => this._onListScroll(...__a)),
          "child": new SizedBox({
            "height": 160,
            "child": ListView.builder({
              "padding": {
                "left": 8.0,
                "top": 8.0,
                "right": 8.0,
                "bottom": 8.0
              },
              "itemExtent": 56,
              "physics": "BouncingScrollPhysics",
              "itemCount": 20,
              "itemBuilder": (context, index) => new ListTile({
                "leading": (this.__k0 || (this.__k0 = new Icon({
                  "icon": "list"
                }))),
                "title": new CommonListItem({
                  "index": index,
                  "salt": this._listSalt
                })
              })
            })
          }),
          "model": "ScrollNotification"
        }),
        new Align({
          "alignment": "centerLeft",
          "child": new TextButton({
            "onPressed": this.__bindFn(1, [], () => this.setState(() => {
              this._listSalt += 1;
            })),
            "child": (this.__k1 || (this.__k1 = new Text({
              "data": "列表换色（真实更新）"
            })))
          })
        }),
        (this.__k2 || (this.__k2 = new SizedBox({
          "height": 12
        }))),
        new Text({
          "style": {
            "fontSize": 16,
            "fontWeight": "bold"
          },
          "data": "ListView.separated · 分隔列表"
        }),
        new SizedBox({
          "height": 140,
          "child": ListView.separated({
            "padding": {
              "left": 8.0,
              "top": 8.0,
              "right": 8.0,
              "bottom": 8.0
            },
            "itemCount": 6,
            "separatorBuilder": (context, index) => (this.__k3 || (this.__k3 = new Divider({
              "height": 1
            }))),
            "itemBuilder": (context, index) => new ListTile({
              "dense": true,
              "leading": new Icon({
                "color": Colors.teal.shade300,
                "icon": "arrow_right"
              }),
              "title": new Text({
                "data": "separated item " + index
              })
            })
          })
        }),
        (this.__k2 || (this.__k2 = new SizedBox({
          "height": 12
        }))),
        new Text({
          "style": {
            "fontSize": 16,
            "fontWeight": "bold"
          },
          "data": "SingleChildScrollView · 长内容滚动（ctrl offset: " + this._ctrlOffset + "）"
        }),
        new SingleChildScrollView({
          "controller": this._scrollController,
          "scrollDirection": "horizontal",
          "physics": "ClampingScrollPhysics",
          "child": new Row({
            "children": [
              ...(() => { var out = []; for (let i = 1; (i <= 8); (i++)) { out.push.apply(out, [new Padding({
                      "padding": {
                        "left": 4.0,
                        "top": 4.0,
                        "right": 4.0,
                        "bottom": 4.0
                      },
                      "child": new Chip({
                        "label": new Text({
                          "data": "横向 " + i
                        })
                      })
                    })]); } return out; })()
            ]
          })
        }),
        new Align({
          "alignment": "centerLeft",
          "child": new TextButton({
            "onPressed": this.__bindFn(2, [], (...__a) => this._scrollToEnd(...__a)),
            "child": (this.__k4 || (this.__k4 = new Text({
              "data": "横向 · 跳到底"
            })))
          })
        })
      ]
    });
  }
}

// 组件 SliverDetail
export class SliverDetail {
  constructor(args) {
    this.props = args || {};
    this._controller = new ScrollController();
    this._offset = 0;
    this._fixedKey = new GlobalKey();
    this._measureText = "未测量";
  }
  initState() {
    this._controller.addListener(() => { this.setState(() => { this._offset = this._controller.offset; }); });
  }
  dispose() {
    this._controller.dispose();
  }
  _scrollToEnd() {
    this._controller.jumpTo(this._controller.position.maxScrollExtent);
  }
  _scrollToFixed() {
    var ctx = this._fixedKey.currentContext;
    if ((ctx == null)) {
      return;
    }
    var target = ctx.findRenderObject();
    if ((target == null)) {
      return;
    }
    target.showOnScreen();
  }
  async _measureFixed() {
    var ctx = this._fixedKey.currentContext;
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
  build(context) {
    return new Scaffold({
      "body": new CustomScrollView({
        "controller": this._controller,
        "physics": "BouncingScrollPhysics",
        "slivers": [
          new SliverAppBar({
            "title": new Text({
              "data": "SliverAppBar 导航 · offset " + this._offset.toStringAsFixed(0)
            }),
            "backgroundColor": Colors.deepPurple,
            "foregroundColor": Colors.white,
            "pinned": true,
            "floating": true,
            "actions": [
              new IconButton({
                "icon": (this.__k0 || (this.__k0 = new Icon({
                  "icon": "center_focus_strong"
                }))),
                "tooltip": "定位到「固定高度」分区",
                "onPressed": this.__bindFn(0, [], (...__a) => this._scrollToFixed(...__a))
              }),
              new IconButton({
                "icon": (this.__k1 || (this.__k1 = new Icon({
                  "icon": "straighten"
                }))),
                "tooltip": "测量「固定高度」分区的位置与尺寸",
                "onPressed": this.__bindFn(1, [], (...__a) => this._measureFixed(...__a))
              })
            ]
          }),
          new SliverToBoxAdapter({
            "child": new Container({
              "margin": {
                "left": 12.0,
                "top": 12.0,
                "right": 12.0,
                "bottom": 12.0
              },
              "padding": {
                "left": 16.0,
                "top": 16.0,
                "right": 16.0,
                "bottom": 16.0
              },
              "decoration": {
                "color": Colors.deepPurple.shade50,
                "borderRadius": {
                  "radius": 12.0
                }
              },
              "child": (this.__k2 || (this.__k2 = new Text({
                "data": "CustomScrollView 整页 · SliverToBoxAdapter 盒子",
                "style": {
                  "fontSize": 14,
                  "fontWeight": "bold"
                }
              })))
            })
          }),
          new SliverToBoxAdapter({
            "child": new Container({
              "margin": {
                "left": 12.0,
                "top": 0.0,
                "right": 12.0,
                "bottom": 4.0
              },
              "padding": {
                "left": 10.0,
                "top": 10.0,
                "right": 10.0,
                "bottom": 10.0
              },
              "decoration": {
                "color": Colors.teal.shade50,
                "borderRadius": {
                  "radius": 8.0
                }
              },
              "child": new Text({
                "style": {
                  "fontSize": 13,
                  "color": Colors.teal
                },
                "data": "GlobalKey 测量：「固定高度」分区 " + this._measureText
              })
            })
          }),
          new SliverPadding({
            "padding": {
              "left": 12.0,
              "top": 0.0,
              "right": 12.0,
              "bottom": 0.0
            },
            "sliver": new SliverList({
              "delegate": {
                "__delegate": "list",
                "children": [
                  ...(() => { var out = []; for (let i = 1; (i <= 5); (i++)) { out.push.apply(out, [new ListTile({
                          "leading": (this.__k3 || (this.__k3 = new Icon({
                            "color": Colors.deepPurple,
                            "icon": "list"
                          }))),
                          "title": new Text({
                            "data": "SliverList item " + i
                          }),
                          "trailing": (this.__k4 || (this.__k4 = new Icon({
                            "icon": "chevron_right"
                          })))
                        })]); } return out; })()
                ]
              }
            })
          }),
          new SliverPadding({
            "padding": {
              "left": 12.0,
              "top": 8.0,
              "right": 12.0,
              "bottom": 8.0
            },
            "sliver": new SliverToBoxAdapter({
              "child": new Text({
                "style": {
                  "fontSize": 14,
                  "fontWeight": "bold"
                },
                "data": "SliverList.builder · 懒构建列表"
              })
            })
          }),
          new SliverPadding({
            "padding": {
              "left": 12.0,
              "top": 0.0,
              "right": 12.0,
              "bottom": 0.0
            },
            "sliver": SliverList.builder({
              "itemCount": 8,
              "itemBuilder": (context, index) => new ListTile({
                "leading": new Icon({
                  "color": Colors.orange.shade700,
                  "icon": "build"
                }),
                "title": new Text({
                  "data": "builder item " + index
                }),
                "subtitle": new Text({
                  "data": "index * 10 = " + (index * 10)
                })
              })
            })
          }),
          new SliverPadding({
            "padding": {
              "left": 12.0,
              "top": 8.0,
              "right": 12.0,
              "bottom": 8.0
            },
            "sliver": new SliverToBoxAdapter({
              "child": new Text({
                "style": {
                  "fontSize": 14,
                  "fontWeight": "bold"
                },
                "data": "SliverList.separated · 分隔列表"
              })
            })
          }),
          new SliverPadding({
            "padding": {
              "left": 12.0,
              "top": 0.0,
              "right": 12.0,
              "bottom": 0.0
            },
            "sliver": SliverList.separated({
              "itemCount": 5,
              "itemBuilder": (context, index) => new ListTile({
                "dense": true,
                "leading": (this.__k5 || (this.__k5 = new Icon({
                  "color": Colors.deepPurple,
                  "icon": "arrow_right"
                }))),
                "title": new Text({
                  "data": "separated item " + index
                })
              }),
              "separatorBuilder": (context, index) => (this.__k6 || (this.__k6 = new Divider({
                "height": 1
              })))
            })
          }),
          new SliverPadding({
            "padding": {
              "left": 12.0,
              "top": 8.0,
              "right": 12.0,
              "bottom": 8.0
            },
            "sliver": new SliverToBoxAdapter({
              "child": new Container({
                "padding": {
                  "left": 10.0,
                  "top": 8.0,
                  "right": 10.0,
                  "bottom": 8.0
                },
                "decoration": {
                  "color": Colors.teal.shade50,
                  "borderRadius": {
                    "radius": 6.0
                  }
                },
                "child": new Text({
                  "style": {
                    "fontSize": 14,
                    "fontWeight": "bold"
                  },
                  "data": "SliverFixedExtentList · 固定高度"
                }),
                "key": this._fixedKey
              })
            })
          }),
          new SliverPadding({
            "padding": {
              "left": 12.0,
              "top": 0.0,
              "right": 12.0,
              "bottom": 0.0
            },
            "sliver": new SliverFixedExtentList({
              "itemExtent": 44,
              "delegate": {
                "__delegate": "builder",
                "builder": (context, index) => new ListTile({
                  "dense": true,
                  "leading": (this.__k7 || (this.__k7 = new Icon({
                    "color": Colors.teal,
                    "icon": "height"
                  }))),
                  "title": new Text({
                    "data": "fixed item " + index
                  })
                }),
                "childCount": 6
              }
            })
          }),
          new SliverPadding({
            "padding": {
              "left": 12.0,
              "top": 8.0,
              "right": 12.0,
              "bottom": 8.0
            },
            "sliver": new SliverToBoxAdapter({
              "child": new Text({
                "style": {
                  "fontSize": 14,
                  "fontWeight": "bold"
                },
                "data": "SliverOpacity + SliverGrid.builder · MaxCrossAxisExtent 九宫格"
              })
            })
          }),
          new SliverOpacity({
            "opacity": 0.6,
            "sliver": new SliverPadding({
              "padding": {
                "left": 12.0,
                "top": 0.0,
                "right": 12.0,
                "bottom": 0.0
              },
              "sliver": SliverGrid.builder({
                "gridDelegate": {
                  "maxCrossAxisExtent": 140,
                  "mainAxisSpacing": 8,
                  "crossAxisSpacing": 8,
                  "childAspectRatio": 1
                },
                "itemCount": 9,
                "itemBuilder": (context, index) => new Container({
                  "decoration": {
                    "color": Colors.teal.shade100,
                    "borderRadius": {
                      "radius": 8.0
                    }
                  },
                  "alignment": "center",
                  "child": new Text({
                    "style": {
                      "fontWeight": "bold"
                    },
                    "data": "格 " + index
                  })
                })
              })
            })
          }),
          new SliverSafeArea({
            "sliver": new SliverFillRemaining({
              "hasScrollBody": false,
              "child": new Center({
                "child": new Text({
                  "style": {
                    "color": Colors.grey
                  },
                  "data": "底部 · SliverSafeArea + SliverFillRemaining"
                })
              })
            })
          })
        ]
      }),
      "floatingActionButton": new FloatingActionButton({
        "onPressed": this.__bindFn(2, [], (...__a) => this._scrollToEnd(...__a)),
        "backgroundColor": Colors.deepPurple,
        "foregroundColor": Colors.white,
        "tooltip": "跳到底",
        "child": (this.__k8 || (this.__k8 = new Icon({
          "icon": "arrow_downward"
        })))
      })
    });
  }
}

// 组件 GridDetail
export class GridDetail {
  constructor(args) {
    this.props = args || {};
    this._controller = new ScrollController();
    this._offset = 0;
  }
  initState() {
    this._controller.addListener(() => { this.setState(() => { this._offset = this._controller.offset; }); });
  }
  dispose() {
    this._controller.dispose();
  }
  _jumpBottom() {
    this._controller.jumpTo(this._controller.position.maxScrollExtent);
  }
  build(context) {
    return new Scaffold({
      "backgroundColor": Colors.grey.shade50,
      "appBar": new AppBar({
        "title": (this.__k0 || (this.__k0 = new Text({
          "data": "GridView 懒加载验证"
        }))),
        "backgroundColor": Colors.teal,
        "foregroundColor": Colors.white
      }),
      "floatingActionButton": new FloatingActionButton({
        "onPressed": this.__bindFn(0, [], (...__a) => this._jumpBottom(...__a)),
        "backgroundColor": Colors.teal,
        "foregroundColor": Colors.white,
        "tooltip": "跳到底",
        "child": (this.__k1 || (this.__k1 = new Icon({
          "icon": "arrow_downward"
        })))
      }),
      "body": new Column({
        "crossAxisAlignment": "stretch",
        "children": [
          new Padding({
            "padding": {
              "left": 12.0,
              "top": 12.0,
              "right": 12.0,
              "bottom": 12.0
            },
            "child": new Text({
              "style": {
                "fontSize": 13,
                "color": Colors.grey
              },
              "data": "controller offset: " + this._offset.toStringAsFixed(1)
            })
          }),
          (this.__k2 || (this.__k2 = new Padding({
            "child": new Text({
              "style": {
                "fontSize": 14,
                "fontWeight": "bold"
              },
              "data": "GridView.builder · 固定 3 列 · 30 项（懒加载）"
            }),
            "padding": {
              "bottom": 0.0,
              "left": 12.0,
              "right": 12.0,
              "top": 0.0
            }
          }))),
          new Expanded({
            "flex": 5,
            "child": GridView.builder({
              "controller": this._controller,
              "gridDelegate": {
                "crossAxisCount": 3,
                "mainAxisSpacing": 8,
                "crossAxisSpacing": 8,
                "childAspectRatio": 1
              },
              "itemCount": 30,
              "itemBuilder": (context, index) => new Container({
                "decoration": {
                  "color": Colors.teal.shade100,
                  "borderRadius": {
                    "radius": 8.0
                  }
                },
                "alignment": "center",
                "child": new Text({
                  "style": {
                    "fontWeight": "bold"
                  },
                  "data": "格 " + index
                })
              })
            })
          }),
          (this.__k3 || (this.__k3 = new Padding({
            "child": new Text({
              "style": {
                "fontSize": 14,
                "fontWeight": "bold"
              },
              "data": "GridView.builder · MaxCrossAxisExtent 120 · 20 项（懒加载）"
            }),
            "padding": {
              "bottom": 8.0,
              "left": 12.0,
              "right": 12.0,
              "top": 8.0
            }
          }))),
          new Expanded({
            "flex": 4,
            "child": GridView.builder({
              "gridDelegate": {
                "maxCrossAxisExtent": 120,
                "mainAxisSpacing": 8,
                "crossAxisSpacing": 8,
                "childAspectRatio": 1
              },
              "itemCount": 20,
              "itemBuilder": (context, index) => new Container({
                "decoration": {
                  "color": Colors.orange.shade100,
                  "borderRadius": {
                    "radius": 8.0
                  }
                },
                "alignment": "center",
                "child": new Text({
                  "style": {
                    "fontWeight": "bold"
                  },
                  "data": "项 " + index
                })
              })
            })
          })
        ]
      })
    });
  }
}

// 组件 ScaffoldDetail
export class ScaffoldDetail {
  constructor(args) {
    this.props = args || {};
    this._navIndex = 0;
  }
  _onNavTap(index) {
    this.setState(() => { this._navIndex = index; });
  }
  _onFab() {
  }
  build(context) {
    return new Scaffold({
      "backgroundColor": Colors.grey.shade50,
      "appBar": new AppBar({
        "leading": (this.__k0 || (this.__k0 = new Icon({
          "icon": "menu"
        }))),
        "title": (this.__k1 || (this.__k1 = new Text({
          "data": "Scaffold / AppBar / FAB / BottomNav"
        }))),
        "backgroundColor": Colors.deepPurple,
        "foregroundColor": Colors.white,
        "elevation": 4,
        "centerTitle": true,
        "toolbarHeight": 56,
        "actions": [
          new Icon({
            "color": Colors.white,
            "icon": "search"
          }),
          new SizedBox({
            "width": 16
          })
        ]
      }),
      "body": new SafeArea({
        "child": new Center({
          "child": new Column({
            "mainAxisAlignment": "center",
            "children": [
              (this.__k2 || (this.__k2 = new Icon({
                "color": Colors.deepPurple,
                "icon": "extension",
                "size": 48
              }))),
              (this.__k3 || (this.__k3 = new SizedBox({
                "height": 12
              }))),
              (this.__k4 || (this.__k4 = new Text({
                "data": "页面骨架组件演示"
              }))),
              new Text({
                "data": "BottomNav 选中：" + this._navIndex
              })
            ]
          })
        })
      }),
      "floatingActionButton": new FloatingActionButton({
        "onPressed": this.__bindFn(0, [], (...__a) => this._onFab(...__a)),
        "backgroundColor": Colors.deepPurple,
        "foregroundColor": Colors.white,
        "tooltip": "添加",
        "child": (this.__k5 || (this.__k5 = new Icon({
          "icon": "add"
        })))
      }),
      "bottomNavigationBar": new BottomNavigationBar({
        "currentIndex": this._navIndex,
        "onTap": this.__bindFn(1, [], (...__a) => this._onNavTap(...__a)),
        "selectedItemColor": Colors.deepPurple,
        "unselectedItemColor": Colors.grey,
        "items": [
          new BottomNavigationBarItem({
            "icon": new Icon({
              "icon": "home"
            }),
            "label": "首页"
          }),
          new BottomNavigationBarItem({
            "icon": new Icon({
              "icon": "search"
            }),
            "label": "搜索"
          }),
          new BottomNavigationBarItem({
            "icon": new Icon({
              "icon": "person"
            }),
            "label": "我的"
          })
        ]
      })
    });
  }
}

// 组件 InputDetail
export class InputDetail {
  constructor(args) {
    this.props = args || {};
    this._controller = new TextEditingController();
    this._text = "";
    this._choice = "A";
    this._dropdown = "苹果";
    this._switchOn = false;
    this._checked = false;
    this._slider = 0.4;
  }
  initState() {
    this._controller.addListener((...args) => this._onControllerChanged(...args));
  }
  _onControllerChanged() {
    if (!this.__unmounted) {
      this.setState(() => { this._text = this._controller.text; });
    }
  }
  _onTextChanged(v) {
    this.setState(() => { this._text = v; });
  }
  _onChoiceChanged(v) {
    this.setState(() => { this._choice = v; });
  }
  _onDropdownChanged(v) {
    this.setState(() => { this._dropdown = v; });
  }
  _onSwitchChanged(v) {
    this.setState(() => { this._switchOn = (v ?? false); });
  }
  _onCheckChanged(v) {
    this.setState(() => { this._checked = v; });
  }
  _onSliderChanged(v) {
    this.setState(() => { this._slider = v; });
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": "stretch",
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "TextField",
          "style": {
            "fontSize": 16,
            "fontWeight": "bold"
          }
        }))),
        new TextField({
          "controller": this._controller,
          "onChanged": this.__bindFn(0, [], (...__a) => this._onTextChanged(...__a)),
          "decoration": (this.__k1 || (this.__k1 = new InputDecoration({
            "hintText": "请输入文本",
            "labelText": "用户名"
          }))),
          "maxLines": 1,
          "style": {
            "fontSize": 16
          }
        }),
        (this.__k2 || (this.__k2 = new SizedBox({
          "height": 4
        }))),
        new Text({
          "style": {
            "fontSize": 14,
            "color": Colors.grey
          },
          "data": "输入内容：" + this._text
        }),
        new Text({
          "style": {
            "fontSize": 14,
            "color": Colors.deepPurple
          },
          "data": "controller.text：" + this._controller.text
        }),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 8
        }))),
        new Align({
          "alignment": "centerLeft",
          "child": new FilledButton({
            "onPressed": this.__bindFn(1, [], () => this._controller.clear()),
            "child": (this.__k4 || (this.__k4 = new Text({
              "data": "清空输入"
            })))
          })
        }),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 12
        }))),
        (this.__k6 || (this.__k6 = new Text({
          "data": "Radio 单选",
          "style": {
            "fontSize": 16,
            "fontWeight": "bold"
          }
        }))),
        new Row({
          "children": [
            new Radio({
              "value": "A",
              "groupValue": this._choice,
              "onChanged": this.__bindFn(2, [], (...__a) => this._onChoiceChanged(...__a)),
              "activeColor": Colors.deepPurple
            }),
            (this.__k7 || (this.__k7 = new Text({
              "data": "选项 A"
            }))),
            new Radio({
              "value": "B",
              "groupValue": this._choice,
              "onChanged": this.__bindFn(3, [], (...__a) => this._onChoiceChanged(...__a)),
              "activeColor": Colors.deepPurple
            }),
            (this.__k8 || (this.__k8 = new Text({
              "data": "选项 B"
            })))
          ]
        }),
        new Text({
          "style": {
            "fontSize": 14,
            "color": Colors.grey
          },
          "data": "当前选择：" + this._choice
        }),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 12
        }))),
        (this.__k9 || (this.__k9 = new Text({
          "data": "DropdownButton",
          "style": {
            "fontSize": 16,
            "fontWeight": "bold"
          }
        }))),
        new DropdownButton({
          "value": this._dropdown,
          "isExpanded": true,
          "onChanged": this.__bindFn(4, [], (...__a) => this._onDropdownChanged(...__a)),
          "items": [
            new DropdownMenuItem({
              "value": "苹果",
              "child": new Text({
                "data": "苹果"
              })
            }),
            new DropdownMenuItem({
              "value": "香蕉",
              "child": new Text({
                "data": "香蕉"
              })
            }),
            new DropdownMenuItem({
              "value": "橙子",
              "child": new Text({
                "data": "橙子"
              })
            })
          ]
        }),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 12
        }))),
        new Row({
          "children": [
            new Switch({
              "value": this._switchOn,
              "onChanged": this.__bindFn(5, [], (...__a) => this._onSwitchChanged(...__a)),
              "activeColor": Colors.white,
              "activeTrackColor": Colors.deepPurple,
              "inactiveThumbColor": Colors.grey,
              "inactiveTrackColor": Colors.grey.shade300
            }),
            (this.__k10 || (this.__k10 = new SizedBox({
              "width": 8
            }))),
            new Text({
              "data": "Switch：" + (this._switchOn ? "开" : "关")
            })
          ]
        }),
        new Row({
          "children": [
            new Checkbox({
              "value": this._checked,
              "onChanged": this.__bindFn(6, [], (...__a) => this._onCheckChanged(...__a)),
              "activeColor": Colors.deepPurple,
              "checkColor": Colors.white
            }),
            (this.__k10 || (this.__k10 = new SizedBox({
              "width": 8
            }))),
            new Text({
              "data": "Checkbox：" + (this._checked ?? false)
            })
          ]
        }),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 8
        }))),
        new Text({
          "style": {
            "fontSize": 14
          },
          "data": "Slider 值：" + this._slider
        }),
        new Slider({
          "value": this._slider,
          "min": 0,
          "max": 1,
          "divisions": 10,
          "label": ((this._slider * 100)).round() + "%",
          "activeColor": Colors.deepPurple,
          "inactiveColor": Colors.grey.shade300,
          "onChanged": this.__bindFn(7, [], (...__a) => this._onSliderChanged(...__a))
        })
      ]
    });
  }
}

// 组件 ProgressDetail
export class ProgressDetail {
  constructor(args) {
    this.props = args || {};
    this._progress = 0.65;
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": "stretch",
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "CircularProgressIndicator",
          "style": {
            "fontSize": 16,
            "fontWeight": "bold"
          }
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new Row({
          "children": [
            new CircularProgressIndicator({
              "value": this._progress,
              "color": Colors.deepPurple,
              "backgroundColor": Colors.deepPurple.shade50,
              "strokeWidth": 6
            }),
            (this.__k2 || (this.__k2 = new SizedBox({
              "width": 24
            }))),
            (this.__k3 || (this.__k3 = new CircularProgressIndicator({})))
          ]
        }),
        (this.__k4 || (this.__k4 = new SizedBox({
          "height": 16
        }))),
        (this.__k5 || (this.__k5 = new Text({
          "data": "LinearProgressIndicator",
          "style": {
            "fontSize": 16,
            "fontWeight": "bold"
          }
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new LinearProgressIndicator({
          "value": this._progress,
          "color": Colors.deepPurple,
          "backgroundColor": Colors.deepPurple.shade50,
          "minHeight": 8
        }),
        (this.__k6 || (this.__k6 = new SizedBox({
          "height": 4
        }))),
        (this.__k7 || (this.__k7 = new LinearProgressIndicator({}))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 8
        }))),
        new Text({
          "style": {
            "fontSize": 14,
            "color": Colors.grey
          },
          "data": "进度值：" + this._progress
        })
      ]
    });
  }
}

// 组件 NotifierCard
export class NotifierCard {
  constructor(args) {
    this.props = args || {};
    this._model = new CounterVm();
  }
  _inc() {
    this._model.inc();
  }
  _reset() {
    this._model.reset();
  }
  build(context) {
    return new Card({
      "child": new Padding({
        "padding": {
          "left": 16.0,
          "top": 16.0,
          "right": 16.0,
          "bottom": 16.0
        },
        "child": new Column({
          "mainAxisSize": "min",
          "children": [
            new ListenableBuilder({
              "listenable": this._model,
              "builder": (context, index) => new Text({
                "style": {
                  "fontSize": 24,
                  "fontWeight": "bold"
                },
                "data": "count = " + this._model.count
              })
            }),
            (this.__k0 || (this.__k0 = new SizedBox({
              "height": 12
            }))),
            new Row({
              "mainAxisAlignment": "center",
              "children": [
                new ElevatedButton({
                  "onPressed": this.__bindFn(0, [], (...__a) => this._inc(...__a)),
                  "child": (this.__k1 || (this.__k1 = new Text({
                    "data": "+1"
                  })))
                }),
                (this.__k2 || (this.__k2 = new SizedBox({
                  "width": 12
                }))),
                new ElevatedButton({
                  "onPressed": this.__bindFn(1, [], (...__a) => this._reset(...__a)),
                  "child": (this.__k3 || (this.__k3 = new Text({
                    "data": "Reset"
                  })))
                })
              ]
            })
          ]
        })
      })
    });
  }
  dispose() {
    this._model.dispose();
  }
}

// 组件 StatelessCard
export class StatelessCard {
  constructor(args) {
    this.props = args || {};
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.title = (args && args.title !== undefined) ? args.title : '';
    this.subtitle = (args && args.subtitle !== undefined) ? args.subtitle : "";
    this.badge = (args && args.badge !== undefined) ? args.badge : "NEW";
  }
  build(context) {
    return new Card({
      "margin": {
        "left": 12.0,
        "top": 12.0,
        "right": 12.0,
        "bottom": 12.0
      },
      "child": new Padding({
        "padding": {
          "left": 16.0,
          "top": 16.0,
          "right": 16.0,
          "bottom": 16.0
        },
        "child": new Column({
          "mainAxisSize": "min",
          "crossAxisAlignment": "start",
          "children": [
            new Row({
              "children": [
                (this.__k0 || (this.__k0 = new Icon({
                  "color": Colors.teal,
                  "icon": "article"
                }))),
                (this.__k1 || (this.__k1 = new SizedBox({
                  "width": 8
                }))),
                new Expanded({
                  "child": new Text({
                    "style": {
                      "fontSize": 18,
                      "fontWeight": "bold"
                    },
                    "data": this.badge + " · " + this.title
                  })
                })
              ]
            }),
            (this.__k2 || (this.__k2 = new Divider({
              "height": 24
            }))),
            new Text({
              "style": {
                "fontSize": 14,
                "color": Colors.grey
              },
              "data": this.subtitle
            })
          ]
        })
      })
    });
  }
}

// 组件 TabDetail
export class TabDetail {
  constructor(args) {
    this.props = args || {};
    this._controller = new TabController({length: 3, vsync: this});
    this._index = 0;
  }
  initState() {
    this._controller.addListener(() => { this.setState(() => { this._index = this._controller.index; }); });
  }
  dispose() {
    this._controller.dispose();
  }
  _next() {
    this._controller.animateTo((((this._index + 1)) % 3));
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": "stretch",
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "DefaultTabController · 官方惯用法（controller 由祖先提供）",
          "style": {
            "fontSize": 15,
            "fontWeight": "bold"
          }
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 6
        }))),
        new SizedBox({
          "height": 180,
          "child": new DefaultTabController({
            "length": 3,
            "child": new Column({
              "children": [
                new TabBar({
                  "isScrollable": true,
                  "indicatorColor": Colors.deepPurple,
                  "labelColor": Colors.deepPurple,
                  "unselectedLabelColor": Colors.grey,
                  "tabs": [
                    new Tab({
                      "text": "广场"
                    }),
                    new Tab({
                      "text": "推荐"
                    }),
                    new Tab({
                      "text": "关注"
                    })
                  ]
                }),
                new Expanded({
                  "child": new TabBarView({
                    "children": [
                      new Center({
                        "child": new Text({
                          "data": "TabBarView · 广场"
                        })
                      }),
                      new Center({
                        "child": new Text({
                          "data": "TabBarView · 推荐"
                        })
                      }),
                      new Center({
                        "child": new Text({
                          "data": "TabBarView · 关注"
                        })
                      })
                    ]
                  })
                })
              ]
            })
          })
        }),
        (this.__k2 || (this.__k2 = new SizedBox({
          "height": 14
        }))),
        new Text({
          "style": {
            "fontSize": 15,
            "fontWeight": "bold"
          },
          "data": "显式 TabController · index = " + this._index
        }),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 6
        }))),
        new SizedBox({
          "height": 170,
          "child": new Column({
            "children": [
              new TabBar({
                "controller": this._controller,
                "tabs": [
                  new Tab({
                    "text": "首页"
                  }),
                  new Tab({
                    "text": "社区"
                  }),
                  new Tab({
                    "text": "我的"
                  })
                ]
              }),
              new Expanded({
                "child": new TabBarView({
                  "controller": this._controller,
                  "children": [
                    new Center({
                      "child": new Text({
                        "data": "第 1 页（index 0）"
                      })
                    }),
                    new Center({
                      "child": new Text({
                        "data": "第 2 页（index 1）"
                      })
                    }),
                    new Center({
                      "child": new Text({
                        "data": "第 3 页（index 2）"
                      })
                    })
                  ]
                })
              })
            ]
          })
        }),
        new Align({
          "alignment": "centerLeft",
          "child": new TextButton({
            "onPressed": this.__bindFn(0, [], (...__a) => this._next(...__a)),
            "child": (this.__k3 || (this.__k3 = new Text({
              "data": "下一 tab · controller.animateTo"
            })))
          })
        })
      ]
    });
  }
}

// 组件 PageViewDetail
export class PageViewDetail {
  constructor(args) {
    this.props = args || {};
    this._page = 0;
    this._pageController = new PageController({initialPage: 0});
  }
  _onPageChanged(index) {
    this.setState(() => { this._page = index; });
  }
  _prevPage() {
    if ((this._page > 0)) {
      this._pageController.jumpToPage((this._page - 1));
    }
  }
  _nextPage() {
    if ((this._page < 2)) {
      this._pageController.jumpToPage((this._page + 1));
    }
  }
  _jumpToLast() {
    this._pageController.jumpToPage(2);
  }
  dispose() {
    this._pageController.dispose();
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": "stretch",
      "children": [
        new Text({
          "style": {
            "fontSize": 15,
            "fontWeight": "bold"
          },
          "data": "PageView · 当前第 " + (this._page + 1) + " / 3 页"
        }),
        (this.__k0 || (this.__k0 = new SizedBox({
          "height": 6
        }))),
        new SizedBox({
          "height": 150,
          "child": new PageView({
            "controller": this._pageController,
            "onPageChanged": this.__bindFn(0, [], (...__a) => this._onPageChanged(...__a)),
            "children": [
              new Container({
                "color": Colors.deepPurple.shade100,
                "alignment": "center",
                "child": (this.__k1 || (this.__k1 = new Text({
                  "data": "第 1 页"
                })))
              }),
              new Container({
                "color": Colors.teal.shade100,
                "alignment": "center",
                "child": (this.__k2 || (this.__k2 = new Text({
                  "data": "第 2 页"
                })))
              }),
              new Container({
                "color": Colors.orange.shade100,
                "alignment": "center",
                "child": (this.__k3 || (this.__k3 = new Text({
                  "data": "第 3 页"
                })))
              })
            ]
          })
        }),
        (this.__k4 || (this.__k4 = new SizedBox({
          "height": 10
        }))),
        new Row({
          "mainAxisAlignment": "center",
          "children": [
            ...(() => { var out = []; for (let i = 0; (i < 3); (i++)) { out.push.apply(out, [new Container({
                    "width": 9,
                    "height": 9,
                    "margin": {
                      "left": 4.0,
                      "top": 4.0,
                      "right": 4.0,
                      "bottom": 4.0
                    },
                    "decoration": {
                      "shape": "circle",
                      "color": ((i == this._page) ? Colors.deepPurple : new Color({value: 0xFFBDBDBD}))
                    }
                  })]); } return out; })()
          ]
        }),
        (this.__k5 || (this.__k5 = new SizedBox({
          "height": 8
        }))),
        new Row({
          "mainAxisAlignment": "center",
          "children": [
            new TextButton({
              "onPressed": this.__bindFn(1, [], (...__a) => this._prevPage(...__a)),
              "child": (this.__k6 || (this.__k6 = new Text({
                "data": "上一页"
              })))
            }),
            new TextButton({
              "onPressed": this.__bindFn(2, [], (...__a) => this._nextPage(...__a)),
              "child": (this.__k7 || (this.__k7 = new Text({
                "data": "下一页"
              })))
            }),
            new TextButton({
              "onPressed": this.__bindFn(3, [], (...__a) => this._jumpToLast(...__a)),
              "child": (this.__k8 || (this.__k8 = new Text({
                "data": "跳到第 3 页"
              })))
            })
          ]
        })
      ]
    });
  }
}

// 组件 KeyTile
export class KeyTile {
  constructor(args) {
    this.props = args || {};
    this.__applyProps(args);
    this._count = 0;
  }
  __applyProps(args) {
    this.index = (args && args.index !== undefined) ? args.index : 0;
    this.label = (args && args.label !== undefined) ? args.label : '';
  }
  bump() {
    this.setState(() => { this._count += 1; });
  }
  build(context) {
    var label = this.label;
    var caption = label + " · 计数 " + this._count;
    return new Container({
      "margin": {
        "left": 0.0,
        "top": 2.0,
        "right": 0.0,
        "bottom": 2.0
      },
      "padding": {
        "left": 10.0,
        "top": 2.0,
        "right": 10.0,
        "bottom": 2.0
      },
      "decoration": {
        "color": Colors.white,
        "borderRadius": {
          "radius": 6.0
        },
        "border": {
          "all": {
            "color": Colors.grey.shade300
          }
        }
      },
      "child": new Row({
        "children": [
          new Expanded({
            "child": new Text({
              "style": {
                "fontSize": 13
              },
              "data": caption
            })
          }),
          new TextButton({
            "onPressed": this.__bindFn(0, [], (...__a) => this.bump(...__a)),
            "child": (this.__k0 || (this.__k0 = new Text({
              "data": "+1"
            })))
          })
        ]
      })
    });
  }
}

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
      "crossAxisAlignment": "stretch",
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "① 带 key：key: ValueKey(name)",
          "style": {
            "fontSize": 13,
            "fontWeight": "bold"
          }
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
          "style": {
            "fontSize": 13,
            "fontWeight": "bold"
          }
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
      "crossAxisAlignment": "stretch",
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
      "margin": {
        "left": 12.0,
        "top": 6.0,
        "right": 12.0,
        "bottom": 6.0
      },
      "padding": {
        "left": 12.0,
        "top": 12.0,
        "right": 12.0,
        "bottom": 12.0
      },
      "decoration": {
        "color": Colors.grey.shade100,
        "borderRadius": {
          "radius": 10.0
        }
      },
      "child": new Column({
        "crossAxisAlignment": "stretch",
        "children": [
          (this.__k3 || (this.__k3 = new Text({
            "data": "ValueKey · 列表按值匹配",
            "style": {
              "color": Colors.deepPurple,
              "fontSize": 15,
              "fontWeight": "bold"
            }
          }))),
          (this.__k4 || (this.__k4 = new SizedBox({
            "height": 4
          }))),
          (this.__k5 || (this.__k5 = new Text({
            "data": "换序后看两列计数：① 的状态跟着「行（值）」走，② 的状态留在「位置」上——" + "reconciler 取 keySig（v:值）做「带 key 优先、无 key 按位置」的匹配。",
            "style": {
              "color": Colors.grey,
              "fontSize": 12
            }
          }))),
          (this.__k6 || (this.__k6 = new SizedBox({
            "height": 8
          }))),
          this._valueKeyRows(),
          (this.__k6 || (this.__k6 = new SizedBox({
            "height": 8
          }))),
          new Row({
            "children": [
              new TextButton({
                "onPressed": this.__bindFn(0, [], (...__a) => this._rotateNames(...__a)),
                "child": (this.__k7 || (this.__k7 = new Text({
                  "data": "轮换顺序（A→末尾）"
                })))
              }),
              (this.__k8 || (this.__k8 = new SizedBox({
                "width": 8
              }))),
              new TextButton({
                "onPressed": this.__bindFn(1, [], (...__a) => this._resetNames(...__a)),
                "child": (this.__k9 || (this.__k9 = new Text({
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
      "margin": {
        "left": 12.0,
        "top": 6.0,
        "right": 12.0,
        "bottom": 6.0
      },
      "padding": {
        "left": 12.0,
        "top": 12.0,
        "right": 12.0,
        "bottom": 12.0
      },
      "decoration": {
        "color": Colors.grey.shade100,
        "borderRadius": {
          "radius": 10.0
        }
      },
      "child": new Column({
        "crossAxisAlignment": "stretch",
        "children": [
          (this.__k10 || (this.__k10 = new Text({
            "data": "ObjectKey · 按对象身份相等",
            "style": {
              "color": Colors.deepPurple,
              "fontSize": 15,
              "fontWeight": "bold"
            }
          }))),
          (this.__k4 || (this.__k4 = new SizedBox({
            "height": 4
          }))),
          (this.__k11 || (this.__k11 = new Text({
            "data": "ObjectKey 的判据是 identical（是不是**同一个对象实例**），不是值相等。" + "A 行包的是字段里那个实例（跨帧恒定）→ 父级重建后元素复用、计数保留；" + "B 行每次 build 都新造一个 [1]（值一样但身份不同）→ 元素不匹配、销毁重建、计数归零。" + "注意：B 的计数是**被销毁**而不是被藏起来——归零之后回不来。",
            "style": {
              "color": Colors.grey,
              "fontSize": 12
            }
          }))),
          (this.__k6 || (this.__k6 = new SizedBox({
            "height": 8
          }))),
          this._objectKeyRows(),
          (this.__k6 || (this.__k6 = new SizedBox({
            "height": 8
          }))),
          (this.__k12 || (this.__k12 = new Text({
            "data": "操作：先给 A、B 各点几次 +1，再点下面的「父级重建」，对比两行的计数。" + "选型场景：数据源没有稳定 ID、但你跨帧持有同一批对象实例时用它。",
            "style": {
              "color": Colors.grey,
              "fontSize": 12
            }
          }))),
          (this.__k13 || (this.__k13 = new SizedBox({
            "height": 6
          }))),
          (this.__k14 || (this.__k14 = new Text({
            "data": "补充：Dart 里 ValueKey 按 == 比较、ObjectKey 按 identical 比较。" + "本例的 [1] 是 List，没有重写 ==（Dart 的 == 对 List 本就是身份比较），" + "所以这里两者结果相同——本案例要看的是「key 的身份稳不稳定」这件事本身。",
            "style": {
              "color": Colors.grey,
              "fontSize": 11
            }
          }))),
          (this.__k6 || (this.__k6 = new SizedBox({
            "height": 8
          }))),
          new Row({
            "children": [
              new TextButton({
                "onPressed": this.__bindFn(2, [], (...__a) => this._rebuildParent(...__a)),
                "child": (this.__k15 || (this.__k15 = new Text({
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
      "margin": {
        "left": 12.0,
        "top": 6.0,
        "right": 12.0,
        "bottom": 6.0
      },
      "padding": {
        "left": 12.0,
        "top": 12.0,
        "right": 12.0,
        "bottom": 12.0
      },
      "decoration": {
        "color": Colors.grey.shade100,
        "borderRadius": {
          "radius": 10.0
        }
      },
      "child": new Column({
        "crossAxisAlignment": "stretch",
        "children": [
          (this.__k16 || (this.__k16 = new Text({
            "data": "UniqueKey · 每次都是新身份",
            "style": {
              "color": Colors.deepPurple,
              "fontSize": 15,
              "fontWeight": "bold"
            }
          }))),
          (this.__k4 || (this.__k4 = new SizedBox({
            "height": 4
          }))),
          (this.__k17 || (this.__k17 = new Text({
            "data": "点「重建」触发 setState：子树的 UniqueKey 每次都是新实例（身份新 → 元素不匹配），" + "整棵子树重建、内部计数归零。",
            "style": {
              "color": Colors.grey,
              "fontSize": 12
            }
          }))),
          (this.__k6 || (this.__k6 = new SizedBox({
            "height": 8
          }))),
          new KeyTile({
            "index": 0,
            "label": "唯一身份行 #" + this._uniqueSeq,
            "key": new UniqueKey()
          }),
          (this.__k6 || (this.__k6 = new SizedBox({
            "height": 8
          }))),
          new Row({
            "children": [
              new TextButton({
                "onPressed": this.__bindFn(3, [], (...__a) => this._bumpUnique(...__a)),
                "child": (this.__k18 || (this.__k18 = new Text({
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
      "margin": {
        "left": 12.0,
        "top": 6.0,
        "right": 12.0,
        "bottom": 6.0
      },
      "padding": {
        "left": 12.0,
        "top": 12.0,
        "right": 12.0,
        "bottom": 12.0
      },
      "decoration": {
        "color": Colors.grey.shade100,
        "borderRadius": {
          "radius": 10.0
        }
      },
      "child": new Column({
        "crossAxisAlignment": "stretch",
        "children": [
          (this.__k19 || (this.__k19 = new Text({
            "data": "PageStorageKey · 滚动位置持久化",
            "style": {
              "color": Colors.deepPurple,
              "fontSize": 15,
              "fontWeight": "bold"
            }
          }))),
          (this.__k4 || (this.__k4 = new SizedBox({
            "height": 4
          }))),
          (this.__k20 || (this.__k20 = new Text({
            "data": "把 A 列表滚到中间 → 切到 B → 切回 A：位置应回到原处。" + "值本体走值 codec（__psk），宿主造真实 PageStorageKey，位置由宿主端 PageStorage 存取。",
            "style": {
              "color": Colors.grey,
              "fontSize": 12
            }
          }))),
          (this.__k6 || (this.__k6 = new SizedBox({
            "height": 8
          }))),
          this._storageView(),
          (this.__k6 || (this.__k6 = new SizedBox({
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
      "margin": {
        "left": 12.0,
        "top": 6.0,
        "right": 12.0,
        "bottom": 6.0
      },
      "padding": {
        "left": 12.0,
        "top": 12.0,
        "right": 12.0,
        "bottom": 12.0
      },
      "decoration": {
        "color": Colors.grey.shade100,
        "borderRadius": {
          "radius": 10.0
        }
      },
      "child": new Column({
        "crossAxisAlignment": "stretch",
        "children": [
          (this.__k21 || (this.__k21 = new Text({
            "data": "GlobalKey · 宿主端量测 / 定位",
            "style": {
              "color": Colors.deepPurple,
              "fontSize": 15,
              "fontWeight": "bold"
            }
          }))),
          (this.__k4 || (this.__k4 = new SizedBox({
            "height": 4
          }))),
          (this.__k22 || (this.__k22 = new Text({
            "data": "currentContext → findRenderObject 这条链两端同形，但「值」只能在宿主算：" + "位置与尺寸经异步桥回填（box.measure()），定位用真实 RenderObject 的 showOnScreen。",
            "style": {
              "color": Colors.grey,
              "fontSize": 12
            }
          }))),
          (this.__k6 || (this.__k6 = new SizedBox({
            "height": 8
          }))),
          new Container({
            "padding": {
              "left": 10.0,
              "top": 10.0,
              "right": 10.0,
              "bottom": 10.0
            },
            "decoration": {
              "color": Colors.teal.shade50,
              "borderRadius": {
                "radius": 6.0
              }
            },
            "child": (this.__k23 || (this.__k23 = new Text({
              "data": "目标盒子（GlobalKey 挂在这里）",
              "style": {
                "fontSize": 13
              }
            }))),
            "key": this._targetKey
          }),
          (this.__k6 || (this.__k6 = new SizedBox({
            "height": 8
          }))),
          new Text({
            "style": {
              "fontSize": 13,
              "color": Colors.teal
            },
            "data": "测量：" + this._measureText
          }),
          (this.__k4 || (this.__k4 = new SizedBox({
            "height": 4
          }))),
          new Row({
            "children": [
              new TextButton({
                "onPressed": this.__bindFn(5, [], (...__a) => this._measureTarget(...__a)),
                "child": (this.__k24 || (this.__k24 = new Text({
                  "data": "测量位置与尺寸"
                })))
              }),
              (this.__k8 || (this.__k8 = new SizedBox({
                "width": 8
              }))),
              new TextButton({
                "onPressed": this.__bindFn(6, [], (...__a) => this._scrollToTarget(...__a)),
                "child": (this.__k25 || (this.__k25 = new Text({
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
        "title": (this.__k26 || (this.__k26 = new Text({
          "data": "Key 家族 · 全部用例"
        }))),
        "backgroundColor": Colors.deepPurple,
        "foregroundColor": Colors.white
      }),
      "body": new ListView({
        "children": [
          (this.__k27 || (this.__k27 = new Padding({
            "child": new Text({
              "style": {
                "fontSize": 12,
                "color": Colors.grey
              },
              "data": "每一张卡片一种 key 的语义；「计数」是 KeyTile 的内部 State，" + "用它来观察状态是跟着行走还是跟着位置走。"
            }),
            "padding": {
              "bottom": 0.0,
              "left": 12.0,
              "right": 12.0,
              "top": 12.0
            }
          }))),
          this._cardValueKey(),
          this._cardObjectKey(),
          this._cardUniqueKey(),
          this._cardStorageKey(),
          this._cardGlobalKey(),
          (this.__k28 || (this.__k28 = new SizedBox({
            "height": 24
          })))
        ]
      })
    });
  }
}

// 组件 DrawerDetail
export class DrawerDetail {
  constructor(args) {
    this.props = args || {};
    this._picked = (-1);
  }
  _pickOrders() {
    this.setState(() => { this._picked = 0; });
  }
  _pickFavorites() {
    this.setState(() => { this._picked = 1; });
  }
  _pickSettings() {
    this.setState(() => { this._picked = 2; });
  }
  _pickHelp() {
    this.setState(() => { this._picked = 3; });
  }
  build(context) {
    return new Scaffold({
      "backgroundColor": Colors.grey.shade50,
      "appBar": new AppBar({
        "title": (this.__k0 || (this.__k0 = new Text({
          "data": "Drawer / endDrawer"
        }))),
        "backgroundColor": Colors.indigo,
        "foregroundColor": Colors.white
      }),
      "drawer": new Drawer({
        "child": new ListView({
          "children": [
            new DrawerHeader({
              "decoration": {
                "color": Colors.indigo
              },
              "child": (this.__k1 || (this.__k1 = new Align({
                "alignment": "bottomLeft",
                "child": new Text({
                  "style": {
                    "color": Colors.white,
                    "fontSize": 20
                  },
                  "data": "左侧抽屉"
                })
              })))
            }),
            new ListTile({
              "leading": (this.__k2 || (this.__k2 = new Icon({
                "icon": "receipt_long"
              }))),
              "title": (this.__k3 || (this.__k3 = new Text({
                "data": "我的订单"
              }))),
              "onTap": this.__bindFn(0, [], (...__a) => this._pickOrders(...__a))
            }),
            new ListTile({
              "leading": (this.__k4 || (this.__k4 = new Icon({
                "icon": "favorite_border"
              }))),
              "title": (this.__k5 || (this.__k5 = new Text({
                "data": "我的收藏"
              }))),
              "onTap": this.__bindFn(1, [], (...__a) => this._pickFavorites(...__a))
            })
          ]
        })
      }),
      "endDrawer": new Drawer({
        "child": new ListView({
          "children": [
            new DrawerHeader({
              "decoration": {
                "color": Colors.teal
              },
              "child": (this.__k6 || (this.__k6 = new Align({
                "alignment": "bottomLeft",
                "child": new Text({
                  "style": {
                    "color": Colors.white,
                    "fontSize": 20
                  },
                  "data": "右侧抽屉"
                })
              })))
            }),
            new ListTile({
              "leading": (this.__k7 || (this.__k7 = new Icon({
                "icon": "settings"
              }))),
              "title": (this.__k8 || (this.__k8 = new Text({
                "data": "设置"
              }))),
              "onTap": this.__bindFn(2, [], (...__a) => this._pickSettings(...__a))
            }),
            new ListTile({
              "leading": (this.__k9 || (this.__k9 = new Icon({
                "icon": "help_outline"
              }))),
              "title": (this.__k10 || (this.__k10 = new Text({
                "data": "帮助与关于"
              }))),
              "onTap": this.__bindFn(3, [], (...__a) => this._pickHelp(...__a))
            })
          ]
        })
      }),
      "body": new Center({
        "child": new Column({
          "mainAxisAlignment": "center",
          "children": [
            (this.__k11 || (this.__k11 = new Icon({
              "color": Colors.indigo,
              "icon": "menu_open",
              "size": 48
            }))),
            (this.__k12 || (this.__k12 = new SizedBox({
              "height": 12
            }))),
            (this.__k13 || (this.__k13 = new Text({
              "data": "AppBar 左侧为汉堡按钮，右侧为 endDrawer 入口"
            }))),
            (this.__k14 || (this.__k14 = new SizedBox({
              "height": 8
            }))),
            new Text({
              "data": (this._picked < 0) ? "尚未选择菜单项" : "选中菜单项 #" + this._picked
            })
          ]
        })
      })
    });
  }
}

// 组件 ReorderListDetail
export class ReorderListDetail {
  constructor(args) {
    this.props = args || {};
    this._items = ["北京", "上海", "广州", "深圳", "杭州", "成都"];
    this._controller = new ScrollController();
  }
  _onReorder(oldIndex, newIndex) {
    console.log(__str(oldIndex) + " - " + __str(newIndex));
    this.setState(() => { var item = this._items.removeAt(oldIndex); var target = ((newIndex > oldIndex) ? (newIndex - 1) : newIndex); this._items.insert(target, item); });
  }
  _add() {
    this.setState(() => { this._items.add("城市 " + (this._items.length + 1)); });
  }
  build(context) {
    return new Column({
      "mainAxisSize": "min",
      "children": [
        new Padding({
          "padding": {
            "left": 12.0,
            "top": 12.0,
            "right": 12.0,
            "bottom": 12.0
          },
          "child": new Row({
            "children": [
              (this.__k0 || (this.__k0 = new Expanded({
                "child": new Text({
                  "style": {
                    "fontSize": 13,
                    "color": Colors.grey
                  },
                  "data": "长按拖拽调整顺序（onReorder 双参事件）"
                })
              }))),
              new ElevatedButton({
                "onPressed": this.__bindFn(0, [], (...__a) => this._add(...__a)),
                "child": (this.__k1 || (this.__k1 = new Text({
                  "data": "添加"
                })))
              })
            ]
          })
        }),
        new SizedBox({
          "height": 320,
          "child": ReorderableListView.builder({
            "scrollController": this._controller,
            "onReorder": this.__bindFn(1, [], (...__a) => this._onReorder(...__a)),
            "padding": {
              "left": 12.0,
              "top": 0.0,
              "right": 12.0,
              "bottom": 0.0
            },
            "itemCount": this._items.length,
            "itemBuilder": (context, index) => {
              var item = this._items[index];
              return new Card({
                "child": new ListTile({
                  "leading": (this.__k2 || (this.__k2 = new Icon({
                    "icon": "drag_handle"
                  }))),
                  "title": new Text({
                    "data": item
                  })
                }),
                "key": new ValueKey({value: item})
              });
            }
          })
        })
      ]
    });
  }
  dispose() {
    this._controller.dispose();
  }
}

// 组件 TestWidget
export class TestWidget {
  constructor(args) {
    this.props = args || {};
  }
  build(context) {
    var text = new Text({data: "局部变量 widget"});
    var card = new StatelessCard({title: "局部自定义组件", subtitle: "StatelessCard 变量", badge: "VAR"});
    var items = [new Text({data: "列表项 A"}), new Text({data: "列表项 B"})];
    return new Center({
      "child": new Column({
        "mainAxisSize": "min",
        "children": [
          text,
          (this.__k0 || (this.__k0 = new SizedBox({
            "height": 8
          }))),
          card,
          (this.__k0 || (this.__k0 = new SizedBox({
            "height": 8
          }))),
          ...items
        ]
      })
    });
  }
}

