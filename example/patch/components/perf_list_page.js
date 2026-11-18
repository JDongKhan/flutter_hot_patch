// GENERATED CODE - DO NOT EDIT
// 由 dynamic_flutter_generator 从 lib/components/perf_list_page.dart 自动生成
// 重新生成：dart run build_runner build

import { Alignment, AnimatedContainer, AnimatedOpacity, AnimatedScale, Border, BorderRadius, BoxDecoration, BoxFit, Center, ClipRRect, Color, Colors, Column, Container, CrossAxisAlignment, Curves, DecoratedBox, Duration, EdgeInsets, Expanded, FontWeight, Icon, Icons, Image, LinearGradient, ListView, Padding, Positioned, Row, SizedBox, Spacer, Stack, StackFit, StatefulWidget, Text, TextOverflow, TextStyle, Timer, Wrap } from '../flutter.js';

// 模型 PerfEntry
export class PerfEntry {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.seq = (args && args.seq !== undefined) ? args.seq : 0;
    this.img = (args && args.img !== undefined) ? args.img : '';
    this.title = (args && args.title !== undefined) ? args.title : '';
    this.sub = (args && args.sub !== undefined) ? args.sub : '';
    this.emoji = (args && args.emoji !== undefined) ? args.emoji : '';
    this.author = (args && args.author !== undefined) ? args.author : '';
    this.time = (args && args.time !== undefined) ? args.time : '';
    this.desc = (args && args.desc !== undefined) ? args.desc : '';
    this.tags = (args && args.tags !== undefined) ? args.tags : [];
    this.likes = (args && args.likes !== undefined) ? args.likes : '';
    this.comments = (args && args.comments !== undefined) ? args.comments : '';
    this.views = (args && args.views !== undefined) ? args.views : '';
  }
}

