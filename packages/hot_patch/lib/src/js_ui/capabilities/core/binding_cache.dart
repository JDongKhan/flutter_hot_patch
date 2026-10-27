// 跨语言绑定的统一缓存（宿主侧，地基）。
//
// **为什么需要它**：JS ↔ Dart 的绑定关系要求宿主侧长期持有「真实对象 + 它的绑定
// 信息」。此前这些对象散落在各能力自己的全局表里（controllers / fnHandles /
// attached、Key 表、ctx 句柄表 + 结点锚点表…），想找一个对象得先知道它归哪个 kind
// 的哪张表。本文件把它们收进**唯一一个缓存对象**：
//
//   - 条目（[JsBinding]）是缓存里唯一存的东西——对象引用、句柄 id/kind、scope、
//     所属页面、登记来源、创建时间、各能力自用的附加元数据（meta）全在它身上；
//   - 桶（bucket）就是「按 kind 分组」的存储，桶内类型化（保静态类型与 O(1) 查找），
//     业务能力只拿一个桶名；
//   - 对外只有一套入口：put / putIfAbsent / entry / target / remove / dump，
//     登记与释放各打一条日志（仅 debug），[dump] 一次列出全部绑定。
//
// **引用强度（弱 / 强）按「谁真实持有这个对象」逐 kind 决定**：
//
//   1. 有框架外部 owner、本缓存只是索引 → **弱引用**：`ctx/node` 桶里的
//      BuildContext（Element 由 element tree 的父→子强持有）。漏删的后果降级为
//      一条死键（几十字节），不再钉住整棵 Element 子树。
//   2. 本缓存就是 Dart 侧唯一持有者 → **强引用**（即「只有这个缓存持有的除外」）：
//      - controllers：JS 侧句柄才是这些对象的寿命驱动者，而「JS 是否已释放」
//        Dart 侧唯一可观测的信号就是收到 release——未收到就不能弱化，否则
//        「JS 还持着句柄、对象却被 GC」会变成非确定性的句柄失效（create→attach
//        窗口内更是只有本缓存在持有）。
//      - GlobalKey / UniqueKey：挂载期由 element 的 `widget.key` 持有，但离树期间
//        （懒槽位 / 跨父搬移）Dart 侧只有本缓存 + JS 句柄；弱化会让重挂时拿不到
//        同一实例 → 退化 `ValueKey(结点 id)` → 该子树 State 丢失。
//      - JS↔Dart 的纯映射值（如 ctx 句柄 → 结点 id）：没有任何 widget 持有它。
//
// | 桶 / kind | 对象 | Dart 侧真实持有者 | 强度 |
// | --- | --- | --- | --- |
// | `ctx/node` | BuildContext（Element） | element tree（父→子强引用链） | 弱 |
// | `ctx/handle` | 结点 id（纯映射） | 无——只有本缓存 | 强 |
// | `key` | GlobalKey / UniqueKey | 挂载期 element 的 `widget.key`；离树期只有本缓存 + JS 句柄 | 强 |
// | `ctrl/*`、`notifier/*` | ChangeNotifier 真实实例 | attach 后宿主 State；create→attach 窗口与卸载后只有本缓存 | 强 |
import 'package:flutter/foundation.dart';

import '../../../utils/hot_patch_log.dart';

/// 桶名：缓存的存储分组。**全部集中在这里**，一眼看全「缓存里有哪些桶」。
///
/// 控制器桥的桶名直接用句柄 kind（`ctrl/Scroll` / `ctrl/Tab` / `ctrl/Text` /
/// `notifier/ChangeNotifier`），与「新增能力 = 注册一个 kind」同构，故不在此列出。
abstract final class JsBindingBuckets {
  /// Key 句柄（GlobalKey / UniqueKey），强引用。见文件头判定 2。
  static const String key = 'key';

  /// ctx 句柄 → 结点 id（纯映射值），强引用。
  static const String ctxHandle = 'ctx/handle';

  /// 结点 id → 该结点当前 BuildContext，**弱引用**。
  static const String ctxNode = 'ctx/node';
}

/// 一个跨语言绑定条目：把宿主侧真实对象（或纯映射值）连同**绑定信息**包在一起。
///
/// 它是缓存里唯一存的东西——故排查「这个 id 是什么、谁登记的、还活着吗」只需要看
/// 这一个类型（[JsBindingCache.dump]）。
class JsBinding<T extends Object> {
  JsBinding._({
    required this.bucket,
    required this.id,
    required this.kind,
    required this.owner,
    required this.weak,
    required this.quiet,
    required this.pageKey,
    required T? value,
    Map<String, Object?>? meta,
  })  : createdAt = DateTime.now(),
        meta = meta ?? <String, Object?>{},
        _strong = weak ? null : value,
        _weak = (weak && value != null) ? WeakReference<T>(value) : null;

