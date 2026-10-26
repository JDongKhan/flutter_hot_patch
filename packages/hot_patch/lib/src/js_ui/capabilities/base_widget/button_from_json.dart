// ===== 基础组件：JSON → ButtonStyle =====
import 'package:flutter/material.dart';

import '../core/from_json/dart_values_from_json.dart';
import '../core/from_json/layout_from_json.dart';
import '../core/from_json/painting_from_json.dart';
import 'text_from_json.dart';

/// JSON → ButtonStyle（null / 空 Map → null，表示用 widget 默认样式）。
ButtonStyle? buttonStyleFromJson(Map<String, dynamic>? json) {
  if (json == null || json.isEmpty) return null;
  final bg = colorFromJson(json['backgroundColor']);
  final fg = colorFromJson(json['foregroundColor']);
  final overlay = colorFromJson(json['overlayColor']);
  final icon = colorFromJson(json['iconColor']);
  final shadow = colorFromJson(json['shadowColor']);
  final disabledBg = colorFromJson(json['disabledBackgroundColor']);
  final disabledFg = colorFromJson(json['disabledForegroundColor']);
  // ButtonStyle 无 disabledXxx 参数（那是 styleFrom 的便捷参数）：
  // 合并进 backgroundColor/foregroundColor 的 resolveWith。
  final bgProp = (bg == null && disabledBg == null)
      ? null
      : WidgetStateProperty.resolveWith<Color?>((states) =>
          states.contains(WidgetState.disabled) ? (disabledBg ?? bg) : bg);
  final fgProp = (fg == null && disabledFg == null)
      ? null
      : WidgetStateProperty.resolveWith<Color?>((states) =>
          states.contains(WidgetState.disabled) ? (disabledFg ?? fg) : fg);
  return ButtonStyle(
    backgroundColor: bgProp,
    foregroundColor: fgProp,
    overlayColor: overlay == null ? null : WidgetStatePropertyAll<Color?>(overlay),
    iconColor: icon == null ? null : WidgetStatePropertyAll<Color?>(icon),
    shadowColor: shadow == null ? null : WidgetStatePropertyAll<Color?>(shadow),
    elevation: json['elevation'] == null
        ? null
        : WidgetStatePropertyAll<double?>((json['elevation'] as num).toDouble()),
    padding: json['padding'] is Map
        ? WidgetStatePropertyAll<EdgeInsets?>(edgeInsetsFromJson((json['padding'] as Map).cast<String, dynamic>()))
        : null,
    minimumSize: sizeFromJson(json['minimumSize']) == null
        ? null
        : WidgetStatePropertyAll<Size?>(sizeFromJson(json['minimumSize'])),
    maximumSize: sizeFromJson(json['maximumSize']) == null
        ? null
        : WidgetStatePropertyAll<Size?>(sizeFromJson(json['maximumSize'])),
    side: borderSideFromJson(json['side']) == null
        ? null
        : WidgetStatePropertyAll<BorderSide?>(borderSideFromJson(json['side'])),
    shape: shapeFromJson(json['shape']) == null
        ? null
        : WidgetStatePropertyAll<OutlinedBorder?>(shapeFromJson(json['shape'])),
    fixedSize: sizeFromJson(json['fixedSize']) == null
        ? null
        : WidgetStatePropertyAll<Size?>(sizeFromJson(json['fixedSize'])),
    textStyle: json['textStyle'] is Map
        ? WidgetStatePropertyAll<TextStyle?>(textStyleFromJson((json['textStyle'] as Map).cast<String, dynamic>()))
        : null,
    alignment: alignmentFromJson(json['alignment']),
    visualDensity: visualDensityFromJson(json['visualDensity']),
    enableFeedback: json['enableFeedback'] as bool?,
  );
}
