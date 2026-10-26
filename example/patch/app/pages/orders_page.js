// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/app/pages/orders_page.dart 自动生成
// 重新生成：dart run build_runner build

import { AppService } from '../service/app_service.js';
import { OrderFeed } from '../model/app_models.js';
import { Order } from '../model/app_models.js';
import { MiniButton } from 'detail_pages.js';
import { kBrand, kPrice } from 'detail_pages.js';
import { Center, CircularProgressIndicator, ClipRRect, Column, Container, Divider, Expanded, GestureDetector, Image, LinearProgressIndicator, ListView, Padding, Row, SafeArea, SingleChildScrollView, SizedBox, Spacer, Text } from '../../flutter.js';

// 组件 OrdersPage
export class OrdersPage {
  constructor(args) {
    this.props = args || {};
    this.__applyProps(args);
    this._service = new AppService();
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
    this.setState(() => { this._feed = feed; this._status = (this.initialStatus ?? feed.statuses.first); });
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
      return (this.__k0 || (this.__k0 = new Center({
          "child": new CircularProgressIndicator({})
        })));
    }
    return new Column({
        "crossAxisAlignment": "stretch",
        "children": [
          new Container({
              "color": '#FFFFFF',
              "child": new SafeArea({
                  "bottom": false,
                  "child": new Padding({
                      "padding": {
                        "left": 8.0,
                        "top": 6.0,
                        "right": 8.0,
                        "bottom": 10.0
                      },
                      "child": new SingleChildScrollView({
                          "scrollDirection": "horizontal",
                          "child": new Row({
                              "children": [
                                ...(() => { var out = []; for (let s of this._feed.statuses) { out.push.apply(out, [new Padding({
                                  "padding": {
                                    "left": 4.0,
                                    "top": 0.0,
                                    "right": 4.0,
                                    "bottom": 0.0
                                  },
                                  "child": new GestureDetector({
                                      "onTap": this.__bindFn(0, [s], () => this._pickStatus(s)),
                                      "child": new Container({
                                          "padding": {
                                            "left": 13.0,
                                            "top": 6.0,
                                            "right": 13.0,
                                            "bottom": 6.0
                                          },
                                          "decoration": {
                                            "color": ((this._status == s) ? '#ffe8f2ff' : '#FFFFFF'),
                                            "borderRadius": {
                                              "radius": 15.0
                                            }
                                          },
                                          "child": new Text({
                                              "style": {
                                                "fontSize": 13,
                                                "color": ((this._status == s) ? kBrand : '#ff5c6270')
                                              },
                                              "data": s
                                            })
                                        })
                                    })
                                })]); } return out; })()
                              ]
                            })
                        })
                    })
                })
            }),
          ...(this._listLoading ? [(this.__k1 || (this.__k1 = new LinearProgressIndicator({
            "minHeight": 2
          })))] : []),
          new Expanded({
              "child": (this._orders == null) ? (this.__k0 || (this.__k0 = new Center({
                "child": new CircularProgressIndicator({})
              }))) : this._orders.isEmpty ? (this.__k2 || (this.__k2 = new Center({
                "child": new Text({
                    "data": "该状态下暂无订单",
                    "style": {
                      "color": '#ff98a0ac',
                      "fontSize": 13
                    }
                  })
              }))) : ListView.separated({
                "padding": {
                  "left": 12.0,
                  "top": 12.0,
                  "right": 12.0,
                  "bottom": 20.0
                },
                "itemCount": this._orders.length,
                "separatorBuilder": "_separatorBuilder0",
                "itemBuilder": "_itemBuilder1"
              })
            })
        ]
      });
  }
  _separatorBuilder0(context, _) {
      return (this.__k3 || (this.__k3 = new SizedBox({
        "height": 10
      })));
  }
  _itemBuilder1(context, i) {
      var o = this._orders[i];
      return new _OrderCard({
        "order": o,
        "statusColor": this._statusColor(o.status),
        "onOpen": () => { return _app_host_.invoke("openOrder", [o.no]); }
      });
  }
}

