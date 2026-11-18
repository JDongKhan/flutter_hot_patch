// ===== 通用：RenderObject 代理 op 的宿主语义 =====
//
// JS 侧 `GlobalKey.currentContext.findRenderObject()` / `context.findRenderObject()`
// 返回的 `RenderObject` 代理只带一个跨语言句柄 id；`showOnScreen` / `measure`
// 到底走 key 桥还是 BuildContext 桥由**句柄种类**决定（见 key_bridge /
// build_context_bridge），但「拿到真实 RenderObject 之后」的取值语义完全相同，
// 故放在 core 里两侧共用，避免同一套 RenderBox 规则写两遍。
import 'package:flutter/widgets.dart';

/// `measure` op 的载荷：RenderBox 的位置与尺寸快照。
///
/// 位置与尺寸是 RenderBox 才有的语义（RenderObject 没有 `size` /
/// `localToGlobal`）；未布局（`hasSize == false`）时算不出来，回 null 由单源侧判空。
Map<String, Object?>? renderObjectMeasurePayload(RenderObject? ro) {
  if (ro is! RenderBox || !ro.hasSize) return null;
  final topLeft = ro.localToGlobal(Offset.zero);
  return <String, Object?>{
    'dx': topLeft.dx,
    'dy': topLeft.dy,
    'width': ro.size.width,
    'height': ro.size.height,
  };
}
