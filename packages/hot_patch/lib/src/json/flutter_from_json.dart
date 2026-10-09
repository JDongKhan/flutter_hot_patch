import 'package:flutter/material.dart';
import '../utils/hot_patch_log.dart';

// ===========================================================================
// JSON → Flutter 对象的 fromJson 工具集（运行时侧）
//
// 与 ui_component_generator 的 style_translators.dart 对称：
//   生成器：TextStyle/ButtonStyle/Colors/FontWeight … → JSON
//   运行时：同一份 JSON → 真实 Flutter 对象
//
// 解耦：样式还原不放进 widget renderer，避免一个文件越滚越大；
// 新增样式类 = 在这个文件加一个 xxxFromJson + 在 renderer 里调用。
// ===========================================================================

/// JSON → TextStyle（null / 空 Map → 默认样式）。
TextStyle textStyleFromJson(Map<String, dynamic>? json) {
  if (json == null || json.isEmpty) return const TextStyle();
  return TextStyle(
    fontSize: (json['fontSize'] as num?)?.toDouble(),
    fontWeight: fontWeightFromJson(json['fontWeight']),
    color: colorFromJson(json['color']),
    fontStyle: fontStyleFromJson(json['fontStyle']),
    letterSpacing: (json['letterSpacing'] as num?)?.toDouble(),
    wordSpacing: (json['wordSpacing'] as num?)?.toDouble(),
    height: (json['height'] as num?)?.toDouble(),
    fontFamily: json['fontFamily'] as String?,
    fontFamilyFallback: (json['fontFamilyFallback'] as List?)?.map((x) => x.toString()).toList(),
    backgroundColor: colorFromJson(json['backgroundColor']),
    decoration: textDecorationFromJson(json['decoration']),
    decorationColor: colorFromJson(json['decorationColor']),
    decorationStyle: textDecorationStyleFromJson(json['decorationStyle']),
    decorationThickness: (json['decorationThickness'] as num?)?.toDouble(),
  );
}

/// JSON → TextDecoration（'none'/'underline'/'overline'/'lineThrough'）。
TextDecoration? textDecorationFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'none' => TextDecoration.none,
    'underline' => TextDecoration.underline,
    'overline' => TextDecoration.overline,
    'lineThrough' => TextDecoration.lineThrough,
    _ => null,
  };
}

/// JSON → TextDecorationStyle（'solid'/'double'/'dotted'/'dashed'/'wavy'）。
TextDecorationStyle? textDecorationStyleFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'solid' => TextDecorationStyle.solid,
    'double' => TextDecorationStyle.double,
    'dotted' => TextDecorationStyle.dotted,
    'dashed' => TextDecorationStyle.dashed,
    'wavy' => TextDecorationStyle.wavy,
    _ => null,
  };
}

/// JSON → TextAlign（'left'/'right'/'center'/'justify'/'start'/'end'）。
TextAlign? textAlignFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'left' => TextAlign.left,
    'right' => TextAlign.right,
    'center' => TextAlign.center,
    'justify' => TextAlign.justify,
    'start' => TextAlign.start,
    'end' => TextAlign.end,
    _ => null,
  };
}

/// JSON → TextOverflow（'clip'/'fade'/'ellipsis'/'visible'）。
TextOverflow? overflowFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'clip' => TextOverflow.clip,
    'fade' => TextOverflow.fade,
    'ellipsis' => TextOverflow.ellipsis,
    'visible' => TextOverflow.visible,
    _ => null,
  };
}

/// JSON → TextDirection（'ltr'/'rtl'）。
TextDirection? textDirectionFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'ltr' => TextDirection.ltr,
    'rtl' => TextDirection.rtl,
    _ => null,
  };
}

/// JSON → VisualDensity（'compact'/'standard'/'comfortable'）。
VisualDensity? visualDensityFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'compact' => VisualDensity.compact,
    'standard' => VisualDensity.standard,
    'comfortable' => VisualDensity.comfortable,
    _ => null,
  };
}

