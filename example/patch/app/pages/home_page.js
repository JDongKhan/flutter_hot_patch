// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/app/pages/home_page.dart 自动生成
// 重新生成：dart run build_runner build

import { AppService } from '../service/app_service.js';
import { HomeFeed } from '../model/app_models.js';
import { HomeBanner } from '../model/app_models.js';
import { GridEntry } from '../model/app_models.js';
import { Spot } from '../model/app_models.js';
import { Center, CircularProgressIndicator, ClipRRect, Column, Container, CustomScrollView, DecoratedBox, EasyRefresh, Icon, Image, InkWell, Padding, Positioned, Row, SafeArea, SizedBox, SliverPadding, SliverToBoxAdapter, Spacer, Stack, Text, __h } from '../../flutter.js';

// 组件 HomePage
export class HomePage {
  constructor(args) {
    this.props = args || {};
    this._service = new AppService({});
    this._feed = null;
  }
  initState() {
    console.log("HomePage initState ---");
    this._load();
  }
  async _load() {
    var feed = await this._service.fetchHome();
    this.setState(() => { this._feed = feed; });
  }
  build(context) {
    var feed = this._feed;
    if ((feed == null)) {
      return new Center({
          "child": new CircularProgressIndicator({})
        });
    }
    var banners = this._feed.banners;
    var grid = this._feed.grid;
    var spots = this._feed.spots;
    var adImg = this._feed.adImg;
    return new Container({
        "color": '#fff4f5f7',
        "child": new EasyRefresh({
            "onRefresh": this.__bindFn(0, [], (...__a) => this._load(...__a)),
            "child": new CustomScrollView({
                "slivers": [
                  new SliverToBoxAdapter({
                      "child": new Column({
                          "crossAxisAlignment": "stretch",
                          "children": [
                            new HomeHeader({}),
                            new SizedBox({
                                "height": 12
                              }),
                            new SizedBox({
                                "height": 150,
                                "child": __h('PageView', {
                                    "children": [
                                      ...(() => { var out = []; for (let i = 0; (i < this._feed.banners.length); (i++)) { out.push.apply(out, [new BannerSlide({ "banner": this._feed.banners[i] })]); } return out; })()
                                    ]
                                  })
                              }),
                            new SizedBox({
                                "height": 10
                              }),
                            new Row({
                                "mainAxisAlignment": "center",
                                "children": [
                                  ...(() => { var out = []; for (let i = 0; (i < this._feed.banners.length); (i++)) { out.push.apply(out, [new Container({ "margin": { "left": 3.0, "top": 0.0, "right": 3.0, "bottom": 0.0 }, "width": 6, "height": 6, "decoration": { "color": ((i == 0) ? '#ff0e7afb' : '#ffd5d9e0'), "borderRadius": { "radius": 3.0 } } })]); } return out; })()
                                ]
                              }),
                            new SizedBox({
                                "height": 12
                              }),
                            new Container({
                                "margin": {
                                  "left": 12.0,
                                  "top": 0.0,
                                  "right": 12.0,
                                  "bottom": 0.0
                                },
                                "padding": {
                                  "left": 0.0,
                                  "top": 12.0,
                                  "right": 0.0,
                                  "bottom": 12.0
                                },
                                "decoration": {
                                  "color": '#ffffffff',
                                  "borderRadius": {
                                    "radius": 14.0
                                  }
                                },
                                "child": __h('GridView', {
                                    "gridDelegate": {
                                      "maxCrossAxisExtent": 150,
                                      "mainAxisSpacing": 6,
                                      "crossAxisSpacing": 6,
                                      "mainAxisExtent": 84
                                    },
                                    "shrinkWrap": true,
                                    "physics": "NeverScrollableScrollPhysics",
                                    "children": [
                                      ...(() => { var out = []; for (let i = 0; (i < this._feed.grid.length); (i++)) { out.push.apply(out, [new GridCell({ "entry": this._feed.grid[i] })]); } return out; })()
                                    ]
                                  })
                              }),
                            new SizedBox({
                                "height": 12
                              }),
                            new Container({
                                "margin": {
                                  "left": 12.0,
                                  "top": 0.0,
                                  "right": 12.0,
                                  "bottom": 0.0
                                },
                                "child": new PromoCard({
                                    "img": this._feed.adImg
                                  })
                              }),
                            new SizedBox({
                                "height": 16
                              }),
                            new Padding({
                                "padding": {
                                  "left": 14.0,
                                  "top": 0.0,
                                  "right": 14.0,
                                  "bottom": 0.0
                                },
                                "child": new Row({
                                    "children": [
                                      new Container({
                                          "width": 4,
                                          "height": 16,
                                          "decoration": {
                                            "color": '#ff0e7afb',
                                            "borderRadius": {
                                              "radius": 2.0
                                            }
                                          }
                                        }),
                                      new SizedBox({
                                          "width": 8
                                        }),
                                      new Text({
                                          "style": {
                                            "fontSize": 17,
                                            "fontWeight": "w700",
                                            "color": '#ff1f2430'
                                          },
                                          "data": "景点推荐"
                                        }),
                                      new Spacer({}),
                                      new Text({
                                          "style": {
                                            "fontSize": 12,
                                            "color": '#ff8a909e'
                                          },
                                          "data": "为你精选"
                                        })
                                    ]
                                  })
                              }),
                            new SizedBox({
                                "height": 10
                              })
                          ]
                        })
                    }),
                  new SliverPadding({
                      "padding": {
                        "left": 12.0,
                        "top": 0.0,
                        "right": 12.0,
                        "bottom": 0.0
                      },
                      "sliver": __h('SliverGrid', {
                          "gridDelegate": {
                            "maxCrossAxisExtent": 300,
                            "mainAxisSpacing": 10,
                            "crossAxisSpacing": 10,
                            "mainAxisExtent": 190
                          },
                          "delegate": {
                            "__delegate": "builder",
                            "builder": "_builder0",
                            "childCount": this._feed.spots.length
                          }
                        })
                    }),
                  new SliverToBoxAdapter({
                      "child": new SizedBox({
                          "height": 20
                        })
                    })
                ]
              })
          })
      });
  }
  _builder0(context, index) {
      return new SpotCard({
        "spot": this._feed.spots[index]
      });
  }
}

