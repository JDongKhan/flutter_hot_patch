// ===== 基础组件：JSON → IconData =====
import 'package:flutter/widgets.dart';

/// JSON → IconData。
///
/// 协议形态：JS 的 `Icons.xxx` / `IconData(...)` 都是真实对象，跨桥按
/// `toJSON()` 下发 `{codePoint, fontFamily, matchTextDirection}`
/// （见 flutter.js 的 `IconData` 值类，表由 SDK `icons.dart` 自动生成）。
/// 这里只做**结构还原**，不再维护「图标名 → IconData」的手写映射表，也不做
/// 未命中回退——名字在 JS 侧就已解析成码点，未识别的载荷由调用方兜底出声。
IconData? iconDataFromJson(Object? v) {
  if (v is! Map) return null;
  final code = v['codePoint'];
  if (code is! num) return null;
  return IconData(
    code.toInt(),
    fontFamily: v['fontFamily'] as String?,
    matchTextDirection: v['matchTextDirection'] == true,
  );
}
