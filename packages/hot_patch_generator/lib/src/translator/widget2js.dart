import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:build/build.dart' show log;

import '../builders/js_widget_defs.dart';
import 'js_translator.dart';
import 'widget_json.dart';

// ===========================================================================
// widget2js：widget → JS（build 树的翻译与渲染）
//
// widget 在 JS 端没有等价物，需专门翻译：
//   - build 树解析：WidgetNode / WidgetTranslateContext（表达式 → 中立描述）
//   - 中立描述 → JS：`__h(type, props)` 构造调用树（实参按原名进 props，
//     元素工厂在运行时按元素 type 拆结构子结点，见 widget_module_builder 的 __h）
//   - 统一翻译入口：widget_json.dart（widgetToJson）+ value_forms.dart（autoValue）
//   - 静态单例引用：SingletonResolver
// [WidgetTranslateContext] 实现 js_translator 的 [WidgetExprRenderer]，供
// 「Dart 类 → JS」在方法体里渲染返回的 widget。
//
// 扩展方式：**没有** per-widget 的翻译类。任意 widget（内建 / 自定义 / 三方）
// 都走同一条路径——按实参名约定（on* 事件 / delegate 子结点提供者 / 位置形参名）
// 与**值的形态**（字面量 / 构造 / 静态工厂 / 常量引用 / 列表 / 闭包）分派，
// 接入新组件零实现。
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

  /// 原始表达式（InstanceCreationExpression 等，取类型参数等用）。
  final Expression? expr;

  final String? factory;

  WidgetNode(this.type, this.args, {this.factory, this.expr})
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
class WidgetTranslateContext implements WidgetExprRenderer {
  final Map<String, String> propByField;
  final Map<String, String> actionByMethod;
  final String sourcePath;

  /// 本类**全部**实例方法 / getter 名（含非动作方法，如返回字符串的
  /// `_likeText`）。JS 类根部会生成所有方法，故数据表达式里的裸调用
  /// （`Text(_likeText(post.like))`）应翻译成 `this._likeText(...)`，而不只限于
  /// 注册为动作的方法。缺了它，非动作方法调用会整条翻译失败。
  final Set<String> methodNames;

  /// 本类 **getter** 名（`_visiblePosts` 这类）。getter 在 JS 类里是 `get` 访问器，
  /// 作为**函数值**传参时只能按值读（`this._visiblePosts`），不能像方法那样包装成
  /// 调用（`(...__a) => this._visiblePosts(...__a)` —— 访问器不可调用，传出去的
  /// 是函数而非 getter 的值，子组件拿到 `.length` 为 0 的空数据）。
  final Set<String> getterNames;

  /// 组件名 → 依赖产物 jsAsset 路径（null = 无法确定，渲染层走原生注入）。
  /// 由生成器注入：本文件私有/注解组件 → 本文件产物；跨文件组件 →
  /// 从 import directives 推导源文件产物。未注册/兜底组件结点据此产出 import，
  /// 运行时按 import 递归挂载嵌套组件（使用方无需知道依赖）。
  final String? Function(String component)? importResolver;

  /// 跨文件「静态单例类」解析器：build 树里 `MyColors.background`
  /// 这类静态引用翻译成 JS 表达式并登记 import 依赖。
  /// 由生成器从组件文件的 import 源文件解析注入；null = 不启用。
  final SingletonResolver? singletons;

  /// 本文件可见的顶层常量名（同文件 + import 文件）：build 树里 `kBrand` /
  /// `kBanners` 这类引用与字段初值、方法体共用同一份作用域。
  @override
  final Set<String> globalConsts;

  /// 宿主注入方法表（`类名 → {方法名 → 通道名}`；顶层函数挂在 `''` key 下）。
  /// 数据表达式 / 事件回调里 `AppRouter.openPost(id)` 这类 `@HostInjected`
  /// 调用要整体换成 `_app_host_.invoke("通道", 载荷)`——与普通类方法体共用同一份表，
  /// 否则事件里的跳转/提示整条翻译失败。
  final Map<String, Map<String, String>> hostMethods;

  /// 翻译过程中遇到的未注册自定义组件（兜底结点），供生成器
  /// 收集后把本文件内可解析的私有组件（_Xxx）翻译成嵌套组件注册进产物。
  final Set<String> dependencies = {};

  /// 翻译/渲染过程中**实际用到**的 widget 类型：package → {type}。
  /// [renderJs] 在此登记，生成器据此按 package 产出 JS widget 模块并 import。
  final Map<String, Set<String>> usedWidgetPackages = {};

  /// 渲染过程中是否产出过元素构造 [`__h`]。生成器据此决定产物是否 import
  /// 结点工厂：有元素树（组件 build 树 / 方法体里返回 widget）就必须 import；
  /// 纯模型产物（无任何元素）不产生多余 import。
  bool usedNodeHelper = false;

  /// ListenableBuilder 等「builder 闭包」翻译：闭包返回的子树抽到组件方法
  /// `_lbBuilderN()`，运行时时模型 notify 后重新调用拿到最新子树做局部重建。
  /// 收集顺序即 `_lbBuilder${index}` 命名序号。
  final List<Object?> builderTrees = []; // Map = 节点；String = 三目 JS 表达式

  /// 与 [builderTrees] 同步的方法名（`_lbBuilderN` / `_consumerBuilderN`）。
  final List<String> builderNames = [];

  /// 与 [builderTrees] 同步的**形参声明**（Dart 闭包签名逐字对应，如
  /// `context, index` / `context, value`——`context` 是 Dart
  /// `build(BuildContext context)` 那个形参，被委托方法因此天然看得见它）。
  final List<String?> builderParams = [];

  /// 与 [builderTrees] 同步的「方法体前置语句」（JS 源码，如 Builder 闭包
  /// 块体里的 `var model = context.watch('MyModel');`）。
  final List<String> builderPreludes = [];

  WidgetTranslateContext({
    required this.propByField,
    required this.actionByMethod,
    required this.sourcePath,
    this.methodNames = const {},
    this.getterNames = const {},
    this.importResolver,
    this.singletons,
    this.globalConsts = const {},
    this.hostMethods = const {},
    this.jsClassWidgets = const {},
    this.delegateClassWidgets = const {},
  });

  /// 有 JS 类实现的 widget 类型（组件、逻辑 widget、builder 代理）。
  /// 由生成器注入（builder 的模板表是唯一事实源）。
  final Set<String> jsClassWidgets;

  /// 仅 builder 形态才走 JS 类的类型（滚动视图/sliver 代理：普通
  /// `GridView(children: [...])`、`SliverList(delegate: ...)` 仍是宿主节点，
  /// `.builder` / `.separated` 形态才需要类来循环调用拥有者方法展开子树）。
  final Set<String> delegateClassWidgets;

  /// 本节点的元素 type 用 **JS 类引用**还是**类型名字符串**。
  ///
  /// JS 里没有「factory」这层包装：元素的 type 就是类本身（有 JS 逻辑的类型）
  /// 或宿主 widget 的类型名（由宿主注册表映射成 Flutter widget）。有 JS 类的
  /// 类型要 import 类名，宿主类型名是字符串字面量、无需 import。
  bool usesJsClass(String type, Map<String, dynamic>? props) {
    if (!jsClassWidgets.contains(type)) return false;
    if (!delegateClassWidgets.contains(type)) return true;
    if (props == null) return false;
    // 判定只看**产物里显式写下的工厂名**（`factory`），不看属性名：
    // 命名构造 `.builder` / `.separated` → 走 JS 代理类循环调用拥有者方法展开
    // 子树；普通 `children:` / `delegate:`（含 ListDelegate 与 BuilderDelegate）
    // 形态直接是宿主节点，由宿主/运行时按 delegate 描述消费。
    return props.containsKey(factoryPropsKey);
  }

