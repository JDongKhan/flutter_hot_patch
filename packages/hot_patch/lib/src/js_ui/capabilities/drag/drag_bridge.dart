// ===== 能力：拖拽（Draggable / LongPressDraggable / DragTarget）=====
//
// 拖拽负载 `data` 是**任意 JS 值**（模型 / 闭包 / 数组），跨桥只有 JSON，传过去
// 就只剩快照。所以 JS 侧把它换成按身份索引的 id（生成器 drag_js.dart 的引用表），
// 宿主只拿 id 与 Flutter 原生拖动系统对齐——本文件**从不解释 id 的内容**，
// 原样回传给 JS，由 JS 换回原对象后交给用户回调（`details.data` 与 Dart 里
// `draggable.data` 是同一引用）。
//
// 位置 / 速度 / 时间戳按 JSON 下发：
//   `{dx, dy}` → JS `Offset`；`{pxPerSecond: {dx, dy}}` → JS `Velocity`；
//   `sourceTimeStampUs` → JS `Duration`。还原逻辑在 drag_js.dart。
//
// DragTarget 的 `builder(context, candidateData, rejectedData)` 在 JS 侧执行
// （候选数据只在悬停时产生）：这里把候选/被拒的 id 列表回调过去，JS 执行完
// builder 后以 `child` 插槽回填子树。候选签名（id 列表）去重，悬停期间不重复
// 重建；`onWillAccept` 需要同步返回值、跨语言只能异步，故不接（恒接受）。
import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter/widgets.dart';

import '../../js_widget_registry.dart';
import '../../ui_fallback.dart';
import '../core/from_json/dart_values_from_json.dart';
import '../core/from_json/layout_from_json.dart';

/// 登记拖拽三件套的宿主承载。
void registerDragWidgets(JsWidgetRegistry r) {
  r.register('Draggable', (c) => _draggableOf(c, longPress: false));
  r.register('LongPressDraggable', (c) => _draggableOf(c, longPress: true));
  r.register('DragTarget', (c) => _dragTargetOf(c));
}

/// Draggable / LongPressDraggable：同一份参数折算，两个宿主类各自承载
/// （长按版的额外参数 `delay` / `hapticFeedbackOnStart` 只在该分支出现）。
Widget _draggableOf(JsRenderContext c, {required bool longPress}) {
  // child / feedback 在 Dart 侧都是必填：拿不到说明这棵 JS 树缺内容，给可见兜底。
  final child = c.children['child'] as Widget? ??
      uiFallback('${c.type} 缺少 child');
  final feedback = c.children['feedback'] as Widget? ??
      uiFallback('${c.type} 缺少 feedback（拖拽时的浮动子树）');
  final childWhenDragging = c.children['childWhenDragging'] as Widget?;
  final data = c.props['data'];
  final axis = axisFromJson(c.props['axis']);
  final maxSimultaneousDrags = c.int_('maxSimultaneousDrags');
  final hitTestBehavior =
      _hitTestBehaviorOf(c.props['hitTestBehavior']) ?? HitTestBehavior.deferToChild;
  final rootOverlay = c.bool_('rootOverlay') ?? false;
  final ignoringFeedbackPointer = c.bool_('ignoringFeedbackPointer') ?? true;

  final onDragStarted = c.on('onDragStarted');
  final onDragUpdate = c.on1<Map<String, dynamic>>('onDragUpdate');
  final onDragEnd = c.on1<Map<String, dynamic>>('onDragEnd');
  final onDragCompleted = c.on('onDragCompleted');

  if (longPress) {
    return LongPressDraggable<Object>(
      data: data,
      axis: axis,
      maxSimultaneousDrags: maxSimultaneousDrags,
      hitTestBehavior: hitTestBehavior,
      rootOverlay: rootOverlay,
      ignoringFeedbackPointer: ignoringFeedbackPointer,
      delay: durationFromJson(c.props['delay']) ?? kLongPressTimeout,
      hapticFeedbackOnStart: c.bool_('hapticFeedbackOnStart') ?? true,
      feedback: feedback,
      childWhenDragging: childWhenDragging,
      onDragStarted: onDragStarted,
      onDragUpdate: onDragUpdate == null ? null : _dragUpdateHandler(onDragUpdate),
      onDragEnd: onDragEnd == null ? null : _dragEndHandler(onDragEnd),
      onDragCompleted: onDragCompleted,
      child: child,
    );
  }
  return Draggable<Object>(
    data: data,
    axis: axis,
    maxSimultaneousDrags: maxSimultaneousDrags,
    hitTestBehavior: hitTestBehavior,
    rootOverlay: rootOverlay,
    ignoringFeedbackPointer: ignoringFeedbackPointer,
    feedback: feedback,
    childWhenDragging: childWhenDragging,
    onDragStarted: onDragStarted,
    onDragUpdate: onDragUpdate == null ? null : _dragUpdateHandler(onDragUpdate),
    onDragEnd: onDragEnd == null ? null : _dragEndHandler(onDragEnd),
    onDragCompleted: onDragCompleted,
    child: child,
  );
}

