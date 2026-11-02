// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/base/web_view.dart 自动生成
// 重新生成：dart run build_runner build


// 模型 WebView
export class WebView {
  constructor() {
  }
  static async open(url, title) {
    return _app_host_.invoke("open", Array.prototype.slice.call(arguments));
  }
}