  /// 所属桶（缓存的存储分组，如 `ctrl/Scroll` / `ctx/node`）。
  final String bucket;

  /// 句柄 id（或结点锚点键，如 `page:jsui_3`）。
  final String id;

  /// 句柄 kind（`ctrl/Scroll` / `key/Global` / `ctx/BuildContext`…）。
  final String kind;

  /// 登记来源（哪个能力、哪个时机建的）——排查时一眼看出这条是谁登记的。
  final String owner;

  /// 引用强度（见文件头判定），登记后不再改变。
  final bool weak;

  /// 是否**静音**（登记与释放都不打逐条日志，[JsBindingCache.dump] 与泄漏明细里
  /// 仍然可见）。给「纯索引 / 纯映射」类条目用——它们每页每结点一条（如
  /// `ctx/node` 的结点→BuildContext），量大且没有跨页风险，逐条打只会刷屏；
  /// 资源类条目（控制器 / Key / 句柄）保持可逐条追踪。
  final bool quiet;

  final DateTime createdAt;

  /// 各能力自用的附加元数据（如控制器的回传句柄 `fn`、attach 去重标记）。
  final Map<String, Object?> meta;

  /// 所属页面：page scope 的句柄由 `jsHandle create` 带下来（[JsBindingCache.putIfAbsent]
  /// 会补写：宿主可能先建对象、create 消息后到）；结点锚点在登记时直接给出。
  String? pageKey;

  T? _strong;
  WeakReference<T>? _weak;

  /// 句柄 scope：page（随页面释放）/ global（跨页面常驻）。由 [pageKey] 推出
  /// （`local` scope 的纯本端句柄从不同步宿主，不会进本缓存）。
  String get scope => pageKey != null ? 'page' : 'global';

  /// 当前真实对象；弱引用条目在目标被回收后返回 null。
  T? get target => weak ? _weak?.target : _strong;

  /// 是否仍持有真实对象（弱引用被回收 → false）。
  bool get alive => target != null;

  /// 回填 / 替换真实对象（宿主先建条目、对象后到的场景）。按条目自身的 [weak] 存。
  void fill(T value) {
    _strong = weak ? null : value;
    _weak = weak ? WeakReference<T>(value) : null;
  }

  /// 一条绑定的可读摘要（日志与 [JsBindingCache.dump] 共用）。
  ///
  /// 形如：`js:node/Text#43（Text）· 页面=jsui_2 · 弱引用·存活 · 存活 17s · 登记=结点构建`
  /// —— 依次是「哪个 id（什么对象）· 属于哪个页面（无页归属=全局）· 引用强度与存活 ·
  /// 已登记多久 · 谁登记的」。类型优先取 `meta['type']`（结点类型 / 控制器类名），
  /// 其次真实对象的 [Object.runtimeType]，最后按 kind 归名——故「对象尚未创建」的
  /// 条目（如 TabController 的真实对象由宿主随句柄参数创建）不会打出无意义的 `-`。
  String describe() {
    final t = target;
    final what =
        (meta['type'] as String?) ?? (t == null ? _kindName : '${t.runtimeType}');
    final where = pageKey == null ? '全局' : '页面=${_pageLabel(pageKey!)}';
    final hold = weak ? (t == null ? '弱引用·已回收' : '弱引用·存活') : '强引用';
    final age = DateTime.now().difference(createdAt).inSeconds;
    return '$id（$what）· $where · $hold · 存活 ${age}s · 登记=$owner';
  }

  /// kind 的短名（`ctrl/Tab` → `Tab`）：无法判定类型时的兜底显示名。
  String get _kindName {
    final i = kind.indexOf('/');
    return i >= 0 ? kind.substring(i + 1) : kind;
  }

  /// 页面名的日志显示：由统计切面注入；未装配（release / 未登记）→ 原样。
  static String _pageLabel(String pageKey) => kDebugMode
      ? (JsBindingCache.debugPageLabel?.call(pageKey) ?? pageKey)
      : pageKey;
}

/// 跨语言绑定的**唯一**缓存：所有绑定条目都在这里，别的文件不再各自持有全局表。
///
/// 用法（各能力只拿一个桶名；`weak` 必填，见下方判定）：
/// ```dart
/// const _bucket = 'ctrl/Scroll';
/// JsBindingCache.instance.putIfAbsent<ScrollController>(
///   bucket: _bucket, id: id, kind: _bucket, owner: 'scroll.onCreate',
///   weak: false, create: ...);
/// JsBindingCache.instance.target<ScrollController>(_bucket, id);
/// ```
class JsBindingCache {
  JsBindingCache._();