/// `DragUpdateDetails` → JSON（JS 侧还原成同名详情对象）。
void Function(DragUpdateDetails) _dragUpdateHandler(
  ValueChanged<Map<String, dynamic>> emit,
) {
  return (d) => emit(<String, dynamic>{
        'globalPosition': _offsetJson(d.globalPosition),
        'localPosition': _offsetJson(d.localPosition),
        'delta': _offsetJson(d.delta),
        'primaryDelta': d.primaryDelta,
        'sourceTimeStampUs': d.sourceTimeStamp?.inMicroseconds,
      });
}

/// `DraggableDetails` → JSON。
///
/// 注意 Flutter 的 `DraggableDetails` **没有** `data`（要拿负载得用用户自己的
/// 闭包变量），这里同样不下发；JS 侧同名详情对象与 Dart 字段一致。
void Function(DraggableDetails) _dragEndHandler(
  ValueChanged<Map<String, dynamic>> emit,
) {
  return (d) => emit(<String, dynamic>{
        'wasAccepted': d.wasAccepted,
        'offset': _offsetJson(d.offset),
        'velocity': <String, dynamic>{
          'pxPerSecond': _offsetJson(d.velocity.pixelsPerSecond),
        },
      });
}

/// DragTarget：`builder` 句柄 + 已展开的子树。
Widget _dragTargetOf(JsRenderContext c) {
  final builder = c.props['builder'];
  if (builder == null) {
    // builder 是 DragTarget 的必填参数（Dart 侧签名要求）。
    return uiFallback('${c.type} 缺少 builder 句柄');
  }
  return _JsDragTarget(
    builder: builder,
    onAccept: c.on1<Object?>('onAccept'),
    onAcceptWithDetails: c.on1<Map<String, dynamic>>('onAcceptWithDetails'),
    onMove: c.on1<Map<String, dynamic>>('onMove'),
    onLeave: c.on1<Object?>('onLeave'),
    child: c.children['child'] as Widget?,
  );
}

class _JsDragTarget extends StatefulWidget {
  const _JsDragTarget({
    required this.builder,
    required this.child,
    required this.onAccept,
    required this.onAcceptWithDetails,
    required this.onMove,
    required this.onLeave,
  });

  /// JS 侧登记的 builder 句柄（`{__fn: id}`）。
  final Object? builder;

  /// JS 侧按上次候选集合展开的子树（首帧为空）。
  final Widget? child;

  /// Flutter 的 `onAccept` / `onLeave` 形参是 `data`（JS 侧给的 id）。
  final ValueChanged<Object?>? onAccept;
  final ValueChanged<Map<String, dynamic>>? onAcceptWithDetails;
  final ValueChanged<Map<String, dynamic>>? onMove;
  final ValueChanged<Object?>? onLeave;

  @override
  State<_JsDragTarget> createState() => _JsDragTargetState();
}

class _JsDragTargetState extends State<_JsDragTarget> {
  /// 上次回调过去的候选集合签名（id 列表）。
  String? _lastSig;

  void _emitIfChanged(List<Object?> candidate, List<Object?> rejected) {
    final sig = '${candidate.join('|')}#${rejected.join('|')}';
    if (sig == _lastSig) return;
    _lastSig = sig;
    invokeJsHandler(widget.builder, [
      <String, dynamic>{
        'candidate': candidate,
        'rejected': rejected,
      },
    ]);
  }

  @override
  Widget build(BuildContext context) {
    // 首帧没有任何候选时也要回调一次：builder 是 DragTarget 的常规内容来源
    // （Dart 侧同样是 `builder(context, [], [])`），否则目标区域会一直是空的。
    return DragTarget<Object>(
      builder: (context, candidate, rejected) {
        _emitIfChanged(candidate, rejected);
        // 子树由 JS 侧执行 builder 后随 patch 回填。
        return widget.child ?? const SizedBox.shrink();
      },
      onAcceptWithDetails: (d) => widget.onAcceptWithDetails?.call(_detailsJson(d)),
      onMove: (d) => widget.onMove?.call(_detailsJson(d)),
      onLeave: (d) => widget.onLeave?.call(d),
    );
  }
}

Map<String, dynamic> _detailsJson(DragTargetDetails<Object> d) => <String, dynamic>{
      'data': d.data,
      'offset': _offsetJson(d.offset),
    };

Map<String, double> _offsetJson(Offset o) => <String, double>{'dx': o.dx, 'dy': o.dy};

HitTestBehavior? _hitTestBehaviorOf(Object? raw) {
  switch ('$raw') {
    case 'opaque':
      return HitTestBehavior.opaque;
    case 'translucent':
      return HitTestBehavior.translucent;
    case 'deferToChild':
      return HitTestBehavior.deferToChild;
  }
  return null;
}
