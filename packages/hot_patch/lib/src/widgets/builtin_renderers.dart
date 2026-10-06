import 'dart:convert';

import 'package:flutter/material.dart';

import '../json/flutter_from_json.dart';
import '../services/js_runtime_manager.dart';
import 'widget_renderer.dart';
import '../utils/hot_patch_log.dart';

/// ListenableBuilder 局部重建的回调注册表：
/// key = `<instanceKey>::<builderName>`（_lbBuilderN），值 = 重取子树 + setState。
/// JS 模型 notifyListeners → sendMessage('lbNotify', {key, builder}) →
/// [LbNotifyService] 按 key 查表调用。全局唯一、按实例 key 隔离、随 dispose 清理。
final Map<String, void Function()> lbRefreshCallbacks = {};

/// 内置渲染策略：把 codegen 生成的 JSON 节点渲染为常见 Flutter widget。
///
/// 新增内置 widget = 在这里加一个 renderer 类 + register 一行；
/// 自定义 widget = 业务方实现 WidgetRenderer 并通过
/// HotPatchWidget(rendererRegistry: ...) 注入，核心代码零改动。
void registerBuiltinRenderers(WidgetRendererRegistry registry) {
  registry
    ..register(const ColumnRenderer())
    ..register(const RowRenderer())
    ..register(const TextRenderer())
    ..register(const ButtonRenderer())
    ..register(const SizedBoxRenderer())
    ..register(const ChipRenderer())
    ..register(const ListTileRenderer())
    ..register(const ClipRRectRenderer())
    // 布局
    ..register(const CenterRenderer())
    ..register(const PaddingRenderer())
    ..register(const AlignRenderer())
    ..register(const ExpandedRenderer())
    ..register(const FlexibleRenderer())
    ..register(const StackRenderer())
    ..register(const PositionedRenderer())
    ..register(const ContainerRenderer())
    ..register(const DividerRenderer())
    ..register(const CardRenderer())
    ..register(const ScaffoldRenderer())
    ..register(const AppBarRenderer())
    ..register(const ListViewRenderer())
    ..register(const SingleChildScrollViewRenderer())
    ..register(const WrapRenderer())
    // 内容
    ..register(const IconRenderer())
    ..register(const ImageRenderer())
    ..register(const CircleAvatarRenderer())
    // 交互
    ..register(const InkWellRenderer())
    ..register(const GestureDetectorRenderer())
    ..register(const SwitchRenderer())
    ..register(const CheckboxRenderer())
    ..register(const SliderRenderer())
    // 响应式：ListenableBuilder（配合 ChangeNotifier 局部重建）
    ..register(const ListenableBuilderRenderer());
}

/// Column / Row 共用逻辑：方向决定主轴 + 对齐 + children。
abstract class _AxisLayoutRenderer extends WidgetRenderer {
  const _AxisLayoutRenderer();

  /// 主轴方向：'Column' 垂直 / 'Row' 水平。
  Axis get axis;

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    final children = [for (final c in node.children) ctx.render(c)];
    // Flutter 中 Column / Row 的 mainAxisSize 默认都是 max，
    // 未显式翻译时保持与原生一致。
    final size = mainAxisSizeFromJson(node.props['mainAxisSize']) ??
        MainAxisSize.max;
    final main = mainAxisAlignmentFromJson(node.props['mainAxisAlignment']);
    final cross = crossAxisAlignmentFromJson(node.props['crossAxisAlignment']);
    if (axis == Axis.vertical) {
      return Column(
        mainAxisSize: size,
        mainAxisAlignment: main ?? MainAxisAlignment.start,
        crossAxisAlignment: cross ?? CrossAxisAlignment.center,
        children: children,
      );
    }
    return Row(
      mainAxisSize: size,
      mainAxisAlignment: main ?? MainAxisAlignment.start,
      crossAxisAlignment: cross ?? CrossAxisAlignment.center,
      children: children,
    );
  }
}

/// Column：垂直布局容器（单一 type）。
class ColumnRenderer extends _AxisLayoutRenderer {
  const ColumnRenderer();

