// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/app/pages/detail_pages.dart 自动生成
// 重新生成：dart run build_runner build

import { Spot } from '../model/app_models.js';
import { Post } from '../model/app_models.js';
import { Resource } from '../model/app_models.js';
import { Order } from '../model/app_models.js';
import { kAvatarImg, kBanners, kHotSearch, kPosts, kSpots } from '../model/app_data.js';
import { __h } from '../../flutter.js';

export const kBrand = '#ff0e7afb';
export const kPrice = '#ffff5a36';
const _steps = ["提交订单", "支付成功", "商家发货", "已完成"];

// 组件 MiniButton
export class MiniButton {
  constructor(args) {
    this.label = (args && args.label !== undefined) ? args.label : '';
    this.primary = (args && args.primary !== undefined) ? args.primary : false;
    this.onTap = (args && args.onTap !== undefined) ? args.onTap : null;
  }
  build() {
    return __h('GestureDetector', {
        "event": this.__bind("this.onTap()")
      }, [
        __h('Container', {
            "height": 32,
            "padding": {
              "left": 14.0,
              "top": 0.0,
              "right": 14.0,
              "bottom": 0.0
            },
            "alignment": "center",
            "decoration": {
              "color": (this.primary ? kBrand : '#FFFFFF'),
              "borderRadius": {
                "radius": 14.0
              },
              "border": {
                "all": {
                  "color": (this.primary ? kBrand : '#ffdfe4ec')
                }
              }
            }
          }, [
            __h('Text', {
                "data": this.label,
                "style": {
                  "fontSize": 12,
                  "color": (this.primary ? '#FFFFFF' : '#ff4d5462')
                }
              })
          ])
      ]);
  }
}

// 组件 SearchPage
export class SearchPage {
  constructor() {
    this._controller = new TextEditingController();
  }
  dispose() {
    this._controller.dispose();
  }
  _go(kw) {
    __jsui.host("toast", ["搜索：" + ((kw.length === 0) ? "全部" : kw)]);
  }
  build() {
    var guesses = [...kSpots].reverse();
    return __h('Scaffold', {
        "body": __h('Column', {}, [
            __h('Container', {
                "color": '#FFFFFF'
              }, [
                __h(_TopBar, {
                    "title": "",
                    "trailing": __h('GestureDetector', {
                        "event": this.__bind("this._go(this._controller.text)")
                      }, [
                        __h('Text', {
                            "data": "搜索",
                            "style": {
                              "fontSize": 13.5,
                              "color": kBrand,
                              "fontWeight": "w600"
                            }
                          })
                      ])
                  })
              ]),
            __h('Container', {
                "margin": {
                  "left": 14.0,
                  "top": 0.0,
                  "right": 14.0,
                  "bottom": 12.0
                }
              }, [
                __h('TextField', {
                    "onSubmitted": this.__bind("_go"),
                    "controller": this._controller,
                    "hintText": "搜索景点 / 目的地 / 攻略"
                  })
              ]),
            __h('Expanded', {}, [
                __h('ListView', {
                    "padding": {
                      "left": 0.0,
                      "top": 0.0,
                      "right": 0.0,
                      "bottom": 24.0
                    }
                  }, [
                    __h(_Block, {
                        "child": __h('Column', {
                            "crossAxisAlignment": "start"
                          }, [
                            __h(_BlockTitle, {}),
                            __h('Wrap', {
                                "spacing": 8,
                                "runSpacing": 8
                              }, [
                                ...(() => { var out = []; for (let k of kHotSearch) { out.push.apply(out, [__h('GestureDetector', { "event": this.__bindFn("() => _go(k)" + ":" + String(k), () => { this._go(k); }) }, [ __h('Container', { "padding": { "left": 13.0, "top": 6.0, "right": 13.0, "bottom": 6.0 }, "decoration": { "color": '#fff3f5f8', "borderRadius": { "radius": 14.0 } } }, [ __h('Text', { "data": k, "style": { "fontSize": 12.5, "color": '#ff4d5462' } }) ]) ])]); } return out; })()
                              ])
                          ])
                      }),
                    __h('Padding', {
                        "padding": {
                          "left": 16.0,
                          "top": 6.0,
                          "right": 16.0,
                          "bottom": 10.0
                        }
                      }, [
                        __h('Text', {
                            "data": "猜你想去",
                            "style": {
                              "fontSize": 17,
                              "fontWeight": "w700"
                            }
                          })
                      ]),
                    ...(() => { var out = []; for (let s of guesses) { out.push.apply(out, [__h('Padding', { "padding": { "left": 12.0, "top": 0.0, "right": 12.0, "bottom": 10.0 } }, [ __h('GestureDetector', { "event": this.__bindFn("() => AppRouter.openSpot(s.id)" + ":" + String(s), () => { __jsui.host("openSpot", [s.id]); }) }, [ __h(PostRow, { "img": s.img, "title": s.title, "sub": s.sub, "trailing": "￥" + s.price + " 起" }) ]) ])]); } return out; })()
                  ])
              ])
          ]),
        "backgroundColor": '#fff3f5f8'
      });
  }
}

