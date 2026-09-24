// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/components/scaffold_demo.dart 自动生成
// 重新生成：dart run build_runner build

// 组件注册表：多个 JS 补丁共享，加载顺序无关
var __components = __components || {};
// 实例注册表：每个 HotPatchWidget 持有自己的组件实例（状态互不共享）
var __instances = __instances || {};

// IIFE 闭包：不泄漏到全局，加载多个 JS 不会重名
__components['ScaffoldDemo'] = (function() {
  // 构造函数：new 一次得到一个独立组件实例，可重复实例化
  function ScaffoldDemo() {
    this._count = 0;
  }

  ScaffoldDemo.prototype._inc = function() { this.setState(function(){ this._count += 1; }); };

  ScaffoldDemo.prototype.build = function() {
    return {
      "type": "Scaffold",
      "children": [
        {
          "type": "AppBar",
          "children": [
            {
              "type": "Text",
              "props": {
                "data": "Scaffold · 页面骨架"
              }
            }
          ]
        },
        {
          "type": "Center",
          "children": [
            {
              "type": "SingleChildScrollView",
              "props": {
                "padding": {
                  "left": 16.0,
                  "top": 16.0,
                  "right": 16.0,
                  "bottom": 16.0
                }
              },
              "children": [
                {
                  "type": "Column",
                  "props": {
                    "mainAxisSize": "min"
                  },
                  "children": [
                    {
                      "type": "Text",
                      "props": {
                        "data": "SingleChildScrollView · 滚动容器",
                        "style": {
                          "fontSize": 18,
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
                        "data": "Scaffold / AppBar / Center / SingleChildScrollView 同页演示，向下滚动查看更多",
                        "style": {
                          "fontSize": 12,
                          "color": '#9E9E9E'
                        }
                      }
                    },
                    {
                      "type": "SizedBox",
                      "props": {
                        "height": 16
                      }
                    },
                    {
                      "type": "Card",
                      "children": [
                        {
                          "type": "Padding",
                          "props": {
                            "padding": {
                              "left": 16.0,
                              "top": 16.0,
                              "right": 16.0,
                              "bottom": 16.0
                            }
                          },
                          "children": [
                            {
                              "type": "Column",
                              "children": [
                                {
                                  "type": "Text",
                                  "props": {
                                    "data": "count = " + this._count
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
                                    "label": "Bump",
                                    "event": "_inc"
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
                        "height": 8
                      }
                    },
                    {
                      "type": "Card",
                      "children": [
                        {
                          "type": "Padding",
                          "props": {
                            "padding": {
                              "left": 16.0,
                              "top": 16.0,
                              "right": 16.0,
                              "bottom": 16.0
                            }
                          },
                          "children": [
                            {
                              "type": "Column",
                              "props": {
                                "crossAxisAlignment": "start"
                              },
                              "children": [
                                {
                                  "type": "Text",
                                  "props": {
                                    "data": "Center · 居中",
                                    "style": {
                                      "fontSize": 15,
                                      "fontWeight": "w600"
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
                                    "data": "body 由 Center 包裹，内容水平垂直居中",
                                    "style": {
                                      "fontSize": 12,
                                      "color": '#9E9E9E'
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
                      "type": "SizedBox",
                      "props": {
                        "height": 8
                      }
                    },
                    {
                      "type": "Card",
                      "children": [
                        {
                          "type": "Padding",
                          "props": {
                            "padding": {
                              "left": 16.0,
                              "top": 16.0,
                              "right": 16.0,
                              "bottom": 16.0
                            }
                          },
                          "children": [
                            {
                              "type": "Column",
                              "props": {
                                "crossAxisAlignment": "start"
                              },
                              "children": [
                                {
                                  "type": "Text",
                                  "props": {
                                    "data": "AppBar · 顶栏",
                                    "style": {
                                      "fontSize": 15,
                                      "fontWeight": "w600"
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
                                    "data": "页面顶部的 AppBar 展示标题",
                                    "style": {
                                      "fontSize": 12,
                                      "color": '#9E9E9E'
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
                      "type": "SizedBox",
                      "props": {
                        "height": 8
                      }
                    },
                    {
                      "type": "Card",
                      "children": [
                        {
                          "type": "Padding",
                          "props": {
                            "padding": {
                              "left": 16.0,
                              "top": 16.0,
                              "right": 16.0,
                              "bottom": 16.0
                            }
                          },
                          "children": [
                            {
                              "type": "Column",
                              "props": {
                                "crossAxisAlignment": "start"
                              },
                              "children": [
                                {
                                  "type": "Text",
                                  "props": {
                                    "data": "SingleChildScrollView · 滚动",
                                    "style": {
                                      "fontSize": 15,
                                      "fontWeight": "w600"
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
                                    "data": "内容超高时整体可滚动",
                                    "style": {
                                      "fontSize": 12,
                                      "color": '#9E9E9E'
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
                      "type": "SizedBox",
                      "props": {
                        "height": 8
                      }
                    },
                    {
                      "type": "Card",
                      "children": [
                        {
                          "type": "Padding",
                          "props": {
                            "padding": {
                              "left": 16.0,
                              "top": 16.0,
                              "right": 16.0,
                              "bottom": 16.0
                            }
                          },
                          "children": [
                            {
                              "type": "Column",
                              "props": {
                                "crossAxisAlignment": "start"
                              },
                              "children": [
                                {
                                  "type": "Text",
                                  "props": {
                                    "data": "Card · 卡片",
                                    "style": {
                                      "fontSize": 15,
                                      "fontWeight": "w600"
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
                                    "data": "Material 卡片承载条目",
                                    "style": {
                                      "fontSize": 12,
                                      "color": '#9E9E9E'
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
                      "type": "SizedBox",
                      "props": {
                        "height": 8
                      }
                    },
                    {
                      "type": "Card",
                      "children": [
                        {
                          "type": "Padding",
                          "props": {
                            "padding": {
                              "left": 16.0,
                              "top": 16.0,
                              "right": 16.0,
                              "bottom": 16.0
                            }
                          },
                          "children": [
                            {
                              "type": "Text",
                              "props": {
                                "data": "Item 6 · 第 6 个条目，用于撑高滚动内容",
                                "style": {
                                  "fontSize": 13
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
                        "height": 8
                      }
                    },
                    {
                      "type": "Card",
                      "children": [
                        {
                          "type": "Padding",
                          "props": {
                            "padding": {
                              "left": 16.0,
                              "top": 16.0,
                              "right": 16.0,
                              "bottom": 16.0
                            }
                          },
                          "children": [
                            {
                              "type": "Text",
                              "props": {
                                "data": "Item 7 · 第 7 个条目，用于撑高滚动内容",
                                "style": {
                                  "fontSize": 13
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
                        "height": 8
                      }
                    },
                    {
                      "type": "Card",
                      "children": [
                        {
                          "type": "Padding",
                          "props": {
                            "padding": {
                              "left": 16.0,
                              "top": 16.0,
                              "right": 16.0,
                              "bottom": 16.0
                            }
                          },
                          "children": [
                            {
                              "type": "Text",
                              "props": {
                                "data": "Item 8 · 第 8 个条目，用于撑高滚动内容",
                                "style": {
                                  "fontSize": 13
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
                        "height": 8
                      }
                    },
                    {
                      "type": "Card",
                      "children": [
                        {
                          "type": "Padding",
                          "props": {
                            "padding": {
                              "left": 16.0,
                              "top": 16.0,
                              "right": 16.0,
                              "bottom": 16.0
                            }
                          },
                          "children": [
                            {
                              "type": "Text",
                              "props": {
                                "data": "Item 9 · 第 9 个条目，用于撑高滚动内容",
                                "style": {
                                  "fontSize": 13
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
                        "height": 8
                      }
                    },
                    {
                      "type": "Card",
                      "children": [
                        {
                          "type": "Padding",
                          "props": {
                            "padding": {
                              "left": 16.0,
                              "top": 16.0,
                              "right": 16.0,
                              "bottom": 16.0
                            }
                          },
                          "children": [
                            {
                              "type": "Text",
                              "props": {
                                "data": "Item 10 · 第 10 个条目，用于撑高滚动内容",
                                "style": {
                                  "fontSize": 13
                                }
                              }
                            }
                          ]
                        }
                      ]
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

  return ScaffoldDemo;
})();

