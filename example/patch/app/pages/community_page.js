// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/app/pages/community_page.dart 自动生成
// 重新生成：dart run build_runner build

import { AppService } from '../service/app_service.js';
import { CommunityFeed } from '../model/app_models.js';
import { Post } from '../model/app_models.js';
import { Resource } from '../model/app_models.js';
import { kBrand } from 'detail_pages.js';
import { Center, CircularProgressIndicator, ClipRRect, Column, Container, Expanded, GestureDetector, Icon, Image, LinearProgressIndicator, ListView, Material, Padding, Positioned, Row, SafeArea, SizedBox, Spacer, Stack, Text, Wrap, __h } from '../../flutter.js';

// 组件 CommunityPage
export class CommunityPage {
  constructor(args) {
    this.props = args || {};
    this._service = new AppService();
    this._feed = null;
    this._posts = null;
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
  _selectTab(tab) {
    this.setState(() => { this._tab = tab; });
    this._loadPosts();
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
    if ((feed == null)) {
      return (this.__k0 || (this.__k0 = new Center({
          "child": new CircularProgressIndicator({})
        })));
    }
    return new Column({
        "children": [
          new Container({
              "color": '#FFFFFF',
              "child": new SafeArea({
                  "bottom": false,
                  "child": new Padding({
                      "padding": {
                        "left": 12.0,
                        "top": 4.0,
                        "right": 12.0,
                        "bottom": 10.0
                      },
                      "child": new Row({
                          "children": [
                            ...(() => { var out = []; for (let t of this._feed.tabs) { out.push.apply(out, [new Padding({
                              "padding": {
                                "left": 0.0,
                                "top": 0.0,
                                "right": 8.0,
                                "bottom": 0.0
                              },
                              "child": new GestureDetector({
                                  "onTap": this.__bindFn(0, [t], () => this._selectTab(t)),
                                  "child": new Container({
                                      "padding": {
                                        "left": 15.0,
                                        "top": 6.0,
                                        "right": 15.0,
                                        "bottom": 6.0
                                      },
                                      "decoration": {
                                        "color": ((this._tab == t) ? '#ffe8f2ff' : '#fff3f5f8'),
                                        "borderRadius": {
                                          "radius": 15.0
                                        }
                                      },
                                      "child": new Text({
                                          "style": {
                                            "fontSize": 13.5,
                                            "color": ((this._tab == t) ? kBrand : '#ff5c6270')
                                          },
                                          "data": t
                                        })
                                    })
                                })
                            })]); } return out; })(),
                            (this.__k2 || (this.__k2 = new Spacer({}))),
                            new GestureDetector({
                                "onTap": this.__bindFn(1, [], () => _app_host_.invoke("toast", ["发布新动态（演示）"])),
                                "child": new Container({
                                    "width": 32,
                                    "height": 32,
                                    "decoration": {
                                      "color": '#fff3f5f8',
                                      "shape": "circle"
                                    },
                                    "child": (this.__k3 || (this.__k3 = new Icon({
                                        "color": '#ff5c6270',
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
          (this.__k4 || (this.__k4 = new SizedBox({
              "height": 10
            }))),
          new SizedBox({
              "height": 116,
              "child": ListView.separated({
                  "scrollDirection": "horizontal",
                  "padding": {
                    "left": 12.0,
                    "top": 0.0,
                    "right": 12.0,
                    "bottom": 0.0
                  },
                  "itemCount": this._feed.resources.length,
                  "separatorBuilder": "_separatorBuilder0",
                  "itemBuilder": "_itemBuilder1"
                })
            }),
          (this.__k5 || (this.__k5 = new SizedBox({
              "height": 12
            }))),
          new Container({
              "color": '#FFFFFF',
              "padding": {
                "left": 12.0,
                "top": 8.0,
                "right": 12.0,
                "bottom": 8.0
              },
              "child": new Row({
                  "children": [
                    ...(() => { var out = []; for (let s of this._feed.sorts) { out.push.apply(out, [new Padding({
                      "padding": {
                        "left": 0.0,
                        "top": 0.0,
                        "right": 6.0,
                        "bottom": 0.0
                      },
                      "child": new GestureDetector({
                          "onTap": this.__bindFn(2, [s], () => this._selectFilter("sort", s)),
                          "child": new Container({
                              "padding": {
                                "left": 12.0,
                                "top": 5.0,
                                "right": 12.0,
                                "bottom": 5.0
                              },
                              "decoration": {
                                "color": ((this._sort == s) ? '#ffe8f2ff' : '#fff3f5f8'),
                                "borderRadius": {
                                  "radius": 14.0
                                }
                              },
                              "child": new Text({
                                  "style": {
                                    "fontSize": 12.5,
                                    "color": ((this._sort == s) ? kBrand : '#ff5c6270')
                                  },
                                  "data": s
                                })
                            })
                        })
                    })]); } return out; })(),
                    (this.__k2 || (this.__k2 = new Spacer({}))),
                    new GestureDetector({
                        "onTap": this.__bindFn(3, [], (...__a) => this._toggleFilter(...__a)),
                        "child": new Container({
                            "padding": {
                              "left": 11.0,
                              "top": 5.0,
                              "right": 11.0,
                              "bottom": 5.0
                            },
                            "decoration": {
                              "color": (this._filterOpen ? '#ffe8f2ff' : '#fff3f5f8'),
                              "borderRadius": {
                                "radius": 14.0
                              }
                            },
                            "child": new Row({
                                "children": [
                                  new Text({
                                      "style": {
                                        "fontSize": 12.5,
                                        "fontWeight": "w600",
                                        "color": (this._filterOpen ? kBrand : '#ff5c6270')
                                      },
                                      "data": "筛选"
                                    }),
                                  (this.__k6 || (this.__k6 = new SizedBox({
                                      "width": 3
                                    }))),
                                  new Icon({
                                      "size": 14,
                                      "color": this._filterOpen ? kBrand : '#ff5c6270',
                                      "icon": "tune"
                                    })
                                ]
                              })
                          })
                      })
                  ]
                })
            }),
          ...(this._listLoading ? [(this.__k1 || (this.__k1 = new LinearProgressIndicator({
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
  _separatorBuilder0(context, _) {
      return (this.__k7 || (this.__k7 = new SizedBox({
        "width": 10
      })));
  }
  _itemBuilder1(context, i) {
      return new _ResourceCard({
        "resource": this._feed.resources[i],
        "onTap": () => { return _app_host_.invoke("openResource", [this._feed.resources[i].id]); }
      });
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
          __h('ListView', {
              "padding": {
                "left": 0.0,
                "top": 0.0,
                "right": 0.0,
                "bottom": 20.0
              },
              "children": [
                ...(this.list.isEmpty ? [(this.__k0 || (this.__k0 = new Padding({
                  "child": new Center({
                      "child": new Text({
                          "data": "没有符合条件的帖子，试试放宽筛选条件",
                          "style": {
                            "color": '#ff98a0ac',
                            "fontSize": 13
                          }
                        })
                    }),
                  "padding": {
                    "bottom": 60.0,
                    "left": 0.0,
                    "right": 0.0,
                    "top": 60.0
                  }
                })))] : (() => { var out = []; for (let p of this.list) { out.push.apply(out, [new Padding({
                  "padding": {
                    "left": 12.0,
                    "top": 0.0,
                    "right": 12.0,
                    "bottom": 10.0
                  },
                  "child": new _PostCard({
                      "post": p,
                      "onTap": () => { return _app_host_.invoke("openPost", [p.id]); }
                    })
                })]); } return out; })())
              ]
            }),
          ...(this.openFilter ? [new Positioned({
            "child": new GestureDetector({
                "onTap": this.__bindFn(0, [], (...__a) => this.toggleFilter(...__a)),
                "child": new Container({
                    "color": '#66000000'
                  })
              }),
            "factory": "fill"
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
              "padding": {
                "left": 0.0,
                "top": 0.0,
                "right": 0.0,
                "bottom": 8.0
              },
              "child": new Text({
                  "style": {
                    "fontSize": 12.5,
                    "fontWeight": "w700",
                    "color": '#ff171a21'
                  },
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
                      "padding": {
                        "left": 13.0,
                        "top": 6.0,
                        "right": 13.0,
                        "bottom": 6.0
                      },
                      "decoration": {
                        "color": ((current == v) ? kBrand : '#fff3f5f8'),
                        "borderRadius": {
                          "radius": 14.0
                        }
                      },
                      "child": new Text({
                          "style": {
                            "fontSize": 12,
                            "fontWeight": "w500",
                            "color": ((current == v) ? '#FFFFFF' : '#ff5c6270')
                          },
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
        "color": '#FFFFFF',
        "elevation": 8,
        "child": new Padding({
            "padding": {
              "left": 16.0,
              "top": 16.0,
              "right": 16.0,
              "bottom": 14.0
            },
            "child": new Column({
                "crossAxisAlignment": "start",
                "children": [
                  this._group("排序方式", "sort", this.feed.sorts, this.sort),
                  (this.__k0 || (this.__k0 = new SizedBox({
                      "height": 16
                    }))),
                  this._group("内容类型", "type", this.feed.postTypes, this.type),
                  (this.__k0 || (this.__k0 = new SizedBox({
                      "height": 16
                    }))),
                  this._group("距离范围", "dist", this.feed.dists, this.dist),
                  (this.__k0 || (this.__k0 = new SizedBox({
                      "height": 16
                    }))),
                  this._group("价格区间", "price", this.feed.priceRanges, this.price),
                  (this.__k1 || (this.__k1 = new SizedBox({
                      "height": 18
                    }))),
                  new Row({
                      "children": [
                        new Expanded({
                            "child": new GestureDetector({
                                "onTap": this.__bindFn(1, [], (...__a) => this.onReset(...__a)),
                                "child": new Container({
                                    "height": 42,
                                    "alignment": "center",
                                    "decoration": {
                                      "color": '#fff3f5f8',
                                      "borderRadius": {
                                        "radius": 21.0
                                      }
                                    },
                                    "child": (this.__k2 || (this.__k2 = new Text({
                                        "data": "重置",
                                        "style": {
                                          "color": '#ff5c6270',
                                          "fontSize": 14,
                                          "fontWeight": "w600"
                                        }
                                      })))
                                  })
                              })
                          }),
                        (this.__k3 || (this.__k3 = new SizedBox({
                            "width": 10
                          }))),
                        new Expanded({
                            "child": new GestureDetector({
                                "onTap": this.__bindFn(2, [], (...__a) => this.onApply(...__a)),
                                "child": new Container({
                                    "height": 42,
                                    "alignment": "center",
                                    "decoration": {
                                      "color": kBrand,
                                      "borderRadius": {
                                        "radius": 21.0
                                      }
                                    },
                                    "child": (this.__k4 || (this.__k4 = new Text({
                                        "data": "查看结果",
                                        "style": {
                                          "color": '#FFFFFF',
                                          "fontSize": 14,
                                          "fontWeight": "w600"
                                        }
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
  _likeText(n) {
    return ((n > 999) ? ((n / 1000)).toStringAsFixed(1) + "k" : n);
  }
  build(context) {
    return new GestureDetector({
        "onTap": this.__bindFn(0, [], (...__a) => this.onTap(...__a)),
        "child": new Container({
            "padding": {
              "left": 10.0,
              "top": 10.0,
              "right": 10.0,
              "bottom": 10.0
            },
            "decoration": {
              "color": '#FFFFFF',
              "borderRadius": {
                "radius": 14.0
              }
            },
            "child": new Row({
                "crossAxisAlignment": "start",
                "children": [
                  new ClipRRect({
                      "borderRadius": {
                        "radius": 10.0
                      },
                      "child": new Image({
                          "width": 92,
                          "height": 92,
                          "fit": "cover",
                          "errorBuilder": "_errorBuilder0",
                          "factory": "network",
                          "src": this.post.img
                        })
                    }),
                  (this.__k0 || (this.__k0 = new SizedBox({
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
                                    "style": {
                                      "fontSize": 14.5,
                                      "fontWeight": "w600"
                                    },
                                    "data": this.post.title
                                  }),
                                (this.__k1 || (this.__k1 = new SizedBox({
                                    "height": 5
                                  }))),
                                new Expanded({
                                    "child": new Text({
                                        "maxLines": 2,
                                        "overflow": "ellipsis",
                                        "style": {
                                          "fontSize": 11.5,
                                          "color": '#ff8b909a',
                                          "height": 1.5
                                        },
                                        "data": this.post.sub
                                      })
                                  }),
                                new Row({
                                    "children": [
                                      new Container({
                                          "padding": {
                                            "left": 5.0,
                                            "top": 1.0,
                                            "right": 5.0,
                                            "bottom": 1.0
                                          },
                                          "decoration": {
                                            "color": '#fff3f5f8',
                                            "borderRadius": {
                                              "radius": 5.0
                                            }
                                          },
                                          "child": new Text({
                                              "style": {
                                                "fontSize": 10,
                                                "color": '#ff5c6270'
                                              },
                                              "data": this.post.type
                                            })
                                        }),
                                      (this.__k2 || (this.__k2 = new SizedBox({
                                          "width": 6
                                        }))),
                                      new Text({
                                          "style": {
                                            "fontSize": 10.5,
                                            "color": '#ffa3a9b4'
                                          },
                                          "data": this.post.author + " · " + this.post.time
                                        }),
                                      (this.__k3 || (this.__k3 = new Spacer({}))),
                                      (this.__k4 || (this.__k4 = new Icon({
                                          "color": '#ffa3a9b4',
                                          "icon": "favorite_border",
                                          "size": 13
                                        }))),
                                      (this.__k5 || (this.__k5 = new SizedBox({
                                          "width": 3
                                        }))),
                                      new Text({
                                          "style": {
                                            "fontSize": 10.5,
                                            "color": '#ffa3a9b4'
                                          },
                                          "data": this._likeText(this.post.like)
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
  _errorBuilder0(context, e) {
      return new Container({
        "width": 92,
        "height": 92,
        "color": '#ffe8ebf0'
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
            "decoration": {
              "color": '#FFFFFF',
              "borderRadius": {
                "radius": 14.0
              }
            },
            "child": new Column({
                "crossAxisAlignment": "start",
                "children": [
                  new SizedBox({
                      "height": 68,
                      "child": new Image({
                          "fit": "cover",
                          "errorBuilder": "_errorBuilder0",
                          "factory": "network",
                          "src": this.resource.img
                        })
                    }),
                  new Padding({
                      "padding": {
                        "left": 9.0,
                        "top": 6.0,
                        "right": 9.0,
                        "bottom": 6.0
                      },
                      "child": new Column({
                          "crossAxisAlignment": "start",
                          "children": [
                            new Text({
                                "maxLines": 1,
                                "overflow": "ellipsis",
                                "style": {
                                  "fontSize": 12.5,
                                  "fontWeight": "w600"
                                },
                                "data": this.resource.title
                              }),
                            (this.__k0 || (this.__k0 = new SizedBox({
                                "height": 2
                              }))),
                            new Text({
                                "maxLines": 1,
                                "overflow": "ellipsis",
                                "style": {
                                  "fontSize": 10.5,
                                  "color": '#ff98a0ac'
                                },
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
  _errorBuilder0(context, e) {
      return new Container({
        "height": 68,
        "color": '#ffe8ebf0'
      });
  }
}

