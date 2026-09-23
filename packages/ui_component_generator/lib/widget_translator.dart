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
/// 不直接依赖某个具体 widget：type 是构造名（'Column'/'Text'/...），
/// 参数按位置/命名分开存放，由对应 translator 自行解析。
class WidgetNode {
  final String type;
  final List<Expression> positionalArgs;
  final Map<String, Expression> namedArgs;

  WidgetNode(this.type, this.positionalArgs, this.namedArgs);
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

  WidgetTranslateContext({
    required this.registry,
    required this.propByField,
    required this.actionByMethod,
    required this.sourcePath,
  });

  // -------------------------------------------------------------------------
  // 递归入口：表达式 → JSON 描述 / JS 渲染
  // -------------------------------------------------------------------------

  /// 把 build() 里的一个 widget 表达式翻译成 JSON 描述（schema 与 JS 共用）。
  Map<String, dynamic> translate(Expression e) {
    final node = _toNode(e);
    final translator = registry.lookup(node.type);
    if (translator == null) {
      throw FormatException(
          'ui_component_generator: 不支持的组件 "${node.type}"，'
          '请实现并注册对应的 WidgetTranslator（当前已注册: '
          '${registry.registeredTypes.join('/')}）');
    }
    return translator.toJson(node, this);
  }

  /// 渲染一个已翻译的 JSON 节点为 JS 对象字面量。
  String renderJs(Map<String, dynamic> json, int depth) {
    final type = json['type'] as String;
    final translator = registry.lookup(type);
    if (translator == null) {
      throw FormatException('未知节点类型: $type');
    }
    return translator.renderJs(json, depth, this);
  }

  // -------------------------------------------------------------------------
  // 通用 AST 解析 helper（translator 可直接复用）
  // -------------------------------------------------------------------------

  /// 取构造调用：`Foo(...)` 在无 resolution 的 parseString 下可能是
  /// InstanceCreationExpression 或 MethodInvocation（无 const 时），统一处理。
  (String?, List<Expression>) ctorOf(Expression e) {
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

  Expression? namedArg(List<Expression> args, String name) {
    for (final a in args) {
      if (a is NamedExpression && a.name.label.name == name) return a.expression;
    }
    return null;
  }

  Expression? positionalArg(List<Expression> args, int i) =>
      i < args.length ? args[i] : null;

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

  /// 字符串插值 → JS 表达式（`'count = $_count'` → `"count = " + __state.count`）
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
          final x = el.expression;
          if (x is Identifier) {
            parts.add('__state.${propOf(x)}');
          } else {
            throw FormatException(
                '插值只支持状态字段引用（如 \$_count），不支持 ${x.toSource()}');
          }
        }
      }
      return parts.isEmpty ? '""' : parts.join(' + ');
    }
    throw FormatException('文本内容只支持字符串字面量/插值，不支持 ${e.toSource()}');
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
    final positional = <Expression>[];
    final named = <String, Expression>{};
    for (final a in args) {
      if (a is NamedExpression) {
        named[a.name.label.name] = a.expression;
      } else {
        positional.add(a);
      }
    }
    return WidgetNode(ctor, positional, named);
  }
}

/// ===========================================================================
/// 策略抽象类：一个 widget 类型族的「widget → JSON 描述 + JS 渲染」
///
/// - [types]：处理的 widget 构造名集合（如 {'Text'} 或 {'Column','Row'}）
/// - [toJson]：AST 节点 → 中立 JSON 描述（schema 直接使用这份 JSON）
/// - [renderJs]：JSON 描述 → JS 对象字面量（运行时 create() 用）
/// ===========================================================================
abstract class WidgetTranslator {
  const WidgetTranslator();

  /// 本 translator 支持的 widget 构造名集合。
  Set<String> get types;

  /// 把 [node] 翻译成 JSON 描述（type/props/children）。
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx);

  /// 把 [json]（toJson 的产物）渲染成 JS 对象字面量。
  String renderJs(Map<String, dynamic> json, int depth, WidgetTranslateContext ctx);
}

/// ===========================================================================
/// 管理类：注册 / 分发 translator
///
/// ComponentBuilder 持有一个 registry；运行时按 widget 构造名查 translator。
/// 扩展新 widget = 写一个 WidgetTranslator 并 register，核心代码零改动。
/// ===========================================================================
class WidgetTranslatorRegistry {
  final List<WidgetTranslator> _translators = [];

  /// 注册一个 translator（同 type 覆盖旧的，后注册者优先）。
  void register(WidgetTranslator translator) {
    _translators.removeWhere((t) => t.types.intersection(translator.types).isNotEmpty);
    _translators.add(translator);
  }

  /// 按 widget 构造名查找 translator；未注册返回 null。
  WidgetTranslator? lookup(String type) {
    for (final t in _translators.reversed) {
      if (t.types.contains(type)) return t;
    }
    return null;
  }

  /// 当前已注册的类型集合（用于报错信息）。
  Set<String> get registeredTypes =>
      {for (final t in _translators) ...t.types};
}
