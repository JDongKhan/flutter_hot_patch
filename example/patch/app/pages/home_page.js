// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/app/pages/home_page.dart 自动生成
// 重新生成：dart run build_runner build

import { AppService } from '../service/app_service.js';
import { HomeFeed } from '../model/app_models.js';
import { GridEntry } from '../model/app_models.js';
import { Spot } from '../model/app_models.js';
import { BannerCarousel } from '../widgets/banner_carousel.js';
import { Alignment, BorderRadius, BoxDecoration, BoxFit, Center, CircularProgressIndicator, Clip, ClipRRect, Color, Column, Container, CrossAxisAlignment, CustomScrollView, DecoratedBox, EasyRefresh, EasyRefreshController, EdgeInsets, Expanded, FontWeight, GridView, Icon, Image, InkWell, LinearGradient, MainAxisAlignment, NeverScrollableScrollPhysics, Padding, Positioned, Radius, Row, SafeArea, SizedBox, SliverGrid, SliverGridDelegateWithMaxCrossAxisExtent, SliverPadding, SliverToBoxAdapter, Spacer, Stack, StackFit, Text, TextOverflow, TextStyle } from '../../flutter.js';

// 组件 HomePage
export class HomePage {
  constructor(args) {
    this.props = args || {};
    this._service = new AppService();
    this._refreshController = new EasyRefreshController();
    this._feed = null;
    this._city = "上海";
  }
  initState() {
    console.log("HomePage initState ---");
    this._load();
  }
  async _pickCity() {
    var picked = await _app_host_.invoke("openCityPicker", [this._city]);
    if ((picked == null)) {
      return;
    }
    this.setState(() => { this._city = picked; });
    await this._load();
  }
  didUpdateWidget(oldWidget) {
    console.log("--HomePage didUpdateWidget 0");
  }
  _refresh() {
    this._refreshController.callRefresh();
  }
  async _load() {
    var feed = await this._service.fetchHome(this._city);
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
      "color": (this.__k1 || (this.__k1 = new Color({
        "value": 0xFFF4F5F7
      }))),
      "child": new Column({
        "crossAxisAlignment": CrossAxisAlignment.stretch,
        "children": [
          new HomeHeader({
            "city": this._city,
            "onRefresh": (...__a) => this._refresh(...__a),
            "onPickCity": (...__a) => this._pickCity(...__a)
          }),
          new Expanded({
            "child": new EasyRefresh({
              "controller": this._refreshController,
              "onRefresh": this.__bindFn(0, [], (...__a) => this._load(...__a)),
              "child": new CustomScrollView({
                "slivers": [
                  new SliverToBoxAdapter({
                    "child": new Column({
                      "crossAxisAlignment": CrossAxisAlignment.stretch,
                      "children": [
                        (this.__k2 || (this.__k2 = new SizedBox({
                          "height": 12
                        }))),
                        new BannerCarousel({
                          "banners": this._feed.banners
                        }),
                        (this.__k2 || (this.__k2 = new SizedBox({
                          "height": 12
                        }))),
                        new Container({
                          "margin": (this.__k3 || (this.__k3 = EdgeInsets.symmetric({
                            "horizontal": 12
                          }))),
                          "padding": (this.__k4 || (this.__k4 = EdgeInsets.symmetric({
                            "vertical": 12
                          }))),
                          "decoration": (this.__k5 || (this.__k5 = new BoxDecoration({
                            "borderRadius": BorderRadius.all({
                              "radius": Radius.circular({
                                "radius": 14
                              })
                            }),
                            "color": new Color({
                              "value": 0xFFFFFFFF
                            })
                          }))),
                          "child": new GridView({
                            "gridDelegate": (this.__k6 || (this.__k6 = new SliverGridDelegateWithMaxCrossAxisExtent({
                              "crossAxisSpacing": 6,
                              "mainAxisExtent": 84,
                              "mainAxisSpacing": 6,
                              "maxCrossAxisExtent": 150
                            }))),
                            "shrinkWrap": true,
                            "physics": (this.__k7 || (this.__k7 = new NeverScrollableScrollPhysics({}))),
                            "children": [
                              ...(() => { var out = []; for (let i = 0; (i < this._feed.grid.length); (i++)) { out.push.apply(out, [new GridCell({
                                      "entry": this._feed.grid[i]
                                    })]); } return out; })()
                            ]
                          })
                        }),
                        (this.__k2 || (this.__k2 = new SizedBox({
                          "height": 12
                        }))),
                        new Container({
                          "margin": (this.__k3 || (this.__k3 = EdgeInsets.symmetric({
                            "horizontal": 12
                          }))),
                          "child": new PromoCard({
                            "img": this._feed.adImg
                          })
                        }),
                        (this.__k8 || (this.__k8 = new SizedBox({
                          "height": 16
                        }))),
                        new Padding({
                          "padding": (this.__k9 || (this.__k9 = EdgeInsets.symmetric({
                            "horizontal": 14
                          }))),
                          "child": new Row({
                            "children": [
                              new Container({
                                "width": 4,
                                "height": 16,
                                "decoration": (this.__k10 || (this.__k10 = new BoxDecoration({
                                  "borderRadius": BorderRadius.all({
                                    "radius": Radius.circular({
                                      "radius": 2
                                    })
                                  }),
                                  "color": new Color({
                                    "value": 0xFF0E7AFB
                                  })
                                })))
                              }),
                              (this.__k11 || (this.__k11 = new SizedBox({
                                "width": 8
                              }))),
                              (this.__k12 || (this.__k12 = new Text({
                                "data": "景点推荐",
                                "style": new TextStyle({
                                  "fontSize": 17,
                                  "fontWeight": FontWeight.w700,
                                  "color": new Color({
                                    "value": 0xFF1F2430
                                  })
                                })
                              }))),
                              (this.__k13 || (this.__k13 = new Spacer({}))),
                              (this.__k14 || (this.__k14 = new Text({
                                "data": "为你精选",
                                "style": new TextStyle({
                                  "fontSize": 12,
                                  "color": new Color({
                                    "value": 0xFF8A909E
                                  })
                                })
                              })))
                            ]
                          })
                        }),
                        (this.__k15 || (this.__k15 = new SizedBox({
                          "height": 10
                        })))
                      ]
                    })
                  }),
                  new SliverPadding({
                    "padding": (this.__k16 || (this.__k16 = EdgeInsets.fromLTRB({
                      "bottom": 0,
                      "left": 12,
                      "right": 12,
                      "top": 0
                    }))),
                    "sliver": new SliverGrid({
                      "gridDelegate": (this.__k17 || (this.__k17 = new SliverGridDelegateWithMaxCrossAxisExtent({
                        "crossAxisSpacing": 10,
                        "mainAxisExtent": 190,
                        "mainAxisSpacing": 10,
                        "maxCrossAxisExtent": 300
                      }))),
                      "delegate": {
                        "__delegate": "builder",
                        "builder": (context, index) => new SpotCard({
                          "spot": this._feed.spots[index]
                        }),
                        "childCount": this._feed.spots.length
                      }
                    })
                  }),
                  (this.__k18 || (this.__k18 = new SliverToBoxAdapter({
                    "child": new SizedBox({
                      "height": 20
                    })
                  })))
                ]
              })
            })
          })
        ]
      })
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
    this.city = (args && args.city !== undefined) ? args.city : '';
    this.onPickCity = (args && args.onPickCity !== undefined) ? args.onPickCity : null;
  }
  openSearch() {
    _app_host_.invoke("openSearch", []);
  }
  openMessages() {
    _app_host_.invoke("openNotifications", []);
  }
  build(context) {
    return new Container({
      "padding": (this.__k0 || (this.__k0 = EdgeInsets.fromLTRB({
        "bottom": 16,
        "left": 16,
        "right": 16,
        "top": 14
      }))),
      "decoration": (this.__k1 || (this.__k1 = new BoxDecoration({
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
        "child": new Column({
          "crossAxisAlignment": CrossAxisAlignment.start,
          "children": [
            new Row({
              "children": [
                new InkWell({
                  "onTap": this.__bindFn(0, [], (...__a) => this.onPickCity(...__a)),
                  "child": new Row({
                    "children": [
                      (this.__k2 || (this.__k2 = new Icon({
                        "color": new Color({
                          "value": 0xFFFFFFFF
                        }),
                        "icon": "location_on",
                        "size": 18
                      }))),
                      (this.__k3 || (this.__k3 = new SizedBox({
                        "width": 2
                      }))),
                      new Text({
                        "style": (this.__k4 || (this.__k4 = new TextStyle({
                          "color": new Color({
                            "value": 0xFFFFFFFF
                          }),
                          "fontSize": 15,
                          "fontWeight": FontWeight.w600
                        }))),
                        "data": this.city
                      }),
                      (this.__k5 || (this.__k5 = new Icon({
                        "color": new Color({
                          "value": 0xFFFFFFFF
                        }),
                        "icon": "keyboard_arrow_down",
                        "size": 18
                      })))
                    ]
                  })
                }),
                (this.__k6 || (this.__k6 = new Spacer({}))),
                new InkWell({
                  "onTap": this.__bindFn(1, [], (...__a) => this.onRefresh(...__a)),
                  "borderRadius": (this.__k7 || (this.__k7 = BorderRadius.all({
                    "radius": Radius.circular({
                      "radius": 18
                    })
                  }))),
                  "child": (this.__k8 || (this.__k8 = new Padding({
                    "child": new Icon({
                      "color": new Color({
                        "value": 0xFFFFFFFF
                      }),
                      "size": 24,
                      "icon": "refresh"
                    }),
                    "padding": EdgeInsets.all({
                      "value": 4
                    })
                  })))
                }),
                (this.__k9 || (this.__k9 = new SizedBox({
                  "width": 8
                }))),
                new InkWell({
                  "onTap": this.__bindFn(2, [], (...__a) => this.openMessages(...__a)),
                  "borderRadius": (this.__k7 || (this.__k7 = BorderRadius.all({
                    "radius": Radius.circular({
                      "radius": 18
                    })
                  }))),
                  "child": (this.__k10 || (this.__k10 = new Stack({
                    "children": [
                      new Padding({
                        "padding": EdgeInsets.all({
                          "value": 4
                        }),
                        "child": new Icon({
                          "color": new Color({
                            "value": 0xFFFFFFFF
                          }),
                          "size": 24,
                          "icon": "notifications"
                        })
                      }),
                      new Positioned({
                        "right": 3,
                        "top": 3,
                        "child": new DecoratedBox({
                          "decoration": new BoxDecoration({
                            "color": new Color({
                              "value": 0xFFFF5A36
                            }),
                            "borderRadius": BorderRadius.all({
                              "radius": Radius.circular({
                                "radius": 4
                              })
                            })
                          }),
                          "child": new SizedBox({
                            "width": 8,
                            "height": 8
                          })
                        })
                      })
                    ]
                  })))
                })
              ]
            }),
            (this.__k11 || (this.__k11 = new SizedBox({
              "height": 12
            }))),
            new InkWell({
              "onTap": this.__bindFn(3, [], (...__a) => this.openSearch(...__a)),
              "borderRadius": (this.__k12 || (this.__k12 = BorderRadius.all({
                "radius": Radius.circular({
                  "radius": 20
                })
              }))),
              "child": new Container({
                "height": 42,
                "padding": (this.__k13 || (this.__k13 = EdgeInsets.symmetric({
                  "horizontal": 14
                }))),
                "decoration": (this.__k14 || (this.__k14 = new BoxDecoration({
                  "borderRadius": BorderRadius.all({
                    "radius": Radius.circular({
                      "radius": 21
                    })
                  }),
                  "color": new Color({
                    "value": 0xFFFFFFFF
                  })
                }))),
                "child": (this.__k15 || (this.__k15 = new Row({
                  "children": [
                    new Icon({
                      "color": new Color({
                        "value": 0xFF9AA0AC
                      }),
                      "size": 20,
                      "icon": "search"
                    }),
                    new SizedBox({
                      "width": 6
                    }),
                    new Text({
                      "style": new TextStyle({
                        "fontSize": 14,
                        "color": new Color({
                          "value": 0xFF9AA0AC
                        })
                      }),
                      "data": "搜索目的地 / 关键词"
                    }),
                    new Spacer({}),
                    new Text({
                      "style": new TextStyle({
                        "fontSize": 13,
                        "color": new Color({
                          "value": 0xFF0E7AFB
                        }),
                        "fontWeight": FontWeight.w600
                      }),
                      "data": "搜索"
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
    _app_host_.invoke("openChannel", [this.entry.title, this.entry.emoji]);
  }
  build(context) {
    return new InkWell({
      "onTap": this.__bindFn(0, [], (...__a) => this.open(...__a)),
      "child": new Column({
        "mainAxisAlignment": MainAxisAlignment.center,
        "children": [
          new Text({
            "style": (this.__k0 || (this.__k0 = new TextStyle({
              "fontSize": 22
            }))),
            "data": this.entry.emoji
          }),
          (this.__k1 || (this.__k1 = new SizedBox({
            "height": 6
          }))),
          new Text({
            "style": (this.__k2 || (this.__k2 = new TextStyle({
              "color": new Color({
                "value": 0xFF4D5462
              }),
              "fontSize": 12
            }))),
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
      "borderRadius": (this.__k0 || (this.__k0 = BorderRadius.all({
        "radius": Radius.circular({
          "radius": 14
        })
      }))),
      "child": new Container({
        "decoration": (this.__k1 || (this.__k1 = new BoxDecoration({
          "borderRadius": BorderRadius.all({
            "radius": Radius.circular({
              "radius": 14
            })
          }),
          "color": new Color({
            "value": 0xFFFFFFFF
          })
        }))),
        "clipBehavior": Clip.antiAlias,
        "child": new Column({
          "crossAxisAlignment": CrossAxisAlignment.start,
          "children": [
            new SizedBox({
              "height": 96,
              "child": new Stack({
                "fit": StackFit.expand,
                "children": [
                  Image.asset({
                    "fit": BoxFit.cover,
                    "name": this.spot.img
                  }),
                  new Positioned({
                    "left": 8,
                    "top": 8,
                    "child": new Container({
                      "padding": (this.__k2 || (this.__k2 = EdgeInsets.symmetric({
                        "horizontal": 6,
                        "vertical": 2
                      }))),
                      "decoration": (this.__k3 || (this.__k3 = new BoxDecoration({
                        "borderRadius": BorderRadius.all({
                          "radius": Radius.circular({
                            "radius": 6
                          })
                        }),
                        "color": new Color({
                          "value": 0xFFFF5A36
                        })
                      }))),
                      "child": new Text({
                        "style": (this.__k4 || (this.__k4 = new TextStyle({
                          "color": new Color({
                            "value": 0xFFFFFFFF
                          }),
                          "fontSize": 10,
                          "fontWeight": FontWeight.w600
                        }))),
                        "data": this.spot.tag
                      })
                    })
                  })
                ]
              })
            }),
            new Padding({
              "padding": (this.__k5 || (this.__k5 = EdgeInsets.fromLTRB({
                "bottom": 10,
                "left": 10,
                "right": 10,
                "top": 8
              }))),
              "child": new Column({
                "crossAxisAlignment": CrossAxisAlignment.start,
                "children": [
                  new Text({
                    "maxLines": 1,
                    "overflow": TextOverflow.ellipsis,
                    "style": (this.__k6 || (this.__k6 = new TextStyle({
                      "color": new Color({
                        "value": 0xFF1F2430
                      }),
                      "fontSize": 14,
                      "fontWeight": FontWeight.w600
                    }))),
                    "data": this.spot.title
                  }),
                  (this.__k7 || (this.__k7 = new SizedBox({
                    "height": 4
                  }))),
                  new Text({
                    "maxLines": 1,
                    "overflow": TextOverflow.ellipsis,
                    "style": (this.__k8 || (this.__k8 = new TextStyle({
                      "color": new Color({
                        "value": 0xFF8A909E
                      }),
                      "fontSize": 11
                    }))),
                    "data": this.spot.sub
                  }),
                  (this.__k9 || (this.__k9 = new SizedBox({
                    "height": 8
                  }))),
                  new Row({
                    "children": [
                      (this.__k10 || (this.__k10 = new Text({
                        "data": "¥",
                        "style": new TextStyle({
                          "fontSize": 11,
                          "color": new Color({
                            "value": 0xFFFF5A36
                          }),
                          "fontWeight": FontWeight.w700
                        })
                      }))),
                      new Text({
                        "style": (this.__k11 || (this.__k11 = new TextStyle({
                          "color": new Color({
                            "value": 0xFFFF5A36
                          }),
                          "fontSize": 17,
                          "fontWeight": FontWeight.w700
                        }))),
                        "data": this.spot.price
                      }),
                      (this.__k12 || (this.__k12 = new Spacer({}))),
                      new Text({
                        "style": (this.__k13 || (this.__k13 = new TextStyle({
                          "color": new Color({
                            "value": 0xFF9AA0AC
                          }),
                          "fontSize": 10
                        }))),
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
      "borderRadius": (this.__k0 || (this.__k0 = BorderRadius.all({
        "radius": Radius.circular({
          "radius": 14
        })
      }))),
      "child": new SizedBox({
        "height": 96,
        "child": new ClipRRect({
          "borderRadius": (this.__k0 || (this.__k0 = BorderRadius.all({
            "radius": Radius.circular({
              "radius": 14
            })
          }))),
          "child": new Stack({
            "fit": StackFit.expand,
            "children": [
              Image.asset({
                "fit": BoxFit.cover,
                "name": this.img
              }),
              new Positioned({
                "left": 16,
                "top": 22,
                "child": new Column({
                  "crossAxisAlignment": CrossAxisAlignment.start,
                  "children": [
                    (this.__k1 || (this.__k1 = new Text({
                      "data": "热气球季 · 限时特惠",
                      "style": new TextStyle({
                        "color": new Color({
                          "value": 0xFFFFFFFF
                        }),
                        "fontSize": 16,
                        "fontWeight": FontWeight.w700
                      })
                    }))),
                    (this.__k2 || (this.__k2 = new SizedBox({
                      "height": 6
                    }))),
                    new Container({
                      "padding": (this.__k3 || (this.__k3 = EdgeInsets.symmetric({
                        "horizontal": 10,
                        "vertical": 4
                      }))),
                      "decoration": (this.__k4 || (this.__k4 = new BoxDecoration({
                        "borderRadius": BorderRadius.all({
                          "radius": Radius.circular({
                            "radius": 12
                          })
                        }),
                        "color": new Color({
                          "value": 0xE6FFFFFF
                        })
                      }))),
                      "child": (this.__k5 || (this.__k5 = new Text({
                        "data": "立即查看 >",
                        "style": new TextStyle({
                          "fontSize": 11,
                          "color": new Color({
                            "value": 0xFF0E7AFB
                          }),
                          "fontWeight": FontWeight.w600
                        })
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

