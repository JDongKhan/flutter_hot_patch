import 'package:analyzer/dart/ast/ast.dart';

import 'dart2js.dart';
import 'host_injected.dart';
import 'js_translator.dart';
import 'widget2js.dart';

// ===========================================================================
// 统一入口：Dart 类 → ClassInfo（方法体已预渲染为 JS）
//
// 翻译只有这一个入口 [translateClass]，内部唯一的分叉是：
//   - 类是 StatefulWidget（声明了 createState）→ 与同文件 State 类合并
//     （widget 构造参数 + State 字段/方法）；
//   - 其余类（普通模型 / ChangeNotifier / StatelessWidget / …）直接翻译自身。
//
// 分叉之后不再有任何「组件 / 普通类」两套逻辑：字段收集、方法体翻译、
// 依赖发现、widget 树渲染全部同一条路径。类引用到的其它类（普通类或自定义
// 组件）统一挂在 ClassInfo.dependencies 上，builder 只按名字递归翻译 /
// 决定同文件内联还是跨文件 import——「给一个入口，按依赖关系递归翻译」。
// ===========================================================================

/// JS 运行时已有同名类的 Dart 类型（翻译成 JS 同名构造，如
/// `ScrollController` → `new ScrollController()`）：字段不跳过，方法/属性
/// 调用一比一翻译（`addListener` / `jumpTo` / `offset` 由 JS 侧实例提供，
/// 宿主按 id 绑定真实对象）。
const Set<String> _jsRuntimeTypes = {
  'ScrollController',
  'TextEditingController',
  'TabController',
};

/// JS 运行时同名代理类的构造调用 → JS：命名实参一比一透传成对象字面量
/// （`TabController(length: 3, vsync: this)` → `new TabController({length: 3,
/// vsync: this})`），代理类自行取用/忽略（如 TabController 取 length，
/// 忽略 Dart 专属的 vsync）。实参翻译不出来时跳过该条；全空则退化为无参构造。
String _jsRuntimeCtorToJs(
  String type,
  Expression init,
  Map<String, ClassInfo> used,
) {
  // 无 resolution 的 parseString 下 `TabController(...)` 与 `Foo()` 一样被解析成
  // MethodInvocation（类名即无参构造），显式 `new` 才是 InstanceCreationExpression
  // ——两种形态都要认，否则实参整批丢失（只留下 `new TabController()`）。
  final NodeList<Expression> args;
  if (init is InstanceCreationExpression) {
    args = init.argumentList.arguments;
  } else if (init is MethodInvocation && init.target == null) {
    args = init.argumentList.arguments;
  } else {
    return 'new $type()';
  }
  final entries = <String>[];
  for (final a in args) {
    // 代理类的语义面由 JS 侧定义，位置参数不参与（均为具名参数调用）。
    if (a is! NamedExpression) continue;
    final v = rhsToJs(a.expression, FieldScope(), used);
    if (v != null) entries.add('${a.name.label.name}: $v');
  }
  return entries.isEmpty ? 'new $type()' : 'new $type({${entries.join(', ')}})';
}