// 组件 PostRow
export class PostRow {
  constructor(args) {
    this.img = (args && args.img !== undefined) ? args.img : '';
    this.title = (args && args.title !== undefined) ? args.title : '';
    this.sub = (args && args.sub !== undefined) ? args.sub : '';
    this.trailing = (args && args.trailing !== undefined) ? args.trailing : '';
    this.footNote = (args && args.footNote !== undefined) ? args.footNote : '';
  }
  build() {
    return __h('Container', {
        "padding": {
          "left": 10.0,
          "top": 10.0,
          "right": 10.0,
          "bottom": 10.0
        },
        "decoration": {
          "color": '#FFFFFF',
          "borderRadius": {
            "radius": 14.0
          }
        }
      }, [
        __h('Row', {
            "crossAxisAlignment": "start"
          }, [
            __h('ClipRRect', {
                "child": __h('Image', {
                    "source": this.img,
                    "width": 86,
                    "height": 86,
                    "fit": "cover"
                  })
              }),
            __h('SizedBox', {
                "width": 11
              }),
            __h('Expanded', {}, [
                __h('Column', {
                    "crossAxisAlignment": "start"
                  }, [
                    __h('Text', {
                        "data": this.title,
                        "style": {
                          "fontSize": 14,
                          "fontWeight": "w600"
                        },
                        "maxLines": 1,
                        "overflow": "ellipsis"
                      }),
                    __h('SizedBox', {
                        "height": 5
                      }),
                    __h('Text', {
                        "data": this.sub,
                        "style": {
                          "fontSize": 11.5,
                          "color": '#ff8b909a',
                          "height": 1.5
                        },
                        "maxLines": 2,
                        "overflow": "ellipsis"
                      }),
                    ...((this.trailing != null) ? [__h('Padding', { "padding": { "left": 0.0, "top": 8.0, "right": 0.0, "bottom": 0.0 } }, [ __h('Text', { "data": this.trailing, "style": { "fontSize": 13, "color": kPrice, "fontWeight": "w700" } }) ])] : []),
                    ...((this.footNote != null) ? [__h('Padding', { "padding": { "left": 0.0, "top": 6.0, "right": 0.0, "bottom": 0.0 } }, [ __h('Text', { "data": this.footNote, "style": { "fontSize": 11, "color": '#ffa3a9b4' } }) ])] : [])
                  ])
              ])
          ])
      ]);
  }
}

