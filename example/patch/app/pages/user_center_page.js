// GENERATED CODE - DO NOT EDIT
// 由 dynamic_flutter_generator 从 lib/app/pages/user_center_page.dart 自动生成
// 重新生成：dart run build_runner build

import { UserCenterVm } from '../vm/user_center_vm.js';
import { UserProfile } from '../model/app_models.js';
import { AppRouter } from '../../base/app_router.js';
import { LoadErrorView } from '../widgets/load_error_view.js';
import { Alignment, BorderRadius, BoxDecoration, BoxFit, Center, CircularProgressIndicator, ClipOval, Color, Colors, Column, Container, CrossAxisAlignment, Divider, EdgeInsets, Expanded, Flexible, FontWeight, GestureDetector, Icon, Icons, Image, LinearGradient, ListView, Padding, Row, SafeArea, Scaffold, SizedBox, Spacer, StatelessWidget, Text, TextOverflow, TextStyle } from '../../flutter.js';
import { ChangeNotifierProvider } from '../../packages/provider.js';

// 组件 UserCenterPage
export class UserCenterPage extends StatelessWidget {
  constructor(args) {
    super(args);
  }
  build(context) {
    return new ChangeNotifierProvider({
      "create": (_) => { return (() => { const _t = new UserCenterVm(); _t.load(); return _t; })(); },
      "child": (this.__k0 || (this.__k0 = new _UserCenterView({}))),
      "typeArguments": {"T": "UserCenterVm"}
    });
  }
}

// 组件 _UserCenterView
export class _UserCenterView extends StatelessWidget {
  constructor(args) {
    super(args);
  }
  build(context) {
    const vm = context.watch({ typeArguments: {"T": "UserCenterVm"} });
    const profile = vm.feed;
    const error = vm.error;
    let body = null;
    if ((__nn(profile) != null)) {
      body = new _ProfileBody({
        "profile": profile
      });
    } else {
      if ((__nn(error) != null)) {
        body = new LoadErrorView({
          "message": error,
          "onRetry": (...__a) => vm.load(...__a)
        });
      } else {
        body = (this.__k0 || (this.__k0 = new Center({
          "child": new CircularProgressIndicator({})
        })));
      }
    }
    return new Scaffold({
      "backgroundColor": (this.__k1 || (this.__k1 = new Color({
        "value": 0xFFF3F5F8
      }))),
      "body": new Column({
        "children": [
          new _ProfileHeader({
            "profile": profile
          }),
          new Expanded({
            "child": body
          })
        ]
      })
    });
  }
}

