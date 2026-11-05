// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/app/floors/grid_floor.dart 自动生成
// 重新生成：dart run build_runner build

import { AppService } from '../service/app_service.js';
import { GridEntry } from '../model/app_models.js';
import { AppRouter } from '../../base/app_router.js';
import { FloorLoadingView } from 'floor_status.js';
import { FloorErrorView } from 'floor_status.js';
import { BorderRadius, BoxDecoration, ChangeNotifier, Color, Column, Container, EdgeInsets, GridView, InkWell, MainAxisAlignment, NeverScrollableScrollPhysics, Padding, Radius, SizedBox, SliverGridDelegateWithMaxCrossAxisExtent, StatelessWidget, Text, TextStyle } from '../../flutter.js';
import { ChangeNotifierProvider } from '../../provider.js';

// 模型 GridFloorVm
export class GridFloorVm extends ChangeNotifier {
  constructor(args) {
    super(args);
    this.__applyProps(args);
    this.loading = true;
    this.error = null;
    this._service = new AppService();
    this.grid = [];
  }
  __applyProps(args) {
    this.city = (args && args.city !== undefined) ? args.city : '';
  }
  async load() {
    this.loading = true;
    this.error = null;
    this.notifyListeners();
    try {
      this.grid = await this._service.fetchHomeGrid();
      this.error = null;
    } catch (__e) {
      var e = __e;
      print("GridFloor 加载失败: " + e);
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

// 组件 GridFloor
export class GridFloor extends StatelessWidget {
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
      "child": (this.__k0 || (this.__k0 = new GridFloorView({}))),
      "typeArguments": {"T": "GridFloorVm"}
    });
  }
}

// 组件 GridFloorView
export class GridFloorView extends StatelessWidget {
  constructor(args) {
    super(args);
  }
  build(context) {
    var vm = context.watch({ typeArguments: {"T": "GridFloorVm"} });
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
        body = new Container({
          "padding": (this.__k1 || (this.__k1 = EdgeInsets.symmetric({
            "vertical": 12
          }))),
          "decoration": (this.__k2 || (this.__k2 = new BoxDecoration({
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
            "gridDelegate": (this.__k3 || (this.__k3 = new SliverGridDelegateWithMaxCrossAxisExtent({
              "crossAxisSpacing": 6,
              "mainAxisExtent": 84,
              "mainAxisSpacing": 6,
              "maxCrossAxisExtent": 150
            }))),
            "shrinkWrap": true,
            "physics": (this.__k4 || (this.__k4 = new NeverScrollableScrollPhysics({}))),
            "children": [
              ...(() => { var out = []; for (let i = 0; (i < vm.grid.length); (i++)) { out.push.apply(out, [new GridCell({
                      "entry": vm.grid[i]
                    })]); } return out; })()
            ]
          })
        });
      }
    }
    return new Padding({
      "padding": (this.__k5 || (this.__k5 = EdgeInsets.fromLTRB({
        "bottom": 12,
        "left": 12,
        "right": 12,
        "top": 0
      }))),
      "child": body
    });
  }
}

// 组件 GridCell
export class GridCell extends StatelessWidget {
  constructor(args) {
    super(args);
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.entry = (args && args.entry !== undefined) ? args.entry : null;
  }
  open() {
    AppRouter.openChannel(this.entry.title, this.entry.emoji);
  }
  build(context) {
    return new InkWell({
      "onTap": () => this.open(),
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

