// ===== 能力：PopScope（拦截返回 + 回调回 JS）=====
//
// `PopScope` 是**纯宿主承载**的组件：它的语义（拦截系统返回 / 返回手势、把
// didPop / result 回传）全部由 Flutter 的 `ModalRoute` 机制实现，JS 侧没有等价物
// 需要镜像——JS 只提供一个回调闭包（句柄）。
//
// 产物形态：`new PopScope({canPop: false, onPopInvokedWithResult: {__fn: id},
// child: …})`，这里直接挂真实 `PopScope`，回调里把 `[didPop, result]` 回传 JS
// （两参事件，与 JS 侧 `(didPop, result) => …` 的形参一一对应）。
//
// `result` 是 Dart 侧任意对象（`Navigator.pop(result)` 的返回值）：能 JSON 编码
// 就原样下发，编不了（自定义类 / 循环引用）降级为 null——跨桥只走 JSON，
// 传不过去的对象不能把整条回传打死。
import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../../js_widget_registry.dart';

/// 登记 PopScope 的宿主承载。
void registerPopScopeWidgets(JsWidgetRegistry r) {
  r.register('PopScope', (c) {
    // `onPopInvoked` 是 Flutter 的旧名（v3.22 起的 deprecated API）：产物里写哪个
    // 键就绑哪个，两者语义相同（都只关心 didPop）。
    final handler =
        c.props['onPopInvokedWithResult'] ?? c.props['onPopInvoked'];
    return _JsPopScope(
      canPop: c.bool_('canPop') ?? true,
      handler: handler,
      child: c.children['child'] as Widget?,
    );
  });
}

class _JsPopScope extends StatelessWidget {
  const _JsPopScope({
    required this.canPop,
    required this.handler,
    required this.child,
  });

  /// 是否允许本路由被弹出；false 时用户返回动作被拦截（调回调但不 pop）。
  final bool canPop;

  /// JS 侧登记的回调句柄（`{__fn: id}`）；null = 不回调。
  final Object? handler;

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: handler == null
          ? null
          : (didPop, result) =>
              invokeJsHandler(handler, [didPop, _jsonSafe(result)]),
      child: child ?? const SizedBox.shrink(),
    );
  }

  /// 能 JSON 编码就原样下发；编不了（自定义对象 / 循环引用）降级 null。
  static Object? _jsonSafe(Object? v) {
    if (v == null) return null;
    try {
      jsonEncode(v);
      return v;
    } catch (_) {
      return null;
    }
  }
}
