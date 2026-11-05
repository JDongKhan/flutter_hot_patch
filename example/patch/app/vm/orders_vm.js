// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/app/vm/orders_vm.dart 自动生成
// 重新生成：dart run build_runner build

import { AppService } from '../service/app_service.js';
import { OrderFeed } from '../model/app_models.js';
import { Order } from '../model/app_models.js';
import { ChangeNotifier } from '../../flutter.js';

// 模型 OrdersVm
export class OrdersVm extends ChangeNotifier {
  constructor(args) {
    super(args);
    this.__applyProps(args);
    this._service = new AppService();
    this.feed = null;
    this.orders = null;
    this.listLoading = false;
    this.feedError = null;
    this.ordersError = null;
    this.status = "";
  }
  __applyProps(args) {
    this.initialStatus = (args && args.initialStatus !== undefined) ? args.initialStatus : null;
  }
  load() {
    this.loadFeed();
    this.loadOrders();
  }
  async loadFeed() {
    try {
      const value = await this._service.fetchOrders();
      this.feed = value;
      this.status = (this.initialStatus ?? value.statuses.first);
      this.feedError = null;
      this.notifyListeners();
      if ((__nn(this.initialStatus) != null)) {
        await this.loadOrders();
      }
    } catch (__e) {
      const e = __e;
      print("OrdersVm 状态条加载失败: " + e);
      this.feedError = e.toString();
      this.notifyListeners();
    }
  }
  async loadOrders() {
    this.listLoading = true;
    this.notifyListeners();
    try {
      const value = await this._service.fetchOrderList(this.status);
      this.orders = value;
      this.listLoading = false;
      this.ordersError = null;
      this.notifyListeners();
    } catch (__e) {
      const e = __e;
      print("OrdersVm 订单列表加载失败: " + e);
      this.listLoading = false;
      this.ordersError = e.toString();
      this.notifyListeners();
    }
  }
  retry() {
    this.feedError = null;
    this.ordersError = null;
    this.notifyListeners();
    this.load();
  }
  pickStatus(value) {
    this.status = value;
    this.notifyListeners();
    this.loadOrders();
  }
}