  @override
  String get type => 'Column';

  @override
  Axis get axis => Axis.vertical;
}

/// Row：水平布局容器（单一 type）。
class RowRenderer extends _AxisLayoutRenderer {
  const RowRenderer();

  @override
  String get type => 'Row';

  @override
  Axis get axis => Axis.horizontal;
}

/// Text：文案 + 样式映射（title/hint/body）。
class TextRenderer extends WidgetRenderer {
  const TextRenderer();

  @override
  String get type => 'Text';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    int? i(Object? v) => int.tryParse('$v');
    final w = Text(
      node.props['data']?.toString() ?? '',
      textAlign: textAlignFromJson(node.props['textAlign']),
      textDirection: textDirectionFromJson(node.props['textDirection']),
      overflow: overflowFromJson(node.props['overflow']),
      softWrap: node.props['softWrap'] == null
          ? null
          : node.props['softWrap'].toString() == 'true',
      maxLines: i(node.props['maxLines']),
      textScaler: textScalerFromJson(node.props['textScaler']),
      semanticsLabel: node.props['semanticsLabel']?.toString(),
      style: textStyleFromJson(
        node.props['style'] is Map
            ? (node.props['style'] as Map).cast<String, dynamic>()
            : null,
      ),
    );
    return w;
  }
}

/// Button：ElevatedButton，点击时把 props.event 上报给 JS 驱动逻辑。
class ButtonRenderer extends WidgetRenderer {
  const ButtonRenderer();

  @override
  String get type => 'Button';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    final event = node.props['event']?.toString() ?? '';
    final style = buttonStyleFromJson(
      node.props['style'] is Map
          ? (node.props['style'] as Map).cast<String, dynamic>()
          : null,
    );
    final label = Text(node.props['label']?.toString() ?? '');
    // event 为空（onPressed: null）→ 禁用态按钮
    void Function()? onPressed =
        event.isEmpty ? null : () => ctx.onEvent(event);
    final w = switch (node.props['kind']?.toString()) {
      'text' => TextButton(onPressed: onPressed, style: style, child: label),
      'outlined' =>
        OutlinedButton(onPressed: onPressed, style: style, child: label),
      _ => ElevatedButton(onPressed: onPressed, style: style, child: label),
    };
    return w;
  }
}


/// SizedBox：布局空隙，无 UI 内容（JS 树里翻译为占位尺寸）。
/// Chip：标签 + 背景色（无交互）。
class ChipRenderer extends WidgetRenderer {
  const ChipRenderer();

  @override
  String get type => 'Chip';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    return Chip(
      label: Text(node.props['label']?.toString() ?? ''),
      backgroundColor: colorFromJson(node.props['backgroundColor']),
    );
  }
}

/// ListTile：列表条目（title/subtitle/leading/trailing/event）。
class ListTileRenderer extends WidgetRenderer {
  const ListTileRenderer();

  @override
  String get type => 'ListTile';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    final event = node.props['event']?.toString() ?? '';
    Widget? sub(Object? v) {
      final rn = RenderNode.of(v);
      return rn == null ? null : ctx.render(rn);
    }

    return ListTile(
      title: Text(node.props['title']?.toString() ?? ''),
      subtitle: node.props['subtitle'] == null
          ? null
          : Text(node.props['subtitle'].toString()),
      leading: sub(node.props['leading']),
      trailing: sub(node.props['trailing']),
      onTap: event.isEmpty ? null : () => ctx.onEvent(event),
    );
  }
}

/// ClipRRect：圆角裁剪（borderRadius + child）。
/// child 由生成器放进 props['child']（单节点 Map），不经过 children 列表。
class ClipRRectRenderer extends WidgetRenderer {
  const ClipRRectRenderer();

  @override
  String get type => 'ClipRRect';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    double? r(Object? v) => v is num ? v.toDouble() : double.tryParse('$v');
    final radius = r(node.props['borderRadius']);
    final childNode = RenderNode.of(node.props['child']);
    final child = childNode == null ? null : ctx.render(childNode);
    return ClipRRect(
      borderRadius: radius == null
          ? BorderRadius.zero
          : BorderRadius.all(Radius.circular(radius)),
      child: child,
    );
  }
}

