// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/app/pages/mine_page.dart 自动生成
// 重新生成：dart run build_runner build

import { AppService } from '../service/app_service.js';
import { MineFeed } from '../model/app_models.js';
import { kBrand, kPrice } from 'detail_pages.js';
import { Center, CircularProgressIndicator, ClipOval, Column, Container, Divider, Expanded, GestureDetector, Icon, Image, Padding, Row, SafeArea, SizedBox, Text, Transform, __h } from '../../flutter.js';

const _menuTints = ['#ffe8f2ff', '#fffff3e0', '#ffeef0f4', '#ffe9f7ef'];

// 组件 MinePage
export class MinePage {
  constructor(args) {
    this.props = args || {};
    this._service = new AppService({});
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
      return new Center({
          "child": new CircularProgressIndicator({})
        });
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
                    '#ff1e88ff',
                    '#ff0e7afb'
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
                                "child": new Image({
                                    "width": 58,
                                    "height": 58,
                                    "fit": "cover",
                                    "errorBuilder": "_errorBuilder0",
                                    "factory": "network",
                                    "src": this._feed.avatar
                                  })
                              }),
                            new SizedBox({
                                "width": 13
                              }),
                            new Expanded({
                                "child": new Column({
                                    "crossAxisAlignment": "start",
                                    "children": [
                                      new Text({
                                          "style": {
                                            "fontSize": 17.5,
                                            "fontWeight": "w700",
                                            "color": '#FFFFFF'
                                          },
                                          "data": "旅行家小七"
                                        }),
                                      new SizedBox({
                                          "height": 4
                                        }),
                                      new Text({
                                          "style": {
                                            "fontSize": 12,
                                            "color": '#ccffffff'
                                          },
                                          "data": "138****8888"
                                        }),
                                      new SizedBox({
                                          "height": 6
                                        }),
                                      new Text({
                                          "style": {
                                            "fontSize": 11,
                                            "color": '#b3ffffff'
                                          },
                                          "data": "点击头像可跳转登录页 ›"
                                        })
                                    ]
                                  })
                              }),
                            new Icon({
                                "color": '#ccffffff',
                                "size": 20,
                                "icon": "chevron_right"
                              })
                          ]
                        })
                    })
                })
            }),
          new Transform({
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
                    "color": '#FFFFFF',
                    "borderRadius": {
                      "radius": 14.0
                    }
                  },
                  "child": new Row({
                      "children": [
                        ...(() => { var out = []; for (let s of this._feed.stats) { out.push.apply(out, [new Expanded({ "child": new GestureDetector({ "onTap": this.__bindFn(1, [], () => _app_host_.invoke("openOrders", [])), "child": new Column({ "children": [ new Text({ "style": { "fontSize": 17, "fontWeight": "w700", "color": '#ff171a21' }, "data": s[1] }), new SizedBox({ "height": 3 }), new Text({ "style": { "fontSize": 11.5, "color": '#ff8b909a' }, "data": s[0] }) ] }) }) })]); } return out; })()
                      ]
                    })
                }),
              "factory": "translate"
            }),
          new Container({
              "margin": {
                "left": 12.0,
                "top": 0.0,
                "right": 12.0,
                "bottom": 12.0
              },
              "decoration": {
                "color": '#FFFFFF',
                "borderRadius": {
                  "radius": 14.0
                }
              },
              "child": new Column({
                  "children": [
                    ...(() => { var out = []; for (let i = 0; (i < this._feed.menu.length); (i++)) { out.push.apply(out, [...((i > 0) ? [new Divider({ "height": 1, "indent": 56, "color": '#fff0f2f6' })] : []), new GestureDetector({ "onTap": this.__bindFn(2, [i], () => this._openMenu(this._feed.menu[i])), "child": new Padding({ "padding": { "left": 14.0, "top": 12.0, "right": 12.0, "bottom": 12.0 }, "child": new Row({ "children": [ new Container({ "width": 30, "height": 30, "alignment": "center", "decoration": { "color": _menuTints[(i % _menuTints.length)], "borderRadius": { "radius": 9.0 } }, "child": new Text({ "style": { "fontSize": 15 }, "data": this._feed.menu[i].emoji }) }), new SizedBox({ "width": 12 }), new Expanded({ "child": new Text({ "style": { "fontSize": 14 }, "data": this._feed.menu[i].title }) }), new Icon({ "size": 18, "color": '#ffc3c8d2', "icon": "chevron_right" }) ] }) }) })]); } return out; })()
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
                        "color": '#FFFFFF',
                        "borderRadius": {
                          "radius": 14.0
                        }
                      },
                      "child": new Text({
                          "style": {
                            "fontSize": 14,
                            "fontWeight": "w600",
                            "color": kPrice
                          },
                          "data": "退出登录"
                        })
                    })
                })
            }),
          new Padding({
              "padding": {
                "left": 18.0,
                "top": 4.0,
                "right": 18.0,
                "bottom": 8.0
              },
              "child": new Text({
                  "style": {
                    "fontSize": 12.5,
                    "fontWeight": "w700",
                    "color": '#ff98a0ac'
                  },
                  "data": "开发者"
                })
            }),
          new Container({
              "margin": {
                "left": 12.0,
                "top": 0.0,
                "right": 12.0,
                "bottom": 24.0
              },
              "decoration": {
                "color": '#FFFFFF',
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
                    new Divider({
                        "height": 1,
                        "indent": 56,
                        "color": '#fff0f2f6'
                      }),
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
  _errorBuilder0(context, e) {
      return new Container({
        "width": 58,
        "height": 58,
        "color": '#33ffffff'
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
                        "color": '#ffe8f2ff',
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
                  new SizedBox({
                      "width": 12
                    }),
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
                            new SizedBox({
                                "height": 3
                              }),
                            new Text({
                                "maxLines": 1,
                                "overflow": "ellipsis",
                                "style": {
                                  "fontSize": 11,
                                  "color": '#ff98a0ac'
                                },
                                "data": this.subtitle
                              })
                          ]
                        })
                    }),
                  new Icon({
                      "size": 18,
                      "color": '#ffc3c8d2',
                      "icon": "chevron_right"
                    })
                ]
              })
          })
      });
  }
}

