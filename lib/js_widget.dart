import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_js/flutter_js.dart';

/// ============================================================
/// WidgetFactory —— 节点树 → 真实 Flutter Widget 的渲染桥
///
/// JS 只产出声明式描述（type/props/children），真正的 widget
/// 在这里实例化：渲染永远发生在原生 Flutter 侧。
/// 扩展方式：新增一种节点类型 = 新增一个 case。
/// ============================================================
class WidgetFactory {
  const WidgetFactory();

  Widget build(Object? node, {required void Function(String event) onEvent}) {
    if (node is! Map) return const SizedBox.shrink();
    final map = Map<String, dynamic>.from(node);
    final type = map['type'] as String?;
    final props = (map['props'] as Map?)?.cast<String, dynamic>() ?? const {};
    final children = (map['children'] as List?) ?? const [];

    switch (type) {
      case 'Column':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final c in children) build(c, onEvent: onEvent),
          ],
        );
      case 'Row':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final c in children) build(c, onEvent: onEvent),
          ],
        );
      case 'Text':
        return Text(
          props['data']?.toString() ?? '',
          textAlign: TextAlign.center,
          style: _styleFor(props['style']?.toString()),
        );
      case 'Button':
        return ElevatedButton(
          onPressed: () => onEvent(props['event']?.toString() ?? ''),
          child: Text(props['label']?.toString() ?? ''),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  static TextStyle? _styleFor(String? style) {
    final t = ThemeData.light();
    return switch (style) {
      'title' => t.textTheme.headlineSmall,
      'hint' => t.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
      _ => t.textTheme.bodyLarge,
    };
  }
}

/// ============================================================
/// JsWidget —— 加载一份 JS 组件，由 JS 驱动渲染与逻辑
///
/// JS 来自构建期 codegen：注解类（@UIComponent）→ build_runner →
/// .component.js。生产环境可改为从远端下载 + 版本/签名校验。
///
/// 流程：
///   1. 加载 JS 源码
///   2. 创建 JS 运行时（iOS/macOS=JavaScriptCore，Android=QuickJS），
///      把组件注册进全局 __components
///   3. 调用 create() 拿首帧节点树
///   4. 事件回流：handleEvent(action) → 新节点树 → setState 重渲染
///   5. JS→Flutter 原生方向：JS 里 sendMessage('nativeToast', ...)，
///      由 onMessage 通道接住并转成原生 SnackBar
/// ============================================================
class JsWidget extends StatefulWidget {
  const JsWidget({super.key, required this.jsAsset, required this.component});

  /// JS 描述模块的来源。本 demo 用 assets；生产环境换成远端 URL。
  final String jsAsset;

  /// 要实例化的组件名（对应 @UIComponent 注解的 name）。
  final String component;

  @override
  State<JsWidget> createState() => _JsWidgetState();
}

class _JsWidgetState extends State<JsWidget> {
  static const _factory = WidgetFactory();

  JavascriptRuntime? _runtime;
  Object? _tree;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      // 1. 加载 JS 源码（生产环境：从远端下载，校验签名与版本）
      final jsSource = await rootBundle.loadString(widget.jsAsset);

      // 2. 创建 JS 运行时（iOS/macOS 用 JavaScriptCore，Android 用 QuickJS）
      final runtime = getJavascriptRuntime();
      _runtime = runtime;

      // 2.1 注册 JS→Flutter 原生通道
      runtime.onMessage('nativeToast', (dynamic args) {
        debugPrint('[JsWidget] onMessage nativeToast args=$args');
        try {
          final message = args is Map
              ? args['message']?.toString()
              : args?.toString();
          _showNativeToast(message ?? '');
        } catch (_) {}
      });

      // 2.2 把组件注册到全局 __components
      final setup = '''
        var __components = {};
        $jsSource
        __components['${widget.component}'] = {
          create: create,
          handleEvent: handleEvent
        };
      ''';
      runtime.evaluate(setup);

      // 3. 首帧：让 JS 产出节点树
      _tree = _callCreate();
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
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
    return jsonDecode(r.stringResult);
  }

  Object? _callHandleEvent(String action) {
    final r = _runtime!.evaluate(
      'JSON.stringify(__components["${widget.component}"].handleEvent(${jsonEncode(action)}, {}))',
    );
    return jsonDecode(r.stringResult);
  }

  void _onEvent(String event) {
    debugPrint('[JsWidget] onEvent: $event');
    final newTree = _callHandleEvent(event);
    if (!mounted) return;
    setState(() => _tree = newTree);
  }

  void _showNativeToast(String message) {
    debugPrint('[JsWidget] showNativeToast: $message');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text('加载失败: $_error', style: const TextStyle(color: Colors.red)),
      );
    }
    return _factory.build(_tree, onEvent: _onEvent);
  }

  @override
  void dispose() {
    _runtime?.dispose();
    super.dispose();
  }
}
