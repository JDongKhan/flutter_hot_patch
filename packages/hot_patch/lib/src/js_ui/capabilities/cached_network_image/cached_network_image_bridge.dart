// ===== 能力：CachedNetworkImage 磁盘缓存网络图（组件注册）=====
//
// 三方包 cached_network_image 的视觉组件：Flutter 侧没有等价物，按「只有引入
// Flutter 侧不存在的视觉 widget 才往宿主注册表加一条」注册一条。本能力**纯宿主
// 侧**（无 JS 片段、无通道）——JS 侧只下发元素 type 与 props，宿主还原成真实的
// CachedNetworkImage。
//
// JS 侧写法（生成器由 Dart 的 `CachedNetworkImage(imageUrl: …, fit: …)` 产出）：
//   __h('CachedNetworkImage', { source: "https://…", height: 120, fit: "cover" })
//   source → 包要求的 imageUrl。
//
// 不还原的部分：placeholder / errorWidget（包内均为 builder 闭包，非 Widget）、
// 缓存策略（cacheManager / cacheKey / httpHeaders …）与 fade 参数——均属视觉/
// 命令式细节，统一用包内默认行为（生成器只下发 imageUrl → source）。
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

import '../../../json/flutter_from_json.dart';
import '../../js_widget_registry.dart';

/// CachedNetworkImage 能力域组件注册。
void registerCachedNetworkImageWidgets(JsWidgetRegistry r) {
  r.register('CachedNetworkImage', (c) {
    return CachedNetworkImage(
      // 具名参数名原样下发（`CachedNetworkImage(imageUrl: …)` → props.imageUrl）。
      imageUrl: c.str('imageUrl') ?? c.str('source') ?? '',
      width: c.num_('width'),
      height: c.num_('height'),
      fit: boxFitFromJson(c.props['fit']),
      alignment: alignmentFromJson(c.props['alignment']) ?? Alignment.center,
      color: colorFromJson(c.props['color']),
      colorBlendMode: blendModeFromJson(c.props['colorBlendMode']),
    );
  });
}
