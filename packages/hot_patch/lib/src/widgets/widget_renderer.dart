import 'package:flutter/material.dart';


import '../hot_patch_widget.dart';
import '../services/native_service.dart';
import '../services/js_runtime_manager.dart';

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
    final children = <RenderNode>[];
    for (final c in rawChildren) {
      // 单次查找：RenderNode.of 内部依赖 inherited widget 注册表，重复调用浪费
      final node = RenderNode.of(c);
      if (node != null) children.add(node);
    }
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

  /// 带值事件（Switch/Slider 等 onChanged 需要把新值传给 JS 方法）。
  /// 未提供时由 renderer 回退到 [onEvent]（无参调用）。
  final void Function(String event, Object? value)? onEventValue;

  /// 当前组件的 jsAsset 所在目录（如 'assets/components/components/'，
  /// 或远端 URL 的目录）。Component 节点的 import 是相对路径，
  /// 渲染递归嵌套 HotPatchWidget 时以它为基准解析成完整 jsAsset——
  /// 产物整体发布（CDN / 包内迁移）后相对关系依然成立。
  final String baseUri;

  /// 原生组件注入表（无 JS 产物的普通 widget）：组件名 → Flutter widget 构造。
  /// 由 HotPatchWidget 透传业务方的 nativeComponents，渲染 Component 节点
  /// 且无 import 时使用；未注册则渲染占位提示。
  final Map<String, Widget Function(Map<String, dynamic> args)>
      nativeComponents;

  /// 嵌套 HotPatchWidget 的扩展点透传（递归渲染 Component 节点时使用）：
  /// 与宿主保持一致，嵌套组件自管理加载/实例化/生命周期/事件/状态。
  final WidgetRendererRegistry? nestedRendererRegistry;
  final List<NativeService>? nativeServices;
  final JsRuntimeManager? sharedManager;

  /// 当前 HotPatchWidget 的 JS 实例 key（`__instances["<key>"]` 寻址）。
  /// ListenableBuilder 等需要反向调 JS（重取 builder 子树 / 挂 JS 监听）时用。
  final String? instanceKey;

  WidgetRenderContext({
    required this.registry,
    required this.onEvent,
    this.onEventValue,
    this.baseUri = '',
    this.nativeComponents = const {},
    this.nestedRendererRegistry,
    this.nativeServices,
    this.sharedManager,
    this.instanceKey,
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
    final args = (node.props['args'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    // 渲染优先级：JS 优先。控制权在 JS 侧——产物可随时发布，想用某组件
    // 的 JS 版就在产物里保留它的 import / class；想回退原生就发布一个
    // 去掉该 import 的产物（组件索引里没有它 → 自然落到 nativeComponents）。
    // 切换全程不动 Dart、不用发版。
    // 1) JS 组件索引（导出类名 → jsAsset，JsRuntimeManager 模块加载时
    //    登记）→ 返回嵌套 HotPatchWidget 递归渲染——它自管理加载/实例化/
    //    生命周期/事件/状态，层级深度不限；扩展点（rendererRegistry/
    //    nativeServices/sharedManager）从本 ctx 透传，与宿主保持一致。
    //    跨文件组件与同文件组件都走索引；
    // 2) 索引未命中 → nativeComponents 显式注入的原生实现（无 JS 产物
    //    的 lib 普通组件等）；
    // 3) 都没有 → 占位提示。
    final manager = sharedManager ?? JsRuntimeManager.instance;
    final jsAsset = manager.resolveComponentAsset(name);
    if (jsAsset != null) {
      return HotPatchWidget(
        jsAsset: jsAsset,
        component: name,
        componentArgs: args,
        rendererRegistry: nestedRendererRegistry,
        nativeServices: nativeServices,
        nativeComponents: nativeComponents,
        sharedManager: manager,
      );
    }
    final builder = nativeComponents[name];
    if (builder != null) return builder(args);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        '[$name] 无 JS 版本（原生可用）',
        style: TextStyle(color: Colors.grey[500], fontSize: 12),
      ),
    );
  }
}

/// ===========================================================================
/// 策略抽象类：一种 JSON 节点类型 → 真实 Flutter Widget
///
/// - [type]：本 renderer 对应的**单一** JSON 节点 type（如 'Text' / 'Column'）。
///   一个 type 一个实现；共用逻辑用继承（基类 + 子类覆写 type）。
/// - [render]：节点 → Widget；子节点用 [ctx.render] 递归
/// ===========================================================================
abstract class WidgetRenderer {
  const WidgetRenderer();

  /// 本 renderer 对应的单一 JSON 节点 type。
  String get type;

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
  /// JSON 节点 type → renderer（Map 直查 O(1)，组件几千个也不退化）。
  final Map<String, WidgetRenderer> _renderers = {};

  /// 注册一个 renderer（同 type 覆盖旧的，后注册者优先）。
  void register(WidgetRenderer renderer) {
    _renderers[renderer.type] = renderer;
  }

  /// 按节点 type 查找 renderer；未注册返回 null。
  WidgetRenderer? lookup(String type) => _renderers[type];

  /// 当前已注册的类型集合（用于报错信息）。
  Set<String> get registeredTypes => _renderers.keys.toSet();
}
