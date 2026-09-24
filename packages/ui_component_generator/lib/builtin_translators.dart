import 'package:analyzer/dart/ast/ast.dart';

import 'style_translators.dart';
import 'widget_translator.dart';

/// 内置 widget 策略：把常见 Flutter widget 注册进 [WidgetTranslatorRegistry]。
///
/// 新增内置 widget = 在这里加一个 translator 类 + register 一行；
/// 自定义 widget = 在业务代码里实现 WidgetTranslator 并 register，
/// ComponentBuilder 核心逻辑无需改动。
///
/// 值约定：toJson 的 props 叶子值一律是 **JS 表达式字符串**（字符串字面量
/// 用 `ctx.jsString()` 带引号、数字/布尔/表达式原样），默认 renderJs
/// 由基类把 toJson 产物序列化为 JS 对象字面量。
void registerBuiltinTranslators(WidgetTranslatorRegistry registry) {
  registry
    ..register(const ColumnRowTranslator())
    ..register(const TextTranslator())
    ..register(const ButtonTranslator())
    ..register(const SizedBoxTranslator())
    // 嵌套组件兜底：build 树里出现的其他自定义 widget → Component 节点
    ..register(const ComponentTranslator());
}

/// Column / Row：容器节点，唯一策略是递归翻译 children。
class ColumnRowTranslator extends WidgetTranslator {
  const ColumnRowTranslator();

  @override
  Set<String> get types => const {'Column', 'Row'};

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final children = ctx.listArg(node.args, 'children', node.type);
    return {
      'type': ctx.jsString(node.type),
      'children': [
        for (final c in children) ctx.translate(c),
      ],
    };
  }
}

/// Text：文案（支持状态插值）+ TextStyle → 结构化 style JSON。
class TextTranslator extends WidgetTranslator {
  const TextTranslator();

  @override
  Set<String> get types => const {'Text'};

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final dataExpr =
        ctx.namedArg(node.args, 'data') ?? ctx.positionalArg(node.args, 0);
    if (dataExpr == null) {
      throw FormatException('Text 缺少内容');
    }
    final props = <String, dynamic>{
      'data': ctx.jsDataExpr(dataExpr),
    };
    // TextStyle(...) → JSON（运行时 textStyleFromJson 还原）
    final style = textStyleToJson(ctx.namedArg(node.args, 'style'), ctx);
    if (style != null) props['style'] = style;
    return {'type': ctx.jsString('Text'), 'props': props};
  }
}

/// ElevatedButton：onPressed → 事件名，child Text → label，
/// style（styleFrom / ButtonStyle）→ JSON。
class ButtonTranslator extends WidgetTranslator {
  const ButtonTranslator();

  @override
  Set<String> get types => const {'ElevatedButton'};

  /// 产物节点统一叫 'Button'（运行时 WidgetFactory 识别名）。
  @override
  Set<String> get jsonTypes => const {'Button'};

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final onPressed = ctx.namedArg(node.args, 'onPressed');
    final child = ctx.namedArg(node.args, 'child');
    if (onPressed == null) {
      throw FormatException('ElevatedButton 缺少 onPressed');
    }
    final props = <String, dynamic>{
      'label': _labelFrom(child, ctx),
      'event': ctx.jsString(_eventFrom(onPressed, ctx)),
    };
    // ElevatedButton.styleFrom(...) / ButtonStyle(...) → JSON
    final style = buttonStyleToJson(ctx.namedArg(node.args, 'style'), ctx);
    if (style != null) props['style'] = style;
    return {'type': ctx.jsString('Button'), 'props': props};
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

/// SizedBox：布局空隙（height/width），无 UI 内容。
class SizedBoxTranslator extends WidgetTranslator {
  const SizedBoxTranslator();

  @override
  Set<String> get types => const {'SizedBox'};

  @override
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx) {
    final props = <String, dynamic>{};
    final h = _numLiteral(ctx.namedArg(node.args, 'height'));
    final w = _numLiteral(ctx.namedArg(node.args, 'width'));
    if (h != null) props['height'] = h;
    if (w != null) props['width'] = w;
    return {'type': ctx.jsString('SizedBox'), 'props': props};
  }

  static String? _numLiteral(Expression? e) {
    if (e is IntegerLiteral) {
      final v = e.value;
      return v == null ? null : '$v';
    }
    if (e is DoubleLiteral) {
      return '${e.value}';
    }
    return null;
  }
}