// 组件 SpotDetailPage
export class SpotDetailPage {
  constructor(args) {
    this.spot = (args && args.spot !== undefined) ? args.spot : null;
  }
  build() {
    return __h('Scaffold', {
        "body": __h('Column', {}, [
            __h('Expanded', {}, [
                __h('ListView', {}, [
                    __h('SizedBox', {
                        "height": 230
                      }, [
                        __h('Stack', {
                            "fit": "expand"
                          }, [
                            __h('Image', {
                                "source": this.spot.img,
                                "fit": "cover"
                              }),
                            __h('DecoratedBox', {
                                "decoration": {
                                  "gradient": {
                                    "kind": "linear",
                                    "begin": "topCenter",
                                    "end": "bottomCenter",
                                    "colors": [
                                      '#00000000',
                                      '#99000000'
                                    ]
                                  }
                                }
                              }),
                            __h('Positioned', {
                                "left": 14,
                                "top": 44
                              }, [
                                __h('GestureDetector', {
                                    "event": this.__bind("__jsui.host(\"pop\", [])")
                                  }, [
                                    __h('Container', {
                                        "width": 34,
                                        "height": 34,
                                        "decoration": {
                                          "color": '#e6ffffff',
                                          "shape": "circle"
                                        }
                                      }, [
                                        __h('Icon', {
                                            "icon": "arrow_back_ios_new",
                                            "size": 15,
                                            "color": '#ff171a21'
                                          })
                                      ])
                                  ])
                              ]),
                            __h('Positioned', {
                                "left": 16,
                                "right": 16,
                                "bottom": 16
                              }, [
                                __h('Column', {
                                    "crossAxisAlignment": "start"
                                  }, [
                                    __h('Text', {
                                        "data": this.spot.title,
                                        "style": {
                                          "fontSize": 21,
                                          "fontWeight": "w700",
                                          "color": '#FFFFFF'
                                        }
                                      }),
                                    __h('SizedBox', {
                                        "height": 6
                                      }),
                                    __h('Text', {
                                        "data": this.spot.sub,
                                        "style": {
                                          "fontSize": 12.5,
                                          "color": '#e6ffffff'
                                        }
                                      })
                                  ])
                              ])
                          ])
                      ]),
                    __h('SizedBox', {
                        "height": 12
                      }),
                    __h(_Block, {
                        "child": __h('Column', {
                            "crossAxisAlignment": "start"
                          }, [
                            __h(_BlockTitle, {}),
                            __h('Wrap', {
                                "spacing": 7,
                                "runSpacing": 7
                              }, [
                                ...(() => { var out = []; for (let t of this.spot.tags) { out.push.apply(out, [__h('Container', { "padding": { "left": 9.0, "top": 3.0, "right": 9.0, "bottom": 3.0 }, "decoration": { "color": '#ffeaf3ff', "borderRadius": { "radius": 8.0 } } }, [ __h('Text', { "data": t, "style": { "fontSize": 11.5, "color": kBrand } }) ])]); } return out; })()
                              ]),
                            __h('SizedBox', {
                                "height": 12
                              }),
                            __h('Text', {
                                "data": this.spot.desc,
                                "style": {
                                  "fontSize": 13,
                                  "height": 1.85,
                                  "color": '#ff4d5462'
                                }
                              })
                          ])
                      }),
                    __h(_Block, {
                        "child": __h('Column', {
                            "crossAxisAlignment": "start"
                          }, [
                            __h(_BlockTitle, {}),
                            __h(_Kv, {
                                "label": "成人价",
                                "value": "￥" + this.spot.price + " / 人",
                                "highlight": true
                              }),
                            __h(_Kv, {
                                "label": "已售",
                                "value": this.spot.sold
                              }),
                            __h(_Kv, {
                                "label": "退改政策",
                                "value": "出行前 24 小时免费退"
                              })
                          ])
                      }),
                    __h(_Block, {
                        "child": __h('Column', {
                            "crossAxisAlignment": "start"
                          }, [
                            __h(_BlockTitle, {}),
                            __h('Text', {
                                "data": "“海岛的水真的很蓝，浮潜看到了很多鱼，酒店离沙滩走路两分钟，值。” —— 旅行家小七",
                                "style": {
                                  "fontSize": 13,
                                  "height": 1.85,
                                  "color": '#ff4d5462'
                                }
                              })
                          ])
                      })
                  ])
              ]),
            __h(_BottomBar, {
                "children": [
                  __h('Text', {
                      "data": "￥" + this.spot.price,
                      "style": {
                        "fontSize": 22,
                        "color": kPrice,
                        "fontWeight": "w700"
                      }
                    }),
                  __h('SizedBox', {
                      "width": 6
                    }),
                  __h('Text', {
                      "data": "起",
                      "style": {
                        "fontSize": 13,
                        "color": '#ff5c6270'
                      }
                    }),
                  __h('SizedBox', {
                      "width": 12
                    }),
                  __h('Expanded', {}, [
                      __h('Button', {
                          "kind": "elevated",
                          "label": "立即预订",
                          "event": this.__bind("__jsui.host(\"toast\", [\"已提交预订（演示）\"])"),
                          "style": {
                            "backgroundColor": kBrand,
                            "foregroundColor": '#FFFFFF',
                            "shape": {
                              "kind": "rounded",
                              "borderRadius": {
                                "radius": 22.0
                              }
                            }
                          }
                        })
                    ])
                ]
              })
          ]),
        "backgroundColor": '#fff3f5f8'
      });
  }
}

