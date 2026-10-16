import 'dart:convert';

import '../services/js_runtime_manager.dart';
import '../utils/hot_patch_log.dart';

/// JS 侧泄漏观测（debug 工具）：页面**进入前**与**销毁后**各取一次运行时
/// 自维护表的快照做 diff，残留即泄漏——覆盖 JS 端对象（句柄表里的 obj 构造
/// 名），不只是 Dart 端。
///
/// 可观测面：JS 堆无法直接枚举，但本运行时的页面级对象（组件实例 / 控制器
/// 代理 / 函数闭包 / Key / 监听器）全部经三张表可达——页面根表 roots、
/// 句柄表 handles、页面句柄索引 pageHandles。这三张表清干净，其余对象失去
/// 引用自然可被 GC；表里有残留，就是真泄漏。
///
/// 用法（JsUiWidget 已接线）：initState 取基线 [capture]，dispose 取第二次
/// 后调 [reportLeaks]。仅在 debug 构建启用（HotPatchLog 门控），release 零开销。
class JsLeakSnapshot {
  JsLeakSnapshot._({
    required this.handles,
    required this.pageHandleCounts,
    required this.roots,
  });

  /// 句柄明细：`{id, kind, scope, key, obj}`（obj 为 JS 侧构造名或 typeof）。
  final List<Map<String, Object?>> handles;

  /// pageKey → 该页登记的句柄数。
  final Map<String, int> pageHandleCounts;

  /// 现存页面根 key。
  final List<String> roots;

  /// 取一次快照；JS 运行时骨架未注入 / 执行出错时返回 null（调用方按
  /// 「无法观测」静默跳过，不干扰页面流程）。
  static JsLeakSnapshot? capture() {
    final r = JsRuntimeManager.instance.evaluate(
      'typeof __jsui !== "undefined" && __jsui.leakSnapshot '
      '? __jsui.leakSnapshot() : "null";',
    );
    if (r.isError) return null;
    final Object? raw;
    try {
      raw = jsonDecode(r.stringResult);
    } catch (_) {
      return null;
    }
    if (raw is! Map) return null;
    final handles = <Map<String, Object?>>[
      for (final h in raw['handles'] as List? ?? const [])
        if (h is Map) h.cast<String, Object?>(),
    ];
    final pageHandleCounts = <String, int>{
      for (final e in (raw['pageHandles'] as Map? ?? const {}).entries)
        if (e.value is num) '${e.key}': (e.value as num).toInt(),
    };
    final roots = <String>[
      for (final k in raw['roots'] as List? ?? const []) '$k',
    ];
    return JsLeakSnapshot._(
      handles: handles,
      pageHandleCounts: pageHandleCounts,
      roots: roots,
    );
  }

  /// 本页销毁后的快照与进入前的 [baseline] 对比，打印残留明细（含 JS 对象）。
  ///
  /// 判定三类：
  ///   1. 页面根未销毁（roots 仍含 pageKey）；
  ///   2. 页面句柄残留（pageHandles 索引或 handles 里 key==pageKey 的条目）；
  ///   3. global 句柄净增：本页生命周期内新增、销毁后仍在的 global 句柄——
  ///      多为「page 意图但登记时 activeRoot 缺失退化为 global」的对象，
  ///      不随任何页面回收。
  void reportLeaks(String pageKey, JsLeakSnapshot? baseline) {
    final leaks = <String>[];
    if (roots.contains(pageKey)) {
      leaks.add('页面根 roots[$pageKey] 未销毁');
    }
    final pending = pageHandleCounts[pageKey];
    if (pending != null && pending > 0) {
      leaks.add('页面句柄索引 pageHandles[$pageKey] 残留 $pending 项');
    }
    for (final h in handles) {
      if (h['key'] == pageKey) {
        leaks.add('句柄未释放：${h['id']}（kind: ${h['kind']}, obj: ${h['obj']}）');
      }
    }
    final before = {
      for (final h in baseline?.handles ?? const <Map<String, Object?>>[]) h['id'],
    };
    for (final h in handles) {
      if (h['scope'] == 'global' && !before.contains(h['id'])) {
        leaks.add(
          '疑似泄漏（global 句柄净增）：${h['id']}（kind: ${h['kind']}, obj: ${h['obj']}）',
        );
      }
    }
    if (leaks.isEmpty) {
      HotPatchLog.log(
        'leak-check $pageKey: clean（全局句柄 ${handles.length}，根 ${roots.length}）',
      );
      return;
    }
    HotPatchLog.log(
      'leak-check $pageKey: ${leaks.length} 项残留\n  ${leaks.join('\n  ')}',
    );
  }
}
