// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/app/pages/orders_page.dart 自动生成
// 重新生成：dart run build_runner build

import { AppService } from '../service/app_service.js';
import { OrderFeed } from '../model/app_models.js';
import { Order } from '../model/app_models.js';
import { MiniButton } from 'detail_pages.js';
import { kBrand, kPrice } from 'detail_pages.js';
import { BorderRadius, BoxDecoration, Center, CircularProgressIndicator, ClipRRect, Color, Colors, Column, Container, Divider, EdgeInsets, Expanded, FontWeight, GestureDetector, Image, LinearProgressIndicator, ListView, Padding, Row, SafeArea, SingleChildScrollView, SizedBox, Spacer, Text, TextStyle } from '../../flutter.js';

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
        case "已完成": return new Color({value: 0xFF8B909A});
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
          "color": Colors.white,
          "child": new SafeArea({
            "bottom": false,
            "child": new Padding({
              "padding": (this.__k1 || (this.__k1 = EdgeInsets.fromLTRB({
                "bottom": 10,
                "left": 8,
                "right": 8,
                "top": 6
              }))),
              "child": new SingleChildScrollView({
                "scrollDirection": "horizontal",
                "child": new Row({
                  "children": [
                    ...(() => { var out = []; for (let s of this._feed.statuses) { out.push.apply(out, [new Padding({
                            "padding": (this.__k2 || (this.__k2 = EdgeInsets.symmetric({
                              "horizontal": 4
                            }))),
                            "child": new GestureDetector({
                              "onTap": this.__bindFn(0, [s], () => this._pickStatus(s)),
                              "child": new Container({
                                "padding": (this.__k3 || (this.__k3 = EdgeInsets.symmetric({
                                  "horizontal": 13,
                                  "vertical": 6
                                }))),
                                "decoration": new BoxDecoration({
                                  "color": (this._status == s) ? (this.__k4 || (this.__k4 = new Color({
                                    "value": 0xFFE8F2FF
                                  }))) : Colors.white,
                                  "borderRadius": BorderRadius.circular({
                                    "radius": 15
                                  })
                                }),
                                "child": new Text({
                                  "style": new TextStyle({
                                    "fontSize": 13,
                                    "fontWeight": (this._status == s) ? FontWeight.w700 : FontWeight.w500,
                                    "color": (this._status == s) ? kBrand : (this.__k5 || (this.__k5 = new Color({
                                      "value": 0xFF5C6270
                                    })))
                                  }),
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
        ...(this._listLoading ? [(this.__k6 || (this.__k6 = new LinearProgressIndicator({
            "minHeight": 2
          })))] : []),
        new Expanded({
          "child": (this._orders == null) ? (this.__k0 || (this.__k0 = new Center({
            "child": new CircularProgressIndicator({})
          }))) : this._orders.isEmpty ? (this.__k7 || (this.__k7 = new Center({
            "child": new Text({
              "style": new TextStyle({
                "fontSize": 13,
                "color": new Color({
                  "value": 0xFF98A0AC
                })
              }),
              "data": "该状态下暂无订单"
            })
          }))) : ListView.separated({
            "padding": (this.__k8 || (this.__k8 = EdgeInsets.fromLTRB({
              "bottom": 20,
              "left": 12,
              "right": 12,
              "top": 12
            }))),
            "itemCount": this._orders.length,
            "separatorBuilder": (context, index) => (this.__k9 || (this.__k9 = new SizedBox({
              "height": 10
            }))),
            "itemBuilder": (context, i) => {
              var o = this._orders[i];
              return new _OrderCard({
                "order": o,
                "statusColor": this._statusColor(o.status),
                "onOpen": () => { return _app_host_.invoke("openOrder", [o.no]); }
              });
            }
          })
        })
      ]
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
        "decoration": new BoxDecoration({
          "color": Colors.white,
          "borderRadius": BorderRadius.circular({
            "radius": 14
          })
        }),
        "child": new Column({
          "children": [
            new Padding({
              "padding": (this.__k0 || (this.__k0 = EdgeInsets.fromLTRB({
                "bottom": 10,
                "left": 14,
                "right": 14,
                "top": 12
              }))),
              "child": new Row({
                "children": [
                  new Text({
                    "style": (this.__k1 || (this.__k1 = new TextStyle({
                      "color": new Color({
                        "value": 0xFF8B909A
                      }),
                      "fontSize": 12
                    }))),
                    "data": "订单号 " + this.order.no
                  }),
                  (this.__k2 || (this.__k2 = new Spacer({}))),
                  new Text({
                    "style": new TextStyle({
                      "fontSize": 12.5,
                      "fontWeight": FontWeight.w700,
                      "color": this.statusColor
                    }),
                    "data": this.order.status
                  })
                ]
              })
            }),
            (this.__k3 || (this.__k3 = new Divider({
              "color": new Color({
                "value": 0xFFF0F2F6
              }),
              "height": 1
            }))),
            new Padding({
              "padding": (this.__k4 || (this.__k4 = EdgeInsets.all({
                "value": 12
              }))),
              "child": new Row({
                "crossAxisAlignment": "start",
                "children": [
                  new ClipRRect({
                    "borderRadius": BorderRadius.circular({
                      "radius": 10
                    }),
                    "child": Image.asset({
                      "width": 66,
                      "height": 66,
                      "fit": "cover",
                      "errorBuilder": (context, e, s) => new Container({
                        "width": 66,
                        "height": 66,
                        "color": (this.__k5 || (this.__k5 = new Color({
                          "value": 0xFFE8EBF0
                        })))
                      }),
                      "name": this.order.img
                    })
                  }),
                  (this.__k6 || (this.__k6 = new SizedBox({
                    "width": 11
                  }))),
                  new Expanded({
                    "child": new Column({
                      "crossAxisAlignment": "start",
                      "children": [
                        new Text({
                          "maxLines": 1,
                          "overflow": "ellipsis",
                          "style": (this.__k7 || (this.__k7 = new TextStyle({
                            "fontSize": 14,
                            "fontWeight": FontWeight.w600
                          }))),
                          "data": this.order.title
                        }),
                        (this.__k8 || (this.__k8 = new SizedBox({
                          "height": 5
                        }))),
                        new Text({
                          "maxLines": 1,
                          "overflow": "ellipsis",
                          "style": (this.__k9 || (this.__k9 = new TextStyle({
                            "color": new Color({
                              "value": 0xFF8B909A
                            }),
                            "fontSize": 11.5
                          }))),
                          "data": this.order.spec
                        }),
                        (this.__k10 || (this.__k10 = new SizedBox({
                          "height": 6
                        }))),
                        (this.__k11 || (this.__k11 = new Text({
                          "data": "×1",
                          "style": new TextStyle({
                            "fontSize": 11,
                            "color": new Color({
                              "value": 0xFFA3A9B4
                            })
                          })
                        })))
                      ]
                    })
                  })
                ]
              })
            }),
            (this.__k3 || (this.__k3 = new Divider({
              "color": new Color({
                "value": 0xFFF0F2F6
              }),
              "height": 1
            }))),
            new Padding({
              "padding": (this.__k12 || (this.__k12 = EdgeInsets.fromLTRB({
                "bottom": 12,
                "left": 14,
                "right": 12,
                "top": 10
              }))),
              "child": new Row({
                "children": [
                  (this.__k13 || (this.__k13 = new Text({
                    "data": "合计 ",
                    "style": new TextStyle({
                      "fontSize": 12.5,
                      "color": new Color({
                        "value": 0xFF5C6270
                      })
                    })
                  }))),
                  new Text({
                    "style": (this.__k14 || (this.__k14 = new TextStyle({
                      "color": kPrice,
                      "fontSize": 16,
                      "fontWeight": FontWeight.w700
                    }))),
                    "data": "￥" + this.order.price
                  }),
                  (this.__k2 || (this.__k2 = new Spacer({}))),
                  ...(pending ? [new MiniButton({
                      "label": "取消",
                      "onTap": () => { return _app_host_.invoke("toast", ["已取消订单 " + this.order.no + "（演示）"]); }
                    }), (this.__k15 || (this.__k15 = new SizedBox({
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
}

