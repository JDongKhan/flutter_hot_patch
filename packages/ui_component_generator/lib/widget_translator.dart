import 'package:analyzer/dart/ast/ast.dart';

// ===========================================================================
// widget → JSON 翻译的策略扩展点
//
// 设计目标：新增/自定义 widget 时不动 ComponentBuilder 的核心代码。
// 扩展一个 widget 只需要两步：
//   1. 实现 WidgetTranslator（types + toJson + renderJs）
//   2. 注册：registry.register(MyTranslator())
//
// 核心代码（注解解析、状态/动作提取、产物组装）只与
// WidgetTranslateContext / WidgetTranslatorRegistry 交互。
// ===========================================================================

/// 一个 widget 构造节点的中立表示（build() 树解析的中间产物）。
///
/// 不直接依赖某个具体 widget：type 是构造名（'Column'/'Text'/...）。
/// [args] 保留原始参数列表（含 NamedExpression，供 ctx 的 namedArg/
/// positionalArg/listArg 解析）；[positionalArgs]/[namedArgs] 是拆分视图。
class WidgetNode {
  final String type;
  final List<Expression> args;
  final List<Expression> positionalArgs;
  final Map<String, Expression> namedArgs;

  WidgetNode(this.type, this.args)
      : positionalArgs = [
          for (final a in args)
            if (a is! NamedExpression) a,
        ],
        namedArgs = {
          for (final a in args)
            if (a is NamedExpression) a.name.label.name: a.expression,
        };
}

/// 翻译上下文：持有注册表与组件元数据，并向 translator 提供通用解析能力。
///
/// translator 通过 [translate] 递归子节点、通过 [renderJs] 递归渲染子节点，
/// 通过 [jsDataExpr]/[eventOf]/[propOf] 等 helper 解析参数。
class WidgetTranslateContext {
  final WidgetTranslatorRegistry registry;
  final Map<String, String> propByField;
  final Map<String, String> actionByMethod;
  final String sourcePath;

  /// 组件名 → 依赖产物 jsAsset 路径（null = 无法确定，渲染层走原生注入）。
  /// 由生成器注入：本文件私有/注解组件 → 本文件产物；跨文件组件 →
  /// 从 import directives 推导源文件产物。Component 节点据此产出 import，
  /// 运行时以嵌套 HotPatchWidget 递归渲染（使用方无需知道依赖）。
  final String? Function(String component)? importResolver;

  /// 翻译过程中遇到的未知自定义组件（Component 兜底），供生成器
  /// 收集后把本文件内可解析的私有组件（_Xxx）翻译成嵌套组件注册进产物。
  final Set<String> dependencies = {};

  WidgetTranslateContext({
    required this.registry,
    required this.propByField,
    required this.actionByMethod,
    required this.sourcePath,
    this.importResolver,
  });

  /// 记录一个被兜底为 Component 节点的自定义组件名。
  void collectDependency(String name) => dependencies.add(name);

  // -------------------------------------------------------------------------
  // 递归入口：表达式 → JSON 描述 / JS 渲染
  // -------------------------------------------------------------------------

  /// 把 build() 里的一个 widget 表达式翻译成 JSON 描述（schema 与 JS 共用）。
  Map<String, dynamic> translate(Expression e) {
    final node = _toNode(e);
    final translator = registry.lookup(node.type);
    if (translator != null) return translator.toJson(node, this);
    // 未注册：按「嵌套组件」兜底翻译（需注册 fallback = ComponentTranslator）。
    // 有 @UIComponent 注解的组件运行时递归渲染 JS 版本；
    // 无注解的 lib 自定义 widget 原生直接可用，JS 版渲染为 Component 占位。
    final fb = registry.fallback;
    if (fb != null && _isUpperCamel(node.type)) {
      collectDependency(node.type);
      return fb.toJson(node, this);
    }
    throw FormatException(
        'ui_component_generator: 不支持的组件 "${node.type}"，'
        '请实现并注册对应的 WidgetTranslator（当前已注册: '
        '${registry.registeredTypes.join('/')}）');
  }

  static bool _isUpperCamel(String name) =>
      name.isNotEmpty && name[0] == name[0].toUpperCase();

  /// 渲染一个已翻译的 JSON 节点为 JS 对象字面量。
  ///
  /// 值契约：toJson 的叶子值一律是 JS 表达式字符串（`"Text"` 这类字符串
  /// 字面量由 [jsString] 产生），因此分发前剥离字符串字面量的引号取语义名。
  String renderJs(Map<String, dynamic> json, int depth) {
    final type = _semanticType(json['type']);
    final translator = registry.lookupJson(type);
    if (translator == null) {
      throw FormatException('未知节点类型: $type');
    }
    return translator.renderJs(json, depth, this);
  }

