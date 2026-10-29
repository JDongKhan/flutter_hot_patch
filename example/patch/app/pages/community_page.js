// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/app/pages/community_page.dart 自动生成
// 重新生成：dart run build_runner build

import { AppService } from '../service/app_service.js';
import { CommunityFeed } from '../model/app_models.js';
import { Post } from '../model/app_models.js';
import { Resource } from '../model/app_models.js';
import { kBrand } from 'detail_pages.js';
import { Alignment, BorderRadius, BoxDecoration, Center, CircularProgressIndicator, ClipRRect, Color, Colors, Column, Container, EdgeInsets, Expanded, FontWeight, GestureDetector, Icon, Image, LinearProgressIndicator, ListView, Material, Padding, Positioned, Row, SafeArea, SizedBox, Spacer, Stack, Text, TextStyle, Wrap } from '../../flutter.js';

// 组件 CommunityPage
export class CommunityPage {
  constructor(args) {
    this.props = args || {};
    this._service = new AppService();
    this._feed = null;
    this._posts = null;
    this._resources = null;
    this._listLoading = false;
    this._filterOpen = false;
    this._tab = "";
    this._sort = "";
    this._type = "";
    this._dist = "";
    this._price = "";
  }
  initState() {
    console.log("CommunityPage initState ---");
    this._load();
    this._loadPosts();
    this._loadResources();
  }
  async _load() {
    var feed = await this._service.fetchCommunity();
    this.setState(() => { this._feed = feed; this._tab = feed.tabs.first; this._sort = feed.sorts.first; this._type = feed.postTypes.first; this._dist = feed.dists.first; this._price = feed.priceRanges.first; });
  }
  async _loadPosts() {
    this.setState(() => { this._listLoading = true; });
    var posts = await this._service.fetchPostList(this._tab, this._sort, this._type, this._dist, this._price);
    this.setState(() => { this._posts = posts; this._listLoading = false; });
  }
  async _loadResources() {
    var resources = await this._service.fetchCommunityResources(this._tab);
    this.setState(() => { this._resources = resources; });
  }
  _selectTab(tab) {
    this.setState(() => { this._tab = tab; });
    this._loadPosts();
    this._loadResources();
  }
  _selectFilter(key, value) {
    this.setState(() => { switch (key) {   case "sort":     this._sort = value;   break;   case "type":     this._type = value;   break;   case "dist":     this._dist = value;   break;   case "price":     this._price = value;   break; } });
    this._loadPosts();
  }
  _toggleFilter() {
    this.setState(() => { this._filterOpen = (!this._filterOpen); });
  }
  _resetFilter() {
    var feed = this._feed;
    if ((feed == null)) {
      return;
    }
    this.setState(() => { this._sort = feed.sorts.first; this._type = feed.postTypes.first; this._dist = feed.dists.first; this._price = feed.priceRanges.first; });
    this._loadPosts();
  }
  build(context) {
    console.log("CommunityPage build : filterOpen=" + __str(this._filterOpen));
    var feed = this._feed;
    var resources = this._resources;
    if (((feed == null) || (resources == null))) {
      return (this.__k0 || (this.__k0 = new Center({
        "child": new CircularProgressIndicator({})
      })));
    }
    return new Column({
      "children": [
        new Container({
          "color": Colors.white,
          "child": new SafeArea({
            "bottom": false,
            "child": new Padding({
              "padding": (this.__k1 || (this.__k1 = EdgeInsets.fromLTRB({
                "bottom": 10,
                "left": 12,
                "right": 12,
                "top": 4
              }))),
              "child": new Row({
                "children": [
                  ...(() => { var out = []; for (let t of this._feed.tabs) { out.push.apply(out, [new Padding({
                          "padding": (this.__k2 || (this.__k2 = EdgeInsets.only({
                            "right": 8
                          }))),
                          "child": new GestureDetector({
                            "onTap": this.__bindFn(0, [t], () => this._selectTab(t)),
                            "child": new Container({
                              "padding": (this.__k3 || (this.__k3 = EdgeInsets.symmetric({
                                "horizontal": 15,
                                "vertical": 6
                              }))),
                              "decoration": new BoxDecoration({
                                "color": (this._tab == t) ? (this.__k4 || (this.__k4 = new Color({
                                  "value": 0xFFE8F2FF
                                }))) : (this.__k5 || (this.__k5 = new Color({
                                  "value": 0xFFF3F5F8
                                }))),
                                "borderRadius": BorderRadius.circular({
                                  "radius": 15
                                })
                              }),
                              "child": new Text({
                                "style": new TextStyle({
                                  "fontSize": 13.5,
                                  "fontWeight": (this._tab == t) ? FontWeight.w700 : FontWeight.w500,
                                  "color": (this._tab == t) ? kBrand : (this.__k6 || (this.__k6 = new Color({
                                    "value": 0xFF5C6270
                                  })))
                                }),
                                "data": t
                              })
                            })
                          })
                        })]); } return out; })(),
                  (this.__k7 || (this.__k7 = new Spacer({}))),
                  new GestureDetector({
                    "onTap": this.__bindFn(1, [], () => _app_host_.invoke("toast", ["发布新动态（演示）"])),
                    "child": new Container({
                      "width": 32,
                      "height": 32,
                      "decoration": (this.__k8 || (this.__k8 = new BoxDecoration({
                        "color": new Color({
                          "value": 0xFFF3F5F8
                        }),
                        "shape": "circle"
                      }))),
                      "child": (this.__k9 || (this.__k9 = new Icon({
                        "color": new Color({
                          "value": 0xFF5C6270
                        }),
                        "icon": "edit",
                        "size": 16
                      })))
                    })
                  })
                ]
              })
            })
          })
        }),
        (this.__k10 || (this.__k10 = new SizedBox({
          "height": 10
        }))),
        new SizedBox({
          "height": 116,
          "child": ListView.separated({
            "scrollDirection": "horizontal",
            "padding": (this.__k11 || (this.__k11 = EdgeInsets.symmetric({
              "horizontal": 12
            }))),
            "itemCount": this._resources.length,
            "separatorBuilder": (context, index) => (this.__k12 || (this.__k12 = new SizedBox({
              "width": 10
            }))),
            "itemBuilder": (context, i) => new _ResourceCard({
              "resource": this._resources[i],
              "onTap": () => { return _app_host_.invoke("openResource", [this._resources[i].id]); }
            })
          })
        }),
        (this.__k13 || (this.__k13 = new SizedBox({
          "height": 12
        }))),
        new Container({
          "color": Colors.white,
          "padding": (this.__k14 || (this.__k14 = EdgeInsets.fromLTRB({
            "bottom": 8,
            "left": 12,
            "right": 12,
            "top": 8
          }))),
          "child": new Row({
            "children": [
              ...(() => { var out = []; for (let s of this._feed.sorts) { out.push.apply(out, [new Padding({
                      "padding": (this.__k15 || (this.__k15 = EdgeInsets.only({
                        "right": 6
                      }))),
                      "child": new GestureDetector({
                        "onTap": this.__bindFn(2, [s], () => this._selectFilter("sort", s)),
                        "child": new Container({
                          "padding": (this.__k16 || (this.__k16 = EdgeInsets.symmetric({
                            "horizontal": 12,
                            "vertical": 5
                          }))),
                          "decoration": new BoxDecoration({
                            "color": (this._sort == s) ? (this.__k4 || (this.__k4 = new Color({
                              "value": 0xFFE8F2FF
                            }))) : (this.__k5 || (this.__k5 = new Color({
                              "value": 0xFFF3F5F8
                            }))),
                            "borderRadius": BorderRadius.circular({
                              "radius": 14
                            })
                          }),
                          "child": new Text({
                            "style": new TextStyle({
                              "fontSize": 12.5,
                              "fontWeight": (this._sort == s) ? FontWeight.w700 : FontWeight.w500,
                              "color": (this._sort == s) ? kBrand : (this.__k6 || (this.__k6 = new Color({
                                "value": 0xFF5C6270
                              })))
                            }),
                            "data": s
                          })
                        })
                      })
                    })]); } return out; })(),
              (this.__k7 || (this.__k7 = new Spacer({}))),
              new GestureDetector({
                "onTap": this.__bindFn(3, [], (...__a) => this._toggleFilter(...__a)),
                "child": new Container({
                  "padding": (this.__k17 || (this.__k17 = EdgeInsets.symmetric({
                    "horizontal": 11,
                    "vertical": 5
                  }))),
                  "decoration": new BoxDecoration({
                    "color": this._filterOpen ? (this.__k4 || (this.__k4 = new Color({
                      "value": 0xFFE8F2FF
                    }))) : (this.__k5 || (this.__k5 = new Color({
                      "value": 0xFFF3F5F8
                    }))),
                    "borderRadius": BorderRadius.circular({
                      "radius": 14
                    })
                  }),
                  "child": new Row({
                    "children": [
                      new Text({
                        "style": new TextStyle({
                          "fontSize": 12.5,
                          "fontWeight": FontWeight.w600,
                          "color": this._filterOpen ? kBrand : (this.__k6 || (this.__k6 = new Color({
                            "value": 0xFF5C6270
                          })))
                        }),
                        "data": "筛选"
                      }),
                      (this.__k18 || (this.__k18 = new SizedBox({
                        "width": 3
                      }))),
                      new Icon({
                        "size": 14,
                        "color": this._filterOpen ? kBrand : (this.__k6 || (this.__k6 = new Color({
                          "value": 0xFF5C6270
                        }))),
                        "icon": "tune"
                      })
                    ]
                  })
                })
              })
            ]
          })
        }),
        ...(this._listLoading ? [(this.__k19 || (this.__k19 = new LinearProgressIndicator({
            "minHeight": 2
          })))] : []),
        new Expanded({
          "child": (this._posts == null) ? (this.__k0 || (this.__k0 = new Center({
            "child": new CircularProgressIndicator({})
          }))) : new _ListContent({
            "resetFilter": (...__a) => this._resetFilter(...__a),
            "openFilter": this._filterOpen,
            "toggleFilter": (...__a) => this._toggleFilter(...__a),
            "feed": this._feed,
            "list": this._posts,
            "sort": this._sort,
            "type": this._type,
            "dist": this._dist,
            "price": this._price,
            "onSelectFilter": (...__a) => this._selectFilter(...__a)
          })
        })
      ]
    });
  }
  get wantKeepAlive() {
    return true;
  }
}

