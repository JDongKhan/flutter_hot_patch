import 'package:analyzer/dart/ast/ast.dart';
import 'style_translators.dart';

// ===========================================================================
// widget → JSON 翻译的策略扩展点
//
// 设计目标：新增/自定义 widget 时不动 ComponentBuilder 的核心代码。
// 扩展一个 widget 只需要两步：
//   1. 实现 WidgetTranslator（type + toJson）
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
class WidgetTranslateContext {
  final WidgetTranslatorRegistry registry;
  final Map<String, String> propByField;
  final Map<String, String> actionByMethod;
  final String sourcePath;

  /// 组件名 → 依赖产物 jsAsset 路径（null = 无法确定，渲染层走原生注入）。
  /// 由生成器注入：本文件私有/注解组件 → 本文件产物；跨文件组件 →
  /// 从 import directives 推导源文件产物。Component 节点据此产出 import，
  /// 运行时按 import 递归挂载嵌套组件（使用方无需知道依赖）。
  final String? Function(String component)? importResolver;

  /// 跨文件「静态单例类」解析器：build 树里 `MyColors.background`
  /// 这类静态引用翻译成 JS 表达式并登记 import 依赖。
  /// 由生成器从组件文件的 import 源文件解析注入；null = 不启用。
  final SingletonResolver? singletons;

  /// 翻译过程中遇到的未知自定义组件（Component 兜底），供生成器
  /// 收集后把本文件内可解析的私有组件（_Xxx）翻译成嵌套组件注册进产物。
  final Set<String> dependencies = {};

  /// 翻译/渲染过程中**实际用到**的 widget 类型：package → {type}。
  /// [renderJs] 在此登记，生成器据此按 package 产出 JS widget 模块并 import。
  final Map<String, Set<String>> usedWidgetPackages = {};

  /// ListenableBuilder 等「builder 闭包」翻译：闭包返回的子树抽到组件方法
  /// `_lbBuilderN()`，运行时时模型 notify 后重新调用拿到最新子树做局部重建。
  /// 收集顺序即 `_lbBuilder${index}` 命名序号。
  final List<Object?> builderTrees = []; // Map = 节点；String = 三目 JS 表达式

  /// 与 [builderTrees] 同步的方法名（`_lbBuilderN` / `_consumerBuilderN`）。
  final List<String> builderNames = [];

  /// 与 [builderTrees] 同步的形参名（null = 无参；Consumer 为 value）。
  final List<String?> builderParams = [];

  /// 与 [builderTrees] 同步的「方法体前置语句」（JS 源码，如 Builder 闭包
  /// 块体里的 `var model = this.__watch('MyModel');`）。
  final List<String> builderPreludes = [];

  WidgetTranslateContext({
    required this.registry,
    required this.propByField,
    required this.actionByMethod,
    required this.sourcePath,
    this.importResolver,
    this.singletons,
  });

  /// 记录一个被兜底为 Component 节点的自定义组件名。
  void collectDependency(String name) => dependencies.add(name);

  // -------------------------------------------------------------------------
  // 递归入口：表达式 → JSON 描述 / JS 渲染
  // -------------------------------------------------------------------------

