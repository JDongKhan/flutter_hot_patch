// ===== 基础组件：JSON → 文本类值 =====
//
// TextStyle 及其配套枚举（字重 / 字形 / 装饰 / 对齐 / 溢出 / 方向 / 缩放 /
// 键盘类型）。Text / TextField / 按钮文案等基础组件共用，故不放进 core。
import 'package:flutter/material.dart';

import '../../../utils/hot_patch_log.dart';
import '../core/from_json/dart_values_from_json.dart';

/// JSON → TextStyle（null / 空 Map → 默认样式）。
TextStyle textStyleFromJson(Map<String, dynamic>? json) {
  if (json == null || json.isEmpty) return const TextStyle();
  return TextStyle(
    fontSize: (json['fontSize'] as num?)?.toDouble(),
    fontWeight: fontWeightFromJson(json['fontWeight']),
    color: colorFromJson(json['color']),
    fontStyle: fontStyleFromJson(json['fontStyle']),
    letterSpacing: (json['letterSpacing'] as num?)?.toDouble(),
    wordSpacing: (json['wordSpacing'] as num?)?.toDouble(),
    height: (json['height'] as num?)?.toDouble(),
    fontFamily: json['fontFamily'] as String?,
    fontFamilyFallback: (json['fontFamilyFallback'] as List?)?.map((x) => x.toString()).toList(),
    backgroundColor: colorFromJson(json['backgroundColor']),
    decoration: textDecorationFromJson(json['decoration']),
    decorationColor: colorFromJson(json['decorationColor']),
    decorationStyle: textDecorationStyleFromJson(json['decorationStyle']),
    decorationThickness: (json['decorationThickness'] as num?)?.toDouble(),
  );
}

/// JSON → InlineSpan 树（RichText.text / Text.rich 的富文本子树）。
///
/// 产物形态与 `TextSpan` 字段同构：`{text, style, children, semanticsLabel}`，
/// `children` 递归同构。形态不支持的子节点（如 WidgetSpan / PlaceholderSpan）
/// 会被跳过并打印告警，避免静默丢内容。
InlineSpan? textSpanFromJson(Object? v) {
  if (v == null) return null;
  if (v is String) return TextSpan(text: v);
  if (v is! Map) {
    HotPatchLog.warn('[RichText] 不支持的 InlineSpan 节点已跳过：$v');
    return null;
  }
  final rawChildren = v['children'];
  final children = <InlineSpan>[];
  if (rawChildren is List) {
    for (final child in rawChildren) {
      final span = textSpanFromJson(child);
      if (span != null) children.add(span);
    }
  }
  final rawStyle = v['style'];
  return TextSpan(
    text: v['text'] as String?,
    style: textStyleFromJson(
      rawStyle is Map ? rawStyle.cast<String, dynamic>() : null,
    ),
    children: children.isEmpty ? null : children,
    semanticsLabel: v['semanticsLabel'] as String?,
  );
}

/// JSON → TextDecoration（'none'/'underline'/'overline'/'lineThrough'）。
TextDecoration? textDecorationFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'none' => TextDecoration.none,
    'underline' => TextDecoration.underline,
    'overline' => TextDecoration.overline,
    'lineThrough' => TextDecoration.lineThrough,
    _ => null,
  };
}

/// JSON → TextDecorationStyle（'solid'/'double'/'dotted'/'dashed'/'wavy'）。
TextDecorationStyle? textDecorationStyleFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'solid' => TextDecorationStyle.solid,
    'double' => TextDecorationStyle.double,
    'dotted' => TextDecorationStyle.dotted,
    'dashed' => TextDecorationStyle.dashed,
    'wavy' => TextDecorationStyle.wavy,
    _ => null,
  };
}

/// JSON → TextAlign（'left'/'right'/'center'/'justify'/'start'/'end'）。
TextAlign? textAlignFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'left' => TextAlign.left,
    'right' => TextAlign.right,
    'center' => TextAlign.center,
    'justify' => TextAlign.justify,
    'start' => TextAlign.start,
    'end' => TextAlign.end,
    _ => null,
  };
}

/// JSON → TextOverflow（'clip'/'fade'/'ellipsis'/'visible'）。
TextOverflow? overflowFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'clip' => TextOverflow.clip,
    'fade' => TextOverflow.fade,
    'ellipsis' => TextOverflow.ellipsis,
    'visible' => TextOverflow.visible,
    _ => null,
  };
}

/// JSON → TextDirection（'ltr'/'rtl'）。
TextDirection? textDirectionFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'ltr' => TextDirection.ltr,
    'rtl' => TextDirection.rtl,
    _ => null,
  };
}

/// JSON → FontWeight（'bold' / 'w500' / 'normal'）。
FontWeight? fontWeightFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'bold' => FontWeight.bold,
    'normal' => FontWeight.normal,
    _ when v.startsWith('w') && v.length == 4 => FontWeight.values.firstWhere(
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

/// JSON → TextScaler：TextScaler.noScaling / TextScaler.linear(f)
/// （与生成器 textScalerToJson 对称）。
TextScaler? textScalerFromJson(Object? v) {
  if (v is String && v == 'noScaling') return TextScaler.noScaling;
  if (v is Map && v['linear'] != null) {
    final f = double.tryParse('${v['linear']}');
    if (f != null) return TextScaler.linear(f);
  }
  return null;
}

/// JSON → TextInputType。
TextInputType? textInputTypeFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'text' => TextInputType.text,
    'number' => TextInputType.number,
    'phone' => TextInputType.phone,
    'emailAddress' => TextInputType.emailAddress,
    'url' => TextInputType.url,
    'multiline' => TextInputType.multiline,
    'datetime' => TextInputType.datetime,
    'visiblePassword' => TextInputType.visiblePassword,
    _ => null,
  };
}
