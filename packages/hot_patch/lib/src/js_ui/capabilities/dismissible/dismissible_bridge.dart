// ===== 能力：Dismissible（滑动删除）=====
//
// Dismissible 的**手势 / 物理 / 位移 / 收缩动画**全在宿主侧，JS 侧只提供：
//   - 值：`key` / `direction` / `resizeDuration` / `movementDuration` /
//     `crossAxisEndOffset` / `dragStartBehavior` / `behavior`；
//   - 子树：`child` / `background` / `secondaryBackground`（具名槽位）；
//   - 事件：`onDismissed(direction)`、`confirmDismiss(direction)`。
//
// 事件里的 `DismissDirection` 跨语言按**枚举名**下发（`'endToStart'` 等），
// 与 Dart 侧 `direction == DismissDirection.endToStart` 一比一——生成器把枚举
// 静态引用翻成同名字符串，比较结果一致。
//
// `confirmDismiss` 的坑在**回程**：宿主 → JS 的 invoke 是单向的，而 Dart 需要
// `Future<bool?>`。这里用通用入口 `JsRuntimeManager.invokeAwait`（JS 执行事件、
// await 其结果、按 token 回传），与 EasyRefresh 的 onRefresh、未来任何 async
// 事件共用同一条通道，本能力不再单独开回传入口。
//
// 未支持（值形态超出跨语言表达，宿主按 Flutter 默认值渲染）：
//   - `dismissThresholds`（Map<DismissDirection, double>）；
//   - `onUpdate`（DismissUpdateDetails 值对象）。
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';

import '../../../services/js_runtime_manager.dart';
import '../../js_widget_registry.dart';
import '../core/from_json/dart_values_from_json.dart';
import '../core/from_json/layout_from_json.dart';

/// JSON → DismissDirection（枚举名）。
DismissDirection? dismissDirectionFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'horizontal' => DismissDirection.horizontal,
    'vertical' => DismissDirection.vertical,
    'startToEnd' => DismissDirection.startToEnd,
    'endToStart' => DismissDirection.endToStart,
    'up' => DismissDirection.up,
    'down' => DismissDirection.down,
    _ => null,
  };
}

/// JSON → DragStartBehavior（枚举名；缺省 start，与 Flutter 默认一致）。
DragStartBehavior dragStartBehaviorFromJson(Object? v) =>
    v == 'down' ? DragStartBehavior.down : DragStartBehavior.start;

/// Dismissible 能力：宿主组件注册。
void registerDismissibleWidgets(JsWidgetRegistry r) {
  r.register('Dismissible', (c) {
    // Dismissible 必须有 key：直接用结点声明的 key（已挂在真实 widget 上，
    // `GlobalKey.currentState` 即 DismissibleState）；JS 侧漏传时用常量占位
    // （不新建实例，重建保持稳定）。
    final key = c.key ?? const ValueKey<String>('js.dismissible');
    // resizeDuration：显式 null = 不收缩（Flutter 语义），未提供时是 300ms；
    // 两者必须区分，不能一律 `?? 默认值`。
    final resizeDuration = c.props.containsKey('resizeDuration')
        ? c.duration('resizeDuration')
        : const Duration(milliseconds: 300);
    final confirm = c.props['confirmDismiss'];
    final onDismissed = c.props['onDismissed'];
    return Dismissible(
      key: key,
      background: c.children['background'] as Widget?,
      secondaryBackground: c.children['secondaryBackground'] as Widget?,
      direction:
          dismissDirectionFromJson(c.props['direction']) ??
          DismissDirection.horizontal,
      resizeDuration: resizeDuration,
      movementDuration:
          c.duration('movementDuration') ??
          const Duration(milliseconds: 200),
      crossAxisEndOffset: c.double_('crossAxisEndOffset') ?? 0.0,
      dragStartBehavior: dragStartBehaviorFromJson(
        c.props['dragStartBehavior'],
      ),
      behavior:
          c.hitTestBehavior('behavior') ??
          HitTestBehavior.opaque,
      confirmDismiss: confirm == null
          ? null
          : (direction) async =>
                (await JsRuntimeManager.invokeAwait(confirm, [
                  direction.name,
                ])) ==
                true,
      onDismissed: onDismissed == null
          ? null
          : (direction) => c.invoke(onDismissed, [direction.name]),
      child: (c.children['child'] as Widget?) ?? const SizedBox.shrink(),
    );
  });
}
