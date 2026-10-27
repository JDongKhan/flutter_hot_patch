// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/app/pages/mine_page.dart 自动生成
// 重新生成：dart run build_runner build

import { AppService } from '../service/app_service.js';
import { MineFeed } from '../model/app_models.js';
import { kBrand, kPrice } from 'detail_pages.js';
import { Center, CircularProgressIndicator, ClipOval, Column, Container, Divider, Expanded, GestureDetector, Icon, Image, Padding, Row, SafeArea, SizedBox, Text, Transform, __h } from '../../flutter.js';

const _menuTints = [new Color({value: 0xFFE8F2FF}), new Color({value: 0xFFFFF3E0}), new Color({value: 0xFFEEF0F4}), new Color({value: 0xFFE9F7EF})];

// 组件 MinePage
export class MinePage {
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
    return __h('ListView', {
      "padding": {
        "left": 0,
        "top": 0,
        "right": 0,
        "bottom": 0
      },
      "children": [
        new Container({
          "padding": {
            "left": 18.0,
            "top": 16.0,
            "right": 18.0,
            "bottom": 22.0
          },
          "decoration": {
            "gradient": {
              "kind": "linear",
              "colors": [
                new Color({value: 0xFF1E88FF}),
                new Color({value: 0xFF0E7AFB})
              ],
              "begin": "topLeft",
              "end": "bottomRight"
            }
          },
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
                      "fit": "cover",
                      "errorBuilder": (context, e, s) => new Container({
                        "width": 58,
                        "height": 58,
                        "color": new Color({value: 0x33FFFFFF})
                      }),
                      "name": this._feed.avatar
                    })
                  }),
                  (this.__k1 || (this.__k1 = new SizedBox({
                    "width": 13
                  }))),
                  (this.__k2 || (this.__k2 = new Expanded({
                    "child": new Column({
                      "crossAxisAlignment": "start",
                      "children": [
                        new Text({
                          "style": {
                            "fontSize": 17.5,
                            "fontWeight": "w700",
                            "color": Colors.white
                          },
                          "data": "旅行家小七"
                        }),
                        new SizedBox({
                          "height": 4
                        }),
                        new Text({
                          "style": {
                            "fontSize": 12,
                            "color": new Color({value: 0xCCFFFFFF})
                          },
                          "data": "138****8888"
                        }),
                        new SizedBox({
                          "height": 6
                        }),
                        new Text({
                          "style": {
                            "fontSize": 11,
                            "color": new Color({value: 0xB3FFFFFF})
                          },
                          "data": "点击头像可跳转登录页 ›"
                        })
                      ]
                    })
                  }))),
                  (this.__k3 || (this.__k3 = new Icon({
                    "color": new Color({value: 0xCCFFFFFF}),
                    "icon": "chevron_right",
                    "size": 20
                  })))
                ]
              })
            })
          })
        }),
        Transform.translate({
          "offset": { "dx": 0, "dy": (-12) },
          "child": new Container({
            "margin": {
              "left": 12.0,
              "top": 0.0,
              "right": 12.0,
              "bottom": 0.0
            },
            "padding": {
              "left": 0.0,
              "top": 14.0,
              "right": 0.0,
              "bottom": 14.0
            },
            "decoration": {
              "color": Colors.white,
              "borderRadius": {
                "radius": 14.0
              }
            },
            "child": new Row({
              "children": [
                ...(() => { var out = []; for (let s of this._feed.stats) { out.push.apply(out, [new Expanded({
                        "child": new GestureDetector({
                          "onTap": this.__bindFn(1, [], () => _app_host_.invoke("openOrders", [])),
                          "child": new Column({
                            "children": [
                              new Text({
                                "style": {
                                  "fontSize": 17,
                                  "fontWeight": "w700",
                                  "color": new Color({value: 0xFF171A21})
                                },
                                "data": s[1]
                              }),
                              (this.__k4 || (this.__k4 = new SizedBox({
                                "height": 3
                              }))),
                              new Text({
                                "style": {
                                  "fontSize": 11.5,
                                  "color": new Color({value: 0xFF8B909A})
                                },
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
          "margin": {
            "left": 12.0,
            "top": 0.0,
            "right": 12.0,
            "bottom": 12.0
          },
          "decoration": {
            "color": Colors.white,
            "borderRadius": {
              "radius": 14.0
            }
          },
          "child": new Column({
            "children": [
              ...(() => { var out = []; for (let i = 0; (i < this._feed.menu.length); (i++)) { out.push.apply(out, [...((i > 0) ? [(this.__k5 || (this.__k5 = new Divider({
                        "color": new Color({value: 0xFFF0F2F6}),
                        "height": 1,
                        "indent": 56
                      })))] : []), new GestureDetector({
                      "onTap": this.__bindFn(2, [i], () => this._openMenu(this._feed.menu[i])),
                      "child": new Padding({
                        "padding": {
                          "left": 14.0,
                          "top": 12.0,
                          "right": 12.0,
                          "bottom": 12.0
                        },
                        "child": new Row({
                          "children": [
                            new Container({
                              "width": 30,
                              "height": 30,
                              "alignment": "center",
                              "decoration": {
                                "color": _menuTints[(i % _menuTints.length)],
                                "borderRadius": {
                                  "radius": 9.0
                                }
                              },
                              "child": new Text({
                                "style": {
                                  "fontSize": 15
                                },
                                "data": this._feed.menu[i].emoji
                              })
                            }),
                            (this.__k6 || (this.__k6 = new SizedBox({
                              "width": 12
                            }))),
                            new Expanded({
                              "child": new Text({
                                "style": {
                                  "fontSize": 14
                                },
                                "data": this._feed.menu[i].title
                              })
                            }),
                            (this.__k7 || (this.__k7 = new Icon({
                              "color": new Color({value: 0xFFC3C8D2}),
                              "icon": "chevron_right",
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
          "padding": {
            "left": 12.0,
            "top": 0.0,
            "right": 12.0,
            "bottom": 20.0
          },
          "child": new GestureDetector({
            "onTap": this.__bindFn(3, [], () => _app_host_.invoke("toast", ["已退出登录（演示）"])),
            "child": new Container({
              "height": 46,
              "alignment": "center",
              "decoration": {
                "color": Colors.white,
                "borderRadius": {
                  "radius": 14.0
                }
              },
              "child": (this.__k8 || (this.__k8 = new Text({
                "data": "退出登录",
                "style": {
                  "color": kPrice,
                  "fontSize": 14,
                  "fontWeight": "w600"
                }
              })))
            })
          })
        }),
        (this.__k9 || (this.__k9 = new Padding({
          "child": new Text({
            "style": {
              "fontSize": 12.5,
              "fontWeight": "w700",
              "color": new Color({value: 0xFF98A0AC})
            },
            "data": "开发者"
          }),
          "padding": {
            "bottom": 8.0,
            "left": 18.0,
            "right": 18.0,
            "top": 4.0
          }
        }))),
        new Container({
          "margin": {
            "left": 12.0,
            "top": 0.0,
            "right": 12.0,
            "bottom": 24.0
          },
          "decoration": {
            "color": Colors.white,
            "borderRadius": {
              "radius": 14.0
            }
          },
          "child": new Column({
            "children": [
              new _DevRow({
                "icon": "widgets_outlined",
                "title": "组件案例",
                "subtitle": "常用组件 原生 ↔ JS 同屏对比",
                "onTap": () => { return _app_host_.invoke("openWidgetShowcase", []); }
              }),
              (this.__k5 || (this.__k5 = new Divider({
                "color": new Color({value: 0xFFF0F2F6}),
                "height": 1,
                "indent": 56
              }))),
              new _DevRow({
                "icon": "compare_arrows",
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
      "behavior": "opaque",
      "child": new Padding({
        "padding": {
          "left": 14.0,
          "top": 12.0,
          "right": 12.0,
          "bottom": 12.0
        },
        "child": new Row({
          "children": [
            new Container({
              "width": 30,
              "height": 30,
              "alignment": "center",
              "decoration": {
                "color": new Color({value: 0xFFE8F2FF}),
                "borderRadius": {
                  "radius": 9.0
                }
              },
              "child": new Icon({
                "size": 16,
                "color": kBrand,
                "icon": this.icon
              })
            }),
            (this.__k0 || (this.__k0 = new SizedBox({
              "width": 12
            }))),
            new Expanded({
              "child": new Column({
                "crossAxisAlignment": "start",
                "children": [
                  new Text({
                    "style": {
                      "fontSize": 14
                    },
                    "data": this.title
                  }),
                  (this.__k1 || (this.__k1 = new SizedBox({
                    "height": 3
                  }))),
                  new Text({
                    "maxLines": 1,
                    "overflow": "ellipsis",
                    "style": {
                      "fontSize": 11,
                      "color": new Color({value: 0xFF98A0AC})
                    },
                    "data": this.subtitle
                  })
                ]
              })
            }),
            (this.__k2 || (this.__k2 = new Icon({
              "color": new Color({value: 0xFFC3C8D2}),
              "icon": "chevron_right",
              "size": 18
            })))
          ]
        })
      })
    });
  }
}