// 组件 _ListContent
export class _ListContent {
  constructor(args) {
    this.props = args || {};
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.list = (args && args.list !== undefined) ? args.list : [];
    this.feed = (args && args.feed !== undefined) ? args.feed : null;
    this.openFilter = (args && args.openFilter !== undefined) ? args.openFilter : false;
    this.sort = (args && args.sort !== undefined) ? args.sort : '';
    this.type = (args && args.type !== undefined) ? args.type : '';
    this.dist = (args && args.dist !== undefined) ? args.dist : '';
    this.price = (args && args.price !== undefined) ? args.price : '';
    this.resetFilter = (args && args.resetFilter !== undefined) ? args.resetFilter : null;
    this.onSelectFilter = (args && args.onSelectFilter !== undefined) ? args.onSelectFilter : null;
    this.toggleFilter = (args && args.toggleFilter !== undefined) ? args.toggleFilter : null;
  }
  initState() {
    console.log("--_ListContent init");
  }
  didUpdateWidget(oldWidget) {
    console.log("--_ListContent didUpdateWidget 0");
    if ((this.list.length != oldWidget.list.length)) {
      console.log("-- _ListContent didUpdateWidget 1");
    }
  }
  build(context) {
    var posts = this.list;
    var filterOpen = this.openFilter;
    return new Stack({
      "children": [
        new ListView({
          "padding": (this.__k0 || (this.__k0 = EdgeInsets.only({
            "bottom": 20
          }))),
          "children": [
            ...(this.list.isEmpty ? [(this.__k1 || (this.__k1 = new Padding({
                "child": new Center({
                  "child": new Text({
                    "style": new TextStyle({
                      "fontSize": 13,
                      "color": new Color({
                        "value": 0xFF98A0AC
                      })
                    }),
                    "data": "没有符合条件的帖子，试试放宽筛选条件"
                  })
                }),
                "padding": EdgeInsets.symmetric({
                  "vertical": 60
                })
              })))] : (() => { var out = []; for (let p of this.list) { out.push.apply(out, [new Padding({
                    "padding": (this.__k2 || (this.__k2 = EdgeInsets.fromLTRB({
                      "bottom": 10,
                      "left": 12,
                      "right": 12,
                      "top": 0
                    }))),
                    "child": new _PostCard({
                      "post": p,
                      "onTap": () => { return _app_host_.invoke("openPost", [p.id]); }
                    })
                  })]); } return out; })())
          ]
        }),
        ...(this.openFilter ? [Positioned.fill({
            "child": new GestureDetector({
              "onTap": this.__bindFn(0, [], (...__a) => this.toggleFilter(...__a)),
              "child": new Container({
                "color": (this.__k3 || (this.__k3 = new Color({
                  "value": 0x66000000
                })))
              })
            })
          }), new Positioned({
            "left": 0,
            "right": 0,
            "top": 0,
            "child": new _FilterPanel({
              "feed": this.feed,
              "sort": this.sort,
              "type": this.type,
              "dist": this.dist,
              "price": this.price,
              "onPick": this.onSelectFilter,
              "onReset": this.resetFilter,
              "onApply": this.toggleFilter
            })
          })] : [])
      ]
    });
  }
}

