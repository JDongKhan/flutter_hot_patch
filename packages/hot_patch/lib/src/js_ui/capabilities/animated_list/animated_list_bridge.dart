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

Widget _itemAt(List<Widget> items, int index) =>
    (index >= 0 && index < items.length) ? items[index] : const SizedBox.shrink();

Duration _durationOf(Map<String, Object?> payload) =>
    durationFromJson(payload['duration']) ??
    const Duration(milliseconds: 300);

/// AnimatedList 能力：宿主组件注册 + `currentState` 方法。
void registerAnimatedListWidgets(JsWidgetRegistry r) {
  r.register('AnimatedList', (c) {
    final items = (c.children['__items'] as List<Widget>?) ?? const <Widget>[];
    // key 由核心统一下发到真实 widget（`c.props['key']` 是序列化形态），
    // 这里取回同一个真实 GlobalKey 用于登记「最近一次的子项快照」。
    final key = jsKeyOf(c.props['key']);
    final globalKey = key is GlobalKey ? key : null;
    if (globalKey != null) _latestItems[globalKey] = items;
    return AnimatedList(
      key: globalKey,
      initialItemCount: items.length,
      scrollDirection: axisFromJson(c.props['scrollDirection']) ?? Axis.vertical,
      reverse: c.bool_('reverse') ?? false,
      padding: nullableEdgeInsets(c.map('padding')),
      // JS 侧 itemBuilder 已按 index 预展开成子结点；这里按下标取，越界给占位
      // （末项退场期间 Flutter 会以旧下标回调，越界不能崩）。
      //
      // 增删补间由**宿主插值**（与隐式动画同口径）：builder 收到的 `animation`
      // 是宿主 AnimationController，逐帧插值不过桥，JS 只需要给出「第 index 项
      // 长什么样」。故这里统一包一层 Size + Fade，与 Dart 侧在 itemBuilder 里
      // 自己写 `SizeTransition(sizeFactor: animation)` 等效。
      itemBuilder: (context, index, animation) => SizeTransition(
        sizeFactor: animation,
        child: FadeTransition(
          opacity: animation,
          child: _itemAt(items, index),
        ),
      ),
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

  // `GlobalKey.currentState.removeItem(index, {duration})`：退场 widget 取最近
  // 一次渲染的第 index 项（与 Dart 侧传 `(context, animation) => item` 同义）。
  registerKeyStateOp('AnimatedListState.removeItem', (key, payload) {
    final state = key.currentState;
    if (state is! AnimatedListState) return null;
    final index = payload['index'];
    if (index is! num) return null;
    final items = _latestItems[key] ?? const <Widget>[];
    state.removeItem(
      index.toInt(),
      (context, animation) => _itemAt(items, index.toInt()),
      duration: _durationOf(payload),
    );
    return null;
  });
}
