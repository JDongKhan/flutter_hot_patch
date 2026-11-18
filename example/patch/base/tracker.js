// GENERATED CODE - DO NOT EDIT
// 由 dynamic_flutter_generator 从 lib/base/tracker.dart 自动生成
// 重新生成：dart run build_runner build

import '../flutter.js';

// 模型 Tracker
export class Tracker {
  constructor() {
  }
  static exposure(event, params) {
    Tracker._report("exposure", event, params);
  }
  static click(event, params) {
    Tracker._report("click", event, params);
  }
  static _report(type, event, params) {
    let detail = "";
    params.forEach(((__v, __k) => ((key, value) => { detail = detail + " " + key + "=" + value; })(__k, __v)));
    debugPrint("[Tracker] " + type + " · " + event + detail);
  }
  // 命名构造 Tracker._
  static _(args) {
    const __o = new Tracker(args);
    return __o;
  }
}