class SizedBoxRenderer extends WidgetRenderer {
  const SizedBoxRenderer();

  @override
  String get type => 'SizedBox';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    final h = node.props['height'];
    final w = node.props['width'];
    return SizedBox(
      height: h is num ? h.toDouble() : (h == null ? null : double.tryParse('$h')),
      width: w is num ? w.toDouble() : (w == null ? null : double.tryParse('$w')),
      child: node.children.isEmpty ? null : ctx.render(node.children.first),
    );
  }
}

// ===========================================================================
// 布局类
// ===========================================================================

/// Center：单子居中。
class CenterRenderer extends WidgetRenderer {
  const CenterRenderer();

  @override
  String get type => 'Center';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    return Center(child: node.children.isEmpty ? null : ctx.render(node.children.first));
  }
}

/// Padding：padding（EdgeInsets JSON）+ 单子。
class PaddingRenderer extends WidgetRenderer {
  const PaddingRenderer();

  @override
  String get type => 'Padding';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    return Padding(
      padding: edgeInsetsFromJson(
        node.props['padding'] is Map
            ? (node.props['padding'] as Map).cast<String, dynamic>()
            : null,
      ),
      child: node.children.isEmpty ? null : ctx.render(node.children.first),
    );
  }
}

/// Align：alignment + 单子。
class AlignRenderer extends WidgetRenderer {
  const AlignRenderer();

  @override
  String get type => 'Align';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    return Align(
      alignment: alignmentFromJson(node.props['alignment']) ?? Alignment.center,
      child: node.children.isEmpty ? null : ctx.render(node.children.first),
    );
  }
}

/// Expanded / Flexible 共用逻辑：flex + 单子（Row/Column 内）。
abstract class _FlexRenderer extends WidgetRenderer {
  const _FlexRenderer();

  /// Expanded 用 tight 撑满，Flexible 用 loose。
  FlexFit get fit;

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    final child = node.children.isEmpty ? const SizedBox.shrink() : ctx.render(node.children.first);
    final flex = node.props['flex'];
    final flexInt = flex is num ? flex.toInt() : int.tryParse('$flex') ?? 1;
    return fit == FlexFit.tight
        ? Expanded(flex: flexInt, child: child)
        : Flexible(flex: flexInt, child: child);
  }
}

/// Expanded：Row/Column 内撑满剩余空间。
class ExpandedRenderer extends _FlexRenderer {
  const ExpandedRenderer();

  @override
  String get type => 'Expanded';

  @override
  FlexFit get fit => FlexFit.tight;
}

/// Flexible：Row/Column 内可伸缩（不强制撑满）。
class FlexibleRenderer extends _FlexRenderer {
  const FlexibleRenderer();

  @override
  String get type => 'Flexible';

  @override
  FlexFit get fit => FlexFit.loose;
}

/// Stack：children + alignment（children 内允许 Positioned 节点）。
class StackRenderer extends WidgetRenderer {
  const StackRenderer();

  @override
  String get type => 'Stack';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    return Stack(
      alignment: alignmentFromJson(node.props['alignment']) ?? AlignmentDirectional.topStart,
      children: [for (final c in node.children) ctx.render(c)],
    );
  }
}

/// Positioned：Stack 内定位（left/top/right/bottom/width/height）。
class PositionedRenderer extends WidgetRenderer {
  const PositionedRenderer();

  @override
  String get type => 'Positioned';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    double? d(Object? v) => v is num ? v.toDouble() : double.tryParse('$v');
    return Positioned(
      left: d(node.props['left']),
      top: d(node.props['top']),
      right: d(node.props['right']),
      bottom: d(node.props['bottom']),
      width: d(node.props['width']),
      height: d(node.props['height']),
      child: node.children.isEmpty
          ? const SizedBox.shrink()
          : ctx.render(node.children.first),
    );
  }
}

