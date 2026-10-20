import 'package:analyzer/dart/ast/ast.dart';

import 'js_translator.dart';
import 'widget2js.dart';

// ===========================================================================
// Flutter 类 → JSON 的 toJson 工具集（生成器侧）
//
// 与 hot_patch 包的 flutter_from_json.dart 对称：
//   生成器：TextStyle/ButtonStyle/Colors/FontWeight … → JSON（JS 表达式字符串值）
//   运行时：同一份 JSON → 真实 Flutter 对象
//
// 解耦：样式翻译不放进 widget translator，避免一个文件越滚越大；
// 新增样式类 = 在这个文件加一个 xxxToJson + 在 widget translator 里调用。
// ===========================================================================

/// TextStyle(...) 构造 → JSON（叶子值 = JS 表达式字符串）。
///
/// 返回 null 表示不可翻译/未提供样式。
Map<String, dynamic>? textStyleToJson(
  Expression? expr,
  WidgetTranslateContext ctx,
) {
  if (expr == null) return null;
  final (ctor, args) = _ctorOfExpr(expr);
  if (ctor != 'TextStyle') return null;

  final map = <String, dynamic>{};
  for (final a in args) {
    if (a is! NamedExpression) continue;
    final name = a.name.label.name;
    final v = a.expression;
    switch (name) {
      case 'fontSize':
        final n = numLiteralJs(v);
        if (n != null) map['fontSize'] = n;
      case 'fontWeight':
        final w = _fontWeightExpr(v);
        if (w != null) map['fontWeight'] = w;
      case 'fontStyle':
        final s = _fontStyleExpr(v);
        if (s != null) map['fontStyle'] = s;
      case 'color':
        final c = translateColor(v, ctx);
        if (c != null) map['color'] = c;
      case 'letterSpacing':
        final n = numLiteralJs(v);
        if (n != null) map['letterSpacing'] = n;
      case 'height':
        final n = numLiteralJs(v);
        if (n != null) map['height'] = n;
      case 'fontFamily':
        if (v is SimpleStringLiteral) map['fontFamily'] = ctx.jsString(v.value);
      case 'wordSpacing':
        final n = numLiteralJs(v);
        if (n != null) map['wordSpacing'] = n;
      case 'backgroundColor':
        final c = translateColor(v, ctx);
        if (c != null) map['backgroundColor'] = c;
      case 'decoration':
        final d = enumName(v, 'TextDecoration');
        if (d != null) map['decoration'] = ctx.jsString(d);
      case 'decorationColor':
        final c = translateColor(v, ctx);
        if (c != null) map['decorationColor'] = c;
      case 'decorationStyle':
        final d = enumName(v, 'TextDecorationStyle');
        if (d != null) map['decorationStyle'] = ctx.jsString(d);
      case 'decorationThickness':
        final n = numLiteralJs(v);
        if (n != null) map['decorationThickness'] = n;
      case 'fontFamilyFallback':
        final list = _stringListExpr(v);
        if (list != null) map['fontFamilyFallback'] = list;
    }
  }
  return map.isEmpty ? null : map;
}

/// ElevatedButton.styleFrom(...) / ButtonStyle(...) → JSON。
///
/// 当前支持：backgroundColor / foregroundColor（WidgetStatePropertyAll 解包）。
/// 返回 null 表示未提供样式。
Map<String, dynamic>? buttonStyleToJson(
  Expression? expr,
  WidgetTranslateContext ctx,
) {
  if (expr == null) return null;
  final (ctor, args) = _ctorOfExpr(expr);
  final map = <String, dynamic>{};
  if (ctor == 'styleFrom' || ctor == 'ButtonStyle') {
    for (final a in args) {
      if (a is! NamedExpression) continue;
      final name = a.name.label.name;
      final v = a.expression;
      switch (name) {
        case 'backgroundColor':
          final c = translateColor(_unwrapWidgetState(v), ctx);
          if (c != null) map['backgroundColor'] = c;
        case 'foregroundColor':
          final c = translateColor(_unwrapWidgetState(v), ctx);
          if (c != null) map['foregroundColor'] = c;
        case 'overlayColor':
          final c = translateColor(_unwrapWidgetState(v), ctx);
          if (c != null) map['overlayColor'] = c;
        case 'iconColor':
          final c = translateColor(_unwrapWidgetState(v), ctx);
          if (c != null) map['iconColor'] = c;
        case 'shadowColor':
          final c = translateColor(v, ctx);
          if (c != null) map['shadowColor'] = c;
        case 'elevation':
          final n = numLiteralJs(v);
          if (n != null) map['elevation'] = n;
        case 'padding':
          final e = edgeInsetsToJson(v, ctx);
          if (e != null) map['padding'] = e;
        case 'minimumSize':
          final sz = _sizeExpr(v);
          if (sz != null) map['minimumSize'] = sz;
        case 'maximumSize':
          final sz = _sizeExpr(v);
          if (sz != null) map['maximumSize'] = sz;
        case 'side':
          final sd = borderSideToJson(v, ctx);
          if (sd != null) map['side'] = sd;
        case 'shape':
          final sh = shapeToJson(v, ctx);
          if (sh != null) map['shape'] = sh;
        case 'fixedSize':
          final sz = _sizeExpr(v);
          if (sz != null) map['fixedSize'] = sz;
        case 'disabledBackgroundColor':
          final c = translateColor(v, ctx);
          if (c != null) map['disabledBackgroundColor'] = c;
        case 'disabledForegroundColor':
          final c = translateColor(v, ctx);
          if (c != null) map['disabledForegroundColor'] = c;
        case 'textStyle':
          final t = textStyleToJson(v, ctx);
          if (t != null) map['textStyle'] = t;
        case 'alignment':
          final al = enumName(v, 'Alignment');
          if (al != null) map['alignment'] = ctx.jsString(al);
        case 'visualDensity':
          final d = enumName(v, 'VisualDensity');
          if (d != null) map['visualDensity'] = ctx.jsString(d);
        case 'enableFeedback':
          final b = boolLiteralJs(v);
          if (b != null) map['enableFeedback'] = b;
      }
    }
  }
  return map.isEmpty ? null : map;
}