/// JSON → Size（{'width':..,'height':..}）。
Size? sizeFromJson(Object? v) {
  if (v is! Map) return null;
  double? d(Object? x) {
    if (x is num) return x.toDouble();
    return double.tryParse('$x');
  }

  final w = d(v['width']);
  final h = d(v['height']);
  if (w == null || h == null) return null;
  return Size(w, h);
}

/// JSON → BorderSide（{'color':..,'width':..,'style':..}）。
BorderSide? borderSideFromJson(Object? v) {
  if (v is! Map) return null;
  final c = colorFromJson(v['color']);
  final w = (v['width'] as num?)?.toDouble();
  return BorderSide(
    color: c ?? const Color(0xFF000000),
    width: w ?? 1.0,
    style: v['style'] == 'none' ? BorderStyle.none : BorderStyle.solid,
  );
}

/// JSON → ButtonStyle（null / 空 Map → null，表示用 widget 默认样式）。
ButtonStyle? buttonStyleFromJson(Map<String, dynamic>? json) {
  if (json == null || json.isEmpty) return null;
  final bg = colorFromJson(json['backgroundColor']);
  final fg = colorFromJson(json['foregroundColor']);
  final overlay = colorFromJson(json['overlayColor']);
  final icon = colorFromJson(json['iconColor']);
  final shadow = colorFromJson(json['shadowColor']);
  final disabledBg = colorFromJson(json['disabledBackgroundColor']);
  final disabledFg = colorFromJson(json['disabledForegroundColor']);
  // ButtonStyle 无 disabledXxx 参数（那是 styleFrom 的便捷参数）：
  // 合并进 backgroundColor/foregroundColor 的 resolveWith。
  final bgProp = (bg == null && disabledBg == null)
      ? null
      : WidgetStateProperty.resolveWith<Color?>((states) =>
          states.contains(WidgetState.disabled) ? (disabledBg ?? bg) : bg);
  final fgProp = (fg == null && disabledFg == null)
      ? null
      : WidgetStateProperty.resolveWith<Color?>((states) =>
          states.contains(WidgetState.disabled) ? (disabledFg ?? fg) : fg);
  return ButtonStyle(
    backgroundColor: bgProp,
    foregroundColor: fgProp,
    overlayColor: overlay == null ? null : WidgetStatePropertyAll<Color?>(overlay),
    iconColor: icon == null ? null : WidgetStatePropertyAll<Color?>(icon),
    shadowColor: shadow == null ? null : WidgetStatePropertyAll<Color?>(shadow),
    elevation: json['elevation'] == null
        ? null
        : WidgetStatePropertyAll<double?>((json['elevation'] as num).toDouble()),
    padding: json['padding'] is Map
        ? WidgetStatePropertyAll<EdgeInsets?>(edgeInsetsFromJson((json['padding'] as Map).cast<String, dynamic>()))
        : null,
    minimumSize: sizeFromJson(json['minimumSize']) == null
        ? null
        : WidgetStatePropertyAll<Size?>(sizeFromJson(json['minimumSize'])),
    maximumSize: sizeFromJson(json['maximumSize']) == null
        ? null
        : WidgetStatePropertyAll<Size?>(sizeFromJson(json['maximumSize'])),
    side: borderSideFromJson(json['side']) == null
        ? null
        : WidgetStatePropertyAll<BorderSide?>(borderSideFromJson(json['side'])),
    shape: shapeFromJson(json['shape']) == null
        ? null
        : WidgetStatePropertyAll<OutlinedBorder?>(shapeFromJson(json['shape'])),
    fixedSize: sizeFromJson(json['fixedSize']) == null
        ? null
        : WidgetStatePropertyAll<Size?>(sizeFromJson(json['fixedSize'])),
    textStyle: json['textStyle'] is Map
        ? WidgetStatePropertyAll<TextStyle?>(textStyleFromJson((json['textStyle'] as Map).cast<String, dynamic>()))
        : null,
    alignment: alignmentFromJson(json['alignment']),
    visualDensity: visualDensityFromJson(json['visualDensity']),
    enableFeedback: json['enableFeedback'] as bool?,
  );
}