/// 任意 Dart 类声明 → 已翻译的 [ClassInfo]（方法体 [ClassMethod.bodyJs]
/// 在本次调用中全部预渲染好，依赖 / 用到的 widget 类型也已收集齐）。
///
/// 参数：
///   - [decl]：待翻译类（@UIComponent widget 类或普通类）。
///   - [unit]：所在编译单元（StatefulWidget 合并时在此查找同文件 State 类）。
///   - [classTable]：全量类表（含组件 / 普通类 / 单例），字段类型与方法体
///     构造调用按名字解析；组件条目标记 [ClassInfo.isComponent]。
///   - [importResolver]：自定义组件名 → 依赖产物相对路径（null = 无 JS 产物，
///     运行时原生注入）。
///   - [isComponent]：是否作为组件产物输出（仅影响注释与 superType 处理：
///     State 合并时不把 `State<X>` / `StatefulWidget` 写成 JS 基类）。
///
/// `@HostInjected` 通道表由本入口自行扫描（见 [buildHostMethods]）并挂在产出的
/// [ClassInfo.hostMethods] 上——组件与普通类同一条路径，调用方无需传参。
ClassInfo translateClass(
  ClassDeclaration decl,
  CompilationUnit unit,
  String sourcePath, {
  required WidgetTranslatorRegistry registry,
  required Map<String, ClassInfo> classTable,
  required String? Function(String name) importResolver,
  SingletonResolver? singletons,
  Set<String> jsClassWidgets = const {},
  Set<String> delegateClassWidgets = const {},
  Set<String> globalConsts = const {},
  bool isComponent = false,
}) {
  // @HostInjected 通道表：翻译层自己扫（本文件 + import 源文件）。方法体里
  // `Foo.bar(...)` 命中即整体换成 `__jsui.host("通道", 载荷)`，组件与普通类
  // 共用同一份数据、同一条翻译路径，构建层不参与。
  final hostMethods = buildHostMethods(unit, sourcePath);

  // --- 唯一分叉：StatefulWidget → widget 类与同文件 State 类合并 ------------
  ClassDeclaration widgetClass = decl;
  ClassDeclaration hostClass = decl;
  final stateClassName = _stateClassNameOf(decl);
  if (stateClassName != null) {
    for (final d in unit.declarations) {
      if (d is ClassDeclaration && d.name.lexeme == stateClassName) {
        hostClass = d;
        break;
      }
    }
    if (identical(hostClass, decl)) {
      throw FormatException('找不到 State 类 $stateClassName（需与 widget 同文件）');
    }
  }

  // 构造参数：widget 类（普通类即自身）构造函数的 this.xxx 命名形参——
  // `required this.x` 在无 resolution 下是 DefaultFormalParameter 包裹
  // FieldFormalParameter，需要解包。带默认值（`this.banners = kBanners`）的
  // 一并记下：这就是 JS 实例属性的兜底初值（JS 侧漏传 props 时用它，而不是
  // 类型默认值 `[]`/`''`）。
  final ctorArgs = <String>{};
  final ctorDefaults = <String, Expression>{};
  for (final m in widgetClass.members) {
    if (m is ConstructorDeclaration) {
      for (final param in m.parameters.parameters) {
        final inner = param is DefaultFormalParameter ? param.parameter : param;
        if (inner is FieldFormalParameter) {
          ctorArgs.add(inner.name.lexeme);
          if (param is DefaultFormalParameter && param.defaultValue != null) {
            ctorDefaults[inner.name.lexeme] = param.defaultValue!;
          }
        }
      }
    }
  }

  // 方法收集：getter 保留（渲染为 get 访问器），setter 跳过。私有 static
  // 方法按**实例方法**翻译（`_PostCard._likeText(n)` 这类同文件私有工具）：JS
  // 侧就是原型方法，类内裸调用 `_likeText(x)` 落成 `this._likeText(x)`。
  // 公开 static 方法不翻译（无 JS 等价物，跨文件引用会给不出正确语义）。
  // build 与其它返回 widget 的方法一视同仁，不做「是不是 build」的判断。
  final methods = <MethodDeclaration>[
    for (final m in hostClass.members)
      if (m is MethodDeclaration &&
          !m.isSetter &&
          (!m.isStatic || m.name.lexeme.startsWith('_')))
        m,
  ];

  // 依赖发现：字段类型 + 方法体构造调用（referencedClassNames）∩ 全量类表。
  // 类表同时包含组件与普通类——普通类方法体里构造自定义组件（如
  // CounterVm.buildText() → BannerCard()）与组件 build 里构造模型走同一套。
  // 已注册 WidgetTranslator 的类型（宿主 widget / 受控 JS 类）由 translator
  // 接管，不能再当模型类。
  final used = <String, ClassInfo>{};
  for (final name in referencedClassNames(hostClass)) {
    final info = classTable[name];
    if (info == null) continue;
    if (registry.registeredTypes.contains(name)) continue;
    used[name] = info;
  }

  // 字段收集：基础类型 / JS 运行时类型 / 普通类类型字段进 JS 实例属性；
  // 组件类型与无 JS 等价物的对象类型字段跳过并告警（与组件/普通类无关，
  // 同一套规则）。
  final propByField = <String, String>{};
  final instanceFields = <ClassField>[];
  // 字段来源：StatefulWidget 场景下 **widget 类**的字段（构造参数，如
  // `OrdersPage.initialStatus`）与 State 类字段合并——运行时 `new Type(props)`
  // 把 widget 属性作为 args 传入，二者在 JS 侧就是同一个类的实例属性；State 内
  // 的 `widget.x` 因此能解析成 `this.x`（见 js_translator 的 widget 分支）。
  final fieldDecls = <(FieldDeclaration, VariableDeclaration)>[];
  final seenField = <String>{};
  for (final cls in [if (stateClassName != null) widgetClass, hostClass]) {
    for (final member in cls.members) {
      if (member is! FieldDeclaration || member.isStatic) continue;
      for (final variable in member.fields.variables) {
        if (seenField.add(variable.name.lexeme)) {
          fieldDecls.add((member, variable));
        }
      }
    }
  }
  // 字段名全集：字段初始化器可能引用其它字段（`widget.x` → `this.x`），
  // 解析初值的作用域需先知道全部字段名（propByField 在下循环里才逐步填充）。
  final fieldNames = {for (final (_, v) in fieldDecls) v.name.lexeme};
  for (final (member, variable) in fieldDecls) {
    {
      final fieldName = variable.name.lexeme;
      final typeName = fieldTypeName(member, variable);
      final erased = eraseType(typeName);
      final isBasic = isBasicType(typeName) || _valueSdkTypes.contains(erased);
      final jsRuntime = _jsRuntimeTypes.contains(erased);
      if (!_fieldTranslatable(typeName, classTable, registry.registeredTypes)) {
        // 对象类型字段（Controller/Widget/Key 等）没有 JS 等价物，自动跳过。
        // ignore: avoid_print - 构建期日志
        print(
          '[ui_component_generator] 跳过字段 $fieldName（类型 $typeName 不可翻译）',
        );
        continue;
      }
      final init = variable.initializer;
      // 初值来源：字段初始化器，否则构造形参默认值（`this.x = <默认值>`）。
      // 两者都走同一条通用表达式翻译（顶层常量 / 集合字面量 / 模型构造都支持）。
      final defaultExpr = ctorDefaults[fieldName];
      final initScope = FieldScope(
        instanceFields: fieldNames,
        globalConsts: globalConsts,
      );
      final String initial;
      if (isBasic) {
        // 初始化器优先（如 `late String _status = widget.x ?? kOrderStatus.first`
        // → `(this.initialStatus ?? kOrderStatus[0])`）；不是编译期常量时再依次
        // 回退到构造形参默认值、类型默认值（String→''、bool→false、数字→0）。
        initial = literalToJs(init) ??
            (init == null ? null : rhsToJs(init, initScope, used)) ??
            (defaultExpr == null
                ? null
                : rhsToJs(defaultExpr, initScope, used)) ??
            _defaultInitial(typeName);
      } else if (jsRuntime) {
        // JS 运行时同名代理类（ScrollController / TextEditingController /
        // TabController）：构造按命名实参透传（代理类自行取用，如 TabController
        // 的 length/initialIndex）。
        initial = init == null ? 'null' : _jsRuntimeCtorToJs(erased, init, used);
      } else {
        String? ctorJs;
        if (init is InstanceCreationExpression) {
          ctorJs = modelCtorToJs(init, initScope, used);
        } else if (init is MethodInvocation &&
            init.target == null &&
            init.typeArguments == null) {
          // `_model = MyModel()` 在无 resolution 的 parseString 下会被解析成
          // MethodInvocation（类名即无参构造），统一按模型构造处理。
          ctorJs = modelCtorFromPartsJs(init.methodName.name,
              init.argumentList.arguments.toList(), initScope, used);
        } else if (init == null && defaultExpr != null) {
          ctorJs = rhsToJs(defaultExpr, initScope, used);
        }
        // 无初始化器（如 `List<Spot> spots` 由构造参数注入）→ 类型默认值
        // （容器→[]/{}），而不是 null：JS 侧漏传 props 时仍能安全遍历。
        initial = ctorJs ?? (init == null ? _defaultInitial(typeName) : 'null');
      }
      instanceFields.add(ClassField(
        name: fieldName,
        typeName: typeName,
        jsInitial: initial,
      ));
      propByField[fieldName] = fieldName;
    }
  }

  // 翻译上下文：实例字段表（propByField）+ 实例方法名表（actionByMethod）
  // ——widget 层据此解析标识符（`_count` → `this._count`）、区分本类实例
  // 方法与嵌套组件构造、事件绑定（`__bind`）。普通类与组件同一个上下文。
  final parseCtx = WidgetTranslateContext(
    registry: registry,
    propByField: propByField,
    actionByMethod: {
      for (final m in methods)
        if (!m.isGetter) m.name.lexeme: m.name.lexeme,
    },
    // 本类全部实例方法 / getter 名（含非动作方法）：数据表达式里的裸调用
    // （`Text(_likeText(post.like))`）与 setState/事件体里的 this.xxx(...) 都
    // 依赖它解析为本类方法，而不只限于注册为动作的方法。
    methodNames: {for (final m in methods) m.name.lexeme},
    sourcePath: sourcePath,
    importResolver: importResolver,
    singletons: singletons,
    globalConsts: globalConsts,
    hostMethods: hostMethods,
    jsClassWidgets: jsClassWidgets,
    delegateClassWidgets: delegateClassWidgets,
  );

  // 方法声明：getter 只保留 body（渲染期走 get 访问器）；普通方法带上形参 /
  // 返回类型判定；方法体是 SnackBar 形式时识别为 native 通道（nativeToast）。
  ClassMethod buildMethod(MethodDeclaration m, {String? bodyJs}) {
    if (m.isGetter) {
      return ClassMethod(
        name: m.name.lexeme,
        params: const [],
        isGetter: true,
        body: m.body,
      );
    }
    final msg = _snackMessage(m.body, parseCtx);
    return ClassMethod(
      name: m.name.lexeme,
      params: jsMethodParams(m),
      isAsync: m.body.isAsynchronous,
      isVoid: isVoidReturn(m),
      returnsWidget: returnsWidgetOf(m),
      body: m.body,
      bodyJs: bodyJs,
      nativeChannel: msg != null ? 'nativeToast' : null,
      nativeMessage: msg,
    );
  }

  final proto = ClassInfo(
    name: decl.name.lexeme,
    sourceFile: sourcePath,
    // 组件（State 合并）不把 StatefulWidget/State 写成 JS 基类；普通类保留
    // extends（如 ChangeNotifier，运行时注入同名 JS 基类）。
    superType: isComponent ? null : decl.extendsClause?.superclass.toSource(),
    instanceFields: instanceFields,
    staticFields: const [],
    methods: [for (final m in methods) buildMethod(m)],
    ctorParams: {
      for (final f in instanceFields)
        if (ctorArgs.contains(f.name)) f.name,
    },
    isComponent: isComponent,
  );

  // 逐个方法翻译：唯一的方法体翻译器，组件与普通类、build 与其它方法完全
  // 同一条路径。parseCtx 在过程中收集依赖组件 / 用到的 widget 类型 /
  // 响应式 builder 子方法。
  final translated = <ClassMethod>[
    for (final m in methods)
      buildMethod(
        m,
        bodyJs: m.isGetter
            ? null
            : translateClassMethodBody(proto, buildMethod(m), used,
                hostMethods: hostMethods,
                widgetCtx: parseCtx,
                globalConsts: globalConsts),
      ),
  ];

  return ClassInfo(
    name: decl.name.lexeme,
    sourceFile: sourcePath,
    superType: proto.superType,
    instanceFields: instanceFields,
    staticFields: const [],
    methods: translated,
    ctorParams: proto.ctorParams,
    isComponent: isComponent,
    hostMethods: hostMethods,
    builders: parseCtx.builderTrees,
    builderNames: parseCtx.builderNames,
    builderParams: parseCtx.builderParams,
    builderPreludes: parseCtx.builderPreludes,
    // 依赖 = widget 树里的自定义组件（parseCtx 收集）+ 字段类型 / 方法体
    // 构造调用命中的类（含跨文件组件，如 CounterVm → BannerCard）。
    dependencies: {...parseCtx.dependencies, ...used.keys},
    usedWidgetPackages: parseCtx.usedWidgetPackages,
    usedNodeHelper: parseCtx.usedNodeHelper,
  );
}