// ---------------------------------------------------------------------------
// 基础表达式解析（样式专用，值一律输出 JS 表达式字符串）
// ---------------------------------------------------------------------------

/// FontWeight.bold / FontWeight.w500 → '"bold"' / '"w500"'（JS 字符串字面量）。
String? _fontWeightExpr(Expression e) {
  final (owner, name) = _staticRef(e);
  if (owner != 'FontWeight' || name == null) return null;
  // 形态：FontWeight.bold / FontWeight.w500
  return switch (name) {
    'bold' => '"bold"',
    'normal' => '"normal"',
    _ when name.startsWith('w') && name.length == 4 => '"$name"', // w100..w900
    _ => null,
  };
}

/// FontStyle.italic / FontStyle.normal → '"italic"' / '"normal"'。
String? _fontStyleExpr(Expression e) {
  final (owner, name) = _staticRef(e);
  if (owner != 'FontStyle') return null;
  return name == null ? null : '"$name"';
}

/// Colors.red → '#F44336'；Color(0xFF112233) → '#112233'；Colors.white/black。
/// 跨文件静态单例类字段引用（MyColors.background）→ JS 表达式
/// 'MyColors.background'（不带引号，jsLiteral 原样输出）。
String? translateColor(Expression e, WidgetTranslateContext ctx) {
  // Color(0xFF...)
  final (ctor, args) = _ctorOfExpr(e);
  if (ctor == 'Color') {
    for (final a in args) {
      if (a is IntegerLiteral) {
        final v = a.value;
        if (v == null) return null;
        final hex = v.toRadixString(16).padLeft(8, '0');
        return "'#$hex'";
      }
      if (a is MethodInvocation && a.methodName.name == 'fromARGB') {
        // Color.fromARGB(a, r, g, b)
        final ints = a.argumentList.arguments
            .whereType<IntegerLiteral>()
            .map((x) => x.value)
            .whereType<int>()
            .toList();
        if (ints.length == 4) {
          final hex = ints
              .map((x) => x.clamp(0, 255).toRadixString(16).padLeft(2, '0'))
              .join();
          return "'#$hex'";
        }
      }
    }
    return null;
  }
  // Colors.red（静态引用）：主色板表与通用表达式层共用同一份。
  final (owner, name) = _staticRef(e);
  if (owner == 'Colors') {
    final hex = materialColorHex(name ?? '');
    if (hex != null) return "'#$hex'";
    return null;
  }
  // Colors.blue.shade100 等 MaterialColor 变体：**编译期**按 Material 色板表
  // 算成 '#RRGGBB'（见 [materialShadeHex]），产物里不再有 '@Colors…' 标记。
  if (owner != null && owner.startsWith('Colors.')) {
    final shade = shadeIndex(name ?? '');
    if (shade != null) {
      final hex = materialShadeHex(owner.substring('Colors.'.length), shade);
      if (hex != null) return "'#$hex'";
    }
    return null;
  }
  // 跨文件静态单例类字段引用（MyColors.background）→ JS 表达式
  final singleton = ctx.singletons?.staticRef(e);
  if (singleton != null) return singleton;
  // 三目（isAdult ? MyColors.adult : MyColors.background）→ JS 三目表达式
  if (e is ConditionalExpression) {
    final condJs = ctx.jsDataExpr(e.condition);
    final thenJs = translateColor(e.thenExpression, ctx);
    final elseJs = translateColor(e.elseExpression, ctx);
    if (thenJs == null || elseJs == null) return null;
    return '($condJs ? $thenJs : $elseJs)';
  }
  // 具名颜色常量（`kBrand` / `kPrice` / `_menuTints`）：常量在产物里已经译成
  // 色值字符串（同文件内联 / 跨文件 import），直接引用同名 JS 常量即可。
  if (e is SimpleIdentifier && ctx.globalConsts.contains(e.name)) {
    return e.name;
  }
  // 常量颜色表索引（`_menuTints[i % _menuTints.length]`）：常量表在产物顶部是
  // 「颜色字符串数组」（值已是色值契约里的字符串），索引取值直接产出 JS 索引
  // 表达式即可，无需在 JS 侧再翻译颜色。
  if (e is IndexExpression && e.target is SimpleIdentifier) {
    final name = (e.target as SimpleIdentifier).name;
    if (ctx.globalConsts.contains(name)) {
      return '$name[${ctx.jsDataExpr(e.index)}]';
    }
  }
  return null;
}

