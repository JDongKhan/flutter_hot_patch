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

import '../../../services/js_runtime_manager.dart';
import '../../../utils/hot_patch_log.dart';

/// 一个 kind 的描述符：三端 hook 均按需提供。
class JsHandleKind {
  const JsHandleKind({this.onCreate, this.onOp, this.onRelease});

  /// JS 端登记句柄时调用（据此创建/登记真实对象）。meta 为随句柄下发的
  /// 构造参数（如 TabController 的 length/initialIndex）；pageKey 是该句柄所属
  /// 页面（global scope 为 null）——绑定条目据此自带页面归属，泄漏观测不必再
  /// 额外维护归属表。
  final void Function(String id, Object? meta, String? pageKey)? onCreate;

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
        final rawPage = payload['pageKey']?.toString();
        final pageKey = (rawPage == null || rawPage.isEmpty) ? null : rawPage;
        _handleKindById[id] = kind;
        if (pageKey != null) _handlePageById[id] = pageKey;
        _handleKinds[kind]?.onCreate?.call(id, payload['meta'], pageKey);
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
    HotPatchLog.error('jsHandle eval failed: ${r.stringResult} | code: $code');
  }
}

// ===== 泄漏观测（仅 js_leak_snapshot.dart 读取；release 下只是纯计数） =====
//
// 对象级的残留由**绑定缓存**自行按页统计（见 binding_cache.dart 的 pageCounts：
// 每个条目自带 pageKey，故不需要任何额外的归属表）；这里只补一项本注册表专有的
// 观测量——页面句柄索引是否被兜底回收干净。

/// 本页仍在**页面句柄索引**里的句柄数（`releasePageHandles` 兜底回收后应为 0；
/// 非 0 说明释放路径整段没跑到，连对象也还在缓存里）。
int dartPageHandleCount(String pageKey) =>
    _handlePageById.values.where((k) => k == pageKey).length;
