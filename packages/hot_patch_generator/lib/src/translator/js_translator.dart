import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart' show log;

// ===========================================================================
// 公共翻译工具：Dart 语言 → JS 语言
//
// 只做语言层转换，不认识 widget / 组件：
//   - 类模型：ClassInfo / ClassField / ClassMethod
//   - 作用域：FieldScope（表达式 / 语句翻译的统一键）
//   - 翻译：literalToJs / exprToJs / rhsToJs / methodCallExprJs / closureToJs /
//           exprStmtToJs / translateStmtList / translateMethodBody /
//           translateClassMethodBody / jsMethodParams / jsString 等
//   - 全局标志：globalFlagJs / platformFlagJs
//   - SDK 基类映射：sdkSuperClassMap / sdkBaseName
//
// 分工（依赖方向单向、无环）：
//   js_translator  ←  dart2js（Dart 类 → JS 类声明）
//                  ←  widget2js（widget → JS / build 树渲染）
// 新增一门表达式 / 语句 / 字面量语法只改本文件，两类翻译同时生效。
//
// 唯一的「向上」缝：方法体里 `return Container(...)` 需要 widget 层参与，
// 用下面的 [WidgetExprRenderer] 接口解耦——本文件定义接口，widget2js 实现。
// ===========================================================================

/// 类的一个字段（实例或 static）。
///
/// 初始值二选一：普通类给 [initializer]（AST，渲染期翻译）；组件路径
/// （字段翻译已由组件翻译器完成）直接给预渲染好的 [jsInitial] JS 表达式。
class ClassField {
  final String name;
  final String typeName;
  final Expression? initializer; // 无初始化则 null
  final bool isStatic;
  final String? jsInitial; // 预渲染 JS 初始值（非 null 时优先于 initializer）
  const ClassField({
    required this.name,
    required this.typeName,
    this.initializer,
    this.isStatic = false,
    this.jsInitial,
  });
}

/// 类的实例方法 / getter。
///
/// **方法体翻译只有一条路径**：所有方法体都由 [translateClassMethodBody]
/// → [translateMethodBody] 翻译，方法体里 `return Text(...)` 这类「返回 widget」
/// 的表达式一律走 widget 层渲染——build 与其它返回 widget 的方法没有任何区别
/// （不存在「是不是 build」的判断）。
///
/// [bodyJs] 只是同一份翻译的**缓存**：组件类在生成期（需要先遍历一次以发现
/// 依赖类）就把方法体译好存下，渲染期直接用；普通类给 [body] 由渲染期翻译。
/// 两者形状一致、来自同一个翻译器。
class ClassMethod {
  final String name;
  final List<String> params; // 形参名（JS 一比一）
  final bool isAsync;
  final bool isGetter;

  /// 返回类型为 void：箭头体会被译为语句（不加 `return`）。
  final bool isVoid;

  /// 返回值是否为 widget：`return Text(...)` 只有在此为真时才走 widget 树
  /// 渲染路径。普通类里返回模型的方法（`User makeUser() => User(...)`）返回
  /// 的是数据而非 widget，按普通表达式翻译，不会被误判成组件占位节点。
  final bool returnsWidget;
  final FunctionBody? body;
  final String? bodyJs; // 预渲染方法体（非 null 时优先于 body）

  /// 方法体是「宿主通道」形式（如 SnackBar → `nativeToast`）：整体译为
  /// `__jsui.host("通道名", {...})`，[nativeMessage] 是已译好的消息 JS 表达式。
  final String? nativeChannel;
  final String? nativeMessage;
  const ClassMethod({
    required this.name,
    required this.params,
    this.isAsync = false,
    this.isGetter = false,
    this.isVoid = false,
    this.returnsWidget = true,
    this.body,
    this.bodyJs,
    this.nativeChannel,
    this.nativeMessage,
  });
}

/// 一个 Dart 类翻译成 JS 后的中立描述（按「声明」建模，不看用途）。
///
/// 组件（@PatchEntry）与普通类都是 Dart 类，用**完全相同**的模型描述：
/// 字段、方法（方法体翻译唯一走 [translateClassMethodBody]）、构造参数。
/// 组件只是额外带两项数据：
///   1. [builders]/[builderNames]/… —— 响应式 builder 闭包子方法（翻译过程中
///      由 widget 层收集，渲染成 `_lbBuilderN` 实例方法）；
///   2. [isComponent] —— 仅用于产物注释标注。
class ClassInfo {
  final String name;
  final String sourceFile; // dart 源文件路径（用于推导 import/相对产物）
  final String? superType; // extends 的类名（如 ChangeNotifier）
  final List<ClassField> instanceFields;
  final List<ClassField> staticFields;
  final List<ClassMethod> methods; // 含 getter
  final Set<String> ctorParams; // this.x 构造形参名

  /// 是否为 @PatchEntry 组件（仅用于产物注释标注，不参与结构分叉）。
  final bool isComponent;

  /// 响应式 builder 闭包子方法（ListenableBuilder/Consumer）。
  final List<Object?> builders;
  final List<String> builderNames;
  final List<String?> builderParams;
  final List<String> builderPreludes;

  // --- 翻译期发现的依赖信息（组件/普通类同一份模型，builder 据此递归、import）---

  /// 翻译本类时引用到的其它类/组件名：字段类型 + 方法体里构造调用 + 嵌套组件。
  /// builder 据此**递归翻译**依赖组件，并按 [sourceFile] 决定同文件内联还是
  /// 跨文件 import。依赖发现与「类 → JS」是同一次翻译的产物（不在 builder 里另起一套）。
  final Set<String> dependencies;

  /// 本类实际用到的 widget 类型（package → {type}）：据「只转换用到的」按 package
  /// 产出 JS widget 模块。
  final Map<String, Set<String>> usedWidgetPackages;

  /// 方法体里是否用到结点工厂 `__h`（决定产物是否 import `__h`）。
  final bool usedNodeHelper;

  /// 本文件 `@HostInjected` 声明的通道表（类名 → {方法名 → 通道名}；顶层函数
  /// 挂在空串 key 下）。由 [translateClass] 翻译时自行扫好挂在模型上，方法体
  /// 翻译据此把调用点整体换成 `__jsui.host(通道, 载荷)`——组件与普通类同一份
  /// 数据、同一条路径，构建层不参与。
  final Map<String, Map<String, String>> hostMethods;

  const ClassInfo({
    required this.name,
    required this.sourceFile,
    this.superType,
    required this.instanceFields,
    required this.staticFields,
    required this.methods,
    this.ctorParams = const {},
    this.isComponent = false,
    this.builders = const [],
    this.builderNames = const [],
    this.builderParams = const [],
    this.builderPreludes = const [],
    this.dependencies = const {},
    this.usedWidgetPackages = const {},
    this.usedNodeHelper = false,
    this.hostMethods = const {},
  });

  bool get isStaticOnly => instanceFields.isEmpty && methods.isEmpty;

  Set<String> get instanceFieldNames =>
      {for (final f in instanceFields) f.name};

  Set<String> get methodNames => {for (final m in methods) m.name};
}

/// 方法形参 → JS 形参名列表（解 DefaultFormalParameter 包裹）。
///
/// **一一对应**：Dart 是什么形参，JS 就是什么形参（形参名、顺序、个数完全一致），
/// 不做任何类型剔除——`BuildContext` 也有对应物（运行时以最近宿主祖先结点为锚
/// 的代理，由 build 传参）。形参名在作用域内保持裸引用；仅事件等延迟作用域因
/// 看不见形参，才由作用域别名译成 `this.context`（见 WidgetTranslateContext._eventScope）。
/// 组件与普通类共用这一处。
List<String> jsMethodParams(MethodDeclaration m) {
  final out = <String>[];
  for (final p in m.parameters?.parameters ?? const <FormalParameter>[]) {
    final inner = p is DefaultFormalParameter ? p.parameter : p;
    final name = inner.name?.lexeme;
    if (name == null || name.isEmpty) continue;
    out.add(name);
  }
  return out;
}

/// 方法是否 `void`：返回类型为 `void`（箭头体译为语句，不产生 `return`）。
bool isVoidReturn(MethodDeclaration m) {
  final t = m.returnType?.toSource().trim();
  return t == 'void';
}

