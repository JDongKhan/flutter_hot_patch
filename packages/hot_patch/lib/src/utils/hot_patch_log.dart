import 'package:flutter/foundation.dart';

/// 日志级别（低 → 高）。本地打印与上报共用同一套口径：各级别方法产出一条
/// [HotPatchLogRecord]，由 [HotPatchLog.sink] **统一拦截**。
enum HotPatchLevel { debug, info, warn, error }

/// 一条日志记录：统一拦截（[HotPatchLog.sink]）的载荷。
///
/// 字段即上报所需的最小集合（级别 / 文本 / 时间 / 异常 / 堆栈）；宿主拿到后
/// 按自己日志平台的协议序列化上传即可，包内不做任何平台约定。
@immutable
class HotPatchLogRecord {
  const HotPatchLogRecord({
    required this.level,
    required this.message,
    required this.time,
    this.error,
    this.stackTrace,
  });

  final HotPatchLevel level;
  final String message;
  final DateTime time;
  final Object? error;
  final StackTrace? stackTrace;

  @override
  String toString() => '[${level.name.toUpperCase()}] [hot_patch] $message'
      '${error == null ? '' : ' | $error'}';
}

/// 上报出口：宿主注册（如接到日志平台）。所有达到 [HotPatchLog.minSinkLevel]
/// 的记录都会经过它；为空则只本地打印。**不得抛异常**（抛出会被兜底吞掉）。
typedef HotPatchLogSink = void Function(HotPatchLogRecord record);

/// 热更包日志的统一出口。
///
/// 两条出口**彼此独立**：
///   - **本地打印**：由 [enabled] 控制（默认 kDebugMode），只影响控制台输出；
///   - **上报**：由 [sink] 控制，注册即生效，**不受 [enabled] 影响**——
///     故 release（`enabled=false`）下仍能采集，而这正是日志平台的主场景。
///
/// 宿主接入（如 `main()`）：
/// ```dart
/// HotPatchLog.sink = (r) => MyLogPlatform.upload(
///       level: r.level.name,
///       message: r.message,
///       error: r.error,
///       stack: r.stackTrace,
///       time: r.time,
///     );
/// // 默认只上报 warn/error；要全量（含链路 info）就调低阈值：
/// HotPatchLog.minSinkLevel = HotPatchLevel.info;
/// ```
class HotPatchLog {
  HotPatchLog._();

  /// 本地打印开关：true 输出，false 静默。**不影响** [sink] 上报。
  static bool enabled = kDebugMode;

  /// **详细缓存追踪**开关（默认关；仅 debug 生效）。
  ///
  /// 打开后逐条打印双端缓存的登记 / 释放：
  ///   - Dart 侧：每条绑定进 [JsBindingCache] / 出缓存（含 `quiet` 的索引类条目）；
  ///   - JS 侧：每个句柄（控制器 / Key / BuildContext 代理 / 事件闭包）的
  ///     `reg` / `releaseHandle`，经 console 桥以 `[js-log]` 回传。
  ///
  /// 置 true 只影响日志：不改变任何缓存行为、不增加额外表。JS 侧切面由
  /// `JsRuntimeManager.setVerboseCacheTrace(true)` 装配（等价入口，且会立刻
  /// 通知已就绪的 JS 运行时）；直接赋本字段时，下一次运行时初始化会同步过去。
  static bool verboseCache = false;

  /// 统一上报出口（宿主注册；为空 = 只本地打印）。
  static HotPatchLogSink? sink;

  /// 进入 [sink] 的最低级别（默认 warn：只上报告警与报错）。
  static HotPatchLevel minSinkLevel = HotPatchLevel.warn;

  /// 调试细节（默认不上报）。用于排查期的高噪声日志。
  static void debug(String message, {Object? error, StackTrace? stackTrace}) =>
      emit(HotPatchLevel.debug, message,
          error: error, stackTrace: stackTrace);

  /// 常规日志（链路信息），保持原有 `[hot_patch] xxx` 格式。
  static void log(String message, {Object? error, StackTrace? stackTrace}) =>
      emit(HotPatchLevel.info, message, error: error, stackTrace: stackTrace);

  /// 告警：可降级/兜底继续的异常（回退旧产物、未知 op、类型未注册等）。
  static void warn(String message, {Object? error, StackTrace? stackTrace}) =>
      emit(HotPatchLevel.warn, message, error: error, stackTrace: stackTrace);

  /// 报错：功能已失败的异常（加载失败、JS 求值失败、宿主方法调用失败等）。
  static void error(String message, {Object? error, StackTrace? stackTrace}) =>
      emit(HotPatchLevel.error, message,
          error: error, stackTrace: stackTrace);

  /// 唯一出口：打印（[enabled]）+ 上报（[sink]，按 [minSinkLevel] 过滤）。
  /// 需要按名称**动态**定级的调用方（如 JS console 桥）直接用它。
  static void emit(
    HotPatchLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (enabled) {
      debugPrint(
        '[hot_patch] ${_label(level)}$message'
        '${error == null ? '' : ' | $error'}',
      );
    }
    final s = sink;
    if (s == null || level.index < minSinkLevel.index) return;
    // 上报是旁路：宿主 sink 抛异常只兜底记一条，绝不向外冒泡（不许因为
    // 上传日志把业务打断）。
    try {
      s(HotPatchLogRecord(
        level: level,
        message: message,
        time: DateTime.now(),
        error: error,
        stackTrace: stackTrace,
      ));
    } catch (e) {
      debugPrint('[hot_patch] [ERROR] sink 上报失败（已忽略）：$e');
    }
  }

  /// 打印前缀：warn/error 加标签（日志里一眼可检索），debug/info 维持原格式。
  static String _label(HotPatchLevel level) => switch (level) {
        HotPatchLevel.warn => '[WARN] ',
        HotPatchLevel.error => '[ERROR] ',
        _ => '',
      };
}