// 组件 _FilterPanel
export class _FilterPanel {
  constructor(args) {
    this.props = args || {};
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.feed = (args && args.feed !== undefined) ? args.feed : null;
    this.sort = (args && args.sort !== undefined) ? args.sort : '';
    this.type = (args && args.type !== undefined) ? args.type : '';
    this.dist = (args && args.dist !== undefined) ? args.dist : '';
    this.price = (args && args.price !== undefined) ? args.price : '';
    this.onPick = (args && args.onPick !== undefined) ? args.onPick : null;
    this.onReset = (args && args.onReset !== undefined) ? args.onReset : null;
    this.onApply = (args && args.onApply !== undefined) ? args.onApply : null;
  }
  initState() {
    console.debug("[_FilterPanel] initState");
  }
  didChangeDependencies() {
    console.debug("[_FilterPanel] didChangeDependencies");
  }
  didUpdateWidget(oldWidget) {
    console.debug("[_FilterPanel] didUpdateWidget: old=" + __str(oldWidget));
  }
  deactivate() {
    console.debug("[_FilterPanel] deactivate");
  }
  activate() {
    console.debug("[_FilterPanel] activate");
  }
  dispose() {
    console.debug("[_FilterPanel] dispose");
  }
  _group(title, key, values, current) {
    return new Column({
      "crossAxisAlignment": "start",
      "children": [
        new Padding({
          "padding": (this.__k0 || (this.__k0 = EdgeInsets.only({
            "bottom": 8
          }))),
          "child": new Text({
            "style": (this.__k1 || (this.__k1 = new TextStyle({
              "color": new Color({
                "value": 0xFF171A21
              }),
              "fontSize": 12.5,
              "fontWeight": FontWeight.w700
            }))),
            "data": title
          })
        }),
        new Wrap({
          "spacing": 8,
          "runSpacing": 8,
          "children": [
            ...(() => { var out = []; for (let v of values) { out.push.apply(out, [new GestureDetector({
                    "onTap": this.__bindFn(0, [key, v], () => this.onPick(key, v)),
                    "child": new Container({
                      "padding": (this.__k2 || (this.__k2 = EdgeInsets.symmetric({
                        "horizontal": 13,
                        "vertical": 6
                      }))),
                      "decoration": new BoxDecoration({
                        "color": (current == v) ? kBrand : (this.__k3 || (this.__k3 = new Color({
                          "value": 0xFFF3F5F8
                        }))),
                        "borderRadius": BorderRadius.circular({
                          "radius": 14
                        })
                      }),
                      "child": new Text({
                        "style": new TextStyle({
                          "fontSize": 12,
                          "fontWeight": FontWeight.w500,
                          "color": (current == v) ? Colors.white : (this.__k4 || (this.__k4 = new Color({
                            "value": 0xFF5C6270
                          })))
                        }),
                        "data": v
                      })
                    })
                  })]); } return out; })()
          ]
        })
      ]
    });
  }
  build(context) {
    return new Material({
      "color": Colors.white,
      "elevation": 8,
      "child": new Padding({
        "padding": (this.__k5 || (this.__k5 = EdgeInsets.fromLTRB({
          "bottom": 14,
          "left": 16,
          "right": 16,
          "top": 16
        }))),
        "child": new Column({
          "crossAxisAlignment": "start",
          "children": [
            this._group("排序方式", "sort", this.feed.sorts, this.sort),
            (this.__k6 || (this.__k6 = new SizedBox({
              "height": 16
            }))),
            this._group("内容类型", "type", this.feed.postTypes, this.type),
            (this.__k6 || (this.__k6 = new SizedBox({
              "height": 16
            }))),
            this._group("距离范围", "dist", this.feed.dists, this.dist),
            (this.__k6 || (this.__k6 = new SizedBox({
              "height": 16
            }))),
            this._group("价格区间", "price", this.feed.priceRanges, this.price),
            (this.__k7 || (this.__k7 = new SizedBox({
              "height": 18
            }))),
            new Row({
              "children": [
                new Expanded({
                  "child": new GestureDetector({
                    "onTap": this.__bindFn(1, [], (...__a) => this.onReset(...__a)),
                    "child": new Container({
                      "height": 42,
                      "alignment": Alignment.center,
                      "decoration": new BoxDecoration({
                        "color": (this.__k3 || (this.__k3 = new Color({
                          "value": 0xFFF3F5F8
                        }))),
                        "borderRadius": BorderRadius.circular({
                          "radius": 21
                        })
                      }),
                      "child": (this.__k8 || (this.__k8 = new Text({
                        "data": "重置",
                        "style": new TextStyle({
                          "fontSize": 14,
                          "fontWeight": FontWeight.w600,
                          "color": new Color({
                            "value": 0xFF5C6270
                          })
                        })
                      })))
                    })
                  })
                }),
                (this.__k9 || (this.__k9 = new SizedBox({
                  "width": 10
                }))),
                new Expanded({
                  "child": new GestureDetector({
                    "onTap": this.__bindFn(2, [], (...__a) => this.onApply(...__a)),
                    "child": new Container({
                      "height": 42,
                      "alignment": Alignment.center,
                      "decoration": new BoxDecoration({
                        "color": kBrand,
                        "borderRadius": BorderRadius.circular({
                          "radius": 21
                        })
                      }),
                      "child": (this.__k10 || (this.__k10 = new Text({
                        "data": "查看结果",
                        "style": new TextStyle({
                          "fontSize": 14,
                          "fontWeight": FontWeight.w600,
                          "color": Colors.white
                        })
                      })))
                    })
                  })
                })
              ]
            })
          ]
        })
      })
    });
  }
}

