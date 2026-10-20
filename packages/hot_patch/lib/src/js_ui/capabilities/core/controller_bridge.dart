// 控制器句柄桥通用层（宿主侧）：ScrollController / TabController /
// TextEditingController / ChangeNotifier 镜像四个能力的同构样板收敛于此。
//
// 一个控制器桥 = kind 描述符组装（onCreate putIfAbsent、onOp 分派、onRelease
// 释放）+ `__handle` 解析；**对象本体与它的绑定信息全部寄存在绑定缓存里**
// （桶名 = 本桥的 kind，见 binding_cache.dart）——不再各占「controller / 回传
// 句柄 / attach 去重」三张全局表。各能力只留差异：create（真实对象构造，可拿
// meta）、onOp（方法分派）、Host 的 forward（回传载荷）。
//
// 回传句柄（meta.fn）与 attach 去重标记只对 Host 类控制器（Scroll/Tab/Text）
// 有意义；镜像类（ChangeNotifier）的 meta.fn 为 null，无害。
import 'package:flutter/widgets.dart';

import 'binding_cache.dart';
import 'handle_registry.dart';

/// 控制器句柄桥（[T] 为宿主侧真实对象）。由能力文件的 `ensureXxxChannels()`
/// 调 [ensure] 幂等完成 kind 注册。
///
/// **引用强度：强引用**（见 binding_cache.dart 的判定 2）——JS 侧句柄才是这些
/// 对象的寿命驱动者，未收到 release 前 Dart 侧唯一持有者就是本缓存，弱化会让
/// 「JS 还持着句柄、对象却被 GC」成为非确定性失效。
class JsControllerBridge<T extends ChangeNotifier> {
  JsControllerBridge({
    required String kind,

    /// onCreate 阶段创建真实对象（putIfAbsent——与 Host 的兜底创建配合，
    /// 消息与 commit 到达顺序不定，哪端先建都复用同一实例）。为 null 时
    /// onCreate 只登记回传句柄，真实对象由 Host 带参创建（如 TabController
    /// 的 length/initialIndex 随 `__handle` 下发而非 meta）。
    T Function(String id, Object? meta)? create,

    /// 实例级 op 分派（call/get/set），controller 已按 id 解出且非空；
    /// id 未登记（已释放/尚未创建）时静默返回 null（与释放竞态共存）。
    required Object? Function(T controller, String op, Map payload) onOp,
  })  : _kind = kind,
        _create = create,
        _onOp = onOp;

  /// 本桥的存储桶名 = 句柄 kind（`ctrl/Scroll` / `ctrl/Tab` / `ctrl/Text` /
  /// `notifier/ChangeNotifier`）：新增控制器能力照旧只注册一个 kind 即自动获得
  /// 统一缓存、统一日志与页面兜底回收。
  final String _kind;
  final T Function(String id, Object? meta)? _create;
  final Object? Function(T controller, String op, Map payload) _onOp;

  JsBindingCache get _cache => JsBindingCache.instance;

  bool _registered = false;

  /// 幂等注册 kind 描述符（重复调用短路，与 registerHandleKind 的 assert 配合）。
  void ensure() {
    if (_registered) return;
    _registered = true;
    registerHandleKind(
        _kind,
        JsHandleKind(
          onCreate: (id, meta, pageKey) {
            final create = _create;
            // 回传句柄一并记进同一条目（cached 的 create 重发幂等）。
            _cache.putIfAbsent<T>(
              bucket: _kind,
              id: id,
              kind: _kind,
              owner: '$_kind.onCreate',
              pageKey: pageKey,
              create: create == null ? null : () => create(id, meta),
              meta: {'fn': meta is Map ? meta['fn'] : null},
            );
          },
          onOp: (id, op, payload) {
            final c = controllerAt(id);
            return c == null ? null : _onOp(c, op, payload);
          },
          onRelease: (id) {
            final c = controllerAt(id);
            _cache.remove(_kind, id);
            c?.dispose();
          },
        ));
  }

  /// 取真实 controller（未登记 / 已释放返回 null）。
  T? controllerAt(String id) => _cache.target<T>(_kind, id);

  /// 取/建真实 controller（Host 侧兜底创建：与 onCreate 复用同一实例）。
  T controllerOf(String id, T Function() create) =>
      controllerAt(id) ??
      _cache
          .putIfAbsent<T>(
            bucket: _kind,
            id: id,
            kind: _kind,
            owner: '$_kind.host',
            create: create,
          )
          .target!;

  /// 回传句柄 id（`meta.fn`）：Host 挂 listener 时经它 invoke 回 JS 镜像。
  Object? fnHandleOf(String id) => _cache.entry<T>(_kind, id)?.meta['fn'];

  /// 首次 attach 返回 true（同一 id 只挂一次转发——多视图共享同一 controller
  /// 时不重复回传）；回传句柄尚未到达（JS 的 create 未到）也返回 false。
  bool markAttachedOnFirst(String id) {
    final e = _cache.entry<T>(_kind, id);
    if (e == null || e.meta['fn'] == null) return false;
    if (e.meta['attached'] == true) return false;
    e.meta['attached'] = true;
    return true;
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

/// 控制器桥接的通用 Host：按 id 取/建真实 controller（putIfAbsent——Host 若
/// 先于 create 消息构建，与 onCreate 复用同一实例），首次 attach 挂 listener
/// 并经 postFrame 回传一次初始快照（JS 镜像不依赖「先变化才更新」，构造后
/// 立即准确）。真实 controller 生命周期由 JS 侧句柄释放驱动（jsHandle
/// release → onRelease），Host 卸载不重复 dispose。
class JsControllerHost<T extends ChangeNotifier> extends StatefulWidget {
  const JsControllerHost({
    super.key,
    required this.bridge,
    required this.id,
    required this.create,
    required this.forward,
    required this.buildChild,
  });

  final JsControllerBridge<T> bridge;

  /// JS 侧控制器实例的句柄 id（如 'js:ctrl/Scroll#5'）。
  final String id;

  /// putIfAbsent 的兜底创建（可携带句柄下发的构造参数，如 TabController）。
  final T Function() create;

  /// controller 变化 → 回传 JS 实例镜像（闭包内自行 invoke）。
  final void Function(T controller, Object? handler) forward;

  /// 用（按 id 绑定好的）真实 controller 构建具体组件。
  final Widget Function(T controller) buildChild;

  @override
  State<JsControllerHost<T>> createState() => _JsControllerHostState<T>();
}

class _JsControllerHostState<T extends ChangeNotifier>
    extends State<JsControllerHost<T>> {
  late final T _controller = widget.bridge.controllerOf(widget.id, widget.create);

  @override
  void initState() {
    super.initState();
    // 同一 id 只挂一次转发（多视图共享同一 controller 时不重复回传）。
    if (widget.bridge.markAttachedOnFirst(widget.id)) {
      _controller.addListener(_forward);
      WidgetsBinding.instance.addPostFrameCallback((_) => _forward());
    }
  }

  void _forward() {
    final handler = widget.bridge.fnHandleOf(widget.id);
    if (handler == null) return;
    widget.forward(_controller, handler);
  }

  @override
  Widget build(BuildContext context) => widget.buildChild(_controller);
}
