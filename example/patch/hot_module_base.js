// GENERATED CODE - DO NOT EDIT
// 跨包模块（package: hot_module_base）：由 hot_patch_generator 生成
// 本包内被项目组件引用到的类集中于此文件（跨包翻译）

import { Alignment, AnimatedOpacity, BorderRadius, BoxDecoration, Color, Colors, Column, CompositedTransformFollower, CompositedTransformTarget, Container, Duration, EdgeInsets, IgnorePointer, LayerLink, Offset, OverlayPortal, OverlayPortalController, Padding, Positioned, SizedBox, Stack, Text, TextStyle, Timer, Transform } from 'flutter.js';

// 模型 User
export class User {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.name = (args && args.name !== undefined) ? args.name : '';
    this.age = (args && args.age !== undefined) ? args.age : 0;
  }
}

// 组件 GuideBubbleWidget
export class GuideBubbleWidget {
  static _fadeDuration = new Duration({milliseconds: 200});
  static _arrowWidth = 24;
  static _arrowHeight = 9;
  static _arrowInset = 20;
  static _arrowSide = (GuideBubbleWidget._arrowHeight * 1.4142);
  static _arrowAngle = 0.7853981633974483;
  constructor(args) {
    this.props = args || {};
    this.__applyProps(args);
    this._controller = new OverlayPortalController();
    this._layerLink = new LayerLink();
    this._timer = null;
    this._fadeTimer = null;
    this._visible = true;
  }
  __applyProps(args) {
    this.child = (args && args.child !== undefined) ? args.child : null;
    this.text = (args && args.text !== undefined) ? args.text : '';
    this.duration = (args && args.duration !== undefined) ? args.duration : new Duration({seconds: 5});
    this.alignment = (args && args.alignment !== undefined) ? args.alignment : "right";
    this.gap = (args && args.gap !== undefined) ? args.gap : 8.0;
    this.backgroundColor = (args && args.backgroundColor !== undefined) ? args.backgroundColor : new Color({value: 0xE6161616});
    this.textColor = (args && args.textColor !== undefined) ? args.textColor : Colors.white;
    this.textFontSize = (args && args.textFontSize !== undefined) ? args.textFontSize : 16.0;
  }
  initState() {
    this._schedule();
  }
  _schedule() {
    this._cancelTimers();
    this._visible = true;
    this._controller.show();
    this._timer = new Timer({duration: this.duration, callback: () => { this.setState(() => { this._visible = false; });
        this._fadeTimer = new Timer({duration: GuideBubbleWidget._fadeDuration, callback: () => { this._controller.hide(); }}); }});
  }
  _cancelTimers() {
    var timer = this._timer;
    if ((timer != null)) {
      timer.cancel();
    }
    this._timer = null;
    var fadeTimer = this._fadeTimer;
    if ((fadeTimer != null)) {
      fadeTimer.cancel();
    }
    this._fadeTimer = null;
  }
  didUpdateWidget(oldWidget) {
    var restart = (((((((oldWidget.text != this.text) || (oldWidget.alignment != this.alignment)) || (oldWidget.gap != this.gap)) || (oldWidget.duration != this.duration)) || (oldWidget.backgroundColor != this.backgroundColor)) || (oldWidget.textColor != this.textColor)) || (oldWidget.textFontSize != this.textFontSize));
    if ((!restart)) {
      return;
    }
    this.setState(() => { this._schedule(); });
  }
  dispose() {
    this._cancelTimers();
  }
  build(context) {
    return new OverlayPortal({
      "controller": this._controller,
      "overlayChildBuilder": (...__a) => this._buildOverlayChild(...__a),
      "child": new CompositedTransformTarget({
        "link": this._layerLink,
        "child": this.child
      })
    });
  }
  _buildOverlayChild(context) {
    var centered = (this.alignment == "center");
    var right = (this.alignment == "right");
    return new CompositedTransformFollower({
      "link": this._layerLink,
      "showWhenUnlinked": false,
      "offset": new Offset({
        "dx": 0,
        "dy": this.gap
      }),
      "targetAnchor": centered ? Alignment.bottomCenter : ((right ? Alignment.bottomRight : Alignment.bottomLeft)),
      "followerAnchor": centered ? Alignment.topCenter : ((right ? Alignment.topRight : Alignment.topLeft)),
      "child": new IgnorePointer({
        "child": new AnimatedOpacity({
          "opacity": this._visible ? 1 : 0,
          "duration": GuideBubbleWidget._fadeDuration,
          "child": this._buildBubbleContent()
        })
      })
    });
  }
  _buildBubbleContent() {
    var children = [this._arrowRow(), new Container({
        "padding": (this.__k0 || (this.__k0 = EdgeInsets.symmetric({
          "horizontal": 16,
          "vertical": 10
        }))),
        "decoration": new BoxDecoration({
          "color": this.backgroundColor,
          "borderRadius": BorderRadius.circular({
            "radius": 12
          })
        }),
        "child": new Text({
          "style": new TextStyle({
            "fontSize": this.textFontSize,
            "color": this.textColor,
            "height": 1.2
          }),
          "data": this.text
        })
      })];
    if ((this.alignment == "center")) {
      return new Column({
        "mainAxisSize": "min",
        "crossAxisAlignment": "center",
        "children": children
      });
    }
    if ((this.alignment == "right")) {
      return new Column({
        "mainAxisSize": "min",
        "crossAxisAlignment": "end",
        "children": children
      });
    }
    return new Column({
      "mainAxisSize": "min",
      "crossAxisAlignment": "start",
      "children": children
    });
  }
  _arrowRow() {
    if ((this.alignment == "right")) {
      return new Padding({
        "padding": (this.__k1 || (this.__k1 = EdgeInsets.only({
          "right": GuideBubbleWidget._arrowInset
        }))),
        "child": this._buildArrow()
      });
    }
    if ((this.alignment == "center")) {
      return this._buildArrow();
    }
    return new Padding({
      "padding": (this.__k2 || (this.__k2 = EdgeInsets.only({
        "left": GuideBubbleWidget._arrowInset
      }))),
      "child": this._buildArrow()
    });
  }
  _buildArrow() {
    return new SizedBox({
      "width": GuideBubbleWidget._arrowWidth,
      "height": GuideBubbleWidget._arrowHeight,
      "child": new Stack({
        "children": [
          new Positioned({
            "left": (((GuideBubbleWidget._arrowWidth - GuideBubbleWidget._arrowSide)) / 2),
            "top": (GuideBubbleWidget._arrowHeight - (GuideBubbleWidget._arrowSide / 2)),
            "child": Transform.rotate({
              "angle": GuideBubbleWidget._arrowAngle,
              "child": new Container({
                "width": GuideBubbleWidget._arrowSide,
                "height": GuideBubbleWidget._arrowSide,
                "color": this.backgroundColor
              })
            })
          })
        ]
      })
    });
  }
}
