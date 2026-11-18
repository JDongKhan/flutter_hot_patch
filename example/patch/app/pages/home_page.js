// GENERATED CODE - DO NOT EDIT
// 由 dynamic_flutter_generator 从 lib/app/pages/home_page.dart 自动生成
// 重新生成：dart run build_runner build

import { HomeVm } from '../vm/home_vm.js';
import { AppRouter } from '../../base/app_router.js';
import { HomeFloor } from '../floors/floor_base.js';
import { Tracker } from '../../base/tracker.js';
import { AppRoutes } from '../../base/app_router.js';
import { LoadErrorView } from '../widgets/load_error_view.js';
import { TrackerVisibilityWidget } from '../../packages/hot_module_base/src/widgets/tracker_visibility_widget.js';
import { BannerFloor } from '../floors/banner_floor.js';
import { GridFloor } from '../floors/grid_floor.js';
import { SpotFloor } from '../floors/spot_floor.js';
import { PromoFloor } from '../floors/promo_floor.js';
import { Alignment, Axis, BorderRadius, BoxDecoration, Center, CircularProgressIndicator, Color, Column, Container, CrossAxisAlignment, CustomScrollView, DecoratedBox, EdgeInsets, FontWeight, Icon, Icons, InkWell, LinearGradient, ListenableBuilder, Padding, Positioned, Radius, Row, SafeArea, ScrollController, SizedBox, SliverToBoxAdapter, Spacer, Stack, StatefulWidget, StatelessWidget, Text, TextStyle } from '../../flutter.js';
import { ChangeNotifierProvider } from '../../packages/provider.js';
import { EasyRefresh, EasyRefreshController, IndicatorResult } from '../../packages/easy_refresh.js';

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
    this._scrollController = new ScrollController();
  }
  get _navOpacity() {
    let opacity = (this._scrollController.offset / HomeView._navFadeDistance);
    if ((opacity < 0)) {
      opacity = 0;
    }
    if ((opacity > 1)) {
      opacity = 1;
    }
    return opacity;
  }
  dispose() {
    this._scrollController.dispose();
    this._refreshController.dispose();
    super.dispose();
  }
  async _onRefresh() {
    await this.context.read({ typeArguments: {"T": "HomeVm"} }).refresh();
    return IndicatorResult.fail;
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
      "child": new Stack({
        "children": [
          Positioned.fill({
            "child": new EasyRefresh({
              "controller": this._refreshController,
              "onRefresh": () => this._onRefresh(),
              "triggerAxis": Axis.vertical,
              "child": new CustomScrollView({
                "controller": this._scrollController,
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
          }),
          new Positioned({
            "left": 0,
            "right": 0,
            "top": 0,
            "child": new ListenableBuilder({
              "listenable": this._scrollController,
              "builder": (context, child) => new HomeHeader({
                "city": vm.city,
                "navOpacity": this._navOpacity,
                "onRefresh": () => this._refresh(),
                "onPickCity": () => this._pickCity()
              })
            })
          })
        ]
      })
    });
  }
}
HomeView._navFadeDistance = 120;

// 组件 FloorSlot
export class FloorSlot extends StatelessWidget {
  constructor(args) {
    super(args);
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.floor = (args && args.floor !== undefined) ? args.floor : null;
  }
  _tracked(type, child) {
    return new TrackerVisibilityWidget({
      "onExposure": () => Tracker.exposure("home_floor_exposure", new Map([["floor", type]])),
      "child": child
    });
  }
  build(context) {
    const type = this.floor.type;
    if ((type === "banner")) {
      return this._tracked(type, new BannerFloor({
        "vm": this.floor.vm
      }));
    }
    if ((type === "grid")) {
      return this._tracked(type, new GridFloor({
        "vm": this.floor.vm
      }));
    }
    if ((type === "spots")) {
      return this._tracked(type, new SpotFloor({
        "vm": this.floor.vm
      }));
    }
    if ((type === "promo")) {
      return this._tracked(type, new PromoFloor({
        "vm": this.floor.vm
      }));
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
    this.navOpacity = (args && args.navOpacity !== undefined) ? args.navOpacity : 0;
    this.onPickCity = (args && args.onPickCity !== undefined) ? args.onPickCity : null;
  }
  openSearch() {
    const args = new Map();
    if (kInJsRuntime) {
      __idxSet(args, "component", "SearchPage");
      __idxSet(args, "entry", "app/pages/detail_pages.js");
    }
    AppRouter.pushNamed(AppRoutes.search, args);
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
        "top": 0
      }))),
      "decoration": new BoxDecoration({
        "gradient": new LinearGradient({
          "colors": [
            new Color({value: 0xFF1E88FF}).withValues({ "alpha": this.navOpacity }),
            new Color({value: 0xFF0E7AFB}).withValues({ "alpha": this.navOpacity })
          ],
          "begin": Alignment.topLeft,
          "end": Alignment.bottomRight
        })
      }),
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
                      (this.__k1 || (this.__k1 = new Icon({
                        "color": new Color({
                          "value": 0xFFFFFFFF
                        }),
                        "icon": Icons.location_on,
                        "size": 18
                      }))),
                      (this.__k2 || (this.__k2 = new SizedBox({
                        "width": 2
                      }))),
                      new Text({
                        "style": (this.__k3 || (this.__k3 = new TextStyle({
                          "color": new Color({
                            "value": 0xFFFFFFFF
                          }),
                          "fontSize": 15,
                          "fontWeight": FontWeight.w600
                        }))),
                        "data": this.city
                      }),
                      (this.__k4 || (this.__k4 = new Icon({
                        "color": new Color({
                          "value": 0xFFFFFFFF
                        }),
                        "icon": Icons.keyboard_arrow_down,
                        "size": 18
                      })))
                    ]
                  })
                }),
                (this.__k5 || (this.__k5 = new Spacer({}))),
                new InkWell({
                  "onTap": this.onRefresh,
                  "borderRadius": (this.__k6 || (this.__k6 = BorderRadius.all({
                    "radius": Radius.circular({
                      "radius": 18
                    })
                  }))),
                  "child": (this.__k7 || (this.__k7 = new Padding({
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
                (this.__k8 || (this.__k8 = new SizedBox({
                  "width": 8
                }))),
                new InkWell({
                  "onTap": () => this.openMessages(),
                  "borderRadius": (this.__k6 || (this.__k6 = BorderRadius.all({
                    "radius": Radius.circular({
                      "radius": 18
                    })
                  }))),
                  "child": (this.__k9 || (this.__k9 = new Stack({
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
            (this.__k10 || (this.__k10 = new SizedBox({
              "height": 12
            }))),
            new InkWell({
              "onTap": () => this.openSearch(),
              "borderRadius": (this.__k11 || (this.__k11 = BorderRadius.all({
                "radius": Radius.circular({
                  "radius": 20
                })
              }))),
              "child": new Container({
                "height": 42,
                "padding": (this.__k12 || (this.__k12 = EdgeInsets.symmetric({
                  "horizontal": 14
                }))),
                "decoration": (this.__k13 || (this.__k13 = new BoxDecoration({
                  "borderRadius": BorderRadius.all({
                    "radius": Radius.circular({
                      "radius": 21
                    })
                  }),
                  "color": new Color({
                    "value": 0xFFFFFFFF
                  })
                }))),
                "child": (this.__k14 || (this.__k14 = new Row({
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

