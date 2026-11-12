// ===== Tab 能力：JSON → Tab 相关枚举 =====
import 'package:flutter/material.dart';

import '../../js_widget_registry.dart';

/// 对外注册 API：Tab 枚举从 [JsRenderContext] 的 props 按键还原。
extension JsRenderContextTab on JsRenderContext {
  TabBarIndicatorSize? tabBarIndicatorSize(String key) =>
      tabBarIndicatorSizeFromJson(props[key]);
  TabAlignment? tabAlignment(String key) => tabAlignmentFromJson(props[key]);
}

/// JSON → TabBarIndicatorSize（'tab'/'label'）。
TabBarIndicatorSize? tabBarIndicatorSizeFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'tab' => TabBarIndicatorSize.tab,
    'label' => TabBarIndicatorSize.label,
    _ => null,
  };
}

/// JSON → TabAlignment（'start'/'startOffset'/'fill'/'center'）。
TabAlignment? tabAlignmentFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'start' => TabAlignment.start,
    'startOffset' => TabAlignment.startOffset,
    'fill' => TabAlignment.fill,
    'center' => TabAlignment.center,
    _ => null,
  };
}
