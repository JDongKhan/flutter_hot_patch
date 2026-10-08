import 'package:flutter/material.dart';

import '../json/flutter_from_json.dart';
import '../utils/hot_patch_log.dart';

/// 一次结点构建的上下文：JS 下发的 props + 已构建好的子 widget + 事件回传。
///
/// 这是宿主与 JS 的唯一"翻译面"：JS 侧的 `Text({...})` 到这里变成
/// 真正的 Flutter `Text`。新增一个 JS 组件只要用已有 type 组合即可，
/// 不需要动宿主；只有引入 Flutter 侧不存在的**视觉** widget 才注册一条。
class JsBuildContext {
  JsBuildContext({
    required this.props,
    required this.children,
    required this.childTypes,
    required this.propChildren,
    required this.nativeComponents,
    required this.invoke,
  });

  final Map<String, dynamic> props;
  final List<Widget> children;

  /// 与 [children] 一一对应的宿主 type（用于 Scaffold 这类需要按类型
  /// 区分插槽的容器；JS 只能下发 element，无法在 props 里塞 widget）。
  final List<String> childTypes;

  /// 值为 element 的 props（如 ListTile.leading / ClipRRect.child）：
  /// prop 名 -> 已构建好的子 widget。
  final Map<String, Widget> propChildren;

  /// 非私有/无注解组件（Component 节点）的原生注入表：组件名 -> 构造。
  /// 运行时（hot_patch 包）不 import 业务类，由业务方注册。
  final Map<String, Widget Function(Map<String, dynamic> args)>
      nativeComponents;

  /// 把事件句柄（`{'__fn': id}`）回传到 JS 侧执行。
  final void Function(Object? handler, [Object? payload]) invoke;

  Widget? child([int index = 0]) => index < children.length ? children[index] : null;

  /// 要求子 widget 非空时使用（Expanded / 按钮的 child 等）。
  Widget get childOrEmpty => child() ?? const SizedBox.shrink();

  /// 按子结点 type 取第一个匹配的子 widget。
  Widget? childOfType(String type) {
    for (var i = 0; i < childTypes.length; i++) {
      if (childTypes[i] == type) return children[i];
    }
    return null;
  }

  bool hasChildOfType(String type) => childTypes.contains(type);

  /// 取「值为 element 的 prop」对应的子 widget（如 ListTile.leading）。
  Widget? propChild(String key) => propChildren[key];

  /// 把 props 上的事件字段（句柄）绑成 Flutter 回调；无句柄（null）时为 null。
  VoidCallback? on(String key) {
    final handler = props[key];
    if (handler == null) return null;
    return () => invoke(handler);
  }

  /// 值为句柄的 prop → 带 payload 的回调（Switch/Checkbox/Slider 的 onChanged）。
  ValueChanged<T>? onValue<T>(String key) {
    final handler = props[key];
    if (handler == null) return null;
    return (v) => invoke(handler, v);
  }

  String? str(String key) {
    final v = props[key];
    return v == null ? null : '$v';
  }

  double? num_(String key) {
    final v = props[key];
    if (v is num) return v.toDouble();
    return double.tryParse('$v');
  }

  int? int_(String key) {
    final v = props[key];
    if (v is num) return v.toInt();
    return int.tryParse('$v');
  }

  bool? bool_(String key) {
    final v = props[key];
    return v is bool ? v : null;
  }

  Map<String, dynamic>? map(String key) {
    final v = props[key];
    return v is Map ? v.cast<String, dynamic>() : null;
  }
}

typedef JsWidgetBuilder = Widget Function(JsBuildContext c);

/// `type -> Flutter widget` 注册表（宿主唯一扩展点）。
class JsWidgetRegistry {
  final Map<String, JsWidgetBuilder> _builders = {};

  void register(String type, JsWidgetBuilder builder) => _builders[type] = builder;

  bool has(String type) => _builders.containsKey(type);

  JsWidgetBuilder? lookup(String type) => _builders[type];
}

