/// 统一翻译入口：任意 widget 构造 → `{type, props}`。
///
/// 只有这一条路径。判断依据是**值的形态**（见 [autoValue]），**不按属性名、
/// 不看 widget 类型**——所以内建、自定义、三方组件用同一套规则翻译，接入新
/// 组件零实现；`content` / `top` / `bottom` 这类自定义名称与 `child` /
/// `children` 走完全相同的路径。
///
/// 组装规则（全局唯一约定）：
///   - `type` = 构造名**原样**（不做任何归一，如四种按钮各自用真实类型名）；
///   - `factory` = 命名构造 / 静态工厂名（`ListView.builder` → `builder`、
///     `Image.network` → `network`、`ChangeNotifierProvider.value` → `value`）——
///     同类型的不同工厂产物**同 type、不同 factory**，运行时据此选工厂；
///   - 所有具名实参**按原名**放进 `props`，值按形态翻译：widget 构造 → 元素
///     结点、widget 列表 → 元素数组、样式/枚举 → 结构化值；
///   - 元素工厂 `__h` 再按**显式标记**（`element: true`，由 `__h` 给每个元素
///     统一加）把 widget 值归入按原名作 key 的 `children` 对象，运行时从对象
///     按 prop 名取；
///   - `delegate:` 按构造**类型**转换后放进 `children`，不进 props；
///   - `on*` → 事件句柄（键名就是参数名，不改名）；
///   - 位置实参 → 按 Flutter 声明的**形参名**（`Text('hi')` → `data`，见
///     [widgetPositionalArgNames]）；未登记的类型出声告警并丢弃；
///   - `key:` 由渲染层统一注入（见 `WidgetTranslateContext._applyKeyProp`）。
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart' show log;

import '../../shared/ctor_signatures.dart';
import '../../shared/js_widget_defs.dart';
import 'value_forms.dart';
import 'widget2js.dart';

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

    if (_isEventArg(name)) {
      // `on*` 回调有两种消费方，按**目标是否 JS 侧组件**分派（不看内建类型表）：
      //   - JS 侧组件（自定义 / 私有 / `@PatchEntry` 子组件 —— 元素是 JS 类引用，
      //     props 留在 JS 侧）：子组件把回调**当函数直接调**（`this.onPick(k, v)`），
      //     故下发**可调用 JS 值**（方法 tear-off 包成绑定 this 的箭头闭包）。
      //     下发句柄会出现 `TypeError: this.onPick is not a function`；
      //   - 宿主 widget（`ElevatedButton.onPressed` / `InkWell.onTap`…）：宿主
      //     只认 `{__fn:id}` 句柄，点击时经 invoke 回传 JS 执行 → 下发**事件句柄**。
      if (_isJsSideWidget(ctx, node.type)) {
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

/// 位置实参的形参名：直接查源码构造签名（[CtorSignatures]）。
///
/// 不维护任何类型/构造名表——项目类、SDK、依赖包用同一条路径；SDK 新增带位置
/// 实参的组件后重构建即生效。签名查不到时返回 null，调用方告警。
List<String>? positionalArgNames(String type, String? factory) {
  return CtorSignatures.instance
      ?.of(type, ctorName: factory)
      ?.positional;
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

/// 该结点的 `on*` 回调是否由 **JS 侧代码直接调用**（而不是交给宿主）。
///
/// 判据只看产物归属与最终消费方，与「内建/自定义」无关：
///   - 业务组件有 JS 产物 → JS 侧直接调用，下发可调用闭包；
///   - 逻辑组件（Builder / Consumer …）→ JS 类内部消费；
///   - builder 代理类型（ListView / PageView / ReorderableListView …）→ 代理类
///     只负责展开子结点，props **原样透传给宿主节点**，回调仍由宿主消费，
///     必须下发事件句柄；
///   - 其余宿主/原生类型 → 事件句柄。
bool _isJsSideWidget(WidgetTranslateContext ctx, String type) {
  if (ctx.importResolver?.call(type) != null) return true;
  if (!ctx.jsClassWidgets.contains(type)) return false;
  return !ctx.delegateClassWidgets.contains(type);
}

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

