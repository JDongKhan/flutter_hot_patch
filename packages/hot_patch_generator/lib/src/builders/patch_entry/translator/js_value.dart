/// 共享值工具：字面量、字符串转义、颜色、全局标志、类型判断、作用域。
///
/// 与 widget、类结构无关，由收集层（analyze_dart_class）、渲染层（dart2js）
/// 与 widget 层（widget2js）共同使用，避免任何一方反向依赖另一方的实现文件。
library;

import 'package:analyzer/dart/ast/ast.dart';

import '../class_info.dart';

/// JS 双引号字符串字面量（唯一实现）。
///
/// 反斜杠、双引号、换行 / 回车 / 制表符以及所有 C0 控制字符都必须转义：
/// Dart 单引号字符串里可以自由出现 `"`（如 `Text('He said "hi"')`），
/// 漏转义会直接产出非法 JS，导致整个模块求值失败。
String jsString(String s) => jsStringLiteral(s);

/// 字符串值 → JS 双引号字面量（供 [jsString] 与 widget2js 共用，禁止再写第二份）。
String jsStringLiteral(String s) {
  final b = StringBuffer('"');
  for (final code in s.runes) {
    final escaped = switch (code) {
      0x5C => r'\\',
      0x22 => r'\"',
      0x08 => r'\b',
      0x0C => r'\f',
      0x0A => r'\n',
      0x0D => r'\r',
      0x09 => r'\t',
      _ => null,
    };
    if (escaped != null) {
      b.write(escaped);
    } else if (code < 0x20) {
      b.write('\\u${code.toRadixString(16).padLeft(4, '0')}');
    } else {
      b.writeCharCode(code);
    }
  }
  b.write('"');
  return b.toString();
}

/// 字面量 → JS 字面量（字符串带双引号、数字/布尔原样）。不可翻译返回 null。
///
/// **唯一**的「编译期常量字面量」翻译实现：字段初始值（[renderClassDecl]）、
/// 组件 stat/props 初值（builder 侧）、静态单例字段值都走这里——新增字面量
/// 能力只改这一处。当前覆盖 string/int/double/bool、相邻字符串字面量拼接，
/// 以及由它们构成的二元运算。
String? literalToJs(Expression? e) {
  if (e == null) return null;
  // StringInterpolation / AdjacentStrings 都是 StringLiteral 的**子类**，而它们的
  // stringValue 是 null：若被下面那行字面量分支接住，整串会被静默翻译成 `""`
  // （插值表达式与拼接内容全丢）。本函数没有作用域、翻不了插值，故如实返回 null，
  // 由带作用域的 rhsToJs / exprToJs 兜底。
  if (e is StringInterpolation) return null;
  // 相邻字符串字面量拼接（`'a' 'b'`）本身是编译期常量：逐段递归后 `+` 拼接；
  // 任一段非常量（如含插值）则整体放弃，同样交给带作用域的调用方。
  if (e is AdjacentStrings) {
    final parts = <String>[];
    for (final s in e.strings) {
      final v = literalToJs(s);
      if (v == null) return null;
      parts.add(v);
    }
    return parts.join(' + ');
  }
  if (e is StringLiteral) return jsString(e.stringValue ?? '');
  if (e is IntegerLiteral) return e.value?.toString();
  if (e is DoubleLiteral) return e.value.toString();
  if (e is BooleanLiteral) return e.value.toString();
  // 一元前缀（`-1` / `+1` / `!done` / `~x`）：不是字面量节点，Dart 与 JS 语义
  // 一致，一比一透传。不认这层会把 `int _picked = -1` 静默翻译成默认值 0。
  if (e is PrefixExpression) {
    final inner = literalToJs(e.operand);
    if (inner != null) return '(${e.operator.lexeme}$inner)';
  }
  if (e is BinaryExpression) {
    final l = literalToJs(e.leftOperand);
    final r = literalToJs(e.rightOperand);
    if (l != null && r != null) return '($l ${e.operator.lexeme} $r)';
  }
  return null;
}

