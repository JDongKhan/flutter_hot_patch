import 'package:analyzer/dart/ast/ast.dart';

import 'widget_translator.dart';

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
        final n = _numExpr(v);
        if (n != null) map['fontSize'] = n;
      case 'fontWeight':
        final w = _fontWeightExpr(v);
        if (w != null) map['fontWeight'] = w;
      case 'fontStyle':
        final s = _fontStyleExpr(v);
        if (s != null) map['fontStyle'] = s;
      case 'color':
        final c = _colorExpr(v, ctx);
        if (c != null) map['color'] = c;
      case 'letterSpacing':
        final n = _numExpr(v);
        if (n != null) map['letterSpacing'] = n;
      case 'height':
        final n = _numExpr(v);
        if (n != null) map['height'] = n;
      case 'fontFamily':
        if (v is SimpleStringLiteral) map['fontFamily'] = ctx.jsString(v.value);
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
          final c = _colorExpr(_unwrapWidgetState(v), ctx);
          if (c != null) map['backgroundColor'] = c;
        case 'foregroundColor':
          final c = _colorExpr(_unwrapWidgetState(v), ctx);
          if (c != null) map['foregroundColor'] = c;
      }
    }
  }
  return map.isEmpty ? null : map;
}

// ---------------------------------------------------------------------------
// 基础表达式解析（样式专用，值一律输出 JS 表达式字符串）
// ---------------------------------------------------------------------------

/// 数字字面量 → JS 数字表达式（'12' / '1.5'）。
String? _numExpr(Expression e) {
  if (e is IntegerLiteral) {
    final v = e.value;
    return v == null ? null : '$v';
  }
  if (e is DoubleLiteral) {
    return '${e.value}';
  }
  return null;
}

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
/// 跨文件静态单例类字段引用（PanelColors.background）→ JS 表达式
/// 'PanelColors.background'（不带引号，jsLiteral 原样输出）。
String? _colorExpr(Expression e, WidgetTranslateContext ctx) {
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
  // Colors.red（静态引用）
  final (owner, name) = _staticRef(e);
  if (owner == 'Colors') {
    final hex = _materialColors[name];
    if (hex != null) return "'#$hex'";
    return null;
  }
  // 跨文件静态单例类字段引用（PanelColors.background）→ JS 表达式
  final singleton = ctx.singletons?.staticRef(e);
  if (singleton != null) return singleton;
  // 三目（isAdult ? PanelColors.adult : PanelColors.background）→ JS 三目表达式
  if (e is ConditionalExpression) {
    final condJs = ctx.jsDataExpr(e.condition);
    final thenJs = _colorExpr(e.thenExpression, ctx);
    final elseJs = _colorExpr(e.elseExpression, ctx);
    if (thenJs == null || elseJs == null) return null;
    return '($condJs ? $thenJs : $elseJs)';
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

/// Material 主色板（500 档）→ hex（不含 #）。
const Map<String, String> _materialColors = {
  'red': 'F44336',
  'pink': 'E91E63',
  'purple': '9C27B0',
  'deepPurple': '673AB7',
  'indigo': '3F51B5',
  'blue': '2196F3',
  'lightBlue': '03A9F4',
  'cyan': '00BCD4',
  'teal': '009688',
  'green': '4CAF50',
  'lightGreen': '8BC34A',
  'lime': 'CDDC39',
  'yellow': 'FFEB3B',
  'amber': 'FFC107',
  'orange': 'FF9800',
  'deepOrange': 'FF5722',
  'brown': '795548',
  'grey': '9E9E9E',
  'blueGrey': '607D8B',
  'black': '000000',
  'white': 'FFFFFF',
};

// ---------------------------------------------------------------------------
// 布局/内容类 toJson（Container/Padding/Align/Stack/Icon/Image 等复用）
// ---------------------------------------------------------------------------

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
    final n = _numExpr(pos.first);
    if (n != null) {
      l = t = r = b = double.tryParse(n);
    }
  }
  // EdgeInsets.symmetric / only：命名参数
  for (final a in args) {
    if (a is! NamedExpression) continue;
    final n = _numExpr(a.expression);
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
      final n = _numExpr(e);
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

/// BorderRadius.circular(8) / BorderRadius.all(Radius.circular(8)) → JSON。
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
  double? radius;
  // BorderRadius.circular(8)
  if (args.isNotEmpty) {
    final n = _numExpr(args.whereType<Expression>().first);
    if (n != null) radius = double.tryParse(n);
  }
  // BorderRadius.all(Radius.circular(8))：解包 Radius.circular
  for (final a in args) {
    if (a is! NamedExpression || a.name.label.name != 'all') continue;
    final (rCtor, rArgs) = _ctorOfExpr(a.expression);
    if (rCtor == 'Radius' && rArgs.isNotEmpty) {
      final n = _numExpr(rArgs.whereType<Expression>().first);
      if (n != null) radius = double.tryParse(n);
    }
  }
  if (radius == null) return null;
  return {'radius': '$radius'};
}

/// Colors.xxx / Color(0x...) → JS 字符串字面量（'#RRGGBB' / '#AARRGGBB'）。
/// 公共包装：widget translator 直接调用；内部实现在 [_colorExpr]。
String? colorToJson(Expression? expr, WidgetTranslateContext ctx) {
  if (expr == null) return null;
  return _colorExpr(expr, ctx);
}

/// BoxDecoration(color/borderRadius) → JSON。
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
    switch (a.name.label.name) {
      case 'color':
        final c = _colorExpr(a.expression, ctx);
        if (c != null) map['color'] = c;
      case 'borderRadius':
        final br = borderRadiusToJson(a.expression, ctx);
        if (br != null) map['borderRadius'] = br;
    }
  }
  return map.isEmpty ? null : map;
}

/// Image 源：AssetImage('x') / NetworkImage('url') / Image.asset / Image.network
/// → source 字符串（运行时 imageFromJson 选择资源/网络）。
String? imageSourceToJson(Expression? expr, WidgetTranslateContext ctx) {
  if (expr == null) return null;
  // 直接收到路径字符串：Image.network('url') / Image.asset('path') 的位置参数
  if (expr is SimpleStringLiteral) return ctx.jsString(expr.value);
  final (ctor, args) = _ctorOfExpr(expr);
  if (ctor == 'AssetImage' || ctor == 'NetworkImage') {
    final pos = args.whereType<Expression>().toList();
    if (pos.isNotEmpty && pos.first is SimpleStringLiteral) {
      return ctx.jsString((pos.first as SimpleStringLiteral).value);
    }
    return null;
  }
  // Image.asset('x') / Image.network('url')：methodName=asset/network，target=Image
  if (ctor == 'asset' || ctor == 'network') {
    final pos = args.whereType<Expression>().toList();
    if (pos.isNotEmpty && pos.first is SimpleStringLiteral) {
      return ctx.jsString((pos.first as SimpleStringLiteral).value);
    }
  }
  return null;
}
