// ===== 基础组件：宿主注册 =====
//
// Flutter 基础视觉组件的宿主侧映射（`type` → 真实 Flutter widget），属于框架
// 地基，不属于任何可插拔能力：Text / Column / Row / Stack / Container / 按钮 /
// 输入控件 / Scaffold / AppBar / 导航栏 / 指示器等。
//
// 另有一批「单个 child + 少量标量参数」的常用包装组件（Tooltip / IgnorePointer /
// AbsorbPointer / RepaintBoundary / Baseline / FittedBox / RotatedBox /
// IntrinsicWidth / IntrinsicHeight / LimitedBox / InteractiveViewer）：宿主侧只做
// 参数映射，没有新机制。参数名与 Flutter 构造一致，缺省值取 Flutter 自身默认。
//
// InteractiveViewer 的三个交互回调把宿主侧的 `ScaleStart/Update/EndDetails`
// 折算成 JSON（`{scale, focalPoint, localFocalPoint}`），用户回调留在 JS；
// 它自带的 `transformationController` / `interactionEndFrictionCoefficient` 等
// 细粒度参数不参与翻译（保持 Flutter 默认）。
import 'dart:ui' show ImageFilter;

import 'package:flutter/gestures.dart' show kDefaultMouseScrollToScaleFactor;
import 'package:flutter/material.dart';

import '../../../utils/dynamic_flutter_assets.dart';
import '../../js_widget_registry.dart';
import '../../ui_fallback.dart';
import '../core/from_json/dart_values_from_json.dart';
import '../core/from_json/layout_from_json.dart';
import '../core/from_json/painting_from_json.dart';
import '../core/from_json/widget_enum_from_json.dart';
import 'button_from_json.dart';
import 'icon_from_json.dart';
import 'text_from_json.dart';

/// `MaterialType` 枚举名 → 枚举值（缺省 null = Flutter 默认 `canvas`）。
MaterialType? _materialTypeFromJson(Object? v) => switch ('$v') {
  'canvas' => MaterialType.canvas,
  'card' => MaterialType.card,
  'circle' => MaterialType.circle,
  'button' => MaterialType.button,
  'transparency' => MaterialType.transparency,
  _ => null,
};

/// 源字符串 → 图片 provider：`FadeInImage.assetNetwork` 的 placeholder 永远是
/// 资源路径（[forceAsset]），其余按 `http` 前缀判网络 / 资源（与 `Image` 一致）。
///
/// 资源图统一走 [JsAssets.bundle]：补丁包内同名图片优先，缺失回退
/// Flutter assets。
ImageProvider _imageProvider(String source, {bool forceAsset = false}) =>
    (!forceAsset && source.startsWith('http'))
    ? NetworkImage(source)
    : AssetImage(source, bundle: JsAssets.bundle);