/// 类 + 同文件 State 类（StatefulWidget 的字段 / 方法 / 依赖分布在两个类里，
/// 翻译与依赖发现都必须合并扫描）。非 StatefulWidget → 只返回自身。
List<ClassDeclaration> classAndStateDecls(
  ClassDeclaration decl,
  CompilationUnit unit,
) {
  final stateName = _stateClassNameOf(decl);
  if (stateName == null) return [decl];
  for (final d in unit.declarations) {
    if (d is ClassDeclaration && d.name.lexeme == stateName) return [decl, d];
  }
  return [decl];
}

/// 取 StatefulWidget 的 State 类名：解析 createState() 返回的构造
/// （`_MyCardState()` 在无 resolution 下可能是 MethodInvocation）。
/// 未声明 createState → null（StatelessWidget / 普通类）。
String? _stateClassNameOf(ClassDeclaration widgetClass) {
  for (final m in widgetClass.members) {
    if (m is MethodDeclaration && m.name.lexeme == 'createState') {
      final e = _methodExpression(m);
      if (e is InstanceCreationExpression) {
        return e.constructorName.type.name2.lexeme;
      }
      if (e is MethodInvocation) {
        return e.methodName.name;
      }
    }
  }
  return null;
}

Expression? _methodExpression(MethodDeclaration m) {
  final body = m.body;
  if (body is ExpressionFunctionBody) return body.expression;
  if (body is BlockFunctionBody) {
    for (final s in body.block.statements) {
      if (s is ReturnStatement) return s.expression;
    }
  }
  return null;
}

