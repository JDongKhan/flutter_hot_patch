/// 统一翻译入口：任意 widget 构造 → `{type, props}`。
///
/// 只有这一条路径。判断依据是**值的形态**（见 [autoValue]），**不按属性名、
/// 不看 widget 类型**——所以内建、自定义、三方组件用同一套规则翻译，接入新
/// 组件零实现；`content` / `top` / `bottom` 这类自定义名称与 `child` /
/// `children` 走完全相同的路径。
///
/// 组装规则（全局唯一约定）：
///   - `type` = 构造名**原样**（不做任何归一，如四种按钮各自用真实类型名）；
///   - 命名构造 / 静态工厂名（`ListView.builder` → `builder`、`Image.network`
///     → `network`）由渲染层一比一发射成 `X.b(...)`，构造名写在**结点顶层
///     `ctor` 键**（不进 `props`）。JS 没有 Dart 的命名构造，故由 JS 类上的
///     同名静态方法把构造名写进 `props.factory`——宿主只认 `props.factory`，
///     不解析调用形状；
///   - 所有具名实参**按原名**放进 `props`，值按形态翻译：widget 构造 → 元素
///     结点、widget 列表 → 元素数组、样式/枚举 → 结构化值；
///   - 元素工厂 `__h` 再按**显式标记**（`element: true`，由 `__h` 给每个元素
///     统一加）把 widget 值归入按原名作 key 的 `children` 对象，运行时从对象
///     按 prop 名取；
///   - `delegate:` 按构造**类型**转换后放进 `children`，不进 props；
///   - 具名实参是否为回调**只看形参声明类型**（源码构造签名，
///     [CtorSignatures]），不看名字（`onTap` / `buttonClick` 一视同仁）；
///     产物形态由消费方决定（JS 组件 → 普通函数，宿主 → `__fn` 句柄）；
///   - 位置实参 → 按 Flutter 声明的**形参名**（`Text('hi')` → `data`，从源码
///     构造签名抽取，见 [positionalArgNames]）；查不到的出声告警并丢弃；
///   - `key:` 由渲染层统一注入（见 `ElementTranslateContext._applyKeyProp`）。
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart' show log;

import '../../shared/ctor_signatures.dart';
import 'js_translator.dart';
import 'value_forms.dart';
import 'element2js.dart';

/// 结点上「命名构造 / 静态工厂名」的键（**产物中间态**，不跨语言）。
///
/// 只供渲染层把 `A.b(...)` 发射成 `A.b({...})`；它不是元素协议的一部分——
/// 跨语言的那份是 `props.factory`，由 JS 类上的同名静态方法写入（宿主据此
/// 选择原生工厂）。
const String ctorNodeKey = 'ctor';

/// 结点 Map 的**显式标记键**（产物中间态，不跨语言）。
///
/// 结点 Map 只由本文件（[elementToJson]）生产，生产时打上该标记；渲染层据此
/// 判定「这是元素结点」——不再按键集合 / 引号形态猜测（props 里 `Foo(type: _t)`
/// 这类普通容器与结点同形，猜测必然误判）。
const String nodeMarkerKey = '__node';

/// 任意 widget 构造 → 产物结点描述。
Map<String, dynamic> elementToJson(ElementNode node, ElementTranslateContext ctx) {
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
    // [ElementTranslateContext._applyKeyProp]）；这里跳过，避免把 Key 构造
    // 当作子结点/值重复翻译。
    if (name == 'key') continue;

    // 具名实参一律按**值的形态**翻译，不看参数名、不看组件类型。
    // 构造签名只用于一件事：`a.b` 这类成员引用在**函数类型形参**上是方法
    // tear-off（要包成绑定 this 的闭包），在普通值位置上是数据字段（原样引用）。
    // 是否需要跨语言句柄（`{__fn:id}`）由运行时在宿主 props 下发边界按 `typeof`
    // 决定（见 runtime.js 的 `__hostProps`），翻译层不判断「这是不是事件」。
    if (!isBuilderArg(name) && _functionTypedParam(node, name, ctx)) {
      final fn = _functionValueOrNull(ctx, value);
      if (fn != null) {
        props[name] = fn;
      } else if (value is! NullLiteral) {
        log.warning(
          '[hot_patch_generator] ${ctx.sourcePath}: ${node.type}.$name '
          '声明为函数类型，但无法翻译为函数值，已丢弃：${value.toSource()}',
        );
      }
      continue;
    }
    props[name] = autoValue(value, ctx, name: name);
  }

  // 命名构造 / 静态工厂名（`ListView.builder` / `Image.network`）不进 props：
  // 渲染成 `X.b({...})`，由 JS 类的同名静态方法把构造名写进 `props.factory`。
  final factory = factoryNameOf(node.expr, isPrefix: ctx.isImportPrefix);

  // 位置实参：按 Flutter 声明的**形参名**下发（`Text('hi')` → `data`）。
  // 构造签名查不到时没有可靠形参名，禁止伪造下标键（`$pos`）——出声告警并
  // 丢弃该结点。
  if (positional.isNotEmpty) {
    // 签名索引按**裸类名**查（`p.Foo` → `Foo`）：前缀只用于 JS 渲染。
    final names = positionalArgNames(
      ElementTranslateContext.bareTypeName(node.type),
      factory,
    );
    if (names != null && names.length >= positional.length) {
      for (var i = 0; i < positional.length; i++) {
        props[names[i]] = positional[i];
      }
    } else {
      log.warning(
        '[hot_patch_generator] ${ctx.sourcePath}: ${node.type} 的位置实参'
        '未找到构造签名里的形参名，已丢弃；'
        '请确认该构造的源码可被 ctor_signatures.dart 索引。',
      );
    }
  }

  // 构造的类型实参（`Consumer<NetworkVm>(...)` / `ChangeNotifierProvider<T>`）
  // → `typeArguments` 元信息 Map：与值构造、泛型方法调用同一条规则、同一份解析
  // （[typeArgsOf]），key 是类声明的类型参数名（`{T: 'CounterVm'}`）。谁需要谁读
  // （provider 据此声明类型键控的作用域、GlobalKey 据此决定 currentState 的代理
  // 类），翻译层不做类型判断、不发明语义化键名。
  final typeArgs = typeArgsOf(
    node.expr,
    declared: CtorSignatures.instance
            ?.typeParamsOf(ElementTranslateContext.bareTypeName(node.type)) ??
        const [],
  );
  if (typeArgs.isNotEmpty) {
    props['typeArguments'] = typeArgsMapJs(typeArgs);
  }

  return {
    'type': ctx.jsString(node.type),
    'props': nonNull(props),
    nodeMarkerKey: true,
    if (factory != null) ctorNodeKey: factory,
  };
}

