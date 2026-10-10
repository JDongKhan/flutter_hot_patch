// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/components/widget_details.dart 自动生成
// 重新生成：dart run build_runner build

import { CounterModel } from '../model/counter_model.js';
import { Align, AppBar, AspectRatio, BottomNavigationBar, BottomNavigationBarItem, Button, Card, Center, Checkbox, Chip, CircleAvatar, CircularProgressIndicator, ClipRRect, Column, ConstrainedBox, Container, CustomScrollView, DecoratedBox, Divider, DropdownButton, DropdownMenuItem, Expanded, FloatingActionButton, FractionallySizedBox, Icon, Image, LinearProgressIndicator, ListTile, ListView, ListenableBuilder, NotificationListener, Opacity, Padding, Positioned, Radio, Row, SafeArea, Scaffold, SingleChildScrollView, SizedBox, Slider, SliverAppBar, SliverFillRemaining, SliverFixedExtentList, SliverGrid, SliverList, SliverOpacity, SliverPadding, SliverSafeArea, SliverToBoxAdapter, Spacer, Stack, Switch, Text, TextField, Wrap, __h } from '../flutter.js';

class TextDetailComponent {
  constructor() {
    this._count = 0;
  }
  bump() { this.setState(function(){ this._count += 1; }); }
  build() {
    return Column({
        "crossAxisAlignment": "stretch"
      }, [
        Text({
            "data": "基础文案 + TextStyle",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }),
        Text({
            "data": "普通文本，count = " + this._count + "（状态插值）",
            "style": {
              "color": '#2196F3',
              "fontSize": 16
            }
          }),
        SizedBox({
            "height": 6
          }),
        Text({
            "data": "maxLines+overflow 测试：这是一段很长的文字会被截断成省略号显示",
            "maxLines": 1,
            "overflow": "ellipsis"
          }),
        SizedBox({
            "height": 6
          }),
        Text({
            "data": "textScaler.linear(1.6) 放大",
            "textScaler": {
              "linear": 1.6
            }
          }),
        SizedBox({
            "height": 6
          }),
        Text({
            "data": "textAlign 居中",
            "style": {
              "decoration": "underline",
              "decorationColor": '#FF9800',
              "decorationStyle": "wavy"
            },
            "textAlign": "center"
          }),
        SizedBox({
            "height": 6
          }),
        Text({
            "data": "softWrap=false 不换行测试",
            "style": {
              "fontSize": 12,
              "color": '#9E9E9E',
              "wordSpacing": 2,
              "letterSpacing": 1,
              "backgroundColor": '#ffffe082'
            },
            "softWrap": false
          }),
        SizedBox({
            "height": 6
          }),
        Button({
            "kind": "text",
            "label": "Bump count",
            "event": this.__bind("bump")
          })
      ]);
  }
}
export function TextDetail(props, children) {
  return __h(TextDetailComponent, props, children);
}

class ButtonDetailComponent {
  constructor() {
    this._pressed = 0;
  }
  onTap() { this.setState(function(){ this._pressed += 1; }); }
  build() {
    return Column({
        "crossAxisAlignment": "stretch"
      }, [
        Text({
            "data": "点击次数 = " + this._pressed,
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }),
        SizedBox({
            "height": 8
          }),
        Button({
            "kind": "elevated",
            "label": "Elevated · Styled",
            "event": this.__bind("onTap"),
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
            }
          }),
        SizedBox({
            "height": 8
          }),
        Button({
            "kind": "text",
            "label": "TextButton",
            "event": this.__bind("onTap"),
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
            }
          }),
        SizedBox({
            "height": 8
          }),
        Button({
            "kind": "outlined",
            "label": "OutlinedButton",
            "event": this.__bind("onTap"),
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
            }
          }),
        SizedBox({
            "height": 8
          }),
        Button({
            "kind": "elevated",
            "label": "Disabled"
          })
      ]);
  }
}
export function ButtonDetail(props, children) {
  return __h(ButtonDetailComponent, props, children);
}