/// 基础类型字段的默认初值：无初始化器且非常量初始化表达式时兜底。
/// 泛型容器按外层类型给空集合（`List<Spot>` → `[]`、`Map<K,V>` → `{}`），
/// 保证 JS 侧漏传 props 时遍历/取值不炸；对象类型（模型字段）给 `null`
/// ——给 `0` 会让「漏传」变成更难排查的假数据。
String _defaultInitial(String typeName) {
  // 可空类型（`String?` / `int?` / `List<T>?`）无初始化器时 Dart 语义就是 null，
  // 不能给类型默认值：`''`/`0`/`false` 会让 `x ?? 回退值` 直接取到该默认值而
  // 永不回退（订单页 `widget.initialStatus ?? kOrderStatus.first` 因此把「全部」
  // 筛成空列表）。
  if (typeName.trim().endsWith('?')) return 'null';
  final t = eraseType(typeName);
  if (t == 'String') return "''";
  if (t == 'bool') return 'false';
  if (t == 'List' || t == 'Set' || t == 'Iterable') return '[]';
  if (t == 'Map') return '{}';
  if (isBasicType(t)) return '0'; // int / double / num
  return 'null';
}

/// 泛型容器类型（字段类型里的外层名）。
const Set<String> _containerTypes = {'List', 'Set', 'Iterable', 'Map'};

