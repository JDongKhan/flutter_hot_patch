// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/app/pages/orders_page.dart 自动生成
// 重新生成：dart run build_runner build

import { AppService } from '../service/app_service.js';
import { OrderFeed } from '../model/app_models.js';
import { kBrand, kPrice } from 'detail_pages.js';
import { __h } from '../../flutter.js';

// 组件 OrdersPage
export class OrdersPage {
  constructor(args) {
    this.__applyProps(args);
    this._service = new AppService({});
    this._feed = null;
    this._orders = null;
    this._listLoading = false;
    this._status = "";
  }
  __applyProps(args) {
    this.initialStatus = (args && args.initialStatus !== undefined) ? args.initialStatus : null;
  }
  initState() {
    console.log("OrdersPage initState ---");
    this._load();
    this._loadOrders();
  }
  async _load() {
    var feed = await this._service.fetchOrders();
    this.setState(() => { this._feed = feed; this._status = (this.initialStatus ?? feed.statuses[0]); });
    if ((this.initialStatus != null)) {
      await this._loadOrders();
    }
  }
  async _loadOrders() {
    this.setState(() => { this._listLoading = true; });
    var orders = await this._service.fetchOrderList(this._status);
    this.setState(() => { this._orders = orders; this._listLoading = false; });
  }
  _pickStatus(status) {
    this.setState(() => { this._status = status; });
    this._loadOrders();
  }
  _statusColor(status) {
    return (() => { switch (status) {
    case "待付款": return kPrice;
    case "已完成": return '#ff8b909a';
    default: return kBrand;
} })();
  }
  build(context) {
    if ((this._feed == null)) {
      return __h('Center', {
          "child": __h('CircularProgressIndicator', {})
        });
    }
    return __h('Column', {
        "crossAxisAlignment": "stretch",
        "children": [
          __h('Container', {
              "color": '#FFFFFF',
              "child": __h('SafeArea', {
                  "bottom": false,
                  "child": __h('Padding', {
                      "padding": {
                        "left": 8.0,
                        "top": 6.0,
                        "right": 8.0,
                        "bottom": 10.0
                      },
                      "child": __h('SingleChildScrollView', {
                          "scrollDirection": "horizontal",
                          "child": __h('Row', {
                              "children": [
                                ...(() => { var out = []; for (let s of this._feed.statuses) { out.push.apply(out, [__h('Padding', { "padding": { "left": 4.0, "top": 0.0, "right": 4.0, "bottom": 0.0 }, "child": __h('GestureDetector', { "onTap": this.__bindFn(0, [s], () => this._pickStatus(s)), "child": __h('Container', { "padding": { "left": 13.0, "top": 6.0, "right": 13.0, "bottom": 6.0 }, "decoration": { "color": ((this._status == s) ? '#ffe8f2ff' : '#FFFFFF'), "borderRadius": { "radius": 15.0 } }, "child": __h('Text', { "style": { "fontSize": 13, "color": ((this._status == s) ? kBrand : '#ff5c6270') }, "data": s }) }) }) })]); } return out; })()
                              ]
                            })
                        })
                    })
                })
            }),
          ...(this._listLoading ? [__h('LinearProgressIndicator', { "minHeight": 2 })] : []),
          __h('Expanded', {})
        ]
      });
  }
}

