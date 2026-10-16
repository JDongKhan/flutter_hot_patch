import 'dart:convert';

import '../services/js_runtime_manager.dart';
import '../utils/hot_patch_log.dart';
import 'capabilities/core/handle_registry.dart';
import 'js_ui_store.dart';

/// 双端泄漏观测（debug 工具）：页面**进入前**与**销毁后**各取一次快照做
/// diff，残留即泄漏。**JS 端与 Dart 端同时覆盖**：
///
///   - JS 端：运行时自维护的三张表——页面根表 roots、句柄表 handles（含
///     每个对象的 JS 构造名）、页面句柄索引 pageHandles。页面级 JS 对象全部
///     经这三张表可达，表清干净其余自然可被 GC。
///   - Dart 端：句柄注册表（路由 + 页面索引）与各能力登记的镜像表探针——
///     Scroll/Tab/Text/ChangeNotifier 的 controllers/fnHandles/attached、
///     Key 表、BuildContext 锚点（nodeContexts 持有 Element 树引用，泄漏即
///     整棵子树无法回收）、页面 store。
///
/// 用法（JsUiWidget 已接线）：initState 取基线 [capture]，dispose 取第二次
/// 后调 [reportLeaks]。仅 debug 构建启用（kDebugMode + HotPatchLog 门控，
/// release 下探针表恒空、JS 产物不含 leakSnapshot），线上零开销。
class JsLeakSnapshot {
  JsLeakSnapshot._({
    required this.handles,
    required this.pageHandleCounts,
    required this.roots,
    required this.dartTables,
    required this.dartPageHandles,
    required this.dartRoutingIds,
  });

  /// JS 句柄明细：`{id, kind, scope, key, obj}`（obj 为 JS 侧构造名或 typeof）。
  final List<Map<String, Object?>> handles;

  /// JS 侧：pageKey → 该页登记的句柄数。
  final Map<String, int> pageHandleCounts;

  /// JS 侧：现存页面根 key。
  final List<String> roots;

  /// Dart 侧：各句柄镜像表 → 当前条目数（探针登记的全部表 + 路由/页面索引/
  /// 页面 store 数）。
  final Map<String, int> dartTables;

  /// Dart 侧：页面索引里属于本页的条目数（dispose 兜底回收后应为 0）。
  final int dartPageHandles;

  /// Dart 侧：路由表当前句柄 id 集。
  final Set<String> dartRoutingIds;

  /// 取一次快照；JS 运行时骨架未注入 / 执行出错时返回 null（调用方按
  /// 「无法观测」静默跳过，不干扰页面流程）。
  static JsLeakSnapshot? capture(String pageKey) {
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
    // Dart 侧镜像表：注册表自快照 + 各能力探针。
    final reg = dartHandleRegistrySnapshot(pageKey);
    final dartTables = <String, int>{
      'handle.routing': reg['routing'] as int,
      'handle.pageIndex': reg['pageIndex'] as int,
      'pageStores': jsUiPageStores.length,
      for (final e in dartHandleTableProbes.entries) e.key: e.value(),
    };
    return JsLeakSnapshot._(
      handles: handles,
      pageHandleCounts: pageHandleCounts,
      roots: roots,
      dartTables: dartTables,
      dartPageHandles: reg['pageHandles'] as int,
      dartRoutingIds: reg['ids'] as Set<String>,
    );
  }

  /// 本页销毁后的快照与进入前的 [baseline] 对比，打印双端残留明细。
  ///
  /// 判定（三类必空 + 两类净增可疑）：
  ///   1. JS 页面根未销毁（roots 仍含 pageKey）；
  ///   2. JS 页面句柄残留（pageHandles 索引或 handles 里 key==pageKey 的条目）；
  ///   3. Dart 页面句柄索引残留（dispose 兜底回收未清干净）；
  ///   4. JS global 句柄净增：本页生命周期内新增、销毁后仍在的 global 句柄——
  ///      多为「page 意图但登记时 activeRoot 缺失退化为 global」的对象；
  ///   5. Dart 路由/镜像表净增：本页创建但 release 未清回的 Dart 对象
  ///     （controller / Key / context 锚点等）。
  void reportLeaks(String pageKey, JsLeakSnapshot? baseline) {
    final leaks = <String>[];
    // ---- JS 端 ----
    if (roots.contains(pageKey)) {
      leaks.add('JS 页面根 roots[$pageKey] 未销毁');
    }
    final pending = pageHandleCounts[pageKey];
    if (pending != null && pending > 0) {
      leaks.add('JS 页面句柄索引 pageHandles[$pageKey] 残留 $pending 项');
    }
    for (final h in handles) {
      if (h['key'] == pageKey) {
        leaks.add('JS 句柄未释放：${h['id']}（kind: ${h['kind']}, obj: ${h['obj']}）');
      }
    }
    final before = {
      for (final h in baseline?.handles ?? const <Map<String, Object?>>[]) h['id'],
    };
    for (final h in handles) {
      if (h['scope'] == 'global' && !before.contains(h['id'])) {
        leaks.add(
          '疑似泄漏（JS global 句柄净增）：${h['id']}（kind: ${h['kind']}, obj: ${h['obj']}）',
        );
      }
    }
    // ---- Dart 端 ----
    if (dartPageHandles > 0) {
      leaks.add('Dart 页面句柄索引残留 $dartPageHandles 项');
    }
    final dartBefore = baseline?.dartRoutingIds ?? const <String>{};
    for (final id in dartRoutingIds.difference(dartBefore)) {
      leaks.add('疑似泄漏（Dart 路由净增）：$id');
    }
    final beforeTables = baseline?.dartTables ?? const <String, int>{};
    for (final e in dartTables.entries) {
      final delta = e.value - (beforeTables[e.key] ?? 0);
      if (delta > 0) {
        leaks.add('疑似泄漏（Dart 表净增 $delta）：${e.key}（现存 ${e.value}）');
      }
    }
    // ---- 汇总 ----
    if (leaks.isEmpty) {
      HotPatchLog.log(
        'leak-check $pageKey: clean（JS 句柄 ${handles.length}，根 ${roots.length}；'
        'Dart 表 ${dartTables.values.fold(0, (a, b) => a + b)} 项）',
      );
      return;
    }
    HotPatchLog.log(
      'leak-check $pageKey: ${leaks.length} 项残留\n  ${leaks.join('\n  ')}',
    );
  }
}