/// 注册 Flutter 基础视觉组件的宿主侧映射。
///
/// 只覆盖「JS 侧组件用到的、Flutter 侧真实存在的」类型；未注册的类型渲染为
/// 错误占位（便于定位缺失的翻译），而不是静默空白。
///
/// 除基础视觉组件外的 widget 由各自的 JsUiLibrary 子类注册
/// （见 capabilities/<能力>/<能力>_library.dart），本文件不 import 它们。
void registerBaseWidgets(JsWidgetRegistry r) {
  // Text：`data` 是首个位置形参名（`Text('你好')`）。`Text.rich` 是命名构造，
  // 文案在 `textSpan` 里（宿主按 `factory` 还原原生构造，否则会渲染成空文本）。
  r.register('Text', (c) {
    final style = c.textStyle('style');
    final textAlign = c.textAlign('textAlign');
    final overflow = c.overflow('overflow');
    final maxLines = c.int_('maxLines');
    final softWrap = c.bool_('softWrap');
    final textDirection = c.textDirection('textDirection');
    final textScaler = c.textScaler('textScaler');
    final semanticsLabel = c.str('semanticsLabel');
    if (c.str('factory') == 'rich') {
      return Text.rich(
        c.textSpan('textSpan') ?? const TextSpan(),
        key: c.key,
        style: style,
        textAlign: textAlign,
        overflow: overflow,
        maxLines: maxLines,
        softWrap: softWrap,
        textDirection: textDirection,
        textScaler: textScaler,
        semanticsLabel: semanticsLabel,
      );
    }
    return Text(
      c.str('data') ?? '',
      key: c.key,
      style: style,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      softWrap: softWrap,
      textDirection: textDirection,
      textScaler: textScaler,
      semanticsLabel: semanticsLabel,
    );
  });

  r.register(
    'RichText',
    (c) => RichText(
      key: c.key,
      text: c.textSpan('text') ?? const TextSpan(),
      textAlign: c.textAlign('textAlign') ?? TextAlign.start,
      textDirection: c.textDirection('textDirection'),
      softWrap: c.bool_('softWrap') ?? true,
      overflow: c.overflow('overflow') ?? TextOverflow.clip,
      maxLines: c.int_('maxLines'),
      textScaler:
          c.textScaler('textScaler') ?? TextScaler.noScaling,
      selectionColor: c.color('selectionColor'),
    ),
  );

  r.register(
    'Column',
    (c) => Column(
      key: c.key,
      mainAxisAlignment:
          c.mainAxisAlignment('mainAxisAlignment') ??
          MainAxisAlignment.start,
      crossAxisAlignment:
          c.crossAxisAlignment('crossAxisAlignment') ??
          CrossAxisAlignment.center,
      mainAxisSize:
          c.mainAxisSize('mainAxisSize') ?? MainAxisSize.max,
      textBaseline: c.textBaseline('textBaseline'),
      children: ((c.children['children'] as List<Widget>?) ?? const []),
    ),
  );

  r.register(
    'Row',
    (c) => Row(
      key: c.key,
      mainAxisAlignment:
          c.mainAxisAlignment('mainAxisAlignment') ??
          MainAxisAlignment.start,
      crossAxisAlignment:
          c.crossAxisAlignment('crossAxisAlignment') ??
          CrossAxisAlignment.center,
      mainAxisSize:
          c.mainAxisSize('mainAxisSize') ?? MainAxisSize.max,
      textBaseline: c.textBaseline('textBaseline'),
      children: ((c.children['children'] as List<Widget>?) ?? const []),
    ),
  );

  r.register(
    'Stack',
    (c) => Stack(
      key: c.key,
      alignment:
          c.alignment('alignment') ??
          AlignmentDirectional.topStart,
      fit: c.stackFit('fit') ?? StackFit.loose,
      clipBehavior:
          c.clipBehavior('clipBehavior') ?? Clip.hardEdge,
      children: ((c.children['children'] as List<Widget>?) ?? const []),
    ),
  );

  r.register(
    'IndexedStack',
    (c) => IndexedStack(
      key: c.key,
      // index 是状态字段（`this._index`），切换后只重下发 props、子结点原位复用，
      // 因此各 tab 页的状态（滚动位置、输入内容）都能保留。
      index: c.int_('index') ?? 0,
      alignment:
          c.alignment('alignment') ??
          AlignmentDirectional.topStart,
      children: ((c.children['children'] as List<Widget>?) ?? const []),
    ),
  );

  r.register(
    'Wrap',
    (c) => Wrap(
      key: c.key,
      direction: c.axis('direction') ?? Axis.horizontal,
      spacing: c.double_('spacing') ?? 0,
      runSpacing: c.double_('runSpacing') ?? 0,
      alignment:
          c.wrapAlignment('alignment') ?? WrapAlignment.start,
      runAlignment:
          c.wrapAlignment('runAlignment') ?? WrapAlignment.start,
      crossAxisAlignment:
          c.wrapCrossAlignment('crossAxisAlignment') ??
          WrapCrossAlignment.start,
      children: ((c.children['children'] as List<Widget>?) ?? const []),
    ),
  );

  r.register('Container', (c) {
    final deco = c.boxDecoration('decoration');
    // decoration 为空时 clipBehavior 必须为 Clip.none（Flutter 断言）。
    final clip = deco == null
        ? Clip.none
        : (c.clipBehavior('clipBehavior') ?? Clip.none);
    return Container(
      key: c.key,
      width: c.double_('width'),
      height: c.double_('height'),
      // color 与 decoration 同传会断言：decoration 优先（其内可含 color）。
      color: deco == null ? c.color('color') : null,
      decoration: deco,
      // padding / margin 在 Container 里是可选参数（null = 不加内边距），
      // 用 nullable 版本、缺省交给 Flutter 默认，不塞 EdgeInsets.zero。
      padding: c.edgeInsets('padding'),
      margin: c.edgeInsets('margin'),
      alignment: c.alignment('alignment'),
      constraints: c.boxConstraints('constraints'),
      clipBehavior: clip,
      child: (c.children['child'] as Widget?),
    );
  });

  r.register(
    'Padding',
    (c) => Padding(
      key: c.key,
      padding: c.edgeInsets('padding') ?? EdgeInsets.zero,
      child: (c.children['child'] as Widget?),
    ),
  );

  r.register(
    'Center',
    (c) => Center(key: c.key, child: (c.children['child'] as Widget?)),
  );

  r.register(
    'Align',
    (c) => Align(
      key: c.key,
      alignment: c.alignment('alignment') ?? Alignment.center,
      child: (c.children['child'] as Widget?),
    ),
  );

  // `SizedBox.shrink` / `.expand` / `.square` / `.fromSize`：`factory` 由 flutter.js
  // 的静态方法写下，这里还原成对应的原生命名构造（普通构造 `SizedBox(w,h)` 无
  // factory，走默认分支）。
  r.register('SizedBox', (c) {
    final child = c.children['child'] as Widget?;
    switch (c.str('factory')) {
      case 'shrink':
        return SizedBox.shrink(key: c.key, child: child);
      case 'expand':
        return SizedBox.expand(key: c.key, child: child);
      case 'square':
        return SizedBox.square(
          key: c.key,
          dimension: c.double_('dimension'),
          child: child,
        );
      case 'fromSize':
        final size = c.map('size') ?? const <String, dynamic>{};
        final w = size['width'];
        final h = size['height'];
        return SizedBox(
          key: c.key,
          width: w is num ? w.toDouble() : null,
          height: h is num ? h.toDouble() : null,
          child: child,
        );
      default:
        return SizedBox(
          key: c.key,
          width: c.double_('width'),
          height: c.double_('height'),
          child: child,
        );
    }
  });

  r.register(
    'Expanded',
    (c) => Expanded(
      key: c.key,
      flex: c.int_('flex') ?? 1,
      child: ((c.children['child'] as Widget?) ?? const SizedBox.shrink()),
    ),
  );

  r.register(
    'Flexible',
    (c) => Flexible(
      key: c.key,
      flex: c.int_('flex') ?? 1,
      child: ((c.children['child'] as Widget?) ?? const SizedBox.shrink()),
    ),
  );

  // Positioned 的命名构造由 `factory` 还原原生命名构造（与 Dart 一比一）：
  // `.fill` 四边缺省 0；`.directional` 用 start/end + textDirection。
  // `.fromRect` / `.fromRelativeRect` 需要 Rect / RelativeRect 值对象，JS 侧
  // 尚无对应值类，暂按普通构造渲染。
  r.register('Positioned', (c) {
    final child = (c.children['child'] as Widget?) ?? const SizedBox.shrink();
    switch (c.str('factory')) {
      case 'fill':
        return Positioned.fill(
          key: c.key,
          left: c.double_('left') ?? 0,
          top: c.double_('top') ?? 0,
          right: c.double_('right') ?? 0,
          bottom: c.double_('bottom') ?? 0,
          child: child,
        );
      case 'directional':
        return Positioned.directional(
          key: c.key,
          textDirection:
              c.textDirection('textDirection') ??
              TextDirection.ltr,
          start: c.double_('start'),
          top: c.double_('top'),
          end: c.double_('end'),
          bottom: c.double_('bottom'),
          width: c.double_('width'),
          height: c.double_('height'),
          child: child,
        );
      default:
        return Positioned(
          key: c.key,
          left: c.double_('left'),
          top: c.double_('top'),
          right: c.double_('right'),
          bottom: c.double_('bottom'),
          width: c.double_('width'),
          height: c.double_('height'),
          child: child,
        );
    }
  });

  r.register('ClipRRect', (c) {
    // JS 侧 `BorderRadius` 的 toJSON 是 `{radius}` / 四角数字；旧补丁可能直接
    // 下发单个数字。此前只读数字，`BorderRadius.circular(n)` 被当成缺省 0，
    // 导致圆角整体丢失（banner 等圆角容器与原生不一致）。
    final raw = c.props['borderRadius'];
    final radius = raw is Map
        ? borderRadiusFromJson(raw.cast<String, dynamic>())
        : (raw is num
            ? BorderRadius.all(Radius.circular(raw.toDouble()))
            : null);
    return ClipRRect(
      key: c.key,
      borderRadius: radius ?? BorderRadius.zero,
      clipBehavior:
          c.clipBehavior('clipBehavior') ?? Clip.antiAlias,
      child: (c.children['child'] as Widget?),
    );
  });

  r.register(
    'ClipOval',
    (c) => ClipOval(
      key: c.key,
      clipBehavior:
          c.clipBehavior('clipBehavior') ?? Clip.antiAlias,
      child: (c.children['child'] as Widget?),
    ),
  );

  // ColorFiltered：`colorFilter` 值走 colorFilterFromJson（mode / matrix /
  // gamma）；读不出时用「无效果」滤镜，保证子树仍按原样渲染。
  r.register(
    'ColorFiltered',
    (c) => ColorFiltered(
      key: c.key,
      colorFilter:
          c.colorFilter('colorFilter') ??
          const ColorFilter.mode(Color(0x00000000), BlendMode.dst),
      child: (c.children['child'] as Widget?),
    ),
  );

  // `ImageFiltered`：按 imageFilter 值对象模糊/膨胀/腐蚀/矩阵/组合。
  // 滤镜缺失（翻译失败）时用零 sigma 模糊兜底——零 sigma 等价于不变形。
  r.register('ImageFiltered', (c) {
    return ImageFiltered(
      key: c.key,
      imageFilter:
          c.imageFilter('imageFilter') ??
          ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0),
      enabled: c.bool_('enabled') ?? true,
      child: (c.children['child'] as Widget?),
    );
  });

  // `Material`：除颜色/阴影外，`borderRadius` 是圆角的唯一来源（不写就是直角），
  // 必须映射；`shape`（ShapeBorder 值对象）跨语言未支持，写 `borderRadius`
  // 即等价于默认 `MaterialType.canvas` 下的圆角。
  r.register(
    'Material',
    (c) => Material(
      key: c.key,
      type: _materialTypeFromJson(c.props['type']) ?? MaterialType.canvas,
      color: c.color('color'),
      elevation: c.double_('elevation') ?? 0,
      shadowColor: c.color('shadowColor'),
      surfaceTintColor: c.color('surfaceTintColor'),
      borderRadius: c.borderRadius('borderRadius'),
      borderOnForeground: c.bool_('borderOnForeground') ?? true,
      clipBehavior: c.clipBehavior('clipBehavior') ?? Clip.none,
      child: (c.children['child'] as Widget?),
    ),
  );

  // Transform 的命名构造按 `factory` 逐一还原原生构造（与 Dart 一比一）：
  // `.translate`（offset = {dx, dy}）/ `.rotate`（angle）/ `.scale`（scale /
  // scaleX / scaleY）/ `.flip`（flipX / flipY）。普通构造 `Transform(transform:)`
  // 需要 Matrix4 值对象，JS 侧尚无对应值类，暂按 translate 兜底。
  r.register('Transform', (c) {
    final child = (c.children['child'] as Widget?);
    final origin = c.offset('origin');
    final alignment = c.alignment('alignment');
    switch (c.str('factory')) {
      case 'rotate':
        return Transform.rotate(
          key: c.key,
          angle: c.double_('angle') ?? 0,
          origin: origin,
          alignment: alignment,
          child: child,
        );
      case 'scale':
        return Transform.scale(
          key: c.key,
          scale: c.double_('scale'),
          scaleX: c.double_('scaleX'),
          scaleY: c.double_('scaleY'),
          origin: origin,
          alignment: alignment,
          child: child,
        );
      case 'flip':
        return Transform.flip(
          key: c.key,
          flipX: c.bool_('flipX') ?? false,
          flipY: c.bool_('flipY') ?? false,
          origin: origin,
          child: child,
        );
      default:
        final offset = c.map('offset') ?? const <String, dynamic>{};
        final dx = (offset['dx'] as num?)?.toDouble() ?? 0;
        final dy = (offset['dy'] as num?)?.toDouble() ?? 0;
        return Transform.translate(
          key: c.key,
          offset: Offset(dx, dy),
          child: child,
        );
    }
  });

  // Card 的命名构造按 `factory` 还原：`.filled`（surfaceContainerHighest 填充）/
  // `.outlined`（描边无抬升）；普通构造保持原参数（margin 缺省必须走主题默认）。
  r.register('Card', (c) {
    final elevation = c.double_('elevation');
    final margin = c.edgeInsets('margin');
    final color = c.color('color');
    final shape = c.shape('shape');
    final clipBehavior = c.clipBehavior('clipBehavior');
    final shadowColor = c.color('shadowColor');
    final child = (c.children['child'] as Widget?);
    switch (c.str('factory')) {
      case 'filled':
        return Card.filled(
          key: c.key,
          elevation: elevation,
          margin: margin,
          color: color,
          shape: shape,
          clipBehavior: clipBehavior,
          shadowColor: shadowColor,
          child: child,
        );
      case 'outlined':
        return Card.outlined(
          key: c.key,
          elevation: elevation,
          margin: margin,
          color: color,
          shape: shape,
          clipBehavior: clipBehavior,
          shadowColor: shadowColor,
          child: child,
        );
      default:
        return Card(
          key: c.key,
          elevation: elevation,
          // 缺省必须是 null（走 Card 主题默认 EdgeInsets.all(4)）——`edgeInsetsFromJson`
          // 已统一返回可空值，null 保留主题默认，不会把 item 之间的默认间隙抹平。
          margin: margin,
          color: color,
          shape: shape,
          clipBehavior: clipBehavior,
          shadowColor: shadowColor,
          child: child,
        );
    }
  });

  r.register('Icon', (c) {
    // `icon` 是 Flutter `Icon` 的首个位置形参名（`Icon(Icons.star)`）：
    // JS 侧已是 `IconData` 对象，跨桥按码点还原（见 icon_from_json.dart）。
    final icon = c.iconData('icon');
    if (icon == null) return uiFallback('Icon.icon 无法还原为 IconData');
    return Icon(
      icon,
      key: c.key,
      size: c.double_('size'),
      color: c.color('color'),
    );
  });

  // `ImageIcon(AssetImage('a.jpg'))`：把**图片**当图标画，尺寸 / 颜色受
  // IconTheme 影响。与 Image / FadeInImage 同一套 provider 归一化：翻译层把
  // `AssetImage` / `NetworkImage` 折成路径/网址字符串，宿主按前缀还原 provider。
  r.register('ImageIcon', (c) {
    final source = c.str('image') ?? '';
    return ImageIcon(
      source.isEmpty ? null : _imageProvider(source),
      key: c.key,
      size: c.double_('size'),
      color: c.color('color'),
      semanticLabel: c.str('semanticLabel'),
    );
  });

  // `Image.network('url')` / `Image.asset('a.png')`：工厂名（`props.factory`，
  // 由 flutter.js 的静态方法写下）决定构造哪个原生工厂，位置实参名随之不同
  // （`Image.network` → `src`、`Image.asset` → `name`、`Image(...)` → `image`）。
  r.register('Image', (c) {
    final factory = c.str('factory');
    final source = c.str('src') ?? c.str('name') ?? c.str('image') ?? '';
    final width = c.double_('width');
    final height = c.double_('height');
    final fit = c.boxFit('fit');
    final color = c.color('color');
    final blend = c.blendMode('colorBlendMode');
    final align = c.alignment('alignment') ?? Alignment.center;
    final repeat =
        c.imageRepeat('repeat') ?? ImageRepeat.noRepeat;
    // 工厂名优先；缺失（未登记构造 / 普通构造）时退回按网址前缀判断。
    final isNetwork =
        factory == 'network' || (factory == null && source.startsWith('http'));
    return isNetwork
        ? Image.network(
            source,
            key: c.key,
            width: width,
            height: height,
            fit: fit,
            color: color,
            colorBlendMode: blend,
            alignment: align,
            repeat: repeat,
          )
        : Image.asset(
            source,
            key: c.key,
            bundle: JsAssets.bundle,
            width: width,
            height: height,
            fit: fit,
            color: color,
            colorBlendMode: blend,
            alignment: align,
            repeat: repeat,
          );
  });

  // `FadeInImage.assetNetwork(placeholder: 'a.jpg', image: 'https://…')`：
  // placeholder 是**资源路径**、image 是网址（`factory: 'assetNetwork'`）；
  // 普通构造 `FadeInImage(placeholder: AssetImage(…), image: NetworkImage(…))`
  // 两者都是 provider，翻译层已把 provider 归一化成路径/网址字符串，这里按
  // 前缀还原成原生 provider。
  r.register('FadeInImage', (c) {
    final assetNetwork = c.str('factory') == 'assetNetwork';
    return FadeInImage(
      key: c.key,
      placeholder: _imageProvider(
        c.str('placeholder') ?? '',
        forceAsset: assetNetwork,
      ),
      image: _imageProvider(c.str('image') ?? ''),
      fit: c.boxFit('fit'),
      placeholderFit: c.boxFit('placeholderFit'),
      fadeInDuration:
          c.duration('fadeInDuration') ??
          const Duration(milliseconds: 300),
      fadeOutDuration:
          c.duration('fadeOutDuration') ??
          const Duration(milliseconds: 300),
      width: c.double_('width'),
      height: c.double_('height'),
      alignment: c.alignment('alignment') ?? Alignment.center,
      repeat: c.imageRepeat('repeat') ?? ImageRepeat.noRepeat,
    );
  });

  // `Hero`：跨路由共享元素动画。tag 两端按**同值字符串**配对（Dart 的 tag 是
  // Object，JS 只能发字符串/数字，字符串是唯一自然可比的形态）；子结点是
  // 飞行时的 shuttle 本体，宿主直接用。`flightShuttleBuilder` /
  // `placeholderBuilder` / `createRectTween` 是返回 widget / tween 的闭包，
  // 跨语言无法执行 → 不映射（走 Flutter 默认实现，与未声明时行为一致）。
  r.register('Hero', (c) {
    final tag = c.props['tag'];
    return Hero(
      key: c.key,
      tag: tag ?? '',
      transitionOnUserGestures: c.bool_('transitionOnUserGestures') ?? false,
      child: (c.children['child'] as Widget?) ?? const SizedBox.shrink(),
    );
  });

  r.register('CircleAvatar', (c) {
    final bgImage = c.str('backgroundImage');
    return CircleAvatar(
      key: c.key,
      radius: c.double_('radius'),
      minRadius: c.double_('minRadius'),
      maxRadius: c.double_('maxRadius'),
      backgroundColor: c.color('backgroundColor'),
      foregroundColor: c.color('foregroundColor'),
      backgroundImage: bgImage == null ? null : _imageProvider(bgImage),
      child: (c.children['child'] as Widget?),
    );
  });

  // `PreferredSize(preferredSize: Size(0, 64), child: …)`：把**任意子树**声明成
  // `PreferredSizeWidget`（Scaffold.appBar / bottomNavigationBar / SliverAppBar 的
  // flexibleSpace 等位置要求这个类型）。preferredSize 只取 height/width 两个字段，
  // `Size.fromHeight(h)` 的 width 是 +∞（JSON 里被折叠成 null），按 ∞ 还原。
  r.register('PreferredSize', (c) {
    final raw = c.map('preferredSize') ?? const <String, dynamic>{};
    final w = raw['width'] is num
        ? (raw['width'] as num).toDouble()
        : double.infinity;
    final h = raw['height'] is num
        ? (raw['height'] as num).toDouble()
        : kToolbarHeight;
    return _JsPreferredSize(
      key: c.key,
      preferredSize: Size(w, h),
      child: c.children['child'] as Widget?,
    );
  });

  r.register(
    'Divider',
    (c) => Divider(
      key: c.key,
      height: c.double_('height'),
      thickness: c.double_('thickness'),
      indent: c.double_('indent'),
      endIndent: c.double_('endIndent'),
      color: c.color('color'),
    ),
  );

  r.register('Spacer', (c) => Spacer(key: c.key, flex: c.int_('flex') ?? 1));

  // label 现在是结点（props['label']），运行时用 propChild 取。
  r.register(
    'Chip',
    (c) => Chip(
      key: c.key,
      label: (c.children['label'] as Widget?) ?? const SizedBox.shrink(),
      labelStyle: c.textStyle('labelStyle'),
      avatar: (c.children['avatar'] as Widget?),
      deleteIcon: (c.children['deleteIcon'] as Widget?),
      onDeleted: c.on('onDeleted'),
      backgroundColor: c.color('backgroundColor'),
      // padding 缺省必须为 null：否则 EdgeInsets.zero 会覆盖 Chip 默认
      // EdgeInsets.all(8.0)，JS 侧每个 chip 窄 16px（8 个 = 128px），
      // 与原生渲染/滚动范围不一致。
      padding: c.edgeInsets('padding'),
      side: c.borderSide('side'),
      shape: c.shape('shape'),
      elevation: c.double_('elevation'),
    ),
  );

  // title / subtitle / leading / trailing 都是结点（props 里的 element prop）。
  r.register('ListTile', (c) {
    return ListTile(
      key: c.key,
      title: (c.children['title'] as Widget?),
      subtitle: (c.children['subtitle'] as Widget?),
      leading: (c.children['leading'] as Widget?),
      trailing: (c.children['trailing'] as Widget?),
      onTap: c.on('onTap'),
      onLongPress: c.on('onLongPress'),
      tileColor: c.color('tileColor'),
      iconColor: c.color('iconColor'),
      textColor: c.color('textColor'),
      // contentPadding 缺省必须为 null：否则 EdgeInsets.zero 会覆盖主题
      // 默认（水平 16），JS 侧 ListTile 内容贴边。
      contentPadding: c.edgeInsets('contentPadding'),
      dense: c.bool_('dense'),
      shape: c.shape('shape'),
    );
  });

  // 四种按钮各自独立注册：type 就是构造名原样，事件键 `onPressed`，文案在
  // children 里（普通构造 `child`、`.icon` 是 `icon` + `label` 两个 slot）。
  // `onPressed` 缺失 = 禁用。style 值可能是 JSON map（`ButtonStyle(...)`），
  // 也可能是元素结点（`XxxButton.styleFrom(...)` 被当成构造）→ map 两种情况都取。
  r.register('ElevatedButton', (c) {
    final onPressed = c.on('onPressed');
    final style = c.buttonStyle('style');
    if (c.str('factory') == 'icon') {
      return ElevatedButton.icon(
        key: c.key,
        onPressed: onPressed,
        style: style,
        icon: (c.children['icon'] as Widget?) ?? const SizedBox.shrink(),
        label: (c.children['label'] as Widget?) ?? const SizedBox.shrink(),
      );
    }
    return ElevatedButton(
      key: c.key,
      onPressed: onPressed,
      style: style,
      child: ((c.children['child'] as Widget?) ?? const SizedBox.shrink()),
    );
  });

  r.register('TextButton', (c) {
    final onPressed = c.on('onPressed');
    final style = c.buttonStyle('style');
    if (c.str('factory') == 'icon') {
      return TextButton.icon(
        key: c.key,
        onPressed: onPressed,
        style: style,
        icon: (c.children['icon'] as Widget?) ?? const SizedBox.shrink(),
        label: (c.children['label'] as Widget?) ?? const SizedBox.shrink(),
      );
    }
    return TextButton(
      key: c.key,
      onPressed: onPressed,
      style: style,
      child: ((c.children['child'] as Widget?) ?? const SizedBox.shrink()),
    );
  });

  r.register('FilledButton', (c) {
    final onPressed = c.on('onPressed');
    final style = c.buttonStyle('style');
    switch (c.str('factory')) {
      case 'icon':
        return FilledButton.icon(
          key: c.key,
          onPressed: onPressed,
          style: style,
          icon: (c.children['icon'] as Widget?) ?? const SizedBox.shrink(),
          label: (c.children['label'] as Widget?) ?? const SizedBox.shrink(),
        );
      case 'tonal':
        return FilledButton.tonal(
          key: c.key,
          onPressed: onPressed,
          style: style,
          child: ((c.children['child'] as Widget?) ?? const SizedBox.shrink()),
        );
      case 'tonalIcon':
        return FilledButton.tonalIcon(
          key: c.key,
          onPressed: onPressed,
          style: style,
          icon: (c.children['icon'] as Widget?) ?? const SizedBox.shrink(),
          label: (c.children['label'] as Widget?) ?? const SizedBox.shrink(),
        );
      default:
        return FilledButton(
          key: c.key,
          onPressed: onPressed,
          style: style,
          child: ((c.children['child'] as Widget?) ?? const SizedBox.shrink()),
        );
    }
  });

  r.register('OutlinedButton', (c) {
    final onPressed = c.on('onPressed');
    final style = c.buttonStyle('style');
    if (c.str('factory') == 'icon') {
      return OutlinedButton.icon(
        key: c.key,
        onPressed: onPressed,
        style: style,
        icon: (c.children['icon'] as Widget?) ?? const SizedBox.shrink(),
        label: (c.children['label'] as Widget?) ?? const SizedBox.shrink(),
      );
    }
    return OutlinedButton(
      key: c.key,
      onPressed: onPressed,
      style: style,
      child: ((c.children['child'] as Widget?) ?? const SizedBox.shrink()),
    );
  });

  r.register('InkWell', (c) {
    final radius = c.double_('borderRadius');
    return InkWell(
      key: c.key,
      onTap: c.on('onTap'),
      onLongPress: c.on('onLongPress'),
      onDoubleTap: c.on('onDoubleTap'),
      borderRadius: radius == null ? null : BorderRadius.circular(radius),
      splashColor: c.color('splashColor'),
      highlightColor: c.color('highlightColor'),
      child: (c.children['child'] as Widget?),
    );
  });

  r.register(
    'GestureDetector',
    (c) => GestureDetector(
      key: c.key,
      onTap: c.on('onTap'),
      onLongPress: c.on('onLongPress'),
      onDoubleTap: c.on('onDoubleTap'),
      behavior: c.hitTestBehavior('behavior'),
      child: (c.children['child'] as Widget?),
    ),
  );

  r.register(
    'Switch',
    (c) => Switch(
      key: c.key,
      value: c.bool_('value') ?? false,
      onChanged: c.on1<bool?>('onChanged'),
      // 协议键仍叫 activeColor（生成器侧），Flutter 新版改名为 activeThumbColor
      activeThumbColor: c.color('activeColor'),
      activeTrackColor: c.color('activeTrackColor'),
      inactiveThumbColor: c.color('inactiveThumbColor'),
      inactiveTrackColor: c.color('inactiveTrackColor'),
    ),
  );

  r.register(
    'Checkbox',
    (c) => Checkbox(
      key: c.key,
      value: c.bool_('value'),
      tristate: c.bool_('tristate') ?? false,
      onChanged: c.on1<bool?>('onChanged'),
      activeColor: c.color('activeColor'),
      checkColor: c.color('checkColor'),
    ),
  );

  r.register(
    'Slider',
    (c) => Slider(
      key: c.key,
      value: c.double_('value') ?? 0,
      min: c.double_('min') ?? 0,
      max: c.double_('max') ?? 1,
      divisions: c.int_('divisions'),
      label: c.str('label'),
      activeColor: c.color('activeColor'),
      inactiveColor: c.color('inactiveColor'),
      onChanged: c.on1<double>('onChanged'),
    ),
  );

  // Scaffold：appBar / body / floatingActionButton / bottomNavigationBar
  // 都是「值为 element 的 prop」（生成器把命名参数翻译进 props，产物
  // `Scaffold({appBar: AppBar({...}), body: Column({...})})`）——宿主
  // propChild 直取，不依赖 children 顺序/类型判断。appBar 经
  // _JsAppBarAdaptor 适配 PreferredSizeWidget（JS 节点是 JsUiWidget 包装，
  // 非原生 AppBar 实例）。
  r.register('Scaffold', (c) {
    final appBar = (c.children['appBar'] as Widget?);
    return Scaffold(
      key: c.key,
      backgroundColor: c.color('backgroundColor'),
      // appBar 已经是 PreferredSizeWidget（真实 AppBar / PreferredSize 结点）时
      // 原样使用：PreferredSize 的全部意义就是自定义占位高度，套一层固定
      // kToolbarHeight 的适配器会把高度改回去。
      appBar: appBar == null
          ? null
          : (appBar is PreferredSizeWidget ? appBar : _JsAppBarAdaptor(appBar)),
      body: (c.children['body'] as Widget?),
      floatingActionButton: (c.children['floatingActionButton'] as Widget?),
      bottomNavigationBar: (c.children['bottomNavigationBar'] as Widget?),
      // drawer / endDrawer 接进真实 Scaffold：AppBar 自动出现汉堡按钮，
      // 开启原生可用；关闭走 capabilities/drawer/drawer_bridge.dart 的抽屉作用域。
      drawer: (c.children['drawer'] as Widget?),
      endDrawer: (c.children['endDrawer'] as Widget?),
      drawerScrimColor: c.color('drawerScrimColor'),
    );
  });

  // AppBar：title / leading / flexibleSpace / actions 都按 Dart 形参原名从
  // children 取（actions 是数组 slot）。
  r.register('AppBar', (c) {
    final actions =
        (c.children['actions'] as List<Widget>?) ?? const <Widget>[];
    return AppBar(
      key: c.key,
      leading: (c.children['leading'] as Widget?),
      title: (c.children['title'] as Widget?),
      flexibleSpace: (c.children['flexibleSpace'] as Widget?),
      actions: actions.isEmpty ? null : actions,
      backgroundColor: c.color('backgroundColor'),
      foregroundColor: c.color('foregroundColor'),
      elevation: c.double_('elevation'),
      toolbarHeight: c.double_('toolbarHeight'),
      centerTitle: c.bool_('centerTitle'),
      titleTextStyle: c.textStyle('titleTextStyle'),
    );
  });

  // ---------------------------------------------------------------------
  // 布局 / 装饰补充
  // ---------------------------------------------------------------------

  r.register(
    'SafeArea',
    (c) => SafeArea(
      key: c.key,
      left: c.bool_('left') ?? true,
      top: c.bool_('top') ?? true,
      right: c.bool_('right') ?? true,
      bottom: c.bool_('bottom') ?? true,
      // minimum：每边取 max(系统 padding, minimum)——即使系统 padding 为 0
      // （如 macOS 窗口）也能强制留白，是 SafeArea 唯一可见的效果来源。
      // 缺省与 Flutter 官方一致：EdgeInsets.zero。
      minimum: c.edgeInsets('minimum') ?? EdgeInsets.zero,
      // false 时底部用 padding.bottom；true 时改用 viewPadding.bottom
      // （手势条区域的固定内边距，键盘弹出时不跟随变化）。
      maintainBottomViewPadding: c.bool_('maintainBottomViewPadding') ?? false,
      child: ((c.children['child'] as Widget?) ?? const SizedBox.shrink()),
    ),
  );

  r.register(
    'Opacity',
    (c) => Opacity(
      key: c.key,
      opacity: c.double_('opacity') ?? 1,
      child: (c.children['child'] as Widget?),
    ),
  );

  // Offstage：offstage=true 时不参与布局/绘制/命中测试（State 保活，Ticker 照跑）。
  r.register(
    'Offstage',
    (c) => Offstage(
      key: c.key,
      offstage: c.bool_('offstage') ?? false,
      child: (c.children['child'] as Widget?),
    ),
  );

  // Visibility：盒子版显隐控制，六个 maintain* 与 replacement 全部透传。
  // Flutter 的断言链（maintainSemantics/maintainInteractivity ⇒ maintainSize
  // ⇒ maintainAnimation ⇒ maintainState）由**调用方**保证——与原生一致，
  // 这里不替它「自动补齐」，否则会掩盖写法错误。
  //
  // `Visibility.maintain` 是命名构造：它把六个 maintain* 全部置 true（保持占位），
  // 产物里没有这些字段，故按 `factory` 还原原生构造，不能走普通构造的 false 缺省。
  r.register('Visibility', (c) {
    final visible = c.bool_('visible') ?? true;
    final replacement =
        (c.children['replacement'] as Widget?) ?? const SizedBox.shrink();
    final child = (c.children['child'] as Widget);
    if (c.str('factory') == 'maintain') {
      return Visibility.maintain(key: c.key, visible: visible, child: child);
    }
    return Visibility(
      key: c.key,
      visible: visible,
      maintainState: c.bool_('maintainState') ?? false,
      maintainAnimation: c.bool_('maintainAnimation') ?? false,
      maintainSize: c.bool_('maintainSize') ?? false,
      maintainSemantics: c.bool_('maintainSemantics') ?? false,
      maintainInteractivity: c.bool_('maintainInteractivity') ?? false,
      maintainFocusability: c.bool_('maintainFocusability') ?? false,
      replacement: replacement,
      child: child,
    );
  });

  r.register(
    'ConstrainedBox',
    (c) => ConstrainedBox(
      key: c.key,
      constraints:
          c.boxConstraints('constraints') ??
          const BoxConstraints(),
      child: ((c.children['child'] as Widget?) ?? const SizedBox.shrink()),
    ),
  );

  r.register(
    'AspectRatio',
    (c) => AspectRatio(
      key: c.key,
      aspectRatio: c.double_('aspectRatio') ?? 1,
      child: (c.children['child'] as Widget?),
    ),
  );

  r.register(
    'FractionallySizedBox',
    (c) => FractionallySizedBox(
      key: c.key,
      widthFactor: c.double_('widthFactor'),
      heightFactor: c.double_('heightFactor'),
      alignment: c.alignment('alignment') ?? Alignment.center,
      child: (c.children['child'] as Widget?),
    ),
  );

  r.register(
    'DecoratedBox',
    (c) => DecoratedBox(
      key: c.key,
      decoration:
          c.boxDecoration('decoration') ?? const BoxDecoration(),
      child: (c.children['child'] as Widget?),
    ),
  );

  // ---------------------------------------------------------------------
  // 指示器
  // ---------------------------------------------------------------------

  r.register(
    'CircularProgressIndicator',
    (c) => CircularProgressIndicator(
      key: c.key,
      value: c.double_('value'),
      color: c.color('color'),
      backgroundColor: c.color('backgroundColor'),
      strokeWidth: c.double_('strokeWidth') ?? 4.0,
    ),
  );

  r.register(
    'LinearProgressIndicator',
    (c) => LinearProgressIndicator(
      key: c.key,
      value: c.double_('value'),
      color: c.color('color'),
      backgroundColor: c.color('backgroundColor'),
      minHeight: c.double_('minHeight'),
    ),
  );

  // ---------------------------------------------------------------------
  // 输入 / 导航
  // ---------------------------------------------------------------------

  // IconButton：普通构造读 `icon`；`.filled` / `.filledTonal` / `.outlined` 是
  // 命名构造（容器底色 / 描边不同），宿主按 `factory` 还原原生构造。
  r.register('IconButton', (c) {
    final icon =
        (c.children['icon'] as Widget?) ?? const Icon(Icons.error_outline);
    final onPressed = c.on('onPressed');
    final color = c.color('color');
    final iconSize = c.double_('iconSize');
    final tooltip = c.str('tooltip');
    switch (c.str('factory')) {
      case 'filled':
        return IconButton.filled(
          key: c.key,
          onPressed: onPressed,
          icon: icon,
          color: color,
          iconSize: iconSize,
          tooltip: tooltip,
        );
      case 'filledTonal':
        return IconButton.filledTonal(
          key: c.key,
          onPressed: onPressed,
          icon: icon,
          color: color,
          iconSize: iconSize,
          tooltip: tooltip,
        );
      case 'outlined':
        return IconButton.outlined(
          key: c.key,
          onPressed: onPressed,
          icon: icon,
          color: color,
          iconSize: iconSize,
          tooltip: tooltip,
        );
      default:
        return IconButton(
          key: c.key,
          icon: icon,
          onPressed: onPressed,
          color: color,
          iconSize: iconSize,
          tooltip: tooltip,
        );
    }
  });

  // FloatingActionButton：普通构造读 `child`；`.large` / `.small` 是尺寸变体
  // （子结点仍是 child），`.extended` 读 `icon` + `label` 两个 slot——全部按
  // `factory` 还原原生命名构造。
  r.register('FloatingActionButton', (c) {
    // onPressed 缺省必须为 null：Flutter 默认 null = 禁用（灰色不可点）；
    // `() {}` 会变成可点但无动作，与原生语义不一致。
    final onPressed = c.on('onPressed');
    final backgroundColor = c.color('backgroundColor');
    final foregroundColor = c.color('foregroundColor');
    final tooltip = c.str('tooltip');
    final elevation = c.double_('elevation');
    switch (c.str('factory')) {
      case 'extended':
        return FloatingActionButton.extended(
          key: c.key,
          onPressed: onPressed,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          tooltip: tooltip,
          elevation: elevation,
          icon: (c.children['icon'] as Widget?),
          label: (c.children['label'] as Widget?) ?? const SizedBox.shrink(),
        );
      case 'large':
        return FloatingActionButton.large(
          key: c.key,
          onPressed: onPressed,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          tooltip: tooltip,
          elevation: elevation,
          child: (c.children['child'] as Widget?),
        );
      case 'small':
        return FloatingActionButton.small(
          key: c.key,
          onPressed: onPressed,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          tooltip: tooltip,
          elevation: elevation,
          child: (c.children['child'] as Widget?),
        );
      default:
        return FloatingActionButton(
          key: c.key,
          onPressed: onPressed,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          mini: c.bool_('mini') ?? false,
          tooltip: tooltip,
          elevation: elevation,
          child: (c.children['child'] as Widget?),
        );
    }
  });

  r.register('BottomNavigationBar', (c) {
    // items 是值对象数组（BottomNavigationBarItem 在 JS 侧是普通值类，不是
    // 元素）：每项就是它的字段 JSON；携带的 Widget（icon / activeIcon）是元素
    // 描述，用 `element` 就地还原，不进 reconciler 树。
    final items = <BottomNavigationBarItem>[];
    for (final raw in (c.props['items'] as List?) ?? const []) {
      if (raw is! Map) continue;
      items.add(
        BottomNavigationBarItem(
          icon: c.element(raw['icon']) ?? const Icon(Icons.error_outline),
          activeIcon: c.element(raw['activeIcon']),
          label: raw['label'] == null ? null : '${raw['label']}',
          tooltip: raw['tooltip'] == null ? null : '${raw['tooltip']}',
        ),
      );
    }
    return BottomNavigationBar(
      key: c.key,
      items: items,
      currentIndex: c.int_('currentIndex') ?? 0,
      onTap: c.on1<int>('onTap'),
      selectedItemColor: c.color('selectedItemColor'),
      unselectedItemColor: c.color('unselectedItemColor'),
    );
  });

  // RadioGroup：把选中值 + 回调提供给**子树内**的 Radio（子级不必再传
  // `groupValue` / `onChanged`，那两个是被它取代的旧 API）。onChanged 是必填，
  // JS 侧没给时用空函数兜底，避免整页因一个缺失回调挂掉。
  r.register(
    'RadioGroup',
    (c) => RadioGroup<dynamic>(
      key: c.key,
      groupValue: c.props['groupValue'],
      onChanged: c.on1<dynamic>('onChanged') ?? (dynamic _) {},
      child: (c.children['child'] as Widget?) ?? const SizedBox.shrink(),
    ),
  );

  r.register(
    'Radio',
    (c) => Radio<dynamic>(
      key: c.key,
      value: c.props['value'],
      // ignore: deprecated_member_use
      groupValue: c.props['groupValue'],
      // ignore: deprecated_member_use
      onChanged: c.on1<dynamic>('onChanged'),
      activeColor: c.color('activeColor'),
    ),
  );

  r.register('DropdownButton', (c) {
    // items 是值对象数组（DropdownMenuItem 在 JS 侧是普通值类，不是元素）：
    // 每项就是它的字段 JSON；携带的 child 是元素描述，用 `element` 就地还原。
    final items = <DropdownMenuItem<dynamic>>[];
    for (final raw in (c.props['items'] as List?) ?? const []) {
      if (raw is! Map) continue;
      items.add(
        DropdownMenuItem<dynamic>(
          value: raw['value'],
          // enabled 缺省为 true（与 Flutter 默认一致）；alignment 走统一
          // 的枚举/常量协议（JS 侧 Alignment 常量即成员名字符串）。
          enabled: raw['enabled'] is bool ? raw['enabled'] as bool : true,
          alignment:
              alignmentFromJson(raw['alignment']) ??
              AlignmentDirectional.centerStart,
          child: c.element(raw['child']) ?? const SizedBox.shrink(),
        ),
      );
    }
    return DropdownButton<dynamic>(
      key: c.key,
      value: c.props['value'],
      items: items,
      onChanged: c.on1<dynamic>('onChanged'),
      hint: c.children['hint'] as Widget?,
      isExpanded: c.bool_('isExpanded') ?? false,
    );
  });

  // ---------------------------------------------------------------------
  // 单子包装 / 布局交互补充
  // ---------------------------------------------------------------------

  r.register(
    'Tooltip',
    (c) => Tooltip(
      key: c.key,
      message: c.str('message') ?? '',
      waitDuration: c.duration('waitDuration'),
      showDuration: c.duration('showDuration'),
      // padding / margin / verticalOffset / excludeFromSemantics 在 Tooltip 里
      // 都是「null = 用 TooltipTheme 默认」，不能塞自己的零值/常量覆盖主题。
      padding: c.edgeInsets('padding'),
      margin: c.edgeInsets('margin'),
      verticalOffset: c.double_('verticalOffset'),
      preferBelow: c.bool_('preferBelow'),
      excludeFromSemantics: c.bool_('excludeFromSemantics'),
      enableTapToDismiss: c.bool_('enableTapToDismiss') ?? true,
      decoration: c.boxDecoration('decoration'),
      textStyle: c.textStyle('textStyle'),
      child: c.children['child'] as Widget?,
    ),
  );

  r.register(
    'IgnorePointer',
    (c) => IgnorePointer(
      key: c.key,
      ignoring: c.bool_('ignoring') ?? true,
      child: c.children['child'] as Widget?,
    ),
  );

  r.register(
    'AbsorbPointer',
    (c) => AbsorbPointer(
      key: c.key,
      absorbing: c.bool_('absorbing') ?? true,
      child: c.children['child'] as Widget?,
    ),
  );

  r.register(
    'RepaintBoundary',
    (c) => RepaintBoundary(key: c.key, child: c.children['child'] as Widget?),
  );

  r.register(
    'Baseline',
    (c) => Baseline(
      key: c.key,
      baseline: c.double_('baseline') ?? 0,
      baselineType:
          c.textBaseline('baselineType') ??
          TextBaseline.alphabetic,
      child: c.children['child'] as Widget?,
    ),
  );

  r.register(
    'FittedBox',
    (c) => FittedBox(
      key: c.key,
      fit: c.boxFit('fit') ?? BoxFit.contain,
      alignment: c.alignment('alignment') ?? Alignment.center,
      clipBehavior: c.clipBehavior('clipBehavior') ?? Clip.none,
      child: c.children['child'] as Widget?,
    ),
  );

  r.register(
    'RotatedBox',
    (c) => RotatedBox(
      key: c.key,
      quarterTurns: c.int_('quarterTurns') ?? 0,
      child: c.children['child'] as Widget?,
    ),
  );

  r.register(
    'IntrinsicWidth',
    (c) => IntrinsicWidth(
      key: c.key,
      stepWidth: c.double_('stepWidth'),
      stepHeight: c.double_('stepHeight'),
      child: c.children['child'] as Widget?,
    ),
  );

  r.register(
    'IntrinsicHeight',
    (c) => IntrinsicHeight(key: c.key, child: c.children['child'] as Widget?),
  );

  r.register(
    'LimitedBox',
    (c) => LimitedBox(
      key: c.key,
      maxWidth: c.double_('maxWidth') ?? double.infinity,
      maxHeight: c.double_('maxHeight') ?? double.infinity,
      child: c.children['child'] as Widget?,
    ),
  );

  r.register('InteractiveViewer', (c) {
    final child = c.children['child'] as Widget?;
    if (child == null) {
      return uiFallback('InteractiveViewer.child 缺失');
    }
    final start = c.on1<Map<String, dynamic>>('onInteractionStart');
    final update = c.on1<Map<String, dynamic>>('onInteractionUpdate');
    final end = c.on1<Map<String, dynamic>>('onInteractionEnd');
    return InteractiveViewer(
      key: c.key,
      minScale: c.double_('minScale') ?? 0.8,
      maxScale: c.double_('maxScale') ?? 2.5,
      panEnabled: c.bool_('panEnabled') ?? true,
      scaleEnabled: c.bool_('scaleEnabled') ?? true,
      scaleFactor: c.double_('scaleFactor') ?? kDefaultMouseScrollToScaleFactor,
      constrained: c.bool_('constrained') ?? true,
      boundaryMargin: c.edgeInsets('boundaryMargin') ?? EdgeInsets.zero,
      onInteractionStart: start == null ? null : (d) => start(_scaleJson(d)),
      onInteractionUpdate: update == null ? null : (d) => update(_scaleJson(d)),
      onInteractionEnd: end == null ? null : (d) => end(_scaleJson(d)),
      child: child,
    );
  });
}

