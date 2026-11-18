// GENERATED CODE - DO NOT EDIT
// 由 dynamic_flutter_generator 从 lib/app/pages/orders_page.dart 自动生成
// 重新生成：dart run build_runner build

import { OrdersVm } from '../vm/orders_vm.js';
import { Order } from '../model/app_models.js';
import { AppRouter } from '../../base/app_router.js';
import { LoadErrorView } from '../widgets/load_error_view.js';
import { CountdownText } from '../widgets/countdown_text.js';
import { MiniButton } from 'detail_pages.js';
import { kBrand, kPrice } from 'detail_pages.js';
import { Axis, BorderRadius, BoxDecoration, BoxFit, Center, CircularProgressIndicator, ClipRRect, Color, Colors, Column, Container, CrossAxisAlignment, Divider, EdgeInsets, Expanded, FontWeight, GestureDetector, Icon, Icons, Image, LinearProgressIndicator, ListView, MainAxisSize, Padding, Row, SafeArea, SingleChildScrollView, SizedBox, Spacer, StatefulWidget, StatelessWidget, Text, TextOverflow, TextStyle, Wrap } from '../../flutter.js';
import { ChangeNotifierProvider } from '../../packages/provider.js';

// 组件 OrdersPage
export class OrdersPage extends StatelessWidget {
  constructor(args) {
    super(args);
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.initialStatus = (args && args.initialStatus !== undefined) ? args.initialStatus : null;
  }
  build(context) {
    return new ChangeNotifierProvider({
      "create": (_) => { return (() => { const _t = new OrdersVm({initialStatus: this.initialStatus}); _t.load(); return _t; })(); },
      "child": (this.__k0 || (this.__k0 = new OrdersView({}))),
      "typeArguments": {"T": "OrdersVm"}
    });
  }
}