/// Container：width/height/color/padding/margin/alignment/decoration + 单子。
class ContainerRenderer extends WidgetRenderer {
  const ContainerRenderer();

  @override
  String get type => 'Container';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    double? d(Object? v) => v is num ? v.toDouble() : double.tryParse('$v');
    final deco = boxDecorationFromJson(
      node.props['decoration'] is Map
          ? (node.props['decoration'] as Map).cast<String, dynamic>()
          : null,
    );
    final color = colorFromJson(node.props['color']);
    return Container(
      width: d(node.props['width']),
      height: d(node.props['height']),
      // color 与 decoration 同传会断言：decoration 优先（其内可含 color）。
      color: deco == null ? color : null,
      decoration: deco,
      padding: edgeInsetsFromJson(
        node.props['padding'] is Map
            ? (node.props['padding'] as Map).cast<String, dynamic>()
            : null,
      ),
      margin: edgeInsetsFromJson(
        node.props['margin'] is Map
            ? (node.props['margin'] as Map).cast<String, dynamic>()
            : null,
      ),
      alignment: alignmentFromJson(node.props['alignment']),
      child: node.children.isEmpty ? null : ctx.render(node.children.first),
    );
  }
}

/// Divider：height/thickness/color/indent/endIndent。
class DividerRenderer extends WidgetRenderer {
  const DividerRenderer();

  @override
  String get type => 'Divider';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    double? d(Object? v) => v is num ? v.toDouble() : double.tryParse('$v');
    return Divider(
      height: d(node.props['height']),
      thickness: d(node.props['thickness']),
      indent: d(node.props['indent']),
      endIndent: d(node.props['endIndent']),
      color: colorFromJson(node.props['color']),
    );
  }
}

/// Card：child + elevation/margin/color。
class CardRenderer extends WidgetRenderer {
  const CardRenderer();

  @override
  String get type => 'Card';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    final elevation = node.props['elevation'];
    return Card(
      elevation: elevation is num ? elevation.toDouble() : double.tryParse('$elevation'),
      margin: edgeInsetsFromJson(
        node.props['margin'] is Map
            ? (node.props['margin'] as Map).cast<String, dynamic>()
            : null,
      ),
      color: colorFromJson(node.props['color']),
      child: node.children.isEmpty ? null : ctx.render(node.children.first),
    );
  }
}

/// ListView：children 列表（shrinkWrap 适配内嵌场景）。
class ListViewRenderer extends WidgetRenderer {
  const ListViewRenderer();

  @override
  String get type => 'ListView';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    return ListView(
      shrinkWrap: true,
      children: [for (final c in node.children) ctx.render(c)],
    );
  }
}

/// Scaffold：children = [AppBar, body]（生成器约定）。
class ScaffoldRenderer extends WidgetRenderer {
  const ScaffoldRenderer();

  @override
  String get type => 'Scaffold';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    PreferredSizeWidget? appBar;
    if (node.children.isNotEmpty && node.children.first.type == 'AppBar') {
      appBar = ctx.render(node.children.first) as PreferredSizeWidget?;
    }
    return Scaffold(
      backgroundColor: colorFromJson(node.props['backgroundColor']),
      appBar: appBar,
      body: node.children.length > 1 ? ctx.render(node.children[1]) : null,
    );
  }
}

/// AppBar：children[0] = title。
class AppBarRenderer extends WidgetRenderer {
  const AppBarRenderer();

  @override
  String get type => 'AppBar';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    return AppBar(
      title: node.children.isEmpty ? null : ctx.render(node.children.first),
    );
  }
}

/// SingleChildScrollView：child + scrollDirection。
class SingleChildScrollViewRenderer extends WidgetRenderer {
  const SingleChildScrollViewRenderer();

  @override
  String get type => 'SingleChildScrollView';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    return SingleChildScrollView(
      scrollDirection: axisFromJson(node.props['scrollDirection']) ?? Axis.vertical,
      child: node.children.isEmpty ? null : ctx.render(node.children.first),
    );
  }
}

