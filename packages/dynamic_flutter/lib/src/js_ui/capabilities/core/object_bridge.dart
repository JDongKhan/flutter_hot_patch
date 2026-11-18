// 实例对象句柄桥通用层（宿主侧）：**任意**「JS 侧有实例、宿主侧有对应真实对象」
// 的场景共用这一层——ScrollController / TabController / TextEditingController /
// ChangeNotifier 只是其中几类 kind，App 自定义类同样走它（kind 用 `obj/<类名>`）。
//
// 一个句柄桥 = kind 描述符组装（onCreate 建对象、onOp 分派、onRelease 释放）
// + `__handle` 解析；**对象本体与它的绑定信息全部寄存在绑定缓存里**（桶名 =
// 本桥的 kind，见 binding_cache.dart）——不再各占「controller / 回传句柄 /
// attach 去重」三张全局表。各能力只留差异：create（真实对象构造，可拿 meta）、
// onOp（方法分派）、forward（宿主 → JS 镜像的载荷）。
//
// **时序契约（唯一形态）**：真实对象只在 JS 侧构造时创建（`__bindHandle` 发来的
// create 消息 → [create]，构造参数随 meta 下发）。宿主渲染组件时**只按 id 取已建好
// 的对象**（[controllerAt] / [require]），不存在「渲染期兜底造一个实例」的路径——
// 那会让同一 JS 实例在不同时刻对上两个宿主对象（构造参数丢失、listener 挂错实例）。
// 缺对象时出声抛错，不静默兜底。
//
// **回传方向（宿主 → JS 镜像）也在本层**：需要在对象变化后回传的 kind 给
// [forward]，onCreate 时挂一次 listener（对象是 [Listenable] 时），首帧快照由
// [forwardOnNextFrame] 补（渲染方在挂上组件的那一帧调一次）。因此宿主侧不需要
// 任何「控制器 Host 组件」包装：renderer 直接取对象、交给真实 widget。
import 'package:flutter/widgets.dart';

import '../../../utils/dynamic_flutter_log.dart';
import '../../js_widget_registry.dart';
import 'binding_cache.dart';
import 'handle_registry.dart';

/// 实例对象句柄桥（[T] 为宿主侧真实对象）。由能力文件的 `ensureXxxChannels()`
/// 或 App 自定义 `JsUiLibrary.ensureChannels()` 调 [ensure] 幂等完成 kind 注册。
///
/// 通用分派：目标对象实现 [JsHandleMembers] 时，`onOp` 直接传
/// [dispatchJsMember]，**不需要**为每个类再写一遍 switch。
///
/// **引用强度：强引用**（见 binding_cache.dart 的判定 2）——JS 侧句柄才是这些
/// 对象的寿命驱动者，未收到 release 前 Dart 侧唯一持有者就是本缓存，弱化会让
/// 「JS 还持着句柄、对象却被 GC」成为非确定性失效。
///
/// [T] 只要求是普通对象：控制器不一定是 [Listenable]（如 EasyRefreshController
/// 是纯控制类，既非 ChangeNotifier 也非 Listenable）。默认释放语义是
/// ChangeNotifier / AnimationController 调 dispose；类型不同、需要自己的释放
/// 逻辑时用 [onRelease] 覆盖。
class JsObjectBridge<T extends Object> {
  JsObjectBridge({
    required String kind,

    /// 创建真实对象（onCreate 阶段调用）。[meta] 是 JS 侧 `__bindHandle` 随
    /// create 一起下发的构造参数（如 TabController 的 length / initialIndex、
    /// PageController 的 initialPage / viewportFraction）——JS 构造时就把参数
    /// 交过来，宿主不再等渲染才建。
    required T Function(String id, Object? meta) create,

    /// 实例级 op 分派（call/get/set），对象已按 id 解出且非空；
    /// id 未登记（已释放）时按 null 返回并告警。
    required Object? Function(T controller, String op, Map payload) onOp,

    /// 宿主对象变化 → JS 实例镜像：返回本次要回传的参数数组，`null` 表示此刻
    /// 没有可下发的内容（如滚动控制器还没有 clients）。给了本项时，onCreate
    /// 会在对象是 [Listenable] 时挂一次 listener，并在首帧补一次快照。
    List<Object?>? Function(T controller)? forward,

    /// 释放钩子：覆盖默认的「ChangeNotifier / AnimationController 调 dispose」。
    /// 适用于自带 dispose 语义的非 Listenable 控制器（如 EasyRefreshController
    /// 需要在释放时解绑 EasyRefresh）。
    void Function(T controller)? onRelease,
  })  : _kind = kind,
        _create = create,
        _forward = forward,
        _onOp = onOp,
        _onRelease = onRelease;

