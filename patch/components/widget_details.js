// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/components/widget_details.dart 自动生成
// 重新生成：dart run build_runner build

import { CounterVm } from '../model/counter_vm.js';
import { GridView, ListenableBuilder, SliverFixedExtentList, SliverGrid, SliverList, __h } from '../flutter.js';

export class TextDetail {
  constructor() {
    this._count = 0;
  }
  bump() { this.setState(function(){ this._count += 1; }); }
  build() {
    return __h('Column', {
        "crossAxisAlignment": "stretch"
      }, [
        __h('Text', {
            "data": "基础文案 + TextStyle",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }),
        __h('Text', {
            "data": "普通文本，count = " + this._count + "（状态插值）",
            "style": {
              "color": '#2196F3',
              "fontSize": 16
            }
          }),
        __h('SizedBox', {
            "height": 6
          }),
        __h('Text', {
            "data": "maxLines+overflow 测试：这是一段很长的文字会被截断成省略号显示",
            "maxLines": 1,
            "overflow": "ellipsis"
          }),
        __h('SizedBox', {
            "height": 6
          }),
        __h('Text', {
            "data": "textScaler.linear(1.6) 放大",
            "textScaler": {
              "linear": 1.6
            }
          }),
        __h('SizedBox', {
            "height": 6
          }),
        __h('Text', {
            "data": "textAlign 居中",
            "style": {
              "decoration": "underline",
              "decorationColor": '#FF9800',
              "decorationStyle": "wavy"
            },
            "textAlign": "center"
          }),
        __h('SizedBox', {
            "height": 6
          }),
        __h('Text', {
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
        __h('SizedBox', {
            "height": 6
          }),
        __h('Button', {
            "kind": "text",
            "label": "Bump count",
            "event": this.__bind("bump")
          })
      ]);
  }
}

export class ButtonDetail {
  constructor() {
    this._pressed = 0;
  }
  onTap() { this.setState(function(){ this._pressed += 1; }); }
  build() {
    return __h('Column', {
        "crossAxisAlignment": "stretch"
      }, [
        __h('Text', {
            "data": "点击次数 = " + this._pressed,
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }),
        __h('SizedBox', {
            "height": 8
          }),
        __h('Button', {
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
        __h('SizedBox', {
            "height": 8
          }),
        __h('Button', {
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
        __h('SizedBox', {
            "height": 8
          }),
        __h('Button', {
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
        __h('SizedBox', {
            "height": 8
          }),
        __h('Button', {
            "kind": "elevated",
            "label": "Disabled"
          })
      ]);
  }
}

export class LayoutDetail {
  constructor() {
  }
  build() {
    return __h('Column', {
        "crossAxisAlignment": "stretch"
      }, [
        __h('Text', {
            "data": "Row + Expanded / Flexible / Spacer",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
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
                        "data": "A",
                        "textAlign": "center"
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
                        "data": "B（flex=2）",
                        "textAlign": "center"
                      })
                  ])
              ])
          ]),
        __h('SizedBox', {
            "height": 12
          }),
        __h('Text', {
            "data": "Center / Align / Padding / SizedBox",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
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
                    "data": "Center 居中"
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
                    "data": "Align centerLeft"
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
                "data": "Padding 包裹文案"
              })
          ]),
        __h('SizedBox', {
            "height": 12
          }),
        __h('Text', {
            "data": "Stack + Positioned",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
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
                __h('Positioned', {
                    "left": 0,
                    "top": 0,
                    "right": 0,
                    "bottom": 0
                  }, [
                    __h('Center', {}, [
                        __h('Text', {
                            "data": "FILL",
                            "style": {
                              "color": '#FFFFFF',
                              "fontWeight": "bold"
                            }
                          })
                      ])
                  ]),
                __h('Positioned', {
                    "left": 12,
                    "top": 12
                  }, [
                    __h('Text', {
                        "data": "TL"
                      })
                  ]),
                __h('Positioned', {
                    "right": 12,
                    "bottom": 12
                  }, [
                    __h('Text', {
                        "data": "BR"
                      })
                  ])
              ])
          ]),
        __h('SizedBox', {
            "height": 12
          }),
        __h('Text', {
            "data": "Wrap · 自动换行",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }),
        __h('Wrap', {
            "spacing": 8,
            "runSpacing": 8,
            "direction": "horizontal",
            "alignment": "start",
            "runAlignment": "center",
            "crossAxisAlignment": "center"
          }, [
            ...(function(){ var out = []; for (var i = 1; (i <= 5); (i++)) { out.push.apply(out, [__h('Chip', { "label": "chip " + i, "backgroundColor": '@Colors.teal.shade50' })]); } return out; })()
          ]),
        __h('SizedBox', {
            "height": 12
          }),
        __h('Text', {
            "data": "Opacity / ConstrainedBox / AspectRatio / FractionallySizedBox",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
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
                    "data": "50% 透明"
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
                    "data": "ConstrainedBox 宽度 120-200"
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
                    "data": "16:9 比例"
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
                    "data": "60% 宽度",
                    "textAlign": "center"
                  })
              ])
          ])
      ]);
  }
}