/// WidgetStatePropertyAll(color) 解包（ButtonStyle 里常用）。
Expression _unwrapWidgetState(Expression e) {
  final (ctor, args) = _ctorOfExpr(e);
  if (ctor == 'WidgetStatePropertyAll' || ctor == 'MaterialStatePropertyAll') {
    final pos = args.whereType<Expression>().toList();
    if (pos.isNotEmpty) return pos.first;
  }
  return e;
}

/// 静态引用：`Colors.red` / `FontWeight.bold` → (owner, name)。
(String?, String?) _staticRef(Expression e) {
  if (e is PropertyAccess) {
    final target = e.target;
    if (target == null) return (null, null);
    return (target.toSource(), e.propertyName.name);
  }
  if (e is MethodInvocation &&
      e.target != null &&
      e.argumentList.arguments.isEmpty) {
    return (e.target!.toSource(), e.methodName.name);
  }
  if (e is PrefixedIdentifier) {
    return (e.prefix.toSource(), e.identifier.name);
  }
  return (null, null);
}

/// 构造调用：`Foo(...)` / `Foo.bar(...)` 统一取构造名与参数。
(String?, List<Expression>) _ctorOfExpr(Expression e) {
  if (e is InstanceCreationExpression) {
    return (
      e.constructorName.type.name2.lexeme,
      e.argumentList.arguments.toList(),
    );
  }
  if (e is MethodInvocation) {
    return (e.methodName.name, e.argumentList.arguments.toList());
  }
  return (null, const []);
}

/// Material 主色板（500 档）→ hex 表已收敛到通用表达式层（js_translator.dart
/// 的 [materialColors]），样式翻译与数据表达式共用同一份，见 [materialColorHex]。

// ---------------------------------------------------------------------------
// 新增辅助 toJson（ButtonStyle 扩展 / Text 属性扩展共用）
// ---------------------------------------------------------------------------

/// 静态枚举引用：`TextOverflow.ellipsis` → 'ellipsis'；非该枚举返回 null。
String? enumName(Expression e, String owner) {
  final (o, name) = _staticRef(e);
  if (o != owner || name == null) return null;
  return name;
}

/// Size(w, h) → {'width': '..', 'height': '..'}（叶子值 = JS 数字表达式）。
Map<String, dynamic>? _sizeExpr(Expression e) {
  final (ctor, args) = _ctorOfExpr(e);
  if (ctor != 'Size') return null;
  final pos = args.whereType<Expression>().toList();
  if (pos.length < 2) return null;
  final w = numLiteralJs(pos[0]);
  final h = numLiteralJs(pos[1]);
  if (w == null || h == null) return null;
  return {'width': w, 'height': h};
}

/// BorderSide 字段（color/width/style）的一串具名实参 → JSON map。
/// `BorderSide(...)` 与 `Border.all(...)` 字段一致，共用这一处解析。
Map<String, dynamic> _borderSideProps(
  List<Expression> args,
  WidgetTranslateContext ctx,
) {
  final map = <String, dynamic>{};
  for (final a in args) {
    if (a is! NamedExpression) continue;
    final v = a.expression;
    switch (a.name.label.name) {
      case 'color':
        final c = translateColor(v, ctx);
        if (c != null) map['color'] = c;
      case 'width':
        final n = numLiteralJs(v);
        if (n != null) map['width'] = n;
      case 'style':
        final s = enumName(v, 'BorderStyle');
        if (s != null) map['style'] = ctx.jsString(s);
    }
  }
  return map;
}

/// BorderSide(color: ..., width: ..., style: ...) → {'color': c, 'width': n, 'style': s}。
Map<String, dynamic>? borderSideToJson(Expression e, WidgetTranslateContext ctx) {
  final (ctor, args) = _ctorOfExpr(e);
  if (ctor != 'BorderSide') return null;
  final map = _borderSideProps(args, ctx);
  return map.isEmpty ? null : map;
}

/// 字符串列表（fontFamilyFallback: ['A', 'B']）→ JS 数组表达式。
String? _stringListExpr(Expression e) {
  if (e is! ListLiteral) return null;
  final items = <String>[];
  for (final el in e.elements) {
    if (el is SimpleStringLiteral) items.add(jsString(el.value));
  }
  if (items.isEmpty) return null;
  return '[${items.join(', ')}]';
}

// ---------------------------------------------------------------------------
// 布局/内容类 toJson（Container/Padding/Align/Stack/Icon/Image 等复用）
// ---------------------------------------------------------------------------

/// TextScaler.noScaling → '"noScaling"'；TextScaler.linear(2.0) → {'linear': '2.0'}。
Object? textScalerToJson(Expression e) {
  final (ctor, args) = _ctorOfExpr(e);
  if (ctor == 'linear') {
    final pos = args.whereType<Expression>().toList();
    if (pos.isNotEmpty) {
      final n = numLiteralJs(pos.first);
      if (n != null) return {'linear': n};
    }
    return null;
  }
  // TextScaler.noScaling：静态引用
  final (owner, name) = _staticRef(e);
  if (owner == 'TextScaler' && name == 'noScaling') return '"noScaling"';
  return null;
}

