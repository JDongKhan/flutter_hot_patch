import 'dart:convert';

import '../../services/js_runtime_manager.dart';
import '../../utils/hot_patch_log.dart';
import '../capabilities/core/binding_cache.dart';
import '../capabilities/core/handle_registry.dart';
import 'leak_stats.dart';

/// 双端泄漏观测（debug 工具）：页面**进入**与**销毁**两端各对双端缓存取一次
/// 快照，比对「进入后新增、销毁时仍未释放」的条目即泄漏。**JS 端与 Dart 端同时
/// 覆盖**：
///
///   - JS 端：运行时自维护的三张表——页面根表 roots、句柄表 handles（含
///     每个对象的 JS 构造名）、页面句柄索引 pageHandles。页面级 JS 对象全部
///     经这三张表可达，表清干净其余自然可被 GC。
///   - Dart 端：句柄注册表（页面索引是否兜底回收干净）与**绑定缓存**里本页登记
///     的条目（controllers / Key / BuildContext 锚点等都在那一处，见
///     binding_cache.dart）、页面 store。
///
/// **两套判据**：
///   - 按「页面归属」判残留：这些表全是**进程内全局表**（按句柄/结点 id 索引，
///     与页面无关），同屏多实例时规模天然被兄弟页面活着的对象撑大。故 Dart 侧
///     条目自带 pageKey、直接按页统计；JS 侧只看 `key == pageKey` 的句柄与
///     roots/pageHandles。
///   - 按「进入 / 销毁一致性」判净增（[reportLeaks] 的差分项）：不带页面归属的
///     条目（JS 的 global 句柄、Dart 侧 pageKey 为空的绑定）无法按页统计，只能
///     与进入时的基线比对——基线里没有、销毁时仍在，就是本页生命周期内新增且
///     没释放的对象。归属到别的页面的新条目由那一页自己审计，不在此报（避免
///     同屏多实例互相误报）。
///
/// 用法（JsUiWidget 已接线）：**运行时就绪、本页模块加载完、组件尚未 mount**
/// 时取基线 [capture]（模块级单例因此算「进入前已有」），dispose 清理后取第二次
/// 再调 [reportLeaks]。仅 debug 构建**调用**（kDebugMode + HotPatchLog 门控）；
/// `leakSnapshot` 本身在 runtime.js 里恒存在（产物分不出 debug/release），
/// release 下不被调用即零开销。
class JsLeakSnapshot {
  JsLeakSnapshot._({
    required this.handles,
    required this.handleIds,
    required this.pageHandleCounts,
    required this.roots,
    required this.dartTables,
    required this.bindingKeys,
    required this.bindingTotal,
    required this.kindCounts,
    required this.bindingBucketCounts,
  });

  /// JS 句柄明细：`{id, kind, scope, key, obj}`（obj 为 JS 侧构造名或 typeof）。
  final List<Map<String, Object?>> handles;

  /// [handles] 的 id 集合（基线比对用）。
  final Set<String> handleIds;

  /// JS 侧：pageKey → 该页登记的句柄数。
  final Map<String, int> pageHandleCounts;

  /// JS 侧：现存页面根 key。
  final List<String> roots;

  /// Dart 侧：表名 → **本页**当前仍留在该表里的条目数（按页归属统计；销毁后应
  /// 全为 0）。含页面句柄索引、本页 store、以及绑定缓存里本页登记的条目（按桶）。
  final Map<String, int> dartTables;

  /// Dart 绑定缓存全部条目的 `桶|id` 集合（基线比对用）。
  final Set<String> bindingKeys;

  /// Dart 绑定缓存总量（跨桶条目数）。
  final int bindingTotal;

  /// JS 句柄按 kind 汇总（`ctx/BuildContext` / `ctrl/Scroll` / `key` …）：
  /// JS 注入的 Dart 类（PageController / ScrollController / GlobalKey /
  /// BuildContext…）各有多少条，进入与销毁两端对照即知谁在涨。
  final Map<String, int> kindCounts;

