// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/app/pages/home_page.dart 自动生成
// 重新生成：dart run build_runner build

import { HomeVm } from '../vm/home_vm.js';
import { AppRouter } from '../../base/app_router.js';
import { HomeFloor } from '../floors/floor_base.js';
import { LoadErrorView } from '../widgets/load_error_view.js';
import { BannerFloor } from '../floors/banner_floor.js';
import { GridFloor } from '../floors/grid_floor.js';
import { SpotFloor } from '../floors/spot_floor.js';
import { PromoFloor } from '../floors/promo_floor.js';
import { Alignment, BorderRadius, BoxDecoration, Center, CircularProgressIndicator, Color, Column, Container, CrossAxisAlignment, CustomScrollView, DecoratedBox, EasyRefresh, EasyRefreshController, EdgeInsets, Expanded, FontWeight, Icon, Icons, InkWell, LinearGradient, Padding, Positioned, Radius, Row, SafeArea, SizedBox, SliverToBoxAdapter, Spacer, Stack, StatefulWidget, StatelessWidget, Text, TextStyle } from '../../flutter.js';
import { ChangeNotifierProvider } from '../../provider.js';

// 组件 HomePage
export class HomePage extends StatelessWidget {
  constructor(args) {
    super(args);
  }
  build(context) {
    return new ChangeNotifierProvider({
      "create": (_) => { return (() => { const _t = new HomeVm(); _t.load(); return _t; })(); },
      "child": (this.__k0 || (this.__k0 = new HomeView({}))),
      "typeArguments": {"T": "HomeVm"}
    });
  }
}

// 组件 HomeView
export class HomeView extends StatefulWidget {
  constructor(args) {
    super(args);
    this._refreshController = new EasyRefreshController();
  }
  dispose() {
    this._refreshController.dispose();
    super.dispose();
  }
  async _onRefresh() {
    await this.context.read({ typeArguments: {"T": "HomeVm"} }).refresh();
  }
  _refresh() {
    this._refreshController.callRefresh();
  }
  async _pickCity() {
    const vm = this.context.read({ typeArguments: {"T": "HomeVm"} });
    const picked = await AppRouter.openCityPicker(vm.city);
    if ((__nn(picked) == null)) {
      return;
    }
    await vm.changeCity(picked);
  }
  build(context) {
    const vm = context.watch({ typeArguments: {"T": "HomeVm"} });
    if (vm.loading) {
      return (this.__k0 || (this.__k0 = new Center({
        "child": new CircularProgressIndicator({})
      })));
    }
    const error = vm.error;
    if ((__nn(error) != null)) {
      return new LoadErrorView({
        "message": error,
        "onRetry": (...__a) => vm.load(...__a)
      });
    }
    return new Container({
      "color": (this.__k1 || (this.__k1 = new Color({
        "value": 0xFFF4F5F7
      }))),
      "child": new Column({
        "crossAxisAlignment": CrossAxisAlignment.stretch,
        "children": [
          new HomeHeader({
            "city": vm.city,
            "onRefresh": () => this._refresh(),
            "onPickCity": () => this._pickCity()
          }),
          new Expanded({
            "child": new EasyRefresh({
              "controller": this._refreshController,
              "onRefresh": () => this._onRefresh(),
              "child": new CustomScrollView({
                "slivers": [
                  new SliverToBoxAdapter({
                    "child": new Column({
                      "crossAxisAlignment": CrossAxisAlignment.stretch,
                      "children": [
                        ...(() => { var out = []; for (let floor of vm.floors) { out.push.apply(out, [new FloorSlot({
                                "floor": floor
                              })]); } return out; })()
                      ]
                    })
                  })
                ]
              })
            })
          })
        ]
      })
    });
  }
}

// 组件 FloorSlot
export class FloorSlot extends StatelessWidget {
  constructor(args) {
    super(args);
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.floor = (args && args.floor !== undefined) ? args.floor : null;
  }
  build(context) {
    const type = this.floor.type;
    if ((type === "banner")) {
      return new BannerFloor({
        "vm": this.floor.vm
      });
    }
    if ((type === "grid")) {
      return new GridFloor({
        "vm": this.floor.vm
      });
    }
    if ((type === "spots")) {
      return new SpotFloor({
        "vm": this.floor.vm
      });
    }
    if ((type === "promo")) {
      return new PromoFloor({
        "vm": this.floor.vm
      });
    }
    print("FloorSlot 未知楼层类型：" + type);
    return new Text({
      "style": (this.__k0 || (this.__k0 = new TextStyle({
        "color": new Color({
          "value": 0xFF8A909E
        }),
        "fontSize": 12
      }))),
      "data": "未知楼层类型：" + this.floor.type
    });
  }
}

// 组件 HomeHeader
export class HomeHeader extends StatelessWidget {
  constructor(args) {
    super(args);
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.onRefresh = (args && args.onRefresh !== undefined) ? args.onRefresh : null;
    this.city = (args && args.city !== undefined) ? args.city : '';
    this.onPickCity = (args && args.onPickCity !== undefined) ? args.onPickCity : null;
  }
  openSearch() {
    AppRouter.openSearch();
  }
  openMessages() {
    AppRouter.openNotifications();
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
                  "onTap": this.onPickCity,
                  "child": new Row({
                    "children": [
                      (this.__k2 || (this.__k2 = new Icon({
                        "color": new Color({
                          "value": 0xFFFFFFFF
                        }),
                        "icon": Icons.location_on,
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
                        "icon": Icons.keyboard_arrow_down,
                        "size": 18
                      })))
                    ]
                  })
                }),
                (this.__k6 || (this.__k6 = new Spacer({}))),
                new InkWell({
                  "onTap": this.onRefresh,
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
                      "icon": Icons.refresh
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
                  "onTap": () => this.openMessages(),
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
                          "icon": Icons.notifications
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
              "onTap": () => this.openSearch(),
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
                      "icon": Icons.search
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