/// JSON → FontWeight（'bold' / 'w500' / 'normal'）。
FontWeight? fontWeightFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'bold' => FontWeight.bold,
    'normal' => FontWeight.normal,
    _ when v.startsWith('w') && v.length == 4 => FontWeight.values.firstWhere(
      (w) => w.value == int.parse(v.substring(1)),
      orElse: () => FontWeight.normal,
    ),
    _ => null,
  };
}

/// JSON → FontStyle（'italic' / 'normal'）。
FontStyle? fontStyleFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'italic' => FontStyle.italic,
    'normal' => FontStyle.normal,
    _ => null,
  };
}

/// JSON → Color（'#RRGGBB' / '#AARRGGBB'）。
/// TextScaler.noScaling / TextScaler.linear(f)（生成器 textScalerToJson 对称）。
TextScaler? textScalerFromJson(Object? v) {
  if (v is String && v == 'noScaling') return TextScaler.noScaling;
  if (v is Map && v['linear'] != null) {
    final f = double.tryParse('${v['linear']}');
    if (f != null) return TextScaler.linear(f);
  }
  return null;
}

/// Flutter 官方 MaterialColor 常量表（'@Colors.blue.shade100' 标记解析用）。
final Map<String, MaterialColor> _materialColors = {
  'red': Colors.red,
  'pink': Colors.pink,
  'purple': Colors.purple,
  'deepPurple': Colors.deepPurple,
  'indigo': Colors.indigo,
  'blue': Colors.blue,
  'lightBlue': Colors.lightBlue,
  'cyan': Colors.cyan,
  'teal': Colors.teal,
  'green': Colors.green,
  'lightGreen': Colors.lightGreen,
  'lime': Colors.lime,
  'yellow': Colors.yellow,
  'amber': Colors.amber,
  'orange': Colors.orange,
  'deepOrange': Colors.deepOrange,
  'brown': Colors.brown,
  'grey': Colors.grey,
  'blueGrey': Colors.blueGrey,
};

Color? _materialShade(String path) {
  final parts = path.split('.');
  // path: 'Colors.blue.shade100'
  if (parts.length != 3 || parts[0] != 'Colors') return null;
  final base = _materialColors[parts[1]];
  if (base == null) return null;
  return switch (parts[2]) {
    'shade50' => base.shade50,
    'shade100' => base.shade100,
    'shade200' => base.shade200,
    'shade300' => base.shade300,
    'shade400' => base.shade400,
    'shade500' => base.shade500,
    'shade600' => base.shade600,
    'shade700' => base.shade700,
    'shade800' => base.shade800,
    'shade900' => base.shade900,
    _ => null,
  };
}

Color? colorFromJson(Object? v) {
  if (v is! String) return null;
  if (v.startsWith('@')) return _materialShade(v.substring(1));
  if (!v.startsWith('#') || v.length != 7 && v.length != 9) return null;
  final hex = v.substring(1);
  final value = int.tryParse(hex, radix: 16);
  if (value == null) return null;
  // 6 位 → 补不透明 alpha
  if (hex.length == 6) return Color(0xFF000000 | value);
  return Color(value);
}

// ---------------------------------------------------------------------------
// 布局/内容类 fromJson（与 ui_component_generator 的 style_translators 对称）
// ---------------------------------------------------------------------------

/// JSON → EdgeInsets（{left,top,right,bottom}；缺省 0）。
EdgeInsets edgeInsetsFromJson(Map<String, dynamic>? json) {
  if (json == null || json.isEmpty) return EdgeInsets.zero;
  double v(Object? x) {
    if (x is num) return x.toDouble();
    return double.tryParse('$x') ?? 0;
  }

  return EdgeInsets.only(
    left: v(json['left']),
    top: v(json['top']),
    right: v(json['right']),
    bottom: v(json['bottom']),
  );
}

