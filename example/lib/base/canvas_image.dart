import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:hot_patch/hot_patch.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// 宿主图片加载能力：把 url（http(s) 或 assets 路径）解析成 `ui.Image`。
///
/// 设计要点（与 [WebView] / [AppRouter] 同一套 @HostInjected 机制）：
/// - **原生侧直接可用**：普通 static 方法，Dart 里照常 await；
/// - **JS 侧**：本类仍存在，只有方法体换成
///   `_app_host_.invoke('loadCanvasImage', [url])`；调用点与 Dart 一比一，
///   返回值 `ui.Image` 由 canvas 能力登记的编码器转成图片句柄
///   `{__handle, width, height}`（JS 只持有句柄，不持有像素）；
/// - `CustomPaint` 的 `Canvas.drawImage` / `drawImageRect` 重放时按句柄还原
///   真实 `ui.Image` 并绘制。
class CanvasImage {
  const CanvasImage._();

  /// 加载图片（http(s) → [NetworkImage]，其余按 assets 路径处理）。
  ///
  /// assets 统一走 [HotPatchAssets.bundle]：补丁包内同名图片优先，缺失回退
  /// Flutter assets。
  @HostInjected('loadCanvasImage')
  static Future<ui.Image> load(String url) {
    final ImageProvider provider = url.startsWith('http')
        ? NetworkImage(url)
        : AssetImage(url, bundle: HotPatchAssets.bundle);
    final completer = Completer<ui.Image>();
    final stream = provider.resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete(info.image);
      },
      onError: (exception, stackTrace) {
        stream.removeListener(listener);
        if (!completer.isCompleted) {
          completer.completeError(exception, stackTrace);
        }
      },
    );
    stream.addListener(listener);
    return completer.future;
  }
}
