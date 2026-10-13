// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/app/pages/community_page.dart 自动生成
// 重新生成：dart run build_runner build

import { Post } from '../model/app_models.js';
import { Resource } from '../model/app_models.js';
import { kBrand } from 'detail_pages.js';
import { kCommunityTabs, kDists, kPostTypes, kPosts, kPriceRanges, kResources, kSorts } from '../model/app_data.js';
import { ListView, __h } from '../../flutter.js';

// 组件 CommunityPage
export class CommunityPage {
  constructor() {
    this._tab = kCommunityTabs[0];
    this._filterOpen = false;
    this._sort = kSorts[0];
    this._type = kPostTypes[0];
    this._dist = kDists[0];
    this._price = kPriceRanges[0];
  }
  get _visiblePosts() {
    var list = kPosts.filter((p) => { return ((this._type == kPostTypes[0]) || (p.type == this._type)); });
    switch (this._sort) {
      case "最新":
        list = [...list].reverse();
      break;
      case "最热":
        list = (() => { const _t = list; _t.sort((a, b) => { return (b.like - a.like); }); return _t; })();
      break;
    }
    return list;
  }
  _toggleFilter() {
    this.setState(function(){ this._filterOpen = (!this._filterOpen); });
  }
  _resetFilter() {
    this.setState(function(){ this._sort = kSorts[0]; this._type = kPostTypes[0]; this._dist = kDists[0]; this._price = kPriceRanges[0]; });
  }
  build() {
    var posts = this._visiblePosts;
    return __h('Column', {}, [
        __h('Container', {
            "color": '#FFFFFF'
          }, [
            __h('SafeArea', {
                "bottom": false
              }, [
                __h('Padding', {
                    "padding": {
                      "left": 12.0,
                      "top": 4.0,
                      "right": 12.0,
                      "bottom": 10.0
                    }
                  }, [
                    __h('Row', {}, [
                        ...(() => { var out = []; for (let t of kCommunityTabs) { out.push.apply(out, [__h('Padding', { "padding": { "left": 0.0, "top": 0.0, "right": 8.0, "bottom": 0.0 } }, [ __h('GestureDetector', { "event": this.__bindFn("() => setState(() => _tab = t)" + ":" + String(t), () => { this.setState(() => { this._tab = t; }); }) }, [ __h('Container', { "padding": { "left": 15.0, "top": 6.0, "right": 15.0, "bottom": 6.0 }, "decoration": { "color": ((this._tab == t) ? '#ffe8f2ff' : '#fff3f5f8'), "borderRadius": { "radius": 15.0 } } }, [ __h('Text', { "data": t, "style": { "fontSize": 13.5, "color": ((this._tab == t) ? kBrand : '#ff5c6270') } }) ]) ]) ])]); } return out; })(),
                        __h('Spacer', {}),
                        __h('GestureDetector', {
                            "event": this.__bind("__jsui.host(\"toast\", [\"发布新动态（演示）\"])")
                          }, [
                            __h('Container', {
                                "width": 32,
                                "height": 32,
                                "decoration": {
                                  "color": '#fff3f5f8',
                                  "shape": "circle"
                                }
                              }, [
                                __h('Icon', {
                                    "icon": "edit",
                                    "size": 16,
                                    "color": '#ff5c6270'
                                  })
                              ])
                          ])
                      ])
                  ])
              ])
          ]),
        __h('SizedBox', {
            "height": 10
          }),
        __h('SizedBox', {
            "height": 116
          }, [
            __h(ListView, {
                "scrollDirection": "horizontal",
                "padding": {
                  "left": 12.0,
                  "top": 0.0,
                  "right": 12.0,
                  "bottom": 0.0
                },
                "builder": "_listViewBuilder0",
                "itemCount": kResources.length,
                "separatorBuilder": "_listViewBuilderSeparator1"
              })
          ]),
        __h('SizedBox', {
            "height": 12
          }),
        __h('Container', {
            "color": '#FFFFFF',
            "padding": {
              "left": 12.0,
              "top": 8.0,
              "right": 12.0,
              "bottom": 8.0
            }
          }, [
            __h('Row', {}, [
                ...(() => { var out = []; for (let s of kSorts) { out.push.apply(out, [__h('Padding', { "padding": { "left": 0.0, "top": 0.0, "right": 6.0, "bottom": 0.0 } }, [ __h('GestureDetector', { "event": this.__bindFn("() => setState(() => _sort = s)" + ":" + String(s), () => { this.setState(() => { this._sort = s; }); }) }, [ __h('Container', { "padding": { "left": 12.0, "top": 5.0, "right": 12.0, "bottom": 5.0 }, "decoration": { "color": ((this._sort == s) ? '#ffe8f2ff' : '#fff3f5f8'), "borderRadius": { "radius": 14.0 } } }, [ __h('Text', { "data": s, "style": { "fontSize": 12.5, "color": ((this._sort == s) ? kBrand : '#ff5c6270') } }) ]) ]) ])]); } return out; })(),
                __h('Spacer', {}),
                __h('GestureDetector', {
                    "event": this.__bind("_toggleFilter")
                  }, [
                    __h('Container', {
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
                        }
                      }, [
                        __h('Row', {}, [
                            __h('Text', {
                                "data": "筛选",
                                "style": {
                                  "fontSize": 12.5,
                                  "fontWeight": "w600",
                                  "color": (this._filterOpen ? kBrand : '#ff5c6270')
                                }
                              }),
                            __h('SizedBox', {
                                "width": 3
                              }),
                            __h('Icon', {
                                "icon": "tune",
                                "size": 14,
                                "color": (this._filterOpen ? kBrand : '#ff5c6270')
                              })
                          ])
                      ])
                  ])
              ])
          ]),
        __h('Expanded', {}, [
            __h('Stack', {}, [
                __h('ListView', {
                    "padding": {
                      "left": 0.0,
                      "top": 0.0,
                      "right": 0.0,
                      "bottom": 20.0
                    }
                  }, [
                    ...((this._visiblePosts.length === 0) ? [__h('Padding', { "padding": { "left": 0.0, "top": 60.0, "right": 0.0, "bottom": 60.0 } }, [ __h('Center', {}, [ __h('Text', { "data": "没有符合条件的帖子，试试放宽筛选条件", "style": { "fontSize": 13, "color": '#ff98a0ac' } }) ]) ])] : (() => { var out = []; for (let p of this._visiblePosts) { out.push.apply(out, [__h('Padding', { "padding": { "left": 12.0, "top": 0.0, "right": 12.0, "bottom": 10.0 } }, [ __h(_PostCard, { "post": p, "onTap": () => { return __jsui.host("openPost", [p.id]); } }) ])]); } return out; })())
                  ]),
                ...(this._filterOpen ? [__h('Positioned', { "left": 0, "top": 0, "right": 0, "bottom": 0 }, [ __h('GestureDetector', { "event": this.__bind("_toggleFilter") }, [ __h('Container', { "color": '#66000000' }) ]) ]), __h('Positioned', { "left": 0, "top": 0, "right": 0 }, [ __h(_FilterPanel, { "sort": this._sort, "type": this._type, "dist": this._dist, "price": this._price, "onPick": (key, value) => { this.setState(function(){ switch (key) { case "sort": this._sort = value; break; case "type": this._type = value; break; case "dist": this._dist = value; break; case "price": this._price = value; break; } }); }, "onReset": (...__a) => this._resetFilter(...__a), "onApply": (...__a) => this._toggleFilter(...__a) }) ])] : [])
              ])
          ])
      ]);
  }
  _listViewBuilder0(i) {
      return __h(_ResourceCard, {
        "resource": kResources[i],
        "onTap": () => { return __jsui.host("openResource", [kResources[i].id]); }
      });
  }
  _listViewBuilderSeparator1(_) {
      return __h('SizedBox', {
        "width": 10
      });
  }
}