  /// 本桥的存储桶名 = 句柄 kind（`ctrl/Scroll` / `ctrl/Tab` / `ctrl/Text` /
  /// `notifier/ChangeNotifier` / `obj/<类名>`）：新增一类对象只注册一个 kind 即
  /// 自动获得统一缓存、统一日志与页面兜底回收。
  final String _kind;
  final T Function(String id, Object? meta) _create;
  final List<Object?>? Function(T controller)? _forward;
  final Object? Function(T controller, String op, Map payload) _onOp;
  final void Function(T controller)? _onRelease;

  JsBindingCache get _cache => JsBindingCache.instance;

  bool _registered = false;

  /// 已告警过的「句柄尚未创建/已释放却收到 op」组合（释放竞态属正常，但不能
  /// 完全静默，否则调用方只看到 null、不知道为什么没执行）。
  final Set<String> _warnedMissingOps = {};

  /// 已排过首帧快照的句柄（同一 id 只排一次，避免每次 rebuild 都排）。
  final Set<String> _pendingForward = {};

  /// 幂等注册 kind 描述符（重复调用短路，与 registerHandleKind 的 assert 配合）。
  void ensure() {
    if (_registered) return;
    _registered = true;
    registerHandleKind(
        _kind,
        JsHandleKind(
          onCreate: (id, meta, pageKey) {
            final fn = meta is Map ? meta['fn'] : null;
            // 回传句柄一并记进同一条目（cached 的 create 重发幂等）。
            // 强引用：JS 侧句柄才是这些对象的寿命驱动者（见 binding_cache.dart）。
            final binding = _cache.putIfAbsent<T>(
              bucket: _kind,
              id: id,
              kind: _kind,
              // 登记方与类型名都给人看：日志里呈现为
              // `js:ctrl/Tab#11（TabController）· 页面=jsui_2 · 强引用 · … · 登记=JS 构造`。
              owner: 'JS 构造',
              weak: false,
              pageKey: pageKey,
              create: () => _create(id, meta),
              meta: {'fn': fn, 'type': T.toString()},
            );
            final target = binding.target;
            if (target == null) return;
            // 回传句柄缺失时不挂 listener：没有句柄就没有回传对象
            // （镜像类 ChangeNotifier 正是这种形态，方向相反）。
            if (_forward == null || fn == null) return;
            if (target is Listenable) {
              target.addListener(() => _sendForward(id));
            }
            // 首帧快照：建对象时组件可能还没挂上（滚动控制器尚无 clients），
            // 挂上那一帧由渲染方再调 [forwardOnNextFrame] 补一次。
            forwardOnNextFrame(id);
          },
          onOp: (id, op, payload) {
            final c = controllerAt(id);
            if (c == null) {
              final key = '$id|$op';
              if (_warnedMissingOps.length >= 256) _warnedMissingOps.clear();
              if (_warnedMissingOps.add(key)) {
                JsLog.warn('$_kind: 句柄 $id 尚未创建或已释放，'
                    'op "$op" 已丢弃（按 null 返回）');
              }
              return null;
            }
            return _onOp(c, op, payload);
          },
          onRelease: (id) {
            final c = controllerAt(id);
            _pendingForward.remove(id);
            _cache.remove(_kind, id);
            if (c == null) return;
            final release = _onRelease;
            if (release != null) {
              release(c);
              return;
            }
            // AnimationController 等非 ChangeNotifier 的 Listenable 也实现了
            // dispose（AnimationController 有），按类型判断后统一释放。
            if (c is ChangeNotifier) c.dispose();
            if (c is AnimationController) c.dispose();
          },
        ));
  }

