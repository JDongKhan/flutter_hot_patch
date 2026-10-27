// @hot_patch protocol: 0.3.2
// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/app/widgets/banner_carousel.dart 自动生成
// 重新生成：dart run build_runner build

import { HomeBanner } from '../model/app_models.js';
import { ClipRRect, Column, Container, Image, InkWell, Padding, PageView, Positioned, Row, SizedBox, Stack, Text } from '../../flutter.js';

const _height = 150;
const _interval = new Duration({seconds: 5});
const _animate = new Duration({milliseconds: 350});

// 组件 BannerCarousel
export class BannerCarousel {
  constructor(args) {
    this.props = args || {};
    this.__applyProps(args);
    this._controller = new PageController();
    this._timer = null;
    this._index = 0;
  }
  __applyProps(args) {
    this.banners = (args && args.banners !== undefined) ? args.banners : [];
  }
  initState() {
    this._startAutoPlay();
  }
  didUpdateWidget(oldWidget) {
    if ((oldWidget.banners != this.banners)) {
      this._reset();
    }
  }
  dispose() {
    this._stopAutoPlay();
    this._controller.dispose();
  }
  _reset() {
    var count = this.banners.length;
    if ((count == 0)) {
      this._stopAutoPlay();
      this._index = 0;
      return;
    }
    if ((this._index >= count)) {
      this._index = 0;
      if (this._controller.hasClients) {
        this._controller.jumpToPage(0);
      }
    }
    this._startAutoPlay();
  }
  _stopAutoPlay() {
    var timer = this._timer;
    if ((timer != null)) {
      timer.cancel();
    }
    this._timer = null;
  }
  _startAutoPlay() {
    this._stopAutoPlay();
    if ((this.banners.length < 2)) {
      return;
    }
    this._timer = Timer.periodic({duration: _interval, callback: (timer) => { return this._tick(timer); }});
  }
  _tick(timer) {
    if ((this._timer == null)) {
      return;
    }
    var count = this.banners.length;
    if ((count < 2)) {
      return;
    }
    var next = (((this._index + 1)) % count);
    this._controller.animateToPage(next, _animate, Curves.easeOut);
    this.setState(() => { this._index = next; });
  }
  _onPageChanged(index) {
    this.setState(() => { this._index = index; });
  }
  build(context) {
    var banners = this.banners;
    if ((banners.length == 0)) {
      return (this.__k0 || (this.__k0 = new SizedBox({})));
    }
    return new Column({
        "mainAxisSize": "min",
        "children": [
          new SizedBox({
              "height": _height,
              "child": new PageView({
                "controller": this._controller,
                "onPageChanged": this.__bindFn(0, [], (...__a) => this._onPageChanged(...__a)),
                "children": [
                  ...(() => { var out = []; for (let i = 0; (i < this.banners.length); (i++)) { out.push.apply(out, [new BannerSlide({
                    "banner": this.banners[i]
                  })]); } return out; })()
                ]
              })
            }),
          (this.__k1 || (this.__k1 = new SizedBox({
              "height": 10
            }))),
          new Row({
              "mainAxisAlignment": "center",
              "children": [
                ...(() => { var out = []; for (let i = 0; (i < this.banners.length); (i++)) { out.push.apply(out, [new Container({
                  "margin": {
                    "left": 3.0,
                    "top": 0.0,
                    "right": 3.0,
                    "bottom": 0.0
                  },
                  "width": 6,
                  "height": 6,
                  "decoration": {
                    "color": ((i == this._index) ? new Color({value: 0xFF0E7AFB}) : new Color({value: 0xFFD5D9E0})),
                    "borderRadius": {
                      "radius": 3.0
                    }
                  }
                })]); } return out; })()
              ]
            })
        ]
      });
  }
}

// 组件 BannerSlide
export class BannerSlide {
  constructor(args) {
    this.props = args || {};
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.banner = (args && args.banner !== undefined) ? args.banner : null;
  }
  open() {
    _app_host_.invoke("toast", [this.banner.title]);
  }
  build(context) {
    return new Padding({
        "padding": {
          "left": 12.0,
          "top": 0.0,
          "right": 12.0,
          "bottom": 0.0
        },
        "child": new InkWell({
          "onTap": this.__bindFn(0, [], (...__a) => this.open(...__a)),
          "borderRadius": {
            "radius": 14.0
          },
          "child": new ClipRRect({
            "borderRadius": {
              "radius": 14.0
            },
            "child": new Stack({
              "fit": "expand",
              "children": [
                new Image({
                    "fit": "cover",
                    "factory": "network",
                    "src": this.banner.img
                  }),
                new Container({
                    "decoration": {
                      "gradient": {
                        "kind": "linear",
                        "colors": [
                          new Color({value: 0x00000000}),
                          new Color({value: 0xB3000000})
                        ],
                        "begin": "center",
                        "end": "bottomCenter"
                      }
                    }
                  }),
                new Positioned({
                    "left": 14,
                    "right": 14,
                    "bottom": 14,
                    "child": new Column({
                      "crossAxisAlignment": "start",
                      "children": [
                        new Text({
                            "style": {
                              "color": new Color({value: 0xFFFFFFFF}),
                              "fontSize": 17,
                              "fontWeight": "w700"
                            },
                            "data": this.banner.title
                          }),
                        (this.__k0 || (this.__k0 = new SizedBox({
                            "height": 4
                          }))),
                        new Text({
                            "style": {
                              "color": new Color({value: 0xE6FFFFFF}),
                              "fontSize": 12
                            },
                            "data": this.banner.sub
                          })
                      ]
                    })
                  })
              ]
            })
          })
        })
      });
  }
}

