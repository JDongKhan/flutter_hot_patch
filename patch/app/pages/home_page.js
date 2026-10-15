// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/app/pages/home_page.dart 自动生成
// 重新生成：dart run build_runner build

import { HomeBanner } from '../model/app_models.js';
import { GridEntry } from '../model/app_models.js';
import { Spot } from '../model/app_models.js';
import { kAdImg, kBanners, kGrid, kSpots } from '../model/app_data.js';
import { SliverGrid, __h } from '../../flutter.js';

// 组件 HomePage
export class HomePage {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.banners = (args && args.banners !== undefined) ? args.banners : kBanners;
    this.grid = (args && args.grid !== undefined) ? args.grid : kGrid;
    this.spots = (args && args.spots !== undefined) ? args.spots : kSpots;
    this.adImg = (args && args.adImg !== undefined) ? args.adImg : kAdImg;
  }
  build(context) {
    return __h('Container', {
        "color": '#fff4f5f7'
      }, [
        __h('CustomScrollView', {}, [
            __h('SliverToBoxAdapter', {}, [
                __h('Column', {
                    "crossAxisAlignment": "stretch"
                  }, [
                    __h(HomeHeader, {}),
                    __h('SizedBox', {
                        "height": 12
                      }),
                    __h('SizedBox', {
                        "height": 150
                      }, [
                        __h('PageView', {}, [
                            ...(() => { var out = []; for (let i = 0; (i < this.banners.length); (i++)) { out.push.apply(out, [__h(BannerSlide, { "banner": this.banners[i] })]); } return out; })()
                          ])
                      ]),
                    __h('SizedBox', {
                        "height": 10
                      }),
                    __h('Row', {
                        "mainAxisAlignment": "center"
                      }, [
                        ...(() => { var out = []; for (let i = 0; (i < this.banners.length); (i++)) { out.push.apply(out, [__h('Container', { "width": 6, "height": 6, "margin": { "left": 3.0, "top": 0.0, "right": 3.0, "bottom": 0.0 }, "decoration": { "color": ((i == 0) ? '#ff0e7afb' : '#ffd5d9e0'), "borderRadius": { "radius": 3.0 } } })]); } return out; })()
                      ]),
                    __h('SizedBox', {
                        "height": 12
                      }),
                    __h('Container', {
                        "padding": {
                          "left": 0.0,
                          "top": 12.0,
                          "right": 0.0,
                          "bottom": 12.0
                        },
                        "margin": {
                          "left": 12.0,
                          "top": 0.0,
                          "right": 12.0,
                          "bottom": 0.0
                        },
                        "decoration": {
                          "color": '#ffffffff',
                          "borderRadius": {
                            "radius": 14.0
                          }
                        }
                      }, [
                        __h('GridView', {
                            "shrinkWrap": true,
                            "physics": "NeverScrollableScrollPhysics",
                            "maxCrossAxisExtent": 150,
                            "mainAxisSpacing": 6,
                            "crossAxisSpacing": 6,
                            "mainAxisExtent": 84
                          }, [
                            ...(() => { var out = []; for (let i = 0; (i < this.grid.length); (i++)) { out.push.apply(out, [__h(GridCell, { "entry": this.grid[i] })]); } return out; })()
                          ])
                      ]),
                    __h('SizedBox', {
                        "height": 12
                      }),
                    __h('Container', {
                        "margin": {
                          "left": 12.0,
                          "top": 0.0,
                          "right": 12.0,
                          "bottom": 0.0
                        }
                      }, [
                        __h(PromoCard, {
                            "img": this.adImg
                          })
                      ]),
                    __h('SizedBox', {
                        "height": 16
                      }),
                    __h('Padding', {
                        "padding": {
                          "left": 14.0,
                          "top": 0.0,
                          "right": 14.0,
                          "bottom": 0.0
                        }
                      }, [
                        __h('Row', {}, [
                            __h('Container', {
                                "width": 4,
                                "height": 16,
                                "decoration": {
                                  "color": '#ff0e7afb',
                                  "borderRadius": {
                                    "radius": 2.0
                                  }
                                }
                              }),
                            __h('SizedBox', {
                                "width": 8
                              }),
                            __h('Text', {
                                "data": "景点推荐",
                                "style": {
                                  "fontSize": 17,
                                  "fontWeight": "w700",
                                  "color": '#ff1f2430'
                                }
                              }),
                            __h('Spacer', {}),
                            __h('Text', {
                                "data": "为你精选",
                                "style": {
                                  "fontSize": 12,
                                  "color": '#ff8a909e'
                                }
                              })
                          ])
                      ]),
                    __h('SizedBox', {
                        "height": 10
                      })
                  ])
              ]),
            __h('SliverPadding', {
                "padding": {
                  "left": 12.0,
                  "top": 0.0,
                  "right": 12.0,
                  "bottom": 0.0
                }
              }, [
                __h(SliverGrid, {
                    "builder": "_sliverBuilder0",
                    "childCount": this.spots.length,
                    "maxCrossAxisExtent": 300,
                    "mainAxisSpacing": 10,
                    "crossAxisSpacing": 10,
                    "mainAxisExtent": 190
                  })
              ]),
            __h('SliverToBoxAdapter', {}, [
                __h('SizedBox', {
                    "height": 20
                  })
              ])
          ])
      ]);
  }
  _sliverBuilder0(index) {
      return __h(SpotCard, {
        "spot": this.spots[index]
      });
  }
}