  /// 记录一个被兜底为「保留具体类型名结点」的自定义组件名。
  void collectDependency(String name) => dependencies.add(name);

  // -------------------------------------------------------------------------
  // 递归入口：表达式 → JSON 描述 / JS 渲染
  // -------------------------------------------------------------------------

  /// 把 build() 里的一个 widget 表达式翻译成中立描述（渲染层据此产出 JS）。
  ///
  /// 返回 Map = 普通节点；返回 String = **单元素**位置的 JS 源码，渲染层原样
  /// 内联（widget 位置三目 `cond ? A() : B()` → `(condJs ? A : B)`，每支各是
  /// **一个**元素，不是数组——见 [_elementExprJs]）。
  ///
  /// **单个叶子失败不再炸掉整棵 build 树**（放大器缺陷修复）：每次递归调用
  /// 各自兜底——坏叶子降级为占位结点 + 构建期告警，兄弟结点照常翻译。
  @override
  Object? translate(Expression e) {
    try {
      return _translateExpr(e);
    } catch (err) {
      _warnDegrade('widget 表达式', e.toSource(), err);
      return _placeholderNodeJson();
    }
  }

  Object? _translateExpr(Expression e) {
    if (e is ConditionalExpression) {
      // widget 位置三目：每支都是**单个**元素（`child: cond ? A : B`）。
      // 绝不能走 [_collectionArrayJs]——那产出的是「元素数组」，用在单子位置
      // 会变成 props.child 里的嵌套数组（`[ (cond ? [A] : [B]) ]`），元素工厂
      // 抽 children 时 `mount` 拿到数组 → `el.type` undefined → `new el.type` 抛错。
      final cond = jsDataExpr(e.condition);
      final thenJs = _elementExprJs(e.thenExpression);
      final elseJs = _elementExprJs(e.elseExpression);
      return '($cond ? $thenJs : $elseJs)';
    }
    // widget 位置上可能是「构造形态」的只有：InstanceCreationExpression
    // （`const Text(..)`）、无 receiver 的裸调用（`Text(..)` / `_LabeledDivider(..)`）、
    // 以及**静态工厂**（`Image.network(..)` / `Positioned.fill(..)`）。
    // 其余表达式——带实例 receiver 的方法调用（`_modelA.buildText()`）、
    // 字段/属性引用——都是**普通 JS 表达式**，运行时求值即得到元素；绝不能当
    // 组件类构造（否则会把实例方法 `_buildText` 误判成名为 `_buildText` 的组件，
    // 产出错误的兜底结点）。区分靠「构造名是否命中已注册 translator」：
    // 静态工厂的 receiver 是类名，必然命中；实例方法/字段的 receiver 不会命中。
    final (ctor, _) = ctorOf(e);
    if (ctor == null) return _exprAsElement(e);
    // 组件构造的构造名是**类名**（`Image.network(...)` / `Transform.translate(...)`
    // 这类命名构造与静态工厂都归一到类名）；实例方法调用（`_model.build()`、
    // `context.read<T>()`）与命中动作表的裸调用都是普通表达式。判据只看名字
    // 形态，与 widget 类型无关。
    if (e is MethodInvocation) {
      if (actionByMethod.containsKey(ctor)) return _exprAsElement(e);
      if (!_isClassName(ctor)) return _exprAsElement(e);
    }
    // 统一翻译：任意构造 → 结点（不查注册表、不区分内建/自定义）。未识别的
    // 自定义与三方组件同样产出「保留具体类型名」的结点，运行时按需原生注入
    // （registerNativeComponent）或给出可见占位。
    collectDependency(ctor);
    final node = _toNode(e);
    final json = widgetToJson(node, this);
    // `key:` 是跨所有 widget 的通用参数（Key 是值不是结点），此处统一注入
    // props['key']（见 [_applyKeyProp]）。
    _applyKeyProp(json, node);
    return json;
  }

  /// widget 位置上的「非构造表达式」→ JS 表达式字符串（运行时求值即元素）：
  /// `_buildText()` / `_modelA.buildText()` / 字段引用等。翻译不了则出声抛错。
  Object? _exprAsElement(Expression e) {
    try {
      return jsDataExpr(e);
    } catch (err) {
      throw FormatException(
        'hot_patch_generator: widget 位置的表达式无法翻译：'
        '${e.toSource()}（$err）',
      );
    }
  }

  /// 把 widget 构造里的 `key:` 实参注入到翻译产物的 props['key']。
  ///
  /// `key` 是**所有 widget 共有的通用参数**（Key 是**值**不是结点，见
  /// js_translator.keyCtorJs）——各 translator 只挑自己关心的参数，故 key 必须
  /// 在这里统一注入，否则被静默丢弃（曾导致 ReorderableListView 项的
  /// `key: ValueKey(item)` 丢失、重排后列表状态错位）。
  /// 产物 props['key'] 存 JS 表达式字符串（`new ValueKey(this._items[i])`），
  /// 运行时随 props 序列化下发，宿主侧还原成真实 Flutter Key（key_bridge）。
  /// key 是**附加**信息：翻译不出来只丢 key（并出声），不拖垮整个结点。
  void _applyKeyProp(Map<String, dynamic> json, WidgetNode node) {
    final keyExpr = node.namedArgs['key'];
    if (keyExpr == null) return;
    final String js;
    try {
      js = jsDataExpr(keyExpr);
    } catch (err) {
      _warnDegrade('key', keyExpr.toSource(), err);
      return;
    }
    final props = json['props'];
    if (props is Map) {
      props['key'] = js;
    } else {
      json['props'] = <String, dynamic>{'key': js};
    }
    // 结点上另记一份 `json['key']`：**组件的**两条渲染路径（有产物
    // `__h(X, props)` / 无产物 `__h("X", props)`）取的是 `json['key']`
    // （见 _renderJsImpl），只写 props['key'] 会让挂在
    // 组件结点上的 key 静默丢失（宿主结点读 props['key']，故宿主不受影响）。
    // 两处值同源，读哪一份都一样。
    json['key'] = js;
  }

  /// children 列表项翻译：Expression → 节点 Map；IfElement / ForElement →
  /// JS spread 表达式字符串（`...(cond ? [a] : [b])` / `...(function(){...})()`），
  /// 渲染层对 String 原样嵌入（内联构造调用 + 条件/循环展开）。
  Object? translateElement(CollectionElement e) {
    try {
      if (e is Expression) return translate(e);
      if (e is IfElement) return '...${_ifAsArray(e)}';
      if (e is ForElement) return '...${_forAsArray(e)}';
      // `...<list>` 展开（`...[Positioned.fill(...), Positioned(...)]`）：把内层
      // 元素数组原样展开进 children（`...[a, b]` ≡ `a, b`）。
      if (e is SpreadElement) return '...${_collectionArrayJs(e.expression)}';
      throw FormatException('不支持的 collection element: ${e.toSource()}');
    } catch (err) {
      // 单个集合元素（如 `...[...]` spread）无法翻译：降级为占位结点，
      // 兄弟元素照常翻译（放大器缺陷修复）。
      _warnDegrade('集合元素', e.toSource(), err);
      return _placeholderNodeJson();
    }
  }

  /// if/for 作为「元素数组」出现（数组字面量里嵌套、三目分支等），
  /// 不带 spread 前缀：`(cond ? [a] : [b])`。
  String _ifAsArray(IfElement e) {
    final cond = jsDataExpr(e.expression);
    final thenJs = _collectionArrayJs(e.thenElement);
    final elseJs = e.elseElement == null
        ? '[]'
        : _collectionArrayJs(e.elseElement!);
    return '($cond ? $thenJs : $elseJs)';
  }