// 组件 _OrderCard
export class _OrderCard {
  constructor(args) {
    this.props = args || {};
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.order = (args && args.order !== undefined) ? args.order : null;
    this.statusColor = (args && args.statusColor !== undefined) ? args.statusColor : null;
    this.onOpen = (args && args.onOpen !== undefined) ? args.onOpen : null;
  }
  build(context) {
    var pending = (this.order.status == "待付款");
    return new GestureDetector({
        "onTap": this.__bindFn(0, [], (...__a) => this.onOpen(...__a)),
        "child": new Container({
            "decoration": {
              "color": '#FFFFFF',
              "borderRadius": {
                "radius": 14.0
              }
            },
            "child": new Column({
                "children": [
                  new Padding({
                      "padding": {
                        "left": 14.0,
                        "top": 12.0,
                        "right": 14.0,
                        "bottom": 10.0
                      },
                      "child": new Row({
                          "children": [
                            new Text({
                                "style": {
                                  "fontSize": 12,
                                  "color": '#ff8b909a'
                                },
                                "data": "订单号 " + this.order.no
                              }),
                            (this.__k1 || (this.__k1 = new Spacer({}))),
                            new Text({
                                "style": {
                                  "fontSize": 12.5,
                                  "fontWeight": "w700"
                                },
                                "data": this.order.status
                              })
                          ]
                        })
                    }),
                  (this.__k2 || (this.__k2 = new Divider({
                      "color": '#fff0f2f6',
                      "height": 1
                    }))),
                  new Padding({
                      "padding": {
                        "left": 12.0,
                        "top": 12.0,
                        "right": 12.0,
                        "bottom": 12.0
                      },
                      "child": new Row({
                          "crossAxisAlignment": "start",
                          "children": [
                            new ClipRRect({
                                "borderRadius": {
                                  "radius": 10.0
                                },
                                "child": new Image({
                                    "width": 66,
                                    "height": 66,
                                    "fit": "cover",
                                    "errorBuilder": "_errorBuilder0",
                                    "factory": "network",
                                    "src": this.order.img
                                  })
                              }),
                            (this.__k3 || (this.__k3 = new SizedBox({
                                "width": 11
                              }))),
                            new Expanded({
                                "child": new Column({
                                    "crossAxisAlignment": "start",
                                    "children": [
                                      new Text({
                                          "maxLines": 1,
                                          "overflow": "ellipsis",
                                          "style": {
                                            "fontSize": 14,
                                            "fontWeight": "w600"
                                          },
                                          "data": this.order.title
                                        }),
                                      (this.__k4 || (this.__k4 = new SizedBox({
                                          "height": 5
                                        }))),
                                      new Text({
                                          "maxLines": 1,
                                          "overflow": "ellipsis",
                                          "style": {
                                            "fontSize": 11.5,
                                            "color": '#ff8b909a'
                                          },
                                          "data": this.order.spec
                                        }),
                                      (this.__k5 || (this.__k5 = new SizedBox({
                                          "height": 6
                                        }))),
                                      (this.__k6 || (this.__k6 = new Text({
                                          "data": "×1",
                                          "style": {
                                            "color": '#ffa3a9b4',
                                            "fontSize": 11
                                          }
                                        })))
                                    ]
                                  })
                              })
                          ]
                        })
                    }),
                  (this.__k2 || (this.__k2 = new Divider({
                      "color": '#fff0f2f6',
                      "height": 1
                    }))),
                  new Padding({
                      "padding": {
                        "left": 14.0,
                        "top": 10.0,
                        "right": 12.0,
                        "bottom": 12.0
                      },
                      "child": new Row({
                          "children": [
                            (this.__k7 || (this.__k7 = new Text({
                                "data": "合计 ",
                                "style": {
                                  "color": '#ff5c6270',
                                  "fontSize": 12.5
                                }
                              }))),
                            new Text({
                                "style": {
                                  "fontSize": 16,
                                  "fontWeight": "w700",
                                  "color": kPrice
                                },
                                "data": "￥" + this.order.price
                              }),
                            (this.__k1 || (this.__k1 = new Spacer({}))),
                            ...(pending ? [new MiniButton({
                              "label": "取消",
                              "onTap": () => { return _app_host_.invoke("toast", ["已取消订单 " + this.order.no + "（演示）"]); }
                            }), (this.__k0 || (this.__k0 = new SizedBox({
                              "width": 8
                            }))), new MiniButton({
                              "label": "去支付",
                              "primary": true,
                              "onTap": this.onOpen
                            })] : [new MiniButton({
                              "label": "查看详情",
                              "onTap": this.onOpen
                            })])
                          ]
                        })
                    })
                ]
              })
          })
      });
  }
  _errorBuilder0(context, e) {
      return new Container({
        "width": 66,
        "height": 66,
        "color": '#ffe8ebf0'
      });
  }
}

