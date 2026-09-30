// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/components/widget_details.dart 自动生成
// 重新生成：dart run build_runner build


export class TextDetail {
  constructor() {
    this._count = 0;
  }
  bump() { this.setState(function(){ this._count += 1; }); }
  build() {
    return {
      "type": "Column",
      "props": {
        "crossAxisAlignment": "stretch"
      },
      "children": [
        {
          "type": "Text",
          "props": {
            "data": "基础文案 + TextStyle",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }
        },
        {
          "type": "Text",
          "props": {
            "data": "普通文本，count = " + this._count + "（状态插值）",
            "style": {
              "color": '#2196F3',
              "fontSize": 16
            }
          }
        },
        {
          "type": "SizedBox",
          "props": {
            "height": 6
          }
        },
        {
          "type": "Text",
          "props": {
            "data": "maxLines+overflow 测试：这是一段很长的文字会被截断成省略号显示",
            "maxLines": 1,
            "overflow": "ellipsis"
          }
        },
        {
          "type": "SizedBox",
          "props": {
            "height": 6
          }
        },
        {
          "type": "Text",
          "props": {
            "data": "textScaler.linear(1.6) 放大",
            "textScaler": {
              "linear": 1.6
            }
          }
        },
        {
          "type": "SizedBox",
          "props": {
            "height": 6
          }
        },
        {
          "type": "Text",
          "props": {
            "data": "textAlign 居中",
            "style": {
              "decoration": "underline",
              "decorationColor": '#FF9800',
              "decorationStyle": "wavy"
            },
            "textAlign": "center"
          }
        },
        {
          "type": "SizedBox",
          "props": {
            "height": 6
          }
        },
        {
          "type": "Text",
          "props": {
            "data": "softWrap=false 不换行测试",
            "style": {
              "fontSize": 12,
              "color": '#9E9E9E',
              "wordSpacing": 2,
              "letterSpacing": 1,
              "backgroundColor": '#ffffe082'
            },
            "softWrap": false
          }
        },
        {
          "type": "SizedBox",
          "props": {
            "height": 6
          }
        },
        {
          "type": "Button",
          "props": {
            "kind": "text",
            "label": "Bump count",
            "event": "bump"
          }
        }
      ]
    };
  }
}

export class ButtonDetail {
  constructor() {
    this._pressed = 0;
  }
  onTap() { this.setState(function(){ this._pressed += 1; }); }
  build() {
    return {
      "type": "Column",
      "props": {
        "crossAxisAlignment": "stretch"
      },
      "children": [
        {
          "type": "Text",
          "props": {
            "data": "点击次数 = " + this._pressed,
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }
        },
        {
          "type": "SizedBox",
          "props": {
            "height": 8
          }
        },
        {
          "type": "Button",
          "props": {
            "kind": "elevated",
            "label": "Elevated · Styled",
            "event": "onTap",
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
          }
        },
        {
          "type": "SizedBox",
          "props": {
            "height": 8
          }
        },
        {
          "type": "Button",
          "props": {
            "kind": "text",
            "label": "TextButton",
            "event": "onTap",
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
          }
        },
        {
          "type": "SizedBox",
          "props": {
            "height": 8
          }
        },
        {
          "type": "Button",
          "props": {
            "kind": "outlined",
            "label": "OutlinedButton",
            "event": "onTap",
            "style": {
              "side": {
                "color": '#FF9800',
                "width": 2
              },
              "minimumSize": {
                "width": 120,
                "height": 40
              },
              "foregroundColor": '#FF5722'
            }
          }
        },
        {
          "type": "SizedBox",
          "props": {
            "height": 8
          }
        },
        {
          "type": "Button",
          "props": {
            "kind": "elevated",
            "label": "Disabled",
            "event": ""
          }
        }
      ]
    };
  }
}