  /// for 循环 → JS IIFE 展开数组（循环变量 var 提升在 IIFE 内，body 直接引用）。
  String _forAsArray(ForElement e) {
    final parts = e.forLoopParts;
    // 本循环推入的循环变量：渲染结束（含失败）后精确移除，避免异常路径
    // 把作用域泄漏给兄弟结点（放大器缺陷修复的一部分）。
    final pushed = <String>[];
    String head;
    try {
      if (parts is ForPartsWithDeclarations) {
        // 传统 for：`for (var i = 0; i < n; i++)` → JS 同构
        final vars = parts.variables.variables.toList();
        // 循环变量先入作用域：condition/updaters/body 里引用 i 都走 loopVars
        for (final v in vars) {
          pushLoopVar(v.name.lexeme);
          pushed.add(v.name.lexeme);
        }
        final varList = vars.isEmpty
            ? ''
            : 'let ${vars.map((v) => '${v.name.lexeme} = ${v.initializer == null ? '0' : jsDataExpr(v.initializer!)}').join(', ')}';
        final condJs = parts.condition == null
            ? ''
            : jsDataExpr(parts.condition!);
        final incJs = parts.updaters.isEmpty
            ? ''
            : parts.updaters.map((u) => jsDataExpr(u)).join(', ');
        head = 'for ($varList; $condJs; $incJs)';
      } else if (parts is ForPartsWithExpression) {
        // 无声明：`for (i = 0; i < n; i++)`（变量需为已收集的状态字段）
        final initJs = parts.initialization == null
            ? ''
            : jsDataExpr(parts.initialization!);
        final condJs = parts.condition == null
            ? ''
            : jsDataExpr(parts.condition!);
        final incJs = parts.updaters.isEmpty
            ? ''
            : parts.updaters.map((u) => jsDataExpr(u)).join(', ');
        head = 'for ($initJs; $condJs; $incJs)';
      } else if (parts is ForEachPartsWithDeclaration) {
        // for-in（带声明）：`for (final s in kOrderStatus)` → `for (let s of <iter>)`。
        // 用 `let` 而非 `var`：每次迭代一个独立绑定，迭代内注册的事件闭包
        // （`__bindFn`）才能捕获到**本次**的值（`var` 会让所有迭代共享末值）。
        final name = parts.loopVariable.name.lexeme;
        pushLoopVar(name);
        pushed.add(name);
        head = 'for (let $name of ${jsDataExpr(parts.iterable)})';
      } else if (parts is ForEachPartsWithIdentifier) {
        // for-in（无声明）：`for (s in kOrderStatus)`（变量为已收集的状态字段/局部量）
        final name = parts.identifier.name;
        head = 'for ($name of ${jsDataExpr(parts.iterable)})';
      } else {
        throw FormatException('不支持的 for 循环形式: ${e.toSource()}');
      }
      final bodyJs = _collectionArrayJs(e.body);
      // 必须用**箭头函数** IIFE：body 里常引用状态字段（`this.banners`），
      // 普通 function 立即调用时 this 丢失（严格模式下为 undefined）。
      return '(() => { var out = []; $head { out.push.apply(out, $bodyJs); } return out; })()';
    } finally {
      // 清除本循环的循环变量作用域（渲染完成后，body 内已引用 i）
      for (final n in pushed) {
        _loopVars.remove(n);
      }
    }
  }

  /// collection element → JS 数组字面量（元素数组语义；嵌套 if/for 递归展开）。
  String _collectionArrayJs(CollectionElement e) {
    if (e is Expression) {
      final t = translate(e);
      if (t is String) return '[$t]';
      return '[${renderJs(t, 2)}]';
    }
    if (e is IfElement) return _ifAsArray(e);
    if (e is ForElement) return _forAsArray(e);
    // `...<list>` / `...<field>`：展开内层元素。
    //   - 内层是**列表字面量**（widget 列表）：逐元素走 [translateElement]
    //     渲染成元素数组（`...[Positioned(...), Positioned(...)]`）。
    //   - 其余（运行时数组字段）：`[...<expr>]` 运行时展开。
    if (e is SpreadElement) {
      final inner = e.expression;
      if (inner is ListLiteral) {
        final items = inner.elements.map(_elementJs).join(', ');
        return '[$items]';
      }
      final t = translate(inner);
      return '[...${t is String ? t : renderJs(t, 2)}]';
    }
    throw FormatException('不支持的 collection element: ${e.toSource()}');
  }

  /// 单个 collection element → JS 数组项源码：String（已是 JS 表达式，含
  /// `...spread` / IIFE / 三目）原样内联，节点 Map 走 [renderJs]。
  String _elementJs(CollectionElement e) {
    final t = translateElement(e);
    return t is String ? t : renderJs(t, 2);
  }

  /// 单个 widget 表达式 → JS 源码（**单元素**语义）：节点 Map 走 [renderJs]，
  /// 已是 JS 表达式（三目 / 字段引用 / 方法调用）原样内联。
  ///
  /// 与 [_elementJs] 的分工：后者输入是「集合元素」（数组语义，可带 spread），
  /// 本方法输入是「元素本身」（如 `child: cond ? A : B` 的单支、单子组件的
  /// 实参）——绝不能产出数组字面量，否则会变成 props.child 里的嵌套数组。
  String _elementExprJs(Expression e) {
    final t = translate(e);
    return t is String ? t : renderJs(t, 2);
  }

  /// 循环变量作用域：for 循环变量（i 等）在 body 翻译期间遮蔽状态字段查表。
  /// 入/出成对：[_forAsArray] 用 `finally` 精确移除本次循环推入的变量。
  final Set<String> _loopVars = {};
  void pushLoopVar(String name) => _loopVars.add(name);

  /// build() return 前的局部变量（`final isAdult = ...;`）：树里直接引用。
  final Set<String> _locals = {};
  void addLocal(String name) => _locals.add(name);

  /// **方法体局部变量**（来自 [registerLocal]，即各方法体里 `var/final x = ...`）。
  ///
  /// 它们只在**本方法**内可见：懒加载 builder 被抽成实例方法
  /// （`_listViewBuilderN` / `_sliverBuilderN`）后看不到这些名字——只有被折算成
  /// 字段引用（[registerLocalAlias]）才安全，否则产物里就是未定义自由变量。
  final Set<String> _methodBodyLocals = {};

  /// 抽取出的 builder 方法里**真实可见**的名字（闭包形参 context/index +
  /// 块体前置语句声明的局部，见 [addBuilderLocal]）。判「捕获了方法体局部变量」
  /// 时用来排除。
  final Set<String> _extractedVisible = {};

  /// 懒加载 builder 自己的名字：闭包形参（context / index）与块体前置语句声明的
  /// 局部——它们会成为抽取方法的前置语句，方法体里天然可见。
  void addBuilderLocal(String name) {
    _locals.add(name);
    _extractedVisible.add(name);
  }

  /// [WidgetExprRenderer.registerLocal] 实现：方法体翻译器声明局部变量时
  /// 同步登记，保证同一方法体里返回的 widget 树能解析这些名字。
  ///
  /// 同时记为「方法体局部变量」：被抽走的 builder 子树里引用了它就必须告警
  /// （见 [warnCapturedLocals]）。
  @override
  void registerLocal(String name) {
    _locals.add(name);
    _methodBodyLocals.add(name);
  }