  /// 剥离 JS 字符串字面量引号（`"Column"` → `Column`）；非字面量原样返回。
  static String _semanticType(Object? v) {
    final s = v?.toString() ?? '';
    if (s.length >= 2 && s.startsWith('"') && s.endsWith('"')) {
      return s.substring(1, s.length - 1);
    }
    return s;
  }

  // -------------------------------------------------------------------------
  // 通用 AST 解析 helper（translator 可直接复用）
  // -------------------------------------------------------------------------

  /// 取构造调用：`Foo(...)` 在无 resolution 的 parseString 下可能是
  /// InstanceCreationExpression 或 MethodInvocation（无 const 时），统一处理。
  ///
  /// 静态工厂形态（`Image.asset(...)` / `Image.network(...)`）把 ctor 名
  /// 归一为 target 名（'Image'），与注册表 {Image: ImageTranslator} 匹配。
  (String?, List<Expression>) ctorOf(Expression e) {
    if (e is InstanceCreationExpression) {
      return (
        e.constructorName.type.name2.lexeme,
        e.argumentList.arguments.toList(),
      );
    }
    if (e is MethodInvocation) {
      final target = e.target;
      if (target is Identifier) {
        return (target.name, e.argumentList.arguments.toList());
      }
      return (e.methodName.name, e.argumentList.arguments.toList());
    }
    return (null, const []);
  }

  Expression? namedArg(List<Expression> args, String name) {
    for (final a in args) {
      if (a is NamedExpression && a.name.label.name == name) return a.expression;
    }
    return null;
  }

  Expression? positionalArg(List<Expression> args, int i) =>
      i < args.length ? args[i] : null;

  /// 第一个非命名参数（单子组件的 child 定位）：
  /// `Container(width: 120)` 无 child 时，跳过命名参数，返回 null。
  Expression? nonNamedArg(List<Expression> args) {
    for (final a in args) {
      if (a is! NamedExpression) return a;
    }
    return null;
  }

  List<Expression> listArg(List<Expression> args, String name, String ctor) {
    final e = namedArg(args, name);
    if (e is ListLiteral) return e.elements.whereType<Expression>().toList();
    throw FormatException('$ctor 缺少 $name 列表');
  }

  /// 字段名（`_count`）→ 状态名（`count`）
  String propOf(Identifier id) {
    final prop = propByField[id.name];
    if (prop != null) return prop;
    throw FormatException('"${id.name}" 不是 @UIProp 状态字段');
  }

  /// @UIAction 方法名 → 事件名
  String eventOf(String method) {
    final event = actionByMethod[method];
    if (event != null) return event;
    throw FormatException('"$method" 未标注 @UIAction');
  }

  /// 事件参数解析：`onTap: _tap` 或 `onTap: () => _tap()` → 事件名。
  String eventExpr(Expression e) {
    if (e is Identifier) return eventOf(e.name);
    if (e is FunctionExpression) {
      final inner = functionInner(e);
      if (inner is MethodInvocation) return eventOf(inner.methodName.name);
    }
    throw FormatException('事件参数需要直接引用方法（如 onTap: _tap 或 () => _tap()）');
  }

  /// 状态字段引用或字面量 → JS 表达式
  /// （Switch value / Slider value 等「绑定状态或常量」的场景）。
  /// 字段一比一：`_lightsOn` → `this._lightsOn`。
  String propExpr(Expression e) {
    if (e is Identifier) return 'this.${propOf(e)}';
    if (e is BooleanLiteral) return e.value ? 'true' : 'false';
    if (e is IntegerLiteral) return '${e.value}';
    if (e is DoubleLiteral) return '${e.value}';
    if (e is SimpleStringLiteral) return jsString(e.value);
    throw FormatException('仅支持状态字段/字面量，不支持 ${e.toSource()}');
  }

