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

  WidgetRenderContext({
    required this.registry,
    required this.onEvent,
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
