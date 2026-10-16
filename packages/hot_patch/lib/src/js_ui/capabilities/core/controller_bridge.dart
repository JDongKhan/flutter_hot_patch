// 控制器句柄桥通用层（宿主侧）：ScrollController / TabController /
// TextEditingController / ChangeNotifier 镜像四个能力的同构样板收敛于此。
//
// 一个控制器桥 = 三张表（controller / 回传句柄 / attach 去重）+ kind 描述符
// 组装（onCreate putIfAbsent、onOp 分派、onRelease 释放）+ `__handle` 解析。
// 各能力只留差异：create（真实对象构造，可拿 meta）、onOp（方法分派）、
// Host 的 forward（回传载荷）。
//
// fnHandles / attached 仅 Host 类控制器（Scroll/Tab/Text）使用；镜像类
// （ChangeNotifier）只用 controllers——其 meta 无 fn，登记为 null，无害。
import 'package:flutter/widgets.dart';

import 'handle_registry.dart';

/// 控制器句柄桥（[T] 为宿主侧真实对象）。由能力文件的 `ensureXxxChannels()`
/// 调 [ensure] 幂等完成 kind 注册。
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

  final String _kind;
  final T Function(String id, Object? meta)? _create;
  final Object? Function(T controller, String op, Map payload) _onOp;

  /// 句柄 id → 真实 controller。
  final Map<String, T> controllers = {};

  /// 句柄 id → 回传句柄（meta.fn，Host 挂 listener 时经它 invoke 回 JS 镜像）。
  final Map<String, Object?> fnHandles = {};

  /// 已挂转发的句柄 id（多视图共享同一 controller 时不重复回传）。
  final Set<String> attached = {};

  bool _registered = false;

  /// 幂等注册 kind 描述符（重复调用短路，与 registerHandleKind 的 assert 配合）。
  void ensure() {
    if (_registered) return;
    _registered = true;
    registerHandleKind(
        _kind,
        JsHandleKind(
          onCreate: (id, meta) {
            final create = _create;
            if (create != null) {
              controllers.putIfAbsent(id, () => create(id, meta));
            }
            fnHandles[id] = meta is Map ? meta['fn'] : null;
          },
          onOp: (id, op, payload) {
            final c = controllers[id];
            return c == null ? null : _onOp(c, op, payload);
          },
          onRelease: (id) {
            controllers.remove(id)?.dispose();
            fnHandles.remove(id);
            attached.remove(id);
          },
        ));
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
  late final T _controller =
      widget.bridge.controllers.putIfAbsent(widget.id, widget.create);

  @override
  void initState() {
    super.initState();
    // 同一 id 只挂一次转发（多视图共享同一 controller 时不重复回传）。
    if (widget.bridge.fnHandles[widget.id] != null &&
        widget.bridge.attached.add(widget.id)) {
      _controller.addListener(_forward);
      WidgetsBinding.instance.addPostFrameCallback((_) => _forward());
    }
  }

  void _forward() {
    final handler = widget.bridge.fnHandles[widget.id];
    if (handler == null) return;
    widget.forward(_controller, handler);
  }

  @override
  Widget build(BuildContext context) => widget.buildChild(_controller);
}
