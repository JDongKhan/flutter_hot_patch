// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/widget_details.dart 自动生成
// 重新生成：dart run build_runner build

import { CounterVm } from '../model/counter_vm.js';
import { GridView, ListView, ListenableBuilder, SliverFixedExtentList, SliverGrid, SliverList, __h } from '../flutter.js';

// 组件 TextDetail
export class TextDetail {
  constructor() {
    this._count = 0;
  }
  bump() {
    this.setState(() => { this._count += 1; });
  }
  build(context) {
    return __h('Column', {
        "crossAxisAlignment": "stretch"
      }, [
        __h('Text', {
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            },
            "$pos": [
              "基础文案 + TextStyle"
            ]
          }),
        __h('Text', {
            "style": {
              "color": '#2196F3',
              "fontSize": 16
            },
            "$pos": [
              "普通文本，count = " + this._count + "（状态插值）"
            ]
          }),
        __h('SizedBox', {
            "height": 6
          }),
        __h('Text', {
            "maxLines": 1,
            "overflow": "ellipsis",
            "$pos": [
              "maxLines+overflow 测试：这是一段很长的文字会被截断成省略号显示"
            ]
          }),
        __h('SizedBox', {
            "height": 6
          }),
        __h('Text', {
            "textScaler": {
              "linear": 1.6
            },
            "$pos": [
              "textScaler.linear(1.6) 放大"
            ]
          }),
        __h('SizedBox', {
            "height": 6
          }),
        __h('Text', {
            "textAlign": "center",
            "style": {
              "decoration": "underline",
              "decorationColor": '#FF9800',
              "decorationStyle": "wavy"
            },
            "$pos": [
              "textAlign 居中"
            ]
          }),
        __h('SizedBox', {
            "height": 6
          }),
        __h('Text', {
            "softWrap": false,
            "style": {
              "fontSize": 12,
              "color": '#9E9E9E',
              "wordSpacing": 2,
              "letterSpacing": 1,
              "backgroundColor": '#ffffe082'
            },
            "$pos": [
              "softWrap=false 不换行测试"
            ]
          }),
        __h('SizedBox', {
            "height": 6
          }),
        __h('TextButton', {
            "onPressed": this.__bind("bump")
          }, [
            __h('Text', {
                "$pos": [
                  "Bump count"
                ]
              })
          ])
      ]);
  }
}

// 组件 ButtonDetail
export class ButtonDetail {
  constructor() {
    this._pressed = 0;
  }
  onTap() {
    this.setState(() => { this._pressed += 1; });
  }
  build(context) {
    return __h('Column', {
        "crossAxisAlignment": "stretch"
      }, [
        __h('Text', {
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            },
            "$pos": [
              "点击次数 = " + this._pressed
            ]
          }),
        __h('SizedBox', {
            "height": 8
          }),
        __h('ElevatedButton', {
            "onPressed": this.__bind("onTap"),
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
          }, [
            __h('Text', {
                "$pos": [
                  "Elevated · Styled"
                ]
              })
          ]),
        __h('SizedBox', {
            "height": 8
          }),
        __h('TextButton', {
            "onPressed": this.__bind("onTap"),
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
          }, [
            __h('Text', {
                "$pos": [
                  "TextButton"
                ]
              })
          ]),
        __h('SizedBox', {
            "height": 8
          }),
        __h('OutlinedButton', {
            "onPressed": this.__bind("onTap"),
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
          }, [
            __h('Text', {
                "$pos": [
                  "OutlinedButton"
                ]
              })
          ]),
        __h('SizedBox', {
            "height": 8
          }),
        __h('ElevatedButton', {}, [
            __h('Text', {
                "$pos": [
                  "Disabled"
                ]
              })
          ])
      ]);
  }
}

// 组件 LayoutDetail
export class LayoutDetail {
  constructor() {
  }
  build(context) {
    return __h('Column', {
        "crossAxisAlignment": "stretch"
      }, [
        __h('Text', {
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            },
            "$pos": [
              "Row + Expanded / Flexible / Spacer"
            ]
          }),
        __h('Row', {}, [
            __h('Expanded', {
                "flex": 1
              }, [
                __h('Container', {
                    "color": '@Colors.blue.shade100',
                    "padding": {
                      "left": 8.0,
                      "top": 8.0,
                      "right": 8.0,
                      "bottom": 8.0
                    }
                  }, [
                    __h('Text', {
                        "textAlign": "center",
                        "$pos": [
                          "A"
                        ]
                      })
                  ])
              ]),
            __h('Spacer', {
                "flex": 1
              }),
            __h('Expanded', {
                "flex": 2
              }, [
                __h('Container', {
                    "color": '@Colors.green.shade100',
                    "padding": {
                      "left": 8.0,
                      "top": 8.0,
                      "right": 8.0,
                      "bottom": 8.0
                    }
                  }, [
                    __h('Text', {
                        "textAlign": "center",
                        "$pos": [
                          "B（flex=2）"
                        ]
                      })
                  ])
              ])
          ]),
        __h('SizedBox', {
            "height": 12
          }),
        __h('Text', {
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            },
            "$pos": [
              "Center / Align / Padding / SizedBox"
            ]
          }),
        __h('Center', {}, [
            __h('Container', {
                "color": '@Colors.amber.shade100',
                "padding": {
                  "left": 12.0,
                  "top": 12.0,
                  "right": 12.0,
                  "bottom": 12.0
                }
              }, [
                __h('Text', {
                    "$pos": [
                      "Center 居中"
                    ]
                  })
              ])
          ]),
        __h('SizedBox', {
            "height": 8
          }),
        __h('Align', {
            "alignment": "centerLeft"
          }, [
            __h('Container', {
                "color": '@Colors.purple.shade50',
                "padding": {
                  "left": 8.0,
                  "top": 8.0,
                  "right": 8.0,
                  "bottom": 8.0
                }
              }, [
                __h('Text', {
                    "$pos": [
                      "Align centerLeft"
                    ]
                  })
              ])
          ]),
        __h('SizedBox', {
            "height": 8
          }),
        __h('Padding', {
            "padding": {
              "left": 8.0,
              "top": 4.0,
              "right": 8.0,
              "bottom": 4.0
            }
          }, [
            __h('Text', {
                "$pos": [
                  "Padding 包裹文案"
                ]
              })
          ]),
        __h('SizedBox', {
            "height": 12
          }),
        __h('Text', {
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            },
            "$pos": [
              "Stack + Positioned"
            ]
          }),
        __h('SizedBox', {
            "height": 100
          }, [
            __h('Stack', {
                "fit": "expand",
                "clipBehavior": "hardEdge"
              }, [
                __h('Container', {
                    "color": '@Colors.grey.shade200'
                  }),
                __h('Positioned', {}, [
                    __h('Center', {}, [
                        __h('Text', {
                            "style": {
                              "color": '#FFFFFF',
                              "fontWeight": "bold"
                            },
                            "$pos": [
                              "FILL"
                            ]
                          })
                      ])
                  ]),
                __h('Positioned', {
                    "left": 12,
                    "top": 12
                  }, [
                    __h('Text', {
                        "$pos": [
                          "TL"
                        ]
                      })
                  ]),
                __h('Positioned', {
                    "right": 12,
                    "bottom": 12
                  }, [
                    __h('Text', {
                        "$pos": [
                          "BR"
                        ]
                      })
                  ])
              ])
          ]),
        __h('SizedBox', {
            "height": 12
          }),
        __h('Text', {
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            },
            "$pos": [
              "Wrap · 自动换行"
            ]
          }),
        __h('Wrap', {
            "direction": "horizontal",
            "spacing": 8,
            "runSpacing": 8,
            "alignment": "start",
            "runAlignment": "center",
            "crossAxisAlignment": "center"
          }, [
            ...(() => { var out = []; for (let i = 1; (i <= 5); (i++)) { out.push.apply(out, [__h('Chip', { "label": __h('Text', { "$pos": [ "chip " + i ] }), "backgroundColor": '@Colors.teal.shade50' })]); } return out; })()
          ]),
        __h('SizedBox', {
            "height": 12
          }),
        __h('Text', {
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            },
            "$pos": [
              "Opacity / ConstrainedBox / AspectRatio / FractionallySizedBox"
            ]
          }),
        __h('Opacity', {
            "opacity": 0.5
          }, [
            __h('Container', {
                "color": '#F44336',
                "padding": {
                  "left": 8.0,
                  "top": 8.0,
                  "right": 8.0,
                  "bottom": 8.0
                }
              }, [
                __h('Text', {
                    "$pos": [
                      "50% 透明"
                    ]
                  })
              ])
          ]),
        __h('SizedBox', {
            "height": 8
          }),
        __h('ConstrainedBox', {
            "constraints": {
              "minWidth": 120,
              "maxWidth": 200
            }
          }, [
            __h('Container', {
                "color": '@Colors.orange.shade100',
                "padding": {
                  "left": 8.0,
                  "top": 8.0,
                  "right": 8.0,
                  "bottom": 8.0
                }
              }, [
                __h('Text', {
                    "$pos": [
                      "ConstrainedBox 宽度 120-200"
                    ]
                  })
              ])
          ]),
        __h('SizedBox', {
            "height": 8
          }),
        __h('AspectRatio', {
            "aspectRatio": 1.78
          }, [
            __h('Container', {
                "color": '@Colors.indigo.shade100',
                "alignment": "center"
              }, [
                __h('Text', {
                    "$pos": [
                      "16:9 比例"
                    ]
                  })
              ])
          ]),
        __h('SizedBox', {
            "height": 8
          }),
        __h('FractionallySizedBox', {
            "widthFactor": 0.6,
            "alignment": "center"
          }, [
            __h('Container', {
                "color": '@Colors.pink.shade100',
                "padding": {
                  "left": 8.0,
                  "top": 8.0,
                  "right": 8.0,
                  "bottom": 8.0
                }
              }, [
                __h('Text', {
                    "textAlign": "center",
                    "$pos": [
                      "60% 宽度"
                    ]
                  })
              ])
          ])
      ]);
  }
}