class LayoutDetailComponent {
  constructor() {
  }
  build() {
    return Column({
        "crossAxisAlignment": "stretch"
      }, [
        Text({
            "data": "Row + Expanded / Flexible / Spacer",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }),
        Row({}, [
            Expanded({
                "flex": 1
              }, [
                Container({
                    "color": '@Colors.blue.shade100',
                    "padding": {
                      "left": 8.0,
                      "top": 8.0,
                      "right": 8.0,
                      "bottom": 8.0
                    }
                  }, [
                    Text({
                        "data": "A",
                        "textAlign": "center"
                      })
                  ])
              ]),
            Spacer({
                "flex": 1
              }),
            Expanded({
                "flex": 2
              }, [
                Container({
                    "color": '@Colors.green.shade100',
                    "padding": {
                      "left": 8.0,
                      "top": 8.0,
                      "right": 8.0,
                      "bottom": 8.0
                    }
                  }, [
                    Text({
                        "data": "B（flex=2）",
                        "textAlign": "center"
                      })
                  ])
              ])
          ]),
        SizedBox({
            "height": 12
          }),
        Text({
            "data": "Center / Align / Padding / SizedBox",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }),
        Center({}, [
            Container({
                "color": '@Colors.amber.shade100',
                "padding": {
                  "left": 12.0,
                  "top": 12.0,
                  "right": 12.0,
                  "bottom": 12.0
                }
              }, [
                Text({
                    "data": "Center 居中"
                  })
              ])
          ]),
        SizedBox({
            "height": 8
          }),
        Align({
            "alignment": "centerLeft"
          }, [
            Container({
                "color": '@Colors.purple.shade50',
                "padding": {
                  "left": 8.0,
                  "top": 8.0,
                  "right": 8.0,
                  "bottom": 8.0
                }
              }, [
                Text({
                    "data": "Align centerLeft"
                  })
              ])
          ]),
        SizedBox({
            "height": 8
          }),
        Padding({
            "padding": {
              "left": 8.0,
              "top": 4.0,
              "right": 8.0,
              "bottom": 4.0
            }
          }, [
            Text({
                "data": "Padding 包裹文案"
              })
          ]),
        SizedBox({
            "height": 12
          }),
        Text({
            "data": "Stack + Positioned",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }),
        SizedBox({
            "height": 100
          }, [
            Stack({
                "fit": "expand",
                "clipBehavior": "hardEdge"
              }, [
                Container({
                    "color": '@Colors.grey.shade200'
                  }),
                Positioned({
                    "left": 0,
                    "top": 0,
                    "right": 0,
                    "bottom": 0
                  }, [
                    Center({}, [
                        Text({
                            "data": "FILL",
                            "style": {
                              "color": '#FFFFFF',
                              "fontWeight": "bold"
                            }
                          })
                      ])
                  ]),
                Positioned({
                    "left": 12,
                    "top": 12
                  }, [
                    Text({
                        "data": "TL"
                      })
                  ]),
                Positioned({
                    "right": 12,
                    "bottom": 12
                  }, [
                    Text({
                        "data": "BR"
                      })
                  ])
              ])
          ]),
        SizedBox({
            "height": 12
          }),
        Text({
            "data": "Wrap · 自动换行",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }),
        Wrap({
            "spacing": 8,
            "runSpacing": 8,
            "direction": "horizontal",
            "alignment": "start",
            "runAlignment": "center",
            "crossAxisAlignment": "center"
          }, [
            ...(function(){ var out = []; for (var i = 1; (i <= 5); (i++)) { out.push.apply(out, [Chip({ "label": "chip " + i, "backgroundColor": '@Colors.teal.shade50' })]); } return out; })()
          ]),
        SizedBox({
            "height": 12
          }),
        Text({
            "data": "Opacity / ConstrainedBox / AspectRatio / FractionallySizedBox",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }),
        Opacity({
            "opacity": 0.5
          }, [
            Container({
                "color": '#F44336',
                "padding": {
                  "left": 8.0,
                  "top": 8.0,
                  "right": 8.0,
                  "bottom": 8.0
                }
              }, [
                Text({
                    "data": "50% 透明"
                  })
              ])
          ]),
        SizedBox({
            "height": 8
          }),
        ConstrainedBox({
            "constraints": {
              "minWidth": 120,
              "maxWidth": 200
            }
          }, [
            Container({
                "color": '@Colors.orange.shade100',
                "padding": {
                  "left": 8.0,
                  "top": 8.0,
                  "right": 8.0,
                  "bottom": 8.0
                }
              }, [
                Text({
                    "data": "ConstrainedBox 宽度 120-200"
                  })
              ])
          ]),
        SizedBox({
            "height": 8
          }),
        AspectRatio({
            "aspectRatio": 1.78
          }, [
            Container({
                "color": '@Colors.indigo.shade100',
                "alignment": "center"
              }, [
                Text({
                    "data": "16:9 比例"
                  })
              ])
          ]),
        SizedBox({
            "height": 8
          }),
        FractionallySizedBox({
            "widthFactor": 0.6,
            "alignment": "center"
          }, [
            Container({
                "color": '@Colors.pink.shade100',
                "padding": {
                  "left": 8.0,
                  "top": 8.0,
                  "right": 8.0,
                  "bottom": 8.0
                }
              }, [
                Text({
                    "data": "60% 宽度",
                    "textAlign": "center"
                  })
              ])
          ])
      ]);
  }
}
export function LayoutDetail(props, children) {
  return __h(LayoutDetailComponent, props, children);
}