  /// 全局唯一实例（与句柄注册表一样：全框架只有这一个绑定缓存，永无第二实现）。
  static final JsBindingCache instance = JsBindingCache._();

  /// 桶名 → (id → 条目)。桶内类型由登记它的能力决定（Dart 泛型协变，故这里用
  /// `JsBinding<Object>` 收口；取值走 [entry] 的类型化查询 + 运行时断言）。
  final Map<String, Map<String, JsBinding<Object>>> _buckets = {};

  /// 取一条绑定（未登记 / 类型不符返回 null）。
  JsBinding<T>? entry<T extends Object>(String bucket, String id) {
    final raw = _buckets[bucket]?[id];
    if (raw == null) return null;
    // 同桶必须同类型：桶内类型由登记它的能力决定，查错类型属编码错误（debug 暴露）。
    assert(raw is JsBinding<T>, 'binding 桶 "$bucket" 类型不符：$raw 不是 JsBinding<$T>');
    return raw is JsBinding<T> ? raw : null;
  }

  /// 取一条绑定的真实对象（未登记 / 弱引用已回收返回 null）。
  T? target<T extends Object>(String bucket, String id) =>
      entry<T>(bucket, id)?.target;

  /// 登记 / 更新一条绑定（**就地更新**：已有条目保留 meta 与 createdAt，只换对象
  /// 与归属）。用于「每次 build 都要刷新」的锚点类绑定。
  ///
  /// [weak] **必填**：引用强度是决定「会不会泄漏」的关键轴，不给默认值——每个
  /// 登记点显式声明，读代码与排查时一眼看出这里是不是真持有者（判定见文件头）。
  JsBinding<T> put<T extends Object>({
    required String bucket,
    required String id,
    required String kind,
    required T value,
    required String owner,
    required bool weak,
    bool quiet = false,
    String? pageKey,
    Map<String, Object?>? meta,
  }) {
    final existing = entry<T>(bucket, id);
    if (existing != null) {
      existing.pageKey = pageKey ?? existing.pageKey;
      if (meta != null) existing.meta.addAll(meta);
      existing.fill(value);
      return existing;
    }
    final created = JsBinding<T>._(
      bucket: bucket,
      id: id, kind: kind, owner: owner, weak: weak, quiet: quiet,
      pageKey: pageKey, value: value, meta: meta,
    );
    (_buckets[bucket] ??= <String, JsBinding<Object>>{})[id] = created;
    _notifyStat(created);
    _logPut(created);
    return created;
  }

  /// 登记一条绑定（**幂等复用**：已有条目保留原对象，只补写归属 / 元数据；[create]
  /// 非空且还没有对象时回填）。
  ///
  /// 这就是「create 消息与首帧渲染到达顺序不定，哪端先建都复用同一实例」的落点：
  /// 宿主先建 → 这里回填 meta/归属；JS 先建 → 这里走 [create]。
  ///
  /// [weak] **必填**（同 [put]）。
  JsBinding<T> putIfAbsent<T extends Object>({
    required String bucket,
    required String id,
    required String kind,
    required String owner,
    required bool weak,
    bool quiet = false,
    T Function()? create,
    String? pageKey,
    Map<String, Object?>? meta,
  }) {
    final existing = entry<T>(bucket, id);
    if (existing != null) {
      existing.pageKey = pageKey ?? existing.pageKey;
      if (meta != null) existing.meta.addAll(meta);
      if (create != null && !existing.alive) existing.fill(create());
      return existing;
    }
    final created = JsBinding<T>._(
      bucket: bucket,
      id: id, kind: kind, owner: owner, weak: weak, quiet: quiet,
      pageKey: pageKey, value: create?.call(), meta: meta,
    );
    (_buckets[bucket] ??= <String, JsBinding<Object>>{})[id] = created;
    _notifyStat(created);
    _logPut(created);
    return created;
  }

  /// 释放一条绑定（幂等；空桶一并摘除）。
  void remove(String bucket, String id) {
    final b = _buckets[bucket];
    final e = b?.remove(id);
    if (e == null) return;
    if (b!.isEmpty) _buckets.remove(bucket);
    if (kDebugMode && HotPatchLog.verboseCache) {
      HotPatchLog.debug('[binding] - ${e.describe()}');
    }
  }

  /// 某个桶里的全部绑定（同桶同类型，取用方自行按需断言）。
  Iterable<JsBinding<Object>> entries(String bucket) =>
      _buckets[bucket]?.values ?? const <JsBinding<Object>>[];