/// EdgeInsets.all/symmetric/only/fromLTRB → JSON {left,top,right,bottom}。
/// 返回 null 表示不可翻译/未提供。
Map<String, dynamic>? edgeInsetsToJson(
  Expression? expr,
  WidgetTranslateContext ctx,
) {
  if (expr == null) return null;
  final (ctor, args) = _ctorOfExpr(expr);
  // EdgeInsets.all/symmetric/only/fromLTRB 是静态方法调用（MethodInvocation），
  // EdgeInsets(...) 直接构造是 InstanceCreationExpression。
  if (ctor != 'EdgeInsets' &&
      ctor != 'all' &&
      ctor != 'symmetric' &&
      ctor != 'only' &&
      ctor != 'fromLTRB') {
    return null;
  }
  final map = <String, dynamic>{};
  double? l, t, r, b;
  // EdgeInsets.all(8)
  final pos = args.whereType<Expression>().toList();
  if (pos.isNotEmpty) {
    final n = numLiteralJs(pos.first);
    if (n != null) {
      l = t = r = b = double.tryParse(n);
    }
  }
  // EdgeInsets.symmetric / only：命名参数
  for (final a in args) {
    if (a is! NamedExpression) continue;
    final n = numLiteralJs(a.expression);
    if (n == null) continue;
    final v = double.tryParse(n);
    if (v == null) continue;
    switch (a.name.label.name) {
      case 'left': l = v;
      case 'top': t = v;
      case 'right': r = v;
      case 'bottom': b = v;
      case 'horizontal': l = r = v;
      case 'vertical': t = b = v;
    }
  }
  // EdgeInsets.fromLTRB(l, t, r, b)：4 个位置参数
  if (pos.length == 4) {
    final nums = pos.map((e) {
      final n = numLiteralJs(e);
      return n == null ? null : double.tryParse(n);
    }).toList();
    if (nums.every((x) => x != null)) {
      l = nums[0]; t = nums[1]; r = nums[2]; b = nums[3];
    }
  }
  if (l == null && t == null && r == null && b == null) return null;
  map['left'] = '${l ?? 0}';
  map['top'] = '${t ?? 0}';
  map['right'] = '${r ?? 0}';
  map['bottom'] = '${b ?? 0}';
  return map;
}

/// SliverGridDelegateWithFixedCrossAxisCount / ...WithMaxCrossAxisExtent → JSON。
///
/// `gridDelegate:` 是**结构化值**（不是子结点）：不转 JSON 就会落进「类名构造 →
/// 子结点」分支，产物变成 `__h('SliverGridDelegateWith…', …)` 结点，运行时
/// `_gridDelegateFromJson` 读不到 crossAxisCount / maxCrossAxisExtent（GridView /
/// SliverGrid 退化成单列）。返回 null 表示不可翻译/未提供。
Map<String, dynamic>? gridDelegateToJson(
  Expression? expr,
  WidgetTranslateContext ctx,
) {
  if (expr == null) return null;
  final (ctor, args) = _ctorOfExpr(expr);
  if (ctor != 'SliverGridDelegateWithFixedCrossAxisCount' &&
      ctor != 'SliverGridDelegateWithMaxCrossAxisExtent') {
    return null;
  }
  final map = <String, dynamic>{};
  for (final a in args) {
    if (a is! NamedExpression) continue;
    switch (a.name.label.name) {
      case 'crossAxisCount':
      case 'maxCrossAxisExtent':
      case 'mainAxisSpacing':
      case 'crossAxisSpacing':
      case 'childAspectRatio':
      case 'mainAxisExtent':
        final n = numLiteralJs(a.expression);
        if (n != null) map[a.name.label.name] = n;
    }
  }
  return map.isEmpty ? null : map;
}

/// Alignment.center/topLeft/... → '"center"' 等（运行时 alignmentFromJson）。
String? alignmentToJson(Expression? expr, WidgetTranslateContext ctx) {
  if (expr == null) return null;
  final (owner, name) = _staticRef(expr);
  if (owner != 'Alignment' || name == null) return null;
  return '"$name"';
}

/// MainAxisAlignment.start/center/spaceBetween → '"start"' 等。
String? mainAxisAlignmentToJson(Expression? expr) {
  if (expr == null) return null;
  final (owner, name) = _staticRef(expr);
  if (owner != 'MainAxisAlignment' || name == null) return null;
  return '"$name"';
}

/// CrossAxisAlignment.start/center/stretch → '"start"' 等。
String? crossAxisAlignmentToJson(Expression? expr) {
  if (expr == null) return null;
  final (owner, name) = _staticRef(expr);
  if (owner != 'CrossAxisAlignment' || name == null) return null;
  return '"$name"';
}

/// MainAxisSize.min/max → '"min"' / '"max"'。
String? mainAxisSizeToJson(Expression? expr) {
  if (expr == null) return null;
  final (owner, name) = _staticRef(expr);
  if (owner != 'MainAxisSize' || name == null) return null;
  return '"$name"';
}