class ImageDetailComponent {
  constructor() {
  }
  build() {
    return Column({
        "crossAxisAlignment": "stretch"
      }, [
        Text({
            "data": "Image · 网络图片",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }),
        ClipRRect({
            "child": Image({
                "source": "https://picsum.photos/seed/hotpatch/400/160",
                "height": 120,
                "fit": "cover"
              })
          }),
        SizedBox({
            "height": 12
          }),
        Text({
            "data": "Icon / CircleAvatar",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }),
        Row({}, [
            Icon({
                "icon": "star",
                "size": 28,
                "color": '#FFC107'
              }),
            SizedBox({
                "width": 12
              }),
            Icon({
                "icon": "home",
                "size": 28,
                "color": '#2196F3'
              }),
            SizedBox({
                "width": 12
              }),
            Icon({
                "icon": "favorite",
                "size": 28,
                "color": '#F44336'
              }),
            SizedBox({
                "width": 12
              }),
            CircleAvatar({
                "radius": 20,
                "backgroundColor": '#009688'
              }, [
                Text({
                    "data": "AV",
                    "style": {
                      "color": '#FFFFFF'
                    }
                  })
              ])
          ])
      ]);
  }
}
export function ImageDetail(props, children) {
  return __h(ImageDetailComponent, props, children);
}

class ContainerDetailComponent {
  constructor() {
  }
  build() {
    return Column({
        "crossAxisAlignment": "stretch"
      }, [
        Text({
            "data": "Container · 颜色/圆角/Padding",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }),
        Container({
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
            }
          }, [
            Text({
                "data": "容器内容（teal 圆角）",
                "style": {
                  "color": '#FFFFFF'
                }
              })
          ]),
        SizedBox({
            "height": 12
          }),
        Text({
            "data": "Container · 边框 + 阴影 + 渐变",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }),
        Container({
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
            }
          }, [
            Text({
                "data": "渐变 + 边框 + 阴影",
                "style": {
                  "color": '#FFFFFF'
                }
              })
          ]),
        SizedBox({
            "height": 12
          }),
        Text({
            "data": "DecoratedBox · 纯装饰",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }),
        DecoratedBox({
            "decoration": {
              "color": '@Colors.amber.shade100',
              "border": {
                "all": {
                  "color": '#FFC107',
                  "width": 2
                }
              },
              "borderRadius": {
                "radius": 8.0
              }
            }
          }, [
            Padding({
                "padding": {
                  "left": 12.0,
                  "top": 12.0,
                  "right": 12.0,
                  "bottom": 12.0
                }
              }, [
                Text({
                    "data": "DecoratedBox 内容"
                  })
              ])
          ]),
        SizedBox({
            "height": 12
          }),
        Text({
            "data": "Card · shape / clipBehavior",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }),
        Card({
            "elevation": 4,
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
            "shadowColor": '#673AB7'
          }, [
            Padding({
                "padding": {
                  "left": 16.0,
                  "top": 16.0,
                  "right": 16.0,
                  "bottom": 16.0
                }
              }, [
                Text({
                    "data": "圆角卡片 + 描边 + 阴影"
                  })
              ])
          ]),
        SizedBox({
            "height": 12
          }),
        Divider({}),
        SizedBox({
            "height": 12
          }),
        Text({
            "data": "SizedBox · 尺寸约束",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }),
        Container({
            "width": 120,
            "height": 48,
            "color": '@Colors.blueGrey.shade100',
            "alignment": "center"
          }, [
            Text({
                "data": "固定 120×48"
              })
          ])
      ]);
  }
}
export function ContainerDetail(props, children) {
  return __h(ContainerDetailComponent, props, children);
}