/// 注册内置的宿主 widget 翻译。
///
/// 只覆盖「JS 侧组件用到的、Flutter 侧真实存在的」类型；未注册的类型渲染为
/// 错误占位（便于定位缺失的翻译），而不是静默空白。
///
/// 状态类 widget（provider / Builder / ListenableBuilder）**不在这里**：
/// 它们由 JS 侧逻辑组件承担，宿主零感知。
void registerBuiltinJsWidgets(JsWidgetRegistry r) {
  r.register('Text', (c) => Text(
        c.str('data') ?? '',
        style: textStyleFromJson(c.map('style')),
        textAlign: textAlignFromJson(c.props['textAlign']),
        overflow: overflowFromJson(c.props['overflow']),
        maxLines: c.int_('maxLines'),
        softWrap: c.bool_('softWrap'),
        textDirection: textDirectionFromJson(c.props['textDirection']),
        textScaler: textScalerFromJson(c.props['textScaler']),
        semanticsLabel: c.str('semanticsLabel'),
      ));

  r.register('Column', (c) => Column(
        mainAxisAlignment: mainAxisAlignmentFromJson(c.props['mainAxisAlignment']) ?? MainAxisAlignment.start,
        crossAxisAlignment: crossAxisAlignmentFromJson(c.props['crossAxisAlignment']) ?? CrossAxisAlignment.center,
        mainAxisSize: mainAxisSizeFromJson(c.props['mainAxisSize']) ?? MainAxisSize.max,
        children: c.children,
      ));

  r.register('Row', (c) => Row(
        mainAxisAlignment: mainAxisAlignmentFromJson(c.props['mainAxisAlignment']) ?? MainAxisAlignment.start,
        crossAxisAlignment: crossAxisAlignmentFromJson(c.props['crossAxisAlignment']) ?? CrossAxisAlignment.center,
        mainAxisSize: mainAxisSizeFromJson(c.props['mainAxisSize']) ?? MainAxisSize.max,
        children: c.children,
      ));

  r.register('Stack', (c) => Stack(
        alignment: alignmentFromJson(c.props['alignment']) ?? AlignmentDirectional.topStart,
        children: c.children,
      ));

  r.register('Wrap', (c) => Wrap(
        spacing: c.num_('spacing') ?? 0,
        runSpacing: c.num_('runSpacing') ?? 0,
        children: c.children,
      ));

  r.register('ListView', (c) => ListView(
        shrinkWrap: true,
        scrollDirection: axisFromJson(c.props['scrollDirection']) ?? Axis.vertical,
        children: c.children,
      ));

  r.register('SingleChildScrollView', (c) => SingleChildScrollView(
        scrollDirection: axisFromJson(c.props['scrollDirection']) ?? Axis.vertical,
        padding: edgeInsetsFromJson(c.map('padding')),
        child: c.child(),
      ));

  r.register('Container', (c) {
    final deco = boxDecorationFromJson(c.map('decoration'));
    return Container(
      width: c.num_('width'),
      height: c.num_('height'),
      // color 与 decoration 同传会断言：decoration 优先（其内可含 color）。
      color: deco == null ? colorFromJson(c.props['color']) : null,
      decoration: deco,
      padding: edgeInsetsFromJson(c.map('padding')),
      margin: edgeInsetsFromJson(c.map('margin')),
      alignment: alignmentFromJson(c.props['alignment']),
      child: c.child(),
    );
  });

  r.register('Padding', (c) => Padding(
        padding: edgeInsetsFromJson(c.map('padding')),
        child: c.child(),
      ));

  r.register('Center', (c) => Center(child: c.child()));

  r.register('Align', (c) => Align(
        alignment: alignmentFromJson(c.props['alignment']) ?? Alignment.center,
        child: c.child(),
      ));

  r.register('SizedBox', (c) => SizedBox(
        width: c.num_('width'),
        height: c.num_('height'),
        child: c.child(),
      ));

  r.register('Expanded', (c) => Expanded(
        flex: c.int_('flex') ?? 1,
        child: c.childOrEmpty,
      ));

  r.register('Flexible', (c) => Flexible(
        flex: c.int_('flex') ?? 1,
        child: c.childOrEmpty,
      ));

  r.register('Positioned', (c) => Positioned(
        left: c.num_('left'),
        top: c.num_('top'),
        right: c.num_('right'),
        bottom: c.num_('bottom'),
        width: c.num_('width'),
        height: c.num_('height'),
        child: c.childOrEmpty,
      ));

  r.register('ClipRRect', (c) {
    final radius = c.num_('borderRadius');
    return ClipRRect(
      borderRadius:
          radius == null ? BorderRadius.zero : BorderRadius.all(Radius.circular(radius)),
      child: c.propChild('child'),
    );
  });

  r.register('Card', (c) => Card(
        elevation: c.num_('elevation'),
        margin: edgeInsetsFromJson(c.map('margin')),
        color: colorFromJson(c.props['color']),
        child: c.child(),
      ));

  r.register('Icon', (c) => Icon(
        iconFromJson(c.props['icon']),
        size: c.num_('size'),
        color: colorFromJson(c.props['color']),
      ));

  r.register('Image', (c) {
    final source = c.str('source') ?? '';
    final width = c.num_('width');
    final height = c.num_('height');
    final fit = boxFitFromJson(c.props['fit']);
    return source.startsWith('http')
        ? Image.network(source, width: width, height: height, fit: fit)
        : Image.asset(source, width: width, height: height, fit: fit);
  });

  r.register('CircleAvatar', (c) => CircleAvatar(
        radius: c.num_('radius'),
        backgroundColor: colorFromJson(c.props['backgroundColor']),
        child: c.child(),
      ));

  r.register('Divider', (c) => Divider(
        height: c.num_('height'),
        thickness: c.num_('thickness'),
        indent: c.num_('indent'),
        endIndent: c.num_('endIndent'),
        color: colorFromJson(c.props['color']),
      ));

  r.register('Spacer', (c) => const Spacer());

  r.register('Chip', (c) => Chip(
        label: Text(c.str('label') ?? ''),
        backgroundColor: colorFromJson(c.props['backgroundColor']),
      ));

  r.register('ListTile', (c) {
    final title = c.str('title');
    final subtitle = c.str('subtitle');
    return ListTile(
      title: title == null ? null : Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      leading: c.propChild('leading'),
      trailing: c.propChild('trailing'),
      onTap: c.on('event'),
    );
  });

  r.register('ElevatedButton', (c) => ElevatedButton(
        onPressed: c.on('onPressed'),
        style: buttonStyleFromJson(c.map('style')),
        child: c.childOrEmpty,
      ));

  r.register('TextButton', (c) => TextButton(
        onPressed: c.on('onPressed'),
        style: buttonStyleFromJson(c.map('style')),
        child: c.childOrEmpty,
      ));

  // Button：生成器把 ElevatedButton/TextButton/OutlinedButton 统一译为
  // `{type:'Button', props:{kind, label, event}}`，event 是运行时事件句柄
  // （或 null 表示禁用）→ 点击经宿主把句柄 id 回传 JS 侧执行。
  r.register('Button', (c) {
    final style = buttonStyleFromJson(c.map('style'));
    final label = Text(c.str('label') ?? '');
    final onPressed = c.on('event');
    return switch (c.str('kind')) {
      'text' => TextButton(onPressed: onPressed, style: style, child: label),
      'outlined' =>
        OutlinedButton(onPressed: onPressed, style: style, child: label),
      _ => ElevatedButton(onPressed: onPressed, style: style, child: label),
    };
  });

  r.register('InkWell', (c) => InkWell(onTap: c.on('event'), child: c.child()));

  r.register(
      'GestureDetector',
      (c) => GestureDetector(
            onTap: c.on('event'),
            child: c.child(),
          ));

  r.register('Switch', (c) => Switch(
        value: c.bool_('value') ?? false,
        onChanged: c.onValue<bool?>('event'),
      ));

  r.register('Checkbox', (c) => Checkbox(
        value: c.bool_('value') ?? false,
        onChanged: c.onValue<bool?>('event'),
      ));

  r.register('Slider', (c) => Slider(
        value: c.num_('value') ?? 0,
        min: c.num_('min') ?? 0,
        max: c.num_('max') ?? 1,
        onChanged: c.onValue<double>('event'),
      ));

  r.register('Scaffold', (c) {
    final appBar = c.childOfType('AppBar');
    return Scaffold(
      backgroundColor: colorFromJson(c.props['backgroundColor']),
      appBar: appBar is AppBar ? appBar : null,
      body: c.hasChildOfType('AppBar') ? c.child(1) : c.child(0),
    );
  });

  r.register('AppBar', (c) => AppBar(title: c.child()));

  // Component：无 JS 产物的组件节点（无注解的 lib 普通 widget /
  // @UIComponentIgnore）→ 宿主 nativeComponents 原生注入；未注册给可见占位。
  r.register('Component', (c) {
    final name = c.str('component') ?? '';
    final native = c.nativeComponents[name];
    if (native != null) return native(c.map('args') ?? const {});
    return buildMissingJsWidget(name, c.children);
  });
}

/// 迁移中的 JS 组件引用了宿主未注册的类型时，给出可见占位。
Widget buildMissingJsWidget(String type, List<Widget> children) {
  HotPatchLog.log('js_ui: 未注册的宿主 widget 类型 "$type"');
  return Container(
    padding: const EdgeInsets.all(4),
    color: const Color(0x22FF0000),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('<未注册 widget: $type>', style: const TextStyle(fontSize: 11, color: Color(0xFFB00020))),
        ...children,
      ],
    ),
  );
}