/// JSON → Alignment（'center'/'topLeft'/...）。
Alignment? alignmentFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'center' => Alignment.center,
    'topLeft' => Alignment.topLeft,
    'topCenter' => Alignment.topCenter,
    'topRight' => Alignment.topRight,
    'centerLeft' => Alignment.centerLeft,
    'centerRight' => Alignment.centerRight,
    'bottomLeft' => Alignment.bottomLeft,
    'bottomCenter' => Alignment.bottomCenter,
    'bottomRight' => Alignment.bottomRight,
    _ => null,
  };
}

/// JSON → MainAxisAlignment。
MainAxisAlignment? mainAxisAlignmentFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'start' => MainAxisAlignment.start,
    'end' => MainAxisAlignment.end,
    'center' => MainAxisAlignment.center,
    'spaceBetween' => MainAxisAlignment.spaceBetween,
    'spaceAround' => MainAxisAlignment.spaceAround,
    'spaceEvenly' => MainAxisAlignment.spaceEvenly,
    _ => null,
  };
}

/// JSON → CrossAxisAlignment。
CrossAxisAlignment? crossAxisAlignmentFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'start' => CrossAxisAlignment.start,
    'end' => CrossAxisAlignment.end,
    'center' => CrossAxisAlignment.center,
    'stretch' => CrossAxisAlignment.stretch,
    'baseline' => CrossAxisAlignment.baseline,
    _ => null,
  };
}

/// JSON → MainAxisSize（'min'/'max'）。
MainAxisSize? mainAxisSizeFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'min' => MainAxisSize.min,
    'max' => MainAxisSize.max,
    _ => null,
  };
}

/// JSON → Axis（'horizontal'/'vertical'）。
Axis? axisFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'horizontal' => Axis.horizontal,
    'vertical' => Axis.vertical,
    _ => null,
  };
}

/// JSON → BoxFit（'cover'/'contain'/...）。
BoxFit? boxFitFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'cover' => BoxFit.cover,
    'contain' => BoxFit.contain,
    'fill' => BoxFit.fill,
    'fitWidth' => BoxFit.fitWidth,
    'fitHeight' => BoxFit.fitHeight,
    'none' => BoxFit.none,
    'scaleDown' => BoxFit.scaleDown,
    _ => null,
  };
}

/// JSON → BorderRadius（{radius: n} 统一圆角，或
/// {topLeft, topRight, bottomLeft, bottomRight} 四角独立；缺省角 = 0）。
BorderRadius? borderRadiusFromJson(Map<String, dynamic>? json) {
  if (json == null) return null;
  double? v(Object? x) {
    if (x is num) return x.toDouble();
    return double.tryParse('$x');
  }

  final r = v(json['radius']);
  if (r != null) return BorderRadius.circular(r);
  final tl = v(json['topLeft']);
  final tr = v(json['topRight']);
  final bl = v(json['bottomLeft']);
  final br = v(json['bottomRight']);
  if (tl == null && tr == null && bl == null && br == null) return null;
  return BorderRadius.only(
    topLeft: Radius.circular(tl ?? 0),
    topRight: Radius.circular(tr ?? 0),
    bottomLeft: Radius.circular(bl ?? 0),
    bottomRight: Radius.circular(br ?? 0),
  );
}

/// JSON → Border（{'all': borderSide} 四边统一，或
/// {'top': ..., 'right': ..., 'bottom': ..., 'left': ...} 四边独立）。
Border? borderFromJson(Map<String, dynamic>? json) {
  if (json == null || json.isEmpty) return null;
  final all = borderSideFromJson(json['all']);
  if (all != null) return Border.fromBorderSide(all);
  return Border(
    top: borderSideFromJson(json['top']) ?? BorderSide.none,
    right: borderSideFromJson(json['right']) ?? BorderSide.none,
    bottom: borderSideFromJson(json['bottom']) ?? BorderSide.none,
    left: borderSideFromJson(json['left']) ?? BorderSide.none,
  );
}