// 组件 ImageDetail
export class ImageDetail {
  constructor() {
  }
  build(context) {
    return __h('Column', {
        "crossAxisAlignment": "stretch"
      }, [
        __h('Text', {
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            },
            "$pos": [
              "Image · 网络图片"
            ]
          }),
        __h('ClipRRect', {
            "borderRadius": {
              "radius": 12.0
            }
          }, [
            __h('Image', {
                "height": 120,
                "fit": "cover",
                "$pos": [
                  "https://picsum.photos/seed/hotpatch/400/160"
                ]
              })
          ]),
        __h('SizedBox', {
            "height": 12
          }),
        __h('Text', {
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            },
            "$pos": [
              "CachedNetworkImage · 磁盘缓存网络图"
            ]
          }),
        __h('ClipRRect', {
            "borderRadius": {
              "radius": 12.0
            }
          }, [
            __h('CachedNetworkImage', {
                "imageUrl": "https://picsum.photos/seed/hotpatchcache/400/160",
                "height": 120,
                "fit": "cover"
              })
          ]),
        __h('SizedBox', {
            "height": 12
          }),
        __h('Text', {
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            },
            "$pos": [
              "Icon / CircleAvatar"
            ]
          }),
        __h('Row', {}, [
            __h('Icon', {
                "color": '#FFC107',
                "size": 28,
                "$pos": [
                  "star"
                ]
              }),
            __h('SizedBox', {
                "width": 12
              }),
            __h('Icon', {
                "color": '#2196F3',
                "size": 28,
                "$pos": [
                  "home"
                ]
              }),
            __h('SizedBox', {
                "width": 12
              }),
            __h('Icon', {
                "color": '#F44336',
                "size": 28,
                "$pos": [
                  "favorite"
                ]
              }),
            __h('SizedBox', {
                "width": 12
              }),
            __h('CircleAvatar', {
                "radius": 20,
                "backgroundColor": '#009688'
              }, [
                __h('Text', {
                    "style": {
                      "color": '#FFFFFF'
                    },
                    "$pos": [
                      "AV"
                    ]
                  })
              ])
          ])
      ]);
  }
}

// 组件 ContainerDetail
export class ContainerDetail {
  constructor() {
  }
  build(context) {
    return __h('Column', {
        "crossAxisAlignment": "stretch"
      }, [
        __h('Text', {
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            },
            "$pos": [
              "Container · 颜色/圆角/Padding"
            ]
          }),
        __h('Container', {
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
            __h('Text', {
                "style": {
                  "color": '#FFFFFF'
                },
                "$pos": [
                  "容器内容（teal 圆角）"
                ]
              })
          ]),
        __h('SizedBox', {
            "height": 12
          }),
        __h('Text', {
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            },
            "$pos": [
              "Container · 边框 + 阴影 + 渐变"
            ]
          }),
        __h('Container', {
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
            __h('Text', {
                "style": {
                  "color": '#FFFFFF'
                },
                "$pos": [
                  "渐变 + 边框 + 阴影"
                ]
              })
          ]),
        __h('SizedBox', {
            "height": 12
          }),
        __h('Text', {
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            },
            "$pos": [
              "DecoratedBox · 纯装饰"
            ]
          }),
        __h('DecoratedBox', {
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
            __h('Padding', {
                "padding": {
                  "left": 12.0,
                  "top": 12.0,
                  "right": 12.0,
                  "bottom": 12.0
                }
              }, [
                __h('Text', {
                    "$pos": [
                      "DecoratedBox 内容"
                    ]
                  })
              ])
          ]),
        __h('SizedBox', {
            "height": 12
          }),
        __h('Text', {
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            },
            "$pos": [
              "Card · shape / clipBehavior"
            ]
          }),
        __h('Card', {
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
            "clipBehavior": "antiAlias"
          }, [
            __h('Padding', {
                "padding": {
                  "left": 16.0,
                  "top": 16.0,
                  "right": 16.0,
                  "bottom": 16.0
                }
              }, [
                __h('Text', {
                    "$pos": [
                      "圆角卡片 + 描边 + 阴影"
                    ]
                  })
              ])
          ]),
        __h('SizedBox', {
            "height": 12
          }),
        __h('Divider', {}),
        __h('SizedBox', {
            "height": 12
          }),
        __h('Text', {
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            },
            "$pos": [
              "SizedBox · 尺寸约束"
            ]
          }),
        __h('Container', {
            "width": 120,
            "height": 48,
            "alignment": "center",
            "color": '@Colors.blueGrey.shade100'
          }, [
            __h('Text', {
                "$pos": [
                  "固定 120×48"
                ]
              })
          ])
      ]);
  }
}

// 组件 ScrollDetail
export class ScrollDetail {
  constructor() {
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
    return __h('Column', {
        "crossAxisAlignment": "stretch"
      }, [
        __h('Text', {
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            },
            "$pos": [
              "ListView.builder · 懒构建列表（offset: " + this._offset + "）"
            ]
          }),
        __h('NotificationListener', {
            "onNotification": this.__bind("_onListScroll"),
            "model": "ScrollNotification"
          }, [
            __h('SizedBox', {
                "height": 160
              }, [
                __h(ListView, {
                    "padding": {
                      "left": 8.0,
                      "top": 8.0,
                      "right": 8.0,
                      "bottom": 8.0
                    },
                    "itemExtent": 56,
                    "physics": "BouncingScrollPhysics",
                    "itemCount": 5,
                    "itemBuilder": "_itemBuilder0"
                  })
              ])
          ]),
        __h('SizedBox', {
            "height": 12
          }),
        __h('Text', {
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            },
            "$pos": [
              "ListView.separated · 分隔列表"
            ]
          }),
        __h('SizedBox', {
            "height": 140
          }, [
            __h(ListView, {
                "padding": {
                  "left": 8.0,
                  "top": 8.0,
                  "right": 8.0,
                  "bottom": 8.0
                },
                "itemCount": 6,
                "separatorBuilder": "_separatorBuilder1",
                "itemBuilder": "_itemBuilder2"
              })
          ]),
        __h('SizedBox', {
            "height": 12
          }),
        __h('Text', {
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            },
            "$pos": [
              "SingleChildScrollView · 长内容滚动（ctrl offset: " + this._ctrlOffset + "）"
            ]
          }),
        __h('SingleChildScrollView', {
            "controller": this._scrollController,
            "scrollDirection": "horizontal",
            "physics": "ClampingScrollPhysics"
          }, [
            __h('Row', {}, [
                ...(() => { var out = []; for (let i = 1; (i <= 8); (i++)) { out.push.apply(out, [__h('Padding', { "padding": { "left": 4.0, "top": 4.0, "right": 4.0, "bottom": 4.0 } }, [ __h('Chip', { "label": __h('Text', { "$pos": [ "横向 " + i ] }) }) ])]); } return out; })()
              ])
          ]),
        __h('Align', {
            "alignment": "centerLeft"
          }, [
            __h('TextButton', {
                "onPressed": this.__bind("_scrollToEnd")
              }, [
                __h('Text', {
                    "$pos": [
                      "横向 · 跳到底"
                    ]
                  })
              ])
          ])
      ]);
  }
  _itemBuilder0(context, index) {
      return __h('ListTile', {
        "leading": __h('Icon', {
            "$pos": [
              "list"
            ]
          }),
        "title": __h('Text', {
            "$pos": [
              "builder item " + index
            ]
          })
      });
  }
  _separatorBuilder1(context, index) {
      return __h('Divider', {
        "height": 1
      });
  }
  _itemBuilder2(context, index) {
      return __h('ListTile', {
        "dense": true,
        "leading": __h('Icon', {
            "color": '@Colors.teal.shade300',
            "$pos": [
              "arrow_right"
            ]
          }),
        "title": __h('Text', {
            "$pos": [
              "separated item " + index
            ]
          })
      });
  }
}