// 组件 PostDetailPage
export class PostDetailPage {
  constructor(args) {
    this.post = (args && args.post !== undefined) ? args.post : null;
  }
  build() {
    return __h('Scaffold', {
        "body": __h('Column', {}, [
            __h('Expanded', {}, [
                __h('ListView', {}, [
                    __h('SizedBox', {
                        "height": 180
                      }, [
                        __h('Stack', {
                            "fit": "expand"
                          }, [
                            __h('Image', {
                                "source": this.post.img,
                                "fit": "cover"
                              }),
                            __h('DecoratedBox', {
                                "decoration": {
                                  "gradient": {
                                    "kind": "linear",
                                    "begin": "topCenter",
                                    "end": "bottomCenter",
                                    "colors": [
                                      '#00000000',
                                      '#99000000'
                                    ]
                                  }
                                }
                              }),
                            __h('Positioned', {
                                "left": 14,
                                "top": 44
                              }, [
                                __h('GestureDetector', {
                                    "event": this.__bind("__jsui.host(\"pop\", [])")
                                  }, [
                                    __h('Container', {
                                        "width": 34,
                                        "height": 34,
                                        "decoration": {
                                          "color": '#e6ffffff',
                                          "shape": "circle"
                                        }
                                      }, [
                                        __h('Icon', {
                                            "icon": "arrow_back_ios_new",
                                            "size": 15,
                                            "color": '#ff171a21'
                                          })
                                      ])
                                  ])
                              ]),
                            __h('Positioned', {
                                "left": 16,
                                "right": 16,
                                "bottom": 16
                              }, [
                                __h('Text', {
                                    "data": this.post.title,
                                    "style": {
                                      "fontSize": 19,
                                      "fontWeight": "w700",
                                      "color": '#FFFFFF'
                                    }
                                  })
                              ])
                          ])
                      ]),
                    __h('Container', {
                        "color": '#FFFFFF',
                        "padding": {
                          "left": 16.0,
                          "top": 16.0,
                          "right": 16.0,
                          "bottom": 16.0
                        }
                      }, [
                        __h('Row', {}, [
                            __h('CircleAvatar', {
                                "radius": 19,
                                "backgroundImage": kAvatarImg
                              }),
                            __h('SizedBox', {
                                "width": 10
                              }),
                            __h('Expanded', {}, [
                                __h('Column', {
                                    "crossAxisAlignment": "start"
                                  }, [
                                    __h('Text', {
                                        "data": this.post.author,
                                        "style": {
                                          "fontSize": 14,
                                          "fontWeight": "w600"
                                        }
                                      }),
                                    __h('SizedBox', {
                                        "height": 2
                                      }),
                                    __h('Text', {
                                        "data": this.post.time + " · " + this.post.type,
                                        "style": {
                                          "fontSize": 11,
                                          "color": '#ff8b909a'
                                        }
                                      })
                                  ])
                              ]),
                            __h('GestureDetector', {
                                "event": this.__bind("__jsui.host(\"toast\", [\"已关注 \" + this.post.author])")
                              }, [
                                __h('Container', {
                                    "padding": {
                                      "left": 16.0,
                                      "top": 6.0,
                                      "right": 16.0,
                                      "bottom": 6.0
                                    },
                                    "decoration": {
                                      "color": kBrand,
                                      "borderRadius": {
                                        "radius": 14.0
                                      }
                                    }
                                  }, [
                                    __h('Text', {
                                        "data": "关注",
                                        "style": {
                                          "fontSize": 12.5,
                                          "color": '#FFFFFF'
                                        }
                                      })
                                  ])
                              ])
                          ])
                      ]),
                    __h('SizedBox', {
                        "height": 12
                      }),
                    __h(_Block, {
                        "child": __h('Column', {
                            "crossAxisAlignment": "start"
                          }, [
                            __h('Text', {
                                "data": this.post.sub,
                                "style": {
                                  "fontSize": 13.5,
                                  "height": 1.9,
                                  "color": '#ff4d5462'
                                }
                              }),
                            __h('SizedBox', {
                                "height": 12
                              }),
                            __h('Text', {
                                "data": "这次出行一共 3 天，人均花费不到 800。第一天上午出发，中午到营地搭好帐篷，下午沿着湖边走了差不多 6 公里，傍晚的日落是全程最值得的部分。",
                                "style": {
                                  "fontSize": 13.5,
                                  "height": 1.9,
                                  "color": '#ff4d5462'
                                }
                              }),
                            __h('SizedBox', {
                                "height": 12
                              }),
                            __h('Text', {
                                "data": "装备方面，帐篷和防潮垫是必须的，夜里温度会降到 10 度以下，建议带一件抓绒。营地有热水和厕所，但没有便利店，食物要提前备好。",
                                "style": {
                                  "fontSize": 13.5,
                                  "height": 1.9,
                                  "color": '#ff4d5462'
                                }
                              })
                          ])
                      })
                  ])
              ]),
            __h(_BottomBar, {
                "children": [
                  __h('Expanded', {}, [
                      __h(MiniButton, {
                          "label": "♡ 点赞 · " + ((this.post.like > 999) ? ((this.post.like / 1000)).toFixed(1) + "k" : this.post.like),
                          "onTap": () => { return __jsui.host("toast", ["已点赞"]); }
                        })
                    ]),
                  __h('SizedBox', {
                      "width": 10
                    }),
                  __h('Expanded', {}, [
                      __h(MiniButton, {
                          "label": "收藏",
                          "primary": true,
                          "onTap": () => { return __jsui.host("toast", ["已收藏"]); }
                        })
                    ])
                ]
              })
          ]),
        "backgroundColor": '#fff3f5f8'
      });
  }
}

