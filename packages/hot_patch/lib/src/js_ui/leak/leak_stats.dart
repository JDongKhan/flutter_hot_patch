import 'package:flutter/foundation.dart';

import '../capabilities/core/binding_cache.dart';

/// 绑定统计**切面**（debug-only）。
///
/// 统计是横切关注点：绑定缓存（`binding_cache.dart`）与页面生命周期都不该为了
/// 统计而携带计数表、页面名表或分支判断。故业务侧只留一个**可空的切面挂载点**
/// （`JsBindingCache.debugPageLabel`），由本切面在 debug 构建
/// 里装配；release 下挂载点恒为 null 且 `kDebugMode` 是编译期常量 false，业务侧
/// 调用被整段裁掉，统计代码不会执行、也不影响任何业务行为。
///
/// 本切面只做一件事：维护 pageKey → 页面名（日志显示用）。
/// 记账失败绝不影响绑定登记本身（见 `JsBindingCache` 挂载点的 try/catch）。
abstract final class LeakStats {
  static bool _installed = false;

  static final Map<String, String> _pageNames = {};

  /// 装配切面（幂等；release 下直接返回，不注册任何东西）。
  static void install() {
    if (!kDebugMode || _installed) return;
    _installed = true;
    JsBindingCache.debugPageLabel = labelOf;
  }

  /// 登记页面名（幂等覆盖；pageKey 全局递增唯一，同一 key 不会重复登记）。
  /// 调用方须在页面销毁时 [unregisterPage]，否则本表无界增长。
  static void registerPage(String pageKey, String name) {
    if (!kDebugMode) return;
    install();
    _pageNames[pageKey] = name;
  }

  /// 页面销毁时注销页面名（与 [registerPage] 配对，条目不跨页面生命周期残留）。
  static void unregisterPage(String pageKey) {
    if (!kDebugMode) return;
    _pageNames.remove(pageKey);
  }

  /// 页面名的日志显示：已登记 → `HelloCard（jsui_0）`（人类名在前、id 保留在后，
  /// 同组件多实例仍可区分）；未登记 / release → 原样返回 pageKey。
  static String labelOf(String pageKey) {
    if (!kDebugMode) return pageKey;
    final name = _pageNames[pageKey];
    return name == null ? pageKey : '$name（$pageKey）';
  }
}