// 组件 _PostCard
export class _PostCard {
  constructor(args) {
    this.props = args || {};
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.post = (args && args.post !== undefined) ? args.post : null;
    this.onTap = (args && args.onTap !== undefined) ? args.onTap : null;
  }
  static _likeText(n) {
    return ((n > 999) ? ((n / 1000)).toStringAsFixed(1) + "k" : n);
  }
  build(context) {
    return new GestureDetector({
      "onTap": this.__bindFn(0, [], (...__a) => this.onTap(...__a)),
      "child": new Container({
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
          "crossAxisAlignment": "start",
          "children": [
            new ClipRRect({
              "borderRadius": BorderRadius.circular({
                "radius": 10
              }),
              "child": Image.asset({
                "width": 92,
                "height": 92,
                "fit": "cover",
                "errorBuilder": (context, e, s) => new Container({
                  "width": 92,
                  "height": 92,
                  "color": (this.__k1 || (this.__k1 = new Color({
                    "value": 0xFFE8EBF0
                  })))
                }),
                "name": this.post.img
              })
            }),
            (this.__k2 || (this.__k2 = new SizedBox({
              "width": 11
            }))),
            new Expanded({
              "child": new SizedBox({
                "height": 92,
                "child": new Column({
                  "crossAxisAlignment": "start",
                  "children": [
                    new Text({
                      "maxLines": 1,
                      "overflow": "ellipsis",
                      "style": (this.__k3 || (this.__k3 = new TextStyle({
                        "fontSize": 14.5,
                        "fontWeight": FontWeight.w600
                      }))),
                      "data": this.post.title
                    }),
                    (this.__k4 || (this.__k4 = new SizedBox({
                      "height": 5
                    }))),
                    new Expanded({
                      "child": new Text({
                        "maxLines": 2,
                        "overflow": "ellipsis",
                        "style": (this.__k5 || (this.__k5 = new TextStyle({
                          "color": new Color({
                            "value": 0xFF8B909A
                          }),
                          "fontSize": 11.5,
                          "height": 1.5
                        }))),
                        "data": this.post.sub
                      })
                    }),
                    new Row({
                      "children": [
                        new Container({
                          "padding": (this.__k6 || (this.__k6 = EdgeInsets.symmetric({
                            "horizontal": 5,
                            "vertical": 1
                          }))),
                          "decoration": new BoxDecoration({
                            "color": (this.__k7 || (this.__k7 = new Color({
                              "value": 0xFFF3F5F8
                            }))),
                            "borderRadius": BorderRadius.circular({
                              "radius": 5
                            })
                          }),
                          "child": new Text({
                            "style": (this.__k8 || (this.__k8 = new TextStyle({
                              "color": new Color({
                                "value": 0xFF5C6270
                              }),
                              "fontSize": 10
                            }))),
                            "data": this.post.type
                          })
                        }),
                        (this.__k9 || (this.__k9 = new SizedBox({
                          "width": 6
                        }))),
                        new Text({
                          "style": (this.__k10 || (this.__k10 = new TextStyle({
                            "color": new Color({
                              "value": 0xFFA3A9B4
                            }),
                            "fontSize": 10.5
                          }))),
                          "data": this.post.author + " · " + this.post.time
                        }),
                        (this.__k11 || (this.__k11 = new Spacer({}))),
                        (this.__k12 || (this.__k12 = new Icon({
                          "color": new Color({
                            "value": 0xFFA3A9B4
                          }),
                          "icon": "favorite_border",
                          "size": 13
                        }))),
                        (this.__k13 || (this.__k13 = new SizedBox({
                          "width": 3
                        }))),
                        new Text({
                          "style": (this.__k10 || (this.__k10 = new TextStyle({
                            "color": new Color({
                              "value": 0xFFA3A9B4
                            }),
                            "fontSize": 10.5
                          }))),
                          "data": _PostCard._likeText(this.post.like)
                        })
                      ]
                    })
                  ]
                })
              })
            })
          ]
        })
      })
    });
  }
}