// 组件 ResourceDetailPage
export class ResourceDetailPage {
  constructor(args) {
    this.resource = (args && args.resource !== undefined) ? args.resource : null;
  }
  build() {
    var items = kPosts.take(3);
    return __h('Scaffold', {
        "body": __h('Column', {}, [
            __h('Container', {
                "color": '#FFFFFF'
              }, [
                __h(_TopBar, {
                    "title": this.resource.title
                  })
              ]),
            __h('Expanded', {}, [
                __h('ListView', {
                    "padding": {
                      "left": 0.0,
                      "top": 0.0,
                      "right": 0.0,
                      "bottom": 24.0
                    }
                  }, [
                    __h('SizedBox', {
                        "height": 150
                      }, [
                        __h('Stack', {
                            "fit": "expand"
                          }, [
                            __h('Image', {
                                "source": this.resource.img,
                                "fit": "cover"
                              }),
                            __h('DecoratedBox', {
                                "decoration": {
                                  "gradient": {
                                    "kind": "linear",
                                    "begin": "topCenter",
                                    "end": "bottomCenter",
                                    "colors": [
                                      '#00000000',
                                      '#99000000'
                                    ]
                                  }
                                }
                              }),
                            __h('Positioned', {
                                "left": 16,
                                "right": 16,
                                "bottom": 14
                              }, [
                                __h('Column', {
                                    "crossAxisAlignment": "start"
                                  }, [
                                    __h('Text', {
                                        "data": this.resource.title,
                                        "style": {
                                          "fontSize": 18,
                                          "fontWeight": "w700",
                                          "color": '#FFFFFF'
                                        }
                                      }),
                                    __h('SizedBox', {
                                        "height": 4
                                      }),
                                    __h('Text', {
                                        "data": this.resource.sub,
                                        "style": {
                                          "fontSize": 12,
                                          "color": '#e6ffffff'
                                        }
                                      })
                                  ])
                              ])
                          ])
                      ]),
                    __h('Padding', {
                        "padding": {
                          "left": 16.0,
                          "top": 18.0,
                          "right": 16.0,
                          "bottom": 10.0
                        }
                      }, [
                        __h('Text', {
                            "data": "相关推荐",
                            "style": {
                              "fontSize": 15,
                              "fontWeight": "w700"
                            }
                          })
                      ]),
                    ...(() => { var out = []; for (let p of items) { out.push.apply(out, [__h('Padding', { "padding": { "left": 12.0, "top": 0.0, "right": 12.0, "bottom": 10.0 } }, [ __h('GestureDetector', { "event": this.__bindFn("() => AppRouter.openPost(p.id)" + ":" + String(p), () => { __jsui.host("openPost", [p.id]); }) }, [ __h(PostRow, { "img": p.img, "title": p.title, "sub": p.sub, "footNote": p.author + " · " + p.time }) ]) ])]); } return out; })()
                  ])
              ])
          ]),
        "backgroundColor": '#fff3f5f8'
      });
  }
}