  /// 文本内容表达式 → JS 表达式（`'count = $_count'` →
  /// `"count = " + this._count`；`'user: ${_user?.name ?? "x"}'` → 模型属性链）。
  ///
  /// 支持：字符串字面量/相邻字符串/插值、状态字段（this._x）、模型属性链
  /// （this._user.name）、null-aware 访问（? .，转显式三元保证引擎兼容）、
  /// ?? 合并、+ 拼接、括号。
  String jsDataExpr(Expression e) {
    if (e is SimpleStringLiteral) return jsString(e.value);
    if (e is AdjacentStrings) {
      return e.strings.map(jsDataExpr).join(' + ');
    }
    if (e is StringInterpolation) {
      final parts = <String>[];
      for (final el in e.elements) {
        if (el is InterpolationString) {
          if (el.value.isNotEmpty) parts.add(jsString(el.value));
        } else if (el is InterpolationExpression) {
          parts.add(jsDataExpr(el.expression));
        }
      }
      return parts.isEmpty ? '""' : parts.join(' + ');
    }
    if (e is Identifier) return 'this.${propOf(e)}';
    if (e is PropertyAccess && e.target != null) {
      final target = jsDataExpr(e.target!);
      final name = e.propertyName.name;
      if (e.operator.lexeme == '?.') {
        // `_user?.name` → `(this._user == null ? null : this._user.name)`
        return '($target == null ? null : $target.$name)';
      }
      return '$target.$name';
    }
    if (e is BinaryExpression && e.operator.lexeme == '??') {
      return '(${jsDataExpr(e.leftOperand)} ?? ${jsDataExpr(e.rightOperand)})';
    }
    if (e is BinaryExpression && e.operator.lexeme == '+') {
      return '(${jsDataExpr(e.leftOperand)} + ${jsDataExpr(e.rightOperand)})';
    }
    if (e is ParenthesizedExpression) return '(${jsDataExpr(e.expression)})';
    throw FormatException(
        '文本内容只支持字符串/插值/状态字段/模型属性，不支持 ${e.toSource()}');
  }

  /// 方法 tear-off 或 `() => _inc()` 内部的方法调用表达式
  Expression? functionInner(FunctionExpression fn) {
    final body = fn.body;
    if (body is ExpressionFunctionBody) return body.expression;
    if (body is BlockFunctionBody) {
      for (final s in body.block.statements) {
        if (s is ExpressionStatement) return s.expression;
      }
    }
    return null;
  }

  /// 把 toJson 产物的值序列化为 JS 对象字面量源码。
  ///
  /// 值约定：toJson 输出的叶子值一律为 **JS 表达式字符串**（字符串字面量
  /// 用 [jsString] 带引号、数字/布尔/表达式原样），这里原样嵌入、不加引号。
  String jsLiteral(Object? value, int depth) {
    if (value is Map) {
      if (value.isEmpty) return '{}';
      final ind = '  ' * depth;
      final ind2 = '  ' * (depth + 1);
      final entries = value.entries
          .map((e) => '"${e.key}": ${jsLiteral(e.value, depth + 1)}')
          .join(',\n$ind2');
      return '{\n$ind2$entries\n$ind}';
    }
    if (value is List) {
      if (value.isEmpty) return '[]';
      final ind = '  ' * depth;
      final ind2 = '  ' * (depth + 1);
      final items = value.map((v) => jsLiteral(v, depth + 1)).join(',\n$ind2');
      return '[\n$ind2$items\n$ind]';
    }
    // 叶子值 = JS 表达式字符串（已带引号的字符串 / 数字 / 表达式）
    return value?.toString() ?? 'null';
  }

  /// 生成 JS 双引号字符串字面量
  String jsString(String s) {
    final escaped = s
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r')
        .replaceAll('\t', r'\t');
    return '"$escaped"';
  }

  WidgetNode _toNode(Expression e) {
    final (ctor, args) = ctorOf(e);
    if (ctor == null) {
      throw FormatException('不支持的 UI 表达式: ${e.toSource()}');
    }
    return WidgetNode(ctor, args);
  }
}

/// ===========================================================================
/// 策略抽象类：一个 widget 类型族的「widget → JSON 描述 + JS 渲染」
///
/// - [types]：处理的源码 widget 构造名（如 {'Text'} 或 {'Column','Row'}）
/// - [jsonTypes]：产物 JSON 里的节点 type 名（默认与 [types] 相同；
///   如 ElevatedButton 的产物节点叫 'Button' 时覆写）
/// - [toJson]：AST 节点 → 中立 JSON 描述（schema 直接使用这份 JSON）
/// - [renderJs]：JSON 描述 → JS 对象字面量（运行时 create() 用）
/// ===========================================================================
abstract class WidgetTranslator {
  const WidgetTranslator();

  /// 本 translator 对应的**单一**源码 widget 构造名（如 'Text' / 'Column'）。
  /// 一个 type 一个实现；共用逻辑用继承（基类 + 子类覆写 type）。
  String get type;

  /// 本 translator 产物 JSON 中使用的节点 type 名集合（默认与 [type] 相同；
  /// 如三种按钮产物统一叫 'Button'）。
  Set<String> get jsonTypes => {type};

