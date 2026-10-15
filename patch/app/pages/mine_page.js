// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/app/pages/mine_page.dart 自动生成
// 重新生成：dart run build_runner build

import { AppService } from '../service/app_service.js';
import { MineFeed } from '../model/app_models.js';
import { kBrand, kPrice } from 'detail_pages.js';
import { __h } from '../../flutter.js';

const _menuTints = ['#ffe8f2ff', '#fffff3e0', '#ffeef0f4', '#ffe9f7ef'];

// 组件 MinePage
export class MinePage {
  constructor() {
    this._service = new AppService({});
    this._feed = null;
  }
  initState() {
    this._load();
  }
  async _load() {
    var feed = await this._service.fetchMine();
    this.setState(function(){ this._feed = feed; });
  }
  _openMenu(m) {
    if ((m.screen == "orders")) {
      _app_host_.invoke("openOrders", []);
    } else {
      if ((m.screen == "showcase")) {
        _app_host_.invoke("openWidgetShowcase", []);
      } else {
        _app_host_.invoke("open", ["https://flutter.dev", ((m.arg.length === 0) ? m.title : m.arg)]);
      }
    }
  }
  build(context) {
    var feed = this._feed;
    if ((feed == null)) {
      return __h('Center', {}, [
          __h('CircularProgressIndicator', {})
        ]);
    }
    return __h('ListView', {}, [
        __h('Container', {
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
            }
          }, [
            __h('SafeArea', {
                "bottom": false
              }, [
                __h('GestureDetector', {
                    "event": this.__bind("_app_host_.invoke(\"openLogin\", [])")
                  }, [
                    __h('Row', {}, [
                        __h('ClipOval', {
                            "child": __h('Image', {
                                "source": this._feed.avatar,
                                "width": 58,
                                "height": 58,
                                "fit": "cover"
                              })
                          }),
                        __h('SizedBox', {
                            "width": 13
                          }),
                        __h('Expanded', {}, [
                            __h('Column', {
                                "crossAxisAlignment": "start"
                              }, [
                                __h('Text', {
                                    "data": "旅行家小七",
                                    "style": {
                                      "fontSize": 17.5,
                                      "fontWeight": "w700",
                                      "color": '#FFFFFF'
                                    }
                                  }),
                                __h('SizedBox', {
                                    "height": 4
                                  }),
                                __h('Text', {
                                    "data": "138****8888",
                                    "style": {
                                      "fontSize": 12,
                                      "color": '#ccffffff'
                                    }
                                  }),
                                __h('SizedBox', {
                                    "height": 6
                                  }),
                                __h('Text', {
                                    "data": "点击头像可跳转登录页 ›",
                                    "style": {
                                      "fontSize": 11,
                                      "color": '#b3ffffff'
                                    }
                                  })
                              ])
                          ]),
                        __h('Icon', {
                            "icon": "chevron_right",
                            "size": 20,
                            "color": '#ccffffff'
                          })
                      ])
                  ])
              ])
          ]),
        __h('Transform', {
            "offset": { "dx": 0, "dy": (-12) },
            "child": __h('Container', {
                "padding": {
                  "left": 0.0,
                  "top": 14.0,
                  "right": 0.0,
                  "bottom": 14.0
                },
                "margin": {
                  "left": 12.0,
                  "top": 0.0,
                  "right": 12.0,
                  "bottom": 0.0
                },
                "decoration": {
                  "color": '#FFFFFF',
                  "borderRadius": {
                    "radius": 14.0
                  }
                }
              }, [
                __h('Row', {}, [
                    ...(() => { var out = []; for (let s of this._feed.stats) { out.push.apply(out, [__h('Expanded', {}, [ __h('GestureDetector', { "event": this.__bindFn("() => AppRouter.openOrders()" + ":" + String(s), () => { _app_host_.invoke("openOrders", []); }) }, [ __h('Column', {}, [ __h('Text', { "data": s[1], "style": { "fontSize": 17, "fontWeight": "w700", "color": '#ff171a21' } }), __h('SizedBox', { "height": 3 }), __h('Text', { "data": s[0], "style": { "fontSize": 11.5, "color": '#ff8b909a' } }) ]) ]) ])]); } return out; })()
                  ])
              ])
          }),
        __h('Container', {
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
            }
          }, [
            __h('Column', {}, [
                ...(() => { var out = []; for (let i = 0; (i < this._feed.menu.length); (i++)) { out.push.apply(out, [...((i > 0) ? [__h('Divider', { "height": 1, "indent": 56, "color": '#fff0f2f6' })] : []), __h('GestureDetector', { "event": this.__bindFn("() => _openMenu(feed.menu[i])" + ":" + String(i), () => { this._openMenu(this._feed.menu[i]); }) }, [ __h('Padding', { "padding": { "left": 14.0, "top": 12.0, "right": 12.0, "bottom": 12.0 } }, [ __h('Row', {}, [ __h('Container', { "width": 30, "height": 30, "alignment": "center", "decoration": { "color": _menuTints[(i % _menuTints.length)], "borderRadius": { "radius": 9.0 } } }, [ __h('Text', { "data": this._feed.menu[i].emoji, "style": { "fontSize": 15 } }) ]), __h('SizedBox', { "width": 12 }), __h('Expanded', {}, [ __h('Text', { "data": this._feed.menu[i].title, "style": { "fontSize": 14 } }) ]), __h('Icon', { "icon": "chevron_right", "size": 18, "color": '#ffc3c8d2' }) ]) ]) ])]); } return out; })()
              ])
          ]),
        __h('Padding', {
            "padding": {
              "left": 12.0,
              "top": 0.0,
              "right": 12.0,
              "bottom": 20.0
            }
          }, [
            __h('GestureDetector', {
                "event": this.__bind("_app_host_.invoke(\"toast\", [\"已退出登录（演示）\"])")
              }, [
                __h('Container', {
                    "height": 46,
                    "alignment": "center",
                    "decoration": {
                      "color": '#FFFFFF',
                      "borderRadius": {
                        "radius": 14.0
                      }
                    }
                  }, [
                    __h('Text', {
                        "data": "退出登录",
                        "style": {
                          "fontSize": 14,
                          "fontWeight": "w600",
                          "color": kPrice
                        }
                      })
                  ])
              ])
          ]),
        __h('Padding', {
            "padding": {
              "left": 18.0,
              "top": 4.0,
              "right": 18.0,
              "bottom": 8.0
            }
          }, [
            __h('Text', {
                "data": "开发者",
                "style": {
                  "fontSize": 12.5,
                  "fontWeight": "w700",
                  "color": '#ff98a0ac'
                }
              })
          ]),
        __h('Container', {
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
            }
          }, [
            __h('Column', {}, [
                __h(_DevRow, {
                    "icon": "widgets_outlined",
                    "title": "组件案例",
                    "subtitle": "常用组件 原生 ↔ JS 同屏对比",
                    "onTap": () => { return _app_host_.invoke("openWidgetShowcase", []); }
                  }),
                __h('Divider', {
                    "height": 1,
                    "indent": 56,
                    "color": '#fff0f2f6'
                  }),
                __h(_DevRow, {
                    "icon": "compare_arrows",
                    "title": "热更 Demo 列表",
                    "subtitle": "HelloCard / ProviderCard / WatchDemo 等对比",
                    "onTap": () => { return _app_host_.invoke("openDemoList", []); }
                  })
              ])
          ])
      ]);
  }
}