// 组件 OrderDetailPage
export class OrderDetailPage {
  constructor(args) {
    this.order = (args && args.order !== undefined) ? args.order : null;
  }
  build() {
    return __h('Scaffold', {
        "body": __h('Column', {}, [
            __h('Container', {
                "color": '#FFFFFF'
              }, [
                __h(_TopBar, {
                    "title": "订单详情"
                  })
              ]),
            __h('Expanded', {}, [
                __h('ListView', {
                    "padding": {
                      "left": 0.0,
                      "top": 12.0,
                      "right": 0.0,
                      "bottom": 24.0
                    }
                  }, [
                    __h(_Block, {
                        "child": __h('Column', {
                            "crossAxisAlignment": "start"
                          }, [
                            __h(_BlockTitle, {}),
                            ...(() => { var out = []; for (let i = 0; (i < _steps.length); (i++)) { out.push.apply(out, [__h('Padding', { "padding": { "left": 0.0, "top": 5.0, "right": 0.0, "bottom": 5.0 } }, [ __h('Row', {}, [ __h('Container', { "width": 8, "height": 8, "decoration": { "color": ((i <= this.order.step) ? kBrand : '#ffdfe4ec'), "shape": "circle" } }), __h('SizedBox', { "width": 10 }), __h('Text', { "data": _steps[i], "style": { "fontSize": 12.5, "color": ((i <= this.order.step) ? '#ff171a21' : '#ff8b909a') } }) ]) ])]); } return out; })()
                          ])
                      }),
                    __h(_Block, {
                        "child": __h('Column', {
                            "crossAxisAlignment": "start"
                          }, [
                            __h(_BlockTitle, {}),
                            __h('Row', {
                                "crossAxisAlignment": "start"
                              }, [
                                __h('ClipRRect', {
                                    "child": __h('Image', {
                                        "source": this.order.img,
                                        "width": 62,
                                        "height": 62,
                                        "fit": "cover"
                                      })
                                  }),
                                __h('SizedBox', {
                                    "width": 10
                                  }),
                                __h('Expanded', {}, [
                                    __h('Column', {
                                        "crossAxisAlignment": "start"
                                      }, [
                                        __h('Text', {
                                            "data": this.order.title,
                                            "style": {
                                              "fontSize": 13.5,
                                              "fontWeight": "w600"
                                            }
                                          }),
                                        __h('SizedBox', {
                                            "height": 5
                                          }),
                                        __h('Text', {
                                            "data": this.order.spec,
                                            "style": {
                                              "fontSize": 11,
                                              "color": '#ff8b909a'
                                            }
                                          }),
                                        __h('SizedBox', {
                                            "height": 5
                                          }),
                                        __h('Text', {
                                            "data": "×1",
                                            "style": {
                                              "fontSize": 11,
                                              "color": '#ffa3a9b4'
                                            },
                                            "textAlign": "right"
                                          })
                                      ])
                                  ])
                              ])
                          ])
                      }),
                    __h(_Block, {
                        "child": __h('Column', {
                            "crossAxisAlignment": "start"
                          }, [
                            __h(_BlockTitle, {}),
                            __h(_Kv, {
                                "label": "订单号",
                                "value": this.order.no
                              }),
                            __h(_Kv, {
                                "label": "下单时间",
                                "value": "2026-10-13 09:41"
                              }),
                            __h(_Kv, {
                                "label": "出行人",
                                "value": "旅行家小七"
                              })
                          ])
                      }),
                    __h(_Block, {
                        "child": __h('Column', {
                            "crossAxisAlignment": "start"
                          }, [
                            __h(_BlockTitle, {}),
                            __h(_Kv, {
                                "label": "成人票 × 1",
                                "value": "￥" + this.order.price
                              }),
                            __h(_Kv, {
                                "label": "优惠",
                                "value": "-￥0"
                              }),
                            __h(_Kv, {
                                "label": "实付",
                                "value": "￥" + this.order.price,
                                "highlight": true
                              })
                          ])
                      })
                  ])
              ]),
            __h(_BottomBar, {
                "children": [
                  __h('Expanded', {}, [
                      __h(MiniButton, {
                          "label": "联系客服",
                          "onTap": () => { return __jsui.host("toast", ["已联系客服（演示）"]); }
                        })
                    ]),
                  __h('SizedBox', {
                      "width": 10
                    }),
                  __h('Expanded', {}, [
                      __h('Button', {
                          "kind": "elevated",
                          "label": ((this.order.status == "待付款") ? "立即支付" : "申请开票"),
                          "event": this.__bind("__jsui.host(\"toast\", [((this.order.status == \"待付款\") ? \"支付成功（演示）\" : \"已申请开票（演示）\")])"),
                          "style": {
                            "backgroundColor": ((this.order.status == "待付款") ? kPrice : kBrand),
                            "foregroundColor": '#FFFFFF',
                            "shape": {
                              "kind": "rounded",
                              "borderRadius": {
                                "radius": 20.0
                              }
                            }
                          }
                        })
                    ])
                ]
              })
          ]),
        "backgroundColor": '#fff3f5f8'
      });
  }
}