export class LayoutDetail {
  constructor() {
  }
  build() {
    return {
      "type": "Column",
      "props": {
        "crossAxisAlignment": "stretch"
      },
      "children": [
        {
          "type": "Text",
          "props": {
            "data": "Row + Expanded / Flexible",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }
        },
        {
          "type": "Row",
          "children": [
            {
              "type": "Expanded",
              "props": {
                "flex": 1
              },
              "children": [
                {
                  "type": "Container",
                  "props": {
                    "color": '@Colors.blue.shade100',
                    "padding": {
                      "left": 8.0,
                      "top": 8.0,
                      "right": 8.0,
                      "bottom": 8.0
                    }
                  },
                  "children": [
                    {
                      "type": "Text",
                      "props": {
                        "data": "A",
                        "textAlign": "center"
                      }
                    }
                  ]
                }
              ]
            },
            {
              "type": "SizedBox",
              "props": {
                "width": 4
              }
            },
            {
              "type": "Expanded",
              "props": {
                "flex": 2
              },
              "children": [
                {
                  "type": "Container",
                  "props": {
                    "color": '@Colors.green.shade100',
                    "padding": {
                      "left": 8.0,
                      "top": 8.0,
                      "right": 8.0,
                      "bottom": 8.0
                    }
                  },
                  "children": [
                    {
                      "type": "Text",
                      "props": {
                        "data": "B（flex=2）",
                        "textAlign": "center"
                      }
                    }
                  ]
                }
              ]
            }
          ]
        },
        {
          "type": "SizedBox",
          "props": {
            "height": 12
          }
        },
        {
          "type": "Text",
          "props": {
            "data": "Center / Align / Padding / SizedBox",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }
        },
        {
          "type": "Center",
          "children": [
            {
              "type": "Container",
              "props": {
                "color": '@Colors.amber.shade100',
                "padding": {
                  "left": 12.0,
                  "top": 12.0,
                  "right": 12.0,
                  "bottom": 12.0
                }
              },
              "children": [
                {
                  "type": "Text",
                  "props": {
                    "data": "Center 居中"
                  }
                }
              ]
            }
          ]
        },
        {
          "type": "SizedBox",
          "props": {
            "height": 8
          }
        },
        {
          "type": "Align",
          "props": {
            "alignment": "centerLeft"
          },
          "children": [
            {
              "type": "Container",
              "props": {
                "color": '@Colors.purple.shade50',
                "padding": {
                  "left": 8.0,
                  "top": 8.0,
                  "right": 8.0,
                  "bottom": 8.0
                }
              },
              "children": [
                {
                  "type": "Text",
                  "props": {
                    "data": "Align centerLeft"
                  }
                }
              ]
            }
          ]
        },
        {
          "type": "SizedBox",
          "props": {
            "height": 8
          }
        },
        {
          "type": "Padding",
          "props": {
            "padding": {
              "left": 8.0,
              "top": 4.0,
              "right": 8.0,
              "bottom": 4.0
            }
          },
          "children": [
            {
              "type": "Text",
              "props": {
                "data": "Padding 包裹文案"
              }
            }
          ]
        },
        {
          "type": "SizedBox",
          "props": {
            "height": 12
          }
        },
        {
          "type": "Text",
          "props": {
            "data": "Stack + Positioned",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }
        },
        {
          "type": "SizedBox",
          "props": {
            "height": 100
          },
          "children": [
            {
              "type": "Stack",
              "children": [
                {
                  "type": "Container",
                  "props": {
                    "color": '@Colors.grey.shade200'
                  }
                },
                {
                  "type": "Positioned",
                  "props": {
                    "left": 0,
                    "top": 0,
                    "right": 0,
                    "bottom": 0
                  },
                  "children": [
                    {
                      "type": "Center",
                      "children": [
                        {
                          "type": "Text",
                          "props": {
                            "data": "FILL",
                            "style": {
                              "color": '#FFFFFF',
                              "fontWeight": "bold"
                            }
                          }
                        }
                      ]
                    }
                  ]
                },
                {
                  "type": "Positioned",
                  "props": {
                    "left": 12,
                    "top": 12
                  },
                  "children": [
                    {
                      "type": "Text",
                      "props": {
                        "data": "TL"
                      }
                    }
                  ]
                },
                {
                  "type": "Positioned",
                  "props": {
                    "right": 12,
                    "bottom": 12
                  },
                  "children": [
                    {
                      "type": "Text",
                      "props": {
                        "data": "BR"
                      }
                    }
                  ]
                }
              ]
            }
          ]
        },
        {
          "type": "SizedBox",
          "props": {
            "height": 12
          }
        },
        {
          "type": "Text",
          "props": {
            "data": "Wrap · 自动换行",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }
        },
        {
          "type": "Wrap",
          "props": {
            "spacing": 8,
            "runSpacing": 8
          },
          "children": [
            ...(function(){ var out = []; for (var i = 1; (i <= 5); (i++)) { out.push.apply(out, [{ "type": "Chip", "props": { "label": "chip " + i, "backgroundColor": '@Colors.teal.shade50' } }]); } return out; })()
          ]
        }
      ]
    };
  }
}

