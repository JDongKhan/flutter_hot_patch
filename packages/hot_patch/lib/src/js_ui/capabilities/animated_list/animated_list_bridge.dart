// ===== 能力：AnimatedList（列表增删动画）=====
//
// AnimatedList 与 ListView.builder 的关键区别：增删不是「重建列表」，而是由
// **AnimatedListState** 记录「第 i 项刚插入 / 第 i 项正在退出」，Flutter 再按
// 记录播放补间。State 只在宿主侧存在（JS 拿不到 State 对象），因此本能力做两件事：
//
//   1. 渲染：`itemBuilder` 由 JS 预展开成有序子结点列表（builder 代理协议，
//      JS 侧只放一个标记回调，见 builderProxySource）——与 ListView 同一套
//      懒槽位/展开机制，不做特殊处理；
//   2. 命令：`GlobalKey.currentState.insertItem / removeItem` 由 key 桥接层的
//      state op 扩展点转进来（见 capabilities/key/key_bridge.dart），这里把
//      「GlobalKey → AnimatedListState」的真实语义补全，并按 Flutter 原方法
//      签名处理 `duration` 命名参数。
//
// 与 Dart 侧一比一：`insertItem(index, {duration})` / `removeItem(index,
// {duration})` 的调用形态完全一致，JS 只是把宿主对象换成句柄 + 同名方法。
import 'package:flutter/material.dart';

import '../../js_widget_registry.dart';
import '../core/from_json/dart_values_from_json.dart';
import '../core/from_json/layout_from_json.dart';
import '../key/key_bridge.dart';

/// 每个 AnimatedList 最近一次渲染出的有序子项（`removeItem` 的退场 widget 用）。
///
/// 键是真实 GlobalKey，值随每次渲染覆盖；Expando 随 key 一起回收，不额外持有。
final Expando<List<Widget>> _latestItems = Expando('animatedList.items');

/// 上一次渲染的子项（删除前的列表）。
///
/// `removeItem` 可能在 `setState` 重建**之前**也可能在**之后**到达（取决于 JS
/// 侧调用与宿主 commit 的先后），所以不能固定取某一帧：取「长度较大的那个」
/// 就是删除前的列表（一次删除只少一项），退场项永远是被删掉的那一项。
final Expando<List<Widget>> _previousItems = Expando('animatedList.prevItems');

Widget _itemAt(List<Widget> items, int index) =>
    (index >= 0 && index < items.length) ? items[index] : const SizedBox.shrink();

/// 删除前的子项列表（见 [_previousItems] 的说明）。
List<Widget> _itemsBeforeRemoval(GlobalKey key) {
  final latest = _latestItems[key] ?? const <Widget>[];
  final previous = _previousItems[key] ?? const <Widget>[];
  return latest.length >= previous.length ? latest : previous;
}

Duration _durationOf(Map<String, Object?> payload) =>
    durationFromJson(payload['duration']) ??
    const Duration(milliseconds: 300);

/// AnimatedList 能力：宿主组件注册 + `currentState` 方法。
void registerAnimatedListWidgets(JsWidgetRegistry r) {
  r.register('AnimatedList', (c) {
    final items = (c.children['__items'] as List<Widget>?) ?? const <Widget>[];
    // 元素的 key 已挂在元素结点（`_JsNode`）上，GlobalKey 不能同时挂两处，故
    // 真实 widget 用 [hostStateKey] 分配的独立 GlobalKey；`currentState` 解析
    // 会顺着这层映射找到 AnimatedListState（见 key_bridge）。
    final key = hostStateKey(c.props['key']);
    final previous = _latestItems[key];
    if (previous != null) _previousItems[key] = previous;
    _latestItems[key] = items;
    return AnimatedList(
      key: key,
      initialItemCount: items.length,
      scrollDirection: axisFromJson(c.props['scrollDirection']) ?? Axis.vertical,
      reverse: c.bool_('reverse') ?? false,
      padding: nullableEdgeInsets(c.map('padding')),
      // JS 侧 itemBuilder 已按 index 预展开成子结点；这里按下标取，越界给占位
      // （末项退场期间 Flutter 会以旧下标回调，越界不能崩）。
      //
      // **不加任何过渡包装**：Dart 源码的 itemBuilder 没消费 `animation`，JS 版
      // 就与原生完全一致（增删瞬间生效）。JS 的 builder 拿不到 Animation 对象
      // （预展开时只传 ctx 与 index），所以不能在 JS 侧还原 `SizeTransition`；
      // 需要过渡时先在 Dart 侧支持 animation 下发。
      itemBuilder: (context, index, animation) => _itemAt(items, index),
    );
  });

  // `GlobalKey.currentState.insertItem(index, {duration})`。
  // 键带 State 类型名：不同组件的同名方法互不影响。
  registerKeyStateOp('AnimatedListState.insertItem', (key, payload) {
    final state = key.currentState;
    if (state is! AnimatedListState) return null;
    final index = payload['index'];
    if (index is! num) return null;
    state.insertItem(index.toInt(), duration: _durationOf(payload));
    return null;
  });

  // `GlobalKey.currentState.removeItem(index, builder, {duration})`：退场 widget
  // 取**删除前**那一帧的第 index 项。
  //
  // 已知限制：Dart 传入的退场 `builder` 是闭包，跨语言无法执行，JS 侧只能复用
  // 「被移除的原项」——因此退场样式与普通项一致（Dart 侧若写了不同的退场样式，
  // 只有原生版生效）。JS 代理类对该参数会告警一次（见 js_widget_defs.dart）。
  registerKeyStateOp('AnimatedListState.removeItem', (key, payload) {
    final state = key.currentState;
    if (state is! AnimatedListState) return null;
    final index = payload['index'];
    if (index is! num) return null;
    final items = _itemsBeforeRemoval(key);
    state.removeItem(
      index.toInt(),
      (context, animation) => _itemAt(items, index.toInt()),
      duration: _durationOf(payload),
    );
    return null;
  });
}