// 组件 _ProfileHeader
export class _ProfileHeader extends StatelessWidget {
  constructor(args) {
    super(args);
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.profile = (args && args.profile !== undefined) ? args.profile : null;
  }
  build(context) {
    const p = this.profile;
    const avatar = ((__nn(p) == null) ? "assets/images/photo-1494790108377-be9c29b29330.jpg" : p.avatar);
    const nickname = ((__nn(p) == null) ? "未登录" : p.nickname);
    const phone = ((__nn(p) == null) ? "登录后同步你的旅行足迹" : p.phone);
    const level = ((__nn(p) == null) ? "游客" : p.level);
    const levelSub = ((__nn(p) == null) ? "" : p.levelSub);
    return new Container({
      "decoration": (this.__k0 || (this.__k0 = new BoxDecoration({
        "gradient": new LinearGradient({
          "colors": [
            new Color({
              "value": 0xFF1E88FF
            }),
            new Color({
              "value": 0xFF0E7AFB
            })
          ],
          "begin": Alignment.topLeft,
          "end": Alignment.bottomRight
        })
      }))),
      "child": new SafeArea({
        "bottom": false,
        "child": new Padding({
          "padding": (this.__k1 || (this.__k1 = EdgeInsets.fromLTRB({
            "bottom": 18,
            "left": 14,
            "right": 14,
            "top": 8
          }))),
          "child": new Column({
            "crossAxisAlignment": CrossAxisAlignment.start,
            "children": [
              new Row({
                "children": [
                  new GestureDetector({
                    "onTap": () => AppRouter.pop(),
                    "child": new Container({
                      "padding": (this.__k2 || (this.__k2 = EdgeInsets.all({
                        "value": 4
                      }))),
                      "child": (this.__k3 || (this.__k3 = new Icon({
                        "color": Colors.white,
                        "icon": Icons.arrow_back,
                        "size": 20
                      })))
                    })
                  }),
                  (this.__k4 || (this.__k4 = new SizedBox({
                    "width": 6
                  }))),
                  (this.__k5 || (this.__k5 = new Text({
                    "data": "个人中心",
                    "style": new TextStyle({
                      "fontSize": 16,
                      "fontWeight": FontWeight.w600,
                      "color": Colors.white
                    })
                  }))),
                  (this.__k6 || (this.__k6 = new Spacer({}))),
                  new GestureDetector({
                    "onTap": () => AppRouter.toast("编辑资料（演示）"),
                    "child": new Container({
                      "padding": (this.__k7 || (this.__k7 = EdgeInsets.symmetric({
                        "horizontal": 10,
                        "vertical": 4
                      }))),
                      "decoration": new BoxDecoration({
                        "color": (this.__k8 || (this.__k8 = new Color({
                          "value": 0x33FFFFFF
                        }))),
                        "borderRadius": BorderRadius.circular({
                          "radius": 12
                        })
                      }),
                      "child": (this.__k9 || (this.__k9 = new Text({
                        "data": "编辑资料",
                        "style": new TextStyle({
                          "fontSize": 11,
                          "color": Colors.white
                        })
                      })))
                    })
                  })
                ]
              }),
              (this.__k10 || (this.__k10 = new SizedBox({
                "height": 14
              }))),
              new Row({
                "crossAxisAlignment": CrossAxisAlignment.start,
                "children": [
                  new ClipOval({
                    "child": Image.asset({
                      "width": 62,
                      "height": 62,
                      "fit": BoxFit.cover,
                      "errorBuilder": (context, e, s) => new Container({
                        "width": 62,
                        "height": 62,
                        "color": (this.__k8 || (this.__k8 = new Color({
                          "value": 0x33FFFFFF
                        })))
                      }),
                      "name": avatar
                    })
                  }),
                  (this.__k11 || (this.__k11 = new SizedBox({
                    "width": 12
                  }))),
                  new Expanded({
                    "child": new Column({
                      "crossAxisAlignment": CrossAxisAlignment.start,
                      "children": [
                        new Row({
                          "children": [
                            new Flexible({
                              "child": new Text({
                                "maxLines": 1,
                                "overflow": TextOverflow.ellipsis,
                                "style": (this.__k12 || (this.__k12 = new TextStyle({
                                  "color": Colors.white,
                                  "fontSize": 17.5,
                                  "fontWeight": FontWeight.w700
                                }))),
                                "data": nickname
                              })
                            }),
                            (this.__k13 || (this.__k13 = new SizedBox({
                              "width": 8
                            }))),
                            new Container({
                              "padding": (this.__k14 || (this.__k14 = EdgeInsets.symmetric({
                                "horizontal": 7,
                                "vertical": 2
                              }))),
                              "decoration": new BoxDecoration({
                                "color": (this.__k8 || (this.__k8 = new Color({
                                  "value": 0x33FFFFFF
                                }))),
                                "borderRadius": BorderRadius.circular({
                                  "radius": 9
                                })
                              }),
                              "child": new Text({
                                "style": (this.__k15 || (this.__k15 = new TextStyle({
                                  "color": Colors.white,
                                  "fontSize": 10.5
                                }))),
                                "data": level
                              })
                            })
                          ]
                        }),
                        (this.__k16 || (this.__k16 = new SizedBox({
                          "height": 5
                        }))),
                        new Text({
                          "style": (this.__k17 || (this.__k17 = new TextStyle({
                            "color": new Color({
                              "value": 0xCCFFFFFF
                            }),
                            "fontSize": 12
                          }))),
                          "data": phone
                        }),
                        (this.__k18 || (this.__k18 = new SizedBox({
                          "height": 6
                        }))),
                        new Text({
                          "maxLines": 1,
                          "overflow": TextOverflow.ellipsis,
                          "style": (this.__k19 || (this.__k19 = new TextStyle({
                            "color": new Color({
                              "value": 0xB3FFFFFF
                            }),
                            "fontSize": 11
                          }))),
                          "data": levelSub
                        })
                      ]
                    })
                  })
                ]
              })
            ]
          })
        })
      })
    });
  }
}

