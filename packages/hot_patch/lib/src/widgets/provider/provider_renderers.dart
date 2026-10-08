import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/js_runtime_manager.dart';
import '../builtin_renderers.dart' show lbRefreshCallbacks;
import '../../utils/hot_patch_log.dart';
import '../widget_renderer.dart';

/// provider 包渲染策略（ChangeNotifierProvider / MultiProvider / Consumer）。
/// 独立子目录承载，避免 builtin_renderers.dart 臃肿；新增 provider 类型
/// （Provider / ListenableProvider 等）在此扩展，核心代码零改动。
void registerProviderRenderers(WidgetRendererRegistry registry) {
  registry
    ..register(const ChangeNotifierProviderRenderer())
    ..register(const MultiProviderRenderer())
    ..register(const ConsumerRenderer());
}

/// ChangeNotifierProvider 渲染：节点 `{type:'ChangeNotifierProvider',
/// props:{model, create, child}}`。initState 在 JS 侧 provider 作用域
/// `__providers[key][model]` 登记模型实例（create.ref 复用状态字段实例 /
/// create.construct 从组件索引 new 模型类），dispose 清理；child 子树正常
/// 渲染。Consumer 渲染时按 key+model 从作用域取实例并挂监听。
class ChangeNotifierProviderRenderer extends WidgetRenderer {
  const ChangeNotifierProviderRenderer();

  @override
  String get type => 'ChangeNotifierProvider';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    final model = node.props['model']?.toString() ?? '';
    final create = (node.props['create'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final child = _childOf(node);
    return _JsChangeNotifierProvider(
      ctx: ctx,
      model: model,
      create: create,
      child: child,
    );
  }
}

class _JsChangeNotifierProvider extends StatefulWidget {
  const _JsChangeNotifierProvider({
    required this.ctx,
    required this.model,
    required this.create,
    required this.child,
  });

  final WidgetRenderContext ctx;
  final String model;
  final Map<String, dynamic> create;
  final RenderNode? child;

