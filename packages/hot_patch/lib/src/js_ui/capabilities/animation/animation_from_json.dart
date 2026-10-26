// ===== 动画：JSON → 动画语义值 =====
//
// 曲线名 / CrossFadeState：本能力（隐式动画 / 过渡动画）消费的枚举值。
// 值一律是**成员名字符串**（生成器把 `Curves.easeOut` 等译成字符串），宿主
// 按名字查真实对象；未登记时出声，不静默丢弃整条配置。
//
// 公共值类（Duration / Offset 等）不在这里：它们跨能力复用，见
// `../core/from_json/dart_values_from_json.dart`。
import 'package:flutter/material.dart';

import '../../../utils/hot_patch_log.dart';

/// JSON → CrossFadeState（'showFirst' / 'showSecond'，枚举成员名口径）。
CrossFadeState crossFadeStateFromJson(Object? v) =>
    v == 'showSecond' ? CrossFadeState.showSecond : CrossFadeState.showFirst;

/// 曲线名 → Curve（`Curves.<name>` 的成员名口径，生成器统一译成字符串）。
///
/// 未给 / 未登记都返回 `Curves.linear`（与 `Animated*` 家族的默认曲线一致），
/// 未登记时出声——不静默丢弃整条曲线配置。
Curve curveFromJson(Object? v) {
  if (v is! String) return Curves.linear;
  final curve = _curves[v];
  if (curve == null) {
    HotPatchLog.warn('curveFromJson: 未登记的曲线 "$v"，按 linear 处理');
    return Curves.linear;
  }
  return curve;
}

/// 常用曲线名表（按需扩展；与 Dart `Curves` 成员同名）。
const Map<String, Curve> _curves = {
  'linear': Curves.linear,
  'ease': Curves.ease,
  'easeIn': Curves.easeIn,
  'easeOut': Curves.easeOut,
  'easeInOut': Curves.easeInOut,
  'easeInToLinear': Curves.easeInToLinear,
  'easeInSine': Curves.easeInSine,
  'easeOutSine': Curves.easeOutSine,
  'easeInOutSine': Curves.easeInOutSine,
  'easeInQuad': Curves.easeInQuad,
  'easeOutQuad': Curves.easeOutQuad,
  'easeInOutQuad': Curves.easeInOutQuad,
  'easeInCubic': Curves.easeInCubic,
  'easeOutCubic': Curves.easeOutCubic,
  'easeInOutCubic': Curves.easeInOutCubic,
  'easeInQuart': Curves.easeInQuart,
  'easeOutQuart': Curves.easeOutQuart,
  'easeInOutQuart': Curves.easeInOutQuart,
  'easeInQuint': Curves.easeInQuint,
  'easeOutQuint': Curves.easeOutQuint,
  'easeInOutQuint': Curves.easeInOutQuint,
  'easeInExpo': Curves.easeInExpo,
  'easeOutExpo': Curves.easeOutExpo,
  'easeInOutExpo': Curves.easeInOutExpo,
  'easeInCirc': Curves.easeInCirc,
  'easeOutCirc': Curves.easeOutCirc,
  'easeInOutCirc': Curves.easeInOutCirc,
  'easeInBack': Curves.easeInBack,
  'easeOutBack': Curves.easeOutBack,
  'easeInOutBack': Curves.easeInOutBack,
  'fastOutSlowIn': Curves.fastOutSlowIn,
  'slowMiddle': Curves.slowMiddle,
  'bounceIn': Curves.bounceIn,
  'bounceOut': Curves.bounceOut,
  'bounceInOut': Curves.bounceInOut,
  'elasticIn': Curves.elasticIn,
  'elasticOut': Curves.elasticOut,
  'elasticInOut': Curves.elasticInOut,
  'decelerate': Curves.decelerate,
  'fastLinearToSlowEaseIn': Curves.fastLinearToSlowEaseIn,
  'fastEaseInToSlowEaseOut': Curves.fastEaseInToSlowEaseOut,
};
