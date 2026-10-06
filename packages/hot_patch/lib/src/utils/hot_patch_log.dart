import 'package:flutter/foundation.dart';

/// 热更包日志统一开关。
///
/// 默认开启（开发期可见全部链路日志）；生产环境一行关闭：
/// ```dart
/// HotPatchLog.enabled = false;
/// ```
/// 关闭后所有 [log] 调用直接短路，不产生任何输出。
class HotPatchLog {
  HotPatchLog._();

  /// 全局开关：true 输出，false 静默。
  static bool enabled = true;

  /// 输出日志（统一带 `[hot_patch]` 前缀）。
  static void log(String message) {
    if (!enabled) return;
    debugPrint('[hot_patch] $message');
  }
}