// 组件 HomeHeader
export class HomeHeader {
  constructor(args) {
    this.props = args || {};
  }
  openSearch() {
    _app_host_.invoke("openSearch", []);
  }
  openMessages() {
    _app_host_.invoke("toast", ["暂无新消息"]);
  }
  openLocation() {
    _app_host_.invoke("toast", ["定位：上海市 · 点击切换城市"]);
  }
  build(context) {
    return new Container({
        "padding": {
          "left": 16.0,
          "top": 14.0,
          "right": 16.0,
          "bottom": 16.0
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
            "child": new Column({
                "crossAxisAlignment": "start",
                "children": [
                  new Row({
                      "children": [
                        new InkWell({
                            "onTap": this.__bindFn(0, [], (...__a) => this.openLocation(...__a)),
                            "child": new Row({
                                "children": [
                                  new Icon({
                                      "color": '#ffffffff',
                                      "size": 18,
                                      "icon": "location_on"
                                    }),
                                  new SizedBox({
                                      "width": 2
                                    }),
                                  new Text({
                                      "style": {
                                        "color": '#ffffffff',
                                        "fontSize": 15,
                                        "fontWeight": "w600"
                                      },
                                      "data": "上海"
                                    }),
                                  new Icon({
                                      "color": '#ffffffff',
                                      "size": 18,
                                      "icon": "keyboard_arrow_down"
                                    })
                                ]
                              })
                          }),
                        new Spacer({}),
                        new InkWell({
                            "onTap": this.__bindFn(1, [], (...__a) => this.openMessages(...__a)),
                            "borderRadius": {
                              "radius": 18.0
                            },
                            "child": new Stack({
                                "children": [
                                  new Padding({
                                      "padding": {
                                        "left": 4.0,
                                        "top": 4.0,
                                        "right": 4.0,
                                        "bottom": 4.0
                                      },
                                      "child": new Icon({
                                          "color": '#ffffffff',
                                          "size": 24,
                                          "icon": "notifications"
                                        })
                                    }),
                                  new Positioned({
                                      "right": 3,
                                      "top": 3,
                                      "child": new DecoratedBox({
                                          "decoration": {
                                            "color": '#ffff5a36',
                                            "borderRadius": {
                                              "radius": 4.0
                                            }
                                          },
                                          "child": new SizedBox({
                                              "width": 8,
                                              "height": 8
                                            })
                                        })
                                    })
                                ]
                              })
                          })
                      ]
                    }),
                  new SizedBox({
                      "height": 12
                    }),
                  new InkWell({
                      "onTap": this.__bindFn(2, [], (...__a) => this.openSearch(...__a)),
                      "borderRadius": {
                        "radius": 20.0
                      },
                      "child": new Container({
                          "height": 42,
                          "padding": {
                            "left": 14.0,
                            "top": 0.0,
                            "right": 14.0,
                            "bottom": 0.0
                          },
                          "decoration": {
                            "color": '#ffffffff',
                            "borderRadius": {
                              "radius": 21.0
                            }
                          },
                          "child": new Row({
                              "children": [
                                new Icon({
                                    "color": '#ff9aa0ac',
                                    "size": 20,
                                    "icon": "search"
                                  }),
                                new SizedBox({
                                    "width": 6
                                  }),
                                new Text({
                                    "style": {
                                      "fontSize": 14,
                                      "color": '#ff9aa0ac'
                                    },
                                    "data": "搜索目的地 / 关键词"
                                  }),
                                new Spacer({}),
                                new Text({
                                    "style": {
                                      "fontSize": 13,
                                      "color": '#ff0e7afb',
                                      "fontWeight": "w600"
                                    },
                                    "data": "搜索"
                                  })
                              ]
                            })
                        })
                    })
                ]
              })
          })
      });
  }
}

