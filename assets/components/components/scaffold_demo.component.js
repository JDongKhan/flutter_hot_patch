// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/components/scaffold_demo.dart 自动生成
// 重新生成：dart run build_runner build

import { AppBar } from '../flutter/AppBar.js';
import { Button } from '../flutter/Button.js';
import { Card } from '../flutter/Card.js';
import { Center } from '../flutter/Center.js';
import { Column } from '../flutter/Column.js';
import { Padding } from '../flutter/Padding.js';
import { Scaffold } from '../flutter/Scaffold.js';
import { SingleChildScrollView } from '../flutter/SingleChildScrollView.js';
import { SizedBox } from '../flutter/SizedBox.js';
import { Text } from '../flutter/Text.js';
// 节点工厂：归一化 props/children，形状与 widget 模块一致。
function __h(type, props, children) {
  return {
    type: type,
    props: props || {},
    children: children == null
        ? []
        : (Array.isArray(children) ? children : [children]),
  };
}

class ScaffoldDemoComponent {
  constructor() {
    this._count = 0;
  }
  _inc() { this.setState(function(){ this._count += 1; }); }
  build() {
    return Scaffold({}, [
        AppBar({}, [
            Text({
                "data": "Scaffold · 页面骨架"
              })
          ]),
        Center({}, [
            SingleChildScrollView({
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
                    Text({
                        "data": "SingleChildScrollView · 滚动容器",
                        "style": {
                          "fontSize": 18,
                          "fontWeight": "bold"
                        }
                      }),
                    SizedBox({
                        "height": 8
                      }),
                    Text({
                        "data": "Scaffold / AppBar / Center / SingleChildScrollView 同页演示，向下滚动查看更多",
                        "style": {
                          "fontSize": 12,
                          "color": '#9E9E9E'
                        }
                      }),
                    SizedBox({
                        "height": 16
                      }),
                    Card({}, [
                        Padding({
                            "padding": {
                              "left": 16.0,
                              "top": 16.0,
                              "right": 16.0,
                              "bottom": 16.0
                            }
                          }, [
                            Column({}, [
                                Text({
                                    "data": "count = " + this._count
                                  }),
                                SizedBox({
                                    "height": 8
                                  }),
                                Button({
                                    "kind": "elevated",
                                    "label": "Bump",
                                    "event": "_inc"
                                  })
                              ])
                          ])
                      ]),
                    SizedBox({
                        "height": 8
                      }),
                    Card({}, [
                        Padding({
                            "padding": {
                              "left": 16.0,
                              "top": 16.0,
                              "right": 16.0,
                              "bottom": 16.0
                            }
                          }, [
                            Column({
                                "crossAxisAlignment": "start"
                              }, [
                                Text({
                                    "data": "Center · 居中",
                                    "style": {
                                      "fontSize": 15,
                                      "fontWeight": "w600"
                                    }
                                  }),
                                SizedBox({
                                    "height": 4
                                  }),
                                Text({
                                    "data": "body 由 Center 包裹，内容水平垂直居中",
                                    "style": {
                                      "fontSize": 12,
                                      "color": '#9E9E9E'
                                    }
                                  })
                              ])
                          ])
                      ]),
                    SizedBox({
                        "height": 8
                      }),
                    Card({}, [
                        Padding({
                            "padding": {
                              "left": 16.0,
                              "top": 16.0,
                              "right": 16.0,
                              "bottom": 16.0
                            }
                          }, [
                            Column({
                                "crossAxisAlignment": "start"
                              }, [
                                Text({
                                    "data": "AppBar · 顶栏",
                                    "style": {
                                      "fontSize": 15,
                                      "fontWeight": "w600"
                                    }
                                  }),
                                SizedBox({
                                    "height": 4
                                  }),
                                Text({
                                    "data": "页面顶部的 AppBar 展示标题",
                                    "style": {
                                      "fontSize": 12,
                                      "color": '#9E9E9E'
                                    }
                                  })
                              ])
                          ])
                      ]),
                    SizedBox({
                        "height": 8
                      }),
                    Card({}, [
                        Padding({
                            "padding": {
                              "left": 16.0,
                              "top": 16.0,
                              "right": 16.0,
                              "bottom": 16.0
                            }
                          }, [
                            Column({
                                "crossAxisAlignment": "start"
                              }, [
                                Text({
                                    "data": "SingleChildScrollView · 滚动",
                                    "style": {
                                      "fontSize": 15,
                                      "fontWeight": "w600"
                                    }
                                  }),
                                SizedBox({
                                    "height": 4
                                  }),
                                Text({
                                    "data": "内容超高时整体可滚动",
                                    "style": {
                                      "fontSize": 12,
                                      "color": '#9E9E9E'
                                    }
                                  })
                              ])
                          ])
                      ]),
                    SizedBox({
                        "height": 8
                      }),
                    Card({}, [
                        Padding({
                            "padding": {
                              "left": 16.0,
                              "top": 16.0,
                              "right": 16.0,
                              "bottom": 16.0
                            }
                          }, [
                            Column({
                                "crossAxisAlignment": "start"
                              }, [
                                Text({
                                    "data": "Card · 卡片",
                                    "style": {
                                      "fontSize": 15,
                                      "fontWeight": "w600"
                                    }
                                  }),
                                SizedBox({
                                    "height": 4
                                  }),
                                Text({
                                    "data": "Material 卡片承载条目",
                                    "style": {
                                      "fontSize": 12,
                                      "color": '#9E9E9E'
                                    }
                                  })
                              ])
                          ])
                      ]),
                    SizedBox({
                        "height": 8
                      }),
                    Card({}, [
                        Padding({
                            "padding": {
                              "left": 16.0,
                              "top": 16.0,
                              "right": 16.0,
                              "bottom": 16.0
                            }
                          }, [
                            Text({
                                "data": "Item 6 · 第 6 个条目，用于撑高滚动内容",
                                "style": {
                                  "fontSize": 13
                                }
                              })
                          ])
                      ]),
                    SizedBox({
                        "height": 8
                      }),
                    Card({}, [
                        Padding({
                            "padding": {
                              "left": 16.0,
                              "top": 16.0,
                              "right": 16.0,
                              "bottom": 16.0
                            }
                          }, [
                            Text({
                                "data": "Item 7 · 第 7 个条目，用于撑高滚动内容",
                                "style": {
                                  "fontSize": 13
                                }
                              })
                          ])
                      ]),
                    SizedBox({
                        "height": 8
                      }),
                    Card({}, [
                        Padding({
                            "padding": {
                              "left": 16.0,
                              "top": 16.0,
                              "right": 16.0,
                              "bottom": 16.0
                            }
                          }, [
                            Text({
                                "data": "Item 8 · 第 8 个条目，用于撑高滚动内容",
                                "style": {
                                  "fontSize": 13
                                }
                              })
                          ])
                      ]),
                    SizedBox({
                        "height": 8
                      }),
                    Card({}, [
                        Padding({
                            "padding": {
                              "left": 16.0,
                              "top": 16.0,
                              "right": 16.0,
                              "bottom": 16.0
                            }
                          }, [
                            Text({
                                "data": "Item 9 · 第 9 个条目，用于撑高滚动内容",
                                "style": {
                                  "fontSize": 13
                                }
                              })
                          ])
                      ]),
                    SizedBox({
                        "height": 8
                      }),
                    Card({}, [
                        Padding({
                            "padding": {
                              "left": 16.0,
                              "top": 16.0,
                              "right": 16.0,
                              "bottom": 16.0
                            }
                          }, [
                            Text({
                                "data": "Item 10 · 第 10 个条目，用于撑高滚动内容",
                                "style": {
                                  "fontSize": 13
                                }
                              })
                          ])
                      ])
                  ])
              ])
          ])
      ]);
  }
}
export function ScaffoldDemo(props, children) {
  return __h(ScaffoldDemoComponent, props, children);
}

