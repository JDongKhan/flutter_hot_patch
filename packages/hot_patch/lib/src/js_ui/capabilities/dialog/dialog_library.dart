// ===== Dialog 能力：组件注册 =====
//
// 弹层内容里最常用的容器组件（AlertDialog / SimpleDialog / Dialog）与
// Cupertino 侧的弹窗 / 动作面板。它们只是**普通宿主组件映射**：弹层的
// 挂载/关闭全在 dialog_bridge.dart，这里不持有任何状态，也不做「这是不是
// 一个弹层」的判断。
import 'package:flutter/cupertino.dart';
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
  // `.adaptive` 是命名构造（按平台用 Material / Cupertino 实现），按 factory 还原。
  r.register('AlertDialog', (c) {
    final actions = (c.children['actions'] as List<Widget>?) ?? const <Widget>[];
    final icon = (c.children['icon'] as Widget?);
    final title = (c.children['title'] as Widget?);
    final titleTextStyle = textStyleFromJson(c.map('titleTextStyle'));
    final content = (c.children['content'] as Widget?);
    final contentTextStyle = textStyleFromJson(c.map('contentTextStyle'));
    final actionsPadding = nullableEdgeInsets(c.map('actionsPadding'));
    final backgroundColor = colorFromJson(c.props['backgroundColor']);
    final elevation = c.num_('elevation');
    final shadowColor = colorFromJson(c.props['shadowColor']);
    final surfaceTintColor = colorFromJson(c.props['surfaceTintColor']);
    final insetPadding = nullableEdgeInsets(c.map('insetPadding'));
    final clipBehavior = clipBehaviorFromJson(c.props['clipBehavior']);
    final shape = shapeFromJson(c.props['shape']);
    final alignment = alignmentFromJson(c.props['alignment']);
    final scrollable = c.bool_('scrollable') ?? false;
    final semanticLabel = c.str('semanticLabel');
    if (c.str('factory') == 'adaptive') {
      return AlertDialog.adaptive(
        icon: icon,
        title: title,
        titleTextStyle: titleTextStyle,
        content: content,
        contentTextStyle: contentTextStyle,
        actions: actions.isEmpty ? null : actions,
        actionsPadding: actionsPadding,
        backgroundColor: backgroundColor,
        elevation: elevation,
        shadowColor: shadowColor,
        surfaceTintColor: surfaceTintColor,
        insetPadding: insetPadding ??
            const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        clipBehavior: clipBehavior,
        shape: shape,
        alignment: alignment,
        scrollable: scrollable,
        semanticLabel: semanticLabel,
      );
    }
    return AlertDialog(
      icon: icon,
      title: title,
      titleTextStyle: titleTextStyle,
      content: content,
      contentTextStyle: contentTextStyle,
      actions: actions.isEmpty ? null : actions,
      actionsPadding: actionsPadding,
      backgroundColor: backgroundColor,
      elevation: elevation,
      shadowColor: shadowColor,
      surfaceTintColor: surfaceTintColor,
      insetPadding: insetPadding,
      clipBehavior: clipBehavior,
      shape: shape,
      alignment: alignment,
      scrollable: scrollable,
      semanticLabel: semanticLabel,
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

  // Dialog：只有一个 child 的自定义弹层。`.fullscreen` 是命名构造（铺满屏幕、
  // 无 shape/alignment），按 factory 还原。
  r.register('Dialog', (c) {
    final backgroundColor = colorFromJson(c.props['backgroundColor']);
    final elevation = c.num_('elevation');
    final shadowColor = colorFromJson(c.props['shadowColor']);
    final surfaceTintColor = colorFromJson(c.props['surfaceTintColor']);
    final insetPadding = nullableEdgeInsets(c.map('insetPadding'));
    final clipBehavior = clipBehaviorFromJson(c.props['clipBehavior']);
    final child = (c.children['child'] as Widget?);
    if (c.str('factory') == 'fullscreen') {
      return Dialog.fullscreen(
        backgroundColor: backgroundColor,
        child: child,
      );
    }
    return Dialog(
      backgroundColor: backgroundColor,
      elevation: elevation,
      shadowColor: shadowColor,
      surfaceTintColor: surfaceTintColor,
      insetPadding: insetPadding,
      clipBehavior: clipBehavior,
      shape: shapeFromJson(c.props['shape']),
      alignment: alignmentFromJson(c.props['alignment']),
      child: child,
    );
  });

  // ── Cupertino 侧 ──
  // 这些只是普通的宿主 widget 映射：用在 showCupertinoDialog /
  // showAdaptiveDialog / showCupertinoModalPopup 里，也可以在页面内直接用。

  // CupertinoAlertDialog：title / content 单元素 slot，actions 数组 slot。
  // insetAnimationDuration / Curve 保持 Flutter 默认（不映射，避免覆盖主题）。
  r.register('CupertinoAlertDialog', (c) {
    return CupertinoAlertDialog(
      title: (c.children['title'] as Widget?),
      content: (c.children['content'] as Widget?),
      actions: (c.children['actions'] as List<Widget>?) ?? const <Widget>[],
    );
  });

  // CupertinoDialogAction：CupertinoAlertDialog.actions 里的标准按钮。
  r.register('CupertinoDialogAction', (c) {
    return CupertinoDialogAction(
      onPressed: c.on('onPressed'),
      isDefaultAction: c.bool_('isDefaultAction') ?? false,
      isDestructiveAction: c.bool_('isDestructiveAction') ?? false,
      textStyle: textStyleFromJson(c.map('textStyle')),
      child: (c.children['child'] as Widget?) ?? const SizedBox.shrink(),
    );
  });

  // CupertinoActionSheet：title / message / cancelButton 单元素 slot，
  // actions 数组 slot（CupertinoActionSheetAction）。
  r.register('CupertinoActionSheet', (c) {
    final actions = (c.children['actions'] as List<Widget>?) ?? const <Widget>[];
    return CupertinoActionSheet(
      title: (c.children['title'] as Widget?),
      message: (c.children['message'] as Widget?),
      actions: actions.isEmpty ? null : actions,
      cancelButton: (c.children['cancelButton'] as Widget?),
    );
  });

  // CupertinoActionSheetAction：onPressed 在 Flutter 侧是必填，JS 没给时按
  // 空实现兜底（否则整棵弹层树构造成立即抛断言）。
  r.register('CupertinoActionSheetAction', (c) {
    return CupertinoActionSheetAction(
      onPressed: c.on('onPressed') ?? () {},
      isDefaultAction: c.bool_('isDefaultAction') ?? false,
      isDestructiveAction: c.bool_('isDestructiveAction') ?? false,
      child: (c.children['child'] as Widget?) ?? const SizedBox.shrink(),
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