// 组件 BannerSlide
export class BannerSlide {
  constructor(args) {
    this.props = args || {};
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.banner = (args && args.banner !== undefined) ? args.banner : null;
  }
  open() {
    _app_host_.invoke("toast", [this.banner.title]);
  }
  build(context) {
    return new Padding({
        "padding": {
          "left": 12.0,
          "top": 0.0,
          "right": 12.0,
          "bottom": 0.0
        },
        "child": new InkWell({
            "onTap": this.__bindFn(0, [], (...__a) => this.open(...__a)),
            "borderRadius": {
              "radius": 14.0
            },
            "child": new ClipRRect({
                "borderRadius": {
                  "radius": 14.0
                },
                "child": new Stack({
                    "fit": "expand",
                    "children": [
                      new Image({
                          "fit": "cover",
                          "factory": "network",
                          "src": this.banner.img
                        }),
                      new Container({
                          "decoration": {
                            "gradient": {
                              "kind": "linear",
                              "colors": [
                                '#00000000',
                                '#b3000000'
                              ],
                              "begin": "center",
                              "end": "bottomCenter"
                            }
                          }
                        }),
                      new Positioned({
                          "left": 14,
                          "right": 14,
                          "bottom": 14,
                          "child": new Column({
                              "crossAxisAlignment": "start",
                              "children": [
                                new Text({
                                    "style": {
                                      "color": '#ffffffff',
                                      "fontSize": 17,
                                      "fontWeight": "w700"
                                    },
                                    "data": this.banner.title
                                  }),
                                new SizedBox({
                                    "height": 4
                                  }),
                                new Text({
                                    "style": {
                                      "color": '#e6ffffff',
                                      "fontSize": 12
                                    },
                                    "data": this.banner.sub
                                  })
                              ]
                            })
                        })
                    ]
                  })
              })
          })
      });
  }
}

// 组件 GridCell
export class GridCell {
  constructor(args) {
    this.props = args || {};
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.entry = (args && args.entry !== undefined) ? args.entry : null;
  }
  open() {
    _app_host_.invoke("toast", [this.entry.title + " 频道"]);
  }
  build(context) {
    return new InkWell({
        "onTap": this.__bindFn(0, [], (...__a) => this.open(...__a)),
        "child": new Column({
            "mainAxisAlignment": "center",
            "children": [
              new Text({
                  "style": {
                    "fontSize": 22
                  },
                  "data": this.entry.emoji
                }),
              new SizedBox({
                  "height": 6
                }),
              new Text({
                  "style": {
                    "fontSize": 12,
                    "color": '#ff4d5462'
                  },
                  "data": this.entry.title
                })
            ]
          })
      });
  }
}

