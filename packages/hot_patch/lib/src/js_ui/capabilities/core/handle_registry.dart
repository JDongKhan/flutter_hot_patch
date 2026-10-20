// 跨语言句柄注册表（宿主侧，通用层地基）。
//
// 与 JS 侧 handle_registry_js.dart **对称**（同目录并排）：一个真实对象只存在于一端，
// 另一端只持句柄（id），操作按 id 转发。
//   - JS 端登记句柄（`new ScrollController()`）→ 经 `jsHandle:create` 同步到宿主，
//     由同名 kind 描述符创建真实对象；
//   - 释放（任一端发起）→ 统一经 `jsHandle:release` 落到拥有端的描述符销毁真实
//     对象；重复释放幂等；
//   - 宿主 → JS 端真实对象：evaluate **同步**（`__jsui.call`）；
//   - JS → 宿主端真实对象：host 通道 **异步**（返回 Promise）。
//
// **扩展点**：新增能力 = 两端各 registerHandleKind 注册一个描述符
// （onCreate / onOp / onRelease），核心文件（本文件 / runtime_source 骨架 /
// disposeRoot）零改动。
//
// **为什么本文件刻意不是 [JsUiLibrary] 子类**（地基而非能力）：
//   1. 它是「插座」而不是「插头」——各能力的 `ensureChannels()` 全都调
//      [registerHandleKind]，故 [ensureHandleChannels] 必须**显式**排在
//      js_ui_capabilities 的遍历循环之前；若改成靠注册表顺序自律，重排
//      清单会静默炸掉全部能力；
//   2. JS 侧 handle_registry_js.dart 目前拼在 mini-react 骨架**之前**
//      （见 runtime_source），进模板循环会被挪到骨架之后，需逐段重新论证
//      求值顺序；
//   3. 全框架只有这一个句柄注册表，永无「第二个实现」，模板的幂等注册/
//      可替换价值在此为零。
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../services/js_runtime_manager.dart';
import '../../../utils/hot_patch_log.dart';

/// 一个 kind 的描述符：三端 hook 均按需提供。
class JsHandleKind {
  const JsHandleKind({this.onCreate, this.onOp, this.onRelease});

  /// JS 端登记句柄时调用（据此创建/登记真实对象）。meta 为随句柄下发的
  /// 构造参数（如 TabController 的 length/initialIndex）。
  final void Function(String id, Object? meta)? onCreate;

  /// 宿主端真实对象上的 op（JS → 宿主调用）：op ∈ call/get/set/invoke。
  /// payload 为 `{method?, args?, name?, value?}`。返回值经通道回填 JS Promise。
  final Object? Function(String id, String op, Map payload)? onOp;

  /// 释放宿主端真实对象（拥有端为准）。幂等。
  final void Function(String id)? onRelease;
}

/// kind → 描述符（全局唯一）。
final Map<String, JsHandleKind> _handleKinds = {};

/// 句柄 id → kind：create 时登记，release 时据此路由到对应描述符。
final Map<String, String> _handleKindById = {};

/// 句柄 id → pageKey（仅 scope=page 的句柄）：页面销毁时按页兜底回收。
final Map<String, String> _handlePageById = {};

/// 注册一个 kind 描述符（幂等覆盖；同名重复注册在 debug 下暴露）。
void registerHandleKind(String kind, JsHandleKind desc) {
  assert(
    !_handleKinds.containsKey(kind),
    'registerHandleKind: kind "$kind" 已注册（重复注册会静默覆盖）',
  );
  _handleKinds[kind] = desc;
}

bool _handleChannelsRegistered = false;

/// 幂等注册通用句柄通道（由 js_ui_capabilities.ensureJsUiCapabilities 聚合调用）。
void ensureHandleChannels() {
  if (_handleChannelsRegistered) return;
  _handleChannelsRegistered = true;
  JsRuntimeManager.registerHostMethod('jsHandle', (Object? payload) {
    if (payload is! Map) return null;
    final id = payload['id']?.toString();
    if (id == null || id.isEmpty) return null;
    final op = payload['op']?.toString() ?? '';
    switch (op) {
      case 'create':
        final kind = payload['kind']?.toString() ?? '';
        final pageKey = payload['pageKey']?.toString();
        _handleKindById[id] = kind;
        if (pageKey != null && pageKey.isNotEmpty) {
          _handlePageById[id] = pageKey;
          // 泄漏观测归属（仅 debug）：页面销毁后要能把「释放跑了、但某张镜像表
          // 没清」的残留归因到本页。
          if (kDebugMode) _debugHandlePage[id] = pageKey;
        }
        _handleKinds[kind]?.onCreate?.call(id, payload['meta']);
        break;
      case 'release':
        // 拥有端为准：先摘除路由再回调（防重复释放 + 防释放中再次触发）。
        releaseHandleLocal(id);
        break;
      default:
        final kind = _handleKindById[id];
        final desc = kind != null ? _handleKinds[kind] : null;
        final impl = desc?.onOp;
        if (impl == null) return null;
        return impl(id, op, payload);
    }
    return null;
  });
}