/// Axis.horizontal/vertical → '"horizontal"' / '"vertical"'。
String? axisToJson(Expression? expr) {
  if (expr == null) return null;
  final (owner, name) = _staticRef(expr);
  if (owner != 'Axis' || name == null) return null;
  return '"$name"';
}

/// BoxFit.cover/contain/... → '"cover"' 等。
String? boxFitToJson(Expression? expr) {
  if (expr == null) return null;
  final (owner, name) = _staticRef(expr);
  if (owner != 'BoxFit' || name == null) return null;
  return '"$name"';
}

/// Icons.add/star/... → '"add"' / '"star"'（运行时 iconFromJson 映射）。
String? iconDataToJson(Expression? expr) {
  if (expr == null) return null;
  final (owner, name) = _staticRef(expr);
  if (owner != 'Icons' || name == null) return null;
  return '"$name"';
}

/// `Offset(dx, dy)` → `{ "dx": <js>, "dy": <js> }`（Transform.translate 用；
/// 运行时 offsetFromJson 组装 Offset）。
String? offsetExprToJson(Expression? expr) {
  if (expr == null) return null;
  final (ctor, args) = _ctorOfExpr(expr);
  if (ctor != 'Offset') return null;
  final pos = args.whereType<Expression>().toList();
  if (pos.length < 2) return null;
  final dx = numLiteralJs(pos[0]);
  final dy = numLiteralJs(pos[1]);
  if (dx == null || dy == null) return null;
  return '{ "dx": $dx, "dy": $dy }';
}

/// BorderRadius.circular(8) / BorderRadius.all(Radius.circular(8)) /
/// BorderRadius.only(topLeft: Radius.circular(8), ...) → JSON。
/// 统一圆角 → {'radius': n}；四角独立 → {'topLeft': n, 'topRight': n, ...}
/// （缺省角 = 0，运行时按边角名组装 BorderRadius.only）。
Map<String, dynamic>? borderRadiusToJson(
  Expression? expr,
  WidgetTranslateContext ctx,
) {
  if (expr == null) return null;
  final (ctor, args) = _ctorOfExpr(expr);
  // BorderRadius.circular/all/only 是静态方法调用。
  if (ctor != 'BorderRadius' && ctor != 'circular' && ctor != 'all' && ctor != 'only') {
    return null;
  }
  // BorderRadius.only(topLeft: Radius.circular(8), ...)：四角独立
  if (ctor == 'only') {
    final map = <String, dynamic>{};
    for (final a in args) {
      if (a is! NamedExpression) continue;
      final corner = a.name.label.name;
      if (corner != 'topLeft' && corner != 'topRight' &&
          corner != 'bottomLeft' && corner != 'bottomRight') {
        continue;
      }
      final n = _radiusValue(a.expression);
      if (n != null) map[corner] = n;
    }
    return map.isEmpty ? null : map;
  }
  double? radius;
  // BorderRadius.circular(8)：裸数字字面量；
  // BorderRadius.all(Radius.circular(8))：首个位置参数是 Radius，需解包。
  if (args.isNotEmpty) {
    final first = args.whereType<Expression>().first;
    final n = numLiteralJs(first) ?? _radiusValue(first);
    if (n != null) radius = double.tryParse(n);
  }
  // BorderRadius.all(Radius.circular(8)) 的防御性兜底（正常走上面的解包）
  for (final a in args) {
    if (a is! NamedExpression || a.name.label.name != 'all') continue;
    final n = _radiusValue(a.expression);
    if (n != null) radius = double.tryParse(n);
  }
  if (radius == null) return null;
  return {'radius': '$radius'};
}

/// Radius.circular(8) → '8'；裸数字字面量 → '8'。
String? _radiusValue(Expression e) {
  final n = numLiteralJs(e);
  if (n != null) return n;
  final (ctor, args) = _ctorOfExpr(e);
  if (ctor == 'Radius' || ctor == 'circular') {
    final pos = args.whereType<Expression>().toList();
    if (pos.isNotEmpty) return numLiteralJs(pos.first);
  }
  return null;
}

/// Colors.xxx / Color(0x...) → JS 字符串字面量（'#RRGGBB' / '#AARRGGBB'）。
/// 公共包装：widget translator 直接调用；内部实现在 [translateColor]。
String? colorToJson(Expression? expr, WidgetTranslateContext ctx) {
  if (expr == null) return null;
  return translateColor(expr, ctx);
}

/// BoxDecoration(color/borderRadius/border/boxShadow/gradient/shape/image) → JSON。
Map<String, dynamic>? boxDecorationToJson(
  Expression? expr,
  WidgetTranslateContext ctx,
) {
  if (expr == null) return null;
  final (ctor, args) = _ctorOfExpr(expr);
  if (ctor != 'BoxDecoration') return null;
  final map = <String, dynamic>{};
  for (final a in args) {
    if (a is! NamedExpression) continue;
    final v = a.expression;
    switch (a.name.label.name) {
      case 'color':
        final c = translateColor(v, ctx);
        if (c != null) map['color'] = c;
      case 'borderRadius':
        final br = borderRadiusToJson(v, ctx);
        if (br != null) map['borderRadius'] = br;
      case 'border':
        final b = borderToJson(v, ctx);
        if (b != null) map['border'] = b;
      case 'boxShadow':
        final s = boxShadowListToJson(v, ctx);
        if (s != null) map['boxShadow'] = s;
      case 'gradient':
        final g = gradientToJson(v, ctx);
        if (g != null) map['gradient'] = g;
      case 'shape':
        final s = enumName(v, 'BoxShape');
        if (s != null) map['shape'] = ctx.jsString(s);
      case 'image':
        final img = decorationImageToJson(v, ctx);
        if (img != null) map['image'] = img;
    }
  }
  return map.isEmpty ? null : map;
}

