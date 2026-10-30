// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/app/pages/mine_page.dart 自动生成
// 重新生成：dart run build_runner build

import { AppService } from '../service/app_service.js';
import { MineFeed } from '../model/app_models.js';
import { MenuEntry } from '../model/app_models.js';
import { kBrand, kPrice } from 'detail_pages.js';
import { Alignment, BorderRadius, BoxDecoration, BoxFit, Center, CircularProgressIndicator, ClipOval, Color, Colors, Column, Container, CrossAxisAlignment, Divider, EdgeInsets, Expanded, FontWeight, GestureDetector, HitTestBehavior, Icon, Icons, Image, LinearGradient, ListView, Offset, Padding, Row, SafeArea, SizedBox, Text, TextOverflow, TextStyle, Transform } from '../../flutter.js';

// 组件 MinePage
export class MinePage {
  static _menuTints = [new Color({value: 0xFFE8F2FF}), new Color({value: 0xFFFFF3E0}), new Color({value: 0xFFEEF0F4}), new Color({value: 0xFFE9F7EF})];
  constructor(args) {
    this.props = args || {};
    this._service = new AppService();
    this._feed = null;
  }
  initState() {
    console.log("MinePage initState ---");
    this._load();
  }
  async _load() {
    var feed = await this._service.fetchMine();
    this.setState(() => { this._feed = feed; });
  }
  _openMenu(m) {
    if ((m.screen == "orders")) {
      _app_host_.invoke("openOrders", []);
    } else {
      if ((m.screen == "showcase")) {
        _app_host_.invoke("openWidgetShowcase", []);
      } else {
        _app_host_.invoke("open", ["https://flutter.dev", (m.arg.isEmpty ? m.title : m.arg)]);
      }
    }
  }
  build(context) {
    var feed = this._feed;
    if ((feed == null)) {
      return (this.__k0 || (this.__k0 = new Center({
        "child": new CircularProgressIndicator({})
      })));
    }
    return new ListView({
      "padding": EdgeInsets.zero,
      "children": [
        new Container({
          "padding": (this.__k1 || (this.__k1 = EdgeInsets.fromLTRB({
            "bottom": 22,
            "left": 18,
            "right": 18,
            "top": 16
          }))),
          "decoration": (this.__k2 || (this.__k2 = new BoxDecoration({
            "gradient": new LinearGradient({
              "colors": [
                new Color({
                  "value": 0xFF1E88FF
                }),
                new Color({
                  "value": 0xFF0E7AFB
                })
              ],
              "begin": Alignment.topLeft,
              "end": Alignment.bottomRight
            })
          }))),
          "child": new SafeArea({
            "bottom": false,
            "child": new GestureDetector({
              "onTap": this.__bindFn(0, [], () => _app_host_.invoke("openLogin", [])),
              "child": new Row({
                "children": [
                  new ClipOval({
                    "child": Image.asset({
                      "width": 58,
                      "height": 58,
                      "fit": BoxFit.cover,
                      "errorBuilder": (context, e, s) => new Container({
                        "width": 58,
                        "height": 58,
                        "color": (this.__k3 || (this.__k3 = new Color({
                          "value": 0x33FFFFFF
                        })))
                      }),
                      "name": this._feed.avatar
                    })
                  }),
                  (this.__k4 || (this.__k4 = new SizedBox({
                    "width": 13
                  }))),
                  (this.__k5 || (this.__k5 = new Expanded({
                    "child": new Column({
                      "crossAxisAlignment": CrossAxisAlignment.start,
                      "children": [
                        new Text({
                          "style": new TextStyle({
                            "fontSize": 17.5,
                            "fontWeight": FontWeight.w700,
                            "color": Colors.white
                          }),
                          "data": "旅行家小七"
                        }),
                        new SizedBox({
                          "height": 4
                        }),
                        new Text({
                          "style": new TextStyle({
                            "fontSize": 12,
                            "color": new Color({
                              "value": 0xCCFFFFFF
                            })
                          }),
                          "data": "138****8888"
                        }),
                        new SizedBox({
                          "height": 6
                        }),
                        new Text({
                          "style": new TextStyle({
                            "fontSize": 11,
                            "color": new Color({
                              "value": 0xB3FFFFFF
                            })
                          }),
                          "data": "点击头像可跳转登录页 ›"
                        })
                      ]
                    })
                  }))),
                  (this.__k6 || (this.__k6 = new Icon({
                    "color": new Color({
                      "value": 0xCCFFFFFF
                    }),
                    "icon": Icons.chevron_right,
                    "size": 20
                  })))
                ]
              })
            })
          })
        }),
        Transform.translate({
          "offset": (this.__k7 || (this.__k7 = new Offset({
            "dx": 0,
            "dy": (-12)
          }))),
          "child": new Container({
            "margin": (this.__k8 || (this.__k8 = EdgeInsets.symmetric({
              "horizontal": 12
            }))),
            "padding": (this.__k9 || (this.__k9 = EdgeInsets.symmetric({
              "vertical": 14
            }))),
            "decoration": new BoxDecoration({
              "color": Colors.white,
              "borderRadius": BorderRadius.circular({
                "radius": 14
              })
            }),
            "child": new Row({
              "children": [
                ...(() => { var out = []; for (let s of this._feed.stats) { out.push.apply(out, [new Expanded({
                        "child": new GestureDetector({
                          "onTap": this.__bindFn(1, [], () => _app_host_.invoke("openOrders", [])),
                          "child": new Column({
                            "children": [
                              new Text({
                                "style": (this.__k10 || (this.__k10 = new TextStyle({
                                  "color": new Color({
                                    "value": 0xFF171A21
                                  }),
                                  "fontSize": 17,
                                  "fontWeight": FontWeight.w700
                                }))),
                                "data": s[1]
                              }),
                              (this.__k11 || (this.__k11 = new SizedBox({
                                "height": 3
                              }))),
                              new Text({
                                "style": (this.__k12 || (this.__k12 = new TextStyle({
                                  "color": new Color({
                                    "value": 0xFF8B909A
                                  }),
                                  "fontSize": 11.5
                                }))),
                                "data": s[0]
                              })
                            ]
                          })
                        })
                      })]); } return out; })()
              ]
            })
          })
        }),
        new Container({
          "margin": (this.__k13 || (this.__k13 = EdgeInsets.fromLTRB({
            "bottom": 12,
            "left": 12,
            "right": 12,
            "top": 0
          }))),
          "decoration": new BoxDecoration({
            "color": Colors.white,
            "borderRadius": BorderRadius.circular({
              "radius": 14
            })
          }),
          "child": new Column({
            "children": [
              ...(() => { var out = []; for (let i = 0; (i < this._feed.menu.length); (i++)) { out.push.apply(out, [...((i > 0) ? [(this.__k14 || (this.__k14 = new Divider({
                        "color": new Color({
                          "value": 0xFFF0F2F6
                        }),
                        "height": 1,
                        "indent": 56
                      })))] : []), new GestureDetector({
                      "onTap": this.__bindFn(2, [i], () => this._openMenu(this._feed.menu[i])),
                      "child": new Padding({
                        "padding": (this.__k15 || (this.__k15 = EdgeInsets.fromLTRB({
                          "bottom": 12,
                          "left": 14,
                          "right": 12,
                          "top": 12
                        }))),
                        "child": new Row({
                          "children": [
                            new Container({
                              "width": 30,
                              "height": 30,
                              "alignment": Alignment.center,
                              "decoration": new BoxDecoration({
                                "color": MinePage._menuTints[(i % MinePage._menuTints.length)],
                                "borderRadius": BorderRadius.circular({
                                  "radius": 9
                                })
                              }),
                              "child": new Text({
                                "style": (this.__k16 || (this.__k16 = new TextStyle({
                                  "fontSize": 15
                                }))),
                                "data": this._feed.menu[i].emoji
                              })
                            }),
                            (this.__k17 || (this.__k17 = new SizedBox({
                              "width": 12
                            }))),
                            new Expanded({
                              "child": new Text({
                                "style": (this.__k18 || (this.__k18 = new TextStyle({
                                  "fontSize": 14
                                }))),
                                "data": this._feed.menu[i].title
                              })
                            }),
                            (this.__k19 || (this.__k19 = new Icon({
                              "color": new Color({
                                "value": 0xFFC3C8D2
                              }),
                              "icon": Icons.chevron_right,
                              "size": 18
                            })))
                          ]
                        })
                      })
                    })]); } return out; })()
            ]
          })
        }),
        new Padding({
          "padding": (this.__k20 || (this.__k20 = EdgeInsets.fromLTRB({
            "bottom": 20,
            "left": 12,
            "right": 12,
            "top": 0
          }))),
          "child": new GestureDetector({
            "onTap": this.__bindFn(3, [], () => _app_host_.invoke("toast", ["已退出登录（演示）"])),
            "child": new Container({
              "height": 46,
              "alignment": Alignment.center,
              "decoration": new BoxDecoration({
                "color": Colors.white,
                "borderRadius": BorderRadius.circular({
                  "radius": 14
                })
              }),
              "child": (this.__k21 || (this.__k21 = new Text({
                "data": "退出登录",
                "style": new TextStyle({
                  "fontSize": 14,
                  "fontWeight": FontWeight.w600,
                  "color": kPrice
                })
              })))
            })
          })
        }),
        (this.__k22 || (this.__k22 = new Padding({
          "child": new Text({
            "style": new TextStyle({
              "fontSize": 12.5,
              "fontWeight": FontWeight.w700,
              "color": new Color({
                "value": 0xFF98A0AC
              })
            }),
            "data": "开发者"
          }),
          "padding": EdgeInsets.fromLTRB({
            "left": 18,
            "top": 4,
            "right": 18,
            "bottom": 8
          })
        }))),
        new Container({
          "margin": (this.__k23 || (this.__k23 = EdgeInsets.fromLTRB({
            "bottom": 24,
            "left": 12,
            "right": 12,
            "top": 0
          }))),
          "decoration": new BoxDecoration({
            "color": Colors.white,
            "borderRadius": BorderRadius.circular({
              "radius": 14
            })
          }),
          "child": new Column({
            "children": [
              new _DevRow({
                "icon": Icons.widgets_outlined,
                "title": "组件案例",
                "subtitle": "常用组件 原生 ↔ JS 同屏对比",
                "onTap": () => { return _app_host_.invoke("openWidgetShowcase", []); }
              }),
              (this.__k14 || (this.__k14 = new Divider({
                "color": new Color({
                  "value": 0xFFF0F2F6
                }),
                "height": 1,
                "indent": 56
              }))),
              new _DevRow({
                "icon": Icons.compare_arrows,
                "title": "热更 Demo 列表",
                "subtitle": "HelloCard / ProviderCard / WatchDemo 等对比",
                "onTap": () => { return _app_host_.invoke("openDemoList", []); }
              })
            ]
          })
        })
      ]
    });
  }
}

