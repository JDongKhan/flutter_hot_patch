// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/app/floors/banner_floor.dart 自动生成
// 重新生成：dart run build_runner build

import { AppService } from '../service/app_service.js';
import { HomeBanner } from '../model/app_models.js';
import { FloorLoadingView } from 'floor_status.js';
import { FloorErrorView } from 'floor_status.js';
import { BannerCarousel } from '../widgets/banner_carousel.js';
import { ChangeNotifier, EdgeInsets, Padding, StatelessWidget } from '../../flutter.js';
import { ChangeNotifierProvider } from '../../provider.js';

// 模型 BannerFloorVm
export class BannerFloorVm extends ChangeNotifier {
  constructor(args) {
    super(args);
    this.__applyProps(args);
    this.loading = true;
    this.error = null;
    this._service = new AppService();
    this.banners = [];
  }
  __applyProps(args) {
    this.city = (args && args.city !== undefined) ? args.city : '';
  }
  async load() {
    this.loading = true;
    this.error = null;
    this.notifyListeners();
    try {
      this.banners = await this._service.fetchHomeBanners(this.city);
      this.error = null;
    } catch (__e) {
      const e = __e;
      print("BannerFloor 加载失败: " + e);
      this.error = e.toString();
    }
    this.loading = false;
    this.notifyListeners();
  }
  async refresh() {
  }
  async setCity(newCity) {
    if ((newCity === this.city)) {
      return;
    }
    this.city = newCity;
    await this.load();
  }
}

// 组件 BannerFloor
export class BannerFloor extends StatelessWidget {
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
      "child": (this.__k0 || (this.__k0 = new BannerFloorView({}))),
      "typeArguments": {"T": "BannerFloorVm"}
    });
  }
}

// 组件 BannerFloorView
export class BannerFloorView extends StatelessWidget {
  constructor(args) {
    super(args);
  }
  build(context) {
    const vm = context.watch({ typeArguments: {"T": "BannerFloorVm"} });
    let body = null;
    if (vm.loading) {
      body = (this.__k0 || (this.__k0 = new FloorLoadingView({
        "height": 150
      })));
    } else {
      if ((vm.error != null)) {
        body = new FloorErrorView({
          "message": vm.error,
          "onRetry": (...__a) => vm.load(...__a),
          "height": 150
        });
      } else {
        body = new BannerCarousel({
          "banners": vm.banners
        });
      }
    }
    return new Padding({
      "padding": (this.__k1 || (this.__k1 = EdgeInsets.only({
        "bottom": 12,
        "top": 12
      }))),
      "child": body
    });
  }
}

