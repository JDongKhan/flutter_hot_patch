// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/app/floors/promo_floor.dart 自动生成
// 重新生成：dart run build_runner build

import { AppService } from '../service/app_service.js';
import { WebView } from '../../base/web_view.js';
import { FloorLoadingView } from 'floor_status.js';
import { FloorErrorView } from 'floor_status.js';
import { BorderRadius, BoxDecoration, BoxFit, ChangeNotifier, ClipRRect, Color, Column, Container, CrossAxisAlignment, EdgeInsets, FontWeight, Image, InkWell, Padding, Positioned, Radius, SizedBox, Stack, StackFit, StatelessWidget, Text, TextStyle } from '../../flutter.js';
import { ChangeNotifierProvider } from '../../provider.js';

// 模型 PromoFloorVm
export class PromoFloorVm extends ChangeNotifier {
  constructor(args) {
    super(args);
    this.__applyProps(args);
    this.loading = true;
    this.error = null;
    this._service = new AppService();
    this.img = "";
  }
  __applyProps(args) {
    this.city = (args && args.city !== undefined) ? args.city : '';
  }
  async load() {
    this.loading = true;
    this.error = null;
    this.notifyListeners();
    try {
      this.img = await this._service.fetchHomePromo(this.city);
      this.error = null;
    } catch (e) {
      print("PromoFloor 加载失败: " + e);
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

// 组件 PromoFloor
export class PromoFloor extends StatelessWidget {
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
      "child": (this.__k0 || (this.__k0 = new PromoFloorView({}))),
      "typeArguments": {"T": "PromoFloorVm"}
    });
  }
}

// 组件 PromoFloorView
export class PromoFloorView extends StatelessWidget {
  constructor(args) {
    super(args);
  }
  build(context) {
    var vm = context.watch({ typeArguments: {"T": "PromoFloorVm"} });
    var body;
    if (vm.loading) {
      body = (this.__k0 || (this.__k0 = new FloorLoadingView({
        "height": 96
      })));
    } else {
      if ((vm.error != null)) {
        body = new FloorErrorView({
          "message": vm.error,
          "onRetry": (...__a) => vm.load(...__a),
          "height": 96
        });
      } else {
        body = new PromoCard({
          "img": vm.img
        });
      }
    }
    return new Padding({
      "padding": (this.__k1 || (this.__k1 = EdgeInsets.fromLTRB({
        "bottom": 16,
        "left": 12,
        "right": 12,
        "top": 0
      }))),
      "child": body
    });
  }
}

// 组件 PromoCard
export class PromoCard extends StatelessWidget {
  constructor(args) {
    super(args);
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.img = (args && args.img !== undefined) ? args.img : '';
  }
  open() {
    WebView.open("https://flutter.dev", "活动详情");
  }
  build(context) {
    return new InkWell({
      "onTap": () => this.open(),
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