/// 释放**本端**真实对象（不回通知 JS）。幂等。
void releaseHandleLocal(String id) {
  _handlePageById.remove(id);
  final kind = _handleKindById.remove(id);
  if (kind != null) {
    _handleKinds[kind]?.onRelease?.call(id);
  }
}

/// 页面兜底：释放该页登记的全部句柄（含通知 JS 释放对端句柄）。
///
/// 正常路径下 JS 侧 disposeRoot 已逐个 release 并通知到本端，此处为空操作；
/// 仅当 JS 侧释放未走到（异常/运行时被销毁）时兜底，保证两端的页面级资源
/// 都不残留。JS 侧的 release 是幂等的，且自 JS 发起的释放不会二次回通知，
/// 故不存在回环。
void releasePageHandles(String pageKey) {
  final ids = _handlePageById.entries
      .where((e) => e.value == pageKey)
      .map((e) => e.key)
      .toList();
  for (final id in ids) {
    releaseHandleLocal(id);
    _evalJs('__jsui.release(${jsonEncode(id)});');
  }
}

void _evalJs(String code) {
  final r = JsRuntimeManager.instance.evaluate(code);
  if (r.isError) {
    HotPatchLog.log('jsHandle eval failed: ${r.stringResult} | code: $code');
  }
}

// ===== debug 泄漏观测（仅 js_leak_snapshot.dart 读取；release 探针表恒空） =====

/// debug：句柄 id → 登记它的页面（仅 scope=page 的句柄，见 jsHandle create 的
/// pageKey）。
///
/// **刻意不在 release 时清理**：泄漏检查发生在 `releasePageHandles` **之后**，
/// 此刻还要能把「释放跑了、但某张镜像表漏清」的残留归因到本页（否则这类 bug
/// 反而会被静默漏检）；页面泄漏检查结束由 [dropDebugPageOwnership] 统一回收。
final Map<String, String> _debugHandlePage = {};

/// debug 探针辅助：统计 [keys] 中属于 [pageKey] 的条目数。
int debugPageOwnedCount(Iterable<String> keys, String pageKey) {
  var n = 0;
  for (final k in keys) {
    if (_debugHandlePage[k] == pageKey) n += 1;
  }
  return n;
}

/// debug：回收某页的句柄归属登记（页面泄漏检查完成后调用，防表无界增长）。
void dropDebugPageOwnership(String pageKey) {
  _debugHandlePage.removeWhere((_, page) => page == pageKey);
}

/// 句柄相关 Dart 表的「本页残留」探针：key 为表名，value 接收 pageKey、返回
/// **本页登记过且当前仍在该表里**的条目数。各能力在 ensure* 时按 kDebugMode
/// 登记——release 构建本表恒空、无任何回调被注册，线上零开销。
///
/// **为什么必须带 pageKey**：这些镜像表都是**进程内全局表**（按句柄/结点 id
/// 索引，与页面无关）。同屏多实例时，表规模天然被兄弟页面活着的对象撑大；拿
/// 全局计数做「进入前 / 销毁后」差分，会把兄弟实例的活对象误判成本页泄漏。
/// 按归属统计后判据变成「本页登记的对象在页面销毁后仍留在表里」，跨实例正交。
final dartHandleTableProbes = <String, int Function(String pageKey)>{};

/// 本注册表（路由 + 页面索引）的**本页**快照。[pageKey]：只统计本页登记过的
/// 句柄——页面 dispose 兜底回收后两项都应为空。
Map<String, Object?> dartHandleRegistrySnapshot(String pageKey) {
  return {
    // 本页仍在页面索引里的句柄数（release 未跑到才有残留）。
    'pageHandles': _handlePageById.values.where((k) => k == pageKey).length,
    // 仍在路由表里的本页句柄 id（非空即残留；逐条报出便于定位具体对象）。
    'ids': Set<String>.of(
      _handleKindById.keys.where((id) => _debugHandlePage[id] == pageKey),
    ),
  };
}