/// JSON → BoxShadow（{'color': c, 'dx': n, 'dy': n, 'blur': n, 'spread': n,
/// 'blurStyle': s}）。
BoxShadow? boxShadowFromJson(Object? v) {
  if (v is! Map) return null;
  double d(Object? x) {
    if (x is num) return x.toDouble();
    return double.tryParse('$x') ?? 0;
  }

  return BoxShadow(
    color: colorFromJson(v['color']) ?? const Color(0xFF000000),
    offset: Offset(d(v['dx']), d(v['dy'])),
    blurRadius: d(v['blur']),
    spreadRadius: d(v['spread']),
    blurStyle: switch (v['blurStyle']) {
      'solid' => BlurStyle.solid,
      'outer' => BlurStyle.outer,
      'inner' => BlurStyle.inner,
      _ => BlurStyle.normal,
    },
  );
}

/// JSON → BoxShadow 列表。
List<BoxShadow>? boxShadowListFromJson(Object? v) {
  if (v is! List) return null;
  final list = [for (final e in v) boxShadowFromJson(e)].nonNulls.toList();
  return list.isEmpty ? null : list;
}

/// JSON → Gradient（{kind:'linear'|'radial'|'sweep', colors, begin/end/center,
/// radius, stops}）。
Gradient? gradientFromJson(Map<String, dynamic>? json) {
  if (json == null) return null;
  final colors = (json['colors'] as List?)
      ?.map(colorFromJson)
      .nonNulls
      .toList();
  if (colors == null || colors.length < 2) return null;
  final stops = (json['stops'] as List?)
      ?.map((x) => x is num ? x.toDouble() : double.tryParse('$x'))
      .nonNulls
      .toList();
  double? radius() {
    final r = json['radius'];
    return r is num ? r.toDouble() : double.tryParse('$r');
  }

  return switch (json['kind']) {
    'radial' => RadialGradient(
        colors: colors,
        stops: stops,
        center: alignmentFromJson(json['center']) ?? Alignment.center,
        radius: radius() ?? 0.5,
      ),
    'sweep' => SweepGradient(
        colors: colors,
        stops: stops,
        center: alignmentFromJson(json['center']) ?? Alignment.center,
      ),
    _ => LinearGradient(
        colors: colors,
        stops: stops,
        begin: alignmentFromJson(json['begin']) ?? Alignment.centerLeft,
        end: alignmentFromJson(json['end']) ?? Alignment.centerRight,
      ),
  };
}

/// JSON → DecorationImage（{source, fit}）。
DecorationImage? decorationImageFromJson(Map<String, dynamic>? json) {
  if (json == null) return null;
  final source = json['source'];
  if (source is! String || source.isEmpty) return null;
  return DecorationImage(
    image: source.startsWith('http')
        ? NetworkImage(source)
        : AssetImage(source) as ImageProvider,
    fit: boxFitFromJson(json['fit']),
  );
}

/// JSON → BoxConstraints（{minWidth, maxWidth, minHeight, maxHeight}）。
BoxConstraints? boxConstraintsFromJson(Map<String, dynamic>? json) {
  if (json == null || json.isEmpty) return null;
  double? v(Object? x) {
    if (x is num) return x.toDouble();
    return double.tryParse('$x');
  }

  return BoxConstraints(
    minWidth: v(json['minWidth']) ?? 0,
    maxWidth: v(json['maxWidth']) ?? double.infinity,
    minHeight: v(json['minHeight']) ?? 0,
    maxHeight: v(json['maxHeight']) ?? double.infinity,
  );
}

/// JSON → OutlinedBorder（{kind:'rounded'|'stadium'|'circle'|'beveled'|
/// 'continuous', borderRadius?, side?}）。
OutlinedBorder? shapeFromJson(Object? v) {
  if (v is! Map) return null;
  final radius = borderRadiusFromJson(
    v['borderRadius'] is Map
        ? (v['borderRadius'] as Map).cast<String, dynamic>()
        : null,
  );
  final side = borderSideFromJson(v['side']) ?? BorderSide.none;
  return switch (v['kind']) {
    'stadium' => StadiumBorder(side: side),
    'circle' => CircleBorder(side: side),
    'beveled' => BeveledRectangleBorder(
        borderRadius: radius ?? BorderRadius.zero, side: side),
    'continuous' => ContinuousRectangleBorder(
        borderRadius: radius ?? BorderRadius.zero, side: side),
    _ => RoundedRectangleBorder(
        borderRadius: radius ?? BorderRadius.zero, side: side),
  };
}