// 组件 _FilterPanel
export class _FilterPanel {
  constructor(args) {
    this.sort = (args && args.sort !== undefined) ? args.sort : '';
    this.type = (args && args.type !== undefined) ? args.type : '';
    this.dist = (args && args.dist !== undefined) ? args.dist : '';
    this.price = (args && args.price !== undefined) ? args.price : '';
    this.onPick = (args && args.onPick !== undefined) ? args.onPick : null;
    this.onReset = (args && args.onReset !== undefined) ? args.onReset : null;
    this.onApply = (args && args.onApply !== undefined) ? args.onApply : null;
  }
  _group(title, key, values, current) {
    return __h('Column', {
        "crossAxisAlignment": "start"
      }, [
        __h('Padding', {
            "padding": {
              "left": 0.0,
              "top": 0.0,
              "right": 0.0,
              "bottom": 8.0
            }
          }, [
            __h('Text', {
                "data": title,
                "style": {
                  "fontSize": 12.5,
                  "fontWeight": "w700",
                  "color": '#ff171a21'
                }
              })
          ]),
        __h('Wrap', {
            "spacing": 8,
            "runSpacing": 8
          }, [
            ...(() => { var out = []; for (let v of values) { out.push.apply(out, [__h('GestureDetector', { "event": this.__bindFn("() => onPick(key, v)" + ":" + String(v), () => { this.onPick(key, v); }) }, [ __h('Container', { "padding": { "left": 13.0, "top": 6.0, "right": 13.0, "bottom": 6.0 }, "decoration": { "color": ((current == v) ? kBrand : '#fff3f5f8'), "borderRadius": { "radius": 14.0 } } }, [ __h('Text', { "data": v, "style": { "fontSize": 12, "fontWeight": "w500", "color": ((current == v) ? '#FFFFFF' : '#ff5c6270') } }) ]) ])]); } return out; })()
          ])
      ]);
  }
  build() {
    return __h("Component", {
        "component": "Material",
        "args": {
          "color": Colors.white,
          "elevation": 8,
          "child": __h('Padding', {
              "padding": {
                "left": 16.0,
                "top": 16.0,
                "right": 16.0,
                "bottom": 14.0
              }
            }, [
              __h('Column', {
                  "crossAxisAlignment": "start"
                }, [
                  this._group("排序方式", "sort", kSorts, this.sort),
                  __h('SizedBox', {
                      "height": 16
                    }),
                  this._group("内容类型", "type", kPostTypes, this.type),
                  __h('SizedBox', {
                      "height": 16
                    }),
                  this._group("距离范围", "dist", kDists, this.dist),
                  __h('SizedBox', {
                      "height": 16
                    }),
                  this._group("价格区间", "price", kPriceRanges, this.price),
                  __h('SizedBox', {
                      "height": 18
                    }),
                  __h('Row', {}, [
                      __h('Expanded', {}, [
                          __h('GestureDetector', {
                              "event": this.__bind("this.onReset()")
                            }, [
                              __h('Container', {
                                  "height": 42,
                                  "alignment": "center",
                                  "decoration": {
                                    "color": '#fff3f5f8',
                                    "borderRadius": {
                                      "radius": 21.0
                                    }
                                  }
                                }, [
                                  __h('Text', {
                                      "data": "重置",
                                      "style": {
                                        "fontSize": 14,
                                        "fontWeight": "w600",
                                        "color": '#ff5c6270'
                                      }
                                    })
                                ])
                            ])
                        ]),
                      __h('SizedBox', {
                          "width": 10
                        }),
                      __h('Expanded', {}, [
                          __h('GestureDetector', {
                              "event": this.__bind("this.onApply()")
                            }, [
                              __h('Container', {
                                  "height": 42,
                                  "alignment": "center",
                                  "decoration": {
                                    "color": kBrand,
                                    "borderRadius": {
                                      "radius": 21.0
                                    }
                                  }
                                }, [
                                  __h('Text', {
                                      "data": "查看结果",
                                      "style": {
                                        "fontSize": 14,
                                        "fontWeight": "w600",
                                        "color": '#FFFFFF'
                                      }
                                    })
                                ])
                            ])
                        ])
                    ])
                ])
            ])
        }
      }, null);
  }
}

