// GENERATED CODE - DO NOT EDIT
// 由 dynamic_flutter_generator 从 lib/app/pages/detail_pages.dart 自动生成
// 重新生成：dart run build_runner build

import { AppService } from '../service/app_service.js';
import { Spot } from '../model/app_models.js';
import { SearchFeed } from '../model/app_models.js';
import { AppRouter } from '../../base/app_router.js';
import { LoadErrorView } from '../widgets/load_error_view.js';
import { Alignment, Border, BorderRadius, BorderSide, BoxDecoration, BoxFit, BoxShape, Center, CircularProgressIndicator, ClipRRect, Color, Colors, Column, Container, CrossAxisAlignment, EdgeInsets, Expanded, FontWeight, GestureDetector, Icon, Icons, Image, InputDecoration, ListView, OutlineInputBorder, Padding, Row, SafeArea, Scaffold, SizedBox, StatefulWidget, StatelessWidget, Text, TextDecoration, TextEditingController, TextField, TextOverflow, TextStyle, Wrap } from '../../flutter.js';

const _avatarImg = "assets/images/photo-1494790108377-be9c29b29330.jpg";
const _bannerImg = "assets/images/photo-1519046904884-53103b34b206.jpg";
export const kBrand = new Color({value: 0xFF0E7AFB});
export const kPrice = new Color({value: 0xFFFF5A36});
const _agreementTextStyle = new TextStyle({fontSize: 11, color: new Color({value: 0xFF8B909A}), height: 1.7});
const _agreementLinkStyle = new TextStyle({fontSize: 11, height: 1.7, color: kBrand, decoration: TextDecoration.underline, decorationColor: kBrand});

