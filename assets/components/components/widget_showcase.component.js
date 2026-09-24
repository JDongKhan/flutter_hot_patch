// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/components/widget_showcase.dart 自动生成
// 重新生成：dart run build_runner build

// 组件注册表：多个 JS 补丁共享，加载顺序无关
var __components = __components || {};
// 实例注册表：每个 HotPatchWidget 持有自己的组件实例（状态互不共享）
var __instances = __instances || {};

// IIFE 闭包：不泄漏到全局，加载多个 JS 不会重名
__components['WidgetShowcase'] = (function() {
  // 构造函数：new 一次得到一个独立组件实例，可重复实例化
  function WidgetShowcase() {
    this._bumps = 0;
    this._on = false;
    this._slider = 0.3;
    this._taps = 0;
  }

  WidgetShowcase.prototype.bump = function() { this.setState(function(){ this._bumps += 1; }); };
  WidgetShowcase.prototype.onSwitch = function(v) { this.setState(function(){ this._on = v; }); };
  WidgetShowcase.prototype.onSlider = function(v) { this.setState(function(){ this._slider = v; }); };
  WidgetShowcase.prototype.tap = function() { this.setState(function(){ this._taps += 1; }); };

  WidgetShowcase.prototype.build = function() {
    return {
      "type": "Column",
      "props": {
        "crossAxisAlignment": "stretch"
      },
      "children": [
        {
          "type": "Text",
          "props": {
            "data": "WidgetShowcase · 常用基础组件",
            "style": {
              "fontSize": 20,
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
          "type": "Text",
          "props": {
            "data": "来自 JS 热更：bumps = 0 是静态文案，下面用状态插值"
          }
        },
        {
          "type": "Divider"
        },
        {
          "type": "Text",
          "props": {
            "data": "Text · 文案与 TextStyle"
          }
        },
        {
          "type": "Text",
          "props": {
            "data": "Hello 热更组件，bumps = " + this._bumps,
            "style": {
              "color": '#2196F3',
              "fontSize": 16
            }
          }
        },
        {
          "type": "SizedBox",
          "props": {
            "height": 4
          }
        },
        {
          "type": "Text",
          "props": {
            "data": "taps = " + this._taps + "（GestureDetector 累计）",
            "style": {
              "color": '#4CAF50'
            }
          }
        },
        {
          "type": "Button",
          "props": {
            "kind": "text",
            "label": "Bump",
            "event": "bump"
          }
        },
        {
          "type": "Divider"
        },
        {
          "type": "Text",
          "props": {
            "data": "Image · 网络图片"
          }
        },
        {
          "type": "SizedBox",
          "props": {
            "height": 4
          }
        },
        {
          "type": "Image",
          "props": {
            "source": "https://picsum.photos/300/120",
            "width": 300,
            "height": 120,
            "fit": "cover"
          }
        },
        {
          "type": "Divider"
        },
        {
          "type": "Text",
          "props": {
            "data": "Icon / CircleAvatar"
          }
        },
        {
          "type": "SizedBox",
          "props": {
            "height": 4
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
                "size": 28
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
                "radius": 24,
                "backgroundColor": '#FF9800'
              },
              "children": [
                {
                  "type": "Icon",
                  "props": {
                    "icon": "person",
                    "color": '#FFFFFF'
                  }
                }
              ]
            }
          ]
        },
        {
          "type": "Divider"
        },
        {
          "type": "Text",
          "props": {
            "data": "Container · 颜色/圆角/Padding"
          }
        },
        {
          "type": "SizedBox",
          "props": {
            "height": 4
          }
        },
        {
          "type": "Container",
          "props": {
            "padding": {
              "left": 12.0,
              "top": 12.0,
              "right": 12.0,
              "bottom": 12.0
            },
            "decoration": {
              "color": '#009688',
              "borderRadius": {
                "radius": 12.0
              }
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
          "type": "Divider"
        },
        {
          "type": "Text",
          "props": {
            "data": "Card"
          }
        },
        {
          "type": "SizedBox",
          "props": {
            "height": 4
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
          "type": "Divider"
        },
        {
          "type": "Text",
          "props": {
            "data": "Row + Expanded / Flexible"
          }
        },
        {
          "type": "SizedBox",
          "props": {
            "height": 4
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
                    "color": '#F44336',
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
                        "data": "A"
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
                    "color": '#2196F3',
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
                        "data": "B（flex=2）"
                      }
                    }
                  ]
                }
              ]
            }
          ]
        },
        {
          "type": "Divider"
        },
        {
          "type": "Text",
          "props": {
            "data": "Center / Align"
          }
        },
        {
          "type": "SizedBox",
          "props": {
            "height": 4
          }
        },
        {
          "type": "Center",
          "children": [
            {
              "type": "Container",
              "props": {
                "color": '#9E9E9E',
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
            "height": 4
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
                "color": '#607D8B',
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
          "type": "Divider"
        },
        {
          "type": "Text",
          "props": {
            "data": "Stack + Positioned"
          }
        },
        {
          "type": "SizedBox",
          "props": {
            "height": 4
          }
        },
        {
          "type": "Stack",
          "children": [
            {
              "type": "Container",
              "props": {
                "width": 120,
                "height": 80,
                "color": '#9E9E9E'
              }
            },
            {
              "type": "Positioned",
              "props": {
                "left": 8,
                "top": 8
              },
              "children": [
                {
                  "type": "Container",
                  "props": {
                    "color": '#673AB7',
                    "padding": {
                      "left": 4.0,
                      "top": 4.0,
                      "right": 4.0,
                      "bottom": 4.0
                    }
                  },
                  "children": [
                    {
                      "type": "Text",
                      "props": {
                        "data": "TL",
                        "style": {
                          "color": '#FFFFFF',
                          "fontSize": 12
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
                "right": 8,
                "bottom": 8
              },
              "children": [
                {
                  "type": "Container",
                  "props": {
                    "color": '#FF5722',
                    "padding": {
                      "left": 4.0,
                      "top": 4.0,
                      "right": 4.0,
                      "bottom": 4.0
                    }
                  },
                  "children": [
                    {
                      "type": "Text",
                      "props": {
                        "data": "BR",
                        "style": {
                          "color": '#FFFFFF',
                          "fontSize": 12
                        }
                      }
                    }
                  ]
                }
              ]
            }
          ]
        },
        {
          "type": "Divider"
        },
        {
          "type": "Text",
          "props": {
            "data": "Wrap · 自动换行"
          }
        },
        {
          "type": "SizedBox",
          "props": {
            "height": 4
          }
        },
        {
          "type": "Wrap",
          "props": {
            "spacing": 8,
            "runSpacing": 8
          },
          "children": [
            {
              "type": "Container",
              "props": {
                "padding": {
                  "left": 10.0,
                  "top": 4.0,
                  "right": 10.0,
                  "bottom": 4.0
                },
                "decoration": {
                  "color": '#3F51B5',
                  "borderRadius": {
                    "radius": 16.0
                  }
                }
              },
              "children": [
                {
                  "type": "Text",
                  "props": {
                    "data": "chip 1",
                    "style": {
                      "color": '#FFFFFF',
                      "fontSize": 12
                    }
                  }
                }
              ]
            },
            {
              "type": "Container",
              "props": {
                "padding": {
                  "left": 10.0,
                  "top": 4.0,
                  "right": 10.0,
                  "bottom": 4.0
                },
                "decoration": {
                  "color": '#3F51B5',
                  "borderRadius": {
                    "radius": 16.0
                  }
                }
              },
              "children": [
                {
                  "type": "Text",
                  "props": {
                    "data": "chip 2",
                    "style": {
                      "color": '#FFFFFF',
                      "fontSize": 12
                    }
                  }
                }
              ]
            },
            {
              "type": "Container",
              "props": {
                "padding": {
                  "left": 10.0,
                  "top": 4.0,
                  "right": 10.0,
                  "bottom": 4.0
                },
                "decoration": {
                  "color": '#3F51B5',
                  "borderRadius": {
                    "radius": 16.0
                  }
                }
              },
              "children": [
                {
                  "type": "Text",
                  "props": {
                    "data": "chip 3",
                    "style": {
                      "color": '#FFFFFF',
                      "fontSize": 12
                    }
                  }
                }
              ]
            },
            {
              "type": "Container",
              "props": {
                "padding": {
                  "left": 10.0,
                  "top": 4.0,
                  "right": 10.0,
                  "bottom": 4.0
                },
                "decoration": {
                  "color": '#3F51B5',
                  "borderRadius": {
                    "radius": 16.0
                  }
                }
              },
              "children": [
                {
                  "type": "Text",
                  "props": {
                    "data": "chip 4",
                    "style": {
                      "color": '#FFFFFF',
                      "fontSize": 12
                    }
                  }
                }
              ]
            }
          ]
        },
        {
          "type": "Divider"
        },
        {
          "type": "Text",
          "props": {
            "data": "GestureDetector · 点击"
          }
        },
        {
          "type": "SizedBox",
          "props": {
            "height": 4
          }
        },
        {
          "type": "GestureDetector",
          "props": {
            "event": "tap"
          },
          "children": [
            {
              "type": "Container",
              "props": {
                "color": '#8BC34A',
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
                    "data": "点我（累计到 taps）"
                  }
                }
              ]
            }
          ]
        },
        {
          "type": "Divider"
        },
        {
          "type": "Text",
          "props": {
            "data": "Switch / Slider · 带值事件"
          }
        },
        {
          "type": "SizedBox",
          "props": {
            "height": 4
          }
        },
        {
          "type": "Row",
          "children": [
            {
              "type": "Switch",
              "props": {
                "value": this._on,
                "event": "onSwitch"
              }
            },
            {
              "type": "SizedBox",
              "props": {
                "width": 12
              }
            },
            {
              "type": "Text",
              "props": {
                "data": "开关"
              }
            },
            {
              "type": "SizedBox",
              "props": {
                "width": 12
              }
            },
            {
              "type": "Expanded",
              "children": [
                {
                  "type": "Slider",
                  "props": {
                    "value": this._slider,
                    "event": "onSlider",
                    "min": 0,
                    "max": 1
                  }
                }
              ]
            }
          ]
        },
        {
          "type": "Text",
          "props": {
            "data": "switch=" + this._on + "  slider=" + this._slider
          }
        },
        {
          "type": "Divider"
        },
        {
          "type": "Text",
          "props": {
            "data": "ListView · 列表"
          }
        },
        {
          "type": "SizedBox",
          "props": {
            "height": 4
          }
        },
        {
          "type": "ListView",
          "children": [
            {
              "type": "Container",
              "props": {
                "color": '#9E9E9E',
                "padding": {
                  "left": 6.0,
                  "top": 6.0,
                  "right": 6.0,
                  "bottom": 6.0
                }
              },
              "children": [
                {
                  "type": "Row",
                  "children": [
                    {
                      "type": "Icon",
                      "props": {
                        "icon": "list",
                        "size": 20
                      }
                    },
                    {
                      "type": "SizedBox",
                      "props": {
                        "width": 8
                      }
                    },
                    {
                      "type": "Text",
                      "props": {
                        "data": "item A"
                      }
                    }
                  ]
                }
              ]
            },
            {
              "type": "Container",
              "props": {
                "color": '#9E9E9E',
                "padding": {
                  "left": 6.0,
                  "top": 6.0,
                  "right": 6.0,
                  "bottom": 6.0
                }
              },
              "children": [
                {
                  "type": "Row",
                  "children": [
                    {
                      "type": "Icon",
                      "props": {
                        "icon": "list",
                        "size": 20
                      }
                    },
                    {
                      "type": "SizedBox",
                      "props": {
                        "width": 8
                      }
                    },
                    {
                      "type": "Text",
                      "props": {
                        "data": "item B"
                      }
                    }
                  ]
                }
              ]
            },
            {
              "type": "Container",
              "props": {
                "color": '#9E9E9E',
                "padding": {
                  "left": 6.0,
                  "top": 6.0,
                  "right": 6.0,
                  "bottom": 6.0
                }
              },
              "children": [
                {
                  "type": "Row",
                  "children": [
                    {
                      "type": "Icon",
                      "props": {
                        "icon": "list",
                        "size": 20
                      }
                    },
                    {
                      "type": "SizedBox",
                      "props": {
                        "width": 8
                      }
                    },
                    {
                      "type": "Text",
                      "props": {
                        "data": "item C"
                      }
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
    };
  };

  return WidgetShowcase;
})();

