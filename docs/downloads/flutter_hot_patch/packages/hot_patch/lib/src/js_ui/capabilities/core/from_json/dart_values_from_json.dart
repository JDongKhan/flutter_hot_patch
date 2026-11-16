// ===== JSON → Flutter 基础值类型（跨能力共用）=====
//
// 颜色 / 尺寸 / 偏移 / 时长：不归属任何具体能力（文本、布局、动画、控制器
// 都用得到），故放在 core，与 `dart_values_js.dart`（JS 侧同名值类）对称。
import 'package:flutter/material.dart';

import '../../../js_widget_registry.dart';

/// 对外注册 API：从 [JsRenderContext] 的 props 按键取值并还原成 Flutter 值。
///
/// 外部自定义组件的 renderer 只需拿到 `c`，不必再 import 各 `*_from_json`
/// 文件。未传 / 类型不符时返回 null（与对应 `*FromJson` 同一口径）；嵌套结构
/// 与无上下文路径（绘制指令、Controller 实参等）继续复用文件内原始解析函数。
extension JsRenderContextDartValues on JsRenderContext {
  Color? color(String key) => colorFromJson(props[key]);
  Size? size(String key) => sizeFromJson(props[key]);
  Offset? offset(String key) => offsetFromJson(props[key]);
  Duration? duration(String key) => durationFromJson(props[key]);
}

/// JSON → Color（'#RRGGBB' / '#AARRGGBB'）。
Color? colorFromJson(Object? v) {
  if (v is! String) return null;
  if (!v.startsWith('#') || v.length != 7 && v.length != 9) return null;
  final hex = v.substring(1);
  final value = int.tryParse(hex, radix: 16);
  if (value == null) return null;
  // 6 位 → 补不透明 alpha
  if (hex.length == 6) return Color(0xFF000000 | value);
  return Color(value);
}

/// JSON → Size（{'width':..,'height':..}）。
///
/// 取不到的维度按 0 处理：`Size.fromHeight` / `Size.fromWidth` 的一侧是
/// `double.infinity`，JSON 无法表达（`JSON.stringify(Infinity)` 为 `null`），
/// 落到这里就是缺省值。
Size? sizeFromJson(Object? v) {
  if (v is! Map) return null;
  double? d(Object? x) {
    if (x is num) return x.toDouble();
    return double.tryParse('$x');
  }

  final w = d(v['width']) ?? 0;
  final h = d(v['height']) ?? 0;
  return Size(w, h);
}

/// JSON → Offset（`{'dx': 0, 'dy': 1}`）。
///
/// 生成器把 `Offset(...)` 译成该 JSON 形态（运行时值类 `dart_values_js.dart` 的 `toJSON`）；
/// 动画偏移（AnimatedSlide）等场景直接消费。
Offset? offsetFromJson(Object? v) {
  if (v is! Map) return null;
  final dx = v['dx'];
  final dy = v['dy'];
  if (dx is num && dy is num) {
    return Offset(dx.toDouble(), dy.toDouble());
  }
  return null;
}

/// JSON → Duration（动画 / 过渡时长）。
///
/// 三种来源都要认：
///   - JS 运行时 `Duration` 值的 `toJSON` → `{'__duration': 毫秒}`；
///   - 裸数字（毫秒）——生成器对 `Duration(milliseconds: 300)` 的取值；
///   - 直接下发毫秒字段的写法（`{'milliseconds': 300}`）。
Duration? durationFromJson(Object? v) {
  if (v is num) return Duration(milliseconds: v.round());
  if (v is String) {
    final ms = int.tryParse(v);
    return ms == null ? null : Duration(milliseconds: ms);
  }
  if (v is Map) {
    final ms = v['__duration'] ?? v['milliseconds'];
    if (ms is num) return Duration(milliseconds: ms.round());
    if (ms is String) {
      final parsed = int.tryParse(ms);
      return parsed == null ? null : Duration(milliseconds: parsed);
    }
  }
  return null;
}