// 组件 OrdersView
export class OrdersView extends StatefulWidget {
  constructor(args) {
    super(args);
  }
  _statusColor(status) {
    return (() => { switch (status) {
        case "待付款": return kPrice;
        case "待发货": return new Color({value: 0xFFF08A00});
        case "待收货": return kBrand;
        case "已完成": return new Color({value: 0xFF8B909A});
        default: return kBrand;
      } })();
  }
  _buildOrderItem(context, i) {
    const orders = context.read({ typeArguments: {"T": "OrdersVm"} }).orders;
    const o = orders[i];
    return new _OrderCard({
      "order": o,
      "statusColor": this._statusColor(o.status),
      "onOpen": () => AppRouter.openOrder(o.no)
    });
  }
  build(context) {
    const vm = context.watch({ typeArguments: {"T": "OrdersVm"} });
    const feed = vm.feed;
    if ((__nn(feed) == null)) {
      const error = vm.feedError;
      if ((__nn(error) != null)) {
        return new LoadErrorView({
          "message": error,
          "onRetry": (...__a) => vm.retry(...__a)
        });
      }
      return (this.__k0 || (this.__k0 = new Center({
        "child": new CircularProgressIndicator({})
      })));
    }
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
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
                "scrollDirection": Axis.horizontal,
                "child": new Row({
                  "children": [
                    ...(() => { var out = []; for (let s of feed.statuses) { out.push.apply(out, [new Padding({
                            "padding": (this.__k2 || (this.__k2 = EdgeInsets.symmetric({
                              "horizontal": 4
                            }))),
                            "child": new GestureDetector({
                              "onTap": () => { return vm.pickStatus(s); },
                              "child": new Container({
                                "padding": (this.__k3 || (this.__k3 = EdgeInsets.symmetric({
                                  "horizontal": 13,
                                  "vertical": 6
                                }))),
                                "decoration": new BoxDecoration({
                                  "color": (vm.status === s) ? (this.__k4 || (this.__k4 = new Color({
                                    "value": 0xFFE8F2FF
                                  }))) : Colors.white,
                                  "borderRadius": BorderRadius.circular({
                                    "radius": 15
                                  })
                                }),
                                "child": new Text({
                                  "style": new TextStyle({
                                    "fontSize": 13,
                                    "fontWeight": (vm.status === s) ? FontWeight.w700 : FontWeight.w500,
                                    "color": (vm.status === s) ? kBrand : (this.__k5 || (this.__k5 = new Color({
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
        new Padding({
          "padding": (this.__k6 || (this.__k6 = EdgeInsets.fromLTRB({
            "bottom": 0,
            "left": 14,
            "right": 14,
            "top": 8
          }))),
          "child": new Text({
            "style": (this.__k7 || (this.__k7 = new TextStyle({
              "color": new Color({
                "value": 0xFF8B909A
              }),
              "fontSize": 12
            }))),
            "data": (vm.orders == null) ? "订单加载中…" : "共 " + vm.orders.length + " 笔订单"
          })
        }),
        ...(vm.listLoading ? [(this.__k8 || (this.__k8 = new LinearProgressIndicator({
            "minHeight": 2
          })))] : []),
        new Expanded({
          "child": (vm.orders == null) ? (vm.ordersError != null) ? new LoadErrorView({
            "message": vm.ordersError,
            "onRetry": (...__a) => vm.retry(...__a)
          }) : (this.__k0 || (this.__k0 = new Center({
            "child": new CircularProgressIndicator({})
          }))) : vm.orders.isEmpty ? (this.__k9 || (this.__k9 = new Center({
            "child": new Text({
              "style": new TextStyle({
                "fontSize": 13,
                "color": new Color({
                  "value": 0xFF98A0AC
                })
              }),
              "data": "该状态下暂无订单"
            })
          }))) : ListView.builder({
            "padding": (this.__k10 || (this.__k10 = EdgeInsets.fromLTRB({
              "bottom": 20,
              "left": 12,
              "right": 12,
              "top": 12
            }))),
            "itemCount": vm.orders.length,
            "itemBuilder": (__a0, __a1) => this._buildOrderItem(__a0, __a1)
          })
        })
      ]
    });
  }
}

// 组件 _OrderCard
export class _OrderCard extends StatelessWidget {
  constructor(args) {
    super(args);
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.order = (args && args.order !== undefined) ? args.order : null;
    this.statusColor = (args && args.statusColor !== undefined) ? args.statusColor : null;
    this.onOpen = (args && args.onOpen !== undefined) ? args.onOpen : null;
  }
  build(context) {
    const pending = (this.order.status === "待付款");
    return new GestureDetector({
      "onTap": this.onOpen,
      "child": new Container({
        "margin": (this.__k0 || (this.__k0 = EdgeInsets.only({
          "bottom": 10
        }))),
        "decoration": new BoxDecoration({
          "color": Colors.white,
          "borderRadius": BorderRadius.circular({
            "radius": 14
          })
        }),
        "child": new Column({
          "crossAxisAlignment": CrossAxisAlignment.stretch,
          "children": [
            new Padding({
              "padding": (this.__k1 || (this.__k1 = EdgeInsets.fromLTRB({
                "bottom": 10,
                "left": 14,
                "right": 12,
                "top": 12
              }))),
              "child": new Row({
                "children": [
                  (this.__k2 || (this.__k2 = new Icon({
                    "color": new Color({
                      "value": 0xFF5C6270
                    }),
                    "icon": Icons.storefront,
                    "size": 15
                  }))),
                  (this.__k3 || (this.__k3 = new SizedBox({
                    "width": 5
                  }))),
                  new Expanded({
                    "child": new Text({
                      "maxLines": 1,
                      "overflow": TextOverflow.ellipsis,
                      "style": (this.__k4 || (this.__k4 = new TextStyle({
                        "color": new Color({
                          "value": 0xFF2A2F3A
                        }),
                        "fontSize": 12.5,
                        "fontWeight": FontWeight.w600
                      }))),
                      "data": this.order.store
                    })
                  }),
                  new Container({
                    "padding": (this.__k5 || (this.__k5 = EdgeInsets.symmetric({
                      "horizontal": 8,
                      "vertical": 3
                    }))),
                    "decoration": new BoxDecoration({
                      "color": this.statusColor.withValues({ "alpha": 0.1 }),
                      "borderRadius": BorderRadius.circular({
                        "radius": 9
                      })
                    }),
                    "child": new Text({
                      "style": new TextStyle({
                        "fontSize": 11.5,
                        "fontWeight": FontWeight.w700,
                        "color": this.statusColor
                      }),
                      "data": this.order.status
                    })
                  })
                ]
              })
            }),
            (this.__k6 || (this.__k6 = new Divider({
              "color": new Color({
                "value": 0xFFF0F2F6
              }),
              "height": 1
            }))),
            new Padding({
              "padding": (this.__k7 || (this.__k7 = EdgeInsets.all({
                "value": 12
              }))),
              "child": new Row({
                "crossAxisAlignment": CrossAxisAlignment.start,
                "children": [
                  new ClipRRect({
                    "borderRadius": BorderRadius.circular({
                      "radius": 10
                    }),
                    "child": Image.asset({
                      "width": 82,
                      "height": 82,
                      "fit": BoxFit.cover,
                      "errorBuilder": (context, e, s) => new Container({
                        "width": 82,
                        "height": 82,
                        "color": (this.__k8 || (this.__k8 = new Color({
                          "value": 0xFFE8EBF0
                        })))
                      }),
                      "name": this.order.img
                    })
                  }),
                  (this.__k9 || (this.__k9 = new SizedBox({
                    "width": 11
                  }))),
                  new Expanded({
                    "child": new Column({
                      "crossAxisAlignment": CrossAxisAlignment.start,
                      "children": [
                        new Text({
                          "maxLines": 2,
                          "overflow": TextOverflow.ellipsis,
                          "style": (this.__k10 || (this.__k10 = new TextStyle({
                            "fontSize": 14,
                            "fontWeight": FontWeight.w600,
                            "height": 1.25
                          }))),
                          "data": this.order.title
                        }),
                        (this.__k11 || (this.__k11 = new SizedBox({
                          "height": 5
                        }))),
                        new Text({
                          "maxLines": 1,
                          "overflow": TextOverflow.ellipsis,
                          "style": (this.__k12 || (this.__k12 = new TextStyle({
                            "color": new Color({
                              "value": 0xFF8B909A
                            }),
                            "fontSize": 11.5
                          }))),
                          "data": this.order.spec
                        }),
                        (this.__k13 || (this.__k13 = new SizedBox({
                          "height": 7
                        }))),
                        new Wrap({
                          "spacing": 5,
                          "runSpacing": 4,
                          "children": [
                            ...(() => { var out = []; for (let tag of this.order.tags) { out.push.apply(out, [new Container({
                                    "padding": (this.__k14 || (this.__k14 = EdgeInsets.symmetric({
                                      "horizontal": 6,
                                      "vertical": 2
                                    }))),
                                    "decoration": new BoxDecoration({
                                      "color": (this.__k15 || (this.__k15 = new Color({
                                        "value": 0xFFFFF2E8
                                      }))),
                                      "borderRadius": BorderRadius.circular({
                                        "radius": 4
                                      })
                                    }),
                                    "child": new Text({
                                      "style": (this.__k16 || (this.__k16 = new TextStyle({
                                        "color": new Color({
                                          "value": 0xFFC8621E
                                        }),
                                        "fontSize": 10
                                      }))),
                                      "data": tag
                                    })
                                  })]); } return out; })()
                          ]
                        })
                      ]
                    })
                  })
                ]
              })
            }),
            new Padding({
              "padding": (this.__k17 || (this.__k17 = EdgeInsets.fromLTRB({
                "bottom": 12,
                "left": 16,
                "right": 16,
                "top": 0
              }))),
              "child": new Row({
                "children": [
                  ...(() => { var out = []; for (let i = 0; (i < _OrderCard._stageLabels.length); (i++)) { out.push.apply(out, [...((i > 0) ? [new Expanded({
                            "child": new Container({
                              "height": 1.5,
                              "margin": (this.__k18 || (this.__k18 = EdgeInsets.symmetric({
                                "horizontal": 4
                              }))),
                              "color": (i <= this.order.step) ? kBrand : (this.__k19 || (this.__k19 = new Color({
                                "value": 0xFFE3E7EF
                              })))
                            })
                          })] : []), new _StageNode({
                          "label": _OrderCard._stageLabels[i],
                          "active": (i <= this.order.step)
                        })]); } return out; })()
                ]
              })
            }),
            ...(pending ? [new Container({
                "margin": (this.__k20 || (this.__k20 = EdgeInsets.fromLTRB({
                  "bottom": 10,
                  "left": 12,
                  "right": 12,
                  "top": 0
                }))),
                "padding": (this.__k21 || (this.__k21 = EdgeInsets.symmetric({
                  "horizontal": 10,
                  "vertical": 8
                }))),
                "decoration": new BoxDecoration({
                  "color": (this.__k22 || (this.__k22 = new Color({
                    "value": 0xFFFFF3F0
                  }))),
                  "borderRadius": BorderRadius.circular({
                    "radius": 8
                  })
                }),
                "child": new Row({
                  "children": [
                    (this.__k23 || (this.__k23 = new Icon({
                      "color": kPrice,
                      "icon": Icons.access_time,
                      "size": 15
                    }))),
                    (this.__k3 || (this.__k3 = new SizedBox({
                      "width": 5
                    }))),
                    (this.__k24 || (this.__k24 = new Text({
                      "data": "剩余支付时间",
                      "style": new TextStyle({
                        "fontSize": 11.5,
                        "color": new Color({
                          "value": 0xFF8B5A4A
                        })
                      })
                    }))),
                    (this.__k25 || (this.__k25 = new SizedBox({
                      "width": 6
                    }))),
                    new CountdownText({
                      "deadlineMillis": this.order.deadlineMs,
                      "color": kPrice
                    }),
                    (this.__k26 || (this.__k26 = new Spacer({}))),
                    (this.__k27 || (this.__k27 = new Text({
                      "data": "超时自动取消",
                      "style": new TextStyle({
                        "fontSize": 10.5,
                        "color": new Color({
                          "value": 0xFFA89089
                        })
                      })
                    })))
                  ]
                })
              })] : [new Padding({
                "padding": (this.__k28 || (this.__k28 = EdgeInsets.fromLTRB({
                  "bottom": 10,
                  "left": 14,
                  "right": 14,
                  "top": 0
                }))),
                "child": new Row({
                  "children": [
                    (this.__k29 || (this.__k29 = new Icon({
                      "color": new Color({
                        "value": 0xFF8B909A
                      }),
                      "icon": Icons.schedule,
                      "size": 14
                    }))),
                    (this.__k3 || (this.__k3 = new SizedBox({
                      "width": 5
                    }))),
                    new Expanded({
                      "child": new Text({
                        "maxLines": 1,
                        "overflow": TextOverflow.ellipsis,
                        "style": (this.__k12 || (this.__k12 = new TextStyle({
                          "color": new Color({
                            "value": 0xFF8B909A
                          }),
                          "fontSize": 11.5
                        }))),
                        "data": this.order.deadline
                      })
                    })
                  ]
                })
              })]),
            new Padding({
              "padding": (this.__k28 || (this.__k28 = EdgeInsets.fromLTRB({
                "bottom": 10,
                "left": 14,
                "right": 14,
                "top": 0
              }))),
              "child": new Column({
                "crossAxisAlignment": CrossAxisAlignment.start,
                "children": [
                  new Row({
                    "children": [
                      (this.__k30 || (this.__k30 = new Icon({
                        "color": new Color({
                          "value": 0xFF8B909A
                        }),
                        "icon": Icons.location_on_outlined,
                        "size": 14
                      }))),
                      (this.__k31 || (this.__k31 = new SizedBox({
                        "width": 4
                      }))),
                      new Expanded({
                        "child": new Text({
                          "maxLines": 1,
                          "overflow": TextOverflow.ellipsis,
                          "style": (this.__k32 || (this.__k32 = new TextStyle({
                            "color": new Color({
                              "value": 0xFF5C6270
                            }),
                            "fontSize": 11.5
                          }))),
                          "data": this.order.address
                        })
                      })
                    ]
                  }),
                  (this.__k33 || (this.__k33 = new SizedBox({
                    "height": 4
                  }))),
                  new Text({
                    "maxLines": 1,
                    "overflow": TextOverflow.ellipsis,
                    "style": (this.__k34 || (this.__k34 = new TextStyle({
                      "color": new Color({
                        "value": 0xFF9AA0AC
                      }),
                      "fontSize": 11
                    }))),
                    "data": "优惠：" + this.order.discount + " · 备注：" + this.order.remark + " · 共 " + this.order.count + " 件"
                  })
                ]
              })
            }),
            (this.__k6 || (this.__k6 = new Divider({
              "color": new Color({
                "value": 0xFFF0F2F6
              }),
              "height": 1
            }))),
            new Padding({
              "padding": (this.__k35 || (this.__k35 = EdgeInsets.fromLTRB({
                "bottom": 12,
                "left": 14,
                "right": 12,
                "top": 10
              }))),
              "child": new Row({
                "children": [
                  (this.__k36 || (this.__k36 = new Text({
                    "data": "合计 ",
                    "style": new TextStyle({
                      "fontSize": 12.5,
                      "color": new Color({
                        "value": 0xFF5C6270
                      })
                    })
                  }))),
                  new Text({
                    "style": (this.__k37 || (this.__k37 = new TextStyle({
                      "color": kPrice,
                      "fontSize": 16,
                      "fontWeight": FontWeight.w700
                    }))),
                    "data": "￥" + this.order.price
                  }),
                  (this.__k25 || (this.__k25 = new SizedBox({
                    "width": 6
                  }))),
                  new Text({
                    "style": (this.__k38 || (this.__k38 = new TextStyle({
                      "color": new Color({
                        "value": 0xFF9AA0AC
                      }),
                      "fontSize": 10.5
                    }))),
                    "data": "（" + this.order.count + " 件）"
                  }),
                  (this.__k26 || (this.__k26 = new Spacer({}))),
                  ...this._actions(pending)
                ]
              })
            })
          ]
        })
      })
    });
  }
  _actions(pending) {
    if (pending) {
      return [new MiniButton({
          "label": "取消订单",
          "onTap": () => AppRouter.toast("已取消订单 " + this.order.no + "（演示）")
        }), (this.__k39 || (this.__k39 = new SizedBox({
          "width": 8
        }))), new MiniButton({
          "label": "去支付",
          "primary": true,
          "onTap": this.onOpen
        })];
    }
    if ((this.order.status === "待发货")) {
      return [new MiniButton({
          "label": "申请退款",
          "onTap": () => AppRouter.toast("已提交退款申请（演示）")
        }), (this.__k39 || (this.__k39 = new SizedBox({
          "width": 8
        }))), new MiniButton({
          "label": "提醒发货",
          "primary": true,
          "onTap": () => AppRouter.toast("已提醒商家发货（演示）")
        })];
    }
    if ((this.order.status === "待收货")) {
      return [new MiniButton({
          "label": "查看物流",
          "onTap": () => AppRouter.toast("包裹运输中（演示）")
        }), (this.__k39 || (this.__k39 = new SizedBox({
          "width": 8
        }))), new MiniButton({
          "label": "确认收货",
          "primary": true,
          "onTap": this.onOpen
        })];
    }
    return [new MiniButton({
        "label": "删除订单",
        "onTap": () => AppRouter.toast("已删除订单（演示）")
      }), (this.__k39 || (this.__k39 = new SizedBox({
        "width": 8
      }))), new MiniButton({
        "label": "再次购买",
        "primary": true,
        "onTap": this.onOpen
      })];
  }
}
_OrderCard._stageLabels = ["提交订单", "支付成功", "商家发货", "已完成"];

// 组件 _StageNode
export class _StageNode extends StatelessWidget {
  constructor(args) {
    super(args);
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.label = (args && args.label !== undefined) ? args.label : '';
    this.active = (args && args.active !== undefined) ? args.active : false;
  }
  build(context) {
    return new Column({
      "mainAxisSize": MainAxisSize.min,
      "children": [
        new Container({
          "width": 7,
          "height": 7,
          "decoration": new BoxDecoration({
            "color": this.active ? kBrand : (this.__k0 || (this.__k0 = new Color({
              "value": 0xFFE3E7EF
            }))),
            "borderRadius": BorderRadius.circular({
              "radius": 4
            })
          })
        }),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 4
        }))),
        new Text({
          "style": new TextStyle({
            "fontSize": 10,
            "color": this.active ? kBrand : (this.__k2 || (this.__k2 = new Color({
              "value": 0xFFA3A9B4
            }))),
            "fontWeight": this.active ? FontWeight.w600 : FontWeight.w400
          }),
          "data": this.label
        })
      ]
    });
  }
}