  /// 把 build() 里的一个 widget 表达式翻译成中立描述（渲染层据此产出 JS）。
  ///
  /// 返回 Map = 普通节点；返回 String = JS 表达式（widget 位置三目
  /// `cond ? A() : B()` → `(condJs ? [A] : [B])`），渲染层对 String 原样嵌入。
  Object? translate(Expression e) {
    if (e is ConditionalExpression) {
      final cond = jsDataExpr(e.condition);
      final thenJs = _collectionArrayJs(e.thenExpression);
      final elseJs = _collectionArrayJs(e.elseExpression);
      return '($cond ? $thenJs : $elseJs)';
    }
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

  /// children 列表项翻译：Expression → 节点 Map；IfElement / ForElement →
  /// JS spread 表达式字符串（`...(cond ? [a] : [b])` / `...(function(){...})()`），
  /// 渲染层对 String 原样嵌入（内联构造调用 + 条件/循环展开）。
  Object? translateElement(CollectionElement e) {
    if (e is Expression) return translate(e);
    if (e is IfElement) return '...${_ifAsArray(e)}';
    if (e is ForElement) return '...${_forAsArray(e)}';
    throw FormatException('不支持的 collection element: ${e.toSource()}');
  }

  /// if/for 作为「元素数组」出现（数组字面量里嵌套、三目分支等），
  /// 不带 spread 前缀：`(cond ? [a] : [b])`。
  String _ifAsArray(IfElement e) {
    final cond = jsDataExpr(e.expression);
    final thenJs = _collectionArrayJs(e.thenElement);
    final elseJs = e.elseElement == null ? '[]' : _collectionArrayJs(e.elseElement!);
    return '($cond ? $thenJs : $elseJs)';
  }

  /// for 循环 → JS IIFE 展开数组（循环变量 var 提升在 IIFE 内，body 直接引用）。
  String _forAsArray(ForElement e) {
    final parts = e.forLoopParts;
    if (parts is! ForParts) {
      throw FormatException('不支持的 for 循环形式: ${e.toSource()}');
    }
    String head;
    if (parts is ForPartsWithDeclarations) {
      // 传统 for：`for (var i = 0; i < n; i++)` → JS 同构
      final vars = parts.variables.variables.toList();
      // 循环变量先入作用域：condition/updaters/body 里引用 i 都走 loopVars
      for (final v in vars) {
        pushLoopVar(v.name.lexeme);
      }
      final varList = vars.isEmpty
          ? ''
          : 'var ${vars.map((v) => '${v.name.lexeme} = ${v.initializer == null ? '0' : jsDataExpr(v.initializer!)}').join(', ')}';
      final condJs = parts.condition == null ? '' : jsDataExpr(parts.condition!);
      final incJs = parts.updaters.isEmpty
          ? ''
          : parts.updaters.map((u) => jsDataExpr(u)).join(', ');
      head = 'for ($varList; $condJs; $incJs)';
    } else if (parts is ForPartsWithExpression) {
      // 无声明：`for (i = 0; i < n; i++)`（变量需为已收集的状态字段）
      final initJs = parts.initialization == null ? '' : jsDataExpr(parts.initialization!);
      final condJs = parts.condition == null ? '' : jsDataExpr(parts.condition!);
      final incJs = parts.updaters.isEmpty
          ? ''
          : parts.updaters.map((u) => jsDataExpr(u)).join(', ');
      head = 'for ($initJs; $condJs; $incJs)';
    } else {
      throw FormatException('暂不支持该 for 形式（for-in 后续补充）: ${e.toSource()}');
    }
    final bodyJs = _collectionArrayJs(e.body);
    // 清除循环变量作用域（翻译完成后，body 内已引用 i）
    popLoopVars();
    return '(function(){ var out = []; $head { out.push.apply(out, $bodyJs); } return out; })()';
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
    throw FormatException('不支持的 collection element: ${e.toSource()}');
  }

  /// 循环变量作用域：for 循环变量（i 等）在 body 翻译期间遮蔽状态字段查表。
  final Set<String> _loopVars = {};
  void pushLoopVar(String name) => _loopVars.add(name);
  void popLoopVars() => _loopVars.clear();

  /// build() return 前的局部变量（`final isAdult = ...;`）：树里直接引用。
  final Set<String> _locals = {};
  void addLocal(String name) => _locals.add(name);

  /// Builder 闭包局部变量 → 模型类型（`final model = context.watch<T>()`）。
  /// 事件表达式（`() => model.inc()`，局部变量不在回传作用域内）据此翻译成
  /// `this.__read("T").inc()`——两条运行时都在实例上挂了 `__read`，不依赖
  /// 局部作用域即可回传执行。
  final Map<String, String> _localModels = {};
  void addLocalModel(String name, String modelType) => _localModels[name] = modelType;

  static bool _isUpperCamel(String name) =>
      name.isNotEmpty && name[0] == name[0].toUpperCase();

  /// 渲染一个已翻译的中立节点为 JS 构造调用（如 `Text({...}, [...])`）。
  ///
  /// 值契约：toJson 的叶子值一律是 JS 表达式字符串（`"Text"` 这类字符串
  /// 字面量由 [jsString] 产生），因此分发前剥离字符串字面量的引号取语义名。
  String renderJs(Object? json, int depth) {
    if (json is String) return json; // 三目/条件表达式（JS 源码字符串）
    if (json is! Map<String, dynamic>) {
      throw FormatException('无法渲染的节点: $json');
    }
    final type = _semanticType(json['type']);
    final translator = registry.lookupJson(type);
    if (translator == null) {
      // Component 兜底节点（未注册的第三方/自定义 widget）：
      //   - 该组件名有 JS 产物（importResolver 命中）→ 渲染成**工厂调用**
      //     `X({...args})`，与 widget 模块契约一致（运行时递归挂载 JS 组件）；
      //   - 无产物（无注解的 lib 普通 widget / @UIComponentIgnore）→
      //     `__h("Component", {...})` 占位，运行时由宿主 nativeComponents
      //     原生注入或占位。
      if (type == 'Component') {
        final call = _renderComponentCall(json, depth);
        if (call != null) return call;
        // 无 JS 产物（无注解的 lib widget / @UIComponentIgnore）：运行时由宿主
        // nativeComponents 原生注入。仍经 __h 归一成与其它结点同形状的元素，
        // 保证运行时统一按 el.children 挂载（不再有裸字面量特例）。
        final props = json['props'];
        final propsJs = (props is Map && props.isNotEmpty)
            ? jsLiteral(props, depth + 1)
            : '{}';
        return '__h("Component", $propsJs, null)';
      }
      throw FormatException('未知节点类型: $type');
    }
    // 登记「实际用到的 widget」（按 package 分组），
    // 生成器据此只为这些类型产出 JS widget 模块。
    (usedWidgetPackages[translator.packageName] ??= <String>{}).add(type);
    return _renderCall(type, json, depth);
  }

  /// 把已翻译的 JSON 节点渲染成 **JS 构造调用**：
  /// `{type:'Text', props:{...}, children:[...]}` → `Text({...}, [...])`。
  ///
  /// `props` 为空 → `{}`；`children` 为空 → 省略第二参。嵌套子节点（children、
  /// 以及 ListTile.leading 这类「props 里的节点」）同样递归成构造调用。
  /// 函数名即节点 type（由生成器按 package 产出的 widget 模块 export）。
  String _renderCall(String type, Map<String, dynamic> json, int depth) {
    final props = json['props'];
    final children = json['children'];
    final propsJs = (props is Map && props.isNotEmpty)
        ? jsLiteral(props, depth + 1)
        : '{}';
    final b = StringBuffer()
      ..write(type)
      ..write('(')
      ..write(propsJs);
    if (children is List && children.isNotEmpty) {
      b
        ..write(', ')
        ..write(jsLiteral(children, depth + 1));
    }
    b.write(')');
    return b.toString();
  }

  /// Component 节点的「工厂调用」渲染：命中 JS 产物时输出 `X({...args})`
  /// （args 复用 [jsLiteral]，与其它构造调用同一值渲染规则）；
  /// 无产物（importResolver 返回 null）→ 返回 null，调用方回退
  /// `__h("Component", ...)` 占位（运行时走宿主 nativeComponents 原生注入）。
  String? _renderComponentCall(Map<String, dynamic> json, int depth) {
    final props = json['props'];
    if (props is! Map) return null;
    final name = _semanticType(props['component']);
    if (name.isEmpty || importResolver?.call(name) == null) return null;
    final args = props['args'];
    final argsJs = (args is Map && args.isNotEmpty)
        ? jsLiteral(args, depth + 1)
        : '{}';
    return '$name($argsJs)';
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

  /// children 等列表参数：保留全部 collection elements。
  /// 注意返回 [CollectionElement]（Expression / IfElement / ForElement），
  /// 由 [translateElement] 统一翻译（if/for 展开成 JS spread 表达式）。
  List<CollectionElement> listArg(List<Expression> args, String name, String ctor) {
    final e = namedArg(args, name);
    if (e is ListLiteral) return e.elements.toList();
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

  /// 事件参数解析：`onTap: _tap` / `onTap: () => _tap()` → 组件方法名；
  /// 带 receiver 的调用（Builder 闭包局部变量 `model.inc()`、
  /// `context.read<T>().reset()` 链式）→ 翻译为 JS 方法调用表达式
  /// （一比一，不查动作表——方法/属性全量生成，无需标注）。
  String eventExpr(Expression e) {
    if (e is Identifier) return eventOf(e.name);
    if (e is FunctionExpression) {
      final inner = functionInner(e);
      if (inner is MethodInvocation) {
        final target = inner.target;
        // 局部变量 receiver：`model.inc()` → 事件表达式中局部变量已不在
        // 作用域，模型局部（context.watch<T>()）改用 `this.__read('T')`；
        // 其余局部变量原样保留（`model.inc()`，闭包内 var 已声明）。
        if (target is Identifier && _locals.contains(target.name)) {
          final modelType = _localModels[target.name];
          final recv =
              modelType != null ? 'this.__read(${jsString(modelType)})' : target.name;
          return '$recv.${inner.methodName.name}'
              '(${_eventArgsJs(inner.argumentList)})';
        }
        // context.read<T>().reset() 链式：先翻译 receiver（jsDataExpr →
        // this.__read('T')），再拼方法调用。
        if (target is MethodInvocation) {
          final recv = jsDataExpr(target);
          return '$recv.${inner.methodName.name}'
              '(${_eventArgsJs(inner.argumentList)})';
        }
        return eventOf(inner.methodName.name);
      }
    }
    throw FormatException('事件参数需要直接引用方法（如 onTap: _tap 或 () => _tap()）');
  }

  /// 事件「构建期句柄」：把事件表达式包成 `this.__bind("表达式")`。
  ///
  /// 这是事件回传的唯一注入方式：`this` 是 build 作用域的组件实例（也就是
  /// **定义该事件方法/表达式归属的组件**），运行时据此登记句柄并按（实例,
  /// 表达式）缓存——重建产出同一句柄（props 稳定、增量补丁仍生效），宿主
  /// 点击只回传 `{__fn:id}`。相比运行时按裸方法名沿组件链启发式查找，绑定
  /// 信息在构建期就确定，语义与 Dart tear-off 一致，且不依赖运行时树形状。
  String eventHandle(Expression e) => 'this.__bind(${jsString(eventExpr(e))})';

  /// 事件参数列表翻译：逐参数走 [jsDataExpr]（字符串/字段/局部变量/字面量）。
  String _eventArgsJs(ArgumentList args) {
    final out = <String>[];
    for (final a in args.arguments) {
      if (a is NamedExpression) {
        out.add(jsDataExpr(a.expression));
      } else {
        out.add(jsDataExpr(a));
      }
    }
    return out.join(', ');
  }

  /// 颜色表达式（Color(0x..)/Colors.x/静态引用/三目）→ JS 表达式字符串。
  /// 委托给 style_translators 的顶层 [colorExpr]（生成器与样式翻译共用一套逻辑）。
  String? colorExpr(Expression e) => translateColor(e, this);

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
    if (e is IntegerLiteral && e.value != null) return '${e.value}';
    if (e is DoubleLiteral) return '${e.value}';
    final (ctor, args) = ctorOf(e);
    if (ctor == 'circular') {
      for (final a in args) {
        if (a is IntegerLiteral && a.value != null) return '${a.value}';
        if (a is DoubleLiteral) return '${a.value}';
      }
    }
    return null;
  }

  /// 状态字段引用或字面量 → JS 表达式
  /// （Switch value / Slider value 等「绑定状态或常量」的场景）。
  /// 字段一比一：`_lightsOn` → `this._lightsOn`。
  String propExpr(Expression e) {
    if (e is Identifier) return 'this.${propOf(e)}';
    if (e is BooleanLiteral) return e.value ? 'true' : 'false';
    if (e is NullLiteral) return 'null';
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
    if (e is IntegerLiteral && e.value != null) return '${e.value}';
    if (e is DoubleLiteral) return '${e.value}';
    if (e is BooleanLiteral) return e.value ? 'true' : 'false';
    if (e is NullLiteral) return 'null';
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
    // `${_model.n}` / `_model.n` 无 `?.` 时解析为 PrefixedIdentifier
    // （其是 Identifier 的子类，必须先于此判断，避免落入 propOf）。
    if (e is PrefixedIdentifier) {
      // Platform.isAndroid 等 → 运行时注入的 Platform 对象（原样保留）
      if (e.prefix.name == 'Platform') {
        final flag = platformFlagJs(e.identifier.name);
        if (flag != null) return flag;
      }
      return '${jsDataExpr(e.prefix)}.${e.identifier.name}';
    }
    if (e is Identifier) {
      // kDebugMode / kReleaseMode → 运行时注入的全局标志
      final flag = globalFlagJs(e.name);
      if (flag != null) return flag;
      // 循环变量（for 循环体里 i 等）/ build 局部变量（final isAdult = ...）
      // 直接引用，不查状态字段表
      if (_loopVars.contains(e.name)) return e.name;
      if (_locals.contains(e.name)) return e.name;
      return 'this.${propOf(e)}';
    }
    if (e is PropertyAccess && e.target is Identifier &&
        (e.target as Identifier).name == 'Platform') {
      // Platform.isAndroid 等 → 运行时注入的平台标志
      final flag = platformFlagJs(e.propertyName.name);
      if (flag != null) return flag;
    }
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
    if (e is BinaryExpression) {
      final op = e.operator.lexeme;
      // 比较 / 逻辑 / 算术运算符：一比一翻译（条件、循环、三目都用得到）
      if (const <String>{
        '>', '<', '>=', '<=', '==', '!=', '&&', '||', '+', '-', '*', '/', '%'
      }.contains(op)) {
        return '(${jsDataExpr(e.leftOperand)} $op ${jsDataExpr(e.rightOperand)})';
      }
      // Dart 整除 `a ~/ b`：JS 无对应运算符，转 Math.floor(a / b)。
      if (op == '~/') {
        return 'Math.floor(${jsDataExpr(e.leftOperand)} / ${jsDataExpr(e.rightOperand)})';
      }
    }
    if (e is ConditionalExpression) {
      return '(${jsDataExpr(e.condition)} ? ${jsDataExpr(e.thenExpression)} : ${jsDataExpr(e.elseExpression)})';
    }
    // 自增/自减：for 更新子（i++ / ++i / i-- / --i）
    if (e is PostfixExpression) {
      // Dart null 断言（_user!.age）：JS 无此概念，直接忽略（条件短路保护）
      if (e.operator.lexeme == '!') return jsDataExpr(e.operand);
      return '(${jsDataExpr(e.operand)}${e.operator.lexeme})';
    }
    if (e is PrefixExpression) {
      return '(${e.operator.lexeme}${jsDataExpr(e.operand)})';
    }
    if (e is ParenthesizedExpression) return '(${jsDataExpr(e.expression)})';
    // `context.watch<T>()` / `context.read<T>()`（provider 包，数据表达式
    // 位置：局部变量初始化 / Text 插值等）→ 运行时挂载的实例方法
    // __watch（订阅局部刷新）/ __read（仅取）。
    if (e is MethodInvocation) {
      final tgt = e.target;
      if (tgt is Identifier && tgt.name == 'context') {
        final name = e.methodName.name;
        if ((name == 'watch' || name == 'read') &&
            e.argumentList.arguments.isEmpty) {
          final ta = e.typeArguments?.arguments;
          if (ta != null && ta.length == 1 && ta.first is NamedType) {
            final model = (ta.first as NamedType).name2.lexeme;
            final method = name == 'watch' ? '__watch' : '__read';
            return 'this.$method(${jsString(model)})';
          }
        }
      }
      throw FormatException('文本内容不支持方法调用：${e.toSource()}');
    }
    throw FormatException(
        '文本内容只支持字符串/插值/状态字段/模型属性/三目，不支持 ${e.toSource()}');
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
      if (value.containsKey('type')) {
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

/// ===========================================================================
/// 策略抽象类：一个 widget 类型族的「widget → JSON 描述」
///
/// - [types]：处理的源码 widget 构造名（如 {'Text'} 或 {'Column','Row'}）
/// - [jsonTypes]：产物 JSON 里的节点 type 名（默认与 [types] 相同；
///   如 ElevatedButton 的产物节点叫 'Button' 时覆写）
/// - [toJson]：AST 节点 → 中立 JSON 描述（渲染层据此输出 JS 构造调用）
/// ===========================================================================
abstract class WidgetTranslator {
  const WidgetTranslator();

  /// 本 translator 对应的**单一**源码 widget 构造名（如 'Text' / 'Column'）。
  /// 一个 type 一个实现；共用逻辑用继承（基类 + 子类覆写 type）。
  String get type;

  /// 本 translator 产物 JSON 中使用的节点 type 名集合（默认与 [type] 相同；
  /// 如三种按钮产物统一叫 'Button'）。
  Set<String> get jsonTypes => {type};

  /// 该 widget 所属的「包」（决定生成器把 JS widget 模块放到哪个目录）。
  /// 默认 'flutter'（Flutter SDK / material / widgets）；三方包覆写，
  /// 如 provider 包的 ChangeNotifierProvider → 'provider'。
  String get packageName => 'flutter';

  /// 把 [node] 翻译成 JSON 描述（type/props/children）。
  Map<String, dynamic> toJson(WidgetNode node, WidgetTranslateContext ctx);
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
/// Component 节点（{ type: 'Component', props: { component, args? } }）。
/// 有注解的组件由生成器直接产出 JS 工厂调用（自动 import 其产物）；本兜底
/// 节点只承载**无 JS 产物**的组件（无注解的 lib 普通 widget）→ 运行时经
/// nativeComponents 原生注入或占位。
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
    // 只承载无 JS 产物的组件（有注解组件的依赖已在 _renderJs 里用
    // ES module import 表达，运行时按 import 递归挂载）。
    return {
      'type': ctx.jsString('Component'),
      'props': {
        'component': ctx.jsString(node.type),
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

  bool get isEmpty => _fields.isEmpty;

  void add(String className, Set<String> publicStaticFields, String sourceFile) {
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