/// Wrap：children + spacing/runSpacing。
class WrapRenderer extends WidgetRenderer {
  const WrapRenderer();

  @override
  String get type => 'Wrap';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    double? d(Object? v) => v is num ? v.toDouble() : double.tryParse('$v');
    return Wrap(
      spacing: d(node.props['spacing']) ?? 0,
      runSpacing: d(node.props['runSpacing']) ?? 0,
      children: [for (final c in node.children) ctx.render(c)],
    );
  }
}

// ===========================================================================
// 内容类
// ===========================================================================

/// Icon：icon 名 + size/color。
class IconRenderer extends WidgetRenderer {
  const IconRenderer();

  @override
  String get type => 'Icon';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    final size = node.props['size'];
    return Icon(
      iconFromJson(node.props['icon']),
      size: size is num ? size.toDouble() : double.tryParse('$size'),
      color: colorFromJson(node.props['color']),
    );
  }
}

/// Image：asset/network 源 + width/height/fit。
class ImageRenderer extends WidgetRenderer {
  const ImageRenderer();

  @override
  String get type => 'Image';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    final source = node.props['source']?.toString() ?? '';
    final width = node.props['width'];
    final height = node.props['height'];
    double? d(Object? v) => v is num ? v.toDouble() : double.tryParse('$v');
    final fit = boxFitFromJson(node.props['fit']);
    final image = source.startsWith('http')
        ? Image.network(source, width: d(width), height: d(height), fit: fit)
        : Image.asset(source, width: d(width), height: d(height), fit: fit);
    return image;
  }
}

/// CircleAvatar：radius/backgroundColor + 可选 child。
class CircleAvatarRenderer extends WidgetRenderer {
  const CircleAvatarRenderer();

  @override
  String get type => 'CircleAvatar';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    final radius = node.props['radius'];
    return CircleAvatar(
      radius: radius is num ? radius.toDouble() : double.tryParse('$radius'),
      backgroundColor: colorFromJson(node.props['backgroundColor']),
      child: node.children.isEmpty ? null : ctx.render(node.children.first),
    );
  }
}

// ===========================================================================
// 交互类
// ===========================================================================

/// InkWell：onTap → 事件 + 单子。
class InkWellRenderer extends WidgetRenderer {
  const InkWellRenderer();

  @override
  String get type => 'InkWell';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    final event = node.props['event']?.toString() ?? '';
    return InkWell(
      onTap: () => ctx.onEvent(event),
      child: node.children.isEmpty ? null : ctx.render(node.children.first),
    );
  }
}

/// GestureDetector：onTap → 事件 + 单子。
class GestureDetectorRenderer extends WidgetRenderer {
  const GestureDetectorRenderer();

  @override
  String get type => 'GestureDetector';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    final event = node.props['event']?.toString() ?? '';
    return GestureDetector(
      onTap: () => ctx.onEvent(event),
      child: node.children.isEmpty ? null : ctx.render(node.children.first),
    );
  }
}

/// Switch：value + onChanged（带值事件 → JS 方法带参调用）。
class SwitchRenderer extends WidgetRenderer {
  const SwitchRenderer();

  @override
  String get type => 'Switch';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    final event = node.props['event']?.toString() ?? '';
    return Switch(
      value: node.props['value'] == true,
      onChanged: (v) {
        final f = ctx.onEventValue;
        if (f != null) {
          f(event, v);
        } else {
          ctx.onEvent(event);
        }
      },
    );
  }
}

/// Checkbox：value + onChanged（带值事件 → JS 方法带参调用）。
class CheckboxRenderer extends WidgetRenderer {
  const CheckboxRenderer();

  @override
  String get type => 'Checkbox';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    final event = node.props['event']?.toString() ?? '';
    return Checkbox(
      value: node.props['value'] == true,
      onChanged: (v) {
        final f = ctx.onEventValue;
        if (f != null) {
          f(event, v);
        } else {
          ctx.onEvent(event);
        }
      },
    );
  }
}