/// 方法返回值是否为 widget：显式返回类型里出现 `Widget`（`Widget` / `Widget?` /
/// `Future<Widget>` / `XxxWidget`）即视为 widget 方法，`return Text(...)` 走
/// widget 树渲染；返回模型等数据类型的普通方法（`User makeUser()`）按普通表达
/// 式翻译，不会被误判成组件占位节点。无显式返回类型时按 widget 处理（保守）。
bool returnsWidgetOf(MethodDeclaration m) {
  final t = m.returnType?.toSource().trim() ?? '';
  if (t.isEmpty) return true;
  return t.contains('Widget');
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
  /// 命中时调用点整体翻译成 `__jsui.host("通道名", 参数载荷)`（载荷形态见
  /// [hostArgsJs]）——参数个数、是否具名、返回值类型都无关（宿主侧用
  /// Function.apply 调实现）。
  final Map<String, Map<String, String>> hostMethods;

  /// 局部变量别名：`final list = _list;` → `list → this._list`。
  /// 抽成实例方法的懒加载 builder（`_listViewBuilderN`）里引用被捕获的
  /// 局部变量时必须落到真实字段引用，否则是未定义的自由变量。
  final Map<String, String> localAliases;

  FieldScope({
    this.propByField = const {},
    this.instanceFields = const {},
    this.params = const {},
    this.methods = const {},
    this.hostMethods = const {},
    Map<String, String>? localAliases,
    Set<String>? localVars,
    Set<String>? globalConsts,
  })  : localVars = localVars ?? {},
        localAliases = localAliases ?? const {},
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
        localAliases: localAliases,
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
// 后续新增 SDK 支持 = 往这张表加一行 +（如需要）在运行时注册对应基类 + 在
// builtin_translators.dart 登记对应 widget 翻译策略。
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
// 表达式 / 语句翻译（以 FieldScope + 已知类表为键）
// ---------------------------------------------------------------------------

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

/// List/Iterable 的属性 → JS 数组等价写法。
///
/// JS 数组没有 `first` / `last` / `isEmpty`（Dart 有），一比一透传会在运行时
/// 得到 `undefined`。按 JS 数组语义改写：`xs.first` → `xs[0]`、
/// `xs.last` → `xs[xs.length - 1]`、`xs.isEmpty` → `(xs.length === 0)`。
/// 其余属性（`length` 等 JS 同名）返回 null，调用方按原样透传。
String? _listPropJs(String base, String prop) => switch (prop) {
      'first' => '$base[0]',
      'last' => '$base[$base.length - 1]',
      'isEmpty' => '($base.length === 0)',
      'isNotEmpty' => '($base.length > 0)',
      // `list.reversed` → 反转副本（Dart 返回 Iterable；后续 `.toList()` 已被
      // 去掉、数组语义一致）。
      'reversed' => '[...$base].reverse()',
      _ => null,
    };

/// 读位置表达式 → JS 表达式（this._model.n / this._model / 字面量 / 形参）。
String? exprToJs(Expression e, FieldScope scope, Map<String, ClassInfo> classes) {
  // 颜色字面量：任意位置都直接译成 '#aarrggbb'（不再只支持 widget 样式属性）。
  final color = colorLiteralJs(e);
  if (color != null) return color;
  // Platform.isAndroid 等（PrefixedIdentifier 是 Identifier 子类，必须先判）
  if (e is PrefixedIdentifier && e.prefix.name == 'Platform') {
    final flag = platformFlagJs(e.identifier.name);
    if (flag != null) return flag;
  }
  // 通用 `a.b`：前缀与属性都是简单标识符时 analyzer 用 PrefixedIdentifier
  // （不是 PropertyAccess），如 `ids.length` / `_user.name` / `m.keys`。
  // 不在这里拦下来，它会落到下面的 Identifier 分支，用整串 `a.b` 去查字段
  // 必然失败——这是「属性访问普遍翻译不出来」的根因。
  if (e is PrefixedIdentifier) {
    // State 内 `widget.x`（访问 widget 自身字段）→ 合并类的实例属性 `this.x`：
    // widget 与 State 在 JS 侧是同一个类，widget 字段即实例字段。
    if (e.prefix.name == 'widget') {
      return scope.fieldRef(e.identifier.name);
    }
    // `Icons.chevron_right` → 图标名字符串（运行时按名映射回 IconData）。
    // 不在这里拦下来，会落到下面的「大写开头前缀原样保留」，产出未定义的 JS
    // 全局 `Icons`——作为组件实参（`_DevRow(icon: Icons.x)`）直接运行时崩。
    if (e.prefix.name == 'Icons') return jsString(e.identifier.name);
    // `Colors.white` → 色值字符串（'#FFFFFF'）。不在这里拦下来会落到下面
    // 「大写开头前缀原样保留」，产出**未定义全局** `Colors`——组件实参
    // （`Material(color: Colors.white)`）在 build() 求值对象字面量时即
    // ReferenceError：事件 setState 触发的重建整棵抛错并被吞掉，表现为
    // 「点击有反馈但状态永不更新」。
    if (e.prefix.name == 'Colors') {
      final hex = materialColorHex(e.identifier.name);
      if (hex != null) return "'#$hex'";
    }
    final p = scope.fieldRef(e.prefix.name);
    String? base;
    if (p != null) {
      base = p;
    } else if (scope.globalConsts.contains(e.prefix.name)) {
      // 前缀是顶层常量（如 `kOrderStatus.first`）→ JS 侧同名模块级常量。
      base = e.prefix.name;
    } else if (e.prefix.name.isNotEmpty &&
        RegExp(r'^[A-Z]').hasMatch(e.prefix.name)) {
      // prefix 是大写开头的外部类名（如 Network.post）→ 原样保留。
      base = e.prefix.name;
    }
    if (base == null) return null;
    final lp = _listPropJs(base, e.identifier.name);
    if (lp != null) return lp;
    return '$base.${e.identifier.name}';
  }
  // StringInterpolation 是 StringLiteral 子类，必须先判（否则被字面量分支
  // 吞成 ""——插值表达式丢失）：拼接触发与 _logArgJs 同一逻辑。
  if (e is StringInterpolation) return _logArgJs(e, scope, classes);
  // 相邻字符串字面量（`'a' 'b'`）→ `+` 拼接。
  if (e is AdjacentStrings) {
    final parts = <String>[];
    for (final s in e.strings) {
      final v = exprToJs(s, scope, classes);
      if (v == null) return null;
      parts.add(v);
    }
    return parts.join(' + ');
  }
  // `a ?? b` → JS 原生空值合并（方法体内如 `_switchOn = v ?? false`）
  if (e is BinaryExpression && e.operator.lexeme == '??') {
    final l = exprToJs(e.leftOperand, scope, classes);
    final r = exprToJs(e.rightOperand, scope, classes);
    if (l == null || r == null) return null;
    return '($l ?? $r)';
  }
  // 比较 / 逻辑 / 算术二元运算：一比一翻译（条件、循环、三目、数据绑定都用得到；
  // 组件数据表达式与模型方法体共用这一处，不再各写一套）。
  if (e is BinaryExpression) {
    final op = e.operator.lexeme;
    if (const <String>{
      '>', '<', '>=', '<=', '==', '!=', '&&', '||', '+', '-', '*', '/', '%'
    }.contains(op)) {
      final l = exprToJs(e.leftOperand, scope, classes);
      final r = exprToJs(e.rightOperand, scope, classes);
      if (l == null || r == null) return null;
      return '($l $op $r)';
    }
    // Dart 整除 `a ~/ b`：JS 无对应运算符，转 Math.floor(a / b)。
    if (op == '~/') {
      final l = exprToJs(e.leftOperand, scope, classes);
      final r = exprToJs(e.rightOperand, scope, classes);
      if (l == null || r == null) return null;
      return 'Math.floor($l / $r)';
    }
  }
  // 级联 `target..m(a)..n(b)`：Dart 返回 target 本身。译成 IIFE：
  // `(() => { const _t = <target>; _t.m(a); _t.n(b); return _t; })()`。
  // 常见形态 `list..sort(cmp)`（原方法体内就地排序）与 `c..addListener(..)`，
  // 顺序与返回值都与 Dart 一致。
  if (e is CascadeExpression) {
    final t = exprToJs(e.target, scope, classes);
    if (t == null) return null;
    final stmts = <String>[];
    for (final s in e.cascadeSections) {
      if (s is MethodInvocation) {
        final argsJs = <String>[];
        for (final a in s.argumentList.arguments) {
          final inner = a is NamedExpression ? a.expression : a;
          final v = inner is FunctionExpression
              ? closureToJs(inner, scope, classes)
              : rhsToJs(inner, scope, classes);
          if (v == null) return null;
          argsJs.add(v);
        }
        stmts.add('_t.${s.methodName.name}(${argsJs.join(', ')})');
      } else if (s is PropertyAccess) {
        stmts.add('_t.${s.propertyName.name}');
      } else {
        return null;
      }
    }
    return '(() => { const _t = $t; ${stmts.join('; ')}; return _t; })()';
  }
  // 三目 `c ? a : b`（组件数据/样式与模型方法体共用）。
  if (e is ConditionalExpression) {
    final c = exprToJs(e.condition, scope, classes);
    final t = exprToJs(e.thenExpression, scope, classes);
    final f = exprToJs(e.elseExpression, scope, classes);
    if (c == null || t == null || f == null) return null;
    return '($c ? $t : $f)';
  }
  // switch 表达式（Dart 3）→ IIFE + JS switch（JS 无 switch 表达式语法）。
  if (e is SwitchExpression) return _switchExpressionJs(e, scope, classes);
  // `this`（如 `TabController(length: n, vsync: this)`）：JS 侧方法/构造实参里
  // 的 this 就是组件实例，一比一透传；Dart 侧专属的实参（vsync）由 JS 代理类
  // 构造自行忽略。
  if (e is ThisExpression) return 'this';
  if (e is Identifier) {
    // kDebugMode / kReleaseMode → 运行时注入的全局标志
    final flag = globalFlagJs(e.name);
    if (flag != null) return flag;
    // State.mounted：JS 组件基类有 __unmounted 标记，未卸载即视为已挂载
    if (e.name == 'mounted') return '!this.__unmounted';
    // 顶层常量（如 `kBanners`）：JS 侧是同名模块级常量，原样引用。
    if (scope.globalConsts.contains(e.name)) return e.name;
    return scope.fieldRef(e.name);
  }
  // null 字面量（`data ?? null` 等）：只影响表达式位置，字段默认值仍走
  // literalToJs 的 undefined 语义，故不并入 literalToJs。
  if (e is NullLiteral) return 'null';
  final lit = literalToJs(e);
  if (lit != null) return lit;
  if (e is PropertyAccess && e.target is Identifier &&
      (e.target as Identifier).name == 'Platform') {
    // Platform.isAndroid 等 → 运行时注入的平台标志
    final flag = platformFlagJs(e.propertyName.name);
    if (flag != null) return flag;
  }
  if (e is PropertyAccess && e.target != null) {
    // `Colors.blue.shade100` 等 MaterialColor 变体：产物放 '@Colors.blue.shade100'
    // 标记，运行时按 Flutter 官方 Colors 常量解析（与样式翻译同一约定，绝不
    // 产出未定义的 `Colors` 全局）。
    final tgt = e.target;
    if (tgt is PrefixedIdentifier && tgt.prefix.name == 'Colors') {
      return "'@Colors.${tgt.identifier.name}.${e.propertyName.name}'";
    }
    final t = exprToJs(tgt!, scope, classes);
    if (t == null) return null;
    final op = e.operator.lexeme;
    if (op == '?.') {
      return '($t == null ? null : $t.${e.propertyName.name})';
    }
    final lp = _listPropJs(t, e.propertyName.name);
    if (lp != null) return lp;
    return '$t.${e.propertyName.name}';
  }
  // 下标访问 `a[b]`（如 `userMap["code"]`）：JS 的方括号语法一一对应。
  // 与上面的通用 `a.b` 同理，不在 exprToJs 里兜住就会整条翻译失败（在插值里
  // 表现为片段被丢弃，如 `"用户信息:${userMap["code"]}"` → `"用户信息:"`）。
  if (e is IndexExpression) {
    final tgt = e.target;
    if (tgt == null) return null;
    final t = exprToJs(tgt, scope, classes);
    final i = exprToJs(e.index, scope, classes);
    if (t == null || i == null) return null;
    return '$t[$i]';
  }
  if (e is ParenthesizedExpression) {
    final inner = exprToJs(e.expression, scope, classes);
    return inner == null ? null : '($inner)';
  }
  // 自增/自减（表达式位置，如 for 更新子 `i++`）；Postfix `!` 是 Dart null
  // 断言，JS 无此概念，直接取操作数（条件短路保护）。
  if (e is PostfixExpression) {
    final v = exprToJs(e.operand, scope, classes);
    if (v == null) return null;
    if (e.operator.lexeme == '!') return v;
    return '($v${e.operator.lexeme})';
  }
  // 前缀一元（`!flag` / `-n` / `++i` / `--i`）。
  if (e is PrefixExpression) {
    final v = exprToJs(e.operand, scope, classes);
    return v == null ? null : '(${e.operator.lexeme}$v)';
  }
  if (e is MethodInvocation) return methodCallExprJs(e, scope, classes);
  return null;
}

/// 赋值右侧：字面量 / 形参 / 字段读 / 模型构造 `new X({...})` /
/// 插值、`??` 等其余形态兜底走 exprToJs。
String? rhsToJs(Expression e, FieldScope scope, Map<String, ClassInfo> classes) {
  // StringInterpolation 是 StringLiteral 子类，必须先判（否则被吞成 ""）
  if (e is StringInterpolation) return _logArgJs(e, scope, classes);
  // 相邻字符串字面量拼接（`'a' 'b'`，Dart 语义是**拼接**）同为 StringLiteral 子类，
  // 在 literalToJs 里只能翻「全为常量」的情况；这里交给 exprToJs 的
  // AdjacentStrings 分支逐段翻译，含插值的段才翻得出来（必须早于下面的 literalToJs）。
  if (e is AdjacentStrings) return exprToJs(e, scope, classes);
  // `await <expr>` 统一在这里处理：声明初始化、赋值右侧、实参、独立语句
  // 全都经过 rhsToJs，await 不再只认声明那一种位置（原来 `_x = await f()`
  // 会整条丢掉）。
  if (e is AwaitExpression) {
    final v = _awaitInnerJs(e.expression, scope, classes);
    return v == null ? null : 'await $v';
  }
  final lit = literalToJs(e);
  if (lit != null) return lit;
  // 颜色字面量（`Color(0xFF...)` / `Color.fromARGB(...)`）→ '#aarrggbb'。
  // 必须早于下面的 InstanceCreationExpression 分支：那支对非模型类返回 null
  // 后直接返回（不再往下走），颜色常量会在那里被吞掉。
  final color = colorLiteralJs(e);
  if (color != null) return color;
  // Key 构造（`ValueKey(item)` / `GlobalKey<FormState>()` / `ObjectKey(x)` /
  // `UniqueKey()`）：Key 是**值**不是结点，宿主/JS 各自有同名代理类（见
  // hot_patch capabilities/key/key_js.dart），这里一律译成 `new Xxx(...)`（裸引用
  // 全局类，与 ScrollController 等代理类同款）。必须早于下面的
  // InstanceCreationExpression 分支：那支对非模型类返回 null 后直接返回。
  final keyJs = keyCtorJs(e, scope, classes);
  if (keyJs != null) return keyJs;
  // SDK 值对象构造（`ValueNotifier<int>(0)`）：同样必须早于下面的
  // InstanceCreationExpression 分支（那支对非模型类返回 null 后直接返回）。
  final sdkValJs = sdkValueCtorJs(e, scope, classes);
  if (sdkValJs != null) return sdkValJs;
  // PrefixedIdentifier（`a.b`）不是单纯字段名，交给 exprToJs 的属性分支；
  // 若走下面的 Identifier 分支会用整串名字查字段而必然失败。
  if (e is PrefixedIdentifier) return exprToJs(e, scope, classes);
  // Identifier 一律交给 exprToJs 统一处理（全局标志 kDebugMode、State.mounted、
  // 字段/形参/局部变量同一套解析）——不再在此处单独 fieldRef，否则这些
  // 「非字段标识符」会被漏掉。
  if (e is InstanceCreationExpression) return modelCtorToJs(e, scope, classes);
  // 无 `const`/`new` 的模型构造（如 `const kX = [HomeBanner(...)]` 的元素）在无
  // resolution 的 parseString 下是 MethodInvocation。仅当名字命中已知类表时才按
  // 模型构造处理（避免把 widget 构造 `Text(...)` 误当模型）。
  if (e is MethodInvocation && e.target == null && e.typeArguments == null) {
    final n = e.methodName.name;
    if (classes.containsKey(n)) {
      final ctor = modelCtorFromPartsJs(
          n, e.argumentList.arguments.toList(), scope, classes);
      if (ctor != null) return ctor;
    }
  }
  // 集合字面量：与 JS 对象/数组一一对应（元素递归翻译）。
  // 缺了这两条，`Network.post({"name": name})` 这类调用会因「参数翻译不了」
  // 整体返回 null，调用方再把整条语句丢掉（原来的静默丢代码就出在这里）。
  if (e is SetOrMapLiteral) return _collectionLiteralJs(e, scope, classes);
  if (e is ListLiteral) return _listLiteralJs(e.elements, scope, classes);
  return exprToJs(e, scope, classes);
}

/// `await <expr>` 里的 `<expr>`（不含 await 前缀）。
/// 特殊形态 `Future.delayed(Duration(...))` → setTimeout Promise——JS 没有
/// 等价的 Dart 异步延迟 API，只映射这一种；其余 await 走普通表达式翻译。
String? _awaitInnerJs(
  Expression inner,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  final delay = delayedMsJs(inner);
  if (delay != null) {
    return 'new Promise(function(r){ setTimeout(r, $delay); })';
  }
  return rhsToJs(inner, scope, classes);
}

/// `Future.delayed(Duration(seconds: n))` → setTimeout 毫秒数（不是则 null）。
String? delayedMsJs(Expression e) {
  if (e is! MethodInvocation || e.methodName.name != 'delayed') return null;
  final target = e.target;
  if (target == null || target.toSource() != 'Future') return null;
  final args = e.argumentList.arguments;
  if (args.isEmpty) return null;
  final dur = args.first;
  String? unit;
  double? value;
  if (dur is InstanceCreationExpression &&
      dur.constructorName.type.name2.lexeme == 'Duration') {
    for (final a in dur.argumentList.arguments) {
      if (a is NamedExpression) {
        final lit = a.expression;
        if (lit is IntegerLiteral) {
          if (unit != null) return null; // 多个时间单位不支持
          unit = a.name.label.name;
          value = (lit.value ?? 0).toDouble();
        } else if (lit is DoubleLiteral) {
          if (unit != null) return null;
          unit = a.name.label.name;
          value = lit.value;
        }
      }
    }
  }
  if (unit == null || value == null) return null;
  final ms = switch (unit) {
    'seconds' => value * 1000,
    'milliseconds' => value,
    'microseconds' => value / 1000,
    'minutes' => value * 60 * 1000,
    _ => null,
  };
  if (ms == null) return null;
  return ms == ms.roundToDouble() ? '${ms.round()}' : '$ms';
}

/// `{k: v, ...}` → JS 对象字面量；`{a, b}`（Set）→ `new Set([a, b])`。
String? _collectionLiteralJs(
  SetOrMapLiteral e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  final entries = e.elements;
  // 无 resolution 下不依赖 isMap：元素全是 entry 即 Map，否则按 Set 处理。
  if (entries.every((el) => el is MapLiteralEntry)) {
    final parts = <String>[];
    for (final el in entries.whereType<MapLiteralEntry>()) {
      final k = rhsToJs(el.key, scope, classes);
      final v = rhsToJs(el.value, scope, classes);
      if (k == null || v == null) return null;
      parts.add('$k: $v');
    }
    return '{${parts.join(', ')}}';
  }
  final items = _listLiteralJs(entries, scope, classes);
  return items == null ? null : 'new Set($items)';
}

/// `[a, b]` → JS 数组字面量。展开（`...xs`）与 collection-if/for 不支持。
String? _listLiteralJs(
  NodeList<CollectionElement> elements,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  final parts = <String>[];
  for (final el in elements) {
    if (el is! Expression) return null;
    final v = rhsToJs(el, scope, classes);
    if (v == null) return null;
    parts.add(v);
  }
  return '[${parts.join(', ')}]';
}

/// 支持翻译的 Key 类名（Dart 的 Key 家族里在 JS 侧有同名代理类的部分）。
/// Key 是**值**：JS 用同名类实例承载，跨桥 toJSON 成 `{__vkey:…}` / `{__okey:…}`
/// / `{__psk:…}` / `{__handle:…}`（见 hot_patch capabilities/key/key_js.dart、
/// key/key_bridge.dart）。
/// 宿主与 JS 共用这**一条**表达式路径——widget 的 key 参数、模型字段初值、
/// 集合元素都经过 [rhsToJs]，故支持范围只在这里维护。
const Set<String> keyClassNames = {
  'ValueKey',
  'ObjectKey',
  'PageStorageKey',
  'UniqueKey',
  'GlobalKey',
};

/// Key 构造表达式 → JS `new Xxx(...)`；非 Key 构造返回 null。
///
/// 兼容两种 AST 形态：显式 `new`/`const` 是 InstanceCreationExpression；
/// 无 `new` 的 `GlobalKey<FormState>()`（带类型实参）在无 resolution 的
/// parseString 下是 MethodInvocation。实参按位置摊平（ValueKey/ObjectKey 取值，
/// GlobalKey 的 `debugLabel:` 具名实参同样落到唯一位置参）。
String? keyCtorJs(
  Expression e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  String? name;
  List<Expression> args = const [];
  if (e is InstanceCreationExpression) {
    final n = e.constructorName.type.name2.lexeme;
    if (keyClassNames.contains(n)) {
      name = n;
      args = e.argumentList.arguments.toList();
    }
  } else if (e is MethodInvocation && e.target == null) {
    final n = e.methodName.name;
    if (keyClassNames.contains(n)) {
      name = n;
      args = e.argumentList.arguments.toList();
    }
  }
  if (name == null) return null;
  final parts = <String>[];
  for (final a in args) {
    final v = rhsToJs(a is NamedExpression ? a.expression : a, scope, classes);
    if (v == null) return null;
    parts.add(v);
  }
  return 'new $name(${parts.join(', ')})';
}

/// SDK 值对象构造表达式（`ValueNotifier<int>(0)`）→ JS `new ValueNotifier(0)`；
/// 非本类返回 null。
///
/// 与 [keyCtorJs] 同款：**丢弃泛型实参**、裸引用运行时注入的同名类（见
/// hot_patch 的 change_notifier_js.dart 里 `G.ValueNotifier`）。
String? sdkValueCtorJs(
  Expression e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  String? name;
  List<Expression> args = const [];
  if (e is InstanceCreationExpression) {
    final n = e.constructorName.type.name2.lexeme;
    if (sdkValueClassNames.contains(n)) {
      name = n;
      args = e.argumentList.arguments.toList();
    }
  } else if (e is MethodInvocation && e.target == null) {
    final n = e.methodName.name;
    if (sdkValueClassNames.contains(n)) {
      name = n;
      args = e.argumentList.arguments.toList();
    }
  }
  if (name == null) return null;
  final parts = <String>[];
  for (final a in args) {
    final v = rhsToJs(a is NamedExpression ? a.expression : a, scope, classes);
    if (v == null) return null;
    parts.add(v);
  }
  return 'new $name(${parts.join(', ')})';
}

/// 运行时注入了同名 JS 类的 SDK 值对象（构造时直接裸引用 `new Xxx(...)`）。
const Set<String> sdkValueClassNames = {
  'ValueNotifier',
};

/// 模型构造调用 → JS：`new User({name:..., age:...})`。
/// 位置参数按类实例字段声明顺序映射；命名参数按 label。
String? modelCtorToJs(
  InstanceCreationExpression e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) =>
    modelCtorFromPartsJs(e.constructorName.type.name2.lexeme,
        e.argumentList.arguments.toList(), scope, classes);

/// 按「构造名 + 参数」生成 `new X({...})`。供 modelCtorToJs（InstanceCreation）
/// 与字段初始化的 MethodInvocation 形式（parseString 无 resolution 下 `Foo()`
/// 会被解析成 MethodInvocation）共用同一套映射逻辑。
String? modelCtorFromPartsJs(
  String name,
  List<Expression> args,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  final info = classes[name];
  if (info == null) return null;
  final named = <String>[];
  final positional = <String>[];
  for (final a in args) {
    if (a is NamedExpression) {
      final v = rhsToJs(a.expression, scope, classes);
      if (v == null) return null;
      named.add('${a.name.label.name}: $v');
    } else {
      final v = rhsToJs(a, scope, classes);
      if (v == null) return null;
      positional.add(v);
    }
  }
  final entries = <String>[];
  for (var i = 0; i < info.instanceFields.length && i < positional.length; i++) {
    entries.add('${info.instanceFields[i].name}: ${positional[i]}');
  }
  entries.addAll(named);
  return 'new $name({${entries.join(', ')}})';
}

/// 方法调用（语句位置，带分号）：`_model.inc()` → `this._model.inc();`；
/// 裸调用 `notifyListeners()`（MethodScope 白名单）→ `this.notifyListeners();`。
String? methodCallStmtJs(
  MethodInvocation e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  // Dart 日志 → JS 原生日志方法（运行时注入 console 对象，桥到 log 服务）：
  // debugPrint → console.debug（仅 debug 模式输出）、print → console.log。
  // 参数支持字符串插值（拼接翻译），插值对象时经 `__str` 展开字段
  //（`console.log(oldWidget)` 这类直接传对象的由运行时 console 桥负责展开）。
  if (e.target == null) {
    final name = e.methodName.name;
    if (name == 'debugPrint' || name == 'print') {
      final args = e.argumentList.arguments;
      final v = args.isEmpty
          ? '""'
          : _logArgJs(args.first, scope, classes, expand: true);
      if (v == null) return null;
      final method = name == 'debugPrint' ? 'debug' : 'log';
      return 'console.$method($v);';
    }
  }
  final call = methodCallExprJs(e, scope, classes);
  return call == null ? null : '$call;';
}

/// 日志参数 → JS 表达式：字符串 / 插值拼接 / 字段引用 / 属性链。
///
/// [expand] 仅由「日志调用」置真（`print` / `debugPrint` 的实参）：插值片段
/// 包一层运行时 `__str`，把对象/数组展开成字段文本（Dart 的 `'$x'` 走
/// `toString()`，JS 的 `+` 只给 `[object Object]`）。
/// **其余位置（widget 文案、props 数据、模型初始化）保持原样**：那里的插值
/// 值都是字符串/数字，包一层只是无谓地给产物引入 `__str` 全局依赖。
String? _logArgJs(
  Expression a,
  FieldScope scope,
  Map<String, ClassInfo> classes, {
  bool expand = false,
}) {
  // 注意：StringInterpolation 是 StringLiteral 的子类，必须先判插值
  //（否则 stringValue 会把插值表达式拼进字面量、丢失 this._x 引用）。
  if (a is StringInterpolation) {
    final parts = <String>[];
    for (final el in a.elements) {
      if (el is InterpolationString) {
        if (el.value.isNotEmpty) parts.add(jsString(el.value));
      } else if (el is InterpolationExpression) {
        final v = exprToJs(el.expression, scope, classes);
        if (v != null) {
          parts.add(expand ? '__str($v)' : v);
        } else {
          // 丢片段会让产物「看着对、其实少东西」（如 `"用户信息:$x"` →
          // `"用户信息:"`），故必须出声，不能静默。
          log.warning('[hot_patch_generator] 插值片段无法翻译，已在 JS 产物中'
              '丢失：\${${el.expression.toSource()}}');
        }
      }
    }
    return parts.isEmpty ? '""' : parts.join(' + ');
  }
  return exprToJs(a, scope, classes);
}

/// 混合调用时承载**位置实参**的哨兵键。
///
/// 用哨兵键而不是靠「有没有 `p`/`n` 两个键」来猜，是因为 Dart 标识符
/// 不允许 `@`：任何具名形参都不可能叫 `@args`，判定零歧义。
const String hostPositionalKey = '@args';

/// 宿主注入调用的参数载荷（按实参形态给最简编码）。
///
///   - 纯位置：数组 `[a, b]`（运行时用 `Array.isArray` 判定）
///   - 纯具名：具名表本身 `{"times": 2}`
///   - 混合：具名表 + [hostPositionalKey] 装位置实参
///     `{"@args": ["hi"], "times": 2}`
///
/// 位置实参与具名实参**必须分开传**，宿主侧才能用
/// `Function.apply(impl, 位置, 具名)` 还原 Dart 调用语义。绝不能像普通 JS
/// 调用那样把具名实参扁平化进数组：`Network.post(params: {...})` 会变成 1 个
/// 位置实参，而该函数只接受具名参数 `params`，`Function.apply` 直接抛异常。
///
/// 实参**个数不限**（位置数组与具名键数量都无上限）；未传的可选位置参数
/// (`[int b]`) / 具名默认值 (`int times = 1`) 由 Dart 函数自身兜底，
/// `Function.apply` 自动走默认值。
String hostArgsJs(List<String> positional, List<String> named) {
  if (named.isEmpty) return '[${positional.join(', ')}]';
  if (positional.isEmpty) return '{${named.join(', ')}}';
  return '{${jsString(hostPositionalKey)}: [${positional.join(', ')}], '
      '${named.join(', ')}}';
}

/// 闭包参数 → JS 函数表达式：`() {...}` → `function(){ ... }`、
/// `(v) => expr` → `function(v){ return <expr>; }`。
///
/// 闭包体逐语句翻译，其中 `setState(() {...})` 展开为
/// `this.setState(function(){ ... })`（与组件方法体里的 setState 同构）。
String? closureToJs(
  FunctionExpression fn,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  final params = <String>[];
  for (final p in fn.parameters?.parameters ?? const <FormalParameter>[]) {
    final name = p is DefaultFormalParameter
        ? p.parameter.name?.lexeme
        : p.name?.lexeme;
    if (name != null && name.isNotEmpty) params.add(name);
  }
  final pjs = params.join(', ');
  // 闭包形参登记进作用域：`where((o) => o.status == _status)` 里的 `o` 必须
  // 解析为形参，否则谓词翻译失败、连带整个 `where(...)` 与外围表达式被丢弃。
  final bodyScope = params.isEmpty ? scope : scope.withParams(params);
  final body = fn.body;
  // 一律输出箭头函数：this 词法绑定到定义处（组件实例），与 Dart 闭包
  // 捕获 this 的语义一致——回调（如 addListener 闭包）由宿主经 invoke
  // 普通调用触发时 this 不会丢失，无需 .bind。引擎为 flutter_js
  // （macOS/iOS JavaScriptCore、Android QuickJS），均完整支持 ES6。
  if (body is ExpressionFunctionBody) {
    // 表达式体在 Dart 里就是一个**值**，JS 侧必须 `return`，否则
    // `sort((a, b) => a.compareTo(b))` / `map((e) => e.name)` 这类回调会把
    // 返回值丢掉（谓词恒为 undefined）。先按值翻译并 return；只有值形态翻译
    // 不出来（赋值 `_x = 5`、`setState(...)` 等语句形态）才退回语句翻译。
    final rv = rhsToJs(body.expression, bodyScope, classes);
    if (rv != null) return '($pjs) => { return $rv; }';
    final v = closureBodyStmtJs(body.expression, bodyScope, classes);
    if (v != null) return '($pjs) => { $v }';
    return null;
  }
  if (body is BlockFunctionBody) {
    // 块体逐语句翻译——与方法体、`_setStateJs` 共用**同一条** [translateStmtList]：
    // 声明、if/for/while/switch、setState 展开全部覆盖。旧实现只收
    // `ExpressionStatement`，`onPick: (k, v) { setState(() { switch ... }) }`
    // 这类块体会被静默丢成 `(...) => {}`（筛选面板点选条件无任何反应）。
    final stmts =
        translateStmtList(body.block.statements, bodyScope, classes, null);
    if (stmts.trim().isEmpty) return null;
    return '($pjs) => { ${stmts.trim()} }';
  }
  return null;
}

/// 闭包体内的单条表达式语句 → JS：与方法体共用 [\_bodyExprStmtJs]
/// （`setState(...)` 展开 + 赋值/自增/对象方法调用等）。保留本函数只为兼容
/// 表达式体闭包的调用点（`(v) => expr` 分支）。
String? closureBodyStmtJs(
  Expression e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) =>
    _bodyExprStmtJs(e, scope, classes);

/// 方法调用（表达式位置）：返回 `obj.method(args)` / `this.method(args)`。
String? methodCallExprJs(
  MethodInvocation e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  // `context.watch<T>()` / `context.read<T>()`（provider 包）→ **调用面与 Dart
  // 完全一致**：`context.watch("T")`，`context` 是运行时传入 build 的
  // BuildContext 代理（见 hot_patch 的 capabilities/build_context/build_context_js.dart）。
  // 类型实参 `T` 原样传给 JS——本端按类型名沿 `__parent` 找最近的 provider
  // 宿主结点，同时把类型名发给宿主（Dart 端通用 VM 记着它）。
  // receiver 走 [exprToJs] 而非硬编码：构建作用域里就是形参 `context`；
  // 事件等**延迟作用域**里形参不可见，由作用域别名解析成 `this.context`
  // （运行时按执行位置解析到对应代理，见 WidgetTranslateContext._eventScope）。
  final tgt = e.target;
  if (tgt is Identifier && tgt.name == 'context') {
    final name = e.methodName.name;
    if ((name == 'watch' || name == 'read') &&
        e.argumentList.arguments.isEmpty) {
      final ta = e.typeArguments?.arguments;
      if (ta != null && ta.length == 1 && ta.first is NamedType) {
        final model = (ta.first as NamedType).name2.lexeme;
        final recv = exprToJs(tgt, scope, classes) ?? 'context';
        return '$recv.$name(${jsString(model)})';
      }
      return null;
    }
  }
  // Dart `num.toStringAsFixed(n)` → JS `toFixed(n)`（插值格式化数字常用）。
  // 组件数据表达式与模型方法体共用这一处翻译。
  if (e.methodName.name == 'toStringAsFixed' &&
      e.target != null &&
      e.argumentList.arguments.length == 1) {
    final t = exprToJs(e.target!, scope, classes);
    final a = exprToJs(e.argumentList.arguments.first, scope, classes);
    if (t != null && a != null) return '$t.toFixed($a)';
    return null;
  }
  // Dart 集合 API → JS 数组 API（List/Iterable 在 JS 侧就是数组）：
  //   `xs.where(f)` → `xs.filter(f)`；`xs.where(f).toList()` → `xs.filter(f)`；
  //   `xs.toList()` → `xs`（数组本身即 List，无需拷贝）。
  // 缺这一条，订单页 `kOrders.where((o) => ...).toList()` 这类过滤整条失败。
  if (e.target != null) {
    final collName = e.methodName.name;
    if (collName == 'toList' && e.argumentList.arguments.isEmpty) {
      return exprToJs(e.target!, scope, classes);
    }
    if (collName == 'where' && e.argumentList.arguments.length == 1) {
      final t = exprToJs(e.target!, scope, classes);
      if (t == null) return null;
      final fn = e.argumentList.arguments.first;
      if (fn is! FunctionExpression) return null;
      final fnJs = closureToJs(fn, scope, classes);
      if (fnJs == null) return null;
      return '$t.filter($fnJs)';
    }
    // `list.sort((a, b) => …)` → 就地排序（JS Array.sort 同位，返回值仍为数组）；
    // Dart 的 `..sort()` 级联见 [exprToJs] 的 CascadeExpression 分支。
    if (collName == 'sort' && e.argumentList.arguments.length == 1) {
      final t = exprToJs(e.target!, scope, classes);
      if (t == null) return null;
      final fn = e.argumentList.arguments.first;
      if (fn is! FunctionExpression) return null;
      final fnJs = closureToJs(fn, scope, classes);
      if (fnJs == null) return null;
      return '$t.sort($fnJs)';
    }
    // `b.like.compareTo(a.like)` → `(b.like - a.like)`（数值比较；用于排序比较器）。
    if (collName == 'compareTo' && e.argumentList.arguments.length == 1) {
      final t = exprToJs(e.target!, scope, classes);
      final o = exprToJs(e.argumentList.arguments.first, scope, classes);
      if (t == null || o == null) return null;
      return '($t - $o)';
    }
    // 就地增删（List 在 JS 侧就是数组），**方法名两边都有、语义也一致**，故在此
    // 只做「形参 → 内建 API」的改写（点名映射）：
    //   `xs.add(v)`      → `xs.push(v)`
    //   `xs.removeAt(i)` → `xs.splice(i, 1)[0]`（返回被删元素，供重排复用）
    //   `xs.insert(i, v)`→ `xs.splice(i, 0, v)`
    // ReorderableListView 的 onReorder 重排惯用法（removeAt + insert）依赖这组。
    if (collName == 'add' && e.argumentList.arguments.length == 1) {
      final t = exprToJs(e.target!, scope, classes);
      final v = exprToJs(e.argumentList.arguments.first, scope, classes);
      if (t == null || v == null) return null;
      return '$t.push($v)';
    }
    if (collName == 'removeAt' && e.argumentList.arguments.length == 1) {
      final t = exprToJs(e.target!, scope, classes);
      final i = exprToJs(e.argumentList.arguments.first, scope, classes);
      if (t == null || i == null) return null;
      return '$t.splice($i, 1)[0]';
    }
    if (collName == 'insert' && e.argumentList.arguments.length == 2) {
      final t = exprToJs(e.target!, scope, classes);
      final i = exprToJs(e.argumentList.arguments[0], scope, classes);
      final v = exprToJs(e.argumentList.arguments[1], scope, classes);
      if (t == null || i == null || v == null) return null;
      return '$t.splice($i, 0, $v)';
    }
    // 【项目规则】Dart 方法「在原生 JS 对应类型上不存在」的，**不在本层做名字映射**，
    // 而是由 JS 运行时给该内建补一个同名同义的方法（补齐点见 hot_patch 的
    // packages/hot_patch/lib/src/js_ui/runtime_source.dart【1c】，产物原样调用）。
    // 本函数只看得到**方法名**、拿不到接收者类型（生成器不带 resolution），而 Dart
    // 方法名与别的类的同名方法经常撞车——`clear` 既是 `List.clear()`，也是
    // `TextEditingController.clear()`（本仓库 lib/components/widget_details.dart 的
    // 「清空输入」按钮就在用）。按名字映射成 `length = 0` 会把控制器那次 clear 静默
    // 改错；补齐到 Array.prototype 则天然按接收者类型分发，别处同名方法分毫不动。
    // 上面那组 `add`/`removeAt`/`insert` 属**另一类**：内建已有对应 API、只是名字/
    // 形参不同，才由本层点名改写。
  }
  final args = e.argumentList.arguments;
  final argJs = <String>[]; // 普通调用：位置化扁平（JS 无具名参数）
  final posJs = <String>[]; // 宿主注入：位置实参
  final namedJs = <String>[]; // 宿主注入：具名实参（`"名": 值`）
  for (final a in args) {
    // 闭包参数（addListener(() {...}) / TextButton(onPressed: () => ...) 等）：
    // 翻译成 JS 函数表达式，匿名天然支持——不合成方法名、无重名问题。
    // 闭包体逐语句翻译，setState(...) 展开为 this.setState(function(){...})。
    if (a is FunctionExpression) {
      final fnJs = closureToJs(a, scope, classes);
      if (fnJs == null) return null;
      argJs.add(fnJs);
      posJs.add(fnJs);
      continue;
    }
    // 命名方法引用（`_controller.addListener(_onControllerChanged)`）：Dart
    // tear-off 语义 → 箭头包装（this 词法绑定组件实例，与匿名闭包形态一致），
    // 参数透传以便用于带参回调（builder 等）。仅当名字是本组件方法时包装，
    // 状态字段/局部变量照常 rhsToJs。
    if (a is Identifier && scope.isMethod(a.name)) {
      final wrap = '(...args) => this.${a.name}(...args)';
      argJs.add(wrap);
      posJs.add(wrap);
      continue;
    }
    if (a is NamedExpression) {
      final v = rhsToJs(a.expression, scope, classes);
      if (v == null) return null;
      argJs.add(v);
      namedJs.add('${jsString(a.name.label.name)}: $v');
    } else {
      final v = rhsToJs(a, scope, classes);
      if (v == null) return null;
      argJs.add(v);
      posJs.add(v);
    }
  }
  // 宿主注入（@HostInjected）：static 调用 `AccountCenter.getUserName(a)`
  // 整体替换为 `__jsui.host("通道名", {p: [a], n: {...}})`（返回 Promise，可 await）。
  final hostTarget = e.target;
  if (hostTarget is Identifier) {
    final channel = scope.hostMethods[hostTarget.name]?[e.methodName.name];
    if (channel != null) {
      return '__jsui.host(${jsString(channel)}, ${hostArgsJs(posJs, namedJs)})';
    }
  }
  final passed = argJs.join(', ');
  final target = e.target;
  if (target == null) {
    // 顶层函数（全局方法）：@HostInjected → `__jsui.host("通道", {p, n})`。
    final topChannel = scope.hostMethods['']?[e.methodName.name];
    if (topChannel != null) {
      return '__jsui.host(${jsString(topChannel)}, ${hostArgsJs(posJs, namedJs)})';
    }
    if (!scope.isMethod(e.methodName.name)) return null;
    return 'this.${e.methodName.name}($passed)';
  }
  if (target is Identifier) {
    final ref = scope.fieldRef(target.name);
    if (ref != null) return '$ref.${e.methodName.name}($passed)';
  }
  final t = exprToJs(target, scope, classes);
  if (t != null) return '$t.${e.methodName.name}($passed)';
  return null;
}

/// `<字段>.<属性>`（PrefixedIdentifier）→ JS 引用串（`this._count.value`）。
///
/// 用于 SDK 值对象（`ValueNotifier<int>` 等）的典型用法：字段本身走
/// [FieldScope.fieldRef]（→ `this._count` / 局部变量名），属性部分原样拼接
/// （JS 侧同名属性 / get 访问器）。LHS 不是「本 scope 可解析字段」时返回 null，
/// 交由调用方丢弃（保持「不可翻译不静默错译」的纪律）。
String? _prefixedFieldRef(Expression e, FieldScope scope) {
  if (e is! PrefixedIdentifier) return null;
  final base = scope.fieldRef(e.prefix.name);
  if (base == null) return null;
  return '$base.${e.identifier.name}';
}

/// 纯标识符判定：`_x` 是，`_x.y`（[PrefixedIdentifier]）**不是**。
///
/// **不能只写 `is Identifier`**：analyzer 里 `PrefixedIdentifier` 也
/// `implements Identifier`，裸判定会把 `_count.value++` 当成字段 `_count.value`
/// 的标识符，`fieldRef` 解析不到就整条丢弃（静默丢代码）。
bool _isPlainIdentifier(Expression e) => e is Identifier && e is! PrefixedIdentifier;

/// 一条表达式语句 → JS 语句（带分号）。
///
/// 支持：`_x++ / _x-- / ++_x / --_x`（字段→this）、赋值 `_x = rhs / _x op= rhs`、
/// 字段属性赋值/自增 `_x.y = rhs` / `_x.y++`（[`_prefixedFieldRef`]）、
/// 方法调用（对象方法 / 白名单裸调）。不可翻译返回 null（由调用方丢弃）。
String? exprStmtToJs(Expression e, FieldScope scope, Map<String, ClassInfo> classes) {
  // _x++ / ++_x / _x--
  if (e is PostfixExpression && _isPlainIdentifier(e.operand)) {
    final ref = scope.fieldRef((e.operand as Identifier).name);
    if (ref != null) {
      final delta = e.operator.type.name == 'PLUS_PLUS' ? '1' : '-1';
      return '$ref += $delta;';
    }
    return null;
  }
  if (e is PrefixExpression && _isPlainIdentifier(e.operand)) {
    final ref = scope.fieldRef((e.operand as Identifier).name);
    if (ref != null) {
      final delta = e.operator.type.name == 'PLUS_PLUS' ? '1' : '-1';
      return '$ref += $delta;';
    }
    return null;
  }
  if (e is AssignmentExpression && _isPlainIdentifier(e.leftHandSide)) {
    final ref = scope.fieldRef((e.leftHandSide as Identifier).name);
    if (ref != null) {
      final rhs = rhsToJs(e.rightHandSide, scope, classes);
      if (rhs != null) return '$ref ${e.operator.lexeme} $rhs;';
    }
    return null;
  }
  // 字段的属性赋值 / 自增（`_count.value = 5`、`_count.value++`）：
  // SDK 值对象（ValueNotifier / Listenable 代理类）的典型用法，LHS 是
  // PrefixedIdentifier（`<字段>.<属性>`）。字段部分走 fieldRef（→ `this._count`），
  // 属性部分原样保留（JS 侧同名属性/访问器，如 ValueNotifier.prototype.value）。
  if (e is AssignmentExpression && _prefixedFieldRef(e.leftHandSide, scope) != null) {
    final lhs = _prefixedFieldRef(e.leftHandSide, scope)!;
    final rhs = rhsToJs(e.rightHandSide, scope, classes);
    if (rhs != null) return '$lhs ${e.operator.lexeme} $rhs;';
    return null;
  }
  if ((e is PostfixExpression || e is PrefixExpression)) {
    final operand = e is PostfixExpression ? e.operand : (e as PrefixExpression).operand;
    final lhs = _prefixedFieldRef(operand, scope);
    if (lhs != null) {
      final op = e is PostfixExpression ? e.operator : (e as PrefixExpression).operator;
      final delta = op.type.name == 'PLUS_PLUS' ? '1' : '-1';
      return '$lhs += $delta;';
    }
  }
  // 独立语句 `await <expr>;`：await 的翻译统一在 rhsToJs 里。
  if (e is AwaitExpression) {
    final v = rhsToJs(e, scope, classes);
    return v == null ? null : '$v;';
  }
  if (e is MethodInvocation) return methodCallStmtJs(e, scope, classes);
  return null;
}

// ---------------------------------------------------------------------------
// 类 JS 声明渲染
// ---------------------------------------------------------------------------

/// **唯一**的「方法体 → JS」翻译器：组件动作/State 生命周期、模型方法、状态类
/// 方法全部走这里。
///
/// 语句（表达式语句 / 变量声明 / return / if …）与表达式（[exprToJs]/[rhsToJs]/
/// [exprStmtToJs]）都只在这一处与那一处处理——新增一种语法/能力，组件与普通类
/// 同时生效，不存在「组件的搞一遍、普通类再搞一遍」。
///
/// 参数：
///   - [scope]：标识符解析作用域（组件：状态字段→属性；模型：实例字段）。
///   - [widgetCtx]：可选。传入后，返回 Widget 的表达式（如 `return Container(...)`）
///     走 widget 树翻译路径。
///   - [returnExpressionBody]：箭头体是否包 `return`（Dart 有返回值语义时为真；
///     组件动作方法为假，产物与语句一致）。
String translateMethodBody(
  FunctionBody? body,
  FieldScope scope,
  Map<String, ClassInfo> classes, {
  WidgetExprRenderer? widgetCtx,
  bool returnExpressionBody = false,
  bool returnsWidget = true,
  int depth = 2,
}) {
  final out = <String>[];
  final ind = '  ' * depth;
  if (body is ExpressionFunctionBody) {
    final e = body.expression;
    String? t;
    if (widgetCtx != null && returnsWidget && _isWidgetCtorExpr(e)) {
      t = _widgetExprToJs(widgetCtx, e, depth);
    }
    t ??= _bodyExprStmtJs(e, scope, classes);
    if (t != null) {
      out.add('$ind${returnExpressionBody ? 'return $t;' : t}');
    } else {
      // 语句级不认的表达式（switch 表达式、集合字面量、纯值表达式）：回退到
      // 通用表达式翻译。缺这一步会让「箭头体方法」静默产出空方法体
      // （如 `Color _statusColor(s) => switch (s) {...}` → 空 `{}`）。
      final v = rhsToJs(e, scope, classes);
      if (v != null) {
        out.add('$ind${returnExpressionBody ? 'return $v;' : v}');
      } else {
        log.warning('[hot_patch_generator] 方法体表达式无法翻译，已在 JS '
            '产物中丢弃：${e.toSource()}');
      }
    }
  } else if (body is BlockFunctionBody) {
    final r = translateStmtList(body.block.statements, scope, classes, widgetCtx,
        depth: depth, returnsWidget: returnsWidget);
    if (r.isNotEmpty) out.add(r);
  }
  return out.isEmpty ? '' : out.join('\n');
}

/// 语句列表 → JS（方法体块、if 分支体共用同一套循环）。
///
/// 支持：表达式语句（super 调用忽略、setState 展开）、变量声明、return、
/// if/else、for（三段式 / for-in）、while、do-while、switch（常量 case）、
/// break / continue。无法翻译的语句出声告警（不静默丢代码）。
///
/// 输出为**多行可读**格式：每条语句一行、按 [depth] 缩进（2 空格/层）。
String translateStmtList(
  List<Statement> stmts,
  FieldScope scope,
  Map<String, ClassInfo> classes,
  WidgetExprRenderer? widgetCtx, {
  int depth = 0,
  bool returnsWidget = true,
}) {
  final out = <String>[];
  final ind = '  ' * depth;
  for (final s in stmts) {
    if (s is ExpressionStatement) {
      final e = s.expression;
      // super.initState() 等 super 调用：JS 无 super 语义，忽略。
      if (e is MethodInvocation && e.target is SuperExpression) continue;
      final t = _bodyExprStmtJs(e, scope, classes);
      if (t != null) {
        out.add('$ind$t');
      } else {
        log.warning('[hot_patch_generator] 语句无法翻译，已在 JS 产物中'
            '丢弃：${e.toSource()}');
      }
    } else if (s is VariableDeclarationStatement) {
      // 局部变量声明 `String? name = await X.y();` → `var name = ...;`，
      // 名字登记进 scope，后续语句（含插值）可直接引用。
      for (final v in s.variables.variables) {
        final name = v.name.lexeme;
        // 同步登记到 widget 层：方法体里随后 `return Text('$name')` 时，
        // widget 翻译器要用同一份局部变量表解析标识符（与语句翻译同源）。
        widgetCtx?.registerLocal(name);
        if (v.initializer == null) {
          out.add('${ind}var $name;');
          scope.localVars.add(name);
          continue;
        }
        final init = rhsToJs(v.initializer!, scope, classes);
        if (init == null) {
          // 变量没声明 → 后面引用它的语句（含插值）会连带失效，必须出声。
          log.warning('[hot_patch_generator] 局部变量声明无法翻译，已在 JS '
              '产物中丢弃：${s.toSource()}');
          continue;
        }
        out.add('${ind}var $name = $init;');
        scope.localVars.add(name);
        // 该局部只是「字段 / getter 的别名」（`final list = _list;` →
        // `this._list`）：同步登记进 widget 层，懒加载 builder 抽成实例方法后
        // 引用它时才能落到 `this._list`，而不是未定义的自由变量。
        if (init.startsWith('this.')) {
          widgetCtx?.registerLocalAlias(name, init);
        }
      }
    } else if (s is ReturnStatement) {
      // `return "22";` 是 ReturnStatement（不是 ExpressionStatement），
      // 需单独翻译为 `return <expr>;`，否则 async 方法体被整体丢弃。
      final e = s.expression;
      if (e == null) {
        out.add('${ind}return;');
        continue;
      }
      String? v;
      if (widgetCtx != null && returnsWidget && _isWidgetCtorExpr(e)) {
        v = _widgetExprToJs(widgetCtx, e, depth);
      }
      v ??= rhsToJs(e, scope, classes);
      if (v != null) {
        out.add('${ind}return $v;');
      } else {
        log.warning('[hot_patch_generator] return 表达式无法翻译，已在 JS '
            '产物中丢弃：${s.toSource()}');
      }
    } else if (s is IfStatement) {
      final condJs = exprToJs(s.expression, scope, classes);
      if (condJs == null) {
        log.warning('[hot_patch_generator] if 条件无法翻译，已在 JS 产物中'
            '丢弃：${s.toSource()}');
        continue;
      }
      final thenStmts =
          s.thenStatement is Block ? (s.thenStatement as Block).statements : [s.thenStatement];
      var js = '$ind' 'if ($condJs) {\n'
          '${translateStmtList(thenStmts, scope, classes, widgetCtx, depth: depth + 1, returnsWidget: returnsWidget)}\n'
          '$ind}';
      final els = s.elseStatement;
      if (els != null) {
        final elseStmts = els is Block ? els.statements : [els];
        js += ' else {\n'
            '${translateStmtList(elseStmts, scope, classes, widgetCtx, depth: depth + 1, returnsWidget: returnsWidget)}\n'
            '$ind}';
      }
      out.add(js);
    } else if (s is ForStatement) {
      final js = _forStatementJs(s, scope, classes, widgetCtx, depth, returnsWidget);
      if (js == null) {
        log.warning('[hot_patch_generator] for 语句无法翻译，已在 JS 产物中'
            '丢弃：${s.toSource()}');
      } else {
        out.add(js);
      }
    } else if (s is WhileStatement) {
      final condJs = exprToJs(s.condition, scope, classes);
      if (condJs == null) {
        log.warning('[hot_patch_generator] while 条件无法翻译，已在 JS 产物'
            '中丢弃：${s.toSource()}');
        continue;
      }
      out.add('$ind' 'while ($condJs) {\n'
          '${translateStmtList(_bodyStmts(s.body), scope, classes, widgetCtx, depth: depth + 1, returnsWidget: returnsWidget)}\n'
          '$ind}');
    } else if (s is DoStatement) {
      final condJs = exprToJs(s.condition, scope, classes);
      if (condJs == null) {
        log.warning('[hot_patch_generator] do-while 条件无法翻译，已在 JS '
            '产物中丢弃：${s.toSource()}');
        continue;
      }
      out.add('$ind' 'do {\n'
          '${translateStmtList(_bodyStmts(s.body), scope, classes, widgetCtx, depth: depth + 1, returnsWidget: returnsWidget)}\n'
          '$ind} while ($condJs);');
    } else if (s is SwitchStatement) {
      final js = _switchStatementJs(s, scope, classes, widgetCtx, depth, returnsWidget);
      if (js == null) {
        log.warning('[hot_patch_generator] switch 语句无法翻译（仅支持常量 '
            'case），已在 JS 产物中丢弃：${s.toSource()}');
      } else {
        out.add(js);
      }
    } else if (s is BreakStatement) {
      out.add('${ind}break;');
    } else if (s is ContinueStatement) {
      out.add('${ind}continue;');
    }
  }
  return out.join('\n');
}

/// 语句体 → 语句列表（Block 或单条语句统一成列表，供 translateStmtList 递归）。
List<Statement> _bodyStmts(Statement s) => s is Block ? s.statements : [s];

/// for 语句 → JS（三段式与 for-in）：
///   - `for (var i = 0; i < n; i++)` → 一比一（循环变量登记进 localVars）；
///   - `for (var x in list)` → `for (var x of list)`（Dart 可迭代 → JS 数组）。
/// 不可翻译返回 null（调用方出声告警）。
String? _forStatementJs(
  ForStatement s,
  FieldScope scope,
  Map<String, ClassInfo> classes,
  WidgetExprRenderer? widgetCtx,
  int depth,
  bool returnsWidget,
) {
  final parts = s.forLoopParts;
  String? header;
  if (parts is ForEachPartsWithDeclaration) {
    // for-in 声明式：`for (var x in list)` → `for (var x of list)`。
    final name = parts.loopVariable.name.lexeme;
    scope.localVars.add(name);
    final it = exprToJs(parts.iterable, scope, classes);
    if (it == null) return null;
    header = 'for (let $name of $it)';
  } else if (parts is ForEachPartsWithIdentifier) {
    // for-in 复用已有变量：`for (x in list)` → `for (x of list)`。
    final it = exprToJs(parts.iterable, scope, classes);
    if (it == null) return null;
    header = 'for (${parts.identifier.name} of $it)';
  } else if (parts is ForParts) {
    // 三段式：`for (var i = 0; i < n; i++)` → 一比一。
    final inits = <String>[];
    if (parts is ForPartsWithDeclarations) {
      for (final v in parts.variables.variables) {
        final name = v.name.lexeme;
        scope.localVars.add(name);
        if (v.initializer == null) {
          inits.add('let $name');
          continue;
        }
        final rhs = rhsToJs(v.initializer!, scope, classes);
        if (rhs == null) return null;
        inits.add('let $name = $rhs');
      }
    } else if (parts is ForPartsWithExpression) {
      final init = parts.initialization;
      if (init != null) {
        final t = exprToJs(init, scope, classes);
        if (t == null) return null;
        inits.add(t);
      }
    } else {
      return null; // ForPartsWithPattern：Dart 3 模式 for 头
    }
    String? condJs;
    if (parts.condition != null) {
      condJs = exprToJs(parts.condition!, scope, classes);
      if (condJs == null) return null;
    }
    final upds = <String>[];
    for (final u in parts.updaters) {
      final t = exprToJs(u, scope, classes);
      if (t == null) return null;
      upds.add(t);
    }
    header = 'for (${inits.join(', ')}; ${condJs ?? ''}; ${upds.join(', ')})';
  } else {
    return null;
  }
  final ind = '  ' * depth;
  final bodyJs = translateStmtList(_bodyStmts(s.body), scope, classes, widgetCtx,
      depth: depth + 1, returnsWidget: returnsWidget);
  return '$ind$header {\n$bodyJs\n$ind}';
}

/// switch 语句 → JS switch。仅支持常量 case（analyzer 把常量 case 也解析为
/// SwitchPatternCase(ConstantPattern)）与 default：
///   - Dart 无贯穿语义：非空 case 体若不以 return / break / continue / throw
///     收尾，自动补 `break;`（空 case 体是显式贯穿，JS 天然同形）；
///   - guard / 解构 / 关系 / 逻辑或等模式、带 label 的 case 暂不支持，
///     返回 null 整体丢弃（调用方出声告警），避免产出半翻译的 switch。
String? _switchStatementJs(
  SwitchStatement s,
  FieldScope scope,
  Map<String, ClassInfo> classes,
  WidgetExprRenderer? widgetCtx,
  int depth,
  bool returnsWidget,
) {
  final subj = exprToJs(s.expression, scope, classes);
  if (subj == null) return null;
  final ind = '  ' * depth;
  final caseInd = '  ' * (depth + 1);
  final lines = <String>['$ind' 'switch ($subj) {'];
  for (final member in s.members) {
    if (member.labels.isNotEmpty) return null; // 带标签的 break/continue 不支持
    String? label;
    if (member is SwitchDefault) {
      label = 'default:';
    } else if (member is SwitchPatternCase) {
      // Dart 3 解析形态：常量 case 也是 SwitchPatternCase(ConstantPattern)
      //（实测 analyzer 7 对 switch 语句不再产出旧 SwitchCase）。
      if (member.guardedPattern.whenClause != null) return null;
      final p = member.guardedPattern.pattern;
      if (p is WildcardPattern) {
        label = 'default:'; // `case _:` 等价 default
      } else if (p is ConstantPattern) {
        final v = exprToJs(p.expression, scope, classes);
        if (v == null) return null;
        label = 'case $v:';
      } else {
        return null; // 解构 / 关系 / 逻辑或等模式
      }
    } else if (member is SwitchCase) {
      // 旧解析形态兜底（常量 case 直接挂在 SwitchCase.expression 上）。
      final v = exprToJs(member.expression, scope, classes);
      if (v == null) return null;
      label = 'case $v:';
    } else {
      return null;
    }
    lines.add('$caseInd$label');
    for (final st in member.statements) {
      final js = translateStmtList([st], scope, classes, widgetCtx,
          depth: depth + 2, returnsWidget: returnsWidget);
      if (js.isEmpty) return null; // 某条语句翻译失败 → 整个 switch 丢弃
      lines.add(js);
    }
    if (member.statements.isNotEmpty) {
      final last = member.statements.last;
      final terminated = last is ReturnStatement ||
          last is BreakStatement ||
          last is ContinueStatement ||
          (last is ExpressionStatement && last.expression is ThrowExpression);
      if (!terminated) lines.add('$caseInd' 'break;');
    }
  }
  lines.add('$ind}');
  return lines.join('\n');
}

/// switch 表达式（Dart 3）→ JS IIFE：
///   `switch (x) { 0 => '零', _ => '多' }` →
///   `(() => { switch (x) { case 0: return "零"; default: return "多"; } })()`
/// 仅支持常量模式与 `_`（guard / 解构 / 关系 / 逻辑或模式返回 null，调用方
/// 出声告警）。case 值走普通表达式翻译，不支持返回 widget 的 case（widget
/// 渲染路径只认 return 语句/表达式位置的构造调用）。
String? _switchExpressionJs(
  SwitchExpression e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  final subj = exprToJs(e.expression, scope, classes);
  if (subj == null) return null;
  final arms = <String>[];
  for (final c in e.cases) {
    if (c.guardedPattern.whenClause != null) return null;
    final p = c.guardedPattern.pattern;
    String? label;
    if (p is WildcardPattern) {
      label = 'default:';
    } else if (p is ConstantPattern) {
      final v = exprToJs(p.expression, scope, classes);
      if (v == null) return null;
      label = 'case $v:';
    } else {
      return null;
    }
    final v = rhsToJs(c.expression, scope, classes);
    if (v == null) return null;
    arms.add('    $label return $v;');
  }
  if (arms.isEmpty) return null;
  return '(() => { switch ($subj) {\n${arms.join('\n')}\n} })()';
}

/// 一条表达式语句 → JS：`setState(...)` 展开为 `this.setState(function(){...})`，
/// 其余走 [exprStmtToJs]（赋值 / 自增 / `_model.inc()` 对象方法调用等）。
String? _bodyExprStmtJs(
  Expression e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  if (e is MethodInvocation &&
      e.methodName.name == 'setState' &&
      e.argumentList.arguments.length == 1) {
    final fn = e.argumentList.arguments.first;
    if (fn is FunctionExpression) return _setStateJs(fn, scope, classes);
    return null;
  }
  return exprStmtToJs(e, scope, classes);
}

/// `setState(() => _x++)` → `this.setState(function(){ this._x += 1; });`
/// （回调体逐语句翻译，与 Dart 原封同构）。
String _setStateJs(
  FunctionExpression fn,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  final body = fn.body;
  String inner = '';
  if (body is ExpressionFunctionBody) {
    inner = exprStmtToJs(body.expression, scope, classes) ?? '';
  } else if (body is BlockFunctionBody) {
    inner = translateStmtList(body.block.statements, scope, classes, null);
  }
  // 回调体保持内联（`function(){ ... }`），把多行折回单行。
  inner = inner.replaceAll('\n', ' ');
  return inner.isEmpty
      ? 'this.setState(function(){});'
      : 'this.setState(function(){ $inner });';
}

/// 翻译一个类的方法体 → JS。**组件与普通类共用这一条**：字段表 = 类自身实例
/// 字段，返回 widget 的表达式走 widget 层渲染（与 build 无差别）。
///
/// [ClassMethod.nativeChannel] 非空（如 SnackBar → `nativeToast`）时整体译为
/// 宿主通道调用，不再走普通语句翻译。
String translateClassMethodBody(
  ClassInfo info,
  ClassMethod m,
  Map<String, ClassInfo> classes, {
  Map<String, Map<String, String>> hostMethods = const {},
  WidgetExprRenderer? widgetCtx,
  Set<String> globalConsts = const {},
  int depth = 2,
}) {
  final ind = '  ' * depth;
  final channel = m.nativeChannel;
  if (channel != null) {
    return '$ind'
        '__jsui.host(${jsString(channel)}, '
        '{ message: ${m.nativeMessage ?? '""'} });';
  }
  final scope = FieldScope(
    instanceFields: info.instanceFieldNames,
    params: m.params.toSet(),
    methods: {
      ...info.methodNames,
      if (sdkBaseName(info) != null) 'notifyListeners',
    },
    hostMethods: hostMethods,
    globalConsts: globalConsts,
  );
  // 方法形参同步登记进 widget 层（方法体期间），使返回的 widget 树里
  // `Text(title)` 这类形参引用可解析；翻译结束即恢复，不污染同类其它方法。
  String run() => translateMethodBody(
        m.body,
        scope,
        classes,
        widgetCtx: widgetCtx,
        returnExpressionBody: !m.isVoid,
        returnsWidget: m.returnsWidget,
        depth: depth,
      );
  if (widgetCtx == null || m.params.isEmpty) return run();
  return widgetCtx.withMethodParams(m.params, run);
}

/// 是否为「widget 构造表达式」：`Text(...)` / `new Text(...)`。
///
/// [parseString] 只做语法解析（无符号解析），无 `new` 的类构造在 AST 上是
/// [MethodInvocation]（target 为 null），因此不能只认 [InstanceCreationExpression]。
/// 带 target 的调用（`this.x()` / `a.b()`）不是构造，返回 false。
bool _isWidgetCtorExpr(Expression e) =>
    e is InstanceCreationExpression ||
    (e is MethodInvocation && e.target == null);

/// 把一个 Widget 构造表达式（如 `Container(...)`）通过 [WidgetExprRenderer]
/// （widget2js 层的 WidgetTranslateContext）翻译成 JS 构造调用字符串。
/// 失败返回 null（回退到普通表达式翻译），并出声告警（不静默丢代码）。
///
/// [depth]：该表达式所在语句的缩进深度，widget 树的子节点按此对齐缩进。
String? _widgetExprToJs(WidgetExprRenderer? widgetCtx, Expression e, int depth) {
  if (widgetCtx == null) return null;
  try {
    // translate(Expression) → JSON Map / String；renderJs(json, depth) → JS
    return widgetCtx.renderJs(widgetCtx.translate(e), depth);
  } catch (err) {
    log.warning('[hot_patch_generator] widget 表达式无法翻译，已在 JS 产物中'
        '丢弃：${e.toSource()}（$err）');
    return null;
  }
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

/// JS 双引号字符串字面量。
String jsString(String s) {
  final escaped = s
      .replaceAll(r'\', r'\\')
      .replaceAll('"', r'"')
      .replaceAll('\n', r'\n')
      .replaceAll('\r', r'\r')
      .replaceAll('\t', r'\t');
  return '"$escaped"';
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