class ScrollDetailComponent {
  constructor() {
    this._offset = 0;
    this._ctrlOffset = 0;
    this._scrollController = new ScrollController();
  }
  initState() { this._scrollController.addListener(() => { this.setState(() => { this._ctrlOffset = this._scrollController.offset; }); }); }
  dispose() { this._scrollController.dispose(); }
  _onListScroll(n) { this.setState(function(){ this._offset = n.metrics.pixels; }); }
  _scrollToEnd() { this._scrollController.jumpTo(this._scrollController.position.maxScrollExtent); }
  build() {
    return Column({
        "crossAxisAlignment": "stretch"
      }, [
        Text({
            "data": "ListView · 列表（offset: " + this._offset + "）",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }),
        NotificationListener({
            "onNotification": this.__bind("_onListScroll")
          }, [
            SizedBox({
                "height": 160
              }, [
                ListView({
                    "padding": {
                      "left": 8.0,
                      "top": 8.0,
                      "right": 8.0,
                      "bottom": 8.0
                    },
                    "physics": "BouncingScrollPhysics",
                    "itemExtent": 56
                  }, [
                    ListTile({
                        "title": "item A",
                        "leading": Icon({
                            "icon": "list"
                          })
                      }),
                    ListTile({
                        "title": "item B",
                        "leading": Icon({
                            "icon": "list"
                          })
                      }),
                    ListTile({
                        "title": "item C",
                        "leading": Icon({
                            "icon": "list"
                          })
                      }),
                    ListTile({
                        "title": "item D",
                        "leading": Icon({
                            "icon": "list"
                          })
                      }),
                    ListTile({
                        "title": "item E",
                        "leading": Icon({
                            "icon": "list"
                          })
                      })
                  ])
              ])
          ]),
        SizedBox({
            "height": 12
          }),
        Text({
            "data": "SingleChildScrollView · 长内容滚动（ctrl offset: " + this._ctrlOffset + "）",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }),
        SingleChildScrollView({
            "controller": this._scrollController,
            "scrollDirection": "horizontal",
            "physics": "ClampingScrollPhysics"
          }, [
            Row({}, [
                ...(function(){ var out = []; for (var i = 1; (i <= 8); (i++)) { out.push.apply(out, [Padding({ "padding": { "left": 4.0, "top": 4.0, "right": 4.0, "bottom": 4.0 } }, [ Chip({ "label": "横向 " + i }) ])]); } return out; })()
              ])
          ]),
        Align({
            "alignment": "centerLeft"
          }, [
            Button({
                "kind": "text",
                "label": "横向 · 跳到底",
                "event": this.__bind("_scrollToEnd")
              })
          ])
      ]);
  }
}
export function ScrollDetail(props, children) {
  return __h(ScrollDetailComponent, props, children);
}