// 组件 _ProfileBody
export class _ProfileBody extends StatelessWidget {
  constructor(args) {
    super(args);
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.profile = (args && args.profile !== undefined) ? args.profile : null;
  }
  build(context) {
    return new ListView({
      "padding": (this.__k0 || (this.__k0 = EdgeInsets.only({
        "bottom": 26
      }))),
      "children": [
        this._assetsCard(),
        this._sectionTitle("常用功能"),
        this._servicesCard(),
        this._sectionTitle("账号与安全"),
        this._securityCard(),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 18
        }))),
        this._logout(),
        this._footer()
      ]
    });
  }
  _assetsCard() {
    return new Container({
      "margin": (this.__k2 || (this.__k2 = EdgeInsets.fromLTRB({
        "bottom": 0,
        "left": 12,
        "right": 12,
        "top": 12
      }))),
      "padding": (this.__k3 || (this.__k3 = EdgeInsets.symmetric({
        "vertical": 15
      }))),
      "decoration": this._cardDecoration(),
      "child": new Row({
        "children": [
          this._assetCell("" + this.profile.points, "积分"),
          this._assetCell("" + this.profile.coupons, "优惠券"),
          this._assetCell("" + this.profile.favorites, "收藏"),
          this._assetCell("" + this.profile.footprints, "足迹")
        ]
      })
    });
  }
  _assetCell(value, label) {
    return new Expanded({
      "child": new GestureDetector({
        "onTap": () => AppRouter.toast(label + "（演示）"),
        "child": new Column({
          "children": [
            new Text({
              "style": (this.__k4 || (this.__k4 = new TextStyle({
                "color": new Color({
                  "value": 0xFF1A1D24
                }),
                "fontSize": 19,
                "fontWeight": FontWeight.w700
              }))),
              "data": value
            }),
            (this.__k5 || (this.__k5 = new SizedBox({
              "height": 4
            }))),
            new Text({
              "style": (this.__k6 || (this.__k6 = new TextStyle({
                "color": new Color({
                  "value": 0xFF8B909A
                }),
                "fontSize": 11.5
              }))),
              "data": label
            })
          ]
        })
      })
    });
  }
  _servicesCard() {
    const services = this.profile.services;
    return new Container({
      "margin": (this.__k7 || (this.__k7 = EdgeInsets.symmetric({
        "horizontal": 12
      }))),
      "padding": (this.__k8 || (this.__k8 = EdgeInsets.symmetric({
        "vertical": 14
      }))),
      "decoration": this._cardDecoration(),
      "child": new Column({
        "children": [
          this._serviceRow(this.profile.services, 0),
          (this.__k9 || (this.__k9 = new SizedBox({
            "height": 14
          }))),
          this._serviceRow(this.profile.services, 4)
        ]
      })
    });
  }
  _serviceRow(services, start) {
    const cells = [];
    const end = (start + 4);
    for (let i = start; (i < end); (i++)) {
      if ((i >= services.length)) {
        cells.add((this.__k10 || (this.__k10 = new Expanded({
          "child": new SizedBox({})
        }))));
      } else {
        const emoji = services[i][0];
        const title = services[i][1];
        cells.add(this._serviceCell(emoji, title));
      }
    }
    return new Row({
      "children": cells
    });
  }
  _serviceCell(emoji, title) {
    return new Expanded({
      "child": new GestureDetector({
        "onTap": () => AppRouter.toast(title + "（演示）"),
        "child": new Column({
          "children": [
            new Container({
              "width": 40,
              "height": 40,
              "alignment": Alignment.center,
              "decoration": new BoxDecoration({
                "color": (this.__k11 || (this.__k11 = new Color({
                  "value": 0xFFF2F5FA
                }))),
                "borderRadius": BorderRadius.circular({
                  "radius": 12
                })
              }),
              "child": new Text({
                "style": (this.__k12 || (this.__k12 = new TextStyle({
                  "fontSize": 19
                }))),
                "data": emoji
              })
            }),
            (this.__k13 || (this.__k13 = new SizedBox({
              "height": 7
            }))),
            new Text({
              "maxLines": 1,
              "overflow": TextOverflow.ellipsis,
              "style": (this.__k14 || (this.__k14 = new TextStyle({
                "color": new Color({
                  "value": 0xFF3A3F4A
                }),
                "fontSize": 11.5
              }))),
              "data": title
            })
          ]
        })
      })
    });
  }
  _securityCard() {
    const security = this.profile.security;
    const rows = [];
    for (let i = 0; (i < security.length); (i++)) {
      if ((i > 0)) {
        rows.add((this.__k15 || (this.__k15 = new Divider({
          "color": new Color({
            "value": 0xFFEEF0F4
          }),
          "endIndent": 14,
          "height": 1,
          "indent": 14
        }))));
      }
      rows.add(this._securityRow(security[i]));
    }
    return new Container({
      "margin": (this.__k7 || (this.__k7 = EdgeInsets.symmetric({
        "horizontal": 12
      }))),
      "decoration": this._cardDecoration(),
      "child": new Column({
        "children": rows
      })
    });
  }
  _securityRow(row) {
    const title = row[0];
    const sub = row[1];
    return new GestureDetector({
      "onTap": () => { return this._openSecurity(title); },
      "child": new Padding({
        "padding": (this.__k16 || (this.__k16 = EdgeInsets.fromLTRB({
          "bottom": 13,
          "left": 14,
          "right": 14,
          "top": 13
        }))),
        "child": new Row({
          "children": [
            new Expanded({
              "child": new Column({
                "crossAxisAlignment": CrossAxisAlignment.start,
                "children": [
                  new Text({
                    "style": (this.__k17 || (this.__k17 = new TextStyle({
                      "color": new Color({
                        "value": 0xFF1A1D24
                      }),
                      "fontSize": 13.5,
                      "fontWeight": FontWeight.w500
                    }))),
                    "data": title
                  }),
                  (this.__k18 || (this.__k18 = new SizedBox({
                    "height": 3
                  }))),
                  new Text({
                    "maxLines": 1,
                    "overflow": TextOverflow.ellipsis,
                    "style": (this.__k19 || (this.__k19 = new TextStyle({
                      "color": new Color({
                        "value": 0xFF8B909A
                      }),
                      "fontSize": 11
                    }))),
                    "data": sub
                  })
                ]
              })
            }),
            (this.__k20 || (this.__k20 = new Icon({
              "color": new Color({
                "value": 0xFFC3C8D2
              }),
              "icon": Icons.chevron_right,
              "size": 16
            })))
          ]
        })
      })
    });
  }
  _openSecurity(title) {
    if ((title === "切换账号")) {
      AppRouter.openLogin();
    } else {
      AppRouter.toast(title + "（演示）");
    }
  }
  _logout() {
    return new Container({
      "margin": (this.__k7 || (this.__k7 = EdgeInsets.symmetric({
        "horizontal": 12
      }))),
      "decoration": this._cardDecoration(),
      "child": new GestureDetector({
        "onTap": () => AppRouter.toast("已退出登录（演示）"),
        "child": (this.__k21 || (this.__k21 = new Padding({
          "child": new Center({
            "child": new Text({
              "style": new TextStyle({
                "fontSize": 14,
                "fontWeight": FontWeight.w500,
                "color": new Color({
                  "value": 0xFFE5484D
                })
              }),
              "data": "退出登录"
            })
          }),
          "padding": EdgeInsets.symmetric({
            "vertical": 14
          })
        })))
      })
    });
  }
  _footer() {
    return (this.__k22 || (this.__k22 = new Padding({
      "child": new Center({
        "child": new Text({
          "style": new TextStyle({
            "fontSize": 10.5,
            "color": new Color({
              "value": 0xFFA8ADB8
            })
          }),
          "data": "账号 ID 100086 · 已注册 1024 天"
        })
      }),
      "padding": EdgeInsets.only({
        "top": 16
      })
    })));
  }
  _sectionTitle(title) {
    return new Padding({
      "padding": (this.__k23 || (this.__k23 = EdgeInsets.fromLTRB({
        "bottom": 8,
        "left": 18,
        "right": 18,
        "top": 16
      }))),
      "child": new Text({
        "style": (this.__k24 || (this.__k24 = new TextStyle({
          "color": new Color({
            "value": 0xFF6B7280
          }),
          "fontSize": 12.5,
          "fontWeight": FontWeight.w600
        }))),
        "data": title
      })
    });
  }
  _cardDecoration() {
    return new BoxDecoration({color: Colors.white, borderRadius: BorderRadius.circular({radius: 14})});
  }
}

