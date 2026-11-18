// GENERATED CODE - DO NOT EDIT
// 由 dynamic_flutter_generator 从 lib/app/widgets/countdown_text.dart 自动生成
// 重新生成：dart run build_runner build

import { DateTime, Duration, FontWeight, StatefulWidget, Text, TextStyle, Timer } from '../../flutter.js';

const _countdownText = (sec) => { const safe = ((sec < 0) ? 0 : sec);
  const h = Math.trunc(safe / 3600);
  const m = Math.trunc((__mod(safe, 3600)) / 60);
  const s = __mod(safe, 60);
  const mm = ((m < 10) ? "0" + m : "" + m);
  const ss = ((s < 10) ? "0" + s : "" + s);
  if ((h > 0)) {
    const hh = ((h < 10) ? "0" + h : "" + h);
    return hh + ":" + mm + ":" + ss;
  }
  return mm + ":" + ss; };

// 组件 CountdownText
export class CountdownText extends StatefulWidget {
  constructor(args) {
    super(args);
    this.__applyProps(args);
    this._timer = null;
    this._left = 0;
  }
  __applyProps(args) {
    this.deadlineMillis = (args && args.deadlineMillis !== undefined) ? args.deadlineMillis : 0;
    this.color = (args && args.color !== undefined) ? args.color : null;
    this.fontSize = (args && args.fontSize !== undefined) ? args.fontSize : 13.5;
    this.zeroText = (args && args.zeroText !== undefined) ? args.zeroText : "00:00";
  }
  initState() {
    super.initState();
    this._left = this._remainSeconds();
    this._start();
  }
  didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.deadlineMillis !== this.deadlineMillis)) {
      this._left = this._remainSeconds();
      this._start();
    }
  }
  dispose() {
    this._stop();
    super.dispose();
  }
  _start() {
    this._stop();
    if ((this._left <= 0)) {
      return;
    }
    this._timer = Timer.periodic({duration: new Duration({seconds: 1}), callback: (timer) => { return this._tick(timer); }});
  }
  _stop() {
    this._timer?.cancel();
    this._timer = null;
  }
  _tick(timer) {
    if ((__nn(this._timer) == null)) {
      return;
    }
    const left = this._remainSeconds();
    if ((left <= 0)) {
      this._stop();
      this.setState(() => {
        this._left = 0;
      });
      return;
    }
    this.setState(() => {
      this._left = left;
    });
  }
  _remainSeconds() {
    const diff = (this.deadlineMillis - DateTime.now().millisecondsSinceEpoch);
    if ((diff <= 0)) {
      return 0;
    }
    return Math.trunc(((diff + 999)) / 1000);
  }
  build(context) {
    return new Text({
      "style": new TextStyle({
        "fontSize": this.fontSize,
        "fontWeight": FontWeight.w700,
        "color": this.color
      }),
      "data": (this._left <= 0) ? this.zeroText : _countdownText(this._left)
    });
  }
}