// 组件 HomeHeader
export class HomeHeader {
  constructor() {
  }
  openSearch() {
    __jsui.host("openSearch", []);
  }
  openMessages() {
    __jsui.host("toast", ["暂无新消息"]);
  }
  openLocation() {
    __jsui.host("toast", ["定位：上海市 · 点击切换城市"]);
  }
  build(context) {
    return __h('Container', {
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
        }
      }, [
        __h('SafeArea', {
            "bottom": false
          }, [
            __h('Column', {
                "crossAxisAlignment": "start"
              }, [
                __h('Row', {}, [
                    __h('InkWell', {
                        "event": this.__bind("openLocation")
                      }, [
                        __h('Row', {}, [
                            __h('Icon', {
                                "icon": "location_on",
                                "size": 18,
                                "color": '#ffffffff'
                              }),
                            __h('SizedBox', {
                                "width": 2
                              }),
                            __h('Text', {
                                "data": "上海",
                                "style": {
                                  "color": '#ffffffff',
                                  "fontSize": 15,
                                  "fontWeight": "w600"
                                }
                              }),
                            __h('Icon', {
                                "icon": "keyboard_arrow_down",
                                "size": 18,
                                "color": '#ffffffff'
                              })
                          ])
                      ]),
                    __h('Spacer', {}),
                    __h('InkWell', {
                        "event": this.__bind("openMessages")
                      }, [
                        __h('Stack', {}, [
                            __h('Padding', {
                                "padding": {
                                  "left": 4.0,
                                  "top": 4.0,
                                  "right": 4.0,
                                  "bottom": 4.0
                                }
                              }, [
                                __h('Icon', {
                                    "icon": "notifications",
                                    "size": 24,
                                    "color": '#ffffffff'
                                  })
                              ]),
                            __h('Positioned', {
                                "top": 3,
                                "right": 3
                              }, [
                                __h('DecoratedBox', {
                                    "decoration": {
                                      "color": '#ffff5a36',
                                      "borderRadius": {
                                        "radius": 4.0
                                      }
                                    }
                                  }, [
                                    __h('SizedBox', {
                                        "height": 8,
                                        "width": 8
                                      })
                                  ])
                              ])
                          ])
                      ])
                  ]),
                __h('SizedBox', {
                    "height": 12
                  }),
                __h('InkWell', {
                    "event": this.__bind("openSearch")
                  }, [
                    __h('Container', {
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
                        }
                      }, [
                        __h('Row', {}, [
                            __h('Icon', {
                                "icon": "search",
                                "size": 20,
                                "color": '#ff9aa0ac'
                              }),
                            __h('SizedBox', {
                                "width": 6
                              }),
                            __h('Text', {
                                "data": "搜索目的地 / 关键词",
                                "style": {
                                  "fontSize": 14,
                                  "color": '#ff9aa0ac'
                                }
                              }),
                            __h('Spacer', {}),
                            __h('Text', {
                                "data": "搜索",
                                "style": {
                                  "fontSize": 13,
                                  "color": '#ff0e7afb',
                                  "fontWeight": "w600"
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

// 组件 BannerSlide
export class BannerSlide {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.banner = (args && args.banner !== undefined) ? args.banner : null;
  }
  open() {
    __jsui.host("toast", [this.banner.title]);
  }
  build(context) {
    return __h('Padding', {
        "padding": {
          "left": 12.0,
          "top": 0.0,
          "right": 12.0,
          "bottom": 0.0
        }
      }, [
        __h('InkWell', {
            "event": this.__bind("open")
          }, [
            __h('ClipRRect', {
                "child": __h('Stack', {
                    "fit": "expand"
                  }, [
                    __h('Image', {
                        "source": this.banner.img,
                        "fit": "cover"
                      }),
                    __h('Container', {
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
                    __h('Positioned', {
                        "left": 14,
                        "right": 14,
                        "bottom": 14
                      }, [
                        __h('Column', {
                            "crossAxisAlignment": "start"
                          }, [
                            __h('Text', {
                                "data": this.banner.title,
                                "style": {
                                  "color": '#ffffffff',
                                  "fontSize": 17,
                                  "fontWeight": "w700"
                                }
                              }),
                            __h('SizedBox', {
                                "height": 4
                              }),
                            __h('Text', {
                                "data": this.banner.sub,
                                "style": {
                                  "color": '#e6ffffff',
                                  "fontSize": 12
                                }
                              })
                          ])
                      ])
                  ])
              })
          ])
      ]);
  }
}

// 组件 GridCell
export class GridCell {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.entry = (args && args.entry !== undefined) ? args.entry : null;
  }
  open() {
    __jsui.host("toast", [this.entry.title + " 频道"]);
  }
  build(context) {
    return __h('InkWell', {
        "event": this.__bind("open")
      }, [
        __h('Column', {
            "mainAxisAlignment": "center"
          }, [
            __h('Text', {
                "data": this.entry.emoji,
                "style": {
                  "fontSize": 22
                }
              }),
            __h('SizedBox', {
                "height": 6
              }),
            __h('Text', {
                "data": this.entry.title,
                "style": {
                  "fontSize": 12,
                  "color": '#ff4d5462'
                }
              })
          ])
      ]);
  }
}

// 组件 SpotCard
export class SpotCard {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.spot = (args && args.spot !== undefined) ? args.spot : null;
  }
  open() {
    __jsui.host("openSpot", [this.spot.id]);
  }
  build(context) {
    return __h('InkWell', {
        "event": this.__bind("open")
      }, [
        __h('Container', {
            "decoration": {
              "color": '#ffffffff',
              "borderRadius": {
                "radius": 14.0
              }
            },
            "clipBehavior": "antiAlias"
          }, [
            __h('Column', {
                "crossAxisAlignment": "start"
              }, [
                __h('SizedBox', {
                    "height": 96
                  }, [
                    __h('Stack', {
                        "fit": "expand"
                      }, [
                        __h('Image', {
                            "source": this.spot.img,
                            "fit": "cover"
                          }),
                        __h('Positioned', {
                            "left": 8,
                            "top": 8
                          }, [
                            __h('Container', {
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
                                }
                              }, [
                                __h('Text', {
                                    "data": this.spot.tag,
                                    "style": {
                                      "color": '#ffffffff',
                                      "fontSize": 10,
                                      "fontWeight": "w600"
                                    }
                                  })
                              ])
                          ])
                      ])
                  ]),
                __h('Padding', {
                    "padding": {
                      "left": 10.0,
                      "top": 8.0,
                      "right": 10.0,
                      "bottom": 10.0
                    }
                  }, [
                    __h('Column', {
                        "crossAxisAlignment": "start"
                      }, [
                        __h('Text', {
                            "data": this.spot.title,
                            "style": {
                              "fontSize": 14,
                              "fontWeight": "w600",
                              "color": '#ff1f2430'
                            },
                            "maxLines": 1,
                            "overflow": "ellipsis"
                          }),
                        __h('SizedBox', {
                            "height": 4
                          }),
                        __h('Text', {
                            "data": this.spot.sub,
                            "style": {
                              "fontSize": 11,
                              "color": '#ff8a909e'
                            },
                            "maxLines": 1,
                            "overflow": "ellipsis"
                          }),
                        __h('SizedBox', {
                            "height": 8
                          }),
                        __h('Row', {}, [
                            __h('Text', {
                                "data": "¥",
                                "style": {
                                  "fontSize": 11,
                                  "color": '#ffff5a36',
                                  "fontWeight": "w700"
                                }
                              }),
                            __h('Text', {
                                "data": this.spot.price,
                                "style": {
                                  "fontSize": 17,
                                  "color": '#ffff5a36',
                                  "fontWeight": "w700"
                                }
                              }),
                            __h('Spacer', {}),
                            __h('Text', {
                                "data": this.spot.sold,
                                "style": {
                                  "fontSize": 10,
                                  "color": '#ff9aa0ac'
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

// 组件 PromoCard
export class PromoCard {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.img = (args && args.img !== undefined) ? args.img : '';
  }
  open() {
    __jsui.host("open", ["https://flutter.dev", "活动详情"]);
  }
  build(context) {
    return __h('InkWell', {
        "event": this.__bind("open")
      }, [
        __h('SizedBox', {
            "height": 96
          }, [
            __h('ClipRRect', {
                "child": __h('Stack', {
                    "fit": "expand"
                  }, [
                    __h('Image', {
                        "source": this.img,
                        "fit": "cover"
                      }),
                    __h('Positioned', {
                        "left": 16,
                        "top": 22
                      }, [
                        __h('Column', {
                            "crossAxisAlignment": "start"
                          }, [
                            __h('Text', {
                                "data": "热气球季 · 限时特惠",
                                "style": {
                                  "color": '#ffffffff',
                                  "fontSize": 16,
                                  "fontWeight": "w700"
                                }
                              }),
                            __h('SizedBox', {
                                "height": 6
                              }),
                            __h('Container', {
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
                                }
                              }, [
                                __h('Text', {
                                    "data": "立即查看 >",
                                    "style": {
                                      "fontSize": 11,
                                      "color": '#ff0e7afb',
                                      "fontWeight": "w600"
                                    }
                                  })
                              ])
                          ])
                      ])
                  ])
              })
          ])
      ]);
  }
}

