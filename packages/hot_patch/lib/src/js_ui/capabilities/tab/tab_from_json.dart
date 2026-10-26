// ===== Tab 能力：JSON → Tab 相关枚举 =====
import 'package:flutter/material.dart';

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