/// JSON → ClipBehavior（'hardEdge'/'antiAlias'/'antiAliasWithSaveLayer'/'none'）。
Clip? clipBehaviorFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'hardEdge' => Clip.hardEdge,
    'antiAlias' => Clip.antiAlias,
    'antiAliasWithSaveLayer' => Clip.antiAliasWithSaveLayer,
    'none' => Clip.none,
    _ => null,
  };
}

/// JSON → StackFit（'loose'/'expand'/'passthrough'）。
StackFit? stackFitFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'loose' => StackFit.loose,
    'expand' => StackFit.expand,
    'passthrough' => StackFit.passthrough,
    _ => null,
  };
}

/// JSON → HitTestBehavior（'deferToChild'/'opaque'/'translucent'）。
HitTestBehavior? hitTestBehaviorFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'deferToChild' => HitTestBehavior.deferToChild,
    'opaque' => HitTestBehavior.opaque,
    'translucent' => HitTestBehavior.translucent,
    _ => null,
  };
}

/// JSON → ImageRepeat（'repeat'/'repeatX'/'repeatY'/'noRepeat'）。
ImageRepeat? imageRepeatFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'repeat' => ImageRepeat.repeat,
    'repeatX' => ImageRepeat.repeatX,
    'repeatY' => ImageRepeat.repeatY,
    'noRepeat' => ImageRepeat.noRepeat,
    _ => null,
  };
}

/// JSON → WrapAlignment。
WrapAlignment? wrapAlignmentFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'start' => WrapAlignment.start,
    'end' => WrapAlignment.end,
    'center' => WrapAlignment.center,
    'spaceBetween' => WrapAlignment.spaceBetween,
    'spaceAround' => WrapAlignment.spaceAround,
    'spaceEvenly' => WrapAlignment.spaceEvenly,
    _ => null,
  };
}

/// JSON → WrapCrossAlignment。
WrapCrossAlignment? wrapCrossAlignmentFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'start' => WrapCrossAlignment.start,
    'end' => WrapCrossAlignment.end,
    'center' => WrapCrossAlignment.center,
    _ => null,
  };
}

/// JSON → TextInputType。
TextInputType? textInputTypeFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'text' => TextInputType.text,
    'number' => TextInputType.number,
    'phone' => TextInputType.phone,
    'emailAddress' => TextInputType.emailAddress,
    'url' => TextInputType.url,
    'multiline' => TextInputType.multiline,
    'datetime' => TextInputType.datetime,
    'visiblePassword' => TextInputType.visiblePassword,
    _ => null,
  };
}

/// JSON → BlendMode（Image.colorBlendMode 用，覆盖常用混合模式）。
BlendMode? blendModeFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'modulate' => BlendMode.modulate,
    'multiply' => BlendMode.multiply,
    'screen' => BlendMode.screen,
    'overlay' => BlendMode.overlay,
    'darken' => BlendMode.darken,
    'lighten' => BlendMode.lighten,
    'srcIn' => BlendMode.srcIn,
    'srcATop' => BlendMode.srcATop,
    'colorDodge' => BlendMode.colorDodge,
    'colorBurn' => BlendMode.colorBurn,
    'hue' => BlendMode.hue,
    'saturation' => BlendMode.saturation,
    'color' => BlendMode.color,
    'luminosity' => BlendMode.luminosity,
    _ => null,
  };
}

/// JSON → ScrollPhysics（类名字符串）。
ScrollPhysics? scrollPhysicsFromJson(Object? v) {
  if (v is! String) return null;
  return switch (v) {
    'NeverScrollableScrollPhysics' => const NeverScrollableScrollPhysics(),
    'BouncingScrollPhysics' => const BouncingScrollPhysics(),
    'ClampingScrollPhysics' => const ClampingScrollPhysics(),
    'AlwaysScrollableScrollPhysics' => const AlwaysScrollableScrollPhysics(),
    _ => null,
  };
}