  /// 本桥的 kind（`ctrl/Tab` 等；诊断信息用）。
  String get kind => _kind;

  /// 取真实对象（未登记 / 已释放返回 null）。渲染方要区分「没传句柄」与
  /// 「句柄已失效」时用它；正常路径用 [require]。
  T? controllerAt(String id) => _cache.target<T>(_kind, id);

  /// 取真实对象；未建 / 已释放直接抛错（协议违约：JS 侧必须先构造）。
  ///
  /// 不返回 null、也不现场补建：渲染期补建会丢掉 JS 构造参数，并与 JS 实例的
  /// lifetime 脱钩（同一个 JS 实例对上两个宿主对象）。
  T require(String id) {
    final controller = controllerAt(id);
    if (controller == null) {
      throw FlutterError(
        '$_kind: 句柄 $id 在渲染时不存在——JS 侧必须先构造该对象'
        '（构造参数随 create 的 meta 下发），或该对象已被释放。',
      );
    }
    return controller;
  }

  /// 回传句柄 id（`meta.fn`）：需要手工回传的路径（如动画首帧）经它 invoke。
  Object? fnHandleOf(String id) => _cache.entry<T>(_kind, id)?.meta['fn'];

  /// 立刻把当前状态回传给 JS 镜像（无 [forward] / 对象已释放时短路）。
  void forwardNow(String id) => _sendForward(id);

  /// 下一帧补一次快照：渲染方挂上组件后调用（滚动控制器这一帧才有 clients）。
  /// 同一 id 只排一次，重复调用是空操作。
  void forwardOnNextFrame(String id) {
    if (_forward == null) return;
    if (!_pendingForward.add(id)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_pendingForward.remove(id)) return;
      _sendForward(id);
    });
  }

  void _sendForward(String id) {
    final forward = _forward;
    if (forward == null) return;
    final controller = controllerAt(id);
    if (controller == null) return; // 已释放（release 后 listener 仍可能触发一次）
    final handle = fnHandleOf(id);
    if (handle == null) return;
    final payload = forward(controller);
    if (payload == null) return; // 此刻没有可下发的内容（如尚无 clients）
    invokeJsHandler(handle, payload);
  }

  /// 从 props 的 controller 取值里解析句柄 id：JS 实例跨桥经 toJSON
  /// 序列化为 `{__handle: 'js:<kind>#N'}`。
  static String? idOf(Object? prop) {
    if (prop is Map) {
      final id = prop['__handle'];
      if (id is String) return id;
    }
    return null;
  }
}

/// 「JS 侧按成员名调用宿主对象」的最小契约。
///
/// 为什么需要类自己分派：Dart 没有运行时反射，框架拿不到「字符串成员名 → 方法」
/// 的映射；而每个类把自己对外暴露的成员写清楚，本身就是它的职责。接入成本是
/// **一行一个成员**（`switch` 里一条 `case`），框架侧零改动。
///
/// [op] 取值与 JS 侧调用一一对应：
///   - `call`：`payload['method']` + `payload['args']`（数组）→ 调方法；
///   - `get` ：`payload['name']` → 读字段；
///   - `set` ：`payload['name']` + `payload['value']` → 写字段。
/// 返回非 JSON 值没有意义：JS 侧拿到的就是宿主回填的原样值（可 JSON 化即可）。
abstract interface class JsHandleMembers {
  Object? jsMember(String op, Map payload);
}

/// [JsObjectBridge] 的通用 onOp：目标对象实现 [JsHandleMembers] 就转给它。
///
/// 直接把 `dispatchJsMember` 传给 `onOp:` 即可——
/// `JsObjectBridge<NoteObject>(onOp: dispatchJsMember)`（形参逆变，无需包装闭包）。
Object? dispatchJsMember(Object target, String op, Map payload) =>
    target is JsHandleMembers ? target.jsMember(op, payload) : null;