// 组件 SliverDetail
export class SliverDetail {
  constructor() {
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
    this.setState(() => { this._measureText = "x=" + rect.dx.toFixed(1) + " y=" + rect.dy.toFixed(1) + " · " + rect.width.toFixed(0) + " × " + rect.height.toFixed(0); });
  }
  build(context) {
    return __h('Scaffold', {
        "body": __h('CustomScrollView', {
            "controller": this._controller,
            "physics": "BouncingScrollPhysics"
          }, [
            __h('SliverAppBar', {
                "title": __h('Text', {
                    "$pos": [
                      "SliverAppBar 导航 · offset " + this._offset.toFixed(0)
                    ]
                  }),
                "backgroundColor": '#673AB7',
                "foregroundColor": '#FFFFFF',
                "pinned": true,
                "floating": true,
                "actions": [
                  __h('IconButton', {
                      "icon": __h('Icon', {
                          "$pos": [
                            "center_focus_strong"
                          ]
                        }),
                      "tooltip": "定位到「固定高度」分区",
                      "onPressed": this.__bind("_scrollToFixed")
                    }),
                  __h('IconButton', {
                      "icon": __h('Icon', {
                          "$pos": [
                            "straighten"
                          ]
                        }),
                      "tooltip": "测量「固定高度」分区的位置与尺寸",
                      "onPressed": this.__bind("_measureFixed")
                    })
                ]
              }),
            __h('SliverToBoxAdapter', {}, [
                __h('Container', {
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
                      "color": '@Colors.deepPurple.shade50',
                      "borderRadius": {
                        "radius": 12.0
                      }
                    }
                  }, [
                    __h('Text', {
                        "style": {
                          "fontSize": 14,
                          "fontWeight": "bold"
                        },
                        "$pos": [
                          "CustomScrollView 整页 · SliverToBoxAdapter 盒子"
                        ]
                      })
                  ])
              ]),
            __h('SliverToBoxAdapter', {}, [
                __h('Container', {
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
                      "color": '@Colors.teal.shade50',
                      "borderRadius": {
                        "radius": 8.0
                      }
                    }
                  }, [
                    __h('Text', {
                        "style": {
                          "fontSize": 13,
                          "color": '#009688'
                        },
                        "$pos": [
                          "GlobalKey 测量：「固定高度」分区 " + this._measureText
                        ]
                      })
                  ])
              ]),
            __h('SliverPadding', {
                "padding": {
                  "left": 12.0,
                  "top": 0.0,
                  "right": 12.0,
                  "bottom": 0.0
                }
              }, [
                __h('SliverList', {}, [
                    ...(() => { var out = []; for (let i = 1; (i <= 5); (i++)) { out.push.apply(out, [__h('ListTile', { "leading": __h('Icon', { "color": '#673AB7', "$pos": [ "list" ] }), "title": __h('Text', { "$pos": [ "SliverList item " + i ] }), "trailing": __h('Icon', { "$pos": [ "chevron_right" ] }) })]); } return out; })()
                  ])
              ]),
            __h('SliverPadding', {
                "padding": {
                  "left": 12.0,
                  "top": 8.0,
                  "right": 12.0,
                  "bottom": 8.0
                }
              }, [
                __h('SliverToBoxAdapter', {}, [
                    __h('Text', {
                        "style": {
                          "fontSize": 14,
                          "fontWeight": "bold"
                        },
                        "$pos": [
                          "SliverList.builder · 懒构建列表"
                        ]
                      })
                  ])
              ]),
            __h('SliverPadding', {
                "padding": {
                  "left": 12.0,
                  "top": 0.0,
                  "right": 12.0,
                  "bottom": 0.0
                }
              }, [
                __h(SliverList, {
                    "itemCount": 8,
                    "itemBuilder": "_itemBuilder0"
                  })
              ]),
            __h('SliverPadding', {
                "padding": {
                  "left": 12.0,
                  "top": 8.0,
                  "right": 12.0,
                  "bottom": 8.0
                }
              }, [
                __h('SliverToBoxAdapter', {}, [
                    __h('Text', {
                        "style": {
                          "fontSize": 14,
                          "fontWeight": "bold"
                        },
                        "$pos": [
                          "SliverList.separated · 分隔列表"
                        ]
                      })
                  ])
              ]),
            __h('SliverPadding', {
                "padding": {
                  "left": 12.0,
                  "top": 0.0,
                  "right": 12.0,
                  "bottom": 0.0
                }
              }, [
                __h(SliverList, {
                    "itemCount": 5,
                    "itemBuilder": "_itemBuilder1",
                    "separatorBuilder": "_separatorBuilder2"
                  })
              ]),
            __h('SliverPadding', {
                "padding": {
                  "left": 12.0,
                  "top": 8.0,
                  "right": 12.0,
                  "bottom": 8.0
                }
              }, [
                __h('SliverToBoxAdapter', {}, [
                    __h('Container', {
                        "key": this._fixedKey,
                        "padding": {
                          "left": 10.0,
                          "top": 8.0,
                          "right": 10.0,
                          "bottom": 8.0
                        },
                        "decoration": {
                          "color": '@Colors.teal.shade50',
                          "borderRadius": {
                            "radius": 6.0
                          }
                        }
                      }, [
                        __h('Text', {
                            "style": {
                              "fontSize": 14,
                              "fontWeight": "bold"
                            },
                            "$pos": [
                              "SliverFixedExtentList · 固定高度"
                            ]
                          })
                      ])
                  ])
              ]),
            __h('SliverPadding', {
                "padding": {
                  "left": 12.0,
                  "top": 0.0,
                  "right": 12.0,
                  "bottom": 0.0
                }
              }, [
                __h(SliverFixedExtentList, {
                    "itemExtent": 44,
                    "builder": "_builder3",
                    "childCount": 6
                  })
              ]),
            __h('SliverPadding', {
                "padding": {
                  "left": 12.0,
                  "top": 8.0,
                  "right": 12.0,
                  "bottom": 8.0
                }
              }, [
                __h('SliverToBoxAdapter', {}, [
                    __h('Text', {
                        "style": {
                          "fontSize": 14,
                          "fontWeight": "bold"
                        },
                        "$pos": [
                          "SliverOpacity + SliverGrid.builder · MaxCrossAxisExtent 九宫格"
                        ]
                      })
                  ])
              ]),
            __h('SliverOpacity', {
                "opacity": 0.6
              }, [
                __h('SliverPadding', {
                    "padding": {
                      "left": 12.0,
                      "top": 0.0,
                      "right": 12.0,
                      "bottom": 0.0
                    }
                  }, [
                    __h(SliverGrid, {
                        "gridDelegate": __h('SliverGridDelegateWithMaxCrossAxisExtent', {
                            "maxCrossAxisExtent": 140,
                            "mainAxisSpacing": 8,
                            "crossAxisSpacing": 8,
                            "childAspectRatio": 1
                          }),
                        "itemCount": 9,
                        "itemBuilder": "_itemBuilder4"
                      })
                  ])
              ]),
            __h('SliverSafeArea', {}, [
                __h('SliverFillRemaining', {
                    "hasScrollBody": false
                  }, [
                    __h('Center', {}, [
                        __h('Text', {
                            "style": {
                              "color": '#9E9E9E'
                            },
                            "$pos": [
                              "底部 · SliverSafeArea + SliverFillRemaining"
                            ]
                          })
                      ])
                  ])
              ])
          ]),
        "floatingActionButton": __h('FloatingActionButton', {
            "onPressed": this.__bind("_scrollToEnd"),
            "backgroundColor": '#673AB7',
            "foregroundColor": '#FFFFFF',
            "tooltip": "跳到底"
          }, [
            __h('Icon', {
                "$pos": [
                  "arrow_downward"
                ]
              })
          ])
      });
  }
  _itemBuilder0(context, index) {
      return __h('ListTile', {
        "leading": __h('Icon', {
            "color": '@Colors.orange.shade700',
            "$pos": [
              "build"
            ]
          }),
        "title": __h('Text', {
            "$pos": [
              "builder item " + index
            ]
          }),
        "subtitle": __h('Text', {
            "$pos": [
              "index * 10 = " + (index * 10)
            ]
          })
      });
  }
  _itemBuilder1(context, index) {
      return __h('ListTile', {
        "dense": true,
        "leading": __h('Icon', {
            "color": '#673AB7',
            "$pos": [
              "arrow_right"
            ]
          }),
        "title": __h('Text', {
            "$pos": [
              "separated item " + index
            ]
          })
      });
  }
  _separatorBuilder2(context, index) {
      return __h('Divider', {
        "height": 1
      });
  }
  _builder3(context, index) {
      return __h('ListTile', {
        "dense": true,
        "leading": __h('Icon', {
            "color": '#009688',
            "$pos": [
              "height"
            ]
          }),
        "title": __h('Text', {
            "$pos": [
              "fixed item " + index
            ]
          })
      });
  }
  _itemBuilder4(context, index) {
      return __h('Container', {
        "decoration": {
          "color": '@Colors.teal.shade100',
          "borderRadius": {
            "radius": 8.0
          }
        },
        "alignment": "center"
      }, [
        __h('Text', {
            "style": {
              "fontWeight": "bold"
            },
            "$pos": [
              "格 " + index
            ]
          })
      ]);
  }
}