/// JSON → BoxDecoration（{color, borderRadius, border, boxShadow, gradient,
/// shape, image}）。
BoxDecoration? boxDecorationFromJson(Map<String, dynamic>? json) {
  if (json == null || json.isEmpty) return null;
  return BoxDecoration(
    color: colorFromJson(json['color']),
    borderRadius: borderRadiusFromJson(
      json['borderRadius'] is Map
          ? (json['borderRadius'] as Map).cast<String, dynamic>()
          : null,
    ),
    border: borderFromJson(
      json['border'] is Map
          ? (json['border'] as Map).cast<String, dynamic>()
          : null,
    ),
    boxShadow: boxShadowListFromJson(json['boxShadow']),
    gradient: gradientFromJson(
      json['gradient'] is Map
          ? (json['gradient'] as Map).cast<String, dynamic>()
          : null,
    ),
    shape: switch (json['shape']) {
      'circle' => BoxShape.circle,
      _ => BoxShape.rectangle,
    },
    image: decorationImageFromJson(
      json['image'] is Map
          ? (json['image'] as Map).cast<String, dynamic>()
          : null,
    ),
  );
}

/// JSON → IconData（'add'/'star'/...；未命中回退 Icons.circle）。
IconData iconFromJson(Object? v) {
  final name = v is String ? v : '';
  final icon = _icons[name];
  if (icon == null) {
    HotPatchLog.log('iconFromJson: 未注册的 Icons.$name，回退 Icons.circle');
    return Icons.circle;
  }
  return icon;
}

/// 常用 Material Icons 映射表（按需扩展；未命中回退 circle）。
const Map<String, IconData> _icons = {
  'add': Icons.add,
  'add_circle': Icons.add_circle,
  'arrow_back': Icons.arrow_back,
  'arrow_forward': Icons.arrow_forward,
  'arrow_drop_down': Icons.arrow_drop_down,
  'arrow_downward': Icons.arrow_downward,
  'arrow_upward': Icons.arrow_upward,
  'check': Icons.check,
  'check_box': Icons.check_box,
  'check_box_outline_blank': Icons.check_box_outline_blank,
  'check_circle': Icons.check_circle,
  'chevron_left': Icons.chevron_left,
  'chevron_right': Icons.chevron_right,
  'close': Icons.close,
  'create': Icons.create,
  'date_range': Icons.date_range,
  'delete': Icons.delete,
  'edit': Icons.edit,
  'email': Icons.email,
  'error': Icons.error,
  'exit_to_app': Icons.exit_to_app,
  'explore': Icons.explore,
  'face': Icons.face,
  'favorite': Icons.favorite,
  'favorite_border': Icons.favorite_border,
  'feedback': Icons.feedback,
  'filter_list': Icons.filter_list,
  'flag': Icons.flag,
  'folder': Icons.folder,
  'home': Icons.home,
  'info': Icons.info,
  'keyboard_arrow_down': Icons.keyboard_arrow_down,
  'launch': Icons.launch,
  'list': Icons.list,
  'location_on': Icons.location_on,
  'lock': Icons.lock,
  'lock_open': Icons.lock_open,
  'mail': Icons.mail,
  'menu': Icons.menu,
  'mic': Icons.mic,
  'more_vert': Icons.more_vert,
  'notifications': Icons.notifications,
  'pause': Icons.pause,
  'person': Icons.person,
  'phone': Icons.phone,
  'play_arrow': Icons.play_arrow,
  'refresh': Icons.refresh,
  'search': Icons.search,
  'send': Icons.send,
  'settings': Icons.settings,
  'share': Icons.share,
  'shopping_cart': Icons.shopping_cart,
  'star': Icons.star,
  'star_border': Icons.star_border,
  'thumb_up': Icons.thumb_up,
  'verified': Icons.verified,
  'visibility': Icons.visibility,
  'visibility_off': Icons.visibility_off,
  'volume_down': Icons.volume_down,
  'volume_up': Icons.volume_up,
  'warning': Icons.warning,
  'wifi': Icons.wifi,
};