/// 函数值类型（事件回调字段）：JS 侧函数就是值，原样持有 / 传递即可。
/// `onTap` / `onPick` / `onReset` 这类字段不再被跳过。
const Set<String> _callbackTypes = {
  'Function',
  'VoidCallback',
  'ValueChanged',
  'ValueGetter',
  'ValueSetter',
  'AsyncCallback',
  'GestureTapCallback',
  'GestureLongPressCallback',
  'GestureTapDownCallback',
  'WidgetBuilder',
  'IndexedWidgetBuilder',
};

/// 可承载「元素值」的字段类型：JS 侧元素就是普通对象（`{type, props,
/// children}`），持有 / 转发没有障碍。`child` / `children` / `trailing` /
/// `leading` / `title` 这类 widget 字段因此能进实例属性，`Row(children:
/// children)` 也能拿到真实数组。
const Set<String> _widgetValueTypes = {'Widget', 'PreferredSizeWidget'};

/// 有 JS 值形态的 SDK 类型字段：JS 侧就是字符串（`Color` → `'#aarrggbb'`、
/// `IconData` → 图标名，由运行时映射回真实对象），持有 / 转发都成立。
/// 缺了它，`_OrderCard.statusColor` / `_DevRow.icon` 这类字段会被整条跳过，
/// 传进来也用不上（子组件里 `color: statusColor` 解析失败）。
const Set<String> _valueSdkTypes = {'Color', 'IconData'};

