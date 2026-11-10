import 'package:flutter/foundation.dart';

/// 埋点统一出口。
///
/// 当前只把事件打到日志（原生 `debugPrint` / JS 侧同一个全局函数，最终都进
/// AppLogCenter），后续接入三方统计 SDK 时**只改本类**，调用点不变。
class Tracker {
  const Tracker._();

  /// 曝光埋点：由 TrackerVisibilityWidget 在首次可见时调用一次。
  static void exposure(String event, Map<String, Object?> params) {
    _report('exposure', event, params);
  }

  /// 点击埋点（预留同一出口，事件名与参数由调用方给）。
  static void click(String event, Map<String, Object?> params) {
    _report('click', event, params);
  }

  /// 统一组装并输出：`[Tracker] exposure · home_floor_exposure floor=banner`。
  static void _report(String type, String event, Map<String, Object?> params) {
    var detail = '';
    params.forEach((key, value) {
      detail = '$detail $key=$value';
    });
    debugPrint('[Tracker] $type · $event$detail');
  }
}
