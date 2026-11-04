// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/app/floors/spot_floor.dart 自动生成
// 重新生成：dart run build_runner build

import { AppService } from '../service/app_service.js';
import { Spot } from '../model/app_models.js';
import { AppRouter } from '../../base/app_router.js';
import { FloorLoadingView } from 'floor_status.js';
import { FloorErrorView } from 'floor_status.js';
import { BorderRadius, BoxDecoration, BoxFit, ChangeNotifier, Clip, Color, Column, Container, CrossAxisAlignment, EdgeInsets, FontWeight, GridView, Image, InkWell, NeverScrollableScrollPhysics, Padding, Positioned, Radius, Row, SizedBox, SliverGridDelegateWithMaxCrossAxisExtent, Spacer, Stack, StackFit, StatelessWidget, Text, TextOverflow, TextStyle } from '../../flutter.js';
import { ChangeNotifierProvider } from '../../provider.js';

// 模型 SpotFloorVm
export class SpotFloorVm extends ChangeNotifier {
  constructor(args) {
    super(args);
    this.__applyProps(args);
    this.loading = true;
    this.error = null;
    this._service = new AppService();
    this.spots = [];
  }
  __applyProps(args) {
    this.city = (args && args.city !== undefined) ? args.city : '';
  }
  async load() {
    this.loading = true;
    this.error = null;
    this.notifyListeners();
    try {
      this.spots = await this._service.fetchHomeSpots(this.city);
      this.error = null;
    } catch (e) {
      print("SpotFloor 加载失败: " + e);
      this.error = e.toString();
    }
    this.loading = false;
    this.notifyListeners();
  }
  async refresh() {
    await this.load();
  }
  async setCity(newCity) {
    if ((newCity == this.city)) {
      return;
    }
    this.city = newCity;
    await this.load();
  }
}

// 组件 SpotFloor
export class SpotFloor extends StatelessWidget {
  constructor(args) {
    super(args);
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.vm = (args && args.vm !== undefined) ? args.vm : null;
  }
  build(context) {
    return ChangeNotifierProvider.value({
      "value": this.vm,
      "child": (this.__k0 || (this.__k0 = new SpotFloorView({}))),
      "typeArguments": {"T": "SpotFloorVm"}
    });
  }
}

// 组件 SpotFloorView
export class SpotFloorView extends StatelessWidget {
  constructor(args) {
    super(args);
  }
  build(context) {
    var vm = context.watch({ typeArguments: {"T": "SpotFloorVm"} });
    var body;
    if (vm.loading) {
      body = (this.__k0 || (this.__k0 = new FloorLoadingView({})));
    } else {
      if ((vm.error != null)) {
        body = new FloorErrorView({
          "message": vm.error,
          "onRetry": (...__a) => vm.load(...__a)
        });
      } else {
        body = new GridView({
          "gridDelegate": (this.__k1 || (this.__k1 = new SliverGridDelegateWithMaxCrossAxisExtent({
            "crossAxisSpacing": 10,
            "mainAxisExtent": 190,
            "mainAxisSpacing": 10,
            "maxCrossAxisExtent": 300
          }))),
          "shrinkWrap": true,
          "physics": (this.__k2 || (this.__k2 = new NeverScrollableScrollPhysics({}))),
          "children": [
            ...(() => { var out = []; for (let i = 0; (i < vm.spots.length); (i++)) { out.push.apply(out, [new SpotCard({
                    "spot": vm.spots[i]
                  })]); } return out; })()
          ]
        });
      }
    }
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        new Padding({
          "padding": (this.__k3 || (this.__k3 = EdgeInsets.fromLTRB({
            "bottom": 10,
            "left": 14,
            "right": 14,
            "top": 0
          }))),
          "child": new Row({
            "children": [
              new Container({
                "width": 4,
                "height": 16,
                "decoration": (this.__k4 || (this.__k4 = new BoxDecoration({
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
              (this.__k5 || (this.__k5 = new SizedBox({
                "width": 8
              }))),
              (this.__k6 || (this.__k6 = new Text({
                "data": "景点推荐",
                "style": new TextStyle({
                  "fontSize": 17,
                  "fontWeight": FontWeight.w700,
                  "color": new Color({
                    "value": 0xFF1F2430
                  })
                })
              }))),
              (this.__k7 || (this.__k7 = new Spacer({}))),
              (this.__k8 || (this.__k8 = new Text({
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
        new Padding({
          "padding": (this.__k9 || (this.__k9 = EdgeInsets.fromLTRB({
            "bottom": 20,
            "left": 12,
            "right": 12,
            "top": 0
          }))),
          "child": body
        })
      ]
    });
  }
}

// 组件 SpotCard
export class SpotCard extends StatelessWidget {
  constructor(args) {
    super(args);
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.spot = (args && args.spot !== undefined) ? args.spot : null;
  }
  open() {
    AppRouter.openSpot(this.spot.id);
  }
  build(context) {
    return new InkWell({
      "onTap": () => this.open(),
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

