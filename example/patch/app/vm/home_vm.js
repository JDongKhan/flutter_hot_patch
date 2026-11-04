// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/app/vm/home_vm.dart 自动生成
// 重新生成：dart run build_runner build

import { AppService } from '../service/app_service.js';
import { HomeFloor } from '../floors/floor_base.js';
import { HomeFloorConfig } from '../model/app_models.js';
import { BannerFloorVm } from '../floors/banner_floor.js';
import { GridFloorVm } from '../floors/grid_floor.js';
import { SpotFloorVm } from '../floors/spot_floor.js';
import { PromoFloorVm } from '../floors/promo_floor.js';
import { ChangeNotifier } from '../../flutter.js';

// 模型 HomeVm
export class HomeVm extends ChangeNotifier {
  constructor(args) {
    super(args);
    this._service = new AppService();
    this.city = "上海";
    this.floors = [];
    this.loading = true;
    this.error = null;
  }
  async load() {
    this.loading = true;
    this.error = null;
    this.notifyListeners();
    try {
      var configs = await this._service.fetchHomeFloors();
      if (this.floors.isEmpty) {
        var list = [];
        for (let c of configs) {
          var vm = this._createFloor(c.type);
          if ((vm == null)) {
            print("HomeVm 未知楼层类型：" + c.type + "，已跳过");
            continue;
          }
          vm.load();
          list.add(new HomeFloor({type: c.type, vm: vm}));
        }
        this.floors = list;
      }
      this.error = null;
    } catch (e) {
      print("HomeVm 楼层配置加载失败: " + e);
      this.error = e.toString();
    }
    this.loading = false;
    this.notifyListeners();
  }
  async refresh() {
    for (let floor of this.floors) {
      await floor.vm.refresh();
    }
  }
  async changeCity(newCity) {
    if ((newCity == this.city)) {
      return;
    }
    this.city = newCity;
    this.notifyListeners();
    for (let floor of this.floors) {
      await floor.vm.setCity(newCity);
    }
  }
  _createFloor(type) {
    switch (type) {
      case "banner":
      return new BannerFloorVm({city: this.city});
      case "grid":
      return new GridFloorVm({city: this.city});
      case "spots":
      return new SpotFloorVm({city: this.city});
      case "promo":
      return new PromoFloorVm({city: this.city});
    }
    return null;
  }
  dispose() {
    for (let floor of this.floors) {
      floor.vm.dispose();
    }
    this.floors = [];
    super.dispose();
  }
}

