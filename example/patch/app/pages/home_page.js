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
    this._refreshController = new EasyRefreshController();
    this._feed = null;
  }
  initState() {
    console.log("HomePage initState ---");
    this._load();
  }
  didUpdateWidget(oldWidget) {
    console.log("--HomePage didUpdateWidget 0");
  }
  _refresh() {
    this._refreshController.callRefresh();
  }
  async _load() {
    var feed = await this._service.fetchHome();
    this.setState(() => { this._feed = feed; });
  }
  build(context) {
    console.log("--HomePage build");
    var feed = this._feed;
    if ((feed == null)) {
      return (this.__k0 || (this.__k0 = new Center({
          "child": new CircularProgressIndicator({})
        })));
    }
    var banners = this._feed.banners;
    var grid = this._feed.grid;
    var spots = this._feed.spots;
    var adImg = this._feed.adImg;
    return new Container({
        "color": '#fff4f5f7',
        "child": new EasyRefresh({
            "controller": this._refreshController,
            "onRefresh": this.__bindFn(0, [], (...__a) => this._load(...__a)),
            "child": new CustomScrollView({
                "slivers": [
                  new SliverToBoxAdapter({
                      "child": new Column({
                          "crossAxisAlignment": "stretch",
                          "children": [
                            new HomeHeader({
                                "onRefresh": (...__a) => this._refresh(...__a)
                              }),
                            (this.__k1 || (this.__k1 = new SizedBox({
                                "height": 12
                              }))),
                            new SizedBox({
                                "height": 150,
                                "child": __h('PageView', {
                                    "children": [
                                      ...(() => { var out = []; for (let i = 0; (i < this._feed.banners.length); (i++)) { out.push.apply(out, [new BannerSlide({ "banner": this._feed.banners[i] })]); } return out; })()
                                    ]
                                  })
                              }),
                            (this.__k2 || (this.__k2 = new SizedBox({
                                "height": 10
                              }))),
                            new Row({
                                "mainAxisAlignment": "center",
                                "children": [
                                  ...(() => { var out = []; for (let i = 0; (i < this._feed.banners.length); (i++)) { out.push.apply(out, [new Container({ "margin": { "left": 3.0, "top": 0.0, "right": 3.0, "bottom": 0.0 }, "width": 6, "height": 6, "decoration": { "color": ((i == 0) ? '#ff0e7afb' : '#ffd5d9e0'), "borderRadius": { "radius": 3.0 } } })]); } return out; })()
                                ]
                              }),
                            (this.__k1 || (this.__k1 = new SizedBox({
                                "height": 12
                              }))),
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
                            (this.__k1 || (this.__k1 = new SizedBox({
                                "height": 12
                              }))),
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
                            (this.__k3 || (this.__k3 = new SizedBox({
                                "height": 16
                              }))),
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
                                      (this.__k4 || (this.__k4 = new SizedBox({
                                          "width": 8
                                        }))),
                                      (this.__k5 || (this.__k5 = new Text({
                                          "data": "景点推荐",
                                          "style": {
                                            "color": '#ff1f2430',
                                            "fontSize": 17,
                                            "fontWeight": "w700"
                                          }
                                        }))),
                                      (this.__k6 || (this.__k6 = new Spacer({}))),
                                      (this.__k7 || (this.__k7 = new Text({
                                          "data": "为你精选",
                                          "style": {
                                            "color": '#ff8a909e',
                                            "fontSize": 12
                                          }
                                        })))
                                    ]
                                  })
                              }),
                            (this.__k2 || (this.__k2 = new SizedBox({
                                "height": 10
                              })))
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
                  (this.__k8 || (this.__k8 = new SliverToBoxAdapter({
                      "child": new SizedBox({
                          "height": 20
                        })
                    })))
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
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.onRefresh = (args && args.onRefresh !== undefined) ? args.onRefresh : null;
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
                            "child": (this.__k0 || (this.__k0 = new Row({
                                "children": [
                                  new Icon({
                                      "color": '#ffffffff',
                                      "icon": "location_on",
                                      "size": 18
                                    }),
                                  new SizedBox({
                                      "width": 2
                                    }),
                                  new Text({
                                      "data": "上海",
                                      "style": {
                                        "color": '#ffffffff',
                                        "fontSize": 15,
                                        "fontWeight": "w600"
                                      }
                                    }),
                                  new Icon({
                                      "color": '#ffffffff',
                                      "icon": "keyboard_arrow_down",
                                      "size": 18
                                    })
                                ]
                              })))
                          }),
                        (this.__k1 || (this.__k1 = new Spacer({}))),
                        new InkWell({
                            "onTap": this.__bindFn(1, [], (...__a) => this.onRefresh(...__a)),
                            "borderRadius": {
                              "radius": 18.0
                            },
                            "child": (this.__k2 || (this.__k2 = new Padding({
                                "child": new Icon({
                                    "color": '#ffffffff',
                                    "icon": "refresh",
                                    "size": 24
                                  }),
                                "padding": {
                                  "bottom": 4.0,
                                  "left": 4.0,
                                  "right": 4.0,
                                  "top": 4.0
                                }
                              })))
                          }),
                        (this.__k3 || (this.__k3 = new SizedBox({
                            "width": 8
                          }))),
                        new InkWell({
                            "onTap": this.__bindFn(2, [], (...__a) => this.openMessages(...__a)),
                            "borderRadius": {
                              "radius": 18.0
                            },
                            "child": (this.__k4 || (this.__k4 = new Stack({
                                "children": [
                                  new Padding({
                                      "child": new Icon({
                                          "color": '#ffffffff',
                                          "icon": "notifications",
                                          "size": 24
                                        }),
                                      "padding": {
                                        "bottom": 4.0,
                                        "left": 4.0,
                                        "right": 4.0,
                                        "top": 4.0
                                      }
                                    }),
                                  new Positioned({
                                      "child": new DecoratedBox({
                                          "child": new SizedBox({
                                              "height": 8,
                                              "width": 8
                                            }),
                                          "decoration": {
                                            "borderRadius": {
                                              "radius": 4.0
                                            },
                                            "color": '#ffff5a36'
                                          }
                                        }),
                                      "right": 3,
                                      "top": 3
                                    })
                                ]
                              })))
                          })
                      ]
                    }),
                  (this.__k5 || (this.__k5 = new SizedBox({
                      "height": 12
                    }))),
                  new InkWell({
                      "onTap": this.__bindFn(3, [], (...__a) => this.openSearch(...__a)),
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
                          "child": (this.__k6 || (this.__k6 = new Row({
                              "children": [
                                new Icon({
                                    "color": '#ff9aa0ac',
                                    "icon": "search",
                                    "size": 20
                                  }),
                                new SizedBox({
                                    "width": 6
                                  }),
                                new Text({
                                    "data": "搜索目的地 / 关键词",
                                    "style": {
                                      "color": '#ff9aa0ac',
                                      "fontSize": 14
                                    }
                                  }),
                                new Spacer({}),
                                new Text({
                                    "data": "搜索",
                                    "style": {
                                      "color": '#ff0e7afb',
                                      "fontSize": 13,
                                      "fontWeight": "w600"
                                    }
                                  })
                              ]
                            })))
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
                                (this.__k0 || (this.__k0 = new SizedBox({
                                    "height": 4
                                  }))),
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
              (this.__k0 || (this.__k0 = new SizedBox({
                  "height": 6
                }))),
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
                            (this.__k0 || (this.__k0 = new SizedBox({
                                "height": 4
                              }))),
                            new Text({
                                "maxLines": 1,
                                "overflow": "ellipsis",
                                "style": {
                                  "fontSize": 11,
                                  "color": '#ff8a909e'
                                },
                                "data": this.spot.sub
                              }),
                            (this.__k1 || (this.__k1 = new SizedBox({
                                "height": 8
                              }))),
                            new Row({
                                "children": [
                                  (this.__k2 || (this.__k2 = new Text({
                                      "data": "¥",
                                      "style": {
                                        "color": '#ffff5a36',
                                        "fontSize": 11,
                                        "fontWeight": "w700"
                                      }
                                    }))),
                                  new Text({
                                      "style": {
                                        "fontSize": 17,
                                        "color": '#ffff5a36',
                                        "fontWeight": "w700"
                                      },
                                      "data": this.spot.price
                                    }),
                                  (this.__k3 || (this.__k3 = new Spacer({}))),
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
                                (this.__k0 || (this.__k0 = new Text({
                                    "data": "热气球季 · 限时特惠",
                                    "style": {
                                      "color": '#ffffffff',
                                      "fontSize": 16,
                                      "fontWeight": "w700"
                                    }
                                  }))),
                                (this.__k1 || (this.__k1 = new SizedBox({
                                    "height": 6
                                  }))),
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
                                    "child": (this.__k2 || (this.__k2 = new Text({
                                        "data": "立即查看 >",
                                        "style": {
                                          "color": '#ff0e7afb',
                                          "fontSize": 11,
                                          "fontWeight": "w600"
                                        }
                                      })))
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

