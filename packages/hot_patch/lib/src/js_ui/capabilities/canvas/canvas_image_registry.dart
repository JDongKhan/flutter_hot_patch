// ===== 能力：Canvas 图片句柄（ui.Image 跨语言传递）=====
//
// JS 侧不持有像素，只持有图片句柄 `{__handle, width, height}`：
//   - 句柄来自 @HostInjected 方法（例：example 的 `CanvasImage.load(url)`）的
//     返回值；宿主用 [JsRuntimeManager.registerHostValueEncoder] 把 `ui.Image`
//     编码成该 Map（见 [ensureCanvasImageEncoder]）。
//   - JS `Canvas.drawImage` / `drawImageRect` 只把句柄录进绘制指令，宿主重放时
//     按 id 还原成真实 `ui.Image`（见 [canvasImageFromJson]）。
//
// 生命周期：与 Flutter 的 imageCache 同语义——句柄常驻进程，不随页面销毁释放。
// 图片解码结果本身也由 `ImageCache` 持有，重复 load 相同 URL 命中缓存。
import 'dart:ui' as ui;

import '../../../services/js_runtime_manager.dart';
import '../../../utils/hot_patch_log.dart';

/// 句柄 id → 图片。
final Map<String, ui.Image> _images = {};

/// 图片 → 句柄 id（同一张图多次 load 时复用同一条指令/同一 id）。
final Map<ui.Image, String> _ids = {};

int _seq = 0;

bool _encoderRegistered = false;

/// 幂等登记 `ui.Image` 的宿主返回值编码器（由 `CanvasLibrary.ensureChannels` 调用）。
void ensureCanvasImageEncoder() {
  if (_encoderRegistered) return;
  _encoderRegistered = true;
  JsRuntimeManager.registerHostValueEncoder<ui.Image>(canvasImageToJson);
}

/// `ui.Image` → 跨桥图片句柄 `{__handle, width, height}`。
Map<String, Object> canvasImageToJson(ui.Image image) {
  final existing = _ids[image];
  if (existing != null) {
    return {
      '__handle': existing,
      'width': image.width,
      'height': image.height,
    };
  }
  final id = 'host:canvasImage#${++_seq}';
  _images[id] = image;
  _ids[image] = id;
  return {
    '__handle': id,
    'width': image.width,
    'height': image.height,
  };
}

/// 跨桥图片句柄 → `ui.Image`；形态/身份不合法时报警并返回 null（不猜图片）。
ui.Image? canvasImageFromJson(Object? v) {
  if (v is Map) {
    final id = v['__handle'];
    if (id is String && id.isNotEmpty) {
      final image = _images[id];
      if (image != null) return image;
      HotPatchLog.error('CustomPaint: 图片句柄 "$id" 不存在（只能使用宿主返回值里的句柄）');
      return null;
    }
  }
  HotPatchLog.error('CustomPaint: 图片不是宿主返回的图片句柄: $v');
  return null;
}