/// 数字字面量（int/double）→ JS 数字表达式（'12' / '1.5'）；非数字字面量返回 null。
///
/// 值域比 [literalToJs] 窄（只认数字），供「只接受数字」的属性/样式读取——
/// 样式翻译与 widget 翻译共用这一处，不各自重复一份。
String? numLiteralJs(Expression? e) {
  if (e is IntegerLiteral) return e.value?.toString();
  if (e is DoubleLiteral) return '${e.value}';
  // 负数字面量（`-1`）：同样是一元前缀，不认会在样式/属性里静默丢值。
  if (e is PrefixExpression) {
    final inner = numLiteralJs(e.operand);
    if (inner != null) return '(${e.operator.lexeme}$inner)';
  }
  return null;
}

/// bool 字面量 → 'true' / 'false'；非 bool 字面量返回 null（见 [numLiteralJs]）。
String? boolLiteralJs(Expression? e) {
  if (e is BooleanLiteral) return e.value.toString();
  return null;
}

/// Material 主色板（500 档）→ hex（不含 #）。放通用表达式层：任意表达式位置
/// （组件实参、数据绑定、样式属性）都能解析 `Colors.*`，避免某一处漏掉后
/// 产出未定义的 `Colors` 全局。样式翻译（style_translators）复用同一份表。
const Map<String, String> materialColors = {
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

/// `Colors.<name>` → hex（不含 #）；非主色板名（含 `.shadeNNN` 形态由调用方
/// 单独处理）返回 null。
String? materialColorHex(String name) => materialColors[name];

/// Material 色板**各档位**（`Colors.<name>.shade<N>`）→ hex（不含 #）。
///
/// **数据来源**：Flutter SDK `packages/flutter/lib/src/material/colors.dart`
/// 的 Material spec 常量（恒定不变，已按 SDK 版本核对）。生成器在**编译期**
/// 就把 `Colors.green.shade100` 算成 `'#C8E6C9'`——产物里不再出现
/// `@Colors.green.shade100` 这类标记，翻译层与运行时都不必再为色板做分支。

const Map<String, Map<int, String>> materialColorShades = {
  'amber': {50: 'FFF8E1', 100: 'FFECB3', 200: 'FFE082', 300: 'FFD54F', 400: 'FFCA28', 500: 'FFC107', 600: 'FFB300', 700: 'FFA000', 800: 'FF8F00', 900: 'FF6F00'},
  'blue': {50: 'E3F2FD', 100: 'BBDEFB', 200: '90CAF9', 300: '64B5F6', 400: '42A5F5', 500: '2196F3', 600: '1E88E5', 700: '1976D2', 800: '1565C0', 900: '0D47A1'},
  'blueGrey': {50: 'ECEFF1', 100: 'CFD8DC', 200: 'B0BEC5', 300: '90A4AE', 400: '78909C', 500: '607D8B', 600: '546E7A', 700: '455A64', 800: '37474F', 900: '263238'},
  'brown': {50: 'EFEBE9', 100: 'D7CCC8', 200: 'BCAAA4', 300: 'A1887F', 400: '8D6E63', 500: '795548', 600: '6D4C41', 700: '5D4037', 800: '4E342E', 900: '3E2723'},
  'cyan': {50: 'E0F7FA', 100: 'B2EBF2', 200: '80DEEA', 300: '4DD0E1', 400: '26C6DA', 500: '00BCD4', 600: '00ACC1', 700: '0097A7', 800: '00838F', 900: '006064'},
  'deepOrange': {50: 'FBE9E7', 100: 'FFCCBC', 200: 'FFAB91', 300: 'FF8A65', 400: 'FF7043', 500: 'FF5722', 600: 'F4511E', 700: 'E64A19', 800: 'D84315', 900: 'BF360C'},
  'deepPurple': {50: 'EDE7F6', 100: 'D1C4E9', 200: 'B39DDB', 300: '9575CD', 400: '7E57C2', 500: '673AB7', 600: '5E35B1', 700: '512DA8', 800: '4527A0', 900: '311B92'},
  'green': {50: 'E8F5E9', 100: 'C8E6C9', 200: 'A5D6A7', 300: '81C784', 400: '66BB6A', 500: '4CAF50', 600: '43A047', 700: '388E3C', 800: '2E7D32', 900: '1B5E20'},
  'grey': {50: 'FAFAFA', 100: 'F5F5F5', 200: 'EEEEEE', 300: 'E0E0E0', 350: 'D6D6D6', 400: 'BDBDBD', 500: '9E9E9E', 600: '757575', 700: '616161', 800: '424242', 850: '303030', 900: '212121'},
  'indigo': {50: 'E8EAF6', 100: 'C5CAE9', 200: '9FA8DA', 300: '7986CB', 400: '5C6BC0', 500: '3F51B5', 600: '3949AB', 700: '303F9F', 800: '283593', 900: '1A237E'},
  'lightBlue': {50: 'E1F5FE', 100: 'B3E5FC', 200: '81D4FA', 300: '4FC3F7', 400: '29B6F6', 500: '03A9F4', 600: '039BE5', 700: '0288D1', 800: '0277BD', 900: '01579B'},
  'lightGreen': {50: 'F1F8E9', 100: 'DCEDC8', 200: 'C5E1A5', 300: 'AED581', 400: '9CCC65', 500: '8BC34A', 600: '7CB342', 700: '689F38', 800: '558B2F', 900: '33691E'},
  'lime': {50: 'F9FBE7', 100: 'F0F4C3', 200: 'E6EE9C', 300: 'DCE775', 400: 'D4E157', 500: 'CDDC39', 600: 'C0CA33', 700: 'AFB42B', 800: '9E9D24', 900: '827717'},
  'orange': {50: 'FFF3E0', 100: 'FFE0B2', 200: 'FFCC80', 300: 'FFB74D', 400: 'FFA726', 500: 'FF9800', 600: 'FB8C00', 700: 'F57C00', 800: 'EF6C00', 900: 'E65100'},
  'pink': {50: 'FCE4EC', 100: 'F8BBD0', 200: 'F48FB1', 300: 'F06292', 400: 'EC407A', 500: 'E91E63', 600: 'D81B60', 700: 'C2185B', 800: 'AD1457', 900: '880E4F'},
  'purple': {50: 'F3E5F5', 100: 'E1BEE7', 200: 'CE93D8', 300: 'BA68C8', 400: 'AB47BC', 500: '9C27B0', 600: '8E24AA', 700: '7B1FA2', 800: '6A1B9A', 900: '4A148C'},
  'red': {50: 'FFEBEE', 100: 'FFCDD2', 200: 'EF9A9A', 300: 'E57373', 400: 'EF5350', 500: 'F44336', 600: 'E53935', 700: 'D32F2F', 800: 'C62828', 900: 'B71C1C'},
  'teal': {50: 'E0F2F1', 100: 'B2DFDB', 200: '80CBC4', 300: '4DB6AC', 400: '26A69A', 500: '009688', 600: '00897B', 700: '00796B', 800: '00695C', 900: '004D40'},
  'yellow': {50: 'FFFDE7', 100: 'FFF9C4', 200: 'FFF59D', 300: 'FFF176', 400: 'FFEE58', 500: 'FFEB3B', 600: 'FDD835', 700: 'FBC02D', 800: 'F9A825', 900: 'F57F17'},
};

/// Material **accent** 色板各档位（`Colors.<name>Accent.shade<N>`）→ hex。

const Map<String, Map<int, String>> materialAccentShades = {
  'amberAccent': {100: 'FFE57F', 200: 'FFD740', 400: 'FFC400', 700: 'FFAB00'},
  'blueAccent': {100: '82B1FF', 200: '448AFF', 400: '2979FF', 700: '2962FF'},
  'cyanAccent': {100: '84FFFF', 200: '18FFFF', 400: '00E5FF', 700: '00B8D4'},
  'deepOrangeAccent': {100: 'FF9E80', 200: 'FF6E40', 400: 'FF3D00', 700: 'DD2C00'},
  'deepPurpleAccent': {100: 'B388FF', 200: '7C4DFF', 400: '651FFF', 700: '6200EA'},
  'greenAccent': {100: 'B9F6CA', 200: '69F0AE', 400: '00E676', 700: '00C853'},
  'indigoAccent': {100: '8C9EFF', 200: '536DFE', 400: '3D5AFE', 700: '304FFE'},
  'lightBlueAccent': {100: '80D8FF', 200: '40C4FF', 400: '00B0FF', 700: '0091EA'},
  'lightGreenAccent': {100: 'CCFF90', 200: 'B2FF59', 400: '76FF03', 700: '64DD17'},
  'limeAccent': {100: 'F4FF81', 200: 'EEFF41', 400: 'C6FF00', 700: 'AEEA00'},
  'orangeAccent': {100: 'FFD180', 200: 'FFAB40', 400: 'FF9100', 700: 'FF6D00'},
  'pinkAccent': {100: 'FF80AB', 200: 'FF4081', 400: 'F50057', 700: 'C51162'},
  'purpleAccent': {100: 'EA80FC', 200: 'E040FB', 400: 'D500F9', 700: 'AA00FF'},
  'redAccent': {100: 'FF8A80', 200: 'FF5252', 400: 'FF1744', 700: 'D50000'},
  'tealAccent': {100: 'A7FFEB', 200: '64FFDA', 400: '1DE9B6', 700: '00BFA5'},
  'yellowAccent': {100: 'FFFF8D', 200: 'FFFF00', 400: 'FFEA00', 700: 'FFD600'},
};

/// `Colors.<name>.shade<N>` / `Colors.<name>Accent.shade<N>` → hex（不含 #）；
/// 未登记的色名/档位返回 null。
String? materialShadeHex(String colorName, int shade) =>
    (materialColorShades[colorName] ?? materialAccentShades[colorName])?[shade];

/// 色板成员名 → 档位：`shade100` → 100；非 `shade<N>` 形态返回 null。
int? shadeIndex(String member) {
  if (!member.startsWith('shade')) return null;
  return int.tryParse(member.substring(5));
}

/// `Color(0xAARRGGBB)` / `Color.fromARGB(a, r, g, b)` → JS 颜色字符串
/// `'#aarrggbb'`（运行时按 '#rrggbb' 解析为 Color，与样式翻译同一契约）。
///
/// 放在通用表达式层：任意位置的颜色字面量（顶层常量、模型字段默认值、集合
/// 元素……）都能翻译，而不只是 widget 的样式属性。
String? colorLiteralJs(Expression e) {
  ArgumentList? args;
  String? ctor;
  String? named;
  if (e is InstanceCreationExpression) {
    ctor = e.constructorName.type.name2.lexeme;
    named = e.constructorName.name?.name;
    args = e.argumentList;
  } else if (e is MethodInvocation && e.target == null) {
    ctor = e.methodName.name;
    args = e.argumentList;
  } else if (e is MethodInvocation && e.target is Identifier) {
    // `Color.fromARGB(...)`：target 是类名。
    ctor = (e.target as Identifier).name;
    named = e.methodName.name;
    args = e.argumentList;
  } else {
    return null;
  }
  if (ctor != 'Color') return null;
  final ints = args.arguments
      .whereType<IntegerLiteral>()
      .map((x) => x.value)
      .whereType<int>()
      .toList();
  if (named == 'fromARGB') {
    if (ints.length != 4) return null;
    final hex = ints
        .map((x) => x.clamp(0, 255).toRadixString(16).padLeft(2, '0'))
        .join();
    return "'#$hex'";
  }
  // `Color(0xAARRGGBB)`：单个整数实参。
  for (final a in args.arguments) {
    if (a is IntegerLiteral && a.value != null) {
      return "'#${a.value!.toRadixString(16).padLeft(8, '0')}'";
    }
  }
  return null;
}

/// `kDebugMode` / `kReleaseMode` → 运行时注入同名全局（见 js_runtime_manager
/// 模块表初始化），不命中返回 null。纯语言层映射，与 widget 无关。
String? globalFlagJs(String dartName) {
  const set = {'kDebugMode', 'kReleaseMode'};
  return set.contains(dartName) ? dartName : null;
}

/// `Platform.isXxx` → 原样 `Platform.isXxx`（运行时注入同名 Platform 对象，
/// 含 isAndroid/isIOS/isMacOS/isWindows/isLinux/isFuchsia），不命中返回 null。
String? platformFlagJs(String platformProp) {
  const set = {
    'isAndroid', 'isIOS', 'isMacOS',
    'isWindows', 'isLinux', 'isFuchsia',
  };
  return set.contains(platformProp) ? 'Platform.$platformProp' : null;
}

/// 去掉可空 / 泛型后缀：`BuildContext?` → `BuildContext`、`List<T>` → `List`。
String eraseType(String? type) {
  var t = (type ?? '').trim();
  if (t.endsWith('?')) t = t.substring(0, t.length - 1);
  final lt = t.indexOf('<');
  if (lt >= 0) t = t.substring(0, lt).trim();
  return t;
}

/// 基础类型（可翻译为 JS 初始值）：int/double/num/String/bool/dynamic。
/// 类发现与字段收集共用这一处——新增「基础类型」只改这里。
bool isBasicType(String typeName) {
  final t = typeName.trim();
  if (t.endsWith('?')) return isBasicType(t.substring(0, t.length - 1));
  return switch (t) {
    'int' || 'double' || 'num' || 'String' || 'bool' || 'dynamic' => true,
    _ => false,
  };
}

// ===========================================================================
// Flutter SDK → JS 基类 映射表（便于后续扩展）
//
// 具体要把哪些 Flutter SDK 类转成 JS 基类，由这张表按需登记即可，
// 生成器逻辑零改动。
//
//   key = Dart 父类名（extends 命中的类名）
//   value = 生成的 JS 基类名（运行时需注入同名类）
//
// 额外语义（针对登记在表的类）：
//   - 渲染时自动 `extends <value>` + constructor 里 `super()`
//   - 类方法体裸调白名单自动加上基类能力方法（如 ChangeNotifier 的
//     notifyListeners）
//
// 后续新增 SDK 支持 = 往这张表加一行 +（如需要）在运行时注册对应基类。
// widget 翻译不走 per-widget 实现：统一入口见 widget_json.dart / value_forms.dart。
// ===========================================================================

/// 由 [ClassInfo.superType] 查 JS 基类名；未登记返回 null。
///
/// **必须剥泛型实参**：`class X extends ValueNotifier<int>` 的 superType 是
/// `ValueNotifier<int>`（AST `toSource()` 原样），直接查表必然落空 → 基类不写、
/// 继承来的方法全部译不出来。
String? sdkBaseName(ClassInfo info) {
  final t = info.superType;
  if (t == null) return null;
  return sdkSuperClassMap[t.split('<').first.trim()];
}

/// Dart 基类名 → JS 基类名（运行时注入同名类）。
const Map<String, String> sdkSuperClassMap = {
  'ChangeNotifier': 'ChangeNotifier',
  'ValueNotifier': 'ValueNotifier',
};

// ---------------------------------------------------------------------------
// FieldScope：把 Dart 标识符解析成 JS 引用的抽象
// ---------------------------------------------------------------------------

/// 字段作用域：决定一个 Identifier 怎么转 JS。
///
/// 组件动作：字段名 → propByField[name]（`_count`→`this._count`），形参 extraVars。
/// 模型方法：字段名 → instanceFields（`_n`→`this._n`），形参、白名单方法。
class FieldScope {
  final Map<String, String> propByField; // 组件：字段→属性名
  final Set<String> instanceFields; // 模型：自身实例字段名
  final Set<String> params; // 形参名（原样引用）
  final Set<String> methods; // 裸调白名单（this.method()）

  /// 方法体内声明的局部变量（`var data = ...`），后续引用原样返回。
  final Set<String> localVars;

  /// 本文件可见的**顶层常量**名（同文件 + import 文件，如 `kBanners` / `kBrand`）。
  /// 命中即原样作为 JS 模块级常量引用：同文件的写在同一产物顶部，跨文件的由
  /// import 语句提供（与类引用同一套「同文件内联 / 跨文件 import」规则）。
  final Set<String> globalConsts;

  /// 宿主注入方法表：`类名 → {方法名 → 通道名}`（见 @HostInjected）；
  /// 顶层函数（全局方法）挂在空串 key 下（`'' → {函数名 → 通道名}`）。
  /// 命中时调用点整体翻译成 `_app_host_.invoke("通道名", 参数载荷)`（载荷形态见
  /// [hostArgsJs]）——参数个数、是否具名、返回值类型都无关（宿主侧用
  /// Function.apply 调实现）。
  final Map<String, Map<String, String>> hostMethods;

  /// 当前方法的 super 调用映射（来自 [ClassMethod.superMap]）：`super.foo()` →
  /// `this.<target>()`。随方法体翻译入口（[translateClassMethodBody]）一次性
  /// 挂进作用域，语句翻译（translateStmtList）据此把 super 语句落成 mixin
  /// 方法调用；空表 = 无 mixin，super 语句按原策略忽略。
  final Map<String, String> superMap;

  /// 局部变量别名：`final list = _list;` → `list → this._list`。
  /// 抽成实例方法的懒加载 builder（`_listViewBuilderN`）里引用被捕获的
  /// 局部变量时必须落到真实字段引用，否则是未定义的自由变量。
  final Map<String, String> localAliases;

  /// 声明期登记的字段别名表（`final feed = _feed;` → `feed → this._feed`）。
  ///
  /// **只供后续「变量声明的初始化器」折算**（[forInitializer]）——这样才能闭合
  /// 链式别名：`final spots = feed.spots;` 里的 `feed` 先折成 `this._feed`，
  /// `spots` 于是也成了字段别名，被抽进懒加载 builder 方法后仍能落字段引用。
  ///
  /// 刻意不并进 [localAliases]：那会让方法体里**所有**语句中的引用都变成
  /// 「按引用重求值」，副作用初始化器（`_items.removeAt(i)`、`GlobalKey
  /// .currentContext`）会被每条语句重跑一遍，把既有产物改坏。
  final Map<String, String> declAliases;

  /// 变量声明的初始化器专用作用域：把 [declAliases] 当作别名表，其余照旧。
  /// 只影响**这一次初始化器**的折算，方法体其余语句一律不受影响。
  FieldScope forInitializer() => declAliases.isEmpty
      ? this
      : FieldScope(
          propByField: propByField,
          instanceFields: instanceFields,
          params: params,
          methods: methods,
          localVars: localVars,
          globalConsts: globalConsts,
          hostMethods: hostMethods,
          superMap: superMap,
          localAliases: declAliases,
        );

  FieldScope({
    this.propByField = const {},
    this.instanceFields = const {},
    this.params = const {},
    this.methods = const {},
    this.hostMethods = const {},
    this.superMap = const {},
    Map<String, String>? localAliases,
    Map<String, String>? declAliases,
    Set<String>? localVars,
    Set<String>? globalConsts,
  })  : localVars = localVars ?? {},
        localAliases = localAliases ?? const {},
        declAliases = declAliases ?? {},
        globalConsts = globalConsts ?? {};

  /// 派生作用域：追加形参名（闭包形参 `(o) => o.status`），其余照旧。
  ///
  /// 缺这一步，闭包体里的形参引用（`o`）解析不出来，谓词整条翻译失败，
  /// 连带 `where(...)` / `map(...)` 与外层表达式一起被丢弃。
  FieldScope withParams(Iterable<String> names) => FieldScope(
        propByField: propByField,
        instanceFields: instanceFields,
        params: {...params, ...names},
        methods: methods,
        localVars: localVars,
        globalConsts: globalConsts,
        hostMethods: hostMethods,
        superMap: superMap,
        localAliases: localAliases,
        // 同一个别名表实例：派生作用域里登记的别名，母作用域后续声明同样可见
        // （闭包体内的 `final x = _feed.spots;` 也算链式别名）。
        declAliases: declAliases,
      );

  /// 该名字是否本 scope 可解析的字段。
  bool hasField(String name) =>
      propByField.containsKey(name) ||
      instanceFields.contains(name) ||
      localAliases.containsKey(name) ||
      localVars.contains(name);

  /// 字段 Identifier → JS 引用（`this.x`）；形参/局部变量原样返回；未知返回 null。
  String? fieldRef(String name) {
    if (params.contains(name)) return name;
    final alias = localAliases[name];
    if (alias != null) return alias;
    if (localVars.contains(name)) return name;
    final p = propByField[name];
    if (p != null) return 'this.$p';
    if (instanceFields.contains(name)) return 'this.$name';
    // 实例方法 / getter 引用（`_toggleFilter`、`_visiblePosts` 这类）：
    // JS 类里它们就是原型上的方法 / `get` 访问器，裸引用一律落成 `this.<name>`。
    // 少了这一条，`final list = _list;`（getter）与 tear-off 实参会整条翻译失败，
    // 进而连带把整个 build 树丢掉。
    if (methods.contains(name)) return 'this.$name';
    return null;
  }

  bool isMethod(String name) => methods.contains(name);
}

/// 「widget 表达式 / 树 → JS」的渲染接口（由 widget2js 层的
/// `WidgetTranslateContext` 实现）。
///
/// 放在公共翻译层是为了让「Dart 类 → JS」不反向依赖 widget2js：方法体里
/// `return Container(...)` 这类 widget 构造表达式经此接口交给 widget 层渲染，
/// 其余表达式仍走本文件的通用翻译。
abstract class WidgetExprRenderer {
  /// widget 构造表达式 → 中立描述（Map 节点 / String JS 表达式）。
  Object? translate(Expression e);

  /// 中立描述 → JS 源码（构造调用树）。
  String renderJs(Object? node, int depth);

  /// 把「局部 widget 值」翻译成 JS 元素源码（字段 / 局部变量 / 列表 / 三目）。
  ///
  /// 不是可识别的 widget 构造时返回 null，调用方回退到通用值翻译
  /// （模型构造、标量、普通集合等），避免把 `User()` 误当元素。
  String? widgetValueJs(Expression e, int depth);

  /// 方法体内声明的局部变量（`final isAdult = ...;`）→ 登记进 widget 层局部表。
  /// 方法体翻译与 widget 渲染必须共用同一份标识符作用域，否则返回的 widget
  /// 树里引用局部变量时会解析失败。
  void registerLocal(String name);

  /// 把「字段/ getter 的局部别名」（`final list = _list;` → `this._list`）登记
  /// 进 widget 层：抽成实例方法的懒加载 builder（`_listViewBuilderN`）里引用该
  /// 名字时必须落成 `this._list`，否则方法体内是未定义的自由变量（ReferenceError）。
  void registerLocalAlias(String name, String jsExpr);

  /// 方法形参：翻译**该方法体期间**登记进 widget 层作用域（`_group(String title,
  /// …)` 里 `Text(title)` 要能与局部变量同样解析），方法体翻译结束后恢复，
  /// 避免形参名泄漏到同类的其它方法。成对调用。
  T withMethodParams<T>(Iterable<String> params, T Function() body);

  /// 本文件可见的顶层常量名（widget 树里 `kBrand` 这类引用要与方法体翻译
  /// 共用同一份作用域）。
  Set<String> get globalConsts;
}
