import 'package:flutter/material.dart';

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
    fontFamilyFallback: (json['fontFamilyFallback'] as List?)
        ?.map((x) => x.toString())
        .toList(),
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

/// JSON → BorderSide（{'color':..,'width':..}）。
BorderSide? borderSideFromJson(Object? v) {
  if (v is! Map) return null;
  final c = colorFromJson(v['color']);
  final w = (v['width'] as num?)?.toDouble();
  return BorderSide(
    color: c ?? const Color(0xFF000000),
    width: w ?? 1.0,
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
  return ButtonStyle(
    backgroundColor:
        bg == null ? null : WidgetStatePropertyAll<Color?>(bg),
    foregroundColor:
        fg == null ? null : WidgetStatePropertyAll<Color?>(fg),
    overlayColor:
        overlay == null ? null : WidgetStatePropertyAll<Color?>(overlay),
    iconColor: icon == null ? null : WidgetStatePropertyAll<Color?>(icon),
    shadowColor:
        shadow == null ? null : WidgetStatePropertyAll<Color?>(shadow),
    elevation: json['elevation'] == null
        ? null
        : WidgetStatePropertyAll<double?>(
            (json['elevation'] as num).toDouble()),
    padding: json['padding'] is Map
        ? WidgetStatePropertyAll<EdgeInsets?>(
            edgeInsetsFromJson((json['padding'] as Map).cast<String, dynamic>()))
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
    textStyle: json['textStyle'] is Map
        ? WidgetStatePropertyAll<TextStyle?>(
            textStyleFromJson((json['textStyle'] as Map).cast<String, dynamic>()))
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
    _ when v.startsWith('w') && v.length == 4 =>
      FontWeight.values.firstWhere(
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
Color? colorFromJson(Object? v) {
  if (v is! String) return null;
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

/// JSON → BorderRadius（{radius: n}）。
BorderRadius? borderRadiusFromJson(Map<String, dynamic>? json) {
  if (json == null) return null;
  final r = json['radius'];
  final radius = r is num ? r.toDouble() : double.tryParse('$r');
  if (radius == null) return null;
  return BorderRadius.circular(radius);
}

/// JSON → BoxDecoration（{color, borderRadius}）。
BoxDecoration? boxDecorationFromJson(Map<String, dynamic>? json) {
  if (json == null || json.isEmpty) return null;
  return BoxDecoration(
    color: colorFromJson(json['color']),
    borderRadius: borderRadiusFromJson(
      json['borderRadius'] is Map
          ? (json['borderRadius'] as Map).cast<String, dynamic>()
          : null,
    ),
  );
}

/// JSON → IconData（'add'/'star'/...；未命中回退 Icons.circle）。
IconData iconFromJson(Object? v) {
  final name = v is String ? v : '';
  final icon = _icons[name];
  if (icon == null) {
    debugPrint('[hot_patch] iconFromJson: 未注册的 Icons.$name，回退 Icons.circle');
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