// 组件 GridDetail
export class GridDetail {
  constructor() {
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
    return __h('Scaffold', {
        "backgroundColor": '@Colors.grey.shade50',
        "appBar": __h('AppBar', {
            "title": __h('Text', {
                "$pos": [
                  "GridView 懒加载验证"
                ]
              }),
            "backgroundColor": '#009688',
            "foregroundColor": '#FFFFFF'
          }),
        "floatingActionButton": __h('FloatingActionButton', {
            "onPressed": this.__bind("_jumpBottom"),
            "backgroundColor": '#009688',
            "foregroundColor": '#FFFFFF',
            "tooltip": "跳到底"
          }, [
            __h('Icon', {
                "$pos": [
                  "arrow_downward"
                ]
              })
          ]),
        "body": __h('Column', {
            "crossAxisAlignment": "stretch"
          }, [
            __h('Padding', {
                "padding": {
                  "left": 12.0,
                  "top": 12.0,
                  "right": 12.0,
                  "bottom": 12.0
                }
              }, [
                __h('Text', {
                    "style": {
                      "fontSize": 13,
                      "color": '#9E9E9E'
                    },
                    "$pos": [
                      "controller offset: " + this._offset.toFixed(1)
                    ]
                  })
              ]),
            __h('Padding', {
                "padding": {
                  "left": 12.0,
                  "top": 0.0,
                  "right": 12.0,
                  "bottom": 0.0
                }
              }, [
                __h('Text', {
                    "style": {
                      "fontSize": 14,
                      "fontWeight": "bold"
                    },
                    "$pos": [
                      "GridView.builder · 固定 3 列 · 30 项（懒加载）"
                    ]
                  })
              ]),
            __h('Expanded', {
                "flex": 5
              }, [
                __h(GridView, {
                    "controller": this._controller,
                    "gridDelegate": __h('SliverGridDelegateWithFixedCrossAxisCount', {
                        "crossAxisCount": 3,
                        "mainAxisSpacing": 8,
                        "crossAxisSpacing": 8,
                        "childAspectRatio": 1
                      }),
                    "itemCount": 30,
                    "itemBuilder": "_itemBuilder0"
                  })
              ]),
            __h('Padding', {
                "padding": {
                  "left": 12.0,
                  "top": 8.0,
                  "right": 12.0,
                  "bottom": 8.0
                }
              }, [
                __h('Text', {
                    "style": {
                      "fontSize": 14,
                      "fontWeight": "bold"
                    },
                    "$pos": [
                      "GridView.builder · MaxCrossAxisExtent 120 · 20 项（懒加载）"
                    ]
                  })
              ]),
            __h('Expanded', {
                "flex": 4
              }, [
                __h(GridView, {
                    "gridDelegate": __h('SliverGridDelegateWithMaxCrossAxisExtent', {
                        "maxCrossAxisExtent": 120,
                        "mainAxisSpacing": 8,
                        "crossAxisSpacing": 8,
                        "childAspectRatio": 1
                      }),
                    "itemCount": 20,
                    "itemBuilder": "_itemBuilder1"
                  })
              ])
          ])
      });
  }
  _itemBuilder0(context, index) {
      return __h('Container', {
        "decoration": {
          "color": '@Colors.teal.shade100',
          "borderRadius": {
            "radius": 8.0
          }
        },
        "alignment": "center"
      }, [
        __h('Text', {
            "style": {
              "fontWeight": "bold"
            },
            "$pos": [
              "格 " + index
            ]
          })
      ]);
  }
  _itemBuilder1(context, index) {
      return __h('Container', {
        "decoration": {
          "color": '@Colors.orange.shade100',
          "borderRadius": {
            "radius": 8.0
          }
        },
        "alignment": "center"
      }, [
        __h('Text', {
            "style": {
              "fontWeight": "bold"
            },
            "$pos": [
              "项 " + index
            ]
          })
      ]);
  }
}