// 组件 LoginPage
export class LoginPage {
  constructor() {
    this._phone = new TextEditingController();
    this._code = new TextEditingController();
  }
  dispose() {
    this._phone.dispose();
    this._code.dispose();
  }
  _login() {
    if ((this._phone.text.length < 11)) {
      __jsui.host("toast", ["请输入 11 位手机号"]);
      return;
    }
    __jsui.host("toast", ["登录成功，欢迎回来"]);
    __jsui.host("pop", []);
  }
  build() {
    return __h('Scaffold', {
        "body": __h('Column', {}, [
            __h('Container', {
                "color": '#FFFFFF'
              }, [
                __h(_TopBar, {
                    "title": "登录"
                  })
              ]),
            __h('Expanded', {}, [
                __h('ListView', {
                    "padding": {
                      "left": 26.0,
                      "top": 32.0,
                      "right": 26.0,
                      "bottom": 32.0
                    }
                  }, [
                    __h('Center', {}, [
                        __h('Container', {
                            "width": 66,
                            "height": 66,
                            "alignment": "center",
                            "decoration": {
                              "gradient": {
                                "kind": "linear",
                                "begin": "topLeft",
                                "end": "bottomRight",
                                "colors": [
                                  kBrand,
                                  '#ff7fb6ff'
                                ]
                              },
                              "borderRadius": {
                                "radius": 20.0
                              }
                            }
                          }, [
                            __h('Text', {
                                "data": "🧭",
                                "style": {
                                  "fontSize": 30
                                }
                              })
                          ])
                      ]),
                    __h('SizedBox', {
                        "height": 18
                      }),
                    __h('Text', {
                        "data": "欢迎回来",
                        "style": {
                          "fontSize": 20,
                          "fontWeight": "w700"
                        },
                        "textAlign": "center"
                      }),
                    __h('SizedBox', {
                        "height": 7
                      }),
                    __h('Text', {
                        "data": "登录后可同步订单与收藏",
                        "style": {
                          "fontSize": 12.5,
                          "color": '#ff8b909a'
                        },
                        "textAlign": "center"
                      }),
                    __h('SizedBox', {
                        "height": 22
                      }),
                    __h('Row', {}, [
                        __h('Container', {
                            "height": 50,
                            "padding": {
                              "left": 14.0,
                              "top": 0.0,
                              "right": 14.0,
                              "bottom": 0.0
                            },
                            "alignment": "center",
                            "decoration": {
                              "color": '#FFFFFF',
                              "borderRadius": {
                                "topLeft": 14,
                                "bottomLeft": 14
                              }
                            }
                          }, [
                            __h('Text', {
                                "data": "+86",
                                "style": {
                                  "fontSize": 14,
                                  "fontWeight": "w600"
                                }
                              })
                          ]),
                        __h('Expanded', {}, [
                            __h('SizedBox', {
                                "height": 50
                              }, [
                                __h('TextField', {
                                    "controller": this._phone,
                                    "hintText": "请输入手机号",
                                    "keyboardType": "phone"
                                  })
                              ])
                          ])
                      ]),
                    __h('SizedBox', {
                        "height": 14
                      }),
                    __h('SizedBox', {
                        "height": 50
                      }, [
                        __h('TextField', {
                            "controller": this._code,
                            "hintText": "请输入验证码",
                            "keyboardType": "number"
                          })
                      ]),
                    __h('SizedBox', {
                        "height": 20
                      }),
                    __h('Button', {
                        "kind": "elevated",
                        "label": "登录",
                        "event": this.__bind("_login"),
                        "style": {
                          "backgroundColor": kBrand,
                          "foregroundColor": '#FFFFFF',
                          "shape": {
                            "kind": "rounded",
                            "borderRadius": {
                              "radius": 24.0
                            }
                          }
                        }
                      }),
                    __h('SizedBox', {
                        "height": 16
                      }),
                    __h('Text', {
                        "data": "登录即代表同意《用户协议》与《隐私政策》",
                        "style": {
                          "fontSize": 11,
                          "color": '#ff8b909a',
                          "height": 1.7
                        },
                        "textAlign": "center"
                      })
                  ])
              ])
          ]),
        "backgroundColor": '#fff3f5f8'
      });
  }
}

// 组件 WebViewPage
export class WebViewPage {
  constructor(args) {
    this.url = (args && args.url !== undefined) ? args.url : '';
    this.title = (args && args.title !== undefined) ? args.title : '';
  }
  build() {
    return __h('Scaffold', {
        "body": __h('Column', {}, [
            __h('Container', {
                "color": '#FFFFFF'
              }, [
                __h(_TopBar, {
                    "title": this.title,
                    "trailing": __h('GestureDetector', {
                        "event": this.__bind("__jsui.host(\"toast\", [\"已刷新\"])")
                      }, [
                        __h('Icon', {
                            "icon": "refresh",
                            "size": 18,
                            "color": '#ff5c6270'
                          })
                      ])
                  })
              ]),
            __h('Expanded', {}, [
                __h('ListView', {
                    "padding": {
                      "left": 0.0,
                      "top": 12.0,
                      "right": 0.0,
                      "bottom": 24.0
                    }
                  }, [
                    __h('Container', {
                        "padding": {
                          "left": 12.0,
                          "top": 8.0,
                          "right": 12.0,
                          "bottom": 8.0
                        },
                        "margin": {
                          "left": 12.0,
                          "top": 0.0,
                          "right": 12.0,
                          "bottom": 12.0
                        },
                        "decoration": {
                          "color": '#fff3f5f8',
                          "borderRadius": {
                            "radius": 10.0
                          }
                        }
                      }, [
                        __h('Text', {
                            "data": this.url,
                            "style": {
                              "fontSize": 11,
                              "color": '#ff98a0ac'
                            }
                          })
                      ]),
                    __h(_Block, {
                        "child": __h('Column', {
                            "crossAxisAlignment": "start"
                          }, [
                            __h('ClipRRect', {
                                "child": __h('Image', {
                                    "source": kBanners[0].img,
                                    "height": 130,
                                    "fit": "cover"
                                  })
                              }),
                            __h('SizedBox', {
                                "height": 14
                              }),
                            __h('Text', {
                                "data": this.title,
                                "style": {
                                  "fontSize": 17,
                                  "fontWeight": "w700"
                                }
                              }),
                            __h('SizedBox', {
                                "height": 12
                              }),
                            __h('Text', {
                                "data": "这是通过宿主 WebView 打开的 H5 页面（演示占位）。真实实现中这里会加载真实网页内容，并复用统一的导航栏与加载进度。",
                                "style": {
                                  "fontSize": 13.5,
                                  "height": 1.9,
                                  "color": '#ff4d5462'
                                }
                              }),
                            __h('SizedBox', {
                                "height": 12
                              }),
                            __h('Text', {
                                "data": "JS 侧调用 WebView.open(url, title)，宿主侧用 Navigator 推入本页面（与 Network 同一套 @HostInjected 通道）。",
                                "style": {
                                  "fontSize": 13.5,
                                  "height": 1.9,
                                  "color": '#ff4d5462'
                                }
                              })
                          ])
                      })
                  ])
              ])
          ]),
        "backgroundColor": '#fff3f5f8'
      });
  }
}

