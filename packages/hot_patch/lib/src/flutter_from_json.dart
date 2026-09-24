import 'package:flutter/material.dart';

// ===========================================================================
// JSON → Flutter 对象的 fromJson 工具集（运行时侧）
//
// 与 ui_component_generator 的 style_translators.dart 对称：
//   生成器：TextStyle/ButtonStyle/Colors/FontWeight … → JSON
//   运行时：同一份 JSON → 真实 Flutter 对象
//
// 解耦：样式还原不放进 widget renderer，避免一个文件越滚越大；
// 新增样式类 = 在这个文件加一个 xxxFromJson + 在 renderer 里调用。
// ===========================================================================

/// JSON → TextStyle（null / 空 Map → 默认样式）。
TextStyle textStyleFromJson(Map<String, dynamic>? json) {
  if (json == null || json.isEmpty) return const TextStyle();
  return TextStyle(
    fontSize: (json['fontSize'] as num?)?.toDouble(),
    fontWeight: fontWeightFromJson(json['fontWeight']),
    color: colorFromJson(json['color']),
    fontStyle: fontStyleFromJson(json['fontStyle']),
    letterSpacing: (json['letterSpacing'] as num?)?.toDouble(),
    height: (json['height'] as num?)?.toDouble(),
    fontFamily: json['fontFamily'] as String?,
  );
}

/// JSON → ButtonStyle（null / 空 Map → null，表示用 widget 默认样式）。
ButtonStyle? buttonStyleFromJson(Map<String, dynamic>? json) {
  if (json == null || json.isEmpty) return null;
  final bg = colorFromJson(json['backgroundColor']);
  final fg = colorFromJson(json['foregroundColor']);
  return ButtonStyle(
    backgroundColor:
        bg == null ? null : WidgetStatePropertyAll<Color?>(bg),
    foregroundColor:
        fg == null ? null : WidgetStatePropertyAll<Color?>(fg),
  );
}

/// JSON → FontWeight（'bold' / 'w500' / 'normal'）。
FontWeight? fontWeightFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'bold' => FontWeight.bold,
    'normal' => FontWeight.normal,
    _ when v.startsWith('w') && v.length == 4 =>
      FontWeight.values.firstWhere(
        (w) => w.value == int.parse(v.substring(1)),
        orElse: () => FontWeight.normal,
      ),
    _ => null,
  };
}

/// JSON → FontStyle（'italic' / 'normal'）。
FontStyle? fontStyleFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'italic' => FontStyle.italic,
    'normal' => FontStyle.normal,
    _ => null,
  };
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
