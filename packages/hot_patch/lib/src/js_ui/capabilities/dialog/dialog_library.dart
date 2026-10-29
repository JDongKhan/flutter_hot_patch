// ===== Dialog 能力：组件注册 =====
//
// 弹层内容里最常用的容器组件（AlertDialog / SimpleDialog / Dialog）。
// 它们只是**普通宿主组件映射**：弹层的挂载/关闭全在 dialog_bridge.dart，
// 这里不持有任何状态，也不做「这是不是一个弹层」的判断。
import 'package:flutter/material.dart';

import '../../js_widget_registry.dart';
import '../base_widget/text_from_json.dart';
import '../core/from_json/dart_values_from_json.dart';
import '../core/from_json/layout_from_json.dart';
import '../core/from_json/painting_from_json.dart';
import '../js_ui_library.dart';
import 'dialog_bridge.dart';

/// Dialog 家族的宿主注册。
void registerDialogWidgets(JsWidgetRegistry r) {
  // AlertDialog：icon / title / content / actions（actions 是数组 slot）。
  // insetPadding 缺省走 Flutter 默认（null 时保留 Api 的 40/24），因此用
  // nullableEdgeInsets 而不是 zero，否则对话框会贴满整屏。
  r.register('AlertDialog', (c) {
    final actions = (c.children['actions'] as List<Widget>?) ?? const <Widget>[];
    return AlertDialog(
      icon: (c.children['icon'] as Widget?),
      title: (c.children['title'] as Widget?),
      titleTextStyle: textStyleFromJson(c.map('titleTextStyle')),
      content: (c.children['content'] as Widget?),
      contentTextStyle: textStyleFromJson(c.map('contentTextStyle')),
      actions: actions.isEmpty ? null : actions,
      actionsPadding: nullableEdgeInsets(c.map('actionsPadding')),
      backgroundColor: colorFromJson(c.props['backgroundColor']),
      elevation: c.num_('elevation'),
      shadowColor: colorFromJson(c.props['shadowColor']),
      surfaceTintColor: colorFromJson(c.props['surfaceTintColor']),
      insetPadding: nullableEdgeInsets(c.map('insetPadding')),
      clipBehavior: clipBehaviorFromJson(c.props['clipBehavior']),
      shape: shapeFromJson(c.props['shape']),
      alignment: alignmentFromJson(c.props['alignment']),
      scrollable: c.bool_('scrollable') ?? false,
      semanticLabel: c.str('semanticLabel'),
    );
  });

  // SimpleDialog：标题 + 一组子项（常用于列表式选择）。
  r.register('SimpleDialog', (c) {
    return SimpleDialog(
      titleTextStyle: textStyleFromJson(c.map('titleTextStyle')),
      backgroundColor: colorFromJson(c.props['backgroundColor']),
      elevation: c.num_('elevation'),
      shadowColor: colorFromJson(c.props['shadowColor']),
      surfaceTintColor: colorFromJson(c.props['surfaceTintColor']),
      insetPadding: nullableEdgeInsets(c.map('insetPadding')),
      clipBehavior: clipBehaviorFromJson(c.props['clipBehavior']),
      shape: shapeFromJson(c.props['shape']),
      alignment: alignmentFromJson(c.props['alignment']),
      title: (c.children['title'] as Widget?),
      children: (c.children['children'] as List<Widget>?) ?? const <Widget>[],
    );
  });

  // Dialog：只有一个 child 的自定义弹层。
  r.register('Dialog', (c) {
    return Dialog(
      backgroundColor: colorFromJson(c.props['backgroundColor']),
      elevation: c.num_('elevation'),
      shadowColor: colorFromJson(c.props['shadowColor']),
      surfaceTintColor: colorFromJson(c.props['surfaceTintColor']),
      insetPadding: nullableEdgeInsets(c.map('insetPadding')),
      clipBehavior: clipBehaviorFromJson(c.props['clipBehavior']),
      shape: shapeFromJson(c.props['shape']),
      alignment: alignmentFromJson(c.props['alignment']),
      child: (c.children['child'] as Widget?),
    );
  });
}

/// 本能力的插件声明（内建：JS 片段随运行时产物发布，故 `jsFragments` 为空）。
class DialogLibrary extends JsUiLibrary {
  const DialogLibrary();

  @override
  String get id => 'dialog';

  @override
  void ensureChannels() => ensureDialogChannels();

  @override
  void registerWidgets(JsWidgetRegistry r) => registerDialogWidgets(r);
}