// 组件 _PostCard
export class _PostCard {
  constructor(args) {
    this.post = (args && args.post !== undefined) ? args.post : null;
    this.onTap = (args && args.onTap !== undefined) ? args.onTap : null;
  }
  _likeText(n) {
    return ((n > 999) ? ((n / 1000)).toFixed(1) + "k" : n);
  }
  build() {
    return __h('GestureDetector', {
        "event": this.__bind("this.onTap()")
      }, [
        __h('Container', {
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
            }
          }, [
            __h('Row', {
                "crossAxisAlignment": "start"
              }, [
                __h('ClipRRect', {
                    "child": __h('Image', {
                        "source": this.post.img,
                        "width": 92,
                        "height": 92,
                        "fit": "cover"
                      })
                  }),
                __h('SizedBox', {
                    "width": 11
                  }),
                __h('Expanded', {}, [
                    __h('SizedBox', {
                        "height": 92
                      }, [
                        __h('Column', {
                            "crossAxisAlignment": "start"
                          }, [
                            __h('Text', {
                                "data": this.post.title,
                                "style": {
                                  "fontSize": 14.5,
                                  "fontWeight": "w600"
                                },
                                "maxLines": 1,
                                "overflow": "ellipsis"
                              }),
                            __h('SizedBox', {
                                "height": 5
                              }),
                            __h('Expanded', {}, [
                                __h('Text', {
                                    "data": this.post.sub,
                                    "style": {
                                      "fontSize": 11.5,
                                      "color": '#ff8b909a',
                                      "height": 1.5
                                    },
                                    "maxLines": 2,
                                    "overflow": "ellipsis"
                                  })
                              ]),
                            __h('Row', {}, [
                                __h('Container', {
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
                                    }
                                  }, [
                                    __h('Text', {
                                        "data": this.post.type,
                                        "style": {
                                          "fontSize": 10,
                                          "color": '#ff5c6270'
                                        }
                                      })
                                  ]),
                                __h('SizedBox', {
                                    "width": 6
                                  }),
                                __h('Text', {
                                    "data": this.post.author + " · " + this.post.time,
                                    "style": {
                                      "fontSize": 10.5,
                                      "color": '#ffa3a9b4'
                                    }
                                  }),
                                __h('Spacer', {}),
                                __h('Icon', {
                                    "icon": "favorite_border",
                                    "size": 13,
                                    "color": '#ffa3a9b4'
                                  }),
                                __h('SizedBox', {
                                    "width": 3
                                  }),
                                __h('Text', {
                                    "data": this._likeText(this.post.like),
                                    "style": {
                                      "fontSize": 10.5,
                                      "color": '#ffa3a9b4'
                                    }
                                  })
                              ])
                          ])
                      ])
                  ])
              ])
          ])
      ]);
  }
}