  /// 泄漏观测：**本页**登记过、当前仍在缓存里的条目数（按桶）。
  ///
  /// 判据是「本页登记的对象在页面销毁后仍留在缓存里」——不拿全局计数做差分，
  /// 故同屏多实例（兄弟页面的活对象）不会误报；弱引用条目即便目标已被回收，
  /// 只要条目没被 remove 仍然计入（残留本身就是要报的信号：释放路径漏跑了）。
  ///
  /// **不做任何「在途/新近」豁免**：宿主 release 消息在本实现里是同步到达的，
  /// 一旦出现残留就是真的没清掉，宁可多报也不能漏报。
  Map<String, int> pageCounts(String pageKey) {
    final out = <String, int>{};
    for (final e in _buckets.entries) {
      var n = 0;
      for (final b in e.value.values) {
        if (b.pageKey == pageKey) n += 1;
      }
      if (n > 0) out[e.key] = n;
    }
    return out;
  }

  /// 某页登记的全部绑定（跨桶）：泄漏报警时用来列出「具体是哪条没释放」。
  Iterable<JsBinding<Object>> entriesOfPage(String pageKey) => _buckets.values
      .expand((m) => m.values)
      .where((e) => e.pageKey == pageKey);

  /// 泄漏观测后的页面兜底清理：静默摘除**本页登记的全部条目**（跨桶，含
  /// `ctx/node` 的 Element 镜像；不发 release 消息——对象已由 JS 侧 sweepPage
  /// 拥有端释放）。页面销毁后调用，返回摘除条数。
  ///
  /// 语义就是「页面退出即清干净」：不论本页挂载过几次、卸载路径有没有跑全，
  /// 只要条目自带本页 pageKey 就会被摘掉，因此不会随进出次数累积。幂等。
  int dropPageEntries(String pageKey) {
    var n = 0;
    for (final entry in _buckets.entries) {
      final removed = entry.value.length;
      entry.value.removeWhere((_, b) => b.pageKey == pageKey);
      n += removed - entry.value.length;
    }
    return n;
  }

  /// 当前缓存总量（跨桶条目数）。
  int get totalCount =>
      _buckets.values.fold(0, (a, m) => a + m.length);

  /// 全部绑定条目（跨桶）。
  ///
  /// 泄漏观测在页面**进入**与**销毁**两端各取一次快照，比对「进入后新增且仍未
  /// 释放」的条目（见 `js_leak_snapshot.dart`）；本方法提供快照的原始数据。
  Iterable<JsBinding<Object>> get allEntries =>
      _buckets.values.expand((m) => m.values);

  /// 本页**新登记过**的条目累计数、页面名——都不在业务缓存里维护，见切面
  /// `js_ui/leak/leak_stats.dart`。

  /// 全部绑定的全景文本（按桶分组）：排查时一次看全，不用挨个表找。
  String dump() {
    final total = _buckets.values.fold(0, (a, m) => a + m.length);
    final sb = StringBuffer('binding cache: ${_buckets.length} 桶 / $total 条');
    for (final e in _buckets.entries) {
      sb.write('\n  [${e.key}] ${e.value.length} 条');
      for (final b in e.value.values) {
        sb.write('\n    ${b.describe()}');
      }
    }
    return sb.toString();
  }

  /// 打一条全景日志（仅 debug）。
  void dumpLog() {
    if (kDebugMode) HotPatchLog.log(dump());
  }

  void _logPut(JsBinding<Object> e) {
    if (!kDebugMode || !HotPatchLog.verboseCache) return;
    HotPatchLog.log('[binding] + ${e.describe()}');
  }

  /// ---- 统计切面挂载点（debug-only）----
  ///
  /// 业务侧只提供挂载点，不携带任何统计状态：
  ///   - [debugOnRegister]：新登记了一条（只递出页归属）——旁路记账用；
  ///   - [debugPageLabel]：pageKey → 日志显示名。
  /// 均由 `leak/leak_stats.dart` 在 debug 构建里装配；release 下恒为 null，且
  /// `kDebugMode` 是编译期常量，下面两处调用被整段裁剪。

  static void Function(String? pageKey)? debugOnRegister;
  static String Function(String pageKey)? debugPageLabel;

  /// 通知统计切面。**统计只观测**：任何异常都吞掉，绝不影响绑定登记本身。
  void _notifyStat(JsBinding<Object> e) {
    if (!kDebugMode) return;
    try {
      debugOnRegister?.call(e.pageKey);
    } catch (_) {
      // 切面异常不得影响业务（不重抛、不打日志，避免二次副作用）。
    }
  }
}
