import 'package:flutter/material.dart';

// ===========================================================================
// 运行时渲染策略扩展点：JSON 节点 → 真实 Flutter Widget
//
// 与 ui_component_generator 的 WidgetTranslator 设计对称：
// 生成器负责「源码 widget → JSON」，这里负责「JSON → 运行时 widget」。
//
// 扩展一个新 widget（含自定义 widget）只需要两步：
//   1. 实现 WidgetRenderer（types + render）
//   2. 注册：registry.register(MyRenderer())
//
// 稳定类（WidgetRenderContext / WidgetRendererRegistry / HotPatchWidget）
// 无需改动。
// ===========================================================================

/// 一个 JSON 节点的中立视图（渲染时从 Map 解析）。
///
/// 提供 type/props/children 的读取，renderer 按需取用。
class RenderNode {
  final String type;
  final Map<String, dynamic> props;
  final List<RenderNode> children;

  RenderNode._(this.type, this.props, this.children);

  static RenderNode? of(Object? node) {
    if (node is! Map) {
      debugPrint('[hot_patch] RenderNode.of: node is ${node.runtimeType} (not Map)');
      return null;
    }
    final map = Map<String, dynamic>.from(node);
    final type = map['type'] as String?;
    if (type == null) {
      debugPrint('[hot_patch] RenderNode.of: type is null, keys=${map.keys}');
      return null;
    }
    final props = (map['props'] as Map?)?.cast<String, dynamic>() ?? const {};
    final rawChildren = (map['children'] as List?) ?? const [];
    final children = [
      for (final c in rawChildren)
        if (RenderNode.of(c) != null) RenderNode.of(c)!,
    ];
    if (rawChildren.isNotEmpty && children.length != rawChildren.length) {
      debugPrint(
        '[hot_patch] RenderNode.of: children dropped '
        '${rawChildren.length} -> ${children.length}',
      );
    }
    return RenderNode._(type, props, children);
  }
}

/// 渲染上下文：持有注册表与事件回调，向 renderer 提供递归渲染能力。
///
/// renderer 通过 [render] 递归子节点，通过 [onEvent] 上报按钮事件。
class WidgetRenderContext {
  final WidgetRendererRegistry registry;
  final void Function(String event) onEvent;

  /// 嵌套组件宿主（由 HotPatchWidget 注入）：处理 build 树里的
  /// Component 节点（如 DashboardCard 内嵌 BannerCard）。
  final ComponentHost? componentHost;

  WidgetRenderContext({
    required this.registry,
    required this.onEvent,
    this.componentHost,
  });

  /// 渲染一个节点。
  ///
  /// 外部入口传原始 JSON Map；renderer 递归时传已解析的 [RenderNode]，
  /// 两种形态都接受（RenderNode 直接复用，避免二次解析）。
  Widget render(Object? node) {
    final RenderNode rn;
    if (node is RenderNode) {
      rn = node;
    } else {
      final parsed = RenderNode.of(node);
      if (parsed == null) return const SizedBox.shrink();
      rn = parsed;
    }
    // 嵌套组件节点：递归渲染（共享宿主与注册表）
    if (rn.type == 'Component') return _renderComponent(rn);
    final renderer = registry.lookup(rn.type);
    if (renderer == null) {
      throw StateError(
        'hot_patch: 未注册的节点类型 "${rn.type}"，'
        '请实现并注册对应的 WidgetRenderer（当前已注册: '
        '${registry.registeredTypes.join('/')}）',
      );
    }
    return renderer.render(rn, this);
  }

  Widget _renderComponent(RenderNode node) {
    final name = node.props['component'] as String? ?? '';
    final host = componentHost;
    if (host == null) {
      return Text(
        '[$name]',
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      );
    }
    if (!host.isRegistered(name)) {
      // 无 @UIComponent 注解的 lib 普通 widget：原生直接可用，JS 版占位提示
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          '[$name] 无 JS 版本（原生可用）',
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      );
    }
    final tree = host.treeOf(name);
    // 嵌套子树事件回流到宿主（父级重建整棵树）
    final subCtx = WidgetRenderContext(
      registry: registry,
      onEvent: (e) => host.dispatch(name, e),
      componentHost: host,
    );
    return subCtx.render(tree);
  }
}

/// 嵌套组件宿主：把「实例化/取树/事件分发」与渲染层解耦。
///
/// HotPatchWidget 实现（内部与 JS 运行时交互）；渲染层只依赖这个抽象，
/// 后续支持自定义嵌套组件 / 原生回退时无需改稳定渲染类。
abstract class ComponentHost {
  /// 返回嵌套组件的最新节点树；首次调用会实例化并回调 initState。
  Object? treeOf(String component);

  /// 上报嵌套组件事件（宿主负责调用其方法并重建整棵树）。
  void dispatch(String component, String event);

  /// 组件是否已在 JS 运行时注册（有 @UIComponent 注解的产物）。
  bool isRegistered(String component);
}

/// ===========================================================================
/// 策略抽象类：一种 JSON 节点类型 → 真实 Flutter Widget
///
/// - [types]：支持的 JSON 节点 type 集合（如 {'Text'} 或 {'Column','Row'}）
/// - [render]：节点 → Widget；子节点用 [ctx.render] 递归
/// ===========================================================================
abstract class WidgetRenderer {
  const WidgetRenderer();

  /// 本 renderer 支持的 JSON 节点 type 集合。
  Set<String> get types;

  /// 把 [node] 渲染成真实 Flutter Widget。
  Widget render(RenderNode node, WidgetRenderContext ctx);
}

/// ===========================================================================
/// 管理类：注册 / 分发 renderer
///
/// HotPatchWidget 默认持有内置 renderer；业务方可通过
/// HotPatchWidget(rendererRegistry: ...) 注入扩展。
/// ===========================================================================
class WidgetRendererRegistry {
  final List<WidgetRenderer> _renderers = [];

  /// 注册一个 renderer（同 type 覆盖旧的，后注册者优先）。
  void register(WidgetRenderer renderer) {
    _renderers.removeWhere(
      (r) => r.types.intersection(renderer.types).isNotEmpty,
    );
    _renderers.add(renderer);
  }

  /// 按节点 type 查找 renderer；未注册返回 null。
  WidgetRenderer? lookup(String type) {
    for (final r in _renderers.reversed) {
      if (r.types.contains(type)) return r;
    }
    return null;
  }

  /// 当前已注册的类型集合（用于报错信息）。
  Set<String> get registeredTypes =>
      {for (final r in _renderers) ...r.types};
}