// 组件 _ResourceCard
export class _ResourceCard {
  constructor(args) {
    this.resource = (args && args.resource !== undefined) ? args.resource : null;
    this.onTap = (args && args.onTap !== undefined) ? args.onTap : null;
  }
  build() {
    return __h('GestureDetector', {
        "event": this.__bind("this.onTap()")
      }, [
        __h('Container', {
            "width": 156,
            "decoration": {
              "color": '#FFFFFF',
              "borderRadius": {
                "radius": 14.0
              }
            },
            "clipBehavior": "antiAlias"
          }, [
            __h('Column', {
                "crossAxisAlignment": "start"
              }, [
                __h('SizedBox', {
                    "height": 68
                  }, [
                    __h('Image', {
                        "source": this.resource.img,
                        "fit": "cover"
                      })
                  ]),
                __h('Padding', {
                    "padding": {
                      "left": 9.0,
                      "top": 6.0,
                      "right": 9.0,
                      "bottom": 6.0
                    }
                  }, [
                    __h('Column', {
                        "crossAxisAlignment": "start"
                      }, [
                        __h('Text', {
                            "data": this.resource.title,
                            "style": {
                              "fontSize": 12.5,
                              "fontWeight": "w600"
                            },
                            "maxLines": 1,
                            "overflow": "ellipsis"
                          }),
                        __h('SizedBox', {
                            "height": 2
                          }),
                        __h('Text', {
                            "data": this.resource.sub,
                            "style": {
                              "fontSize": 10.5,
                              "color": '#ff98a0ac'
                            },
                            "maxLines": 1,
                            "overflow": "ellipsis"
                          })
                      ])
                  ])
              ])
          ])
      ]);
  }
}

