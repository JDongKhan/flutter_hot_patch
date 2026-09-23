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
///   3. 调用 create() 拿首帧节点树
///   4. 事件回流：handleEvent(action) → 新节点树 → setState 重渲染
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

  /// 原生服务列表。默认注入内置服务（nativeToast/log）；
  /// 业务方传入自定义实现以扩展 JS→原生 能力（同 channel 覆盖内置）。
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
    // 服务层：默认注册内置服务；业务方注入的列表注册进新注册表。
    _services = NativeServiceRegistry();
    if (widget.nativeServices == null) {
      registerBuiltinNativeServices(_services);
    } else {
      for (final svc in widget.nativeServices!) {
        _services.register(svc);
      }
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

      // 2.2 把补丁组件注册到全局 __components
      final setup = '''
        var __components = {};
        $jsSource
        __components['${widget.component}'] = {
          create: create,
          handleEvent: handleEvent
        };
      ''';
      runtime.evaluate(setup);
      debugPrint('[hot_patch] setup evaluated');

      // 3. 首帧：让 JS 产出节点树
      _tree = _callCreate();
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

  Object? _callCreate() {
    final r = _runtime!.evaluate(
      'JSON.stringify(__components["${widget.component}"].create())',
    );
    debugPrint('[hot_patch] create raw: "${r.stringResult}"');
    return jsonDecode(r.stringResult);
  }

  Object? _callHandleEvent(String action) {
    final r = _runtime!.evaluate(
      'JSON.stringify(__components["${widget.component}"].handleEvent(${jsonEncode(action)}, {}))',
    );
    return jsonDecode(r.stringResult);
  }

  void _onEvent(String event) {
    debugPrint('[hot_patch] onEvent: $event');
    final newTree = _callHandleEvent(event);
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