  /// 抽查懒加载 builder 闭包捕获的名字（构建期告警，不静默）。
  ///
  /// 会被抽成独立实例方法的子树里，只有**闭包形参与前置语句局部**、类成员
  /// （字段 / getter / 方法）、顶层常量可见；`build` 的方法体局部变量与循环变量
  /// 都不在其中——折算不出字段引用时产物就是未定义自由变量，运行时
  /// `ReferenceError`（子结点展开失败 → 页面停在 loading，且错误被求值层吞掉，
  /// 现场几乎无法定位）。
  ///
  /// 正常路径（`final spots = _feed.spots;` 这类字段派生的 final 局部）会先被
  /// [registerLocalAlias] 折算成 `this._feed.spots`，不会命中本告警。
  void warnCapturedLocals(Expression body) {
    final used = <String>{};
    body.accept(_SimpleIdentifierCollector(used));
    for (final name in used) {
      if (!_methodBodyLocals.contains(name) && !_loopVars.contains(name)) {
        continue;
      }
      if (_extractedVisible.contains(name) ||
          _localAliases.containsKey(name) ||
          propByField.containsKey(name) ||
          methodNames.contains(name) ||
          getterNames.contains(name) ||
          globalConsts.contains(name)) {
        continue;
      }
      log.warning(
        '[hot_patch_generator] $sourcePath: "$name" 被懒加载 builder '
        '捕获，却折算不成字段引用（字段 / getter / 顶层常量）：抽取成实例方法'
        '后 JS 侧是未定义自由变量（运行时 ReferenceError，页面会停在 loading）。'
        '请把该值放到字段 / getter 上，或改用「字段派生的 final 局部」'
        '（如 `final spots = _feed.spots;`）。',
      );
    }
  }

  /// 局部别名（`final list = _list;` → `list → this._list`）。被抽成实例方法的
  /// 懒加载 builder 引用该名字时，必须落成真实字段引用（见 [jsDataExpr]）。
  final Map<String, String> _localAliases = {};
  @override
  void registerLocalAlias(String name, String jsExpr) =>
      _localAliases[name] = jsExpr;

  /// 当前正在翻译的方法形参（`withMethodParams` 期间有效）。
  final Set<String> _methodParams = {};

  /// [WidgetExprRenderer.withMethodParams] 实现：翻译某方法体期间把形参登记进
  /// widget 层作用域，结束后恢复（连同本方法产生的局部别名一起回收，避免跨方法串味）。
  @override
  T withMethodParams<T>(Iterable<String> params, T Function() body) {
    final added = <String>[];
    for (final p in params) {
      if (_methodParams.add(p)) added.add(p);
    }
    final aliasesBackup = Map<String, String>.from(_localAliases);
    try {
      return body();
    } finally {
      for (final p in added) {
        _methodParams.remove(p);
      }
      _localAliases
        ..clear()
        ..addAll(aliasesBackup);
    }
  }

  /// 名字是否形如**类名**：跳过前导下划线后首字母大写。
  ///
  /// `Image` / `_OrderCard`（私有组件类）是类名；`_model` / `context` / `build`
  /// 是实例成员。用于区分「组件构造」与「实例方法调用」，与 widget 类型无关。
  static bool _isClassName(String name) {
    var n = name;
    while (n.startsWith('_')) {
      n = n.substring(1);
    }
    return n.isNotEmpty && n[0] == n[0].toUpperCase();
  }

  /// 渲染一个已翻译的中立节点为统一元素构造 `__h(type, props)`。
  ///
  /// 值契约：toJson 的叶子值一律是 JS 表达式字符串（`"Text"` 这类字符串
  /// 字面量由 [jsString] 产生），因此分发前剥离字符串字面量的引号取语义名。
  ///
  /// 渲染失败同样兜底为占位结点（放大器缺陷修复）：单个结点渲染异常不影响
  /// 兄弟结点与上层结点。
  @override
  String renderJs(Object? json, int depth) {
    try {
      return _renderJsImpl(json, depth);
    } catch (err) {
      _warnDegrade('结点', json.toString(), err);
      return _placeholderJs();
    }
  }

  String _renderJsImpl(Object? json, int depth) {
    if (json is String) return json; // 三目/条件表达式（JS 源码字符串）
    if (json is! Map<String, dynamic>) {
      throw FormatException('无法渲染的节点: $json');
    }
    usedNodeHelper = true; // 渲染元素 → 产物必须 import 结点工厂 __h
    final type = _semanticType(json['type']);
    final props = json['props'];
    final propsMap = props is Map<String, dynamic> ? props : null;
    // 元素 type 用**类引用**还是**类型名字符串**：
    //   - 该类型有 JS 产物（importResolver 命中：@PatchEntry 嵌套组件、同文件
    //     私有组件）→ 类引用 `__h(X, …)`，运行时递归挂载 JS 组件；
    //   - 该类型在 JS 侧有类（[jsClassWidgetTypes] 的逻辑组件 / sliver builder
    //     代理，且确实带 builder 形态）→ 类引用，并登记其 package 模块以便 import；
    //   - 其余（宿主 widget 与无产物的自定义组件）→ 字符串类型名 `__h("X", …)`，
    //     运行时注册表未命中则走默认 builder（宿主 registerNativeComponent 注入的
    //     原生实现，否则给出可见占位）。
    final productType = importResolver?.call(type);
    final asClass = productType != null || usesJsClass(type, propsMap);
    if (productType == null && asClass) {
      (usedWidgetPackages[widgetPackageOf(type)] ??= <String>{}).add(type);
    }
    return _renderCall(type, json, depth, asClass: asClass);
  }

  /// 结点级的 `key` 并入元素 props：Key 是**元素级参数**（见
  /// [WidgetTranslateContext._applyKeyProp]），渲染时统一落在 `props.key` 上
  /// ——运行时 `keyOf` / 宿主 key 桥读的就是它。无 key 时 props 原样复制。
  static Map<String, dynamic> _propsWithKey(Object? props, Object? key) {
    final out = <String, dynamic>{};
    if (props is Map) {
      for (final e in props.entries) {
        out['${e.key}'] = e.value;
      }
    }
    if (key != null) out['key'] = key;
    return out;
  }

