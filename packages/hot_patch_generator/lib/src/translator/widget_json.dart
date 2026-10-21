/// 统一翻译入口：任意 widget 构造 → `{type, props, children}`。
///
/// 只有这一条路径。判断依据是**值的形态**（见 [autoValue]）与**通用参数名**
/// （`child` / `children`·`slivers`·`tabs` / `on*` / `delegate`），**不看 widget
/// 类型**——所以内建、自定义、三方组件用同一套规则翻译，接入新组件零实现。
///
/// 组装规则（全局唯一约定）：
///   - `type` = 构造名**原样**（不做任何归一，如四种按钮各自用真实类型名）；
///   - `factory` = 命名构造 / 静态工厂名（`ListView.builder` → `builder`、
///     `Image.network` → `network`、`ChangeNotifierProvider.value` → `value`）——
///     同类型的不同工厂产物**同 type、不同 factory**，运行时据此选工厂；
///   - `child:` → `children`；`children:`/`slivers:`/`tabs:` → 展开进 children；
///   - `delegate:` → sliver 子结点提供者（见 [sliverDelegateResult]）；
///   - `on*` → 事件句柄（键名就是参数名，不改名）；
///   - 位置实参 → 按 Flutter 声明的**形参名**（`Text('hi')` → `data`，见
///     [widgetPositionalArgNames]）；未登记的类型出声告警并丢弃，不再有下标
///     数组兜底；
///   - 其余具名实参 → `props[参数名]`，值按形态翻译（翻译不出来则丢弃该键）；
///   - `key:` 由渲染层统一注入（见 `WidgetTranslateContext._applyKeyProp`）。
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart' show log;

import '../builders/js_widget_defs.dart';
import 'value_forms.dart';
import 'widget2js.dart';

/// 单子参数：值 → `children`（`child` / `sliver` 都是「单个子结点」语义）。
const Set<String> _childArgs = {'child', 'sliver'};

/// 列表参数：值 → 展开进 `children`。
const Set<String> _listArgs = {'children', 'slivers', 'tabs'};

/// 子结点提供者参数：`delegate:`。
const Set<String> _delegateArgs = {'delegate'};

/// 命名构造 / 静态工厂名的 props 键（值为带引号的 JS 字符串）。
///
/// 键名固定，运行时据此**按类型 + 工厂名**挑选原生/JS 工厂：`ListView.builder`
/// → `{factory: 'builder', itemBuilder: …}`、`ListView.separated` → `separated`、
/// `Image.network` → `network`、`ChangeNotifierProvider.value` → `value`。
/// 普通构造（`Text(...)` / `Padding(...)`）不带该键。
const String factoryPropsKey = 'factory';

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

    // `key:` 是元素级参数，由渲染层统一注入 props['key']（见
    // [WidgetTranslateContext._applyKeyProp]）；这里跳过，避免把 Key 构造
    // 当作子结点/值重复翻译。
    if (name == 'key') continue;

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
      // `on*` 回调有两种消费方，按**目标类型**分派：
      //   - 宿主 widget（`ElevatedButton.onPressed` / `InkWell.onTap`…）：宿主
      //     只认 `{__fn:id}` 句柄，点击时经 invoke 回传 JS 执行 → 下发**事件句柄**；
      //   - 组件（自定义 / 私有 / `@PatchEntry` 子组件 —— 元素是 JS 类引用，
      //     props 留在 JS 侧）：子组件把回调**当函数直接调**（`this.onPick(k, v)`），
      //     故下发**可调用 JS 值**（方法 tear-off 包成绑定 this 的箭头闭包）。
      //     下发句柄会出现 `TypeError: this.onPick is not a function`。
      if (!builtinWidgetTypes.contains(node.type)) {
        final fn = _functionOrNull(ctx, value);
        if (fn != null) {
          props[name] = fn;
          continue;
        }
      }
      final h = _eventOrNull(ctx, value);
      if (h != null) props[name] = h;
      continue;
    }
    props[name] = autoValue(value, ctx, name: name);
  }

  // 命名构造 / 静态工厂名（`ListView.builder` / `Image.network` / `Provider.value`）
  // → `props.factory`：产物自解释，运行时按「类型 + 工厂名」选工厂，不再靠
  // props 有没有某个键来猜。
  final factory = factoryNameOf(node.expr);
  if (factory != null) props[factoryPropsKey] = ctx.jsString(factory);

  // 位置实参：按 Flutter 声明的**形参名**下发（`Text('hi')` → `data`）。
  // 未登记的类型没有可靠形参名，禁止伪造下标键（`$pos`）——出声告警并丢弃，
  // 促使在 [widgetPositionalArgNames] 补齐登记。
  if (positional.isNotEmpty) {
    final names = positionalArgNames(node.type, factory);
    if (names != null && names.length >= positional.length) {
      for (var i = 0; i < positional.length; i++) {
        props[names[i]] = positional[i];
      }
    } else {
      log.warning(
        '[hot_patch_generator] ${ctx.sourcePath}: ${node.type} 的位置实参'
        '未登记形参名（widgetPositionalArgNames），已丢弃；'
        '请在 js_widget_defs.dart 登记该构造的位置形参名。',
      );
    }
  }

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

/// 命名构造 / 静态工厂名；普通构造返回 null。
///
///   - `InstanceCreationExpression`（带 const）：`constructorName.name`；
///   - `MethodInvocation` **带 receiver**（静态工厂 `Image.network(...)` /
///     `Positioned.fill(...)`）→ 方法名；
///   - `MethodInvocation` 无 receiver（parseString 下无 const 的 `Foo(...)`）→
///     方法名就是类型名，不是工厂，返回 null。
String? factoryNameOf(Expression? e) {
  if (e is InstanceCreationExpression) return e.constructorName.name?.name;
  if (e is MethodInvocation) {
    return e.target is Identifier ? e.methodName.name : null;
  }
  return null;
}

/// 位置实参的形参名：先查「类型.命名构造」再查「类型」，未登记返回 null。
List<String>? positionalArgNames(String type, String? factory) {
  if (factory != null) {
    final byFactory = widgetPositionalArgNames['$type.$factory'];
    if (byFactory != null) return byFactory;
  }
  return widgetPositionalArgNames[type];
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

/// 组件参数位置上的「函数值」翻译（可调用 JS 表达式）；不是函数形态返回 null。
///
/// 组件（JS 类）会把这类参数**当函数调用**，因此裸方法名不能下发成句柄
/// （见 [widgetToJson] 的 `on*` 分支）。
String? _functionOrNull(WidgetTranslateContext ctx, Expression e) {
  if (e is NullLiteral) return null;
  try {
    return ctx.functionJs(e);
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