// 组件 ScaffoldDetail
export class ScaffoldDetail {
  constructor() {
    this._navIndex = 0;
  }
  _onNavTap(index) {
    this.setState(() => { this._navIndex = index; });
  }
  _onFab() {
  }
  build(context) {
    return __h('Scaffold', {
        "backgroundColor": '@Colors.grey.shade50',
        "appBar": __h('AppBar', {
            "leading": __h('Icon', {
                "$pos": [
                  "menu"
                ]
              }),
            "title": __h('Text', {
                "$pos": [
                  "Scaffold / AppBar / FAB / BottomNav"
                ]
              }),
            "backgroundColor": '#673AB7',
            "foregroundColor": '#FFFFFF',
            "elevation": 4,
            "centerTitle": true,
            "toolbarHeight": 56,
            "actions": [
              __h('Icon', {
                  "color": '#FFFFFF',
                  "$pos": [
                    "search"
                  ]
                }),
              __h('SizedBox', {
                  "width": 16
                })
            ]
          }),
        "body": __h('SafeArea', {}, [
            __h('Center', {}, [
                __h('Column', {
                    "mainAxisAlignment": "center"
                  }, [
                    __h('Icon', {
                        "size": 48,
                        "color": '#673AB7',
                        "$pos": [
                          "extension"
                        ]
                      }),
                    __h('SizedBox', {
                        "height": 12
                      }),
                    __h('Text', {
                        "$pos": [
                          "页面骨架组件演示"
                        ]
                      }),
                    __h('Text', {
                        "$pos": [
                          "BottomNav 选中：" + this._navIndex
                        ]
                      })
                  ])
              ])
          ]),
        "floatingActionButton": __h('FloatingActionButton', {
            "onPressed": this.__bind("_onFab"),
            "backgroundColor": '#673AB7',
            "foregroundColor": '#FFFFFF',
            "tooltip": "添加"
          }, [
            __h('Icon', {
                "$pos": [
                  "add"
                ]
              })
          ]),
        "bottomNavigationBar": __h('BottomNavigationBar', {
            "currentIndex": this._navIndex,
            "onTap": this.__bind("_onNavTap"),
            "selectedItemColor": '#673AB7',
            "unselectedItemColor": '#9E9E9E',
            "items": [
              __h('BottomNavigationBarItem', {
                  "icon": __h('Icon', {
                      "$pos": [
                        "home"
                      ]
                    }),
                  "label": "首页"
                }),
              __h('BottomNavigationBarItem', {
                  "icon": __h('Icon', {
                      "$pos": [
                        "search"
                      ]
                    }),
                  "label": "搜索"
                }),
              __h('BottomNavigationBarItem', {
                  "icon": __h('Icon', {
                      "$pos": [
                        "person"
                      ]
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
  constructor() {
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
    return __h('Column', {
        "crossAxisAlignment": "stretch"
      }, [
        __h('Text', {
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            },
            "$pos": [
              "TextField"
            ]
          }),
        __h('TextField', {
            "controller": this._controller,
            "onChanged": this.__bind("_onTextChanged"),
            "decoration": __h('InputDecoration', {
                "hintText": "请输入文本",
                "labelText": "用户名"
              }),
            "maxLines": 1,
            "style": {
              "fontSize": 16
            }
          }),
        __h('SizedBox', {
            "height": 4
          }),
        __h('Text', {
            "style": {
              "fontSize": 14,
              "color": '#9E9E9E'
            },
            "$pos": [
              "输入内容：" + this._text
            ]
          }),
        __h('Text', {
            "style": {
              "fontSize": 14,
              "color": '#673AB7'
            },
            "$pos": [
              "controller.text：" + this._controller.text
            ]
          }),
        __h('SizedBox', {
            "height": 8
          }),
        __h('Align', {
            "alignment": "centerLeft"
          }, [
            __h('FilledButton', {
                "onPressed": this.__bind("this._controller.clear()")
              }, [
                __h('Text', {
                    "$pos": [
                      "清空输入"
                    ]
                  })
              ])
          ]),
        __h('SizedBox', {
            "height": 12
          }),
        __h('Text', {
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            },
            "$pos": [
              "Radio 单选"
            ]
          }),
        __h('Row', {}, [
            __h('Radio', {
                "value": "A",
                "groupValue": this._choice,
                "onChanged": this.__bind("_onChoiceChanged"),
                "activeColor": '#673AB7'
              }),
            __h('Text', {
                "$pos": [
                  "选项 A"
                ]
              }),
            __h('Radio', {
                "value": "B",
                "groupValue": this._choice,
                "onChanged": this.__bind("_onChoiceChanged"),
                "activeColor": '#673AB7'
              }),
            __h('Text', {
                "$pos": [
                  "选项 B"
                ]
              })
          ]),
        __h('Text', {
            "style": {
              "fontSize": 14,
              "color": '#9E9E9E'
            },
            "$pos": [
              "当前选择：" + this._choice
            ]
          }),
        __h('SizedBox', {
            "height": 12
          }),
        __h('Text', {
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            },
            "$pos": [
              "DropdownButton"
            ]
          }),
        __h('DropdownButton', {
            "value": this._dropdown,
            "isExpanded": true,
            "onChanged": this.__bind("_onDropdownChanged"),
            "items": [
              __h('DropdownMenuItem', {
                  "value": "苹果"
                }, [
                  __h('Text', {
                      "$pos": [
                        "苹果"
                      ]
                    })
                ]),
              __h('DropdownMenuItem', {
                  "value": "香蕉"
                }, [
                  __h('Text', {
                      "$pos": [
                        "香蕉"
                      ]
                    })
                ]),
              __h('DropdownMenuItem', {
                  "value": "橙子"
                }, [
                  __h('Text', {
                      "$pos": [
                        "橙子"
                      ]
                    })
                ])
            ]
          }),
        __h('SizedBox', {
            "height": 12
          }),
        __h('Row', {}, [
            __h('Switch', {
                "value": this._switchOn,
                "onChanged": this.__bind("_onSwitchChanged"),
                "activeColor": '#FFFFFF',
                "activeTrackColor": '#673AB7',
                "inactiveThumbColor": '#9E9E9E',
                "inactiveTrackColor": '@Colors.grey.shade300'
              }),
            __h('SizedBox', {
                "width": 8
              }),
            __h('Text', {
                "$pos": [
                  "Switch：" + (this._switchOn ? "开" : "关")
                ]
              })
          ]),
        __h('Row', {}, [
            __h('Checkbox', {
                "value": this._checked,
                "onChanged": this.__bind("_onCheckChanged"),
                "activeColor": '#673AB7',
                "checkColor": '#FFFFFF'
              }),
            __h('SizedBox', {
                "width": 8
              }),
            __h('Text', {
                "$pos": [
                  "Checkbox：" + (this._checked ?? false)
                ]
              })
          ]),
        __h('SizedBox', {
            "height": 8
          }),
        __h('Text', {
            "style": {
              "fontSize": 14
            },
            "$pos": [
              "Slider 值：" + this._slider
            ]
          }),
        __h('Slider', {
            "value": this._slider,
            "min": 0,
            "max": 1,
            "divisions": 10,
            "label": ((this._slider * 100)).round() + "%",
            "activeColor": '#673AB7',
            "inactiveColor": '@Colors.grey.shade300',
            "onChanged": this.__bind("_onSliderChanged")
          })
      ]);
  }
}

// 组件 ProgressDetail
export class ProgressDetail {
  constructor() {
    this._progress = 0.65;
  }
  build(context) {
    return __h('Column', {
        "crossAxisAlignment": "stretch"
      }, [
        __h('Text', {
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            },
            "$pos": [
              "CircularProgressIndicator"
            ]
          }),
        __h('SizedBox', {
            "height": 8
          }),
        __h('Row', {}, [
            __h('CircularProgressIndicator', {
                "value": this._progress,
                "color": '#673AB7',
                "backgroundColor": '@Colors.deepPurple.shade50',
                "strokeWidth": 6
              }),
            __h('SizedBox', {
                "width": 24
              }),
            __h('CircularProgressIndicator', {})
          ]),
        __h('SizedBox', {
            "height": 16
          }),
        __h('Text', {
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            },
            "$pos": [
              "LinearProgressIndicator"
            ]
          }),
        __h('SizedBox', {
            "height": 8
          }),
        __h('LinearProgressIndicator', {
            "value": this._progress,
            "color": '#673AB7',
            "backgroundColor": '@Colors.deepPurple.shade50',
            "minHeight": 8
          }),
        __h('SizedBox', {
            "height": 4
          }),
        __h('LinearProgressIndicator', {}),
        __h('SizedBox', {
            "height": 8
          }),
        __h('Text', {
            "style": {
              "fontSize": 14,
              "color": '#9E9E9E'
            },
            "$pos": [
              "进度值：" + this._progress
            ]
          })
      ]);
  }
}

// 组件 NotifierCard
export class NotifierCard {
  constructor() {
    this._model = new CounterVm({});
  }
  _inc() {
    this._model.inc();
  }
  _reset() {
    this._model.reset();
  }
  build(context) {
    return __h('Card', {}, [
        __h('Padding', {
            "padding": {
              "left": 16.0,
              "top": 16.0,
              "right": 16.0,
              "bottom": 16.0
            }
          }, [
            __h('Column', {
                "mainAxisSize": "min"
              }, [
                __h(ListenableBuilder, {
                    "listenable": this._model,
                    "builder": "_builder0"
                  }),
                __h('SizedBox', {
                    "height": 12
                  }),
                __h('Row', {
                    "mainAxisAlignment": "center"
                  }, [
                    __h('ElevatedButton', {
                        "onPressed": this.__bind("_inc")
                      }, [
                        __h('Text', {
                            "$pos": [
                              "+1"
                            ]
                          })
                      ]),
                    __h('SizedBox', {
                        "width": 12
                      }),
                    __h('ElevatedButton', {
                        "onPressed": this.__bind("_reset")
                      }, [
                        __h('Text', {
                            "$pos": [
                              "Reset"
                            ]
                          })
                      ])
                  ])
              ])
          ])
      ]);
  }
  dispose() {
    this._model.dispose();
  }
  _builder0(context, _) {
      return __h('Text', {
        "style": {
          "fontSize": 24,
          "fontWeight": "bold"
        },
        "$pos": [
          "count = " + this._model.count
        ]
      });
  }
}

// 组件 StatelessCard
export class StatelessCard {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.title = (args && args.title !== undefined) ? args.title : '';
    this.subtitle = (args && args.subtitle !== undefined) ? args.subtitle : "";
    this.badge = (args && args.badge !== undefined) ? args.badge : "NEW";
  }
  build(context) {
    return __h('Card', {
        "margin": {
          "left": 12.0,
          "top": 12.0,
          "right": 12.0,
          "bottom": 12.0
        }
      }, [
        __h('Padding', {
            "padding": {
              "left": 16.0,
              "top": 16.0,
              "right": 16.0,
              "bottom": 16.0
            }
          }, [
            __h('Column', {
                "mainAxisSize": "min",
                "crossAxisAlignment": "start"
              }, [
                __h('Row', {}, [
                    __h('Icon', {
                        "color": '#009688',
                        "$pos": [
                          "article"
                        ]
                      }),
                    __h('SizedBox', {
                        "width": 8
                      }),
                    __h('Expanded', {}, [
                        __h('Text', {
                            "style": {
                              "fontSize": 18,
                              "fontWeight": "bold"
                            },
                            "$pos": [
                              this.badge + " · " + this.title
                            ]
                          })
                      ])
                  ]),
                __h('Divider', {
                    "height": 24
                  }),
                __h('Text', {
                    "style": {
                      "fontSize": 14,
                      "color": '#9E9E9E'
                    },
                    "$pos": [
                      this.subtitle
                    ]
                  })
              ])
          ])
      ]);
  }
}

// 组件 TabDetail
export class TabDetail {
  constructor() {
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
    return __h('Column', {
        "crossAxisAlignment": "stretch"
      }, [
        __h('Text', {
            "style": {
              "fontSize": 15,
              "fontWeight": "bold"
            },
            "$pos": [
              "DefaultTabController · 官方惯用法（controller 由祖先提供）"
            ]
          }),
        __h('SizedBox', {
            "height": 6
          }),
        __h('SizedBox', {
            "height": 180
          }, [
            __h('DefaultTabController', {
                "length": 3
              }, [
                __h('Column', {}, [
                    __h('TabBar', {
                        "isScrollable": true,
                        "indicatorColor": '#673AB7',
                        "labelColor": '#673AB7',
                        "unselectedLabelColor": '#9E9E9E'
                      }, [
                        __h('Tab', {
                            "text": "广场"
                          }),
                        __h('Tab', {
                            "text": "推荐"
                          }),
                        __h('Tab', {
                            "text": "关注"
                          })
                      ]),
                    __h('Expanded', {}, [
                        __h('TabBarView', {}, [
                            __h('Center', {}, [
                                __h('Text', {
                                    "$pos": [
                                      "TabBarView · 广场"
                                    ]
                                  })
                              ]),
                            __h('Center', {}, [
                                __h('Text', {
                                    "$pos": [
                                      "TabBarView · 推荐"
                                    ]
                                  })
                              ]),
                            __h('Center', {}, [
                                __h('Text', {
                                    "$pos": [
                                      "TabBarView · 关注"
                                    ]
                                  })
                              ])
                          ])
                      ])
                  ])
              ])
          ]),
        __h('SizedBox', {
            "height": 14
          }),
        __h('Text', {
            "style": {
              "fontSize": 15,
              "fontWeight": "bold"
            },
            "$pos": [
              "显式 TabController · index = " + this._index
            ]
          }),
        __h('SizedBox', {
            "height": 6
          }),
        __h('SizedBox', {
            "height": 170
          }, [
            __h('Column', {}, [
                __h('TabBar', {
                    "controller": this._controller
                  }, [
                    __h('Tab', {
                        "text": "首页"
                      }),
                    __h('Tab', {
                        "text": "社区"
                      }),
                    __h('Tab', {
                        "text": "我的"
                      })
                  ]),
                __h('Expanded', {}, [
                    __h('TabBarView', {
                        "controller": this._controller
                      }, [
                        __h('Center', {}, [
                            __h('Text', {
                                "$pos": [
                                  "第 1 页（index 0）"
                                ]
                              })
                          ]),
                        __h('Center', {}, [
                            __h('Text', {
                                "$pos": [
                                  "第 2 页（index 1）"
                                ]
                              })
                          ]),
                        __h('Center', {}, [
                            __h('Text', {
                                "$pos": [
                                  "第 3 页（index 2）"
                                ]
                              })
                          ])
                      ])
                  ])
              ])
          ]),
        __h('Align', {
            "alignment": "centerLeft"
          }, [
            __h('TextButton', {
                "onPressed": this.__bind("_next")
              }, [
                __h('Text', {
                    "$pos": [
                      "下一 tab · controller.animateTo"
                    ]
                  })
              ])
          ])
      ]);
  }
}

// 组件 PageViewDetail
export class PageViewDetail {
  constructor() {
    this._page = 0;
  }
  _onPageChanged(index) {
    this.setState(() => { this._page = index; });
  }
  build(context) {
    return __h('Column', {
        "crossAxisAlignment": "stretch"
      }, [
        __h('Text', {
            "style": {
              "fontSize": 15,
              "fontWeight": "bold"
            },
            "$pos": [
              "PageView · 当前第 " + (this._page + 1) + " / 3 页"
            ]
          }),
        __h('SizedBox', {
            "height": 6
          }),
        __h('SizedBox', {
            "height": 150
          }, [
            __h('PageView', {
                "onPageChanged": this.__bind("_onPageChanged")
              }, [
                __h('Container', {
                    "color": '@Colors.deepPurple.shade100',
                    "alignment": "center"
                  }, [
                    __h('Text', {
                        "$pos": [
                          "第 1 页"
                        ]
                      })
                  ]),
                __h('Container', {
                    "color": '@Colors.teal.shade100',
                    "alignment": "center"
                  }, [
                    __h('Text', {
                        "$pos": [
                          "第 2 页"
                        ]
                      })
                  ]),
                __h('Container', {
                    "color": '@Colors.orange.shade100',
                    "alignment": "center"
                  }, [
                    __h('Text', {
                        "$pos": [
                          "第 3 页"
                        ]
                      })
                  ])
              ])
          ]),
        __h('SizedBox', {
            "height": 10
          }),
        __h('Row', {
            "mainAxisAlignment": "center"
          }, [
            ...(() => { var out = []; for (let i = 0; (i < 3); (i++)) { out.push.apply(out, [__h('Container', { "width": 9, "height": 9, "margin": { "left": 4.0, "top": 4.0, "right": 4.0, "bottom": 4.0 }, "decoration": { "shape": "circle", "color": ((i == this._page) ? '#673AB7' : '#ffbdbdbd') } })]); } return out; })()
          ])
      ]);
  }
}

// 组件 KeyTile
export class KeyTile {
  constructor(args) {
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
    return __h('Container', {
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
              "color": '@Colors.grey.shade300'
            }
          }
        }
      }, [
        __h('Row', {}, [
            __h('Expanded', {}, [
                __h('Text', {
                    "style": {
                      "fontSize": 13
                    },
                    "$pos": [
                      caption
                    ]
                  })
              ]),
            __h('TextButton', {
                "onPressed": this.__bind("bump")
              }, [
                __h('Text', {
                    "$pos": [
                      "+1"
                    ]
                  })
              ])
          ])
      ]);
  }
}

// 组件 KeyDetail
export class KeyDetail {
  constructor() {
    this._names = ["A", "B", "C", "D"];
    this._stableObj = [1];
    this._rebuildSeq = 0;
    this._uniqueSeq = 0;
    this._storeA = true;
    this._targetKey = new GlobalKey();
    this._measureText = "未测量";
  }
  _rotateNames() {
    this.setState(() => { var head = this._names[0]; this._names.splice(0, 1)[0]; this._names.push(head); });
  }
  _resetNames() {
    this.setState(() => { this._names.clear(); this._names.push("A"); this._names.push("B"); this._names.push("C"); this._names.push("D"); });
  }
  _valueKeyRows() {
    return __h('Column', {
        "crossAxisAlignment": "stretch"
      }, [
        __h('Text', {
            "style": {
              "fontSize": 13,
              "fontWeight": "bold"
            },
            "$pos": [
              "① 带 key：key: ValueKey(name)"
            ]
          }),
        ...(() => { var out = []; for (let i = 0; (i < this._names.length); (i++)) { out.push.apply(out, [__h(KeyTile, { "key": new ValueKey(this._names[i]), "index": i, "label": this._names[i] + "（key）" })]); } return out; })(),
        __h('SizedBox', {
            "height": 10
          }),
        __h('Text', {
            "style": {
              "fontSize": 13,
              "fontWeight": "bold"
            },
            "$pos": [
              "② 不带 key：按位置匹配"
            ]
          }),
        ...(() => { var out = []; for (let i = 0; (i < this._names.length); (i++)) { out.push.apply(out, [__h(KeyTile, { "index": i, "label": this._names[i] + "（无 key）" })]); } return out; })()
      ]);
  }
  _rebuildParent() {
    this.setState(() => { this._rebuildSeq += 1; });
  }
  _objectKeyRows() {
    return __h('Column', {
        "crossAxisAlignment": "stretch"
      }, [
        __h(KeyTile, {
            "key": new ObjectKey(this._stableObj),
            "index": 0,
            "label": "A · ObjectKey(字段实例) · 父级已重建 " + this._rebuildSeq + " 次"
          }),
        __h(KeyTile, {
            "key": new ObjectKey([1]),
            "index": 1,
            "label": "B · ObjectKey(每帧新造 [1]) · 父级已重建 " + this._rebuildSeq + " 次"
          })
      ]);
  }
  _bumpUnique() {
    this.setState(() => { this._uniqueSeq += 1; });
  }
  _flipStore() {
    this.setState(() => { this._storeA = (!this._storeA); });
  }
  _storageView() {
    if (this._storeA) {
      return __h('SizedBox', {
          "height": 150
        }, [
          __h('ListView', {
              "key": new PageStorageKey("key-page-a")
            }, [
              ...(() => { var out = []; for (let i = 0; (i < 12); (i++)) { out.push.apply(out, [__h('ListTile', { "dense": true, "title": __h('Text', { "$pos": [ "A 行 " + i ] }) })]); } return out; })()
            ])
        ]);
    }
    return __h('SizedBox', {
        "height": 150
      }, [
        __h('ListView', {
            "key": new PageStorageKey("key-page-b")
          }, [
            ...(() => { var out = []; for (let i = 0; (i < 12); (i++)) { out.push.apply(out, [__h('ListTile', { "dense": true, "title": __h('Text', { "$pos": [ "B 行 " + i ] }) })]); } return out; })()
          ])
      ]);
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
    this.setState(() => { this._measureText = "x=" + rect.dx.toFixed(1) + " y=" + rect.dy.toFixed(1) + " · " + rect.width.toFixed(0) + " × " + rect.height.toFixed(0); });
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
    return __h('Container', {
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
          "color": '@Colors.grey.shade100',
          "borderRadius": {
            "radius": 10.0
          }
        }
      }, [
        __h('Column', {
            "crossAxisAlignment": "stretch"
          }, [
            __h('Text', {
                "style": {
                  "fontSize": 15,
                  "fontWeight": "bold",
                  "color": '#673AB7'
                },
                "$pos": [
                  "ValueKey · 列表按值匹配"
                ]
              }),
            __h('SizedBox', {
                "height": 4
              }),
            __h('Text', {
                "style": {
                  "fontSize": 12,
                  "color": '#9E9E9E'
                },
                "$pos": [
                  "换序后看两列计数：① 的状态跟着「行（值）」走，② 的状态留在「位置」上——" + "reconciler 取 keySig（v:值）做「带 key 优先、无 key 按位置」的匹配。"
                ]
              }),
            __h('SizedBox', {
                "height": 8
              }),
            this._valueKeyRows(),
            __h('SizedBox', {
                "height": 8
              }),
            __h('Row', {}, [
                __h('TextButton', {
                    "onPressed": this.__bind("_rotateNames")
                  }, [
                    __h('Text', {
                        "$pos": [
                          "轮换顺序（A→末尾）"
                        ]
                      })
                  ]),
                __h('SizedBox', {
                    "width": 8
                  }),
                __h('TextButton', {
                    "onPressed": this.__bind("_resetNames")
                  }, [
                    __h('Text', {
                        "$pos": [
                          "重置"
                        ]
                      })
                  ])
              ])
          ])
      ]);
  }
  _cardObjectKey() {
    return __h('Container', {
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
          "color": '@Colors.grey.shade100',
          "borderRadius": {
            "radius": 10.0
          }
        }
      }, [
        __h('Column', {
            "crossAxisAlignment": "stretch"
          }, [
            __h('Text', {
                "style": {
                  "fontSize": 15,
                  "fontWeight": "bold",
                  "color": '#673AB7'
                },
                "$pos": [
                  "ObjectKey · 按对象身份相等"
                ]
              }),
            __h('SizedBox', {
                "height": 4
              }),
            __h('Text', {
                "style": {
                  "fontSize": 12,
                  "color": '#9E9E9E'
                },
                "$pos": [
                  "ObjectKey 的判据是 identical（是不是**同一个对象实例**），不是值相等。" + "A 行包的是字段里那个实例（跨帧恒定）→ 父级重建后元素复用、计数保留；" + "B 行每次 build 都新造一个 [1]（值一样但身份不同）→ 元素不匹配、销毁重建、计数归零。" + "注意：B 的计数是**被销毁**而不是被藏起来——归零之后回不来。"
                ]
              }),
            __h('SizedBox', {
                "height": 8
              }),
            this._objectKeyRows(),
            __h('SizedBox', {
                "height": 8
              }),
            __h('Text', {
                "style": {
                  "fontSize": 12,
                  "color": '#9E9E9E'
                },
                "$pos": [
                  "操作：先给 A、B 各点几次 +1，再点下面的「父级重建」，对比两行的计数。" + "选型场景：数据源没有稳定 ID、但你跨帧持有同一批对象实例时用它。"
                ]
              }),
            __h('SizedBox', {
                "height": 6
              }),
            __h('Text', {
                "style": {
                  "fontSize": 11,
                  "color": '#9E9E9E'
                },
                "$pos": [
                  "补充：Dart 里 ValueKey 按 == 比较、ObjectKey 按 identical 比较。" + "本例的 [1] 是 List，没有重写 ==（Dart 的 == 对 List 本就是身份比较），" + "所以这里两者结果相同——本案例要看的是「key 的身份稳不稳定」这件事本身。"
                ]
              }),
            __h('SizedBox', {
                "height": 8
              }),
            __h('Row', {}, [
                __h('TextButton', {
                    "onPressed": this.__bind("_rebuildParent")
                  }, [
                    __h('Text', {
                        "$pos": [
                          "父级重建（setState 一次）"
                        ]
                      })
                  ])
              ])
          ])
      ]);
  }
  _cardUniqueKey() {
    return __h('Container', {
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
          "color": '@Colors.grey.shade100',
          "borderRadius": {
            "radius": 10.0
          }
        }
      }, [
        __h('Column', {
            "crossAxisAlignment": "stretch"
          }, [
            __h('Text', {
                "style": {
                  "fontSize": 15,
                  "fontWeight": "bold",
                  "color": '#673AB7'
                },
                "$pos": [
                  "UniqueKey · 每次都是新身份"
                ]
              }),
            __h('SizedBox', {
                "height": 4
              }),
            __h('Text', {
                "style": {
                  "fontSize": 12,
                  "color": '#9E9E9E'
                },
                "$pos": [
                  "点「重建」触发 setState：子树的 UniqueKey 每次都是新实例（身份新 → 元素不匹配），" + "整棵子树重建、内部计数归零。"
                ]
              }),
            __h('SizedBox', {
                "height": 8
              }),
            __h(KeyTile, {
                "key": new UniqueKey(),
                "index": 0,
                "label": "唯一身份行 #" + this._uniqueSeq
              }),
            __h('SizedBox', {
                "height": 8
              }),
            __h('Row', {}, [
                __h('TextButton', {
                    "onPressed": this.__bind("_bumpUnique")
                  }, [
                    __h('Text', {
                        "$pos": [
                          "重建（setState 一次）"
                        ]
                      })
                  ])
              ])
          ])
      ]);
  }
  _cardStorageKey() {
    return __h('Container', {
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
          "color": '@Colors.grey.shade100',
          "borderRadius": {
            "radius": 10.0
          }
        }
      }, [
        __h('Column', {
            "crossAxisAlignment": "stretch"
          }, [
            __h('Text', {
                "style": {
                  "fontSize": 15,
                  "fontWeight": "bold",
                  "color": '#673AB7'
                },
                "$pos": [
                  "PageStorageKey · 滚动位置持久化"
                ]
              }),
            __h('SizedBox', {
                "height": 4
              }),
            __h('Text', {
                "style": {
                  "fontSize": 12,
                  "color": '#9E9E9E'
                },
                "$pos": [
                  "把 A 列表滚到中间 → 切到 B → 切回 A：位置应回到原处。" + "值本体走值 codec（__psk），宿主造真实 PageStorageKey，位置由宿主端 PageStorage 存取。"
                ]
              }),
            __h('SizedBox', {
                "height": 8
              }),
            this._storageView(),
            __h('SizedBox', {
                "height": 8
              }),
            __h('Row', {}, [
                __h('TextButton', {
                    "onPressed": this.__bind("_flipStore")
                  }, [
                    __h('Text', {
                        "$pos": [
                          (this._storeA ? "切到 B 列表" : "切回 A 列表")
                        ]
                      })
                  ])
              ])
          ])
      ]);
  }
  _cardGlobalKey() {
    return __h('Container', {
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
          "color": '@Colors.grey.shade100',
          "borderRadius": {
            "radius": 10.0
          }
        }
      }, [
        __h('Column', {
            "crossAxisAlignment": "stretch"
          }, [
            __h('Text', {
                "style": {
                  "fontSize": 15,
                  "fontWeight": "bold",
                  "color": '#673AB7'
                },
                "$pos": [
                  "GlobalKey · 宿主端量测 / 定位"
                ]
              }),
            __h('SizedBox', {
                "height": 4
              }),
            __h('Text', {
                "style": {
                  "fontSize": 12,
                  "color": '#9E9E9E'
                },
                "$pos": [
                  "currentContext → findRenderObject 这条链两端同形，但「值」只能在宿主算：" + "位置与尺寸经异步桥回填（box.measure()），定位用真实 RenderObject 的 showOnScreen。"
                ]
              }),
            __h('SizedBox', {
                "height": 8
              }),
            __h('Container', {
                "key": this._targetKey,
                "padding": {
                  "left": 10.0,
                  "top": 10.0,
                  "right": 10.0,
                  "bottom": 10.0
                },
                "decoration": {
                  "color": '@Colors.teal.shade50',
                  "borderRadius": {
                    "radius": 6.0
                  }
                }
              }, [
                __h('Text', {
                    "style": {
                      "fontSize": 13
                    },
                    "$pos": [
                      "目标盒子（GlobalKey 挂在这里）"
                    ]
                  })
              ]),
            __h('SizedBox', {
                "height": 8
              }),
            __h('Text', {
                "style": {
                  "fontSize": 13,
                  "color": '#009688'
                },
                "$pos": [
                  "测量：" + this._measureText
                ]
              }),
            __h('SizedBox', {
                "height": 4
              }),
            __h('Row', {}, [
                __h('TextButton', {
                    "onPressed": this.__bind("_measureTarget")
                  }, [
                    __h('Text', {
                        "$pos": [
                          "测量位置与尺寸"
                        ]
                      })
                  ]),
                __h('SizedBox', {
                    "width": 8
                  }),
                __h('TextButton', {
                    "onPressed": this.__bind("_scrollToTarget")
                  }, [
                    __h('Text', {
                        "$pos": [
                          "定位（showOnScreen）"
                        ]
                      })
                  ])
              ])
          ])
      ]);
  }
  build(context) {
    return __h('Scaffold', {
        "backgroundColor": '@Colors.grey.shade50',
        "appBar": __h('AppBar', {
            "title": __h('Text', {
                "$pos": [
                  "Key 家族 · 全部用例"
                ]
              }),
            "backgroundColor": '#673AB7',
            "foregroundColor": '#FFFFFF'
          }),
        "body": __h('ListView', {}, [
            __h('Padding', {
                "padding": {
                  "left": 12.0,
                  "top": 12.0,
                  "right": 12.0,
                  "bottom": 0.0
                }
              }, [
                __h('Text', {
                    "style": {
                      "fontSize": 12,
                      "color": '#9E9E9E'
                    },
                    "$pos": [
                      "每一张卡片一种 key 的语义；「计数」是 KeyTile 的内部 State，" + "用它来观察状态是跟着行走还是跟着位置走。"
                    ]
                  })
              ]),
            this._cardValueKey(),
            this._cardObjectKey(),
            this._cardUniqueKey(),
            this._cardStorageKey(),
            this._cardGlobalKey(),
            __h('SizedBox', {
                "height": 24
              })
          ])
      });
  }
}