// 组件 _DevRow
export class _DevRow {
  constructor(args) {
    this.props = args || {};
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.icon = (args && args.icon !== undefined) ? args.icon : null;
    this.title = (args && args.title !== undefined) ? args.title : '';
    this.subtitle = (args && args.subtitle !== undefined) ? args.subtitle : '';
    this.onTap = (args && args.onTap !== undefined) ? args.onTap : null;
  }
  build(context) {
    return new GestureDetector({
      "onTap": this.__bindFn(0, [], (...__a) => this.onTap(...__a)),
      "behavior": HitTestBehavior.opaque,
      "child": new Padding({
        "padding": (this.__k0 || (this.__k0 = EdgeInsets.fromLTRB({
          "bottom": 12,
          "left": 14,
          "right": 12,
          "top": 12
        }))),
        "child": new Row({
          "children": [
            new Container({
              "width": 30,
              "height": 30,
              "alignment": Alignment.center,
              "decoration": new BoxDecoration({
                "color": (this.__k1 || (this.__k1 = new Color({
                  "value": 0xFFE8F2FF
                }))),
                "borderRadius": BorderRadius.circular({
                  "radius": 9
                })
              }),
              "child": new Icon({
                "size": 16,
                "color": kBrand,
                "icon": this.icon
              })
            }),
            (this.__k2 || (this.__k2 = new SizedBox({
              "width": 12
            }))),
            new Expanded({
              "child": new Column({
                "crossAxisAlignment": CrossAxisAlignment.start,
                "children": [
                  new Text({
                    "style": (this.__k3 || (this.__k3 = new TextStyle({
                      "fontSize": 14
                    }))),
                    "data": this.title
                  }),
                  (this.__k4 || (this.__k4 = new SizedBox({
                    "height": 3
                  }))),
                  new Text({
                    "maxLines": 1,
                    "overflow": TextOverflow.ellipsis,
                    "style": (this.__k5 || (this.__k5 = new TextStyle({
                      "color": new Color({
                        "value": 0xFF98A0AC
                      }),
                      "fontSize": 11
                    }))),
                    "data": this.subtitle
                  })
                ]
              })
            }),
            (this.__k6 || (this.__k6 = new Icon({
              "color": new Color({
                "value": 0xFFC3C8D2
              }),
              "icon": Icons.chevron_right,
              "size": 18
            })))
          ]
        })
      })
    });
  }
}

