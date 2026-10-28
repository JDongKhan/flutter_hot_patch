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
// `Future<bool?>`。这里复用 easy_refresh 的思路（见 its `__jsuiAwaitRun`）：
// JS 执行事件、await 其 Promise，再把结果经唯一 JS→宿主出口回传 token；
// 宿主按 token 结算 Completer（JS 片段见生成器 `dismissible_js.dart`）。
//
// 未支持（值形态超出跨语言表达，宿主按 Flutter 默认值渲染）：
//   - `dismissThresholds`（Map<DismissDirection, double>）；
//   - `onUpdate`（DismissUpdateDetails 值对象）。
import 'dart:async';
import 'dart:convert';

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';

import '../../../services/js_runtime_manager.dart';
import '../../js_widget_registry.dart';
import '../core/from_json/dart_values_from_json.dart';
import '../core/from_json/layout_from_json.dart';
import '../key/key_bridge.dart';

/// `confirmDismiss` 完成通道：JS 侧 await 完事件后回传 `[token, 结果 JSON]`。
const String awaitValueDoneChannel = 'jsuiAwaitValueDone';

/// token → 等待 JS 返回值的确认请求。
final Map<String, Completer<Object?>> _pendingValues = {};

int _valueSeq = 0;

bool _channelsRegistered = false;

/// 幂等登记本能力的宿主通道（由 js_ui_capabilities 聚合调用）。
void ensureDismissibleChannels() {
  if (_channelsRegistered) return;
  _channelsRegistered = true;
  JsRuntimeManager.registerHostMethod(
    awaitValueDoneChannel,
    (String token, Object? resultJson) {
      final completer = _pendingValues.remove(token);
      if (completer == null || completer.isCompleted) return null;
      Object? value;
      if (resultJson is String && resultJson.isNotEmpty) {
        try {
          value = jsonDecode(resultJson);
        } catch (_) {
          value = null;
        }
      }
      completer.complete(value);
      return null;
    },
  );
}

/// 触发一次 JS 事件并等待其返回值（JS 返回 Promise 时会被 await）。
///
/// [handler] 是 JS 侧事件句柄 `{'__fn': id}`；形态不对时立即返回 null
/// （等价于「没有这个回调」）。
Future<Object?> _awaitJsValue(Object? handler, [List<Object?> args = const []]) {
  final id = handler is Map ? handler['__fn'] : null;
  if (id is! String) return Future<Object?>.value(null);
  final token = 'dv${++_valueSeq}';
  final completer = Completer<Object?>();
  _pendingValues[token] = completer;
  // args 与 invoke 相同：内层数组 JSON 文本，外层字符串字面量。
  JsRuntimeManager.instance.evaluate(
    '__jsuiAwaitValue(${jsonEncode(id)}, ${jsonEncode(token)}, '
    '${jsonEncode(jsonEncode(args))});',
  );
  // 兜底超时：JS 运行时销毁 / 句柄中途释放时回程永不到达，条目不能永远悬着。
  return completer.future.timeout(const Duration(seconds: 30), onTimeout: () {
    _pendingValues.remove(token);
    // 超时按「不确认」处理：条目留在原地，避免界面与手势结果不一致。
    return null;
  });
}

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
    final declared = jsKeyOf(c.props['key']);
    // Dismissible 必须有 key：GlobalKey 不能与 `_JsNode` 共用（同一 key 挂在
    // 祖先与后代上会触发重复 key 断言），交给 hostStateKey 另分配；LocalKey 按
    // 值重建（跨语言值相等）；未声明时用常量占位——每个 Dismissible 处在各自
    // `_JsNode` 下，常量 key 不会与兄弟冲突，且重建时保持稳定。
    final key = declared is GlobalKey
        ? hostStateKey(c.props['key'])
        : (declared ?? const ValueKey<String>('js.dismissible'));
    // resizeDuration：显式 null = 不收缩（Flutter 语义），未提供时是 300ms；
    // 两者必须区分，不能一律 `?? 默认值`。
    final resizeDuration = c.props.containsKey('resizeDuration')
        ? durationFromJson(c.props['resizeDuration'])
        : const Duration(milliseconds: 300);
    final confirm = c.props['confirmDismiss'];
    final onDismissed = c.props['onDismissed'];
    return Dismissible(
      key: key,
      background: c.children['background'] as Widget?,
      secondaryBackground: c.children['secondaryBackground'] as Widget?,
      direction: dismissDirectionFromJson(c.props['direction']) ?? DismissDirection.horizontal,
      resizeDuration: resizeDuration,
      movementDuration: durationFromJson(c.props['movementDuration']) ?? const Duration(milliseconds: 200),
      crossAxisEndOffset: c.num_('crossAxisEndOffset') ?? 0.0,
      dragStartBehavior: dragStartBehaviorFromJson(c.props['dragStartBehavior']),
      behavior: hitTestBehaviorFromJson(c.props['behavior']) ?? HitTestBehavior.opaque,
      confirmDismiss: confirm == null
          ? null
          : (direction) async => (await _awaitJsValue(confirm, [direction.name])) == true,
      onDismissed: onDismissed == null
          ? null
          : (direction) => c.invoke(onDismissed, [direction.name]),
      child: (c.children['child'] as Widget?) ?? const SizedBox.shrink(),
    );
  });
}