class SliverDetailComponent {
  constructor() {
    this._controller = new ScrollController();
    this._offset = 0;
  }
  initState() { this._controller.addListener(() => { this.setState(() => { this._offset = this._controller.offset; }); }); }
  dispose() { this._controller.dispose(); }
  _scrollToEnd() { this._controller.jumpTo(this._controller.position.maxScrollExtent); }
  build() {
    return Scaffold({
        "floatingActionButton": FloatingActionButton({
            "child": Icon({
                "icon": "arrow_downward"
              }),
            "event": this.__bind("_scrollToEnd"),
            "backgroundColor": '#673AB7',
            "foregroundColor": '#FFFFFF',
            "tooltip": "跳到底"
          })
      }, [
        AppBar({
            "title": Text({
                "data": "Sliver 全家桶 · offset " + this._offset
              }),
            "backgroundColor": '#673AB7',
            "foregroundColor": '#FFFFFF'
          }),
        CustomScrollView({
            "controller": this._controller,
            "physics": "BouncingScrollPhysics"
          }, [
            SliverAppBar({
                "title": Text({
                    "data": "SliverAppBar 导航"
                  }),
                "backgroundColor": '#673AB7',
                "foregroundColor": '#FFFFFF',
                "pinned": true,
                "floating": true
              }),
            SliverToBoxAdapter({}, [
                Container({
                    "padding": {
                      "left": 16.0,
                      "top": 16.0,
                      "right": 16.0,
                      "bottom": 16.0
                    },
                    "margin": {
                      "left": 12.0,
                      "top": 12.0,
                      "right": 12.0,
                      "bottom": 12.0
                    },
                    "decoration": {
                      "color": '@Colors.deepPurple.shade50',
                      "borderRadius": {
                        "radius": 12.0
                      }
                    }
                  }, [
                    Text({
                        "data": "CustomScrollView 整页 · SliverToBoxAdapter 盒子",
                        "style": {
                          "fontSize": 14,
                          "fontWeight": "bold"
                        }
                      })
                  ])
              ]),
            SliverPadding({
                "padding": {
                  "left": 12.0,
                  "top": 0.0,
                  "right": 12.0,
                  "bottom": 0.0
                }
              }, [
                SliverList({}, [
                    ...(function(){ var out = []; for (var i = 1; (i <= 5); (i++)) { out.push.apply(out, [ListTile({ "title": "SliverList item " + i, "leading": Icon({ "icon": "list", "color": '#673AB7' }), "trailing": Icon({ "icon": "chevron_right" }) })]); } return out; })()
                  ])
              ]),
            SliverPadding({
                "padding": {
                  "left": 12.0,
                  "top": 8.0,
                  "right": 12.0,
                  "bottom": 8.0
                }
              }, [
                SliverToBoxAdapter({}, [
                    Text({
                        "data": "SliverChildBuilderDelegate · 懒构建列表",
                        "style": {
                          "fontSize": 14,
                          "fontWeight": "bold"
                        }
                      })
                  ])
              ]),
            SliverPadding({
                "padding": {
                  "left": 12.0,
                  "top": 0.0,
                  "right": 12.0,
                  "bottom": 0.0
                }
              }, [
                SliverList({
                    "delegateBuilder": "_sliverBuilder0",
                    "childCount": 8
                  })
              ]),
            SliverPadding({
                "padding": {
                  "left": 12.0,
                  "top": 8.0,
                  "right": 12.0,
                  "bottom": 8.0
                }
              }, [
                SliverToBoxAdapter({}, [
                    Text({
                        "data": "SliverFixedExtentList · 固定高度",
                        "style": {
                          "fontSize": 14,
                          "fontWeight": "bold"
                        }
                      })
                  ])
              ]),
            SliverPadding({
                "padding": {
                  "left": 12.0,
                  "top": 0.0,
                  "right": 12.0,
                  "bottom": 0.0
                }
              }, [
                SliverFixedExtentList({
                    "delegateBuilder": "_sliverBuilder1",
                    "childCount": 6,
                    "itemExtent": 44
                  })
              ]),
            SliverPadding({
                "padding": {
                  "left": 12.0,
                  "top": 8.0,
                  "right": 12.0,
                  "bottom": 8.0
                }
              }, [
                SliverToBoxAdapter({}, [
                    Text({
                        "data": "SliverOpacity + SliverGrid · MaxCrossAxisExtent 九宫格",
                        "style": {
                          "fontSize": 14,
                          "fontWeight": "bold"
                        }
                      })
                  ])
              ]),
            SliverOpacity({
                "opacity": 0.6
              }, [
                SliverPadding({
                    "padding": {
                      "left": 12.0,
                      "top": 0.0,
                      "right": 12.0,
                      "bottom": 0.0
                    }
                  }, [
                    SliverGrid({
                        "delegateBuilder": "_sliverBuilder2",
                        "childCount": 9,
                        "maxCrossAxisExtent": 140,
                        "mainAxisSpacing": 8,
                        "crossAxisSpacing": 8,
                        "childAspectRatio": 1
                      })
                  ])
              ]),
            SliverSafeArea({}, [
                SliverFillRemaining({
                    "hasScrollBody": false
                  }, [
                    Center({}, [
                        Text({
                            "data": "底部 · SliverSafeArea + SliverFillRemaining",
                            "style": {
                              "color": '#9E9E9E'
                            }
                          })
                      ])
                  ])
              ])
          ])
      ]);
  }
  _sliverBuilder0(index) {
      return ListTile({
        "title": "builder item " + index,
        "subtitle": "index * 10 = " + (index * 10),
        "leading": Icon({
            "icon": "build",
            "color": '@Colors.orange.shade700'
          })
      });
  }
  _sliverBuilder1(index) {
      return ListTile({
        "title": "fixed item " + index,
        "leading": Icon({
            "icon": "height",
            "color": '#009688'
          }),
        "dense": true
      });
  }
  _sliverBuilder2(index) {
      return Container({
        "alignment": "center",
        "decoration": {
          "color": '@Colors.teal.shade100',
          "borderRadius": {
            "radius": 8.0
          }
        }
      }, [
        Text({
            "data": "格 " + index,
            "style": {
              "fontWeight": "bold"
            }
          })
      ]);
  }
}
export function SliverDetail(props, children) {
  return __h(SliverDetailComponent, props, children);
}