/// Border.all(color:, width:, style:) / Border.fromBorderSide(BorderSide(...)) /
/// Border(top:, right:, bottom:, left:) → JSON。
/// 四边统一 → {'all': borderSide}；四边独立 → {'top': ..., 'right': ...}。
Map<String, dynamic>? borderToJson(
  Expression? expr,
  WidgetTranslateContext ctx,
) {
  if (expr == null) return null;
  final (ctor, args) = _ctorOfExpr(expr);
  // Border.all(...)：color/width/style 直接生成统一边
  if (ctor == 'all') {
    final side = _borderSideProps(args, ctx);
    return side.isEmpty ? null : {'all': side};
  }
  if (ctor == 'Border' || ctor == 'fromBorderSide') {
    // Border.fromBorderSide(BorderSide(...)) → 四边统一
    final pos = args.whereType<Expression>().toList();
    if (pos.isNotEmpty) {
      final side = borderSideToJson(pos.first, ctx);
      if (side != null) return {'all': side};
    }
    // Border(top:, right:, bottom:, left:)：四边独立
    final map = <String, dynamic>{};
    for (final a in args) {
      if (a is! NamedExpression) continue;
      final edge = a.name.label.name;
      if (edge != 'top' && edge != 'right' && edge != 'bottom' && edge != 'left') {
        continue;
      }
      final side = borderSideToJson(a.expression, ctx);
      if (side != null) map[edge] = side;
    }
    return map.isEmpty ? null : map;
  }
  return null;
}

/// BoxShadow 列表（boxShadow: [BoxShadow(...), ...]）→ JSON 数组：
/// [{'color': c, 'dx': n, 'dy': n, 'blur': n, 'spread': n, 'blurStyle': s}, ...]。
/// 元素也支持 BoxShadow 作为 const 构造（InstanceCreationExpression）。
List<Map<String, dynamic>>? boxShadowListToJson(
  Expression? expr,
  WidgetTranslateContext ctx,
) {
  if (expr is! ListLiteral) return null;
  final list = <Map<String, dynamic>>[];
  for (final el in expr.elements) {
    if (el is! Expression) continue;
    final s = boxShadowToJson(el, ctx);
    if (s != null) list.add(s);
  }
  return list.isEmpty ? null : list;
}

/// 单个 BoxShadow(color:, offset: Offset(dx, dy), blurRadius:, spreadRadius:,
/// blurStyle:) → JSON。
Map<String, dynamic>? boxShadowToJson(Expression e, WidgetTranslateContext ctx) {
  final (ctor, args) = _ctorOfExpr(e);
  if (ctor != 'BoxShadow') return null;
  final map = <String, dynamic>{};
  for (final a in args) {
    if (a is! NamedExpression) continue;
    final v = a.expression;
    switch (a.name.label.name) {
      case 'color':
        final c = translateColor(v, ctx);
        if (c != null) map['color'] = c;
      case 'offset':
        final (oCtor, oArgs) = _ctorOfExpr(v);
        if (oCtor == 'Offset') {
          final pos = oArgs.whereType<Expression>().toList();
          if (pos.length >= 2) {
            final dx = numLiteralJs(pos[0]);
            final dy = numLiteralJs(pos[1]);
            if (dx != null) map['dx'] = dx;
            if (dy != null) map['dy'] = dy;
          }
        }
      case 'blurRadius':
        final n = numLiteralJs(v);
        if (n != null) map['blur'] = n;
      case 'spreadRadius':
        final n = numLiteralJs(v);
        if (n != null) map['spread'] = n;
      case 'blurStyle':
        final s = enumName(v, 'BlurStyle');
        if (s != null) map['blurStyle'] = ctx.jsString(s);
    }
  }
  return map.isEmpty ? null : map;
}