  /// 把已翻译的 JSON 节点渲染成统一元素构造：`__h(<type>, {...})`。
  ///
  /// JS 没有「factory」这层包装：元素 type 直接是类（有 JS 逻辑的类型，[asClass]
  /// 为 true）或宿主 widget 类型名字符串。所有 Dart 实参都按原名进 props——
  /// `child` / `children` / `slivers` / `tabs` 也在 props 里，由元素工厂 `__h`
  /// 在**运行时按元素类型**拆分：宿主类型抽成 `element.children`，JS 组件类型
  /// 原样保留给 `__applyProps`。因此这里不再传第三参，也不再区分单子/多子。
  String _renderCall(
    String type,
    Map<String, dynamic> json,
    int depth, {
    required bool asClass,
  }) {
    final props = _propsWithKey(json['props'], json['key']);
    final propsJs = props.isNotEmpty ? jsLiteral(props, depth + 1) : '{}';
    final typeArg = asClass ? type : "'$type'";
    return '__h($typeArg, $propsJs)';
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
      // 带 `const` 的命名构造（`const EdgeInsets.all(8)`）在 AST 里把
      // `EdgeInsets.all` **整体**放进 `constructorName.type`，`name2` 只取最后
      // 一段（'all'）。这里取**类型名**：从右往左取第一个类名形态的段
      // （`EdgeInsets.all` → 'EdgeInsets'；`material.Padding` → 'Padding'）。
      return (
        _typeNameOf(e.constructorName.type.toSource()),
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

  /// 构造名源码 → **类型名**：`EdgeInsets.all` → 'EdgeInsets'；
  /// `material.Padding` → 'Padding'；`Padding` → 'Padding'。
  static String _typeNameOf(String ctorSource) {
    final parts = ctorSource.split('.');
    for (var i = parts.length - 1; i >= 0; i--) {
      final seg = _stripGenerics(parts[i]);
      if (_isClassName(seg)) return seg;
    }
    return _stripGenerics(parts.last);
  }

  /// 去掉类型实参：`ChangeNotifierProvider<NetworkVm>` → 'ChangeNotifierProvider'。
  static String _stripGenerics(String s) {
    final lt = s.indexOf('<');
    return lt >= 0 ? s.substring(0, lt) : s;
  }

  Expression? namedArg(List<Expression> args, String name) {
    for (final a in args) {
      if (a is NamedExpression && a.name.label.name == name) {
        return a.expression;
      }
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

  /// children / slivers / tabs 等列表参数 → **已翻译的**JS 数组项（节点 Map /
  /// JS 表达式字符串），渲染层逐项 [jsLiteral]。
  ///
  ///   - `children: [...]` 字面量 → 逐元素 [translateElement]（if/for/spread 由它
  ///     统一展开成 JS spread 表达式）；
  ///   - `children: someList`（字段 / 局部变量，如 `Row(children: children)`）→
  ///     单个 `...<expr>` spread 项，运行时把该数组展开进对应的 props 数组。
  List<Object?> listArg(List<Expression> args, String name, String ctor) {
    final e = namedArg(args, name);
    if (e is ListLiteral) {
      return [for (final c in e.elements) translateElement(c)];
    }
    if (e != null) {
      try {
        return ['...${jsDataExpr(e)}'];
      } catch (err) {
        throw FormatException('$ctor 的 $name 无法翻译：${e.toSource()}（$err）');
      }
    }
    throw FormatException('$ctor 缺少 $name 列表');
  }

  /// 字段名（`_count`）→ 状态名（`count`）
  String propOf(Identifier id) {
    final prop = propByField[id.name];
    if (prop != null) return prop;
    throw FormatException('"${id.name}" 不是组件状态字段（@PatchEntry 组件的实例字段）');
  }

  /// 方法名 → 事件名
  String eventOf(String method) {
    final event = actionByMethod[method];
    if (event != null) return event;
    throw FormatException('"$method" 不是组件方法（未注册为动作）');
  }

  /// `widget.<name>`（State 里引用 widget 自身成员）→ 成员名 `<name>`。
  ///
  /// widget 与 State 在 JS 侧合并成同一个类，`widget.x` 就是 `this.x`。
  /// 注意 analyzer 里 [PrefixedIdentifier] 是 [Identifier] 的子类且 `name` 是
  /// 整串 `widget.x`：不先识别出来，就会拿整串名字去查字段/动作表而必然失败。
  /// 非 `widget.` 前缀（或非简单 `x.y`）返回 null。
  String? widgetMemberName(Expression? e) =>
      e is PrefixedIdentifier && e.prefix.name == 'widget'
      ? e.identifier.name
      : null;

  /// 事件参数解析：`onTap: _tap` / `onTap: () => _tap()` → 组件方法调用；
  /// 带 receiver 的调用（Builder 闭包局部变量 `model.inc()`、
  /// `context.read<T>().reset()` 链式）→ 翻译为 JS 方法调用表达式
  /// （一比一，不查动作表——方法/属性全量生成，无需标注）。
  ///
  /// [scope] 缺省为事件作用域 [_eventScope]；事件闭包的**形参**（`(v) => ...`
  /// 里的 `v`）由调用方经 [FieldScope.withParams] 并入后传入，保证实参里的
  /// 形参名原样落成 JS 标识符。
  String eventExpr(Expression e, [FieldScope? scope]) {
    final activeScope = scope ?? _eventScope();
    if (e is Identifier) {
      // `widget.<name>`（State 里引用 widget 自身的字段/方法，如
      // `onReset: widget.onReset`）：合并类里就是实例成员，调它即可。
      final wm = widgetMemberName(e);
      if (wm != null) {
        final prop = propByField[wm];
        if (prop != null) return 'this.$prop()';
        if (methodNames.contains(wm)) return 'this.$wm()';
        return eventOf(wm);
      }
      // 字段型回调（`onTap: onTap` / `onTap: _onTap`）：字段里存的就是可调用值，
      // 事件触发即调它。字段本身由父组件经函数实参传入（见 [functionJs]）。
      final prop = propByField[e.name];
      if (prop != null) return 'this.$prop()';
      return eventOf(e.name);
    }
    if (e is FunctionExpression) {
      final inner = functionInner(e);
      if (inner is MethodInvocation) {
        // `setState(() {...})`：组件自身的状态更新，不是 @PatchEntry 声明的方法
        // （Dart 的 State.setState 由框架提供）。翻译成 `this.setState(<closure>)`，
        // 运行时基类已提供 setState（见 mini_react_js）。
        if (inner.target == null && inner.methodName.name == 'setState') {
          return _setStateCallJs(inner, activeScope);
        }
        final target = inner.target;
        // @HostInjected 调用（`AppRouter.pop()` / `AppRouter.toast('x')`）：事件
        // 表达式与方法体翻译共用同一份通道表，整体换成 `_app_host_.invoke(通道, 载荷)`。
        // 少了这一步，事件串里的 `this.AppRouter.pop()` 在运行时只是对一个不存在
        // 属性的访问（抛错被运行时吞掉），点击静默失效。
        final hostCall = _hostEventJs(
          target,
          inner.methodName.name,
          inner.argumentList,
          activeScope,
        );
        if (hostCall != null) return hostCall;
        // 局部变量 receiver（`model.inc()`，model 是 builder 里的
        // `final model = context.watch<T>()`）：保留局部名，由 [_eventFnJs]
        // 生成的**构建期箭头闭包**天然捕获它（与 Dart 闭包同语义）。
        // 有别名（`final list = _list;`）的局部落成真实字段引用。
        if (target is Identifier && _locals.contains(target.name)) {
          final recv = activeScope.fieldRef(target.name) ?? target.name;
          return '$recv.${inner.methodName.name}'
              '(${_eventArgsJs(inner.argumentList, activeScope)})';
        }
        // context.read<T>().reset() 链式：先翻译 receiver（jsDataExpr →
        // this.context.read('T')），再拼方法调用。
        if (target is MethodInvocation) {
          final recv = jsDataExpr(target, activeScope);
          return '$recv.${inner.methodName.name}'
              '(${_eventArgsJs(inner.argumentList, activeScope)})';
        }
        // `widget.onPick(key, v)`（`() => widget.onPick(key, v)`）：调用 widget
        // 自身成员——合并类里就是实例方法/字段回调，落成 `this.onPick(key, v)`。
        // 不拦下来会走下面的「组件字段 receiver」分支产出 `this.widget.onPick(...)`
        // ——`widget` 在 JS 侧根本没有这个字段，点击直接抛错失效。
        if (target is Identifier && target.name == 'widget') {
          final wm = inner.methodName.name;
          final args = _eventArgsJs(inner.argumentList, activeScope);
          final prop = propByField[wm];
          if (prop != null) return 'this.$prop($args)';
          if (methodNames.contains(wm)) return 'this.$wm($args)';
          return eventOf(wm);
        }
        // 组件字段/实例 receiver（非局部变量即组件成员）：`_controller.clear()`
        // / `_scrollController.jumpTo(...)` → this._controller.clear()，
        // 不查动作表（实例方法全量生成，与 Dart 写法一致）。
        if (target is Identifier) {
          return 'this.${target.name}.${inner.methodName.name}'
              '(${_eventArgsJs(inner.argumentList, activeScope)})';
        }
        // 无 receiver 的裸调用 `_openMenu(context, i)` / `_go(text)`：本组件实例
        // 方法 → `this.<name>(<args>)`。必须保留「调用 + 实参」形态：只回方法名会
        // 让闭包体变成 `() => { _openMenu; }`（引用而非调用，点击无任何反应）。
        final method = inner.methodName.name;
        // 顶层 @HostInjected 函数（无 receiver，如 `toast('x')`）→ 宿主通道。
        final topHost = _hostEventJs(
          null,
          method,
          inner.argumentList,
          activeScope,
        );
        if (topHost != null) return topHost;
        if (actionByMethod.containsKey(method) ||
            methodNames.contains(method)) {
          return 'this.$method(${_eventArgsJs(inner.argumentList, activeScope)})';
        }
        // 字段型回调用法（`() => onPick(key, v)` / `_FilterPanel` 里的分组循环）：
        // 字段存的是父组件传进来的函数，调它即 `this.<prop>(<args>)`。
        final prop = propByField[method];
        if (prop != null) {
          return 'this.$prop(${_eventArgsJs(inner.argumentList, activeScope)})';
        }
        return eventOf(method);
      }
    }
    throw FormatException('事件参数需要直接引用方法（如 onTap: _tap 或 () => _tap()）');
  }

  /// 事件的**编译期位点号**：产物是静态源码，同一个 `on*` 位点每次构建都是
  /// 同一个号；不同位点必不相同。运行时以「位点号 + 捕获值」复用句柄 id，
  /// 从而重建后 props 稳定、增量补丁不失效，同时循环项之间互不串味。
  int _eventSite = 0;

  /// 事件「构建期句柄」：统一产出构建期**箭头闭包**，由运行时登记成句柄
  /// （`{__fn:id}`，函数不能跨语言传递，只能传 id）。
  ///
  ///     this.__bindFn(17, [i], (...__a) => this._open(i, ...__a))
  ///     this.__bindFn(18, [], () => model.inc())
  ///     this.__bindFn(19, [], (v) => this.setState(() => { this._v = v; }))
  ///
  /// 闭包在 build（或抽出的 builder 方法）里创建，天然捕获当时的局部变量 /
  /// 循环变量——与 Dart 闭包同语义，不存在「点击时求值看不见构建期名字」的
  /// 问题（这正是过去 `__bind` 字符串方案会静默失效的场景）。
  ///
  /// 第二个实参是**捕获值列表**：捕获到不同值的循环项必须拿到不同句柄
  /// （否则点任意行都执行最后一行的回调）。
  String eventHandle(Expression e) {
    final site = _eventSite++;
    try {
      final captures = _eventCaptures(e);
      final fnJs = _eventFnJs(e);
      return 'this.__bindFn($site, [${captures.join(', ')}], $fnJs)';
    } catch (err) {
      // 单个事件翻译失败不该炸掉整棵 build 树（放大器缺陷）：降级为「空操作
      // 句柄」，其余结点照常翻译。
      // ignore: avoid_print - 构建期日志
      print(
        '[hot_patch_generator] 事件处理无法翻译，已降级为空操作：'
        '${e.toSource()}（$err）',
      );
      return 'this.__bindFn($site, [], () => {})';
    }
  }

  /// 事件表达式 → JS 箭头函数源码（参数按 Dart 闭包签名逐字对应）。
  String _eventFnJs(Expression e) {
    if (e is FunctionExpression) {
      final params = _closureParamNames(e);
      final base = _eventScope();
      final scope = params.isEmpty ? base : base.withParams(params);
      final pjs = params.join(', ');
      final body = e.body;
      if (body is ExpressionFunctionBody) {
        // 表达式体在 Dart 里就是事件调用本身：箭头体直接返回，保留返回值
        // （可等待事件 EasyRefresh.onRefresh 靠它拿到 JS 侧 Promise）。
        try {
          return '($pjs) => ${eventExpr(e, scope)}';
        } catch (_) {
          // 非调用形态（赋值 / 自增等）退回语句翻译。
          final stmt = closureBodyStmtJs(body.expression, scope, const {});
          if (stmt == null) rethrow;
          return '($pjs) => { $stmt }';
        }
      }
      if (body is BlockFunctionBody) {
        final stmts = translateStmtList(
          body.block.statements,
          scope,
          const {},
          null,
        );
        if (stmts.trim().isEmpty) {
          throw const FormatException('事件闭包块体为空');
        }
        return '($pjs) => { ${stmts.trim()} }';
      }
      throw const FormatException('不支持的事件闭包体');
    }
    // 方法 / 字段 / widget 成员引用（`onTap: _tap` / `onTap: widget.onTap` /
    // `onTap: onTap`）：触发时把实参原样转发（多参事件 onChanged / onReorder）。
    final ref = _eventRef(e);
    if (ref != null) return '(...__a) => $ref(...__a)';
    // 其余表达式形态：整体求值，无参。
    return '(...__a) => (${eventExpr(e)})';
  }

  /// 事件表达式里的闭包形参名（`(v) => ...` 的 `v`）。
  List<String> _closureParamNames(FunctionExpression fn) {
    final out = <String>[];
    for (final p in fn.parameters?.parameters ?? const <FormalParameter>[]) {
      final name = p is DefaultFormalParameter
          ? p.parameter.name?.lexeme
          : p.name?.lexeme;
      if (name != null && name.isNotEmpty) out.add(name);
    }
    return out;
  }

  /// 「可调用引用」形态（`onTap: _tap` / `widget.onTap` / 字段回调 `onTap`）
  /// → JS 成员引用 `this.<name>`；非引用形态返回 null。
  String? _eventRef(Expression e) {
    final String name;
    if (e is SimpleIdentifier) {
      name = e.name;
    } else {
      final wm = widgetMemberName(e);
      if (wm == null) return null;
      name = wm;
    }
    final prop = propByField[name];
    if (prop != null) return 'this.$prop';
    if (methodNames.contains(name)) return 'this.$name';
    final event = actionByMethod[name];
    if (event != null) return 'this.$event';
    return null;
  }

  /// 事件表达式引用的**构建期局部名**（循环变量 / build 局部 / 方法形参 /
  /// 方法体局部）——运行时按这些值区分句柄：
  ///
  ///   - 同一位点每次重建捕获到同一组值 → key 不变 → 句柄 id 不变（props 稳定）；
  ///   - 循环里捕获到不同值 → key 不同 → 各自独立句柄（回调不互相覆盖）。
  ///
  /// 能折算成字段引用 / 方法 / getter / 顶层常量 / 宿主方法的名字（`this.*`
  /// 或全局）不算捕获；`context` / `widget` 由 [_eventScope] 改写成 `this.*`。
  /// 事件闭包自己的形参（`(v) => ...` 的 `v`）也不捕获——它们在闭包内部遮蔽。
  List<String> _eventCaptures(Expression e) {
    final used = <String>{};
    e.accept(_SimpleIdentifierCollector(used));
    final closureParams = e is FunctionExpression
        ? _closureParamNames(e).toSet()
        : const <String>{};
    final out = <String>[];
    for (final name in used) {
      if (name == 'context' || name == 'this' || name == 'widget') continue;
      if (closureParams.contains(name)) continue;
      if (_localAliases.containsKey(name) ||
          propByField.containsKey(name) ||
          methodNames.contains(name) ||
          getterNames.contains(name) ||
          globalConsts.contains(name) ||
          hostMethods.containsKey(name)) {
        continue;
      }
      if (_locals.contains(name) ||
          _loopVars.contains(name) ||
          _methodParams.contains(name) ||
          _methodBodyLocals.contains(name)) {
        out.add(name);
      }
    }
    return out;
  }

  /// `setState(() {...})` / `setState(() => _x = v)` → `this.setState(() => {...})`。
  ///
  /// 闭包体走统一的语句/表达式翻译（状态字段 → `this.<field>`，与普通方法体
  /// 同一套作用域），翻译失败即抛错，由 [eventHandle] 统一降级为空操作。
  String _setStateCallJs(MethodInvocation call, FieldScope scope) {
    final args = call.argumentList.arguments;
    final fn = args.isNotEmpty ? args.first : null;
    if (fn is! FunctionExpression) {
      throw const FormatException('setState 需要函数实参');
    }
    final body = fn.body;
    String bodyJs;
    if (body is ExpressionFunctionBody) {
      // 箭头体通常是「赋值 / 自增 / 方法调用」语句（`() => _tab = t`）——走语句级
      // 翻译（赋值/自增由 [exprStmtToJs] 处理，纯表达式回退到 [exprToJs]）。
      final stmt = exprStmtToJs(body.expression, scope, const {});
      if (stmt != null) {
        bodyJs = '  $stmt';
      } else {
        final v = exprToJs(body.expression, scope, const {});
        if (v == null) {
          throw FormatException(
            'setState 闭包体无法翻译：${body.expression.toSource()}',
          );
        }
        bodyJs = '  $v;';
      }
    } else if (body is BlockFunctionBody) {
      bodyJs = translateStmtList(
        body.block.statements,
        scope,
        const {},
        null,
        depth: 1,
        returnsWidget: false,
      );
    } else {
      throw const FormatException('不支持的 setState 闭包体');
    }
    return 'this.setState(() => {\n$bodyJs\n})';
  }

  /// 事件参数列表翻译：逐参数走 [jsDataExpr]（字符串/字段/局部变量/字面量）。
  ///
  /// 作用域用 [_eventScope]（或调方传入的事件闭包作用域）：实参里的 `context`
  /// 照常翻译成 `this.context`（运行时按**执行位置**解析到对应代理），形参与
  /// 调用点一一对应，不做剔除。
  String _eventArgsJs(ArgumentList args, FieldScope scope) {
    final out = <String>[];
    for (final a in args.arguments) {
      if (a is NamedExpression) {
        out.add(jsDataExpr(a.expression, scope));
      } else {
        out.add(jsDataExpr(a, scope));
      }
    }
    return out.join(', ');
  }

  /// 事件表达式里的 @HostInjected 调用 → `_app_host_.invoke(通道, 载荷)`。
  ///
  /// [target] 是 @HostInjected 类名（`AppRouter`）或 null（顶层宿主函数）；
  /// 通道表 [hostMethods] 与方法体翻译共用同一份数据，未命中返回 null。
  /// 位置 / 具名实参分开传，宿主侧用 `Function.apply` 还原 Dart 调用语义。
  String? _hostEventJs(
    Expression? target,
    String method,
    ArgumentList args,
    FieldScope scope,
  ) {
    final String? channel;
    if (target is Identifier) {
      channel = hostMethods[target.name]?[method];
    } else if (target == null) {
      channel = hostMethods['']?[method];
    } else {
      channel = null;
    }
    if (channel == null) return null;
    final pos = <String>[];
    final named = <String>[];
    for (final a in args.arguments) {
      // 形参与调用点一一对应，不做任何剔除（`context` → `this.context`，
      // 见 [_eventScope]：事件闭包里按执行位置解析）。
      if (a is NamedExpression) {
        named.add(
          '${jsString(a.name.label.name)}: '
          '${jsDataExpr(a.expression, scope)}',
        );
      } else {
        pos.add(jsDataExpr(a, scope));
      }
    }
    return '_app_host_.invoke(${jsString(channel)}, ${hostArgsJs(pos, named)})';
  }

  /// BorderRadius.all(Radius.circular(n)) / BorderRadius.circular(n) → 数字字符串。
  String? borderRadiusExpr(Expression e) {
    final (ctor, args) = ctorOf(e);
    if (ctor != 'all' && ctor != 'circular') return null;
    for (final a in args) {
      final n = _radiusNum(a);
      if (n != null) return n;
    }
    return null;
  }

  String? _radiusNum(Expression e) {
    final direct = numLiteralJs(e);
    if (direct != null) return direct;
    final (ctor, args) = ctorOf(e);
    if (ctor != 'circular') return null;
    for (final a in args) {
      final n = numLiteralJs(a);
      if (n != null) return n;
    }
    return null;
  }

  /// 状态字段引用或字面量 → JS 表达式
  /// （Switch value / Slider value 等「绑定状态或常量」的场景）。
  /// 与数据表达式共用同一套翻译（一个地方支持新语法，处处生效）。
  String propExpr(Expression e) => jsDataExpr(e);

  /// 数据表达式 → JS 表达式。
  ///
  /// 委托给**唯一**的表达式翻译器 [rhsToJs]（组件数据表达式与模型方法体、
  /// 语句翻译共用同一套语法支持——新增语法只改那一处），只是把作用域换成
  /// 组件侧：状态字段（[propByField]）+ 循环变量 + build 局部变量 + 组件方法。
  /// 无法翻译即抛错（组件数据绑定不允许静默丢表达式）。
  ///
  /// [scope] 可覆盖默认的组件数据作用域：事件路径传 [_eventScope]，把 `context`
  /// 落到 `this.context`（事件串在运行时隔离求值，看不见 build 形参，裸 `context`
  /// 必然 ReferenceError）。运行时 `this.context` 按**执行位置**解析——被委托的
  /// builder 方法里取的是**被委托组件**的代理，与 Dart 闭包捕获 `context` 形参同语义。
  String jsDataExpr(Expression e, [FieldScope? scope]) {
    final js = rhsToJs(e, scope ?? _dataScope(), const {});
    if (js == null) {
      throw FormatException('文本内容只支持字符串/插值/状态字段/模型属性/三目，不支持 ${e.toSource()}');
    }
    return js;
  }

  /// 组件侧数据作用域（文本插值 / 数据表达式 / 事件参数 / 闭包共用一份）：
  /// 状态字段 + 循环变量 + build 局部变量 + 方法形参 + 本类方法 + 顶层常量 +
  /// 宿主注入方法表 + 局部别名。
  ///
  /// 有别名（`final list = _list;` → `list → this._list`）的局部从形参表剔除：
  /// [FieldScope.fieldRef] 先查形参，若不剔除就会把 `list` 原样透传成未定义的
  /// 自由变量（懒加载 builder 抽成实例方法后尤其致命）。
  FieldScope _dataScope() => FieldScope(
    propByField: propByField,
    params: {
      ..._loopVars,
      ..._methodParams,
      for (final l in _locals)
        if (!_localAliases.containsKey(l)) l,
    },
    methods: {...actionByMethod.keys, ...methodNames},
    hostMethods: hostMethods,
    globalConsts: globalConsts,
    localAliases: _localAliases,
  );

  /// 事件表达式作用域：在 [_dataScope] 基础上把 `context` 从形参表**剔除**、
  /// 改挂别名 `context → this.context`。
  ///
  /// 缘由：事件闭包由运行时在点击时调用，Dart 的 build 形参 `context` 不是
  /// 闭包形参；运行时 `this.context` 按**绑定时的执行位置**解析（见【10.7】与
  /// `augment` 的 context getter）：被委托的 builder 方法里取的是**被委托组件**
  /// 的代理（位于 provider 子树之内），与 Dart 闭包捕获 `context` 形参同语义；
  /// 组件自身作用域里则是 build 传参的同一代理。故改走 `this.context` 即可保持
  /// 「调用面与 Dart 一致」。
  /// [FieldScope.fieldRef] 的顺序是形参优先，因此这里必须同时把 `context`
  /// 移出 `params`，别名才会生效（否则渲染期翻译出的 `context.watch` 会占位）。
  FieldScope _eventScope() {
    final base = _dataScope();
    return FieldScope(
      propByField: base.propByField,
      instanceFields: base.instanceFields,
      params: {...base.params}..remove('context'),
      methods: base.methods,
      hostMethods: base.hostMethods,
      globalConsts: base.globalConsts,
      localVars: base.localVars,
      localAliases: {...base.localAliases, 'context': 'this.context'},
    );
  }

  /// 组件参数位置上的「函数值」翻译：返回 null = 不是函数形态。
  ///
  ///   - 闭包字面量（`onTap: () => ...` / `onPick: (k, v) => ...`）→ JS 箭头函数；
  ///   - 方法 tear-off（`onReset: _resetFilter` / `onReset: widget._resetFilter`）→
  ///     绑定宿主实例的箭头闭包（直接传 `this._resetFilter` 会在子组件调用时丢 this）；
  ///   - 字段型回调透传（`onTap: onTap` / `onReset: widget.onReset`）→ 原样函数值。
  String? functionJs(Expression e) {
    if (e is FunctionExpression) {
      return closureToJs(e, _dataScope(), const {});
    }
    if (e is Identifier) {
      // `widget.<name>`：State 里转发 widget 自身成员，合并类里就是实例成员；
      // 非 `widget.` 前缀的 `a.b` 不支持（返回 null，交给数据表达式分支）。
      final name = e is PrefixedIdentifier ? widgetMemberName(e) : e.name;
      if (name == null) return null;
      // getter（`list: _visiblePosts`）：JS 侧是 `get` 访问器，按值读即可；
      // 包装成调用会传出去一个函数，子组件拿到空数据。
      if (getterNames.contains(name)) return 'this.$name';
      if (actionByMethod.containsKey(name) || methodNames.contains(name)) {
        return '(...__a) => this.$name(...__a)';
      }
      final prop = propByField[name];
      if (prop != null) return 'this.$prop';
    }
    return null;
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

  /// 把 toJson 产物的值序列化为 JS 源码（构造调用树）。
  ///
  /// 值约定：toJson 输出的叶子值一律为 **JS 表达式字符串**（字符串字面量
  /// 用 [jsString] 带引号、数字/布尔/表达式原样），这里原样嵌入、不加引号。
  ///
  /// 容器：Map 含 `type` 键 → 视作**节点**，递归 [renderJs] 产出构造调用
  /// （如 `Text(...)`）——props 里嵌套的节点（如 ListTile.leading）据此还原；
  /// 普通 Map/List → 递归容器。
  String jsLiteral(Object? value, int depth) {
    if (value is Map) {
      if (_isNodeMap(value)) {
        return renderJs(Map<String, dynamic>.from(value), depth);
      }
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
    var s = value?.toString() ?? 'null';
    if (s.contains('\n')) {
      // 多行 JS 表达式（if/for spread、IIFE）：压缩为单行，保持树缩进整洁
      s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    }
    return s;
  }

  /// 判断一个 Map 是「widget 节点」还是「普通 props / args 容器」。
  ///
  /// 不能用「含 `type` 键」当判据：组件构造里 `Foo(type: _type)` 这类实参名就叫
  /// `type`，会把整个 props Map 误判成节点（读出的 `type` 是 JS 表达式而非类型名，
  /// 查表落空后整条结点降级）。节点 Map 由 translator 产出，特征明确：
  ///   - 键只有 `type` / `props` / `key`（`key` 是元素级 Key，由
  ///     [WidgetTranslateContext._applyKeyProp] 注入，渲染时并入 props）；
  ///   - `type` 的值是 [jsString] 产出的**带引号字符串字面量**（类型名），
  ///     而不是 `this._type` 这类运行时表达式。
  static bool _isNodeMap(Map value) {
    final t = value['type'];
    if (t is! String || !t.startsWith('"')) return false;
    return value.keys.every(
      (k) => k == 'type' || k == 'props' || k == 'key',
    );
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
    return WidgetNode(
      ctor,
      args,
      factory: e is MethodInvocation ? e.methodName.name : null,
      expr: e,
    );
  }
}

// ---------------------------------------------------------------------------
// 「放大器缺陷」兜底：单个叶子/结点翻译失败时的降级
//
// 原行为：build() 树里**任意一个叶子表达式**抛 FormatException 会一路冒泡，
// 最终让 `_widgetExprToJs` 返回 null，整棵 `return Column(...)` 被丢弃 → 页面
// 退化成空 build。现在把兜底放在每一次 [WidgetTranslateContext.translate] /
// [translateElement] / [renderJs] 递归调用上：坏叶子只丢自己（降级为占位结点），
// 兄弟结点与上层结点照常产出，同时打印构建期告警（不静默）。
// ---------------------------------------------------------------------------

/// 无法翻译的结点占位（中立描述层）：空的 `SizedBox`，渲染成
/// `__h('SizedBox', {})`，运行时零尺寸、不产生可见内容。
Map<String, dynamic> _placeholderNodeJson() => {'type': '"SizedBox"'};

/// 无法渲染的结点占位（JS 源码层）：与 [_placeholderNodeJson] 同义。
String _placeholderJs() => "__h('SizedBox', {})";

/// 构建期降级告警：出声（不静默丢代码），但不再抛错连累兄弟结点。
void _warnDegrade(String what, String source, Object err) {
  // ignore: avoid_print - 构建期日志
  print(
    '[hot_patch_generator] $what 无法翻译，已降级为占位结点：'
    '$source（$err）',
  );
}

/// 跨文件「静态单例类」解析器（如 theme/panel_colors.dart 的 MyColors）。
///
/// 组件 build 树里出现 `MyColors.background` 这类静态引用时，把它翻译成
/// JS 表达式 `MyColors.background`（不带引号，jsLiteral 原样输出），并登记
/// 该单例类为 import 依赖，产物顶部生成 `import { MyColors } from '...'`。
///
/// 由生成器从组件文件的 import 源文件解析填充；未命中映射时 staticRef
/// 返回 null，调用方维持「丢键」现状，不影响其它产物。
class SingletonResolver {
  /// 类名 → 该类非私有 static 字段名集合。
  final Map<String, Set<String>> _fields = {};

  /// 类名 → 源文件 dart 路径（lib/...dart，用于推导 import 相对路径）。
  final Map<String, String> _sourceFile = {};

  /// 翻译过程中实际被引用的单例类（→ 产物 import）。
  final Set<String> used = {};

  void add(
    String className,
    Set<String> publicStaticFields,
    String sourceFile,
  ) {
    _fields[className] = publicStaticFields;
    _sourceFile[className] = sourceFile;
  }

  String? sourceFileOf(String className) => _sourceFile[className];

  bool hasField(String className, String field) =>
      _fields[className]?.contains(field) ?? false;

  /// 命中静态单例字段引用（`MyColors.background`）→ 登记依赖并
  /// 返回 JS 表达式 `MyColors.background`；否则返回 null。
  String? staticRef(Expression e) {
    String? cls;
    String? field;
    if (e is PropertyAccess && e.target is Identifier) {
      cls = (e.target as Identifier).name;
      field = e.propertyName.name;
    } else if (e is PrefixedIdentifier) {
      // `MyColors.background`（两段点号名，前缀是简单标识符）→ 前缀是类名
      cls = e.prefix.name;
      field = e.identifier.name;
    }
    if (cls != null && field != null && hasField(cls, field)) {
      used.add(cls);
      return '$cls.$field';
    }
    return null;
  }
}

/// 收集表达式里出现的简单标识符名——[WidgetTranslateContext.warnCapturedLocals]
/// 的构建期抽查用。
///
/// 成员名（`a.b` 里的 `b`）也会被收进来，误报面由「名字必须是**本类**的方法体
/// 局部变量 / 循环变量」这条过滤限制住，故不做 AST 位置细分。
class _SimpleIdentifierCollector extends RecursiveAstVisitor<void> {
  _SimpleIdentifierCollector(this.names);

  final Set<String> names;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) => names.add(node.name);
}