class ScaffoldDetailComponent {
  constructor() {
    this._navIndex = 0;
  }
  _onNavTap(index) { this.setState(function(){ this._navIndex = index; }); }
  _onFab() { /* 空方法体 */ }
  build() {
    return Scaffold({
        "backgroundColor": '@Colors.grey.shade50',
        "floatingActionButton": FloatingActionButton({
            "child": Icon({
                "icon": "add"
              }),
            "event": this.__bind("_onFab"),
            "backgroundColor": '#673AB7',
            "foregroundColor": '#FFFFFF',
            "tooltip": "添加"
          }),
        "bottomNavigationBar": BottomNavigationBar({
            "currentIndex": this._navIndex,
            "event": this.__bind("_onNavTap"),
            "selectedItemColor": '#673AB7',
            "unselectedItemColor": '#9E9E9E'
          }, [
            BottomNavigationBarItem({
                "icon": Icon({
                    "icon": "home"
                  }),
                "label": "首页"
              }),
            BottomNavigationBarItem({
                "icon": Icon({
                    "icon": "search"
                  }),
                "label": "搜索"
              }),
            BottomNavigationBarItem({
                "icon": Icon({
                    "icon": "person"
                  }),
                "label": "我的"
              })
          ])
      }, [
        AppBar({
            "title": Text({
                "data": "Scaffold / AppBar / FAB / BottomNav"
              }),
            "leading": Icon({
                "icon": "menu"
              }),
            "backgroundColor": '#673AB7',
            "foregroundColor": '#FFFFFF',
            "elevation": 4,
            "toolbarHeight": 56,
            "centerTitle": true
          }, [
            Icon({
                "icon": "search",
                "color": '#FFFFFF'
              }),
            SizedBox({
                "width": 16
              })
          ]),
        SafeArea({}, [
            Center({}, [
                Column({
                    "mainAxisAlignment": "center"
                  }, [
                    Icon({
                        "icon": "extension",
                        "size": 48,
                        "color": '#673AB7'
                      }),
                    SizedBox({
                        "height": 12
                      }),
                    Text({
                        "data": "页面骨架组件演示"
                      }),
                    Text({
                        "data": "BottomNav 选中：" + this._navIndex
                      })
                  ])
              ])
          ])
      ]);
  }
}
export function ScaffoldDetail(props, children) {
  return __h(ScaffoldDetailComponent, props, children);
}