// 组件 _ResourceCard
export class _ResourceCard {
  constructor(args) {
    this.props = args || {};
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.resource = (args && args.resource !== undefined) ? args.resource : null;
    this.onTap = (args && args.onTap !== undefined) ? args.onTap : null;
  }
  build(context) {
    return new GestureDetector({
      "onTap": this.__bindFn(0, [], (...__a) => this.onTap(...__a)),
      "child": new Container({
        "width": 156,
        "clipBehavior": "antiAlias",
        "decoration": new BoxDecoration({
          "color": Colors.white,
          "borderRadius": BorderRadius.circular({
            "radius": 14
          })
        }),
        "child": new Column({
          "crossAxisAlignment": "start",
          "children": [
            new SizedBox({
              "height": 68,
              "child": Image.asset({
                "fit": "cover",
                "errorBuilder": (context, e, s) => new Container({
                  "height": 68,
                  "color": (this.__k0 || (this.__k0 = new Color({
                    "value": 0xFFE8EBF0
                  })))
                }),
                "name": this.resource.img
              })
            }),
            new Padding({
              "padding": (this.__k1 || (this.__k1 = EdgeInsets.fromLTRB({
                "bottom": 6,
                "left": 9,
                "right": 9,
                "top": 6
              }))),
              "child": new Column({
                "crossAxisAlignment": "start",
                "children": [
                  new Text({
                    "maxLines": 1,
                    "overflow": "ellipsis",
                    "style": (this.__k2 || (this.__k2 = new TextStyle({
                      "fontSize": 12.5,
                      "fontWeight": FontWeight.w600
                    }))),
                    "data": this.resource.title
                  }),
                  (this.__k3 || (this.__k3 = new SizedBox({
                    "height": 2
                  }))),
                  new Text({
                    "maxLines": 1,
                    "overflow": "ellipsis",
                    "style": (this.__k4 || (this.__k4 = new TextStyle({
                      "color": new Color({
                        "value": 0xFF98A0AC
                      }),
                      "fontSize": 10.5
                    }))),
                    "data": this.resource.sub
                  })
                ]
              })
            })
          ]
        })
      })
    });
  }
}