export class ImageDetail {
  constructor() {
  }
  build() {
    return {
      "type": "Column",
      "props": {
        "crossAxisAlignment": "stretch"
      },
      "children": [
        {
          "type": "Text",
          "props": {
            "data": "Image · 网络图片",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }
        },
        {
          "type": "ClipRRect",
          "props": {
            "child": {
              "type": "Image",
              "props": {
                "source": "https://picsum.photos/seed/hotpatch/400/160",
                "height": 120,
                "fit": "cover"
              }
            }
          }
        },
        {
          "type": "SizedBox",
          "props": {
            "height": 12
          }
        },
        {
          "type": "Text",
          "props": {
            "data": "Icon / CircleAvatar",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }
        },
        {
          "type": "Row",
          "children": [
            {
              "type": "Icon",
              "props": {
                "icon": "star",
                "size": 28,
                "color": '#FFC107'
              }
            },
            {
              "type": "SizedBox",
              "props": {
                "width": 12
              }
            },
            {
              "type": "Icon",
              "props": {
                "icon": "home",
                "size": 28,
                "color": '#2196F3'
              }
            },
            {
              "type": "SizedBox",
              "props": {
                "width": 12
              }
            },
            {
              "type": "Icon",
              "props": {
                "icon": "favorite",
                "size": 28,
                "color": '#F44336'
              }
            },
            {
              "type": "SizedBox",
              "props": {
                "width": 12
              }
            },
            {
              "type": "CircleAvatar",
              "props": {
                "radius": 20,
                "backgroundColor": '#009688'
              },
              "children": [
                {
                  "type": "Text",
                  "props": {
                    "data": "AV",
                    "style": {
                      "color": '#FFFFFF'
                    }
                  }
                }
              ]
            }
          ]
        }
      ]
    };
  }
}

export class ContainerDetail {
  constructor() {
  }
  build() {
    return {
      "type": "Column",
      "props": {
        "crossAxisAlignment": "stretch"
      },
      "children": [
        {
          "type": "Text",
          "props": {
            "data": "Container · 颜色/圆角/Padding",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }
        },
        {
          "type": "Container",
          "props": {
            "padding": {
              "left": 16.0,
              "top": 16.0,
              "right": 16.0,
              "bottom": 16.0
            },
            "decoration": {
              "color": '#009688'
            }
          },
          "children": [
            {
              "type": "Text",
              "props": {
                "data": "容器内容（teal 圆角）",
                "style": {
                  "color": '#FFFFFF'
                }
              }
            }
          ]
        },
        {
          "type": "SizedBox",
          "props": {
            "height": 12
          }
        },
        {
          "type": "Text",
          "props": {
            "data": "Card",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }
        },
        {
          "type": "Card",
          "props": {
            "elevation": 2
          },
          "children": [
            {
              "type": "Padding",
              "props": {
                "padding": {
                  "left": 12.0,
                  "top": 12.0,
                  "right": 12.0,
                  "bottom": 12.0
                }
              },
              "children": [
                {
                  "type": "Text",
                  "props": {
                    "data": "卡片内容（elevation=2）"
                  }
                }
              ]
            }
          ]
        },
        {
          "type": "SizedBox",
          "props": {
            "height": 12
          }
        },
        {
          "type": "Divider"
        },
        {
          "type": "SizedBox",
          "props": {
            "height": 12
          }
        },
        {
          "type": "Text",
          "props": {
            "data": "SizedBox · 尺寸约束",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }
        },
        {
          "type": "Container",
          "props": {
            "width": 120,
            "height": 48,
            "color": '@Colors.blueGrey.shade100',
            "alignment": "center"
          },
          "children": [
            {
              "type": "Text",
              "props": {
                "data": "固定 120×48"
              }
            }
          ]
        }
      ]
    };
  }
}