// 组件 PerfListPage
export class PerfListPage extends StatefulWidget {
  constructor(args) {
    super(args);
    this._entries = [];
  }
  build(context) {
    if (this._entries.isEmpty) {
      const items = [];
      for (let i = 0; (i < PerfListPage._total); (i++)) {
        const seqNo = i;
        const img = PerfListPage._imgs[__mod(i, PerfListPage._imgs.length)];
        const title = PerfListPage._titles[__mod(i, PerfListPage._titles.length)];
        const sub = PerfListPage._subs[__mod(i, PerfListPage._subs.length)];
        const emoji = PerfListPage._emojis[__mod(i, PerfListPage._emojis.length)];
        const author = PerfListPage._authors[__mod(i, PerfListPage._authors.length)];
        const time = PerfListPage._times[__mod(i, PerfListPage._times.length)];
        const desc = PerfListPage._descs[__mod(i, PerfListPage._descs.length)];
        const tag0 = PerfListPage._tagPool[__mod(i, PerfListPage._tagPool.length)];
        const tag1 = PerfListPage._tagPool[__mod(((i + 3)), PerfListPage._tagPool.length)];
        const tag2 = PerfListPage._tagPool[__mod(((i + 7)), PerfListPage._tagPool.length)];
        const likeCount = (__mod(((i * 137)), 9000) + 120);
        const commentCount = (__mod(((i * 29)), 420) + 8);
        const viewCount = (__mod(((i * 173)), 88000) + 900);
        items.add(new PerfEntry({
          "seq": seqNo,
          "img": img,
          "title": title,
          "sub": sub,
          "emoji": emoji,
          "author": author,
          "time": time,
          "desc": desc,
          "tags": [
            tag0,
            tag1,
            tag2
          ],
          "likes": "" + likeCount,
          "comments": "" + commentCount,
          "views": "" + viewCount
        }));
      }
      this._entries = items;
    }
    return ListView.builder({
      "padding": (this.__k0 || (this.__k0 = EdgeInsets.only({
        "bottom": 24,
        "top": 4
      }))),
      "itemCount": this._entries.length,
      "itemBuilder": (context, index) => new _PerfCard({
        "entry": this._entries[index]
      })
    });
  }
}
PerfListPage._total = 200;
PerfListPage._imgs = ["assets/images/photo-1448375240586-882707db888b.jpg", "assets/images/photo-1449965408869-eaa3f722e40d.jpg", "assets/images/photo-1464822759023-fed622ff2c3b.jpg", "assets/images/photo-1470004914212-05527e49370b.jpg", "assets/images/photo-1470071459604-3b5ec3a7fe05.jpg", "assets/images/photo-1470770841072-f978cf4d019e.jpg", "assets/images/photo-1478131143081-80f7f84ca84d.jpg", "assets/images/photo-1483664852095-d6cc6870702d.jpg", "assets/images/photo-1500375592092-40eb2168fd21.jpg", "assets/images/photo-1500530855697-b586d89ba3ee.jpg", "assets/images/photo-1501785888041-af3ef285b470.jpg", "assets/images/photo-1507525428034-b723cf961d3e.jpg"];
PerfListPage._titles = ["川西雪山 · 日照金山机位", "海边公路 · 一场说走就走的自驾", "古镇夜色 · 灯影里的石板路", "草原深处 · 无人区露营日记", "高原湖泊 · 风吹过的两个下午", "雪山脚下 · 一碗热汤面", "海岛清晨 · 第一缕光落在礁石上", "峡谷徒步 · 走了 18 公里之后", "沙漠星空 · 银河肉眼可见", "林间小屋 · 关掉手机的一晚", "温泉小镇 · 雪天泡汤指南", "城市天际线 · 天台看落日"];
PerfListPage._subs = ["海拔 4200 米 · 6 小时徒步 · 含向导", "全程 320 公里 · 3 晚住宿 · 油费参考", "19:30 亮灯 · 最佳机位在石桥西侧", "露营 2 晚 · 夜间 0℃ · 需自带睡袋", "日出 06:12 · 建议提前 40 分钟到", "人均 45 元 · 排队约 20 分钟", "潮汐表显示 05:40 退潮", "累计爬升 860 米 · 补给点 2 处", "无光污染 · 建议带三脚架", "木屋 6 间 · 需提前两周预订", "室外 42℃ · 室内 39℃ · 含浴衣", "日落 18:26 · 天台 27 层"];
PerfListPage._emojis = ["🏔", "🚗", "🏮", "⛺", "🌊", "🍜", "🌅", "🥾", "🌌", "🏡", "♨️", "🌇"];
PerfListPage._authors = ["山野慢行", "一只旅行箱", "半日闲", "去看海吧", "徒步日记", "深夜食堂", "风光记录者", "北纬三十度", "追星的人", "小院生活"];
PerfListPage._times = ["3 分钟前", "28 分钟前", "1 小时前", "今天 09:12", "昨天 21:40", "昨天 18:05", "2 天前", "3 天前", "上周", "10 月 28 日"];
PerfListPage._descs = ["这条线路走了三年，每次来都能遇到不一样的云。整理了一份详细的机位和补给点清单，" + "需要的朋友可以直接收藏。", "一路都是沿海公路，弯道很多，注意控制车速。中途有两个观景平台可以停车拍照，" + "建议留出半天时间慢慢走。", "亮灯之后人非常多，想拍空镜建议在 18:00 前占位。石桥西侧的倒影最完整，" + "带上小光圈和三脚架。", "夜里的风比想象中大，帐篷地钉一定要打牢。营地有简易热水，但信号几乎没有，" + "提前下载好离线地图。", "清晨的湖面基本没有风，倒影非常清楚。太阳出来后半小时光线就变硬了，" + "想拍柔和的画面要早起。", "下山之后第一件事就是找吃的，这家面馆的汤头很浓，加了一份牛肉才 12 块，" + "老板娘人很好。", "退潮之后的礁石上会露出很多小水洼，逆光拍剪影效果不错。注意不要踩到贝类，" + "鞋底容易打滑。", "全程 18 公里，累计爬升 860 米，正常体力 7 小时左右。中途两个补给点只卖水，" + "干粮要自己带够。", "十一点之后银河升到头顶，肉眼可以清楚看到一条光带。拍星轨的话建议 30 秒曝光，" + "每张间隔 2 秒。", "木屋没有空调，但夜里很凉快。屋里只有一盏灯和一个插座，" + "想办公的话建议自带插排。", "雪天泡汤是这趟行程最值的一段时间。室外池的温度在 42℃ 左右，" + "从池子里出来要马上裹上浴衣。", "天台的落日会被高楼挡掉一部分，18:20 之后光线反而更好，" + "蓝调时刻持续大约 15 分钟。"];
PerfListPage._tagPool = ["攻略", "自驾", "露营", "徒步", "摄影", "美食", "日出", "小众", "亲子", "避坑"];