export class ImageDetail {
  constructor() {
  }
  build() {
    return __h('Column', {
        "crossAxisAlignment": "stretch"
      }, [
        __h('Text', {
            "data": "Image · 网络图片",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }),
        __h('ClipRRect', {
            "child": __h('Image', {
                "source": "https://picsum.photos/seed/hotpatch/400/160",
                "height": 120,
                "fit": "cover"
              })
          }),
        __h('SizedBox', {
            "height": 12
          }),
        __h('Text', {
            "data": "Icon / CircleAvatar",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }),
        __h('Row', {}, [
            __h('Icon', {
                "icon": "star",
                "size": 28,
                "color": '#FFC107'
              }),
            __h('SizedBox', {
                "width": 12
              }),
            __h('Icon', {
                "icon": "home",
                "size": 28,
                "color": '#2196F3'
              }),
            __h('SizedBox', {
                "width": 12
              }),
            __h('Icon', {
                "icon": "favorite",
                "size": 28,
                "color": '#F44336'
              }),
            __h('SizedBox', {
                "width": 12
              }),
            __h('CircleAvatar', {
                "radius": 20,
                "backgroundColor": '#009688'
              }, [
                __h('Text', {
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

export class ContainerDetail {
  constructor() {
  }
  build() {
    return __h('Column', {
        "crossAxisAlignment": "stretch"
      }, [
        __h('Text', {
            "data": "Container · 颜色/圆角/Padding",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
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
                "data": "容器内容（teal 圆角）",
                "style": {
                  "color": '#FFFFFF'
                }
              })
          ]),
        __h('SizedBox', {
            "height": 12
          }),
        __h('Text', {
            "data": "Container · 边框 + 阴影 + 渐变",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
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
                "data": "渐变 + 边框 + 阴影",
                "style": {
                  "color": '#FFFFFF'
                }
              })
          ]),
        __h('SizedBox', {
            "height": 12
          }),
        __h('Text', {
            "data": "DecoratedBox · 纯装饰",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
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
                    "data": "DecoratedBox 内容"
                  })
              ])
          ]),
        __h('SizedBox', {
            "height": 12
          }),
        __h('Text', {
            "data": "Card · shape / clipBehavior",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }),
        __h('Card', {
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
            __h('Padding', {
                "padding": {
                  "left": 16.0,
                  "top": 16.0,
                  "right": 16.0,
                  "bottom": 16.0
                }
              }, [
                __h('Text', {
                    "data": "圆角卡片 + 描边 + 阴影"
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
            "data": "SizedBox · 尺寸约束",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }),
        __h('Container', {
            "width": 120,
            "height": 48,
            "color": '@Colors.blueGrey.shade100',
            "alignment": "center"
          }, [
            __h('Text', {
                "data": "固定 120×48"
              })
          ])
      ]);
  }
}

export class ScrollDetail {
  constructor() {
    this._offset = 0;
    this._ctrlOffset = 0;
    this._scrollController = new ScrollController();
  }
  initState() { this._scrollController.addListener(() => { this.setState(() => { this._ctrlOffset = this._scrollController.offset; }); }); }
  dispose() { this._scrollController.dispose(); }
  _onListScroll(n) { this.setState(function(){ this._offset = n.metrics.pixels; }); return false; }
  _scrollToEnd() { this._scrollController.jumpTo(this._scrollController.position.maxScrollExtent); }
  build() {
    return __h('Column', {
        "crossAxisAlignment": "stretch"
      }, [
        __h('Text', {
            "data": "ListView · 列表（offset: " + this._offset + "）",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }),
        __h('NotificationListener', {
            "onNotification": this.__bind("_onListScroll")
          }, [
            __h('SizedBox', {
                "height": 160
              }, [
                __h('ListView', {
                    "padding": {
                      "left": 8.0,
                      "top": 8.0,
                      "right": 8.0,
                      "bottom": 8.0
                    },
                    "physics": "BouncingScrollPhysics",
                    "itemExtent": 56
                  }, [
                    __h('ListTile', {
                        "title": "item A",
                        "leading": __h('Icon', {
                            "icon": "list"
                          })
                      }),
                    __h('ListTile', {
                        "title": "item B",
                        "leading": __h('Icon', {
                            "icon": "list"
                          })
                      }),
                    __h('ListTile', {
                        "title": "item C",
                        "leading": __h('Icon', {
                            "icon": "list"
                          })
                      }),
                    __h('ListTile', {
                        "title": "item D",
                        "leading": __h('Icon', {
                            "icon": "list"
                          })
                      }),
                    __h('ListTile', {
                        "title": "item E",
                        "leading": __h('Icon', {
                            "icon": "list"
                          })
                      })
                  ])
              ])
          ]),
        __h('SizedBox', {
            "height": 12
          }),
        __h('Text', {
            "data": "SingleChildScrollView · 长内容滚动（ctrl offset: " + this._ctrlOffset + "）",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }),
        __h('SingleChildScrollView', {
            "controller": this._scrollController,
            "scrollDirection": "horizontal",
            "physics": "ClampingScrollPhysics"
          }, [
            __h('Row', {}, [
                ...(function(){ var out = []; for (var i = 1; (i <= 8); (i++)) { out.push.apply(out, [__h('Padding', { "padding": { "left": 4.0, "top": 4.0, "right": 4.0, "bottom": 4.0 } }, [ __h('Chip', { "label": "横向 " + i }) ])]); } return out; })()
              ])
          ]),
        __h('Align', {
            "alignment": "centerLeft"
          }, [
            __h('Button', {
                "kind": "text",
                "label": "横向 · 跳到底",
                "event": this.__bind("_scrollToEnd")
              })
          ])
      ]);
  }
}

export class SliverDetail {
  constructor() {
    this._controller = new ScrollController();
    this._offset = 0;
  }
  initState() { this._controller.addListener(() => { this.setState(() => { this._offset = this._controller.offset; }); }); }
  dispose() { this._controller.dispose(); }
  _scrollToEnd() { this._controller.jumpTo(this._controller.position.maxScrollExtent); }
  build() {
    return __h('Scaffold', {
        "body": __h('CustomScrollView', {
            "controller": this._controller,
            "physics": "BouncingScrollPhysics"
          }, [
            __h('SliverAppBar', {
                "title": __h('Text', {
                    "data": "SliverAppBar 导航 · offset " + this._offset.toFixed(0)
                  }),
                "backgroundColor": '#673AB7',
                "foregroundColor": '#FFFFFF',
                "pinned": true,
                "floating": true
              }),
            __h('SliverToBoxAdapter', {}, [
                __h('Container', {
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
                    __h('Text', {
                        "data": "CustomScrollView 整页 · SliverToBoxAdapter 盒子",
                        "style": {
                          "fontSize": 14,
                          "fontWeight": "bold"
                        }
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
                    ...(function(){ var out = []; for (var i = 1; (i <= 5); (i++)) { out.push.apply(out, [__h('ListTile', { "title": "SliverList item " + i, "leading": __h('Icon', { "icon": "list", "color": '#673AB7' }), "trailing": __h('Icon', { "icon": "chevron_right" }) })]); } return out; })()
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
                        "data": "SliverChildBuilderDelegate · 懒构建列表",
                        "style": {
                          "fontSize": 14,
                          "fontWeight": "bold"
                        }
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
                    "delegateBuilder": "_sliverBuilder0",
                    "childCount": 8
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
                        "data": "SliverFixedExtentList · 固定高度",
                        "style": {
                          "fontSize": 14,
                          "fontWeight": "bold"
                        }
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
                __h(SliverFixedExtentList, {
                    "delegateBuilder": "_sliverBuilder1",
                    "childCount": 6,
                    "itemExtent": 44
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
                        "data": "SliverOpacity + SliverGrid · MaxCrossAxisExtent 九宫格",
                        "style": {
                          "fontSize": 14,
                          "fontWeight": "bold"
                        }
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
                        "delegateBuilder": "_sliverBuilder2",
                        "childCount": 9,
                        "maxCrossAxisExtent": 140,
                        "mainAxisSpacing": 8,
                        "crossAxisSpacing": 8,
                        "childAspectRatio": 1
                      })
                  ])
              ]),
            __h('SliverSafeArea', {}, [
                __h('SliverFillRemaining', {
                    "hasScrollBody": false
                  }, [
                    __h('Center', {}, [
                        __h('Text', {
                            "data": "底部 · SliverSafeArea + SliverFillRemaining",
                            "style": {
                              "color": '#9E9E9E'
                            }
                          })
                      ])
                  ])
              ])
          ]),
        "floatingActionButton": __h('FloatingActionButton', {
            "child": __h('Icon', {
                "icon": "arrow_downward"
              }),
            "event": this.__bind("_scrollToEnd"),
            "backgroundColor": '#673AB7',
            "foregroundColor": '#FFFFFF',
            "tooltip": "跳到底"
          })
      });
  }
  _sliverBuilder0(index) {
      return __h('ListTile', {
        "title": "builder item " + index,
        "subtitle": "index * 10 = " + (index * 10),
        "leading": __h('Icon', {
            "icon": "build",
            "color": '@Colors.orange.shade700'
          })
      });
  }
  _sliverBuilder1(index) {
      return __h('ListTile', {
        "title": "fixed item " + index,
        "leading": __h('Icon', {
            "icon": "height",
            "color": '#009688'
          }),
        "dense": true
      });
  }
  _sliverBuilder2(index) {
      return __h('Container', {
        "alignment": "center",
        "decoration": {
          "color": '@Colors.teal.shade100',
          "borderRadius": {
            "radius": 8.0
          }
        }
      }, [
        __h('Text', {
            "data": "格 " + index,
            "style": {
              "fontWeight": "bold"
            }
          })
      ]);
  }
}

export class GridDetail {
  constructor() {
    this._controller = new ScrollController();
    this._offset = 0;
  }
  initState() { this._controller.addListener(() => { this.setState(() => { this._offset = this._controller.offset; }); }); }
  dispose() { this._controller.dispose(); }
  _jumpBottom() { this._controller.jumpTo(this._controller.position.maxScrollExtent); }
  build() {
    return __h('Scaffold', {
        "appBar": __h('AppBar', {
            "title": __h('Text', {
                "data": "GridView 懒加载验证"
              }),
            "backgroundColor": '#009688',
            "foregroundColor": '#FFFFFF'
          }),
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
                    "data": "controller offset: " + this._offset.toFixed(1),
                    "style": {
                      "fontSize": 13,
                      "color": '#9E9E9E'
                    }
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
                    "data": "GridView.builder · 固定 3 列 · 30 项（懒加载）",
                    "style": {
                      "fontSize": 14,
                      "fontWeight": "bold"
                    }
                  })
              ]),
            __h('Expanded', {
                "flex": 5
              }, [
                __h(GridView, {
                    "controller": this._controller,
                    "crossAxisCount": 3,
                    "mainAxisSpacing": 8,
                    "crossAxisSpacing": 8,
                    "childAspectRatio": 1,
                    "delegateBuilder": "_gridViewBuilder0",
                    "itemCount": 30
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
                    "data": "GridView.builder · MaxCrossAxisExtent 120 · 20 项（懒加载）",
                    "style": {
                      "fontSize": 14,
                      "fontWeight": "bold"
                    }
                  })
              ]),
            __h('Expanded', {
                "flex": 4
              }, [
                __h(GridView, {
                    "maxCrossAxisExtent": 120,
                    "mainAxisSpacing": 8,
                    "crossAxisSpacing": 8,
                    "childAspectRatio": 1,
                    "delegateBuilder": "_gridViewBuilder1",
                    "itemCount": 20
                  })
              ])
          ]),
        "backgroundColor": '@Colors.grey.shade50',
        "floatingActionButton": __h('FloatingActionButton', {
            "child": __h('Icon', {
                "icon": "arrow_downward"
              }),
            "event": this.__bind("_jumpBottom"),
            "backgroundColor": '#009688',
            "foregroundColor": '#FFFFFF',
            "tooltip": "跳到底"
          })
      });
  }
  _gridViewBuilder0(index) {
      return __h('Container', {
        "alignment": "center",
        "decoration": {
          "color": '@Colors.teal.shade100',
          "borderRadius": {
            "radius": 8.0
          }
        }
      }, [
        __h('Text', {
            "data": "格 " + index,
            "style": {
              "fontWeight": "bold"
            }
          })
      ]);
  }
  _gridViewBuilder1(index) {
      return __h('Container', {
        "alignment": "center",
        "decoration": {
          "color": '@Colors.orange.shade100',
          "borderRadius": {
            "radius": 8.0
          }
        }
      }, [
        __h('Text', {
            "data": "项 " + index,
            "style": {
              "fontWeight": "bold"
            }
          })
      ]);
  }
}

export class ScaffoldDetail {
  constructor() {
    this._navIndex = 0;
  }
  _onNavTap(index) { this.setState(function(){ this._navIndex = index; }); }
  _onFab() {  }
  build() {
    return __h('Scaffold', {
        "appBar": __h('AppBar', {
            "title": __h('Text', {
                "data": "Scaffold / AppBar / FAB / BottomNav"
              }),
            "leading": __h('Icon', {
                "icon": "menu"
              }),
            "backgroundColor": '#673AB7',
            "foregroundColor": '#FFFFFF',
            "elevation": 4,
            "toolbarHeight": 56,
            "centerTitle": true
          }, [
            __h('Icon', {
                "icon": "search",
                "color": '#FFFFFF'
              }),
            __h('SizedBox', {
                "width": 16
              })
          ]),
        "body": __h('SafeArea', {}, [
            __h('Center', {}, [
                __h('Column', {
                    "mainAxisAlignment": "center"
                  }, [
                    __h('Icon', {
                        "icon": "extension",
                        "size": 48,
                        "color": '#673AB7'
                      }),
                    __h('SizedBox', {
                        "height": 12
                      }),
                    __h('Text', {
                        "data": "页面骨架组件演示"
                      }),
                    __h('Text', {
                        "data": "BottomNav 选中：" + this._navIndex
                      })
                  ])
              ])
          ]),
        "backgroundColor": '@Colors.grey.shade50',
        "floatingActionButton": __h('FloatingActionButton', {
            "child": __h('Icon', {
                "icon": "add"
              }),
            "event": this.__bind("_onFab"),
            "backgroundColor": '#673AB7',
            "foregroundColor": '#FFFFFF',
            "tooltip": "添加"
          }),
        "bottomNavigationBar": __h('BottomNavigationBar', {
            "currentIndex": this._navIndex,
            "event": this.__bind("_onNavTap"),
            "selectedItemColor": '#673AB7',
            "unselectedItemColor": '#9E9E9E'
          }, [
            __h('BottomNavigationBarItem', {
                "icon": __h('Icon', {
                    "icon": "home"
                  }),
                "label": "首页"
              }),
            __h('BottomNavigationBarItem', {
                "icon": __h('Icon', {
                    "icon": "search"
                  }),
                "label": "搜索"
              }),
            __h('BottomNavigationBarItem', {
                "icon": __h('Icon', {
                    "icon": "person"
                  }),
                "label": "我的"
              })
          ])
      });
  }
}

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
  initState() { this._controller.addListener((...args) => this._onControllerChanged(...args)); }
  _onControllerChanged() { if (!this.__unmounted) { this.setState(function(){ this._text = this._controller.text; }); } }
  _onTextChanged(v) { this.setState(function(){ this._text = v; }); }
  _onChoiceChanged(v) { this.setState(function(){ this._choice = v; }); }
  _onDropdownChanged(v) { this.setState(function(){ this._dropdown = v; }); }
  _onSwitchChanged(v) { this.setState(function(){ this._switchOn = (v ?? false); }); }
  _onCheckChanged(v) { this.setState(function(){ this._checked = v; }); }
  _onSliderChanged(v) { this.setState(function(){ this._slider = v; }); }
  build() {
    return __h('Column', {
        "crossAxisAlignment": "stretch"
      }, [
        __h('Text', {
            "data": "TextField",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }),
        __h('TextField', {
            "event": this.__bind("_onTextChanged"),
            "controller": this._controller,
            "hintText": "请输入文本",
            "labelText": "用户名",
            "maxLines": 1,
            "style": {
              "fontSize": 16
            }
          }),
        __h('SizedBox', {
            "height": 4
          }),
        __h('Text', {
            "data": "输入内容：" + this._text,
            "style": {
              "fontSize": 14,
              "color": '#9E9E9E'
            }
          }),
        __h('Text', {
            "data": "controller.text：" + this._controller.text,
            "style": {
              "fontSize": 14,
              "color": '#673AB7'
            }
          }),
        __h('SizedBox', {
            "height": 8
          }),
        __h('Align', {
            "alignment": "centerLeft"
          }, [
            __h('Button', {
                "kind": "filled",
                "label": "清空输入",
                "event": this.__bind("this._controller.clear()")
              })
          ]),
        __h('SizedBox', {
            "height": 12
          }),
        __h('Text', {
            "data": "Radio 单选",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }),
        __h('Row', {}, [
            __h('Radio', {
                "value": "A",
                "groupValue": this._choice,
                "event": this.__bind("_onChoiceChanged"),
                "activeColor": '#673AB7'
              }),
            __h('Text', {
                "data": "选项 A"
              }),
            __h('Radio', {
                "value": "B",
                "groupValue": this._choice,
                "event": this.__bind("_onChoiceChanged"),
                "activeColor": '#673AB7'
              }),
            __h('Text', {
                "data": "选项 B"
              })
          ]),
        __h('Text', {
            "data": "当前选择：" + this._choice,
            "style": {
              "fontSize": 14,
              "color": '#9E9E9E'
            }
          }),
        __h('SizedBox', {
            "height": 12
          }),
        __h('Text', {
            "data": "DropdownButton",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }),
        __h('DropdownButton', {
            "value": this._dropdown,
            "event": this.__bind("_onDropdownChanged"),
            "isExpanded": true
          }, [
            __h('DropdownMenuItem', {
                "value": "苹果",
                "label": "苹果"
              }),
            __h('DropdownMenuItem', {
                "value": "香蕉",
                "label": "香蕉"
              }),
            __h('DropdownMenuItem', {
                "value": "橙子",
                "label": "橙子"
              })
          ]),
        __h('SizedBox', {
            "height": 12
          }),
        __h('Row', {}, [
            __h('Switch', {
                "value": this._switchOn,
                "event": this.__bind("_onSwitchChanged"),
                "activeColor": '#FFFFFF',
                "activeTrackColor": '#673AB7',
                "inactiveThumbColor": '#9E9E9E',
                "inactiveTrackColor": '@Colors.grey.shade300'
              }),
            __h('SizedBox', {
                "width": 8
              }),
            __h('Text', {
                "data": "Switch：" + (this._switchOn ? "开" : "关")
              })
          ]),
        __h('Row', {}, [
            __h('Checkbox', {
                "value": this._checked,
                "event": this.__bind("_onCheckChanged"),
                "activeColor": '#673AB7',
                "checkColor": '#FFFFFF'
              }),
            __h('SizedBox', {
                "width": 8
              }),
            __h('Text', {
                "data": "Checkbox：" + (this._checked ?? false)
              })
          ]),
        __h('SizedBox', {
            "height": 8
          }),
        __h('Text', {
            "data": "Slider 值：" + this._slider,
            "style": {
              "fontSize": 14
            }
          }),
        __h('Slider', {
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

export class ProgressDetail {
  constructor() {
    this._progress = 0.65;
  }
  build() {
    return __h('Column', {
        "crossAxisAlignment": "stretch"
      }, [
        __h('Text', {
            "data": "CircularProgressIndicator",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }),
        __h('SizedBox', {
            "height": 8
          }),
        __h('Row', {}, [
            __h('CircularProgressIndicator', {
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
            "data": "LinearProgressIndicator",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }),
        __h('SizedBox', {
            "height": 8
          }),
        __h('LinearProgressIndicator', {
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
            "data": "进度值：" + this._progress,
            "style": {
              "fontSize": 14,
              "color": '#9E9E9E'
            }
          })
      ]);
  }
}

export class NotifierCard {
  constructor() {
    this._model = new CounterVm({});
  }
  _inc() { this._model.inc(); }
  _reset() { this._model.reset(); }
  dispose() { this._model.dispose(); }
  build() {
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
                    "listenable": "_model",
                    "builder": "_lbBuilder0"
                  }),
                __h('SizedBox', {
                    "height": 12
                  }),
                __h('Row', {
                    "mainAxisAlignment": "center"
                  }, [
                    __h('Button', {
                        "kind": "elevated",
                        "label": "+1",
                        "event": this.__bind("_inc")
                      }),
                    __h('SizedBox', {
                        "width": 12
                      }),
                    __h('Button', {
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
      return __h('Text', {
        "data": "count = " + this._model.count,
        "style": {
          "fontSize": 24,
          "fontWeight": "bold"
        }
      });
  }
}

export class StatelessCard {
  constructor(args) {
    this.title = (args && args.title !== undefined) ? args.title : '';
    this.subtitle = (args && args.subtitle !== undefined) ? args.subtitle : '';
    this.badge = (args && args.badge !== undefined) ? args.badge : '';
  }
  build() {
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
                        "icon": "article",
                        "color": '#009688'
                      }),
                    __h('SizedBox', {
                        "width": 8
                      }),
                    __h('Expanded', {}, [
                        __h('Text', {
                            "data": this.badge + " · " + this.title,
                            "style": {
                              "fontSize": 18,
                              "fontWeight": "bold"
                            }
                          })
                      ])
                  ]),
                __h('Divider', {
                    "height": 24
                  }),
                __h('Text', {
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