/// LinearGradient / RadialGradient / SweepGradient → JSON：
/// {kind:'linear', colors:[...], begin:'topLeft', end:'bottomRight', stops:[...]}
/// {kind:'radial', colors:[...], center:'center', radius:0.8, stops:[...]}
/// 注意用 kind 而不是 type：jsLiteral 把含 type 键的 Map 当 widget 节点渲染。
Map<String, dynamic>? gradientToJson(
  Expression? expr,
  WidgetTranslateContext ctx,
) {
  if (expr == null) return null;
  final (ctor, args) = _ctorOfExpr(expr);
  final kind = switch (ctor) {
    'LinearGradient' => 'linear',
    'RadialGradient' => 'radial',
    'SweepGradient' => 'sweep',
    _ => null,
  };
  if (kind == null) return null;
  final map = <String, dynamic>{'kind': ctx.jsString(kind)};
  for (final a in args) {
    if (a is! NamedExpression) continue;
    final v = a.expression;
    switch (a.name.label.name) {
      case 'colors':
        if (v is ListLiteral) {
          final colors = <String>[];
          for (final el in v.elements) {
            if (el is! Expression) continue;
            final c = translateColor(el, ctx);
            if (c != null) colors.add(c);
          }
          if (colors.isNotEmpty) map['colors'] = colors;
        }
      case 'stops':
        if (v is ListLiteral) {
          final stops = <String>[];
          for (final el in v.elements) {
            if (el is! Expression) continue;
            final n = numLiteralJs(el);
            if (n != null) stops.add(n);
          }
          if (stops.isNotEmpty) map['stops'] = stops;
        }
      case 'begin':
      case 'end':
      case 'center':
        final al = alignmentToJson(v, ctx);
        if (al != null) map[a.name.label.name] = al;
      case 'radius':
        final n = numLiteralJs(v);
        if (n != null) map['radius'] = n;
    }
  }
  return map['colors'] == null ? null : map;
}

/// DecorationImage(image: NetworkImage/AssetImage(...), fit:) → {source, fit}。
Map<String, dynamic>? decorationImageToJson(
  Expression? expr,
  WidgetTranslateContext ctx,
) {
  if (expr == null) return null;
  final (ctor, args) = _ctorOfExpr(expr);
  if (ctor != 'DecorationImage') return null;
  final map = <String, dynamic>{};
  for (final a in args) {
    if (a is! NamedExpression) continue;
    final v = a.expression;
    switch (a.name.label.name) {
      case 'image':
        final s = imageSourceToJson(v, ctx);
        if (s != null) map['source'] = s;
      case 'fit':
        final f = boxFitToJson(v);
        if (f != null) map['fit'] = f;
    }
  }
  return map['source'] == null ? null : map;
}

/// BoxConstraints(minWidth:, maxWidth:, minHeight:, maxHeight:) /
/// BoxConstraints.tightFor(width:, height:) → JSON（值需数字字面量）。
Map<String, dynamic>? boxConstraintsToJson(
  Expression? expr,
  WidgetTranslateContext ctx,
) {
  if (expr == null) return null;
  final (ctor, args) = _ctorOfExpr(expr);
  if (ctor != 'BoxConstraints' && ctor != 'tightFor' && ctor != 'expand') {
    return null;
  }
  final map = <String, dynamic>{};
  for (final a in args) {
    if (a is! NamedExpression) continue;
    final v = a.expression;
    final n = numLiteralJs(v);
    if (n == null) continue;
    switch (a.name.label.name) {
      case 'minWidth':
      case 'maxWidth':
      case 'minHeight':
      case 'maxHeight':
        map[a.name.label.name] = n;
      // BoxConstraints.tightFor(width:, height:)：等价 min=max
      case 'width':
        map['minWidth'] = n;
        map['maxWidth'] = n;
      case 'height':
        map['minHeight'] = n;
        map['maxHeight'] = n;
    }
  }
  return map.isEmpty ? null : map;
}

/// 形状（ButtonStyle.shape / Card.shape / Chip.shape / ListTile.shape）：
/// RoundedRectangleBorder(borderRadius:, side:) → {kind:'rounded', ...}
/// StadiumBorder(side:) → {kind:'stadium', ...}
/// CircleBorder(side:) → {kind:'circle', ...}
Map<String, dynamic>? shapeToJson(
  Expression? expr,
  WidgetTranslateContext ctx,
) {
  if (expr == null) return null;
  final (ctor, args) = _ctorOfExpr(expr);
  final kind = switch (ctor) {
    'RoundedRectangleBorder' => 'rounded',
    'StadiumBorder' => 'stadium',
    'CircleBorder' => 'circle',
    'BeveledRectangleBorder' => 'beveled',
    'ContinuousRectangleBorder' => 'continuous',
    _ => null,
  };
  if (kind == null) return null;
  final map = <String, dynamic>{'kind': ctx.jsString(kind)};
  for (final a in args) {
    if (a is! NamedExpression) continue;
    final v = a.expression;
    switch (a.name.label.name) {
      case 'borderRadius':
        final br = borderRadiusToJson(v, ctx);
        if (br != null) map['borderRadius'] = br;
      case 'side':
        final sd = borderSideToJson(v, ctx);
        if (sd != null) map['side'] = sd;
    }
  }
  return map;
}

/// ClipBehavior 枚举（clipBehavior 参数通用）：Clip.hardEdge → 'hardEdge'。
String? clipBehaviorToJson(Expression? expr) {
  if (expr == null) return null;
  final (owner, name) = _staticRef(expr);
  if (owner != 'Clip' || name == null) return null;
  return '"$name"';
}

/// TabBarIndicatorSize.tab/label → 字符串。
String? tabBarIndicatorSizeToJson(Expression? expr) {
  if (expr == null) return null;
  final (owner, name) = _staticRef(expr);
  if (owner != 'TabBarIndicatorSize' || name == null) return null;
  return '"$name"';
}

