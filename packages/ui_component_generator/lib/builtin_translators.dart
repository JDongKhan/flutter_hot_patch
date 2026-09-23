import 'package:analyzer/dart/ast/ast.dart';

import 'widget_translator.dart';

/// 内置 widget 策略：把常见 Flutter widget 注册进 [WidgetTranslatorRegistry]。
///
/// 新增内置 widget = 在这里加一个 translator 类 + register 一行；
/// 自定义 widget = 在业务代码里实现 WidgetTranslator 并 register，
/// ComponentBuilder 核心逻辑无需改动。
void registerBuiltinTranslators(WidgetTranslatorRegistry registry) {
  registry
    ..register(const ColumnRowTranslator())
    ..register(const TextTranslator())
    ..register(const ButtonTranslator());
}

/// Column / Row：容器节点，唯一策略是递归翻译 children。
class ColumnRowTranslator extends WidgetTranslator {
  const ColumnRowTranslator();

  @override
  Set<String> get types => const {'Column', 'Row'};

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final children = ctx.listArg(node.positionalArgs, 'children', node.type);
    return {
      'type': node.type,
      'children': [
        for (final c in children) ctx.translate(c),
      ],
    };
  }

  @override
  String renderJs(
    Map<String, dynamic> json,
    int depth,
    WidgetTranslateContext ctx,
  ) {
    final ind = '  ' * depth;
    final ind2 = '  ' * (depth + 1);
    final type = json['type'] as String;
    final children = (json['children'] as List)
        .map((c) => ctx.renderJs(c as Map<String, dynamic>, depth + 1))
        .join(',\n$ind2');
    return '{ type: "$type", children: [\n$ind2$children\n$ind] }';
  }
}

/// Text：文案（支持状态插值）+ 样式映射（fontSize ≥ 20 → title）。
class TextTranslator extends WidgetTranslator {
  const TextTranslator();

  @override
  Set<String> get types => const {'Text'};

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final dataExpr =
        ctx.namedArg(node.positionalArgs, 'data') ??
            ctx.positionalArg(node.positionalArgs, 0);
    if (dataExpr == null) {
      throw FormatException('Text 缺少内容');
    }
    return {
      'type': 'Text',
      'props': {
        'data': ctx.jsDataExpr(dataExpr),
        'style': _textStyleFrom(node.positionalArgs),
      },
    };
  }

  @override
  String renderJs(
    Map<String, dynamic> json,
    int depth,
    WidgetTranslateContext ctx,
  ) {
    final p = json['props'] as Map<String, dynamic>;
    return '{ type: "Text", props: { data: ${p['data']}, style: "${p['style']}" } }';
  }

  static String _textStyleFrom(List<Expression> args) {
    for (final a in args) {
      if (a is! NamedExpression || a.name.label.name != 'style') continue;
      final (ctor, styleArgs) = _ctorOfArg(a.expression);
      if (ctor == 'TextStyle') {
        for (final s in styleArgs) {
          if (s is NamedExpression && s.name.label.name == 'fontSize') {
            final fs = s.expression;
            if (fs is IntegerLiteral && (fs.value ?? 0) >= 20) return 'title';
            if (fs is DoubleLiteral && fs.value >= 20) return 'title';
          }
        }
      }
    }
    return 'body';
  }
}

/// ElevatedButton：onPressed → 事件名（@UIAction），child Text → label。
class ButtonTranslator extends WidgetTranslator {
  const ButtonTranslator();

  @override
  Set<String> get types => const {'ElevatedButton'};

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final onPressed = ctx.namedArg(node.positionalArgs, 'onPressed');
    final child = ctx.namedArg(node.positionalArgs, 'child');
    if (onPressed == null) {
      throw FormatException('ElevatedButton 缺少 onPressed');
    }
    return {
      'type': 'Button',
      'props': {
        'label': _labelFrom(child, ctx),
        'event': _eventFrom(onPressed, ctx),
      },
    };
  }

  @override
  String renderJs(
    Map<String, dynamic> json,
    int depth,
    WidgetTranslateContext ctx,
  ) {
    final p = json['props'] as Map<String, dynamic>;
    return '{ type: "Button", props: { label: ${p['label']}, event: "${p['event']}" } }';
  }

  static String _eventFrom(Expression onPressed, WidgetTranslateContext ctx) {
    // 形式一：onPressed: _inc（方法 tear-off）
    if (onPressed is Identifier) {
      return ctx.eventOf(onPressed.name);
    }
    // 形式二：onPressed: () => _inc() 或 () { _inc(); }
    if (onPressed is FunctionExpression) {
      final inner = ctx.functionInner(onPressed);
      if (inner is MethodInvocation) {
        return ctx.eventOf(inner.methodName.name);
      }
    }
    throw FormatException('onPressed 需要直接引用 @UIAction 方法（如 () => _inc()）');
  }

  static String _labelFrom(Expression? child, WidgetTranslateContext ctx) {
    if (child == null) throw FormatException('ElevatedButton 缺少 child');
    final (ctor, args) = ctx.ctorOf(child);
    if (ctor != 'Text') throw FormatException('ElevatedButton 的 child 需要是 Text');
    final data = ctx.namedArg(args, 'data') ?? ctx.positionalArg(args, 0);
    if (data is SimpleStringLiteral) return ctx.jsString(data.value);
    throw FormatException('按钮文案需要是纯字符串字面量');
  }
}

/// 局部 ctor 解析（仅本文件内部使用，避免把通用逻辑放大到各处）。
(String?, List<Expression>) _ctorOfArg(Expression e) {
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