// 组件 SearchPage
export class SearchPage extends StatefulWidget {
  constructor(args) {
    super(args);
    this._controller = new TextEditingController();
    this._hot = [];
    this._guesses = [];
    this._loading = true;
    this._error = null;
  }
  initState() {
    super.initState();
    this._load();
  }
  dispose() {
    this._controller.dispose();
    super.dispose();
  }
  async _load() {
    if ((!this._loading)) {
      this.setState(() => {
        this._loading = true;
        this._error = null;
      });
    }
    try {
      const feed = await SearchPage._service.fetchSearch();
      if ((!!this.__unmounted)) {
        return;
      }
      this.setState(() => {
        this._hot = feed.hot;
        this._guesses = feed.guesses;
        this._loading = false;
      });
    } catch (__e) {
      const e = __e;
      if ((!!this.__unmounted)) {
        return;
      }
      this.setState(() => {
        this._error = "" + e;
        this._loading = false;
      });
    }
  }
  _go(kw) {
    AppRouter.toast("搜索：" + (kw.isEmpty ? "全部" : kw));
  }
  build(context) {
    const guesses = this._guesses.reversed.toList();
    return new Scaffold({
      "backgroundColor": (this.__k0 || (this.__k0 = new Color({
        "value": 0xFFF3F5F8
      }))),
      "body": new Column({
        "children": [
          new Container({
            "color": Colors.white,
            "child": new SafeArea({
              "bottom": false,
              "child": new _TopBar({
                "title": "",
                "trailing": new GestureDetector({
                  "onTap": () => { return this._go(this._controller.text); },
                  "child": (this.__k1 || (this.__k1 = new Text({
                    "data": "搜索",
                    "style": new TextStyle({
                      "fontSize": 13.5,
                      "color": kBrand,
                      "fontWeight": FontWeight.w600
                    })
                  })))
                })
              })
            })
          }),
          new Container({
            "margin": (this.__k2 || (this.__k2 = EdgeInsets.fromLTRB({
              "bottom": 12,
              "left": 14,
              "right": 14,
              "top": 10
            }))),
            "child": new TextField({
              "controller": this._controller,
              "autofocus": true,
              "onSubmitted": (__a0) => this._go(__a0),
              "decoration": new InputDecoration({
                "hintText": "搜索景点 / 目的地 / 攻略",
                "prefixIcon": (this.__k3 || (this.__k3 = new Icon({
                  "color": new Color({
                    "value": 0xFFA3A9B4
                  }),
                  "icon": Icons.search,
                  "size": 18
                }))),
                "filled": true,
                "fillColor": (this.__k0 || (this.__k0 = new Color({
                  "value": 0xFFF3F5F8
                }))),
                "contentPadding": (this.__k4 || (this.__k4 = EdgeInsets.symmetric({
                  "horizontal": 14,
                  "vertical": 0
                }))),
                "focusedBorder": new OutlineInputBorder({
                  "borderRadius": BorderRadius.circular({
                    "radius": 19
                  }),
                  "borderSide": new BorderSide({
                    "width": 0.5,
                    "color": new Color({
                      "value": 0xff999999
                    })
                  })
                }),
                "border": new OutlineInputBorder({
                  "borderRadius": BorderRadius.circular({
                    "radius": 19
                  }),
                  "borderSide": new BorderSide({
                    "width": 0.5,
                    "color": new Color({
                      "value": 0xffefefef
                    })
                  })
                })
              })
            })
          }),
          new Expanded({
            "child": this._loading ? (this.__k5 || (this.__k5 = new Center({
              "child": new CircularProgressIndicator({})
            }))) : (((__nn(this._error) != null) ? new LoadErrorView({
              "message": this._error,
              "onRetry": () => this._load()
            }) : new ListView({
              "padding": (this.__k6 || (this.__k6 = EdgeInsets.only({
                "bottom": 24
              }))),
              "children": [
                new _Block({
                  "child": new Column({
                    "crossAxisAlignment": CrossAxisAlignment.start,
                    "children": [
                      (this.__k7 || (this.__k7 = new _BlockTitle({
                        "text": "热门搜索"
                      }))),
                      new Wrap({
                        "spacing": 8,
                        "runSpacing": 8,
                        "children": [
                          ...(() => { var out = []; for (let k of this._hot) { out.push.apply(out, [new GestureDetector({
                                  "onTap": () => { return this._go(k); },
                                  "child": new Container({
                                    "padding": (this.__k8 || (this.__k8 = EdgeInsets.symmetric({
                                      "horizontal": 13,
                                      "vertical": 6
                                    }))),
                                    "decoration": new BoxDecoration({
                                      "color": (this.__k0 || (this.__k0 = new Color({
                                        "value": 0xFFF3F5F8
                                      }))),
                                      "borderRadius": BorderRadius.circular({
                                        "radius": 14
                                      })
                                    }),
                                    "child": new Text({
                                      "style": (this.__k9 || (this.__k9 = new TextStyle({
                                        "color": new Color({
                                          "value": 0xFF4D5462
                                        }),
                                        "fontSize": 12.5
                                      }))),
                                      "data": k
                                    })
                                  })
                                })]); } return out; })()
                        ]
                      })
                    ]
                  })
                }),
                (this.__k10 || (this.__k10 = new Padding({
                  "child": new Text({
                    "style": new TextStyle({
                      "fontSize": 17,
                      "fontWeight": FontWeight.w700
                    }),
                    "data": "猜你想去"
                  }),
                  "padding": EdgeInsets.fromLTRB({
                    "left": 16,
                    "top": 6,
                    "right": 16,
                    "bottom": 10
                  })
                }))),
                ...(() => { var out = []; for (let s of guesses) { out.push.apply(out, [new Padding({
                        "padding": (this.__k11 || (this.__k11 = EdgeInsets.fromLTRB({
                          "bottom": 10,
                          "left": 12,
                          "right": 12,
                          "top": 0
                        }))),
                        "child": new GestureDetector({
                          "onTap": () => AppRouter.openSpot(s.id),
                          "child": new PostRow({
                            "img": s.img,
                            "title": s.title,
                            "sub": s.sub,
                            "trailing": "￥" + s.price + " 起"
                          })
                        })
                      })]); } return out; })()
              ]
            })))
          })
        ]
      })
    });
  }
}
SearchPage._service = new AppService();