// 组件 SpotCard
export class SpotCard {
  constructor(args) {
    this.props = args || {};
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.spot = (args && args.spot !== undefined) ? args.spot : null;
  }
  open() {
    _app_host_.invoke("openSpot", [this.spot.id]);
  }
  build(context) {
    return new InkWell({
        "onTap": this.__bindFn(0, [], (...__a) => this.open(...__a)),
        "borderRadius": {
          "radius": 14.0
        },
        "child": new Container({
            "decoration": {
              "color": '#ffffffff',
              "borderRadius": {
                "radius": 14.0
              }
            },
            "clipBehavior": "antiAlias",
            "child": new Column({
                "crossAxisAlignment": "start",
                "children": [
                  new SizedBox({
                      "height": 96,
                      "child": new Stack({
                          "fit": "expand",
                          "children": [
                            new Image({
                                "fit": "cover",
                                "factory": "network",
                                "src": this.spot.img
                              }),
                            new Positioned({
                                "left": 8,
                                "top": 8,
                                "child": new Container({
                                    "padding": {
                                      "left": 6.0,
                                      "top": 2.0,
                                      "right": 6.0,
                                      "bottom": 2.0
                                    },
                                    "decoration": {
                                      "color": '#ffff5a36',
                                      "borderRadius": {
                                        "radius": 6.0
                                      }
                                    },
                                    "child": new Text({
                                        "style": {
                                          "color": '#ffffffff',
                                          "fontSize": 10,
                                          "fontWeight": "w600"
                                        },
                                        "data": this.spot.tag
                                      })
                                  })
                              })
                          ]
                        })
                    }),
                  new Padding({
                      "padding": {
                        "left": 10.0,
                        "top": 8.0,
                        "right": 10.0,
                        "bottom": 10.0
                      },
                      "child": new Column({
                          "crossAxisAlignment": "start",
                          "children": [
                            new Text({
                                "maxLines": 1,
                                "overflow": "ellipsis",
                                "style": {
                                  "fontSize": 14,
                                  "fontWeight": "w600",
                                  "color": '#ff1f2430'
                                },
                                "data": this.spot.title
                              }),
                            new SizedBox({
                                "height": 4
                              }),
                            new Text({
                                "maxLines": 1,
                                "overflow": "ellipsis",
                                "style": {
                                  "fontSize": 11,
                                  "color": '#ff8a909e'
                                },
                                "data": this.spot.sub
                              }),
                            new SizedBox({
                                "height": 8
                              }),
                            new Row({
                                "children": [
                                  new Text({
                                      "style": {
                                        "fontSize": 11,
                                        "color": '#ffff5a36',
                                        "fontWeight": "w700"
                                      },
                                      "data": "¥"
                                    }),
                                  new Text({
                                      "style": {
                                        "fontSize": 17,
                                        "color": '#ffff5a36',
                                        "fontWeight": "w700"
                                      },
                                      "data": this.spot.price
                                    }),
                                  new Spacer({}),
                                  new Text({
                                      "style": {
                                        "fontSize": 10,
                                        "color": '#ff9aa0ac'
                                      },
                                      "data": this.spot.sold
                                    })
                                ]
                              })
                          ]
                        })
                    })
                ]
              })
          })
      });
  }
}

// 组件 PromoCard
export class PromoCard {
  constructor(args) {
    this.props = args || {};
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.img = (args && args.img !== undefined) ? args.img : '';
  }
  open() {
    _app_host_.invoke("open", ["https://flutter.dev", "活动详情"]);
  }
  build(context) {
    return new InkWell({
        "onTap": this.__bindFn(0, [], (...__a) => this.open(...__a)),
        "borderRadius": {
          "radius": 14.0
        },
        "child": new SizedBox({
            "height": 96,
            "child": new ClipRRect({
                "borderRadius": {
                  "radius": 14.0
                },
                "child": new Stack({
                    "fit": "expand",
                    "children": [
                      new Image({
                          "fit": "cover",
                          "factory": "network",
                          "src": this.img
                        }),
                      new Positioned({
                          "left": 16,
                          "top": 22,
                          "child": new Column({
                              "crossAxisAlignment": "start",
                              "children": [
                                new Text({
                                    "style": {
                                      "color": '#ffffffff',
                                      "fontSize": 16,
                                      "fontWeight": "w700"
                                    },
                                    "data": "热气球季 · 限时特惠"
                                  }),
                                new SizedBox({
                                    "height": 6
                                  }),
                                new Container({
                                    "padding": {
                                      "left": 10.0,
                                      "top": 4.0,
                                      "right": 10.0,
                                      "bottom": 4.0
                                    },
                                    "decoration": {
                                      "color": '#e6ffffff',
                                      "borderRadius": {
                                        "radius": 12.0
                                      }
                                    },
                                    "child": new Text({
                                        "style": {
                                          "fontSize": 11,
                                          "color": '#ff0e7afb',
                                          "fontWeight": "w600"
                                        },
                                        "data": "立即查看 >"
                                      })
                                  })
                              ]
                            })
                        })
                    ]
                  })
              })
          })
      });
  }
}

