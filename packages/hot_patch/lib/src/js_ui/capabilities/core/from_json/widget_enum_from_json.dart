// ===== JSON → 杂项组件枚举（跨组件共用）=====
//
// 不归属文本/布局/绘制任一族的参数（混合模式、滚动物理等），被多个能力与
// 内建组件共用，故放在 core。
import 'package:flutter/material.dart';

/// JSON → BlendMode（Image.colorBlendMode 用，覆盖常用混合模式）。
BlendMode? blendModeFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'modulate' => BlendMode.modulate,
    'multiply' => BlendMode.multiply,
    'screen' => BlendMode.screen,
    'overlay' => BlendMode.overlay,
    'darken' => BlendMode.darken,
    'lighten' => BlendMode.lighten,
    'srcIn' => BlendMode.srcIn,
    'srcATop' => BlendMode.srcATop,
    'colorDodge' => BlendMode.colorDodge,
    'colorBurn' => BlendMode.colorBurn,
    'hue' => BlendMode.hue,
    'saturation' => BlendMode.saturation,
    'color' => BlendMode.color,
    'luminosity' => BlendMode.luminosity,
    _ => null,
  };
}

/// JSON → ScrollPhysics（类名字符串）。
ScrollPhysics? scrollPhysicsFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'NeverScrollableScrollPhysics' => const NeverScrollableScrollPhysics(),
    'BouncingScrollPhysics' => const BouncingScrollPhysics(),
    'ClampingScrollPhysics' => const ClampingScrollPhysics(),
    'AlwaysScrollableScrollPhysics' => const AlwaysScrollableScrollPhysics(),
    _ => null,
  };
}