// 组件 _Block
export class _Block {
  constructor(args) {
    this.child = (args && args.child !== undefined) ? args.child : null;
  }
  build() {
    return __h('Container', {
        "padding": {
          "left": 16.0,
          "top": 14.0,
          "right": 16.0,
          "bottom": 14.0
        },
        "margin": {
          "left": 12.0,
          "top": 0.0,
          "right": 12.0,
          "bottom": 12.0
        },
        "decoration": {
          "color": '#FFFFFF',
          "borderRadius": {
            "radius": 16.0
          }
        }
      }, [
        this.child
      ]);
  }
}

// 组件 _TopBar
export class _TopBar {
  constructor(args) {
    this.title = (args && args.title !== undefined) ? args.title : '';
    this.trailing = (args && args.trailing !== undefined) ? args.trailing : null;
  }
  build() {
    return __h('Container', {
        "padding": {
          "left": 14.0,
          "top": 6.0,
          "right": 14.0,
          "bottom": 12.0
        },
        "decoration": {
          "color": '#FFFFFF',
          "border": {
            "bottom": {
              "color": '#ffeef1f5'
            }
          }
        }
      }, [
        __h('Row', {}, [
            __h('GestureDetector', {
                "event": this.__bind("__jsui.host(\"pop\", [])")
              }, [
                __h('Container', {
                    "width": 34,
                    "height": 34,
                    "decoration": {
                      "color": '#fff3f5f8',
                      "shape": "circle"
                    }
                  }, [
                    __h('Icon', {
                        "icon": "arrow_back_ios_new",
                        "size": 15,
                        "color": '#ff171a21'
                      })
                  ])
              ]),
            __h('SizedBox', {
                "width": 10
              }),
            __h('Expanded', {}, [
                __h('Text', {
                    "data": this.title,
                    "style": {
                      "fontSize": 16.5,
                      "fontWeight": "w700"
                    },
                    "maxLines": 1,
                    "overflow": "ellipsis"
                  })
              ]),
            ...((this.trailing != null) ? [this.trailing] : [])
          ])
      ]);
  }
}

// 组件 _BottomBar
export class _BottomBar {
  constructor(args) {
    this.children = (args && args.children !== undefined) ? args.children : [];
  }
  build() {
    return __h('Container', {
        "padding": {
          "left": 16.0,
          "top": 12.0,
          "right": 16.0,
          "bottom": 16.0
        },
        "decoration": {
          "color": '#FFFFFF',
          "border": {
            "top": {
              "color": '#ffeef1f5'
            }
          }
        }
      }, [
        __h('Row', {}, [
            ...this.children
          ])
      ]);
  }
}

// 组件 _Kv
export class _Kv {
  constructor(args) {
    this.label = (args && args.label !== undefined) ? args.label : '';
    this.value = (args && args.value !== undefined) ? args.value : '';
    this.highlight = (args && args.highlight !== undefined) ? args.highlight : false;
  }
  build() {
    return __h('Padding', {
        "padding": {
          "left": 0.0,
          "top": 8.0,
          "right": 0.0,
          "bottom": 8.0
        }
      }, [
        __h('Row', {
            "mainAxisAlignment": "spaceBetween"
          }, [
            __h('Text', {
                "data": this.label,
                "style": {
                  "fontSize": 13,
                  "color": '#ff4d5462'
                }
              }),
            __h('Text', {
                "data": this.value,
                "style": {
                  "color": (this.highlight ? kPrice : '#ff171a21')
                }
              })
          ])
      ]);
  }
}

// 组件 _BlockTitle
export class _BlockTitle {
  constructor(args) {
    this.text = (args && args.text !== undefined) ? args.text : '';
  }
  build() {
    return __h('Padding', {
        "padding": {
          "left": 0.0,
          "top": 0.0,
          "right": 0.0,
          "bottom": 10.0
        }
      }, [
        __h('Text', {
            "data": this.text,
            "style": {
              "fontSize": 15,
              "fontWeight": "w700"
            }
          })
      ]);
  }
}