/// Slider：value + min/max + onChanged（带值事件 → JS 方法带参调用）。
class SliderRenderer extends WidgetRenderer {
  const SliderRenderer();

  @override
  String get type => 'Slider';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    final event = node.props['event']?.toString() ?? '';
    final value = node.props['value'];
    final min = node.props['min'];
    final max = node.props['max'];
    double? d(Object? v) => v is num ? v.toDouble() : double.tryParse('$v');
    return Slider(
      value: d(value) ?? 0,
      min: d(min) ?? 0,
      max: d(max) ?? 1,
      onChanged: (v) {
        final f = ctx.onEventValue;
        if (f != null) {
          f(event, v);
        } else {
          ctx.onEvent(event);
        }
      },
    );
  }
}

// ===========================================================================
// 响应式：ListenableBuilder（ChangeNotifier 局部重建）
// ===========================================================================

/// ListenableBuilder 渲染：节点 `{type:"ListenableBuilder", props:{listenable,
/// builder}}`。child 子树不在树里（生成器抽到实例方法 `_lbBuilderN`），
/// 运行时初始化时重取一次；JS 模型 notifyListeners → 'lbNotify' 服务 →
/// [_JsListenableBuilderState._refresh] 重取最新子树并 setState（仅此节点，
/// 不全量 rebuild）。
class ListenableBuilderRenderer extends WidgetRenderer {
  const ListenableBuilderRenderer();

  @override
  String get type => 'ListenableBuilder';

  @override
  Widget render(RenderNode node, WidgetRenderContext ctx) {
    final listenable = node.props['listenable']?.toString() ?? '';
    final builderName = node.props['builder']?.toString() ?? '';
    return _JsListenableBuilder(
      ctx: ctx,
      listenable: listenable,
      builderName: builderName,
    );
  }
}

class _JsListenableBuilder extends StatefulWidget {
  const _JsListenableBuilder({
    required this.ctx,
    required this.listenable,
    required this.builderName,
  });

  final WidgetRenderContext ctx;
  final String listenable;
  final String builderName;

  @override
  State<_JsListenableBuilder> createState() => _JsListenableBuilderState();
}

class _JsListenableBuilderState extends State<_JsListenableBuilder> {
  late final String _key;
  late final String _cbKey;
  late RenderNode _node;

  JsRuntimeManager get _manager =>
      widget.ctx.sharedManager ?? JsRuntimeManager.instance;

  @override
  void initState() {
    super.initState();
    _key = widget.ctx.instanceKey ?? '';
    _cbKey = '$_key::${widget.builderName}';
    _node = _fetch();
    // 挂 JS 监听：模型 notify 时 sendMessage('lbNotify') → 服务查表调 _refresh。
    lbRefreshCallbacks[_cbKey] = _refresh;
    _manager.evaluate(
      '(function(){ var m = __instances["$_key"].${widget.listenable}; '
      'if (m && typeof m.addListener === "function") { '
      ' m.addListener(function(){ '
      '  sendMessage("lbNotify", JSON.stringify({ key: "$_key", '
      '    builder: "${widget.builderName}" })); }); } })()',
    );
  }

  @override
  void dispose() {
    lbRefreshCallbacks.remove(_cbKey);
    super.dispose();
  }

  /// 重取 builder 子树（JS 实例 `_lbBuilderN()`，build() 内求值 this._model.n）。
  RenderNode _fetch() {
    try {
      final r = _manager.evaluate(
        'JSON.stringify(__instances["$_key"].${widget.builderName}())',
      );
      final node = RenderNode.of(jsonDecode(r.stringResult));
      return node ?? RenderNode.of(const {'type': 'SizedBox'})!;
    } catch (e) {
      HotPatchLog.log('_lbBuilder fetch error: $e');
      return RenderNode.of(const {'type': 'SizedBox'})!;
    }
  }

  void _refresh() {
    if (!mounted) return;
    setState(() => _node = _fetch());
  }

  @override
  Widget build(BuildContext context) {
    return widget.ctx.render(_node);
  }
}