export class ScrollDetail {
  constructor() {
  }
  build() {
    return {
      "type": "Column",
      "props": {
        "crossAxisAlignment": "stretch"
      },
      "children": [
        {
          "type": "Text",
          "props": {
            "data": "ListView · 列表",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }
        },
        {
          "type": "SizedBox",
          "props": {
            "height": 160
          },
          "children": [
            {
              "type": "ListView",
              "children": [
                {
                  "type": "ListTile",
                  "props": {
                    "title": "item A",
                    "leading": {
                      "type": "Icon",
                      "props": {
                        "icon": "list"
                      }
                    }
                  }
                },
                {
                  "type": "ListTile",
                  "props": {
                    "title": "item B",
                    "leading": {
                      "type": "Icon",
                      "props": {
                        "icon": "list"
                      }
                    }
                  }
                },
                {
                  "type": "ListTile",
                  "props": {
                    "title": "item C",
                    "leading": {
                      "type": "Icon",
                      "props": {
                        "icon": "list"
                      }
                    }
                  }
                },
                {
                  "type": "ListTile",
                  "props": {
                    "title": "item D",
                    "leading": {
                      "type": "Icon",
                      "props": {
                        "icon": "list"
                      }
                    }
                  }
                },
                {
                  "type": "ListTile",
                  "props": {
                    "title": "item E",
                    "leading": {
                      "type": "Icon",
                      "props": {
                        "icon": "list"
                      }
                    }
                  }
                }
              ]
            }
          ]
        },
        {
          "type": "SizedBox",
          "props": {
            "height": 12
          }
        },
        {
          "type": "Text",
          "props": {
            "data": "SingleChildScrollView · 长内容滚动",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }
        },
        {
          "type": "SingleChildScrollView",
          "props": {
            "scrollDirection": "horizontal"
          },
          "children": [
            {
              "type": "Row",
              "children": [
                ...(function(){ var out = []; for (var i = 1; (i <= 8); (i++)) { out.push.apply(out, [{ "type": "Padding", "props": { "padding": { "left": 4.0, "top": 4.0, "right": 4.0, "bottom": 4.0 } }, "children": [ { "type": "Chip", "props": { "label": "横向 " + i } } ] }]); } return out; })()
              ]
            }
          ]
        }
      ]
    };
  }
}

export class ScaffoldDetail {
  constructor() {
  }
  build() {
    return {
      "type": "Scaffold",
      "children": [
        {
          "type": "AppBar",
          "children": [
            {
              "type": "Text",
              "props": {
                "data": "Scaffold / AppBar / Center"
              }
            }
          ]
        },
        {
          "type": "Center",
          "children": [
            {
              "type": "Column",
              "props": {
                "mainAxisAlignment": "center"
              },
              "children": [
                {
                  "type": "Icon",
                  "props": {
                    "icon": "extension",
                    "size": 48,
                    "color": '#673AB7'
                  }
                },
                {
                  "type": "SizedBox",
                  "props": {
                    "height": 12
                  }
                },
                {
                  "type": "Text",
                  "props": {
                    "data": "页面骨架组件演示"
                  }
                },
                {
                  "type": "Text",
                  "props": {
                    "data": "Scaffold + AppBar + Center + SingleChildScrollView"
                  }
                }
              ]
            }
          ]
        }
      ]
    };
  }
}

