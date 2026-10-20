/// 统一翻译入口：任意 widget 构造 → `{type, props, children}`。
///
/// 只有这一条路径。判断依据是**值的形态**（见 [autoValue]）与**通用参数名**
/// （`child` / `children`·`slivers`·`tabs` / `on*` / `delegate`），**不看 widget
/// 类型**——所以内建、自定义、三方组件用同一套规则翻译，接入新组件零实现。
///
/// 组装规则（全局唯一约定）：
///   - `type` = 构造名**原样**（不做任何归一，如四种按钮各自用真实类型名）；
///   - `child:` → `children`；`children:`/`slivers:`/`tabs:` → 展开进 children；
///   - `delegate:` → sliver 子结点提供者（见 [sliverDelegateResult]）；
///   - `on*` → 事件句柄（键名就是参数名，不改名）；
///   - 位置实参 → `props['$pos']`（JS 数组，运行时按位取）；
///   - 其余具名实参 → `props[参数名]`，值按形态翻译（翻译不出来则丢弃该键）；
///   - `key:` 由渲染层统一注入（见 `WidgetTranslateContext._applyKeyProp`）。
library;

import 'package:analyzer/dart/ast/ast.dart';

import 'value_forms.dart';
import 'widget2js.dart';

/// 单子参数：值 → `children`（`child` / `sliver` 都是「单个子结点」语义）。
const Set<String> _childArgs = {'child', 'sliver'};

/// 列表参数：值 → 展开进 `children`。
const Set<String> _listArgs = {'children', 'slivers', 'tabs'};

/// 子结点提供者参数：`delegate:`。
const Set<String> _delegateArgs = {'delegate'};

/// 位置实参在 props 里的键名（值为 JS 数组）：运行时按位取。
const String positionalPropsKey = r'$pos';

/// 任意 widget 构造 → 产物结点描述。
Map<String, dynamic> widgetToJson(WidgetNode node, WidgetTranslateContext ctx) {
  final props = <String, dynamic>{};
  final children = <Object?>[];
  final positional = <Object?>[];

  for (final arg in node.args) {
    if (arg is! NamedExpression) {
      positional.add(autoValue(arg, ctx));
      continue;
    }
    final name = arg.name.label.name;
    final value = arg.expression;

    // delegate 是「子结点提供者」：ListDelegate → children；
    // BuilderDelegate → builder/childCount props（不认识的形态走普通值翻译）。
    if (_delegateArgs.contains(name)) {
      final r = sliverDelegateResult(value, ctx);
      if (r != null) {
        children.addAll(r.children);
        props.addAll(r.builder);
        continue;
      }
    }
    if (_childArgs.contains(name)) {
      final n = ctx.translate(value);
      if (n != null) children.add(n);
      continue;
    }
    if (_listArgs.contains(name)) {
      children.addAll(_listOrEmpty(node, ctx, name));
      continue;
    }
    if (_isEventArg(name)) {
      final h = _eventOrNull(ctx, value);
      if (h != null) props[name] = h;
      continue;
    }
    props[name] = autoValue(value, ctx, name: name);
  }

  if (positional.isNotEmpty) props[positionalPropsKey] = positional;

  // 构造的类型实参（`Consumer<NetworkVm>(...)` / `ChangeNotifierProvider<T>`）
  // → `model` prop：provider 的 watch/read/notifier 语义需要模型类名。
  final typeArg = firstTypeArgOf(node.expr);
  if (typeArg != null) props['model'] = ctx.jsString(typeArg);

  return {
    'type': ctx.jsString(node.type),
    'props': nonNull(props),
    'children': children,
  };
}

/// 构造的第一个类型实参名（`Consumer<NetworkVm>(...)` → 'NetworkVm'）。
String? firstTypeArgOf(Expression? e) {
  final List<TypeAnnotation>? args = switch (e) {
    InstanceCreationExpression() =>
      e.constructorName.type.typeArguments?.arguments,
    MethodInvocation() => e.typeArguments?.arguments,
    _ => null,
  };
  if (args == null || args.isEmpty) return null;
  return args.first.toSource();
}

/// 事件参数：`on*` 前缀（`onPressed` / `onChanged` / `onTap` / `onReorder` …）。
bool _isEventArg(String name) => name.length > 2 && name.startsWith('on');

String? _eventOrNull(WidgetTranslateContext ctx, Expression e) {
  // `onXxx: null` 是「禁用」语义（如 `onPressed: null`），不入产物。
  if (e is NullLiteral) return null;
  try {
    return ctx.eventHandle(e);
  } catch (_) {
    return null;
  }
}

List<Object?> _listOrEmpty(
  WidgetNode node,
  WidgetTranslateContext ctx,
  String name,
) {
  try {
    return ctx.listArg(node.args, name, node.type);
  } catch (_) {
    return const [];
  }
}

/// sliver 的 `delegate:` → `(children, builder props)`：
///   - `SliverChildListDelegate([...])` → 直接展开 children；
///   - `SliverChildBuilderDelegate((context, index) => ..., childCount: n)` →
///     闭包抽成组件方法，产出 `{'builder': <方法名>, 'childCount': <jsExpr>}`。
///
/// 两种都不匹配 → null（调用方按普通值形态继续翻译）。
({List<Object?> children, Map<String, dynamic> builder})? sliverDelegateResult(
  Expression? delegate,
  WidgetTranslateContext ctx,
) {
  if (delegate == null) return null;
  final (ctor, args) = ctx.ctorOf(delegate);

  if (ctor == 'SliverChildListDelegate') {
    final first = ctx.nonNamedArg(args);
    if (first is ListLiteral) {
      return (
        children: [
          for (final e in first.elements) ctx.translateElement(e),
        ],
        builder: const {},
      );
    }
    return null;
  }

  if (ctor == 'SliverChildBuilderDelegate') {
    final builderRaw = ctx.namedArg(args, 'builder') ?? ctx.nonNamedArg(args);
    final childCount = ctx.namedArg(args, 'childCount');
    if (builderRaw is! FunctionExpression || childCount == null) return null;
    final method = extractBuilderMethod(ctx, builderRaw, '_builder');
    if (method == null) return null;
    return (
      children: const [],
      builder: {
        'builder': ctx.jsString(method),
        'childCount': ctx.jsDataExpr(childCount),
      },
    );
  }

  return null;
}
