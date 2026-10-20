import 'dart:convert';

import '../services/js_runtime_manager.dart';
import '../utils/hot_patch_log.dart';
import 'capabilities/core/binding_cache.dart';
import 'capabilities/core/handle_registry.dart';
import 'js_ui_store.dart';

/// 双端泄漏观测（debug 工具）：页面**销毁后**扫一遍双端资源表，本页登记过、
/// 销毁后却仍留在表里的即残留。**JS 端与 Dart 端同时覆盖**：
///
///   - JS 端：运行时自维护的三张表——页面根表 roots、句柄表 handles（含
///     每个对象的 JS 构造名）、页面句柄索引 pageHandles。页面级 JS 对象全部
///     经这三张表可达，表清干净其余自然可被 GC。
///   - Dart 端：句柄注册表（页面索引是否兜底回收干净）与**绑定缓存**里本页登记
///     的条目（controllers / Key / BuildContext 锚点等都在那一处，见
///     binding_cache.dart）、页面 store。
///
/// **两端都按「页面归属」判定**：这些表全是**进程内全局表**（按句柄/结点 id
/// 索引，与页面无关），同屏多实例时规模天然被兄弟页面活着的对象撑大——直接拿
/// 全局计数做「进入前 / 销毁后」差分，会把兄弟实例的活对象误判成本页泄漏。
/// 故：
///   - Dart 侧的绑定对象都寄存在 binding_cache.dart 的**唯一缓存**里，条目自带
///     pageKey，直接按页统计（不再需要任何额外的归属表）；本注册表另补一项
///     「页面句柄索引是否被兜底回收干净」；
///   - JS 侧只看 `key == pageKey` 的句柄与 roots/pageHandles；
///   - 仅剩的一项差分是 JS global 句柄净增——global 句柄按定义不带页面归属
///     （退化为 global 的那类「本该是 page」对象），只能与进入前基线比对。
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
  });

  /// JS 句柄明细：`{id, kind, scope, key, obj}`（obj 为 JS 侧构造名或 typeof）。
  final List<Map<String, Object?>> handles;

  /// JS 侧：pageKey → 该页登记的句柄数。
  final Map<String, int> pageHandleCounts;

  /// JS 侧：现存页面根 key。
  final List<String> roots;

  /// Dart 侧：表名 → **本页**当前仍留在该表里的条目数（按页归属统计；销毁后应
  /// 全为 0）。含页面句柄索引、本页 store、以及绑定缓存里本页登记的条目（按桶）。
  final Map<String, int> dartTables;

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
    // Dart 侧表：均按**本页归属**统计（跨实例互不干扰，详见类注释）。
    final dartTables = <String, int>{
      // 本页仍在页面句柄索引里的句柄数（兜底回收后应为 0；非 0 说明释放路径
      // 整段没跑到，缓存里的对象自然也还在）。
      'handle.pageHandles': dartPageHandleCount(pageKey),
      // 本页 store 是否仍在登记表里（页面已摘除；仍在即页面路由未清）。
      'pageStores': jsUiPageStores.containsKey(pageKey) ? 1 : 0,
      // 绑定缓存：本页登记过、销毁后仍留在缓存里的条目（按桶名统计，桶名即
      // kind / 存储分组，见 binding_cache.dart）。
      ...JsBindingCache.instance.pageCounts(pageKey),
    };
    return JsLeakSnapshot._(
      handles: handles,
      pageHandleCounts: pageHandleCounts,
      roots: roots,
      dartTables: dartTables,
    );
  }

  /// 打印本页销毁后的双端残留明细。
  ///
  /// 判定（按页面归属，见类注释）：
  ///   1. JS 页面根未销毁（roots 仍含 pageKey）；
  ///   2. JS 页面句柄残留（pageHandles 索引或 handles 里 key==pageKey 的条目）；
  ///   3. Dart 页面句柄索引残留：兜底回收没跑到；
  ///   4. Dart 绑定缓存残留：本页登记过的条目仍在缓存里（释放路径漏跑 / 某 kind
  ///      的 onRelease 没清自己的桶）——报警时逐条列出是什么 id、谁登记的；
  ///   5. JS global 句柄净增：本页生命周期内新增、销毁后仍在的 global 句柄——
  ///      多为「page 意图但登记时 activeRoot 缺失退化为 global」的对象。global
  ///      句柄按定义不带页面归属，故这是**唯一**仍需 [baseline] 的差分项。
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
    // ---- Dart 端（条目自带页面归属：兄弟实例活着的对象不参与判定）----
    for (final e in dartTables.entries) {
      if (e.value > 0) leaks.add('疑似泄漏（Dart 表残留 ${e.value} 项）：${e.key}');
    }
    if (leaks.isNotEmpty) {
      // 明细：把本页仍留在绑定缓存里的条目逐条列出（id / kind / scope / 存活 /
      // 活了多久 / 谁登记的），便于直接定位是哪条没释放。
      for (final e in JsBindingCache.instance.entriesOfPage(pageKey)) {
        leaks.add('binding 残留：${e.describe()}');
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

  /// 打一条 **JS 侧**绑定缓存的全景日志（与 Dart 侧 `JsBindingCache.dumpLog()`
  /// 对称，排查时两边都能一次看全）。
  ///
  /// JS 端所有对象（函数 / 控制器 / Key / ChangeNotifier / ctx 句柄）本来就都在
  /// 同一张 `handles` 表里（kind 只是条目上的标签），这里按 kind 汇总并逐条列出
  /// id / scope / 所属页面 / 构造名。仅 debug 可用——release 产物不含该 API，
  /// typeof 守卫直接静默跳过。
  static void logJsCache() {
    final r = JsRuntimeManager.instance.evaluate(
      'typeof __jsui !== "undefined" && __jsui.cacheDump '
      '? __jsui.cacheDump() : "null";',
    );
    if (r.isError) return;
    HotPatchLog.log(r.stringResult);
  }
}