class InputDetailComponent {
  constructor() {
    this._text = "";
    this._choice = "A";
    this._dropdown = "苹果";
    this._switchOn = false;
    this._checked = false;
    this._slider = 0.4;
  }
  _onTextChanged(v) { this.setState(function(){ this._text = v; }); }
  _onChoiceChanged(v) { this.setState(function(){ this._choice = v; }); }
  _onDropdownChanged(v) { this.setState(function(){ this._dropdown = v; }); }
  _onSwitchChanged(v) { this.setState(function(){ this._switchOn = (v ?? false); }); }
  _onCheckChanged(v) { this.setState(function(){ this._checked = v; }); }
  _onSliderChanged(v) { this.setState(function(){ this._slider = v; }); }
  build() {
    return Column({
        "crossAxisAlignment": "stretch"
      }, [
        Text({
            "data": "TextField",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }),
        TextField({
            "event": this.__bind("_onTextChanged"),
            "hintText": "请输入文本",
            "labelText": "用户名",
            "maxLines": 1,
            "style": {
              "fontSize": 16
            }
          }),
        SizedBox({
            "height": 4
          }),
        Text({
            "data": "输入内容：" + this._text,
            "style": {
              "fontSize": 14,
              "color": '#9E9E9E'
            }
          }),
        SizedBox({
            "height": 12
          }),
        Text({
            "data": "Radio 单选",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }),
        Row({}, [
            Radio({
                "value": "A",
                "groupValue": this._choice,
                "event": this.__bind("_onChoiceChanged"),
                "activeColor": '#673AB7'
              }),
            Text({
                "data": "选项 A"
              }),
            Radio({
                "value": "B",
                "groupValue": this._choice,
                "event": this.__bind("_onChoiceChanged"),
                "activeColor": '#673AB7'
              }),
            Text({
                "data": "选项 B"
              })
          ]),
        Text({
            "data": "当前选择：" + this._choice,
            "style": {
              "fontSize": 14,
              "color": '#9E9E9E'
            }
          }),
        SizedBox({
            "height": 12
          }),
        Text({
            "data": "DropdownButton",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }),
        DropdownButton({
            "value": this._dropdown,
            "event": this.__bind("_onDropdownChanged"),
            "isExpanded": true
          }, [
            DropdownMenuItem({
                "value": "苹果",
                "label": "苹果"
              }),
            DropdownMenuItem({
                "value": "香蕉",
                "label": "香蕉"
              }),
            DropdownMenuItem({
                "value": "橙子",
                "label": "橙子"
              })
          ]),
        SizedBox({
            "height": 12
          }),
        Row({}, [
            Switch({
                "value": this._switchOn,
                "event": this.__bind("_onSwitchChanged"),
                "activeColor": '#FFFFFF',
                "activeTrackColor": '#673AB7',
                "inactiveThumbColor": '#9E9E9E',
                "inactiveTrackColor": '@Colors.grey.shade300'
              }),
            SizedBox({
                "width": 8
              }),
            Text({
                "data": "Switch：" + (this._switchOn ? "开" : "关")
              })
          ]),
        Row({}, [
            Checkbox({
                "value": this._checked,
                "event": this.__bind("_onCheckChanged"),
                "activeColor": '#673AB7',
                "checkColor": '#FFFFFF'
              }),
            SizedBox({
                "width": 8
              }),
            Text({
                "data": "Checkbox：" + (this._checked ?? false)
              })
          ]),
        SizedBox({
            "height": 8
          }),
        Text({
            "data": "Slider 值：" + this._slider,
            "style": {
              "fontSize": 14
            }
          }),
        Slider({
            "value": this._slider,
            "event": this.__bind("_onSliderChanged"),
            "min": 0,
            "max": 1,
            "divisions": 10,
            "activeColor": '#673AB7',
            "inactiveColor": '@Colors.grey.shade300'
          })
      ]);
  }
}
export function InputDetail(props, children) {
  return __h(InputDetailComponent, props, children);
}