// 组件 _PerfCard
export class _PerfCard extends StatefulWidget {
  constructor(args) {
    super(args);
    this.__applyProps(args);
    this._pulse = false;
    this._builds = 0;
    this._pulseTimer = null;
  }
  __applyProps(args) {
    this.entry = (args && args.entry !== undefined) ? args.entry : null;
  }
  initState() {
    super.initState();
    this._pulseTimer = Timer.periodic({duration: new Duration({milliseconds: 1400}), callback: (timer) => { if ((!!this.__unmounted)) {
          return;
        }
        this.setState(() => {
          this._pulse = (!this._pulse);
        }); }});
  }
  dispose() {
    this._pulseTimer?.cancel();
    this._pulseTimer = null;
    super.dispose();
  }
  build(context) {
    this._builds += 1;
    const e = this.entry;
    const tag0 = e.tags[0];
    return new Container({
      "margin": (this.__k0 || (this.__k0 = EdgeInsets.fromLTRB({
        "bottom": 2,
        "left": 12,
        "right": 12,
        "top": 10
      }))),
      "decoration": new BoxDecoration({
        "color": Colors.white,
        "borderRadius": BorderRadius.circular({
          "radius": 16
        })
      }),
      "child": new ClipRRect({
        "borderRadius": BorderRadius.circular({
          "radius": 16
        }),
        "child": new Column({
          "crossAxisAlignment": CrossAxisAlignment.stretch,
          "children": [
            new SizedBox({
              "height": 210,
              "child": new Stack({
                "fit": StackFit.expand,
                "children": [
                  Image.asset({
                    "fit": BoxFit.cover,
                    "errorBuilder": (context, err, stack) => new Container({
                      "color": (this.__k1 || (this.__k1 = new Color({
                        "value": 0xFFDDE3EC
                      })))
                    }),
                    "name": this.entry.img
                  }),
                  (this.__k2 || (this.__k2 = new DecoratedBox({
                    "decoration": new BoxDecoration({
                      "gradient": new LinearGradient({
                        "colors": [
                          new Color({
                            "value": 0x00000000
                          }),
                          new Color({
                            "value": 0xE6000000
                          })
                        ],
                        "begin": Alignment.topCenter,
                        "end": Alignment.bottomCenter
                      })
                    })
                  }))),
                  new Positioned({
                    "left": 12,
                    "right": 12,
                    "bottom": 10,
                    "child": new Column({
                      "crossAxisAlignment": CrossAxisAlignment.start,
                      "children": [
                        new Text({
                          "maxLines": 2,
                          "overflow": TextOverflow.ellipsis,
                          "style": (this.__k3 || (this.__k3 = new TextStyle({
                            "color": Colors.white,
                            "fontSize": 17,
                            "fontWeight": FontWeight.w700,
                            "height": 1.25
                          }))),
                          "data": this.entry.title
                        }),
                        (this.__k4 || (this.__k4 = new SizedBox({
                          "height": 4
                        }))),
                        new Text({
                          "maxLines": 1,
                          "overflow": TextOverflow.ellipsis,
                          "style": (this.__k5 || (this.__k5 = new TextStyle({
                            "color": new Color({
                              "value": 0xFFD6DCE6
                            }),
                            "fontSize": 11.5
                          }))),
                          "data": this.entry.sub
                        })
                      ]
                    })
                  }),
                  new Positioned({
                    "left": 10,
                    "top": 10,
                    "child": new Container({
                      "padding": (this.__k6 || (this.__k6 = EdgeInsets.symmetric({
                        "horizontal": 8,
                        "vertical": 3
                      }))),
                      "decoration": new BoxDecoration({
                        "color": (this.__k7 || (this.__k7 = new Color({
                          "value": 0xB3000000
                        }))),
                        "borderRadius": BorderRadius.circular({
                          "radius": 9
                        })
                      }),
                      "child": new Text({
                        "style": (this.__k8 || (this.__k8 = new TextStyle({
                          "color": Colors.white,
                          "fontSize": 10,
                          "fontWeight": FontWeight.w600
                        }))),
                        "data": "NO." + (this.entry.seq + 1)
                      })
                    })
                  }),
                  new Positioned({
                    "right": 10,
                    "top": 8,
                    "child": new AnimatedOpacity({
                      "opacity": this._pulse ? 1.0 : 0.35,
                      "duration": (this.__k9 || (this.__k9 = new Duration({
                        "milliseconds": 1400
                      }))),
                      "curve": Curves.easeInOut,
                      "child": new Container({
                        "padding": (this.__k10 || (this.__k10 = EdgeInsets.symmetric({
                          "horizontal": 9,
                          "vertical": 4
                        }))),
                        "decoration": new BoxDecoration({
                          "color": (this.__k11 || (this.__k11 = new Color({
                            "value": 0xFFFF5A36
                          }))),
                          "borderRadius": BorderRadius.circular({
                            "radius": 10
                          })
                        }),
                        "child": (this.__k12 || (this.__k12 = new Text({
                          "data": "HOT",
                          "style": new TextStyle({
                            "fontSize": 10,
                            "fontWeight": FontWeight.w700,
                            "color": Colors.white,
                            "letterSpacing": 0.5
                          })
                        })))
                      })
                    })
                  }),
                  new Center({
                    "child": new AnimatedScale({
                      "scale": this._pulse ? 1.12 : 1.0,
                      "duration": (this.__k9 || (this.__k9 = new Duration({
                        "milliseconds": 1400
                      }))),
                      "curve": Curves.easeInOut,
                      "child": new Container({
                        "width": 52,
                        "height": 52,
                        "alignment": Alignment.center,
                        "decoration": new BoxDecoration({
                          "color": (this.__k13 || (this.__k13 = new Color({
                            "value": 0x33FFFFFF
                          }))),
                          "borderRadius": BorderRadius.circular({
                            "radius": 26
                          }),
                          "border": Border.all({
                            "color": (this.__k14 || (this.__k14 = new Color({
                              "value": 0x66FFFFFF
                            })))
                          })
                        }),
                        "child": (this.__k15 || (this.__k15 = new Icon({
                          "color": Colors.white,
                          "icon": Icons.play_arrow,
                          "size": 26
                        })))
                      })
                    })
                  })
                ]
              })
            }),
            new Padding({
              "padding": (this.__k16 || (this.__k16 = EdgeInsets.fromLTRB({
                "bottom": 12,
                "left": 12,
                "right": 12,
                "top": 10
              }))),
              "child": new Column({
                "crossAxisAlignment": CrossAxisAlignment.start,
                "children": [
                  new Row({
                    "children": [
                      new Container({
                        "width": 30,
                        "height": 30,
                        "alignment": Alignment.center,
                        "decoration": new BoxDecoration({
                          "color": (this.__k17 || (this.__k17 = new Color({
                            "value": 0xFFE8F2FF
                          }))),
                          "borderRadius": BorderRadius.circular({
                            "radius": 15
                          })
                        }),
                        "child": new Text({
                          "style": (this.__k18 || (this.__k18 = new TextStyle({
                            "fontSize": 14
                          }))),
                          "data": this.entry.emoji
                        })
                      }),
                      (this.__k19 || (this.__k19 = new SizedBox({
                        "width": 8
                      }))),
                      new Expanded({
                        "child": new Column({
                          "crossAxisAlignment": CrossAxisAlignment.start,
                          "children": [
                            new Text({
                              "maxLines": 1,
                              "overflow": TextOverflow.ellipsis,
                              "style": (this.__k20 || (this.__k20 = new TextStyle({
                                "fontSize": 12.5,
                                "fontWeight": FontWeight.w600
                              }))),
                              "data": this.entry.author
                            }),
                            new Text({
                              "style": (this.__k21 || (this.__k21 = new TextStyle({
                                "color": new Color({
                                  "value": 0xFFA3A9B4
                                }),
                                "fontSize": 10.5
                              }))),
                              "data": this.entry.time
                            })
                          ]
                        })
                      }),
                      new AnimatedContainer({
                        "duration": (this.__k9 || (this.__k9 = new Duration({
                          "milliseconds": 1400
                        }))),
                        "curve": Curves.easeInOut,
                        "padding": (this.__k10 || (this.__k10 = EdgeInsets.symmetric({
                          "horizontal": 9,
                          "vertical": 4
                        }))),
                        "decoration": new BoxDecoration({
                          "color": this._pulse ? (this.__k22 || (this.__k22 = new Color({
                            "value": 0xFFFFF0E6
                          }))) : (this.__k17 || (this.__k17 = new Color({
                            "value": 0xFFE8F2FF
                          }))),
                          "borderRadius": BorderRadius.circular({
                            "radius": 10
                          })
                        }),
                        "child": new Text({
                          "style": (this.__k23 || (this.__k23 = new TextStyle({
                            "color": new Color({
                              "value": 0xFFC8621E
                            }),
                            "fontSize": 10.5,
                            "fontWeight": FontWeight.w600
                          }))),
                          "data": "#" + tag0
                        })
                      })
                    ]
                  }),
                  (this.__k24 || (this.__k24 = new SizedBox({
                    "height": 8
                  }))),
                  new Text({
                    "maxLines": 3,
                    "overflow": TextOverflow.ellipsis,
                    "style": (this.__k25 || (this.__k25 = new TextStyle({
                      "color": new Color({
                        "value": 0xFF4D5462
                      }),
                      "fontSize": 12,
                      "height": 1.5
                    }))),
                    "data": this.entry.desc
                  }),
                  (this.__k24 || (this.__k24 = new SizedBox({
                    "height": 8
                  }))),
                  new Wrap({
                    "spacing": 6,
                    "runSpacing": 5,
                    "children": [
                      ...(() => { var out = []; for (let t of this.entry.tags) { out.push.apply(out, [new Container({
                              "padding": (this.__k6 || (this.__k6 = EdgeInsets.symmetric({
                                "horizontal": 8,
                                "vertical": 3
                              }))),
                              "decoration": new BoxDecoration({
                                "color": (this.__k26 || (this.__k26 = new Color({
                                  "value": 0xFFF4F5F7
                                }))),
                                "borderRadius": BorderRadius.circular({
                                  "radius": 9
                                })
                              }),
                              "child": new Text({
                                "style": (this.__k27 || (this.__k27 = new TextStyle({
                                  "color": new Color({
                                    "value": 0xFF5C6270
                                  }),
                                  "fontSize": 10.5
                                }))),
                                "data": "#" + t
                              })
                            })]); } return out; })()
                    ]
                  }),
                  (this.__k28 || (this.__k28 = new SizedBox({
                    "height": 10
                  }))),
                  new Row({
                    "children": [
                      (this.__k29 || (this.__k29 = new Icon({
                        "color": new Color({
                          "value": 0xFF98A0AC
                        }),
                        "icon": Icons.favorite_border,
                        "size": 14
                      }))),
                      (this.__k30 || (this.__k30 = new SizedBox({
                        "width": 3
                      }))),
                      new Text({
                        "style": (this.__k31 || (this.__k31 = new TextStyle({
                          "color": new Color({
                            "value": 0xFF98A0AC
                          }),
                          "fontSize": 11
                        }))),
                        "data": this.entry.likes
                      }),
                      (this.__k32 || (this.__k32 = new SizedBox({
                        "width": 12
                      }))),
                      (this.__k33 || (this.__k33 = new Icon({
                        "color": new Color({
                          "value": 0xFF98A0AC
                        }),
                        "icon": Icons.chat_bubble_outline,
                        "size": 14
                      }))),
                      (this.__k30 || (this.__k30 = new SizedBox({
                        "width": 3
                      }))),
                      new Text({
                        "style": (this.__k31 || (this.__k31 = new TextStyle({
                          "color": new Color({
                            "value": 0xFF98A0AC
                          }),
                          "fontSize": 11
                        }))),
                        "data": this.entry.comments
                      }),
                      (this.__k32 || (this.__k32 = new SizedBox({
                        "width": 12
                      }))),
                      (this.__k34 || (this.__k34 = new Icon({
                        "color": new Color({
                          "value": 0xFF98A0AC
                        }),
                        "icon": Icons.visibility_outlined,
                        "size": 14
                      }))),
                      (this.__k30 || (this.__k30 = new SizedBox({
                        "width": 3
                      }))),
                      new Text({
                        "style": (this.__k31 || (this.__k31 = new TextStyle({
                          "color": new Color({
                            "value": 0xFF98A0AC
                          }),
                          "fontSize": 11
                        }))),
                        "data": this.entry.views
                      }),
                      (this.__k35 || (this.__k35 = new Spacer({}))),
                      new Text({
                        "style": (this.__k36 || (this.__k36 = new TextStyle({
                          "color": new Color({
                            "value": 0xFFC3C8D2
                          }),
                          "fontSize": 10
                        }))),
                        "data": "build " + this._builds
                      })
                    ]
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