// 组件 DrawerDetail
export class DrawerDetail {
  constructor() {
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
    return __h('Scaffold', {
        "backgroundColor": '@Colors.grey.shade50',
        "appBar": __h('AppBar', {
            "title": __h('Text', {
                "$pos": [
                  "Drawer / endDrawer"
                ]
              }),
            "backgroundColor": '#3F51B5',
            "foregroundColor": '#FFFFFF'
          }),
        "drawer": __h('Drawer', {}, [
            __h('ListView', {}, [
                __h('DrawerHeader', {
                    "decoration": {
                      "color": '#3F51B5'
                    }
                  }, [
                    __h('Align', {
                        "alignment": "bottomLeft"
                      }, [
                        __h('Text', {
                            "style": {
                              "color": '#FFFFFF',
                              "fontSize": 20
                            },
                            "$pos": [
                              "左侧抽屉"
                            ]
                          })
                      ])
                  ]),
                __h('ListTile', {
                    "leading": __h('Icon', {
                        "$pos": [
                          "receipt_long"
                        ]
                      }),
                    "title": __h('Text', {
                        "$pos": [
                          "我的订单"
                        ]
                      }),
                    "onTap": this.__bind("_pickOrders")
                  }),
                __h('ListTile', {
                    "leading": __h('Icon', {
                        "$pos": [
                          "favorite_border"
                        ]
                      }),
                    "title": __h('Text', {
                        "$pos": [
                          "我的收藏"
                        ]
                      }),
                    "onTap": this.__bind("_pickFavorites")
                  })
              ])
          ]),
        "endDrawer": __h('Drawer', {}, [
            __h('ListView', {}, [
                __h('DrawerHeader', {
                    "decoration": {
                      "color": '#009688'
                    }
                  }, [
                    __h('Align', {
                        "alignment": "bottomLeft"
                      }, [
                        __h('Text', {
                            "style": {
                              "color": '#FFFFFF',
                              "fontSize": 20
                            },
                            "$pos": [
                              "右侧抽屉"
                            ]
                          })
                      ])
                  ]),
                __h('ListTile', {
                    "leading": __h('Icon', {
                        "$pos": [
                          "settings"
                        ]
                      }),
                    "title": __h('Text', {
                        "$pos": [
                          "设置"
                        ]
                      }),
                    "onTap": this.__bind("_pickSettings")
                  }),
                __h('ListTile', {
                    "leading": __h('Icon', {
                        "$pos": [
                          "help_outline"
                        ]
                      }),
                    "title": __h('Text', {
                        "$pos": [
                          "帮助与关于"
                        ]
                      }),
                    "onTap": this.__bind("_pickHelp")
                  })
              ])
          ]),
        "body": __h('Center', {}, [
            __h('Column', {
                "mainAxisAlignment": "center"
              }, [
                __h('Icon', {
                    "size": 48,
                    "color": '#3F51B5',
                    "$pos": [
                      "menu_open"
                    ]
                  }),
                __h('SizedBox', {
                    "height": 12
                  }),
                __h('Text', {
                    "$pos": [
                      "AppBar 左侧为汉堡按钮，右侧为 endDrawer 入口"
                    ]
                  }),
                __h('SizedBox', {
                    "height": 8
                  }),
                __h('Text', {
                    "$pos": [
                      ((this._picked < 0) ? "尚未选择菜单项" : "选中菜单项 #" + this._picked)
                    ]
                  })
              ])
          ])
      });
  }
}