class ProgressDetailComponent {
  constructor() {
    this._progress = 0.65;
  }
  build() {
    return Column({
        "crossAxisAlignment": "stretch"
      }, [
        Text({
            "data": "CircularProgressIndicator",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }),
        SizedBox({
            "height": 8
          }),
        Row({}, [
            CircularProgressIndicator({
                "color": '#673AB7',
                "backgroundColor": '@Colors.deepPurple.shade50',
                "strokeWidth": 6
              }),
            SizedBox({
                "width": 24
              }),
            CircularProgressIndicator({})
          ]),
        SizedBox({
            "height": 16
          }),
        Text({
            "data": "LinearProgressIndicator",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }),
        SizedBox({
            "height": 8
          }),
        LinearProgressIndicator({
            "color": '#673AB7',
            "backgroundColor": '@Colors.deepPurple.shade50',
            "minHeight": 8
          }),
        SizedBox({
            "height": 4
          }),
        LinearProgressIndicator({}),
        SizedBox({
            "height": 8
          }),
        Text({
            "data": "进度值：" + this._progress,
            "style": {
              "fontSize": 14,
              "color": '#9E9E9E'
            }
          })
      ]);
  }
}
export function ProgressDetail(props, children) {
  return __h(ProgressDetailComponent, props, children);
}

class NotifierCardComponent {
  constructor() {
    this._model = new CounterModel({});
  }
  _inc() { this._model.inc(); }
  _reset() { this._model.reset(); }
  dispose() { this._model.dispose(); }
  build() {
    return Card({}, [
        Padding({
            "padding": {
              "left": 16.0,
              "top": 16.0,
              "right": 16.0,
              "bottom": 16.0
            }
          }, [
            Column({
                "mainAxisSize": "min"
              }, [
                ListenableBuilder({
                    "listenable": "_model",
                    "builder": "_lbBuilder0"
                  }),
                SizedBox({
                    "height": 12
                  }),
                Row({
                    "mainAxisAlignment": "center"
                  }, [
                    Button({
                        "kind": "elevated",
                        "label": "+1",
                        "event": this.__bind("_inc")
                      }),
                    SizedBox({
                        "width": 12
                      }),
                    Button({
                        "kind": "elevated",
                        "label": "Reset",
                        "event": this.__bind("_reset")
                      })
                  ])
              ])
          ])
      ]);
  }
  _lbBuilder0() {
      return Text({
        "data": "count = " + this._model.count,
        "style": {
          "fontSize": 24,
          "fontWeight": "bold"
        }
      });
  }
}
export function NotifierCard(props, children) {
  return __h(NotifierCardComponent, props, children);
}

class StatelessCardComponent {
  constructor(args) {
    this.title = (args && args.title !== undefined) ? args.title : '';
    this.subtitle = (args && args.subtitle !== undefined) ? args.subtitle : '';
    this.badge = (args && args.badge !== undefined) ? args.badge : '';
  }
  build() {
    return Card({
        "margin": {
          "left": 12.0,
          "top": 12.0,
          "right": 12.0,
          "bottom": 12.0
        }
      }, [
        Padding({
            "padding": {
              "left": 16.0,
              "top": 16.0,
              "right": 16.0,
              "bottom": 16.0
            }
          }, [
            Column({
                "mainAxisSize": "min",
                "crossAxisAlignment": "start"
              }, [
                Row({}, [
                    Icon({
                        "icon": "article",
                        "color": '#009688'
                      }),
                    SizedBox({
                        "width": 8
                      }),
                    Expanded({}, [
                        Text({
                            "data": this.badge + " · " + this.title,
                            "style": {
                              "fontSize": 18,
                              "fontWeight": "bold"
                            }
                          })
                      ])
                  ]),
                Divider({
                    "height": 24
                  }),
                Text({
                    "data": this.subtitle,
                    "style": {
                      "fontSize": 14,
                      "color": '#9E9E9E'
                    }
                  })
              ])
          ])
      ]);
  }
}
export function StatelessCard(props, children) {
  return __h(StatelessCardComponent, props, children);
}