// 组件 _DevRow
export class _DevRow {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.icon = (args && args.icon !== undefined) ? args.icon : null;
    this.title = (args && args.title !== undefined) ? args.title : '';
    this.subtitle = (args && args.subtitle !== undefined) ? args.subtitle : '';
    this.onTap = (args && args.onTap !== undefined) ? args.onTap : null;
  }
  build(context) {
    return __h('GestureDetector', {
        "event": this.__bind("this.onTap()"),
        "behavior": "opaque"
      }, [
        __h('Padding', {
            "padding": {
              "left": 14.0,
              "top": 12.0,
              "right": 12.0,
              "bottom": 12.0
            }
          }, [
            __h('Row', {}, [
                __h('Container', {
                    "width": 30,
                    "height": 30,
                    "alignment": "center",
                    "decoration": {
                      "color": '#ffe8f2ff',
                      "borderRadius": {
                        "radius": 9.0
                      }
                    }
                  }, [
                    __h('Icon', {
                        "icon": this.icon,
                        "size": 16,
                        "color": kBrand
                      })
                  ]),
                __h('SizedBox', {
                    "width": 12
                  }),
                __h('Expanded', {}, [
                    __h('Column', {
                        "crossAxisAlignment": "start"
                      }, [
                        __h('Text', {
                            "data": this.title,
                            "style": {
                              "fontSize": 14
                            }
                          }),
                        __h('SizedBox', {
                            "height": 3
                          }),
                        __h('Text', {
                            "data": this.subtitle,
                            "style": {
                              "fontSize": 11,
                              "color": '#ff98a0ac'
                            },
                            "maxLines": 1,
                            "overflow": "ellipsis"
                          })
                      ])
                  ]),
                __h('Icon', {
                    "icon": "chevron_right",
                    "size": 18,
                    "color": '#ffc3c8d2'
                  })
              ])
          ])
      ]);
  }
}