  /// Dart 绑定缓存按桶汇总（桶名即 kind / 存储分组）。
  final Map<String, int> bindingBucketCounts;

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
    final cache = JsBindingCache.instance;
    final handleIds = <String>{for (final h in handles) '${h['id']}'};
    final pageHandleIds = dartPageHandleIds(pageKey);
    final dartTables = <String, int>{
      // 本页仍在页面句柄索引里的句柄数。与 JS 侧仍存活的句柄**取交集**后不为 0
      // 才算「释放路径没跑到」——宿主收到 release 消息是异步的，销毁瞬间还在
      // 索引里但 JS 已释放的条目属旅程中，不报。
      'handle.pageHandles':
          pageHandleIds.where(handleIds.contains).length,
      // 绑定缓存：本页登记过、销毁后仍留在缓存里的条目（按桶名统计，桶名即
      // kind / 存储分组，见 binding_cache.dart）。同样排除旅程中条目。
      ...cache.pageCounts(pageKey, liveHandleIds: handleIds),
    };
    return JsLeakSnapshot._(
      handles: handles,
      handleIds: handleIds,
      pageHandleCounts: pageHandleCounts,
      roots: roots,
      dartTables: dartTables,
      bindingKeys: <String>{
        for (final e in cache.allEntries) '${e.bucket}|${e.id}',
      },
      bindingTotal: cache.totalCount,
      kindCounts: _countKinds(handles),
      bindingBucketCounts: _countBuckets(cache.allEntries),
    );
  }

  /// JS 句柄按 kind 计数。
  static Map<String, int> _countKinds(Iterable<Map<String, Object?>> hs) {
    final out = <String, int>{};
    for (final h in hs) {
      final k = '${h['kind']}';
      out[k] = (out[k] ?? 0) + 1;
    }
    return out;
  }

  /// Dart 绑定缓存按桶计数。
  static Map<String, int> _countBuckets(Iterable<JsBinding<Object>> es) {
    final out = <String, int>{};
    for (final e in es) {
      out[e.bucket] = (out[e.bucket] ?? 0) + 1;
    }
    return out;
  }

  /// 「进入 → 销毁」的规模对照：`118 → 120 条（ctx/BuildContext +2，fn 60，…）`。
  ///
  /// 前半是净增（只列数量有变的 kind / 桶），后半是销毁时刻的绝对分布——
  /// 绝对数用于跨页面比对整体规模（如 ctx/BuildContext 是否随页面复杂度上涨），
  /// 净增用于判定本页是否留下对象。
  static String _scaleText(
    int? before,
    int now,
    Map<String, int> nowCounts,
    Map<String, int>? baseCounts,
  ) {
    final changed = <String>[];
    if (baseCounts != null) {
      for (final k in <String>{...baseCounts.keys, ...nowCounts.keys}.toList()
        ..sort()) {
        final d = (nowCounts[k] ?? 0) - (baseCounts[k] ?? 0);
        if (d != 0) changed.add('$k ${d > 0 ? '+' : ''}$d');
      }
    }
    final parts = <String>[
      ...changed,
      for (final k in nowCounts.keys.toList()..sort()) '$k ${nowCounts[k]}',
    ];
    return '${before ?? '-'} → $now 条'
        '${parts.isEmpty ? '' : '（${parts.join('，')}）'}';
  }

  /// 打印本页销毁后的双端残留明细。
  ///
  /// 判定：
  ///   1. JS 页面根未销毁（roots 仍含 pageKey）；
  ///   2. JS 页面句柄残留（pageHandles 索引或 handles 里 key==pageKey 的条目）；
  ///   3. Dart 页面句柄索引残留：兜底回收没跑到；
  ///   4. Dart 绑定缓存残留：本页登记过的条目仍在缓存里（释放路径漏跑 / 某 kind
  ///      的 onRelease 没清自己的桶）——报警时逐条列出是什么 id、谁登记的；
  ///   5. 缓存净增（进入基线 vs 销毁快照）：进入后新增、销毁时仍留在缓存里的
  ///      对象——JS 句柄与 Dart 绑定都算。不带页面归属的条目（JS global / Dart
  ///      pageKey 为空）是这一类的主体；归属别的页面的新条目由那一页自己审计。
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
    // ---- 进入 / 销毁一致性（缓存净增）----
    final base = baseline;
    if (base == null) {
      leaks.add('基线缺失：进入时未取到 JS 运行时快照，跳过缓存净增比对');
    } else {
      final liveIds = <String>{
        for (final h in handles) '${h['id']}',
      };
      for (final h in handles) {
        final id = '${h['id']}';
        if (base.handleIds.contains(id)) continue;
        final key = h['key'];
        // 归属别的页面的新句柄由那一页自己审计（同屏多实例不互相误报）。
        if (key != null && key != pageKey) continue;
        leaks.add(
          'JS 缓存净增（进入后新增且未释放）：$id'
          '（kind: ${h['kind']}, scope: ${h['scope']}, obj: ${h['obj']}）',
        );
      }
      final bindings = JsBindingCache.instance;
      for (final e in bindings.allEntries) {
        // 有页归属的条目已由上面的 dartTables 按页审计，不重复报。
        if (e.pageKey != null) continue;
        if (base.bindingKeys.contains('${e.bucket}|${e.id}')) continue;
        // 进入前就存在的 JS 句柄（模块级单例等）：宿主镜像可能晚于基线到达，
        // 不属于本页新增。
        if (base.handleIds.contains(e.id)) continue;
        // JS 已释放、宿主 release 消息仍在平台通道上（dispose 同步执行，消息
        // 异步到达）：属瞬态，不算泄漏。`ctx/node` 的 id 是结点 id 而非句柄 id，
        // 不能拿句柄表判断。
        if (e.bucket != JsBindingBuckets.ctxNode && !liveIds.contains(e.id)) {
          continue;
        }
        leaks.add('Dart 缓存净增（进入后新增且未释放）：${e.describe()}');
      }
    }
    // ---- Dart 端（条目自带页面归属：兄弟实例活着的对象不参与判定）----
    for (final e in dartTables.entries) {
      if (e.value > 0) leaks.add('疑似泄漏（Dart 表）：${e.key} ×${e.value}');
    }
    if (leaks.isNotEmpty) {
      // 明细：把本页仍留在绑定缓存里的条目逐条列出（id / kind / scope / 存活 /
      // 活了多久 / 谁登记的），便于直接定位是哪条没释放。
      for (final e in JsBindingCache.instance.entriesOfPage(pageKey)) {
        leaks.add('binding 残留：${e.describe()}');
      }
    }
    // ---- 汇总 ----
    // 页面名（`HelloCard（jsui_0）`）：人类名在前、pageKey 保留在后，便于与 JS 侧日志对齐。
    final cache = JsBindingCache.instance;
    final page = LeakStats.labelOf(pageKey);
    final tally = LeakStats.pageTally(pageKey);
    LeakStats.clearPageTally(pageKey);
    // 「进入 → 销毁」的缓存规模对照（量取自两端快照时刻），按 kind / 桶列出净增
    // 与销毁时刻的绝对分布（JS 注入的 PageController / ScrollController /
    // GlobalKey / BuildContext 各多少条，一眼可见）。
    final scale = 'JS 缓存 '
        '${_scaleText(base?.handleIds.length, handles.length, _countKinds(handles), base?.kindCounts)}'
        '，Dart 缓存 '
        '${_scaleText(base?.bindingTotal, cache.totalCount, _countBuckets(cache.allEntries), base?.bindingBucketCounts)}';
    if (leaks.isEmpty) {
      HotPatchLog.log(
        'leak-check $page: clean（JS 根 ${roots.length}；Dart 表 '
        '${dartTables.values.fold(0, (a, b) => a + b)} 项；$scale；'
        'binding 本页登记 $tally 条已全清）',
      );
      return;
    }
    HotPatchLog.warn(
      'leak-check $page: ${leaks.length} 项残留（$scale；binding 本页登记 $tally 条）'
      '\n  ${leaks.join('\n  ')}',
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
