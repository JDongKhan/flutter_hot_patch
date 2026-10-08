// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/components/widget_details.dart 自动生成
// 重新生成：dart run build_runner build

import { __h } from '../flutter/Node.js';
import { Align } from '../flutter/Align.js';
import { AppBar } from '../flutter/AppBar.js';
import { Button } from '../flutter/Button.js';
import { Card } from '../flutter/Card.js';
import { Center } from '../flutter/Center.js';
import { Chip } from '../flutter/Chip.js';
import { CircleAvatar } from '../flutter/CircleAvatar.js';
import { ClipRRect } from '../flutter/ClipRRect.js';
import { Column } from '../flutter/Column.js';
import { Container } from '../flutter/Container.js';
import { Divider } from '../flutter/Divider.js';
import { Expanded } from '../flutter/Expanded.js';
import { Icon } from '../flutter/Icon.js';
import { Image } from '../flutter/Image.js';
import { ListTile } from '../flutter/ListTile.js';
import { ListView } from '../flutter/ListView.js';
import { Padding } from '../flutter/Padding.js';
import { Positioned } from '../flutter/Positioned.js';
import { Row } from '../flutter/Row.js';
import { Scaffold } from '../flutter/Scaffold.js';
import { SingleChildScrollView } from '../flutter/SingleChildScrollView.js';
import { SizedBox } from '../flutter/SizedBox.js';
import { Stack } from '../flutter/Stack.js';
import { Text } from '../flutter/Text.js';
import { Wrap } from '../flutter/Wrap.js';

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
            "data": "Row + Expanded / Flexible",
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
            SizedBox({
                "width": 4
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
            Stack({}, [
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
            "runSpacing": 8
          }, [
            ...(function(){ var out = []; for (var i = 1; (i <= 5); (i++)) { out.push.apply(out, [Chip({ "label": "chip " + i, "backgroundColor": '@Colors.teal.shade50' })]); } return out; })()
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
              "color": '#009688'
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
            "data": "Card",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }),
        Card({
            "elevation": 2
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
                    "data": "卡片内容（elevation=2）"
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
  }
  build() {
    return Column({
        "crossAxisAlignment": "stretch"
      }, [
        Text({
            "data": "ListView · 列表",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }),
        SizedBox({
            "height": 160
          }, [
            ListView({}, [
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
          ]),
        SizedBox({
            "height": 12
          }),
        Text({
            "data": "SingleChildScrollView · 长内容滚动",
            "style": {
              "fontSize": 16,
              "fontWeight": "bold"
            }
          }),
        SingleChildScrollView({
            "scrollDirection": "horizontal"
          }, [
            Row({}, [
                ...(function(){ var out = []; for (var i = 1; (i <= 8); (i++)) { out.push.apply(out, [Padding({ "padding": { "left": 4.0, "top": 4.0, "right": 4.0, "bottom": 4.0 } }, [ Chip({ "label": "横向 " + i }) ])]); } return out; })()
              ])
          ])
      ]);
  }
}
export function ScrollDetail(props, children) {
  return __h(ScrollDetailComponent, props, children);
}

class ScaffoldDetailComponent {
  constructor() {
  }
  build() {
    return Scaffold({}, [
        AppBar({}, [
            Text({
                "data": "Scaffold / AppBar / Center"
              })
          ]),
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
                    "data": "Scaffold + AppBar + Center + SingleChildScrollView"
                  })
              ])
          ])
      ]);
  }
}
export function ScaffoldDetail(props, children) {
  return __h(ScaffoldDetailComponent, props, children);
}