// 组件 MiniButton
export class MiniButton extends StatelessWidget {
  constructor(args) {
    super(args);
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.label = (args && args.label !== undefined) ? args.label : '';
    this.primary = (args && args.primary !== undefined) ? args.primary : false;
    this.onTap = (args && args.onTap !== undefined) ? args.onTap : null;
  }
  build(context) {
    return new GestureDetector({
      "onTap": this.onTap,
      "child": new Container({
        "padding": (this.__k0 || (this.__k0 = EdgeInsets.symmetric({
          "horizontal": 14,
          "vertical": 0
        }))),
        "height": 32,
        "alignment": Alignment.center,
        "decoration": new BoxDecoration({
          "color": this.primary ? kBrand : Colors.white,
          "borderRadius": BorderRadius.circular({
            "radius": 14
          }),
          "border": Border.all({
            "color": this.primary ? kBrand : (this.__k1 || (this.__k1 = new Color({
              "value": 0xFFDFE4EC
            })))
          })
        }),
        "child": new Text({
          "style": new TextStyle({
            "fontSize": 12,
            "fontWeight": this.primary ? FontWeight.w600 : FontWeight.w500,
            "color": this.primary ? Colors.white : (this.__k2 || (this.__k2 = new Color({
              "value": 0xFF4D5462
            })))
          }),
          "data": this.label
        })
      })
    });
  }
}

// 组件 PostRow
export class PostRow extends StatelessWidget {
  constructor(args) {
    super(args);
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.img = (args && args.img !== undefined) ? args.img : '';
    this.title = (args && args.title !== undefined) ? args.title : '';
    this.sub = (args && args.sub !== undefined) ? args.sub : '';
    this.trailing = (args && args.trailing !== undefined) ? args.trailing : null;
    this.footNote = (args && args.footNote !== undefined) ? args.footNote : null;
  }
  build(context) {
    return new Container({
      "padding": (this.__k0 || (this.__k0 = EdgeInsets.all({
        "value": 10
      }))),
      "decoration": new BoxDecoration({
        "color": Colors.white,
        "borderRadius": BorderRadius.circular({
          "radius": 14
        })
      }),
      "child": new Row({
        "crossAxisAlignment": CrossAxisAlignment.start,
        "children": [
          new ClipRRect({
            "borderRadius": BorderRadius.circular({
              "radius": 10
            }),
            "child": Image.asset({
              "width": 86,
              "height": 86,
              "fit": BoxFit.cover,
              "errorBuilder": (context, e, s) => new Container({
                "width": 86,
                "height": 86,
                "color": (this.__k1 || (this.__k1 = new Color({
                  "value": 0xFFE8EBF0
                })))
              }),
              "name": this.img
            })
          }),
          (this.__k2 || (this.__k2 = new SizedBox({
            "width": 11
          }))),
          new Expanded({
            "child": new Column({
              "crossAxisAlignment": CrossAxisAlignment.start,
              "children": [
                new Text({
                  "maxLines": 1,
                  "overflow": TextOverflow.ellipsis,
                  "style": (this.__k3 || (this.__k3 = new TextStyle({
                    "fontSize": 14,
                    "fontWeight": FontWeight.w600
                  }))),
                  "data": this.title
                }),
                (this.__k4 || (this.__k4 = new SizedBox({
                  "height": 5
                }))),
                new Text({
                  "maxLines": 2,
                  "overflow": TextOverflow.ellipsis,
                  "style": (this.__k5 || (this.__k5 = new TextStyle({
                    "color": new Color({
                      "value": 0xFF8B909A
                    }),
                    "fontSize": 11.5,
                    "height": 1.5
                  }))),
                  "data": this.sub
                }),
                ...((__nn(this.trailing) != null) ? [new Padding({
                    "padding": (this.__k6 || (this.__k6 = EdgeInsets.only({
                      "top": 8
                    }))),
                    "child": new Text({
                      "style": (this.__k7 || (this.__k7 = new TextStyle({
                        "color": kPrice,
                        "fontSize": 13,
                        "fontWeight": FontWeight.w700
                      }))),
                      "data": this.trailing
                    })
                  })] : []),
                ...((__nn(this.footNote) != null) ? [new Padding({
                    "padding": (this.__k8 || (this.__k8 = EdgeInsets.only({
                      "top": 6
                    }))),
                    "child": new Text({
                      "style": (this.__k9 || (this.__k9 = new TextStyle({
                        "color": new Color({
                          "value": 0xFFA3A9B4
                        }),
                        "fontSize": 11
                      }))),
                      "data": this.footNote
                    })
                  })] : [])
              ]
            })
          })
        ]
      })
    });
  }
}