/// 命名构造 / 静态工厂名；普通构造返回 null。
///
///   - `InstanceCreationExpression`（带 const）：`constructorName.name`；
///   - `MethodInvocation` **带 receiver**（静态工厂 `Image.network(...)` /
///     `Positioned.fill(...)`）→ 方法名；
///   - `MethodInvocation` 无 receiver（parseString 下无 const 的 `Foo(...)`）→
///     方法名就是类型名，不是工厂，返回 null。
String? factoryNameOf(
  Expression? e, {
  bool Function(String prefix)? isPrefix,
}) {
  if (e is InstanceCreationExpression) {
    final cn = e.constructorName;
    final direct = cn.name?.name;
    if (direct != null) return direct;
    // analyzer 7.x 把 `A.b(...)` 的**构造名整体**放进 `constructorName.type`
    // （`type.toSource()` = `'EdgeInsets.all'`），`constructorName.name` 为 null。
    // 按 `.` 切段：最后一段不是类名形态（小写开头）即为构造名；
    // `ui.EdgeInsets` 这种「导入前缀 + 类名」的最后一段是类名 → 无构造名。
    final segs = cn.toSource().split('.');
    if (segs.length >= 2) {
      final last = segs.last.split('<').first.trim();
      if (!isClassName(last)) return last;
    }
    return null;
  }
  if (e is MethodInvocation) {
    final target = e.target;
    if (target is PrefixedIdentifier) {
      // `p.Foo(...)`：方法名与类型名同名 → 不是工厂（与无 receiver 同形）；
      // `p.Foo.bar(...)` → 构造名 bar（`PrefixedIdentifier.name` 只给前缀，
      // 类型名要从源码文本取）。
      final full = target.toSource();
      final last = full.substring(full.lastIndexOf('.') + 1).split('<').first.trim();
      return e.methodName.name == last ? null : e.methodName.name;
    }
    // `p.Foo(...)`：target 是 import 前缀、方法名就是类型名 → 不是工厂。
    if (target is SimpleIdentifier && (isPrefix?.call(target.name) ?? false)) {
      return null;
    }
    return target is Identifier ? e.methodName.name : null;
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

/// 具名形参是否声明为**函数类型**（构造签名的源码事实）。
///
/// 只用于决定「成员引用怎么渲染」，与属性名 / `on*` 约定无关：
///   - 函数类型位置（`VoidCallback` / `ValueChanged<T>` / typedef 展开）上的
///     `a.b` 是**方法 tear-off** → 包成绑定 this 的闭包；
///   - 其它位置上 `a.b` 是普通成员读取 → 原样引用（`Colors.white` / 数据字段）。
///
/// 值最终是函数还是普通值，以及是否需要跨语言句柄，都不在这里判断：
/// 翻译层只产出字面值，宿主边界由运行时按 `typeof` 决定（见 runtime.js）。
///
/// 例外（协议级，先于类型判定）：builder 协议参数（`builder` / `itemBuilder`
/// / `pageBuilder` …）是返回 widget 的闭包，由 delegate 展开子树
/// （[isBuilderArg]），不参与本判定。
bool _functionTypedParam(ElementNode node, String name, ElementTranslateContext ctx) {
  final sig = CtorSignatures.instance?.of(
    ElementTranslateContext.bareTypeName(node.type),
    ctorName: factoryNameOf(node.expr, isPrefix: ctx.isImportPrefix),
    positionalCount: _positionalArgCount(node),
  );
  return sig != null && sig.functionParams.contains(name);
}

/// 调用点的位置实参个数（构造签名按它区分同名类的不同构造）。
int _positionalArgCount(ElementNode node) =>
    node.args.where((a) => a is! NamedExpression).length;

/// 函数类型形参位置上的值翻译（可调用 JS 表达式）；不是函数形态返回 null。
String? _functionValueOrNull(ElementTranslateContext ctx, Expression e) {
  if (e is NullLiteral) return null;
  try {
    return ctx.callbackJs(e);
  } catch (_) {
    return null;
  }
}

