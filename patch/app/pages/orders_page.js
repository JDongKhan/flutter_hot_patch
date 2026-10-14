// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/app/pages/orders_page.dart 自动生成
// 重新生成：dart run build_runner build

import { Order } from '../model/app_models.js';
import { MiniButton } from 'detail_pages.js';
import { kBrand, kPrice } from 'detail_pages.js';
import { kOrderStatus, kOrders } from '../model/app_data.js';
import { ListView, __h } from '../../flutter.js';

// 组件 OrdersPage
export class OrdersPage {
  constructor(args) {
    this.initialStatus = (args && args.initialStatus !== undefined) ? args.initialStatus : null;
    this._status = (this.initialStatus ?? kOrderStatus[0]);
  }
  get _list() {
    return ((this._status == kOrderStatus[0]) ? kOrders : kOrders.filter((o) => { return (o.status == this._status); }));
  }
  _statusColor(status) {
    return (() => { switch (status) {
    case "待付款": return kPrice;
    case "已完成": return '#ff8b909a';
    default: return kBrand;
} })();
  }
  build() {
    var list = this._list;
    return __h('Column', {
        "crossAxisAlignment": "stretch"
      }, [
        __h('Container', {
            "color": '#FFFFFF'
          }, [
            __h('SafeArea', {
                "bottom": false
              }, [
                __h('Padding', {
                    "padding": {
                      "left": 8.0,
                      "top": 6.0,
                      "right": 8.0,
                      "bottom": 10.0
                    }
                  }, [
                    __h('SingleChildScrollView', {
                        "scrollDirection": "horizontal"
                      }, [
                        __h('Row', {}, [
                            ...(() => { var out = []; for (let s of kOrderStatus) { out.push.apply(out, [__h('Padding', { "padding": { "left": 4.0, "top": 0.0, "right": 4.0, "bottom": 0.0 } }, [ __h('GestureDetector', { "event": this.__bindFn("() => setState(() => _status = s)" + ":" + String(s), () => { this.setState(() => { this._status = s; }); }) }, [ __h('Container', { "padding": { "left": 13.0, "top": 6.0, "right": 13.0, "bottom": 6.0 }, "decoration": { "color": ((this._status == s) ? '#ffe8f2ff' : '#FFFFFF'), "borderRadius": { "radius": 15.0 } } }, [ __h('Text', { "data": s, "style": { "fontSize": 13, "color": ((this._status == s) ? kBrand : '#ff5c6270') } }) ]) ]) ])]); } return out; })()
                          ])
                      ])
                  ])
              ])
          ]),
        __h('Expanded', {}, [
            ((this._list.length === 0) ? __h('Center', {}, [ __h('Text', { "data": "该状态下暂无订单", "style": { "fontSize": 13, "color": '#ff98a0ac' } }) ]) : __h(ListView, { "padding": { "left": 12.0, "top": 12.0, "right": 12.0, "bottom": 20.0 }, "builder": "_listViewBuilder0", "itemCount": this._list.length, "separatorBuilder": "_listViewBuilderSeparator1" }))
          ])
      ]);
  }
  _listViewBuilder0(i) {
      var o = this._list[i];
      return __h(_OrderCard, {
        "order": o,
        "statusColor": this._statusColor(o.status),
        "onOpen": () => { return __jsui.host("openOrder", [o.no]); }
      });
  }
  _listViewBuilderSeparator1(_) {
      return __h('SizedBox', {
        "height": 10
      });
  }
}

// 组件 _OrderCard
export class _OrderCard {
  constructor(args) {
    this.order = (args && args.order !== undefined) ? args.order : null;
    this.statusColor = (args && args.statusColor !== undefined) ? args.statusColor : null;
    this.onOpen = (args && args.onOpen !== undefined) ? args.onOpen : null;
  }
  build() {
    var pending = (this.order.status == "待付款");
    return __h('GestureDetector', {
        "event": this.__bind("this.onOpen()")
      }, [
        __h('Container', {
            "decoration": {
              "color": '#FFFFFF',
              "borderRadius": {
                "radius": 14.0
              }
            }
          }, [
            __h('Column', {}, [
                __h('Padding', {
                    "padding": {
                      "left": 14.0,
                      "top": 12.0,
                      "right": 14.0,
                      "bottom": 10.0
                    }
                  }, [
                    __h('Row', {}, [
                        __h('Text', {
                            "data": "订单号 " + this.order.no,
                            "style": {
                              "fontSize": 12,
                              "color": '#ff8b909a'
                            }
                          }),
                        __h('Spacer', {}),
                        __h('Text', {
                            "data": this.order.status,
                            "style": {
                              "fontSize": 12.5,
                              "fontWeight": "w700"
                            }
                          })
                      ])
                  ]),
                __h('Divider', {
                    "height": 1,
                    "color": '#fff0f2f6'
                  }),
                __h('Padding', {
                    "padding": {
                      "left": 12.0,
                      "top": 12.0,
                      "right": 12.0,
                      "bottom": 12.0
                    }
                  }, [
                    __h('Row', {
                        "crossAxisAlignment": "start"
                      }, [
                        __h('ClipRRect', {
                            "child": __h('Image', {
                                "source": this.order.img,
                                "width": 66,
                                "height": 66,
                                "fit": "cover"
                              })
                          }),
                        __h('SizedBox', {
                            "width": 11
                          }),
                        __h('Expanded', {}, [
                            __h('Column', {
                                "crossAxisAlignment": "start"
                              }, [
                                __h('Text', {
                                    "data": this.order.title,
                                    "style": {
                                      "fontSize": 14,
                                      "fontWeight": "w600"
                                    },
                                    "maxLines": 1,
                                    "overflow": "ellipsis"
                                  }),
                                __h('SizedBox', {
                                    "height": 5
                                  }),
                                __h('Text', {
                                    "data": this.order.spec,
                                    "style": {
                                      "fontSize": 11.5,
                                      "color": '#ff8b909a'
                                    },
                                    "maxLines": 1,
                                    "overflow": "ellipsis"
                                  }),
                                __h('SizedBox', {
                                    "height": 6
                                  }),
                                __h('Text', {
                                    "data": "×1",
                                    "style": {
                                      "fontSize": 11,
                                      "color": '#ffa3a9b4'
                                    }
                                  })
                              ])
                          ])
                      ])
                  ]),
                __h('Divider', {
                    "height": 1,
                    "color": '#fff0f2f6'
                  }),
                __h('Padding', {
                    "padding": {
                      "left": 14.0,
                      "top": 10.0,
                      "right": 12.0,
                      "bottom": 12.0
                    }
                  }, [
                    __h('Row', {}, [
                        __h('Text', {
                            "data": "合计 ",
                            "style": {
                              "fontSize": 12.5,
                              "color": '#ff5c6270'
                            }
                          }),
                        __h('Text', {
                            "data": "￥" + this.order.price,
                            "style": {
                              "fontSize": 16,
                              "fontWeight": "w700",
                              "color": kPrice
                            }
                          }),
                        __h('Spacer', {}),
                        ...(pending ? [__h(MiniButton, { "label": "取消", "onTap": () => { return __jsui.host("toast", ["已取消订单 " + this.order.no + "（演示）"]); } }), __h('SizedBox', { "width": 8 }), __h(MiniButton, { "label": "去支付", "primary": true, "onTap": this.onOpen })] : [__h(MiniButton, { "label": "查看详情", "onTap": this.onOpen })])
                      ])
                  ])
              ])
          ])
      ]);
  }
}