/// 三种 `Scale*Details` 共有的字段（用户回调在 JS 侧只关心这几个）。
Map<String, dynamic> _scaleJson(dynamic d) {
  final focal = d.focalPoint as Offset;
  final local = d.localFocalPoint as Offset;
  return <String, dynamic>{
    'focalPoint': <String, double>{'dx': focal.dx, 'dy': focal.dy},
    'localFocalPoint': <String, double>{'dx': local.dx, 'dy': local.dy},
    // ScaleStartDetails 只有 focalPoint（没有 scale 倍率），其余两个有。
    'scale': d.scale is double ? d.scale as double : 1.0,
    'horizontalScale': d.horizontalScale is double
        ? d.horizontalScale as double
        : 1.0,
    'verticalScale': d.verticalScale is double
        ? d.verticalScale as double
        : 1.0,
    'rotation': d.rotation is double ? d.rotation as double : 0.0,
  };
}

/// AppBar 插槽适配器：把 JS 节点（JsUiWidget 包装）适配为
/// PreferredSizeWidget 交给 Scaffold.appBar。preferredSize 取 AppBar 默认
/// 高度 kToolbarHeight（demo 内 AppBar 均为默认 toolbarHeight）。
class _JsAppBarAdaptor extends StatelessWidget implements PreferredSizeWidget {
  const _JsAppBarAdaptor(this.child);

  final Widget child;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => child;
}

/// `PreferredSize` 承载：把 JS 子树声明成 `PreferredSizeWidget`，尺寸由 props
/// 的 preferredSize 决定（Scaffold.appBar 等位置据此占位）。
class _JsPreferredSize extends StatelessWidget implements PreferredSizeWidget {
  const _JsPreferredSize({super.key, required this.preferredSize, this.child});

  @override
  final Size preferredSize;

  final Widget? child;

  @override
  Widget build(BuildContext context) => child ?? const SizedBox.shrink();
}