/// 字段类型是否可翻译（进 JS 实例属性）：
///   - 基础类型（int/double/num/String/bool/dynamic）；
///   - JS 运行时同名代理类（ScrollController / TextEditingController / …）；
///   - 已登记**非组件**类（模型，如 `Spot`）；
///   - 函数值类型（VoidCallback / `void Function(...)`）——事件回调字段；
///   - 元素值类型（`Widget` / `List<Widget>` / 已登记 widget 类型）——JS 侧
///     元素是普通对象，可持有 / 转发；
///   - 泛型容器按**类型实参**递归判定：`List<Spot>` / `Map<String, int>` /
///     `List<Widget>` 可翻译，`Key?` 不可翻译。
bool _fieldTranslatable(
  String typeName,
  Map<String, ClassInfo> classTable,
  Set<String> widgetTypes,
) {
  final t = typeName.trim();
  if (t.endsWith('?')) {
    return _fieldTranslatable(t.substring(0, t.length - 1), classTable, widgetTypes);
  }
  if (isBasicType(t)) return true;
  final lt = t.indexOf('<');
  final base = lt >= 0 ? t.substring(0, lt).trim() : t;
  // 函数值：`void Function(String, String)`（`Function(` 形态）与
  // `VoidCallback` / `ValueChanged<int>` 这类 typedef 都放行。
  if (_callbackTypes.contains(base) || t.contains('Function(')) return true;
  if (lt >= 0 && t.endsWith('>')) {
    if (!_containerTypes.contains(base)) return false;
    final args = _typeArgs(t.substring(lt + 1, t.length - 1));
    return args.isNotEmpty &&
        args.every((a) => _fieldTranslatable(a, classTable, widgetTypes));
  }
  if (t.isEmpty) return false;
  if (_jsRuntimeTypes.contains(t)) return true;
  // 有 JS 值形态的 SDK 类型（Color → '#aarrggbb'、IconData → 图标名）。
  if (_valueSdkTypes.contains(t)) return true;
  // 元素值字段（Widget / 已登记 widget 类型 / 自定义组件）：JS 侧元素是普通
  // 对象，持有与转发都成立（`child` / `trailing` / `Row(children: children)`）。
  if (_widgetValueTypes.contains(t) || widgetTypes.contains(t)) return true;
  final cls = classTable[t];
  return cls != null;
}

/// 拆分泛型类型实参（按顶层逗号，忽略嵌套尖括号里的逗号）。
List<String> _typeArgs(String src) {
  final out = <String>[];
  var depth = 0;
  var start = 0;
  for (var i = 0; i < src.length; i++) {
    final c = src[i];
    if (c == '<') depth++;
    if (c == '>') depth--;
    if (c == ',' && depth == 0) {
      out.add(src.substring(start, i));
      start = i + 1;
    }
  }
  out.add(src.substring(start));
  return [for (final s in out) if (s.trim().isNotEmpty) s.trim()];
}

/// 提取 SnackBar 消息字符串：方法体为
/// `showSnackBar(SnackBar(content: Text('...')))` 时返回消息的 JS 字符串
/// 字面量（整体方法改译为 nativeToast 宿主通道）；否则 null。
String? _snackMessage(FunctionBody body, WidgetTranslateContext ctx) {
  Expression? outer;
  if (body is ExpressionFunctionBody) {
    outer = body.expression;
  } else if (body is BlockFunctionBody) {
    for (final s in body.block.statements) {
      if (s is ExpressionStatement) {
        outer = s.expression;
        break;
      }
    }
  }
  if (outer is MethodInvocation && outer.methodName.name == 'showSnackBar') {
    final args = outer.argumentList.arguments;
    if (args.isNotEmpty) {
      final snack = args.first;
      // 无 const 的 Foo(...) 在无 resolution 的 parseString 下是 MethodInvocation，
      // 统一用 ctx.ctorOf 取构造名与参数。
      final (snackCtor, snackArgs) = ctx.ctorOf(snack);
      if (snackCtor == 'SnackBar') {
        final content = ctx.namedArg(snackArgs, 'content');
        if (content != null) {
          final (textCtor, textArgs) = ctx.ctorOf(content);
          if (textCtor == 'Text') {
            final data = ctx.positionalArg(textArgs, 0);
            if (data is StringLiteral) return ctx.jsString(data.stringValue ?? '');
          }
        }
      }
    }
  }
  return null;
}