  @override
  State<_JsChangeNotifierProvider> createState() =>
      _JsChangeNotifierProviderState();
}

/// 取节点子树：生成器把单子节点放 `props.child`（JSON map），数组子节点放
/// `children`。RenderNode.of 只解析 children 数组，props.child 需显式解析。
RenderNode? _childOf(RenderNode node) {
  final c = node.props['child'];
  if (c is Map) {
    try {
      return RenderNode.of(c.cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }
  return node.children.isNotEmpty ? node.children.first : null;
}

/// 把一条 provider create 登记进 `__providerChain[key]`（栈）。
/// ref：复用状态字段实例（与 Dart 同实例，生命周期归用户）→ 不释放；
/// construct：JS 侧 new 模型类（组件索引反查 jsAsset）→ 标记 `__dispose`，
/// dispose 时由渲染器负责释放（调模型 dispose）。ChangeNotifierProvider /
/// MultiProvider 共用。
void _providerPush(JsRuntimeManager manager, String key, String model,
    Map<String, dynamic> create) {
  final ref = create['ref'];
  final construct = create['construct'];
  if (ref != null) {
    // ref 是状态字段名（跨 JSON 序列化后为裸名，安全起见再剥一次引号）。
    final refName = ref.toString().replaceAll('"', '');
    manager.evaluate(
      '__providerChain = __providerChain || {}; '
      '__providerChain["$key"] = __providerChain["$key"] || []; '
      '__providerChain["$key"].push({ "$model": '
      '__instances["$key"].$refName, "__dispose": false });',
    );
  } else if (construct != null) {
    final jsAsset = manager.resolveComponentAsset(construct.toString());
    if (jsAsset != null) {
      manager.evaluate(
        '__providerChain = __providerChain || {}; '
        '__providerChain["$key"] = __providerChain["$key"] || []; '
        'var __c = __modules["$jsAsset"]; '
        '__providerChain["$key"].push({ "$model": '
        'new __c.$construct(), "__dispose": true });',
      );
    }
  }
}

/// 从 `__providerChain[key]` 倒序 pop 掉 [count] 层（登记顺序 push，
/// dispose 从内向外触发，倒序 pop 与「Consumer 取最近」对应）。
/// pop 出的条目若标记了 `__dispose`（construct 创建）→ 调模型 JS dispose
/// 释放（清订阅、解除监听闭包）；ref 复用（用户管理）的不动。
void _providerPops(JsRuntimeManager manager, String key, int count) {
  manager.evaluate(
    'if (__providerChain && __providerChain["$key"]) { '
    'for (var __i = 0; __i < $count && '
    '__providerChain["$key"].length > 0; __i++) '
    '{ var __e = __providerChain["$key"].pop(); '
    'if (__e && __e.__dispose) { '
    '  for (var __k in __e) { '
    '    if (__k !== "__dispose" && __e[__k] && '
    '        typeof __e[__k].dispose === "function") '
    '    { __e[__k].dispose(); } } } } }',
  );
}

class _JsChangeNotifierProviderState extends State<_JsChangeNotifierProvider> {
  String get _key => widget.ctx.instanceKey ?? '';

  JsRuntimeManager get _manager =>
      widget.ctx.sharedManager ?? JsRuntimeManager.instance;

  @override
  void initState() {
    super.initState();
    _providerPush(_manager, _key, widget.model, widget.create);
  }

  @override
  void dispose() {
    _providerPops(_manager, _key, 1);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    if (child == null) return const SizedBox.shrink();
    return widget.ctx.render(child);
  }
}

/// MultiProvider 渲染：节点 `{type:'MultiProvider', props:{providers:
/// [ChangeNotifierProvider...平级条目], child}}`。与 Dart 源码一一对应：
/// providers 保持平级数组。运行时把所有条目模型按序 push 进
/// `__providerChain[key]`（栈，条目顺序 = 原生 providers.reversed 包裹的
/// 内→外顺序），Consumer 挂监听时取「最近」实例 —— 与原生 MultiProvider
/// 嵌套 Provider.of 语义一致。
class MultiProviderRenderer extends WidgetRenderer {
  const MultiProviderRenderer();

  @override
  String get type => 'MultiProvider';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    final providers = (node.props['providers'] as List?)?.cast<Map>() ??
        const <Map>[];
    final child = _childOf(node);
    return _JsMultiProvider(
      ctx: ctx,
      providers: providers,
      child: child,
    );
  }
}

class _JsMultiProvider extends StatefulWidget {
  const _JsMultiProvider({
    required this.ctx,
    required this.providers,
    required this.child,
  });

  final WidgetRenderContext ctx;
  final List<Map> providers;
  final RenderNode? child;

  @override
  State<_JsMultiProvider> createState() => _JsMultiProviderState();
}

class _JsMultiProviderState extends State<_JsMultiProvider> {
  String get _key => widget.ctx.instanceKey ?? '';

  JsRuntimeManager get _manager =>
      widget.ctx.sharedManager ?? JsRuntimeManager.instance;

  @override
  void initState() {
    super.initState();
    for (final entry in widget.providers) {
      // 条目是 ChangeNotifierProvider 节点：model/create 在 props 里
      final props = (entry['props'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};
      final model = props['model']?.toString() ?? '';
      final create = (props['create'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};
      _providerPush(_manager, _key, model, create);
    }
  }

  @override
  void dispose() {
    _providerPops(_manager, _key, widget.providers.length);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    if (child == null) return const SizedBox.shrink();
    return widget.ctx.render(child);
  }
}

/// Consumer 渲染：节点 `{type:'Consumer', props:{model, builder}}`。
/// initState 从 provider 作用域取 JS 模型实例挂监听（notify →
/// sendMessage('lbNotify', {key, builder}) → 查 lbRefreshCallbacks 表），
/// 重取 builder 子树时把模型实例作为 value 参数传入
/// `__instances[key]._consumerBuilderN(value)`，子树里 value.count 即模型值。
class ConsumerRenderer extends WidgetRenderer {
  const ConsumerRenderer();

  @override
  String get type => 'Consumer';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    final model = node.props['model']?.toString() ?? '';
    final builderName = node.props['builder']?.toString() ?? '';
    return _JsConsumer(
      ctx: ctx,
      model: model,
      builderName: builderName,
    );
  }
}

class _JsConsumer extends StatefulWidget {
  const _JsConsumer({
    required this.ctx,
    required this.model,
    required this.builderName,
  });

  final WidgetRenderContext ctx;
  final String model;
  final String builderName;

  @override
  State<_JsConsumer> createState() => _JsConsumerState();
}

class _JsConsumerState extends State<_JsConsumer> {
  late final String _key;
  late final String _cbKey;
  late RenderNode _node;

  JsRuntimeManager get _manager =>
      widget.ctx.sharedManager ?? JsRuntimeManager.instance;

  @override
  void initState() {
    super.initState();
    _key = widget.ctx.instanceKey ?? '';
    _cbKey = '$_key::${widget.builderName}';
    _node = _fetch();
    lbRefreshCallbacks[_cbKey] = _refresh;
    // 挂 JS 监听：从 provider 作用域链（栈）取最近的模型实例（与原生
    // 「同类型嵌套取最近 Provider」一致），notify 时局部重建
    _manager.evaluate(
      '(function(){ var m = __lookupProvider("$_key", "${widget.model}"); '
      'if (m && typeof m.addListener === "function") { '
      ' m.addListener(function(){ '
      '  sendMessage("lbNotify", JSON.stringify({ key: "$_key", '
      '    builder: "${widget.builderName}" })); }); } })()',
    );
  }

  @override
  void dispose() {
    lbRefreshCallbacks.remove(_cbKey);
    super.dispose();
  }

  /// 重取 builder 子树（JS 实例 `_consumerBuilderN(value)`，value 为
  /// provider 作用域里的模型实例，子树内 value.count 求值）。
  RenderNode _fetch() {
    try {
      final r = _manager.evaluate(
        'JSON.stringify(__instances["$_key"].${widget.builderName}('
        '__lookupProvider("$_key", "${widget.model}")))',
      );
      final node = RenderNode.of(jsonDecode(r.stringResult));
      return node ?? RenderNode.of(const {'type': 'SizedBox'})!;
    } catch (e) {
      HotPatchLog.log('_consumerBuilder fetch error: $e');
      return RenderNode.of(const {'type': 'SizedBox'})!;
    }
  }

  void _refresh() {
    if (!mounted) return;
    setState(() => _node = _fetch());
  }

  @override
  Widget build(BuildContext context) {
    return widget.ctx.render(_node);
  }
}