// 组件 ReorderListDetail
export class ReorderListDetail {
  constructor() {
    this._items = ["北京", "上海", "广州", "深圳", "杭州", "成都"];
  }
  _onReorder(oldIndex, newIndex) {
    console.log(__str(oldIndex) + " - " + __str(newIndex));
    this.setState(() => { var item = this._items.splice(oldIndex, 1)[0]; var target = ((newIndex > oldIndex) ? (newIndex - 1) : newIndex); this._items.splice(target, 0, item); });
  }
  _add() {
    this.setState(() => { this._items.push("城市 " + (this._items.length + 1)); });
  }
  build(context) {
    return __h('Column', {
        "mainAxisSize": "min"
      }, [
        __h('Padding', {
            "padding": {
              "left": 12.0,
              "top": 12.0,
              "right": 12.0,
              "bottom": 12.0
            }
          }, [
            __h('Row', {}, [
                __h('Expanded', {}, [
                    __h('Text', {
                        "style": {
                          "fontSize": 13,
                          "color": '#9E9E9E'
                        },
                        "$pos": [
                          "长按拖拽调整顺序（onReorder 双参事件）"
                        ]
                      })
                  ]),
                __h('ElevatedButton', {
                    "onPressed": this.__bind("_add")
                  }, [
                    __h('Text', {
                        "$pos": [
                          "添加"
                        ]
                      })
                  ])
              ])
          ]),
        __h('SizedBox', {
            "height": 320
          }, [
            __h('ReorderableListView', {
                "onReorder": this.__bind("_onReorder"),
                "padding": {
                  "left": 12.0,
                  "top": 0.0,
                  "right": 12.0,
                  "bottom": 0.0
                }
              }, [
                ...(() => { var out = []; for (let item of this._items) { out.push.apply(out, [__h('Card', { "key": new ValueKey(item) }, [ __h('ListTile', { "leading": __h('Icon', { "$pos": [ "drag_handle" ] }), "title": __h('Text', { "$pos": [ item ] }) }) ])]); } return out; })()
              ])
          ])
      ]);
  }
}

