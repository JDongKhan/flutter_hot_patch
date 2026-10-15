import 'package:flutter/material.dart';
import 'package:hot_patch/hot_patch.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

import '../app/pages/detail_pages.dart';

/// 宿主 WebView 能力：与 [Network] 同款「跳转方法」。
///
/// 被设计为 **@HostInjected**：实现留在 Dart 侧（真实项目里会换成
/// webview_flutter 或原生 WebView），@PatchEntry 组件里写
/// `WebView.open(url, title)` 时，生成器只把调用点替换为
/// `__jsui.host('openWebView', [url, title])`，由宿主
/// `JsRuntimeManager.registerHostMethod` 接回调并经 Navigator 推入页面。
class WebView {
  const WebView._();

  /// 打开一个 WebView 页面（url + 标题）。
  @HostInjected()
  static Future<void> open(String url, String title) async {
    JsRuntimeManager.navigatorKey?.currentState?.push(
      MaterialPageRoute(builder: (_) => WebViewPage(url: url, title: title)),
    );
  }
}