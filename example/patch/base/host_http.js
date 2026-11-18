// GENERATED CODE - DO NOT EDIT
// 由 dynamic_flutter_generator 从 lib/base/host_http.dart 自动生成
// 重新生成：dart run build_runner build

import '../packages/dio.js';

// 模型 HostHttp
export class HostHttp {
  constructor() {
  }
  static async get(url) {
    return _app_host_.invoke("httpGet", Array.prototype.slice.call(arguments));
  }
}

