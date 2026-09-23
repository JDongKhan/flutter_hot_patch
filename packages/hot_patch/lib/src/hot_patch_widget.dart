import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_js/flutter_js.dart';

import 'builtin_renderers.dart';
import 'builtin_services.dart';
import 'native_service.dart';
import 'widget_renderer.dart';

/// ============================================================
/// HotPatchWidget —— 热更新组件运行时入口
///
/// 使用场景：线上出现 bug 时，下发由 ui_component_generator 从
/// 正常组件静态翻译的 JS 补丁（.component.js + .component.schema.json），
/// 运行时用本组件替换原组件即可修复，无需发版。
///
/// 流程：
///   1. 加载 JS 补丁源码（本 demo 用 assets；生产环境可改为
///      从远端下载 + 版本/签名校验）
///   2. 创建 JS 运行时（iOS/macOS=JavaScriptCore，Android=QuickJS），
///      把补丁组件注册进全局 __components
///   3. 调用 build() 拿首帧节点树（与组件 build() 原封不动对应）
///   4. 事件回流：按钮事件 → 直接调用组件同名方法 → build() 新树 → setState
///   5. JS→Flutter 原生方向：JS 里 sendMessage(channel, ...) 按通道分发
///      到 [NativeService] 实现（默认内置 SnackBar/Log 服务）
///
/// 两个扩展点（均无需改动本组件）：
/// - 渲染层：注入自定义 [rendererRegistry] 支持更多/自定义 widget
/// - 服务层：注入 [nativeServices] 提供各种 JS→原生 能力
/// ============================================================
class HotPatchWidget extends StatefulWidget {
  const HotPatchWidget({
    super.key,
    required this.jsAsset,
    required this.component,
    this.rendererRegistry,
    this.nativeServices,
  });

  /// JS 补丁模块的来源。本 demo 用 assets；生产环境换成远端 URL。
  final String jsAsset;

  /// 要实例化的组件名（对应 @UIComponent 注解的 name）。
  final String component;

  /// 渲染策略注册表。默认注入内置策略（Column/Row/Text/Button）；
  /// 业务方可传入扩展后的注册表以支持更多/自定义 widget。
  final WidgetRendererRegistry? rendererRegistry;

  /// 原生服务注入列表。内置服务（nativeToast/log）始终可用；
  /// 传入的服务为增量扩展（同 channel 时覆盖内置实现）。
  final List<NativeService>? nativeServices;

  @override
  State<HotPatchWidget> createState() => _HotPatchWidgetState();
}

class _HotPatchWidgetState extends State<HotPatchWidget> {
  late final WidgetRendererRegistry _registry;
  late final NativeServiceRegistry _services;

  JavascriptRuntime? _runtime;
  Object? _tree;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // 渲染层：默认注册内置策略；业务方注入的注册表原样使用。
    _registry = widget.rendererRegistry ?? WidgetRendererRegistry();
    if (widget.rendererRegistry == null) {
      registerBuiltinRenderers(_registry);
    }
    // 服务层：内置服务始终注册，外部注入为增量扩展（同 channel 覆盖内置）。
    _services = NativeServiceRegistry();
    registerBuiltinNativeServices(_services);
    for (final svc in widget.nativeServices ?? const <NativeService>[]) {
      _services.register(svc);
    }
    _boot();
  }

  Future<void> _boot() async {
    try {
      // 1. 加载 JS 补丁源码（生产环境：从远端下载，校验签名与版本）
      final jsSource = await rootBundle.loadString(widget.jsAsset);
      debugPrint('[hot_patch] jsSource loaded: ${jsSource.length} chars');

      // 2. 创建 JS 运行时（iOS/macOS 用 JavaScriptCore，Android 用 QuickJS）
      final runtime = getJavascriptRuntime();
      _runtime = runtime;
      debugPrint('[hot_patch] runtime created');

      // 2.1 按注册表挂接 JS→Flutter 原生通道
      for (final channel in _services.channels) {
        final service = _services.lookup(channel)!;
        runtime.onMessage(channel, (dynamic args) {
          debugPrint('[hot_patch] onMessage "$channel" args=$args');
          if (!mounted) return;
          service.handle(context, args);
        });
        debugPrint('[hot_patch] native service "$channel" wired');
      }

      // 2.2 加载补丁模块（产物自包含：声明 __components + IIFE 注册组件）
      runtime.evaluate(jsSource);
      debugPrint('[hot_patch] module loaded');

      // 3. 首帧：让 JS 产出节点树
      _tree = _callBuild();
      debugPrint('[hot_patch] first tree: $_tree');
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      debugPrint('[hot_patch] boot error: $e');
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Object? _callBuild() {
    final r = _runtime!.evaluate(
      'JSON.stringify(__components["${widget.component}"].build())',
    );
    debugPrint('[hot_patch] build raw: "${r.stringResult}"');
    return jsonDecode(r.stringResult);
  }

  void _onEvent(String event) {
    debugPrint('[hot_patch] onEvent: $event');
    // 事件名 = 组件方法名（一比一）：直接调用同名方法，再重新 build 取新树
    final r = _runtime!.evaluate(
      '(function(){ __components["${widget.component}"].$event(); '
      'return JSON.stringify(__components["${widget.component}"].build()); })()',
    );
    final newTree = jsonDecode(r.stringResult);
    if (!mounted) return;
    setState(() => _tree = newTree);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[hot_patch] build: loading=$_loading error=$_error tree=${_tree != null}');
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text('加载失败: $_error', style: const TextStyle(color: Colors.red)),
      );
    }
    final ctx = WidgetRenderContext(registry: _registry, onEvent: _onEvent);
    final w = ctx.render(_tree);
    debugPrint('[hot_patch] render -> ${w.runtimeType}');
    return w;
  }

  @override
  void dispose() {
    _runtime?.dispose();
    super.dispose();
  }
}
