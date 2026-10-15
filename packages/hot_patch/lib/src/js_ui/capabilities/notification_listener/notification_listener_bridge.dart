// ===== 能力：NotificationListener 滚动通知桥接 + 注册 =====
//
// 一个能力 = 桥接组件 + 组件注册，内聚在本文件。
//
// 本能力做什么：JS 侧没有 ScrollPosition/controller 时，滚动监听统一由宿主
// 抓 ScrollNotification，把 metrics 快照经 invoke 回传 JS 事件方法
// （payload 形状与 Dart ScrollNotification 一致，JS 里 `n.metrics.pixels`
// 等属性访问原样可用）。固定 return false，不拦截事件继续冒泡。
import 'package:flutter/material.dart';

import '../../js_widget_registry.dart';

/// NotificationListener 桥接组件（对应注册 key 'NotificationListener'）：
/// 宿主侧监听子树里的滚动通知，把 metrics 快照回传 JS。
///
/// JS 侧写法：
/// ```js
/// NotificationListener({ onNotification: this.__bind("_onScroll") }, [ ... ])
/// ```
/// 滚动时宿主经 invoke 回传 `{type, metrics:{pixels, maxScrollExtent,
/// extentAfter, viewportDimension, axisDirection}}`，JS 事件方法形参（如 n）
/// 直接收下，`n.metrics.pixels` 等属性访问与 Dart 侧源码一比一可用。
class _NotificationListener extends StatefulWidget {
  const _NotificationListener({
    required this.onNotification,
    required this.invoke,
    required this.child,
  });

  /// JS 侧事件句柄（`{'__fn': id}`）。
  final Object? onNotification;

  /// 宿主 → JS 事件回传（js_ui_widget.dart 的 _invoke）。
  final void Function(Object? handler, [List<Object?> args]) invoke;

  final Widget child;

  @override
  State<_NotificationListener> createState() => _NotificationListenerState();
}

class _NotificationListenerState extends State<_NotificationListener> {
  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        final handler = widget.onNotification;
        if (handler != null) {
          // payload 形状对齐 Dart ScrollNotification（metrics 对象 + type 名），
          // JS 事件方法体里的 `n.metrics.pixels` / `n.metrics.extentAfter`
          // 由生成器原样翻译后可直接读取。
          widget.invoke(handler, [{
            'type': n.runtimeType.toString(),
            'metrics': {
              'pixels': n.metrics.pixels,
              'maxScrollExtent': n.metrics.maxScrollExtent,
              'extentAfter': n.metrics.extentAfter,
              'viewportDimension': n.metrics.viewportDimension,
              'axisDirection': n.metrics.axisDirection.name,
            },
          }]);
        }
        // 不拦截：返回 false 让通知继续向上冒泡，外部其它监听不受影响。
        return false;
      },
      child: widget.child,
    );
  }
}

/// 通知能力域组件注册。
void registerNotificationWidgets(JsWidgetRegistry r) {
  r.register('NotificationListener', (c) => _NotificationListener(
        onNotification: c.props['onNotification'],
        invoke: c.invoke,
        child: c.childOrEmpty,
      ));
}