  /// 把 [node] 翻译成 JSON 描述（type/props/children）。
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx);

  /// 把 [json]（toJson 的产物）渲染成 JS 对象字面量。
  ///
  /// **默认实现**：递归序列化 [json]（Map/List 缩进、叶子值原样嵌入）。
  /// 需要特殊输出格式（如单行紧凑）的类型可覆写。
  String renderJs(
    Map<String, dynamic> json,
    int depth,
    WidgetTranslateContext ctx,
  ) {
    return ctx.jsLiteral(json, depth);
  }
}

/// ===========================================================================
/// 管理类：注册 / 分发 translator
///
/// ComponentBuilder 持有一个 registry；运行时按 widget 构造名查 translator。
/// 扩展新 widget = 写一个 WidgetTranslator 并 register，核心代码零改动。
/// ===========================================================================
class WidgetTranslatorRegistry {
  /// 源码构造名 → translator（Map 直查，O(1)；组件几千个也不退化）。
  final Map<String, WidgetTranslator> _translators = {};

  /// 产物 JSON 节点 type → translator（renderJs 分发用，同样 O(1)）。
  final Map<String, WidgetTranslator> _jsonIndex = {};

  /// 兜底 translator（如 ComponentTranslator）：lookup 未命中时由
  /// WidgetTranslateContext.translate 显式判定后使用（仅 UpperCamel 组件）。
  WidgetTranslator? _fallback;

  /// 注册一个 translator（同 type 覆盖旧的，后注册者优先）。
  void register(WidgetTranslator translator) {
    _translators[translator.type] = translator;
    for (final jsonType in translator.jsonTypes) {
      _jsonIndex[jsonType] = translator;
    }
  }

  /// 设置兜底 translator（未注册的自定义组件 → Component 节点）。
  void registerFallback(WidgetTranslator translator) {
    _fallback = translator;
  }

  /// 兜底 translator。
  WidgetTranslator? get fallback => _fallback;

  /// 按源码 widget 构造名查找 translator；未注册返回 null。
  WidgetTranslator? lookup(String type) => _translators[type];

  /// 按产物 JSON 节点 type 查找 translator；未注册返回 null。
  WidgetTranslator? lookupJson(String type) => _jsonIndex[type];

  /// 当前已注册的源码类型集合（用于报错信息）。
  Set<String> get registeredTypes => _translators.keys.toSet();
}


/// 嵌套组件兜底翻译：build 树里出现其他自定义 widget 时统一翻译为
/// Component 节点（{ type: 'Component', props: { component, import?, args? } }）。
/// 运行时发现 import 且后缀为 .js → 返回嵌套 HotPatchWidget(jsAsset: import)
/// 递归渲染（组件自管理生命周期/事件/状态，层级深度不限）；
/// 无 import（无注解的 lib 普通 widget）→ 原生注入（nativeComponents）或占位。
class ComponentTranslator extends WidgetTranslator {
  const ComponentTranslator();

  /// 兜底 translator 不需要参与 Map 注册（registry.registerFallback 持有），
  /// type 取哨兵值 'Component' 仅满足抽象约束。
  @override
  String get type => 'Component';

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    // 构造参数字面量 → 值契约（叶子值一律为 JS 表达式字符串）：
    // 字符串经 jsString 带引号、数字/布尔转字面量，运行时 jsonEncode 即得原值。
    final args = <String, dynamic>{};
    for (final entry in node.namedArgs.entries) {
      final v = _literalValue(entry.value);
      if (v != null) args[entry.key] = _jsLiteral(v, ctx);
    }
    // import：该组件可用的 JS 产物路径（本文件私有/注解组件 → 本文件产物；
    // 跨文件注解组件 → 依赖文件产物）。运行时渲染 Component 节点时发现
    // import 且后缀为 .js → 返回嵌套 HotPatchWidget(jsAsset: import) 递归。
    final import = ctx.importResolver?.call(node.type);
    return {
      'type': ctx.jsString('Component'),
      'props': {
        'component': ctx.jsString(node.type),
        if (import != null) 'import': ctx.jsString(import),
        if (args.isNotEmpty) 'args': args,
      },
    };
  }

  /// AST 字面量 → Dart 值（null 表示不可翻译）。
  static Object? _literalValue(Expression e) {
    if (e is StringLiteral) return e.stringValue;
    if (e is IntegerLiteral) return e.value;
    if (e is DoubleLiteral) return e.value;
    if (e is BooleanLiteral) return e.value;
    if (e is NullLiteral) return null;
    return null;
  }

  /// Dart 值 → JS 表达式字面量。
  static String _jsLiteral(Object? v, WidgetTranslateContext ctx) {
    if (v is String) return ctx.jsString(v);
    if (v is bool) return v ? 'true' : 'false';
    if (v == null) return 'null';
    return '$v';
  }
}