/// TabAlignment 枚举（start/startOffset/fill/center）→ 字符串。
String? tabAlignmentToJson(Expression? expr) {
  if (expr == null) return null;
  final (owner, name) = _staticRef(expr);
  if (owner != 'TabAlignment' || name == null) return null;
  return '"$name"';
}

/// StackFit.loose/expand/passthrough → 字符串。
String? stackFitToJson(Expression? expr) {
  if (expr == null) return null;
  final (owner, name) = _staticRef(expr);
  if (owner != 'StackFit' || name == null) return null;
  return '"$name"';
}

/// HitTestBehavior.deferToChild/opaque/translucent → 字符串。
String? hitTestBehaviorToJson(Expression? expr) {
  if (expr == null) return null;
  final (owner, name) = _staticRef(expr);
  if (owner != 'HitTestBehavior' || name == null) return null;
  return '"$name"';
}

/// ImageRepeat.repeat/repeatX/repeatY/noRepeat → 字符串。
String? imageRepeatToJson(Expression? expr) {
  if (expr == null) return null;
  final (owner, name) = _staticRef(expr);
  if (owner != 'ImageRepeat' || name == null) return null;
  return '"$name"';
}

/// WrapAlignment.start/end/center/spaceBetween/spaceAround/spaceEvenly → 字符串。
String? wrapAlignmentToJson(Expression? expr) {
  if (expr == null) return null;
  final (owner, name) = _staticRef(expr);
  if (owner != 'WrapAlignment' || name == null) return null;
  return '"$name"';
}

/// WrapCrossAlignment.start/end/center → 字符串。
String? wrapCrossAlignmentToJson(Expression? expr) {
  if (expr == null) return null;
  final (owner, name) = _staticRef(expr);
  if (owner != 'WrapCrossAlignment' || name == null) return null;
  return '"$name"';
}

/// TextInputType.text/number/phone/emailAddress/... → 字符串。
String? textInputTypeToJson(Expression? expr) {
  if (expr == null) return null;
  final (owner, name) = _staticRef(expr);
  if (owner != 'TextInputType' || name == null) return null;
  return '"$name"';
}

/// BlendMode.modulate/multiply/... → 字符串（Image.colorBlendMode 用）。
String? blendModeToJson(Expression? expr) {
  if (expr == null) return null;
  final (owner, name) = _staticRef(expr);
  if (owner != 'BlendMode' || name == null) return null;
  return '"$name"';
}

/// ScrollPhysics 构造（NeverScrollableScrollPhysics() 等）→ 类名字符串。
String? scrollPhysicsToJson(Expression? expr) {
  if (expr == null) return null;
  final (ctor, _) = _ctorOfExpr(expr);
  const known = {
    'NeverScrollableScrollPhysics',
    'AlwaysScrollableScrollPhysics',
    'BouncingScrollPhysics',
    'ClampingScrollPhysics',
  };
  if (ctor == null || !known.contains(ctor)) return null;
  return '"$ctor"';
}

/// Image 源：AssetImage('x') / NetworkImage('url') / Image.asset / Image.network
/// → source 字符串（运行时 imageFromJson 选择资源/网络）。
///
/// 位置参数既可以是字符串字面量，也可以是**任意可翻译表达式**
/// （`Image.network(spot.img)` / `Image.network('$base/$id')`）——后者输出
/// 该表达式的 JS 源码，运行时求值即 URL/资源路径。
String? imageSourceToJson(Expression? expr, WidgetTranslateContext ctx) {
  if (expr == null) return null;
  // 直接收到路径字符串：Image.network('url') / Image.asset('path') 的位置参数
  if (expr is SimpleStringLiteral) return ctx.jsString(expr.value);
  final (ctor, args) = _ctorOfExpr(expr);
  if (ctor == 'AssetImage' || ctor == 'NetworkImage') {
    final first = _firstPositional(args);
    return first == null ? null : _imageSourceArg(first, ctx);
  }
  // Image.asset('x') / Image.network('url')：methodName=asset/network，target=Image
  if (ctor == 'asset' || ctor == 'network') {
    final first = _firstPositional(args);
    return first == null ? null : _imageSourceArg(first, ctx);
  }
  // 其余情况：ImageTranslator 传进来的就是**源实参本身**
  // （`Image.network(spot.img)` 的位置参数是 `spot.img`，不是 `Image.network(...)`），
  // 按任意可翻译表达式输出其 JS 源码；翻译不出返回 null 由调用方报错。
  return _imageSourceArg(expr, ctx);
}

/// 第一个**位置**实参（具名实参不参与；AssetImage/Image.network 的源都是位置参数）。
Expression? _firstPositional(List<Expression> args) {
  for (final a in args) {
    if (a is NamedExpression) continue;
    return a;
  }
  return null;
}

/// 源实参 → JS 值：字面量直接引号包裹；其余表达式交给通用表达式翻译
/// （翻译不出返回 null，由调用方给出「Image 需要 asset/network 源」的错误）。
String? _imageSourceArg(Expression e, WidgetTranslateContext ctx) {
  if (e is SimpleStringLiteral) return ctx.jsString(e.value);
  try {
    return ctx.jsDataExpr(e);
  } catch (_) {
    return null;
  }
}
