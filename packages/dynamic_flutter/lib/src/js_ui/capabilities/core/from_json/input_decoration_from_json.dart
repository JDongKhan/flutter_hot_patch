// ===== JSON → InputDecoration（值对象，TextField 等输入类组件共用）=====
//
// JS 侧 `InputDecoration` 是普通值类（生成器 `style_values_js` 的
// `__ConfigValue` 镜像）：字段同名原样下发，宿主按同名还原成 Flutter
// `InputDecoration`。Widget 字段（`icon` / `label` / `prefixIcon` /
// `suffixIcon`）是元素描述，用 `JsRenderContext.element` 就地还原 —— 不进
// reconciler 树、没有 patch/diff，与 Flutter 每次 build 重建一样。
import 'package:flutter/material.dart';

import '../../../js_widget_registry.dart';
import 'dart_values_from_json.dart';
import 'layout_from_json.dart';
import 'painting_from_json.dart';

/// `props['decoration']` → [InputDecoration]（缺省 null = 让 Flutter 用默认装饰）。
///
/// 一个字段一处还原：新增 `InputDecoration` 字段只改这里，消费方（TextField
/// 等）不必跟着加参数。
InputDecoration? inputDecorationFromJson(
  JsRenderContext c,
  Map<String, dynamic>? json,
) {
  if (json == null) return null;
  String? text(Object? v) => v == null ? null : '$v';
  EdgeInsets? insets(Object? v) =>
      v is Map ? edgeInsetsFromJson(v.cast<String, dynamic>()) : null;
  return InputDecoration(
    hintText: text(json['hintText']),
    labelText: text(json['labelText']),
    icon: c.element(json['icon']),
    label: c.element(json['label']),
    prefixIcon: c.element(json['prefixIcon']),
    suffixIcon: c.element(json['suffixIcon']),
    filled: json['filled'] == true,
    fillColor: colorFromJson(json['fillColor']),
    contentPadding: insets(json['contentPadding']),
    border: inputBorderFromJson(json['border']),
    enabledBorder: inputBorderFromJson(json['enabledBorder']),
    disabledBorder: inputBorderFromJson(json['disabledBorder']),
    focusedBorder: inputBorderFromJson(json['focusedBorder']),
    errorBorder: inputBorderFromJson(json['errorBorder']),
    focusedErrorBorder: inputBorderFromJson(json['focusedErrorBorder']),
  );
}