// 组件 _BlockTitle
export class _BlockTitle extends StatelessWidget {
  constructor(args) {
    super(args);
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.text = (args && args.text !== undefined) ? args.text : '';
  }
  build(context) {
    return new Padding({
      "padding": (this.__k0 || (this.__k0 = EdgeInsets.only({
        "bottom": 10
      }))),
      "child": new Text({
        "style": (this.__k1 || (this.__k1 = new TextStyle({
          "fontSize": 15,
          "fontWeight": FontWeight.w700
        }))),
        "data": this.text
      })
    });
  }
}

// 组件 _Block
export class _Block extends StatelessWidget {
  constructor(args) {
    super(args);
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.child = (args && args.child !== undefined) ? args.child : null;
  }
  build(context) {
    return new Container({
      "margin": (this.__k0 || (this.__k0 = EdgeInsets.fromLTRB({
        "bottom": 12,
        "left": 12,
        "right": 12,
        "top": 0
      }))),
      "padding": (this.__k1 || (this.__k1 = EdgeInsets.fromLTRB({
        "bottom": 14,
        "left": 16,
        "right": 16,
        "top": 14
      }))),
      "decoration": new BoxDecoration({
        "color": Colors.white,
        "borderRadius": BorderRadius.circular({
          "radius": 16
        })
      }),
      "child": this.child
    });
  }
}

// 组件 _TopBar
export class _TopBar extends StatelessWidget {
  constructor(args) {
    super(args);
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.title = (args && args.title !== undefined) ? args.title : '';
    this.trailing = (args && args.trailing !== undefined) ? args.trailing : null;
  }
  build(context) {
    return new Container({
      "padding": (this.__k0 || (this.__k0 = EdgeInsets.fromLTRB({
        "bottom": 12,
        "left": 14,
        "right": 14,
        "top": 6
      }))),
      "decoration": (this.__k1 || (this.__k1 = new BoxDecoration({
        "border": new Border({
          "bottom": new BorderSide({
            "color": new Color({
              "value": 0xFFEEF1F5
            })
          })
        }),
        "color": Colors.white
      }))),
      "child": new Row({
        "children": [
          new GestureDetector({
            "onTap": () => AppRouter.pop(),
            "child": new Container({
              "width": 34,
              "height": 34,
              "decoration": (this.__k2 || (this.__k2 = new BoxDecoration({
                "color": new Color({
                  "value": 0xFFF3F5F8
                }),
                "shape": BoxShape.circle
              }))),
              "child": (this.__k3 || (this.__k3 = new Icon({
                "color": new Color({
                  "value": 0xFF171A21
                }),
                "icon": Icons.arrow_back_ios_new,
                "size": 15
              })))
            })
          }),
          (this.__k4 || (this.__k4 = new SizedBox({
            "width": 10
          }))),
          new Expanded({
            "child": new Text({
              "maxLines": 1,
              "overflow": TextOverflow.ellipsis,
              "style": (this.__k5 || (this.__k5 = new TextStyle({
                "fontSize": 16.5,
                "fontWeight": FontWeight.w700
              }))),
              "data": this.title
            })
          }),
          ...((__nn(this.trailing) != null) ? [this.trailing] : [])
        ]
      })
    });
  }
}

