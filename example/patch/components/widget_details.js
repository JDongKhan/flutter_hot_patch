// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/widget_details.dart 自动生成
// 重新生成：dart run build_runner build

import { CounterVm } from '../model/counter_vm.js';
import { Align, AppBar, AspectRatio, BottomNavigationBar, BottomNavigationBarItem, CachedNetworkImage, Card, Center, Checkbox, Chip, CircleAvatar, CircularProgressIndicator, ClipRRect, Column, ConstrainedBox, Container, CustomScrollView, DecoratedBox, DefaultTabController, Divider, Drawer, DrawerHeader, DropdownButton, DropdownMenuItem, ElevatedButton, Expanded, FilledButton, FloatingActionButton, FractionallySizedBox, GridView, Icon, IconButton, Image, InputDecoration, LinearProgressIndicator, ListTile, ListView, ListenableBuilder, NotificationListener, Opacity, OutlinedButton, Padding, Positioned, Radio, ReorderableListView, Row, SafeArea, Scaffold, SingleChildScrollView, SizedBox, Slider, SliverAppBar, SliverFillRemaining, SliverFixedExtentList, SliverGrid, SliverList, SliverOpacity, SliverPadding, SliverSafeArea, SliverToBoxAdapter, Spacer, Stack, Switch, Tab, TabBar, TabBarView, Text, TextButton, TextField, Wrap, __h } from '../flutter.js';

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
          new Text({
              "style": {
                "fontSize": 16,
                "fontWeight": "bold"
              },
              "data": "基础文案 + TextStyle"
            }),
          new Text({
              "style": {
                "color": '#2196F3',
                "fontSize": 16
              },
              "data": "普通文本，count = " + this._count + "（状态插值）"
            }),
          new SizedBox({
              "height": 6
            }),
          new Text({
              "maxLines": 1,
              "overflow": "ellipsis",
              "data": "maxLines+overflow 测试：这是一段很长的文字会被截断成省略号显示"
            }),
          new SizedBox({
              "height": 6
            }),
          new Text({
              "textScaler": {
                "linear": 1.6
              },
              "data": "textScaler.linear(1.6) 放大"
            }),
          new SizedBox({
              "height": 6
            }),
          new Text({
              "textAlign": "center",
              "style": {
                "decoration": "underline",
                "decorationColor": '#FF9800',
                "decorationStyle": "wavy"
              },
              "data": "textAlign 居中,He said \"hi\""
            }),
          new SizedBox({
              "height": 6
            }),
          new Text({
              "softWrap": false,
              "style": {
                "fontSize": 12,
                "color": '#9E9E9E',
                "wordSpacing": 2,
                "letterSpacing": 1,
                "backgroundColor": '#ffffe082'
              },
              "data": "softWrap=false 不换行测试"
            }),
          new SizedBox({
              "height": 6
            }),
          new TextButton({
              "onPressed": this.__bindFn(0, [], (...__a) => this.bump(...__a)),
              "child": new Text({
                  "data": "Bump count"
                })
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
          new SizedBox({
              "height": 8
            }),
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
                "shadowColor": '#673AB7',
                "textStyle": {
                  "fontSize": 18,
                  "fontWeight": "bold",
                  "letterSpacing": 2
                },
                "backgroundColor": '#009688',
                "foregroundColor": '#FFFFFF'
              },
              "child": new Text({
                  "data": "Elevated · Styled"
                })
            }),
          new SizedBox({
              "height": 8
            }),
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
                "foregroundColor": '#3F51B5'
              },
              "child": new Text({
                  "data": "TextButton"
                })
            }),
          new SizedBox({
              "height": 8
            }),
          new OutlinedButton({
              "onPressed": this.__bindFn(2, [], (...__a) => this.onTap(...__a)),
              "style": {
                "side": {
                  "color": '#FF9800',
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
                "foregroundColor": '#FF5722'
              },
              "child": new Text({
                  "data": "OutlinedButton"
                })
            }),
          new SizedBox({
              "height": 8
            }),
          new ElevatedButton({
              "child": new Text({
                  "data": "Disabled"
                })
            })
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
          new Text({
              "style": {
                "fontSize": 16,
                "fontWeight": "bold"
              },
              "data": "Row + Expanded / Flexible / Spacer"
            }),
          new Row({
              "children": [
                new Expanded({
                    "flex": 1,
                    "child": new Container({
                        "color": '#BBDEFB',
                        "padding": {
                          "left": 8.0,
                          "top": 8.0,
                          "right": 8.0,
                          "bottom": 8.0
                        },
                        "child": new Text({
                            "textAlign": "center",
                            "data": "A"
                          })
                      })
                  }),
                new Spacer({
                    "flex": 1
                  }),
                new Expanded({
                    "flex": 2,
                    "child": new Container({
                        "color": '#C8E6C9',
                        "padding": {
                          "left": 8.0,
                          "top": 8.0,
                          "right": 8.0,
                          "bottom": 8.0
                        },
                        "child": new Text({
                            "textAlign": "center",
                            "data": "B（flex=2）"
                          })
                      })
                  })
              ]
            }),
          new SizedBox({
              "height": 12
            }),
          new Text({
              "style": {
                "fontSize": 16,
                "fontWeight": "bold"
              },
              "data": "Center / Align / Padding / SizedBox"
            }),
          new Center({
              "child": new Container({
                  "color": '#FFECB3',
                  "padding": {
                    "left": 12.0,
                    "top": 12.0,
                    "right": 12.0,
                    "bottom": 12.0
                  },
                  "child": new Text({
                      "data": "Center 居中"
                    })
                })
            }),
          new SizedBox({
              "height": 8
            }),
          new Align({
              "alignment": "centerLeft",
              "child": new Container({
                  "color": '#F3E5F5',
                  "padding": {
                    "left": 8.0,
                    "top": 8.0,
                    "right": 8.0,
                    "bottom": 8.0
                  },
                  "child": new Text({
                      "data": "Align centerLeft"
                    })
                })
            }),
          new SizedBox({
              "height": 8
            }),
          new Padding({
              "padding": {
                "left": 8.0,
                "top": 4.0,
                "right": 8.0,
                "bottom": 4.0
              },
              "child": new Text({
                  "data": "Padding 包裹文案"
                })
            }),
          new SizedBox({
              "height": 12
            }),
          new Text({
              "style": {
                "fontSize": 16,
                "fontWeight": "bold"
              },
              "data": "Stack + Positioned"
            }),
          new SizedBox({
              "height": 100,
              "child": new Stack({
                  "fit": "expand",
                  "clipBehavior": "hardEdge",
                  "children": [
                    new Container({
                        "color": '#EEEEEE'
                      }),
                    new Positioned({
                        "child": new Center({
                            "child": new Text({
                                "style": {
                                  "color": '#FFFFFF',
                                  "fontWeight": "bold"
                                },
                                "data": "FILL"
                              })
                          }),
                        "factory": "fill"
                      }),
                    new Positioned({
                        "left": 12,
                        "top": 12,
                        "child": new Text({
                            "data": "TL"
                          })
                      }),
                    new Positioned({
                        "right": 12,
                        "bottom": 12,
                        "child": new Text({
                            "data": "BR"
                          })
                      })
                  ]
                })
            }),
          new SizedBox({
              "height": 12
            }),
          new Text({
              "style": {
                "fontSize": 16,
                "fontWeight": "bold"
              },
              "data": "Wrap · 自动换行"
            }),
          new Wrap({
              "direction": "horizontal",
              "spacing": 8,
              "runSpacing": 8,
              "alignment": "start",
              "runAlignment": "center",
              "crossAxisAlignment": "center",
              "children": [
                ...(() => { var out = []; for (let i = 1; (i <= 5); (i++)) { out.push.apply(out, [new Chip({ "label": new Text({ "data": "chip " + i }), "backgroundColor": '#E0F2F1' })]); } return out; })()
              ]
            }),
          new SizedBox({
              "height": 12
            }),
          new Text({
              "style": {
                "fontSize": 16,
                "fontWeight": "bold"
              },
              "data": "Opacity / ConstrainedBox / AspectRatio / FractionallySizedBox"
            }),
          new Opacity({
              "opacity": 0.5,
              "child": new Container({
                  "color": '#F44336',
                  "padding": {
                    "left": 8.0,
                    "top": 8.0,
                    "right": 8.0,
                    "bottom": 8.0
                  },
                  "child": new Text({
                      "data": "50% 透明"
                    })
                })
            }),
          new SizedBox({
              "height": 8
            }),
          new ConstrainedBox({
              "constraints": {
                "minWidth": 120,
                "maxWidth": 200
              },
              "child": new Container({
                  "color": '#FFE0B2',
                  "padding": {
                    "left": 8.0,
                    "top": 8.0,
                    "right": 8.0,
                    "bottom": 8.0
                  },
                  "child": new Text({
                      "data": "ConstrainedBox 宽度 120-200"
                    })
                })
            }),
          new SizedBox({
              "height": 8
            }),
          new AspectRatio({
              "aspectRatio": 1.78,
              "child": new Container({
                  "color": '#C5CAE9',
                  "alignment": "center",
                  "child": new Text({
                      "data": "16:9 比例"
                    })
                })
            }),
          new SizedBox({
              "height": 8
            }),
          new FractionallySizedBox({
              "widthFactor": 0.6,
              "alignment": "center",
              "child": new Container({
                  "color": '#F8BBD0',
                  "padding": {
                    "left": 8.0,
                    "top": 8.0,
                    "right": 8.0,
                    "bottom": 8.0
                  },
                  "child": new Text({
                      "textAlign": "center",
                      "data": "60% 宽度"
                    })
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
          new Text({
              "style": {
                "fontSize": 16,
                "fontWeight": "bold"
              },
              "data": "Image · 网络图片"
            }),
          new ClipRRect({
              "borderRadius": {
                "radius": 12.0
              },
              "child": new Image({
                  "height": 120,
                  "fit": "cover",
                  "factory": "network",
                  "src": "https://picsum.photos/seed/hotpatch/400/160"
                })
            }),
          new SizedBox({
              "height": 12
            }),
          new Text({
              "style": {
                "fontSize": 16,
                "fontWeight": "bold"
              },
              "data": "CachedNetworkImage · 磁盘缓存网络图"
            }),
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
          new SizedBox({
              "height": 12
            }),
          new Text({
              "style": {
                "fontSize": 16,
                "fontWeight": "bold"
              },
              "data": "Icon / CircleAvatar"
            }),
          new Row({
              "children": [
                new Icon({
                    "color": '#FFC107',
                    "size": 28,
                    "icon": "star"
                  }),
                new SizedBox({
                    "width": 12
                  }),
                new Icon({
                    "color": '#2196F3',
                    "size": 28,
                    "icon": "home"
                  }),
                new SizedBox({
                    "width": 12
                  }),
                new Icon({
                    "color": '#F44336',
                    "size": 28,
                    "icon": "favorite"
                  }),
                new SizedBox({
                    "width": 12
                  }),
                new CircleAvatar({
                    "radius": 20,
                    "backgroundColor": '#009688',
                    "child": new Text({
                        "style": {
                          "color": '#FFFFFF'
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
          new Text({
              "style": {
                "fontSize": 16,
                "fontWeight": "bold"
              },
              "data": "Container · 颜色/圆角/Padding"
            }),
          new Container({
              "padding": {
                "left": 16.0,
                "top": 16.0,
                "right": 16.0,
                "bottom": 16.0
              },
              "decoration": {
                "color": '#009688',
                "borderRadius": {
                  "radius": 12.0
                }
              },
              "child": new Text({
                  "style": {
                    "color": '#FFFFFF'
                  },
                  "data": "容器内容（teal 圆角）"
                })
            }),
          new SizedBox({
              "height": 12
            }),
          new Text({
              "style": {
                "fontSize": 16,
                "fontWeight": "bold"
              },
              "data": "Container · 边框 + 阴影 + 渐变"
            }),
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
                    '#2196F3',
                    '#9C27B0'
                  ],
                  "begin": "topLeft",
                  "end": "bottomRight"
                },
                "borderRadius": {
                  "radius": 16.0
                },
                "border": {
                  "all": {
                    "color": '#FFFFFF',
                    "width": 2
                  }
                },
                "boxShadow": [
                  {
                    "color": '#66000000',
                    "dx": 0,
                    "dy": 4,
                    "blur": 12,
                    "spread": 1
                  }
                ]
              },
              "child": new Text({
                  "style": {
                    "color": '#FFFFFF'
                  },
                  "data": "渐变 + 边框 + 阴影"
                })
            }),
          new SizedBox({
              "height": 12
            }),
          new Text({
              "style": {
                "fontSize": 16,
                "fontWeight": "bold"
              },
              "data": "DecoratedBox · 纯装饰"
            }),
          new DecoratedBox({
              "decoration": {
                "color": '#FFECB3',
                "border": {
                  "all": {
                    "color": '#FFC107',
                    "width": 2
                  }
                },
                "borderRadius": {
                  "radius": 8.0
                }
              },
              "child": new Padding({
                  "padding": {
                    "left": 12.0,
                    "top": 12.0,
                    "right": 12.0,
                    "bottom": 12.0
                  },
                  "child": new Text({
                      "data": "DecoratedBox 内容"
                    })
                })
            }),
          new SizedBox({
              "height": 12
            }),
          new Text({
              "style": {
                "fontSize": 16,
                "fontWeight": "bold"
              },
              "data": "Card · shape / clipBehavior"
            }),
          new Card({
              "elevation": 4,
              "shadowColor": '#673AB7',
              "shape": {
                "kind": "rounded",
                "borderRadius": {
                  "radius": 16.0
                },
                "side": {
                  "color": '#673AB7',
                  "width": 1
                }
              },
              "clipBehavior": "antiAlias",
              "child": new Padding({
                  "padding": {
                    "left": 16.0,
                    "top": 16.0,
                    "right": 16.0,
                    "bottom": 16.0
                  },
                  "child": new Text({
                      "data": "圆角卡片 + 描边 + 阴影"
                    })
                })
            }),
          new SizedBox({
              "height": 12
            }),
          new Divider({}),
          new SizedBox({
              "height": 12
            }),
          new Text({
              "style": {
                "fontSize": 16,
                "fontWeight": "bold"
              },
              "data": "SizedBox · 尺寸约束"
            }),
          new Container({
              "width": 120,
              "height": 48,
              "alignment": "center",
              "color": '#CFD8DC',
              "child": new Text({
                  "data": "固定 120×48"
                })
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
                  "child": new ListView({
                      "padding": {
                        "left": 8.0,
                        "top": 8.0,
                        "right": 8.0,
                        "bottom": 8.0
                      },
                      "itemExtent": 56,
                      "physics": "BouncingScrollPhysics",
                      "itemCount": 5,
                      "itemBuilder": "_itemBuilder0",
                      "factory": "builder"
                    })
                }),
              "model": "ScrollNotification"
            }),
          new SizedBox({
              "height": 12
            }),
          new Text({
              "style": {
                "fontSize": 16,
                "fontWeight": "bold"
              },
              "data": "ListView.separated · 分隔列表"
            }),
          new SizedBox({
              "height": 140,
              "child": new ListView({
                  "padding": {
                    "left": 8.0,
                    "top": 8.0,
                    "right": 8.0,
                    "bottom": 8.0
                  },
                  "itemCount": 6,
                  "separatorBuilder": "_separatorBuilder1",
                  "itemBuilder": "_itemBuilder2",
                  "factory": "separated"
                })
            }),
          new SizedBox({
              "height": 12
            }),
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
                    ...(() => { var out = []; for (let i = 1; (i <= 8); (i++)) { out.push.apply(out, [new Padding({ "padding": { "left": 4.0, "top": 4.0, "right": 4.0, "bottom": 4.0 }, "child": new Chip({ "label": new Text({ "data": "横向 " + i }) }) })]); } return out; })()
                  ]
                })
            }),
          new Align({
              "alignment": "centerLeft",
              "child": new TextButton({
                  "onPressed": this.__bindFn(1, [], (...__a) => this._scrollToEnd(...__a)),
                  "child": new Text({
                      "data": "横向 · 跳到底"
                    })
                })
            })
        ]
      });
  }
  _itemBuilder0(context, index) {
      return new ListTile({
        "leading": new Icon({
            "icon": "list"
          }),
        "title": new Text({
            "data": "builder item " + index
          })
      });
  }
  _separatorBuilder1(context, index) {
      return new Divider({
        "height": 1
      });
  }
  _itemBuilder2(context, index) {
      return new ListTile({
        "dense": true,
        "leading": new Icon({
            "color": '#4DB6AC',
            "icon": "arrow_right"
          }),
        "title": new Text({
            "data": "separated item " + index
          })
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
                  "backgroundColor": '#673AB7',
                  "foregroundColor": '#FFFFFF',
                  "pinned": true,
                  "floating": true,
                  "actions": [
                    new IconButton({
                        "icon": new Icon({
                            "icon": "center_focus_strong"
                          }),
                        "tooltip": "定位到「固定高度」分区",
                        "onPressed": this.__bindFn(0, [], (...__a) => this._scrollToFixed(...__a))
                      }),
                    new IconButton({
                        "icon": new Icon({
                            "icon": "straighten"
                          }),
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
                        "color": '#EDE7F6',
                        "borderRadius": {
                          "radius": 12.0
                        }
                      },
                      "child": new Text({
                          "style": {
                            "fontSize": 14,
                            "fontWeight": "bold"
                          },
                          "data": "CustomScrollView 整页 · SliverToBoxAdapter 盒子"
                        })
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
                        "color": '#E0F2F1',
                        "borderRadius": {
                          "radius": 8.0
                        }
                      },
                      "child": new Text({
                          "style": {
                            "fontSize": 13,
                            "color": '#009688'
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
                  "sliver": __h('SliverList', {
                      "delegate": {
                        "__delegate": "list",
                        "children": [
                          ...(() => { var out = []; for (let i = 1; (i <= 5); (i++)) { out.push.apply(out, [new ListTile({ "leading": new Icon({ "color": '#673AB7', "icon": "list" }), "title": new Text({ "data": "SliverList item " + i }), "trailing": new Icon({ "icon": "chevron_right" }) })]); } return out; })()
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
                  "sliver": new SliverList({
                      "itemCount": 8,
                      "itemBuilder": "_itemBuilder0",
                      "factory": "builder"
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
                  "sliver": new SliverList({
                      "itemCount": 5,
                      "itemBuilder": "_itemBuilder1",
                      "separatorBuilder": "_separatorBuilder2",
                      "factory": "separated"
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
                            "color": '#E0F2F1',
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
                        "builder": "_builder3",
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
                      "sliver": new SliverGrid({
                          "gridDelegate": {
                            "maxCrossAxisExtent": 140,
                            "mainAxisSpacing": 8,
                            "crossAxisSpacing": 8,
                            "childAspectRatio": 1
                          },
                          "itemCount": 9,
                          "itemBuilder": "_itemBuilder4",
                          "factory": "builder"
                        })
                    })
                }),
              new SliverSafeArea({
                  "sliver": new SliverFillRemaining({
                      "hasScrollBody": false,
                      "child": new Center({
                          "child": new Text({
                              "style": {
                                "color": '#9E9E9E'
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
            "backgroundColor": '#673AB7',
            "foregroundColor": '#FFFFFF',
            "tooltip": "跳到底",
            "child": new Icon({
                "icon": "arrow_downward"
              })
          })
      });
  }
  _itemBuilder0(context, index) {
      return new ListTile({
        "leading": new Icon({
            "color": '#F57C00',
            "icon": "build"
          }),
        "title": new Text({
            "data": "builder item " + index
          }),
        "subtitle": new Text({
            "data": "index * 10 = " + (index * 10)
          })
      });
  }
  _itemBuilder1(context, index) {
      return new ListTile({
        "dense": true,
        "leading": new Icon({
            "color": '#673AB7',
            "icon": "arrow_right"
          }),
        "title": new Text({
            "data": "separated item " + index
          })
      });
  }
  _separatorBuilder2(context, index) {
      return new Divider({
        "height": 1
      });
  }
  _builder3(context, index) {
      return new ListTile({
        "dense": true,
        "leading": new Icon({
            "color": '#009688',
            "icon": "height"
          }),
        "title": new Text({
            "data": "fixed item " + index
          })
      });
  }
  _itemBuilder4(context, index) {
      return new Container({
        "decoration": {
          "color": '#B2DFDB',
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
        "backgroundColor": '#FAFAFA',
        "appBar": new AppBar({
            "title": new Text({
                "data": "GridView 懒加载验证"
              }),
            "backgroundColor": '#009688',
            "foregroundColor": '#FFFFFF'
          }),
        "floatingActionButton": new FloatingActionButton({
            "onPressed": this.__bindFn(0, [], (...__a) => this._jumpBottom(...__a)),
            "backgroundColor": '#009688',
            "foregroundColor": '#FFFFFF',
            "tooltip": "跳到底",
            "child": new Icon({
                "icon": "arrow_downward"
              })
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
                        "color": '#9E9E9E'
                      },
                      "data": "controller offset: " + this._offset.toStringAsFixed(1)
                    })
                }),
              new Padding({
                  "padding": {
                    "left": 12.0,
                    "top": 0.0,
                    "right": 12.0,
                    "bottom": 0.0
                  },
                  "child": new Text({
                      "style": {
                        "fontSize": 14,
                        "fontWeight": "bold"
                      },
                      "data": "GridView.builder · 固定 3 列 · 30 项（懒加载）"
                    })
                }),
              new Expanded({
                  "flex": 5,
                  "child": new GridView({
                      "controller": this._controller,
                      "gridDelegate": {
                        "crossAxisCount": 3,
                        "mainAxisSpacing": 8,
                        "crossAxisSpacing": 8,
                        "childAspectRatio": 1
                      },
                      "itemCount": 30,
                      "itemBuilder": "_itemBuilder0",
                      "factory": "builder"
                    })
                }),
              new Padding({
                  "padding": {
                    "left": 12.0,
                    "top": 8.0,
                    "right": 12.0,
                    "bottom": 8.0
                  },
                  "child": new Text({
                      "style": {
                        "fontSize": 14,
                        "fontWeight": "bold"
                      },
                      "data": "GridView.builder · MaxCrossAxisExtent 120 · 20 项（懒加载）"
                    })
                }),
              new Expanded({
                  "flex": 4,
                  "child": new GridView({
                      "gridDelegate": {
                        "maxCrossAxisExtent": 120,
                        "mainAxisSpacing": 8,
                        "crossAxisSpacing": 8,
                        "childAspectRatio": 1
                      },
                      "itemCount": 20,
                      "itemBuilder": "_itemBuilder1",
                      "factory": "builder"
                    })
                })
            ]
          })
      });
  }
  _itemBuilder0(context, index) {
      return new Container({
        "decoration": {
          "color": '#B2DFDB',
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
      });
  }
  _itemBuilder1(context, index) {
      return new Container({
        "decoration": {
          "color": '#FFE0B2',
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
        "backgroundColor": '#FAFAFA',
        "appBar": new AppBar({
            "leading": new Icon({
                "icon": "menu"
              }),
            "title": new Text({
                "data": "Scaffold / AppBar / FAB / BottomNav"
              }),
            "backgroundColor": '#673AB7',
            "foregroundColor": '#FFFFFF',
            "elevation": 4,
            "centerTitle": true,
            "toolbarHeight": 56,
            "actions": [
              new Icon({
                  "color": '#FFFFFF',
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
                      new Icon({
                          "size": 48,
                          "color": '#673AB7',
                          "icon": "extension"
                        }),
                      new SizedBox({
                          "height": 12
                        }),
                      new Text({
                          "data": "页面骨架组件演示"
                        }),
                      new Text({
                          "data": "BottomNav 选中：" + this._navIndex
                        })
                    ]
                  })
              })
          }),
        "floatingActionButton": new FloatingActionButton({
            "onPressed": this.__bindFn(0, [], (...__a) => this._onFab(...__a)),
            "backgroundColor": '#673AB7',
            "foregroundColor": '#FFFFFF',
            "tooltip": "添加",
            "child": new Icon({
                "icon": "add"
              })
          }),
        "bottomNavigationBar": new BottomNavigationBar({
            "currentIndex": this._navIndex,
            "onTap": this.__bindFn(1, [], (...__a) => this._onNavTap(...__a)),
            "selectedItemColor": '#673AB7',
            "unselectedItemColor": '#9E9E9E',
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
          new Text({
              "style": {
                "fontSize": 16,
                "fontWeight": "bold"
              },
              "data": "TextField"
            }),
          new TextField({
              "controller": this._controller,
              "onChanged": this.__bindFn(0, [], (...__a) => this._onTextChanged(...__a)),
              "decoration": new InputDecoration({
                  "hintText": "请输入文本",
                  "labelText": "用户名"
                }),
              "maxLines": 1,
              "style": {
                "fontSize": 16
              }
            }),
          new SizedBox({
              "height": 4
            }),
          new Text({
              "style": {
                "fontSize": 14,
                "color": '#9E9E9E'
              },
              "data": "输入内容：" + this._text
            }),
          new Text({
              "style": {
                "fontSize": 14,
                "color": '#673AB7'
              },
              "data": "controller.text：" + this._controller.text
            }),
          new SizedBox({
              "height": 8
            }),
          new Align({
              "alignment": "centerLeft",
              "child": new FilledButton({
                  "onPressed": this.__bindFn(1, [], () => this._controller.clear()),
                  "child": new Text({
                      "data": "清空输入"
                    })
                })
            }),
          new SizedBox({
              "height": 12
            }),
          new Text({
              "style": {
                "fontSize": 16,
                "fontWeight": "bold"
              },
              "data": "Radio 单选"
            }),
          new Row({
              "children": [
                new Radio({
                    "value": "A",
                    "groupValue": this._choice,
                    "onChanged": this.__bindFn(2, [], (...__a) => this._onChoiceChanged(...__a)),
                    "activeColor": '#673AB7'
                  }),
                new Text({
                    "data": "选项 A"
                  }),
                new Radio({
                    "value": "B",
                    "groupValue": this._choice,
                    "onChanged": this.__bindFn(3, [], (...__a) => this._onChoiceChanged(...__a)),
                    "activeColor": '#673AB7'
                  }),
                new Text({
                    "data": "选项 B"
                  })
              ]
            }),
          new Text({
              "style": {
                "fontSize": 14,
                "color": '#9E9E9E'
              },
              "data": "当前选择：" + this._choice
            }),
          new SizedBox({
              "height": 12
            }),
          new Text({
              "style": {
                "fontSize": 16,
                "fontWeight": "bold"
              },
              "data": "DropdownButton"
            }),
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
          new SizedBox({
              "height": 12
            }),
          new Row({
              "children": [
                new Switch({
                    "value": this._switchOn,
                    "onChanged": this.__bindFn(5, [], (...__a) => this._onSwitchChanged(...__a)),
                    "activeColor": '#FFFFFF',
                    "activeTrackColor": '#673AB7',
                    "inactiveThumbColor": '#9E9E9E',
                    "inactiveTrackColor": '#E0E0E0'
                  }),
                new SizedBox({
                    "width": 8
                  }),
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
                    "activeColor": '#673AB7',
                    "checkColor": '#FFFFFF'
                  }),
                new SizedBox({
                    "width": 8
                  }),
                new Text({
                    "data": "Checkbox：" + (this._checked ?? false)
                  })
              ]
            }),
          new SizedBox({
              "height": 8
            }),
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
              "activeColor": '#673AB7',
              "inactiveColor": '#E0E0E0',
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
          new Text({
              "style": {
                "fontSize": 16,
                "fontWeight": "bold"
              },
              "data": "CircularProgressIndicator"
            }),
          new SizedBox({
              "height": 8
            }),
          new Row({
              "children": [
                new CircularProgressIndicator({
                    "value": this._progress,
                    "color": '#673AB7',
                    "backgroundColor": '#EDE7F6',
                    "strokeWidth": 6
                  }),
                new SizedBox({
                    "width": 24
                  }),
                new CircularProgressIndicator({})
              ]
            }),
          new SizedBox({
              "height": 16
            }),
          new Text({
              "style": {
                "fontSize": 16,
                "fontWeight": "bold"
              },
              "data": "LinearProgressIndicator"
            }),
          new SizedBox({
              "height": 8
            }),
          new LinearProgressIndicator({
              "value": this._progress,
              "color": '#673AB7',
              "backgroundColor": '#EDE7F6',
              "minHeight": 8
            }),
          new SizedBox({
              "height": 4
            }),
          new LinearProgressIndicator({}),
          new SizedBox({
              "height": 8
            }),
          new Text({
              "style": {
                "fontSize": 14,
                "color": '#9E9E9E'
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
    this._model = new CounterVm({});
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
                      "builder": "_builder0"
                    }),
                  new SizedBox({
                      "height": 12
                    }),
                  new Row({
                      "mainAxisAlignment": "center",
                      "children": [
                        new ElevatedButton({
                            "onPressed": this.__bindFn(0, [], (...__a) => this._inc(...__a)),
                            "child": new Text({
                                "data": "+1"
                              })
                          }),
                        new SizedBox({
                            "width": 12
                          }),
                        new ElevatedButton({
                            "onPressed": this.__bindFn(1, [], (...__a) => this._reset(...__a)),
                            "child": new Text({
                                "data": "Reset"
                              })
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
  _builder0(context, _) {
      return new Text({
        "style": {
          "fontSize": 24,
          "fontWeight": "bold"
        },
        "data": "count = " + this._model.count
      });
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
                        new Icon({
                            "color": '#009688',
                            "icon": "article"
                          }),
                        new SizedBox({
                            "width": 8
                          }),
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
                  new Divider({
                      "height": 24
                    }),
                  new Text({
                      "style": {
                        "fontSize": 14,
                        "color": '#9E9E9E'
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
          new Text({
              "style": {
                "fontSize": 15,
                "fontWeight": "bold"
              },
              "data": "DefaultTabController · 官方惯用法（controller 由祖先提供）"
            }),
          new SizedBox({
              "height": 6
            }),
          new SizedBox({
              "height": 180,
              "child": new DefaultTabController({
                  "length": 3,
                  "child": new Column({
                      "children": [
                        new TabBar({
                            "isScrollable": true,
                            "indicatorColor": '#673AB7',
                            "labelColor": '#673AB7',
                            "unselectedLabelColor": '#9E9E9E',
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
          new SizedBox({
              "height": 14
            }),
          new Text({
              "style": {
                "fontSize": 15,
                "fontWeight": "bold"
              },
              "data": "显式 TabController · index = " + this._index
            }),
          new SizedBox({
              "height": 6
            }),
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
                  "child": new Text({
                      "data": "下一 tab · controller.animateTo"
                    })
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
          new SizedBox({
              "height": 6
            }),
          new SizedBox({
              "height": 150,
              "child": __h('PageView', {
                  "controller": this._pageController,
                  "onPageChanged": this.__bindFn(0, [], (...__a) => this._onPageChanged(...__a)),
                  "children": [
                    new Container({
                        "color": '#D1C4E9',
                        "alignment": "center",
                        "child": new Text({
                            "data": "第 1 页"
                          })
                      }),
                    new Container({
                        "color": '#B2DFDB',
                        "alignment": "center",
                        "child": new Text({
                            "data": "第 2 页"
                          })
                      }),
                    new Container({
                        "color": '#FFE0B2',
                        "alignment": "center",
                        "child": new Text({
                            "data": "第 3 页"
                          })
                      })
                  ]
                })
            }),
          new SizedBox({
              "height": 10
            }),
          new Row({
              "mainAxisAlignment": "center",
              "children": [
                ...(() => { var out = []; for (let i = 0; (i < 3); (i++)) { out.push.apply(out, [new Container({ "width": 9, "height": 9, "margin": { "left": 4.0, "top": 4.0, "right": 4.0, "bottom": 4.0 }, "decoration": { "shape": "circle", "color": ((i == this._page) ? '#673AB7' : '#ffbdbdbd') } })]); } return out; })()
              ]
            }),
          new SizedBox({
              "height": 8
            }),
          new Row({
              "mainAxisAlignment": "center",
              "children": [
                new TextButton({
                    "onPressed": this.__bindFn(1, [], (...__a) => this._prevPage(...__a)),
                    "child": new Text({
                        "data": "上一页"
                      })
                  }),
                new TextButton({
                    "onPressed": this.__bindFn(2, [], (...__a) => this._nextPage(...__a)),
                    "child": new Text({
                        "data": "下一页"
                      })
                  }),
                new TextButton({
                    "onPressed": this.__bindFn(3, [], (...__a) => this._jumpToLast(...__a)),
                    "child": new Text({
                        "data": "跳到第 3 页"
                      })
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
          "color": '#FFFFFF',
          "borderRadius": {
            "radius": 6.0
          },
          "border": {
            "all": {
              "color": '#E0E0E0'
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
                  "child": new Text({
                      "data": "+1"
                    })
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
          new Text({
              "style": {
                "fontSize": 13,
                "fontWeight": "bold"
              },
              "data": "① 带 key：key: ValueKey(name)"
            }),
          ...(() => { var out = []; for (let i = 0; (i < this._names.length); (i++)) { out.push.apply(out, [new KeyTile({ "index": i, "label": this._names[i] + "（key）", "key": new ValueKey(this._names[i]) })]); } return out; })(),
          new SizedBox({
              "height": 10
            }),
          new Text({
              "style": {
                "fontSize": 13,
                "fontWeight": "bold"
              },
              "data": "② 不带 key：按位置匹配"
            }),
          ...(() => { var out = []; for (let i = 0; (i < this._names.length); (i++)) { out.push.apply(out, [new KeyTile({ "index": i, "label": this._names[i] + "（无 key）" })]); } return out; })()
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
              "key": new ObjectKey(this._stableObj)
            }),
          new KeyTile({
              "index": 1,
              "label": "B · ObjectKey(每帧新造 [1]) · 父级已重建 " + this._rebuildSeq + " 次",
              "key": new ObjectKey([1])
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
          "child": __h('ListView', {
              "children": [
                ...(() => { var out = []; for (let i = 0; (i < 12); (i++)) { out.push.apply(out, [new ListTile({ "dense": true, "title": new Text({ "data": "A 行 " + i }) })]); } return out; })()
              ],
              "key": new PageStorageKey("key-page-a")
            })
        });
    }
    return new SizedBox({
        "height": 150,
        "child": __h('ListView', {
            "children": [
              ...(() => { var out = []; for (let i = 0; (i < 12); (i++)) { out.push.apply(out, [new ListTile({ "dense": true, "title": new Text({ "data": "B 行 " + i }) })]); } return out; })()
            ],
            "key": new PageStorageKey("key-page-b")
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
          "color": '#F5F5F5',
          "borderRadius": {
            "radius": 10.0
          }
        },
        "child": new Column({
            "crossAxisAlignment": "stretch",
            "children": [
              new Text({
                  "style": {
                    "fontSize": 15,
                    "fontWeight": "bold",
                    "color": '#673AB7'
                  },
                  "data": "ValueKey · 列表按值匹配"
                }),
              new SizedBox({
                  "height": 4
                }),
              new Text({
                  "style": {
                    "fontSize": 12,
                    "color": '#9E9E9E'
                  },
                  "data": "换序后看两列计数：① 的状态跟着「行（值）」走，② 的状态留在「位置」上——" + "reconciler 取 keySig（v:值）做「带 key 优先、无 key 按位置」的匹配。"
                }),
              new SizedBox({
                  "height": 8
                }),
              this._valueKeyRows(),
              new SizedBox({
                  "height": 8
                }),
              new Row({
                  "children": [
                    new TextButton({
                        "onPressed": this.__bindFn(0, [], (...__a) => this._rotateNames(...__a)),
                        "child": new Text({
                            "data": "轮换顺序（A→末尾）"
                          })
                      }),
                    new SizedBox({
                        "width": 8
                      }),
                    new TextButton({
                        "onPressed": this.__bindFn(1, [], (...__a) => this._resetNames(...__a)),
                        "child": new Text({
                            "data": "重置"
                          })
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
          "color": '#F5F5F5',
          "borderRadius": {
            "radius": 10.0
          }
        },
        "child": new Column({
            "crossAxisAlignment": "stretch",
            "children": [
              new Text({
                  "style": {
                    "fontSize": 15,
                    "fontWeight": "bold",
                    "color": '#673AB7'
                  },
                  "data": "ObjectKey · 按对象身份相等"
                }),
              new SizedBox({
                  "height": 4
                }),
              new Text({
                  "style": {
                    "fontSize": 12,
                    "color": '#9E9E9E'
                  },
                  "data": "ObjectKey 的判据是 identical（是不是**同一个对象实例**），不是值相等。" + "A 行包的是字段里那个实例（跨帧恒定）→ 父级重建后元素复用、计数保留；" + "B 行每次 build 都新造一个 [1]（值一样但身份不同）→ 元素不匹配、销毁重建、计数归零。" + "注意：B 的计数是**被销毁**而不是被藏起来——归零之后回不来。"
                }),
              new SizedBox({
                  "height": 8
                }),
              this._objectKeyRows(),
              new SizedBox({
                  "height": 8
                }),
              new Text({
                  "style": {
                    "fontSize": 12,
                    "color": '#9E9E9E'
                  },
                  "data": "操作：先给 A、B 各点几次 +1，再点下面的「父级重建」，对比两行的计数。" + "选型场景：数据源没有稳定 ID、但你跨帧持有同一批对象实例时用它。"
                }),
              new SizedBox({
                  "height": 6
                }),
              new Text({
                  "style": {
                    "fontSize": 11,
                    "color": '#9E9E9E'
                  },
                  "data": "补充：Dart 里 ValueKey 按 == 比较、ObjectKey 按 identical 比较。" + "本例的 [1] 是 List，没有重写 ==（Dart 的 == 对 List 本就是身份比较），" + "所以这里两者结果相同——本案例要看的是「key 的身份稳不稳定」这件事本身。"
                }),
              new SizedBox({
                  "height": 8
                }),
              new Row({
                  "children": [
                    new TextButton({
                        "onPressed": this.__bindFn(2, [], (...__a) => this._rebuildParent(...__a)),
                        "child": new Text({
                            "data": "父级重建（setState 一次）"
                          })
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
          "color": '#F5F5F5',
          "borderRadius": {
            "radius": 10.0
          }
        },
        "child": new Column({
            "crossAxisAlignment": "stretch",
            "children": [
              new Text({
                  "style": {
                    "fontSize": 15,
                    "fontWeight": "bold",
                    "color": '#673AB7'
                  },
                  "data": "UniqueKey · 每次都是新身份"
                }),
              new SizedBox({
                  "height": 4
                }),
              new Text({
                  "style": {
                    "fontSize": 12,
                    "color": '#9E9E9E'
                  },
                  "data": "点「重建」触发 setState：子树的 UniqueKey 每次都是新实例（身份新 → 元素不匹配），" + "整棵子树重建、内部计数归零。"
                }),
              new SizedBox({
                  "height": 8
                }),
              new KeyTile({
                  "index": 0,
                  "label": "唯一身份行 #" + this._uniqueSeq,
                  "key": new UniqueKey()
                }),
              new SizedBox({
                  "height": 8
                }),
              new Row({
                  "children": [
                    new TextButton({
                        "onPressed": this.__bindFn(3, [], (...__a) => this._bumpUnique(...__a)),
                        "child": new Text({
                            "data": "重建（setState 一次）"
                          })
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
          "color": '#F5F5F5',
          "borderRadius": {
            "radius": 10.0
          }
        },
        "child": new Column({
            "crossAxisAlignment": "stretch",
            "children": [
              new Text({
                  "style": {
                    "fontSize": 15,
                    "fontWeight": "bold",
                    "color": '#673AB7'
                  },
                  "data": "PageStorageKey · 滚动位置持久化"
                }),
              new SizedBox({
                  "height": 4
                }),
              new Text({
                  "style": {
                    "fontSize": 12,
                    "color": '#9E9E9E'
                  },
                  "data": "把 A 列表滚到中间 → 切到 B → 切回 A：位置应回到原处。" + "值本体走值 codec（__psk），宿主造真实 PageStorageKey，位置由宿主端 PageStorage 存取。"
                }),
              new SizedBox({
                  "height": 8
                }),
              this._storageView(),
              new SizedBox({
                  "height": 8
                }),
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
          "color": '#F5F5F5',
          "borderRadius": {
            "radius": 10.0
          }
        },
        "child": new Column({
            "crossAxisAlignment": "stretch",
            "children": [
              new Text({
                  "style": {
                    "fontSize": 15,
                    "fontWeight": "bold",
                    "color": '#673AB7'
                  },
                  "data": "GlobalKey · 宿主端量测 / 定位"
                }),
              new SizedBox({
                  "height": 4
                }),
              new Text({
                  "style": {
                    "fontSize": 12,
                    "color": '#9E9E9E'
                  },
                  "data": "currentContext → findRenderObject 这条链两端同形，但「值」只能在宿主算：" + "位置与尺寸经异步桥回填（box.measure()），定位用真实 RenderObject 的 showOnScreen。"
                }),
              new SizedBox({
                  "height": 8
                }),
              new Container({
                  "padding": {
                    "left": 10.0,
                    "top": 10.0,
                    "right": 10.0,
                    "bottom": 10.0
                  },
                  "decoration": {
                    "color": '#E0F2F1',
                    "borderRadius": {
                      "radius": 6.0
                    }
                  },
                  "child": new Text({
                      "style": {
                        "fontSize": 13
                      },
                      "data": "目标盒子（GlobalKey 挂在这里）"
                    }),
                  "key": this._targetKey
                }),
              new SizedBox({
                  "height": 8
                }),
              new Text({
                  "style": {
                    "fontSize": 13,
                    "color": '#009688'
                  },
                  "data": "测量：" + this._measureText
                }),
              new SizedBox({
                  "height": 4
                }),
              new Row({
                  "children": [
                    new TextButton({
                        "onPressed": this.__bindFn(5, [], (...__a) => this._measureTarget(...__a)),
                        "child": new Text({
                            "data": "测量位置与尺寸"
                          })
                      }),
                    new SizedBox({
                        "width": 8
                      }),
                    new TextButton({
                        "onPressed": this.__bindFn(6, [], (...__a) => this._scrollToTarget(...__a)),
                        "child": new Text({
                            "data": "定位（showOnScreen）"
                          })
                      })
                  ]
                })
            ]
          })
      });
  }
  build(context) {
    return new Scaffold({
        "backgroundColor": '#FAFAFA',
        "appBar": new AppBar({
            "title": new Text({
                "data": "Key 家族 · 全部用例"
              }),
            "backgroundColor": '#673AB7',
            "foregroundColor": '#FFFFFF'
          }),
        "body": __h('ListView', {
            "children": [
              new Padding({
                  "padding": {
                    "left": 12.0,
                    "top": 12.0,
                    "right": 12.0,
                    "bottom": 0.0
                  },
                  "child": new Text({
                      "style": {
                        "fontSize": 12,
                        "color": '#9E9E9E'
                      },
                      "data": "每一张卡片一种 key 的语义；「计数」是 KeyTile 的内部 State，" + "用它来观察状态是跟着行走还是跟着位置走。"
                    })
                }),
              this._cardValueKey(),
              this._cardObjectKey(),
              this._cardUniqueKey(),
              this._cardStorageKey(),
              this._cardGlobalKey(),
              new SizedBox({
                  "height": 24
                })
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
        "backgroundColor": '#FAFAFA',
        "appBar": new AppBar({
            "title": new Text({
                "data": "Drawer / endDrawer"
              }),
            "backgroundColor": '#3F51B5',
            "foregroundColor": '#FFFFFF'
          }),
        "drawer": new Drawer({
            "child": __h('ListView', {
                "children": [
                  new DrawerHeader({
                      "decoration": {
                        "color": '#3F51B5'
                      },
                      "child": new Align({
                          "alignment": "bottomLeft",
                          "child": new Text({
                              "style": {
                                "color": '#FFFFFF',
                                "fontSize": 20
                              },
                              "data": "左侧抽屉"
                            })
                        })
                    }),
                  new ListTile({
                      "leading": new Icon({
                          "icon": "receipt_long"
                        }),
                      "title": new Text({
                          "data": "我的订单"
                        }),
                      "onTap": this.__bindFn(0, [], (...__a) => this._pickOrders(...__a))
                    }),
                  new ListTile({
                      "leading": new Icon({
                          "icon": "favorite_border"
                        }),
                      "title": new Text({
                          "data": "我的收藏"
                        }),
                      "onTap": this.__bindFn(1, [], (...__a) => this._pickFavorites(...__a))
                    })
                ]
              })
          }),
        "endDrawer": new Drawer({
            "child": __h('ListView', {
                "children": [
                  new DrawerHeader({
                      "decoration": {
                        "color": '#009688'
                      },
                      "child": new Align({
                          "alignment": "bottomLeft",
                          "child": new Text({
                              "style": {
                                "color": '#FFFFFF',
                                "fontSize": 20
                              },
                              "data": "右侧抽屉"
                            })
                        })
                    }),
                  new ListTile({
                      "leading": new Icon({
                          "icon": "settings"
                        }),
                      "title": new Text({
                          "data": "设置"
                        }),
                      "onTap": this.__bindFn(2, [], (...__a) => this._pickSettings(...__a))
                    }),
                  new ListTile({
                      "leading": new Icon({
                          "icon": "help_outline"
                        }),
                      "title": new Text({
                          "data": "帮助与关于"
                        }),
                      "onTap": this.__bindFn(3, [], (...__a) => this._pickHelp(...__a))
                    })
                ]
              })
          }),
        "body": new Center({
            "child": new Column({
                "mainAxisAlignment": "center",
                "children": [
                  new Icon({
                      "size": 48,
                      "color": '#3F51B5',
                      "icon": "menu_open"
                    }),
                  new SizedBox({
                      "height": 12
                    }),
                  new Text({
                      "data": "AppBar 左侧为汉堡按钮，右侧为 endDrawer 入口"
                    }),
                  new SizedBox({
                      "height": 8
                    }),
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
                    new Expanded({
                        "child": new Text({
                            "style": {
                              "fontSize": 13,
                              "color": '#9E9E9E'
                            },
                            "data": "长按拖拽调整顺序（onReorder 双参事件）"
                          })
                      }),
                    new ElevatedButton({
                        "onPressed": this.__bindFn(0, [], (...__a) => this._add(...__a)),
                        "child": new Text({
                            "data": "添加"
                          })
                      })
                  ]
                })
            }),
          new SizedBox({
              "height": 320,
              "child": new ReorderableListView({
                  "scrollController": this._controller,
                  "onReorder": this.__bindFn(1, [], (...__a) => this._onReorder(...__a)),
                  "padding": {
                    "left": 12.0,
                    "top": 0.0,
                    "right": 12.0,
                    "bottom": 0.0
                  },
                  "itemCount": this._items.length,
                  "itemBuilder": "_itemBuilder0",
                  "factory": "builder"
                })
            })
        ]
      });
  }
  dispose() {
    this._controller.dispose();
  }
  _itemBuilder0(context, index) {
      var item = this._items[index];
      return new Card({
        "child": new ListTile({
            "leading": new Icon({
                "icon": "drag_handle"
              }),
            "title": new Text({
                "data": item
              })
          }),
        "key": new ValueKey(item)
      });
  }
}

// 组件 TestWidget
export class TestWidget {
  constructor(args) {
    this.props = args || {};
  }
  build(context) {
    var text = new Text({
          "data": "局部变量 widget"
        });
    var card = new StatelessCard({
          "title": "局部自定义组件",
          "subtitle": "StatelessCard 变量",
          "badge": "VAR"
        });
    var items = [new Text({
          "data": "列表项 A"
        }), new Text({
          "data": "列表项 B"
        })];
    return new Center({
        "child": new Column({
            "mainAxisSize": "min",
            "children": [
              text,
              new SizedBox({
                  "height": 8
                }),
              card,
              new SizedBox({
                  "height": 8
                }),
              ...items
            ]
          })
      });
  }
}

