/// 共享值工具：字面量、字符串转义、颜色、全局标志、类型判断、作用域。
///
/// 与 widget、类结构无关，由收集层（analyze_dart_class）、渲染层（dart2js）
/// 与 widget 层（widget2js）共同使用，避免任何一方反向依赖另一方的实现文件。
library;

import 'package:analyzer/dart/ast/ast.dart';

import '../../shared/js_widget_defs.dart';
import '../../shared/runtime_global_types.dart';
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
  if (e is IntegerLiteral) return intLiteralJs(e);
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

/// 整数字面量 → JS 数字：**保留源码写法**（Dart 里写 `0xFF0E7AFB`，产物里
/// 仍是 `0xFF0E7AFB`；写 `10` 仍是 `10`）。
///
/// 这是纯语法规则，与类型无关：颜色、掩码、标志位等常量在产物里一眼可读，
/// 不必反算十进制；JS 的 `0x…` 与十进制数值完全等价。下划线分隔符去掉，
/// 不依赖引擎对数值分隔符的支持。
String? intLiteralJs(Expression e) {
  if (e is! IntegerLiteral) return null;
  final v = e.value;
  if (v == null) return null;
  final src = e.toSource().replaceAll('_', '');
  return src.isEmpty ? v.toString() : src;
}

/// 数字字面量（int/double）→ JS 数字表达式（'12' / '1.5'）；非数字字面量返回 null。
///
/// 值域比 [literalToJs] 窄（只认数字），供「只接受数字」的属性/样式读取——
/// 样式翻译与 widget 翻译共用这一处，不各自重复一份。
String? numLiteralJs(Expression? e) {
  if (e is IntegerLiteral) return intLiteralJs(e);
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

/// `x is T` → JS 类型判别表达式；T 在 JS 侧不可解析时返回 null。
///
/// Dart 的运行时类型在 JS 侧没有一一对应的构造（`int` / `double` 同是 number、
/// List 是数组、Map 是普通对象），因此基础类型按 JS 语义映射，其余按
/// `instanceof`——但**只对确实存在的类**生效：`instanceof` 遇到未定义的构造会
/// 抛 ReferenceError，宁可整条表达式不翻译（与其它不可翻译表达式同一策略）。
///
/// [knownClasses] 是本次分析可见的项目类名（`ClassInfo` 表）；宿主包装类与
/// 运行时注入的全局类（`G.X = …`）自动可见，无需登记。
String? typeTestJs(String typeName, String valueJs, {Set<String> knownClasses = const {}}) {
  final t = eraseType(typeName);
  switch (t) {
    case 'String':
      return 'typeof $valueJs === "string"';
    case 'int':
    case 'double':
    case 'num':
      return 'typeof $valueJs === "number"';
    case 'bool':
      return 'typeof $valueJs === "boolean"';
    case 'List':
    case 'Iterable':
      return 'Array.isArray($valueJs)';
    case 'Map':
      return '($valueJs != null && typeof $valueJs === "object" '
          '&& !Array.isArray($valueJs))';
    case 'Function':
      return 'typeof $valueJs === "function"';
    case 'Object':
    case 'dynamic':
      return '$valueJs != null';
  }
  if (knownClasses.contains(t) ||
      hostWrapperTypes.contains(t) ||
      runtimeGlobalTypes().contains(t)) {
    return '$valueJs instanceof $t';
  }
  return null;
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

  /// 中立描述 → 作为**值**的 JS 源码：同样是 `new X({...})`，但不做「元素 /
  /// 宿主字符串结点」的形态切换。
  ///
  /// 值的分派只由**语法位置**决定（参数值是值、`children:` 元素是结点），
  /// 翻译器不判断类型是组件还是普通类：构造一律 1:1 产出构造调用，组件由
  /// 运行时注入的同名类 / 包装类在 `__h` 处折算成元素。
  String renderValue(Object? node, int depth);

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
