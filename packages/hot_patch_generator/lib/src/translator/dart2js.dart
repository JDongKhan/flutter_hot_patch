import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'js_translator.dart';

// ===========================================================================
// 统一「Dart 类 → JS 类」转换处理器
//
// 不按用途分流：任何普通 Dart 类（value object 如 User、ChangeNotifier 状态
// 对象如 MyModel、静态单例如 MyColors）都按同一套「如何声明 +
// 如何被 State 字段 / 构建 / 方法引用」处理。
//
//   - 实例字段    → constructor 里 this.x（this.x 形参取值 / 字段初始化器）
//   - static 字段 → JS 属性（纯 static 类渲染成 const 对象）
//   - 实例方法    → class 方法；getter → get 访问器
//   - extends ChangeNotifier → extends ChangeNotifier（运行时注入同名 JS 基类）
//
// 表达式/语句翻译统一以 [FieldScope] 为键：组件动作（字段=State 属性表）与
// 模型方法（字段=模型自身实例字段）走同一套 translator。
// ===========================================================================

// ===========================================================================
// 建模层：Dart 类 → ClassInfo（含依赖发现）
//
// 组件（@PatchEntry widget）与普通类（模型 / 状态类 / 静态单例）都是 Dart 类，
// 走**同一处**建模：字段、方法、构造参数，以及**依赖发现**（本类引用到的其它
// 类名）都在这里求出来挂在 ClassInfo.dependencies 上。builder 不再关心「依赖
// 怎么算」，只按名字递归翻译 / 决定同文件内联还是跨文件 import。
// ===========================================================================

/// 提取 ClassDeclaration → ClassInfo（结构建模**唯一入口**）。
///
/// 类表（buildClassTable）与翻译入口（translateClass）都从这里取结构，
/// 差异只靠参数显式化，不再有第二套「构造参数 / 字段 / 方法」行走：
///
///   - 构造：收集 this.x 形参名（DefaultFormalParameter 解包），带默认值的
///     一并记入 [ClassInfo.ctorDefaults]（JS 实例属性的兜底初值）。
///   - 字段：类型经 [fieldTypeName] 推断（无类型注解时从初始化器构造名推回），
///     **未过滤、按声明序**（模型构造的位置参数映射依赖此，见
///     modelCtorFromPartsJs）；可翻译性过滤与初值预渲染是翻译期的增强。
///   - 方法：getter 保留（渲染为 get 访问器），setter 跳过；static 方法
///     默认不翻译（Dart static 无 JS 等价物），[includePrivateStaticMethods]
///     为 true 时**私有 static 按实例方法收**（`_PostCard._likeText(n)` 这类
///     同文件私有工具：JS 侧就是原型方法，类内裸调用 `_likeText(x)` 落成
///     `this._likeText(x)`）。
///
/// [dependencies]：本类引用到的其它类名（由 [referencedClassNames] 与类表求交）。
/// [isComponent]：该类是 widget/组件类（@PatchEntry 或 Stateful/Stateless/
/// State 子类）——类表据此把它与普通模型类区分开（组件不作为模型内联、组件
/// 类型字段不当模型构造翻译）。
///
/// [mixins]：类 `with` 子句解析出的 mixin 声明（见 resolveMixinDecls，按书写
/// 顺序，前者优先级低）。按 Dart 线性化规则合并进字段/方法：
/// **类自身 > 后写的 mixin > 前写的 mixin**——同名字段/方法高优先级占原名，
/// 被覆盖的 mixin 方法改名 `_m$<Mixin>$<name>` 保留，并给每个方法挂
/// [ClassMethod.superMap]（`super.foo()` → 链上下一个实现的 JS 名），语句翻译
/// 据此把 super 语句落成 mixin 方法调用，链尾（基类）无 JS 等价物照旧忽略。
ClassInfo classInfoOf(
  ClassDeclaration decl,
  String sourceFile, {
  Set<String> dependencies = const {},
  bool isComponent = false,
  bool includePrivateStaticMethods = false,
  List<MixinDeclaration> mixins = const [],
}) {
  final instanceFields = <ClassField>[];
  final staticFields = <ClassField>[];
  final methods = <ClassMethod>[];
  final ctorParams = <String>{};
  final ctorDefaults = <String, Expression>{};

  // 构造器 this.x 形参（DefaultFormalParameter 解包）；带默认值
  //（`this.banners = kBanners`）的一并记下，供翻译期做字段兜底初值。
  for (final m in decl.members) {
    if (m is ConstructorDeclaration) {
      for (final p in m.parameters.parameters) {
        final inner = p is DefaultFormalParameter ? p.parameter : p;
        if (inner is FieldFormalParameter) {
          ctorParams.add(inner.name.lexeme);
          if (p is DefaultFormalParameter && p.defaultValue != null) {
            ctorDefaults[inner.name.lexeme] = p.defaultValue!;
          }
        }
      }
    }
  }

  // MethodDeclaration → ClassMethod 的同一口径（类自身与 mixin 成员共用）：
  // getter 保留为 get 访问器；setter 跳过；static 默认跳过（参数放开时
  // 私有 static 按实例方法收）。
  ClassMethod? methodOf(
    MethodDeclaration m, {
    String? nameOverride,
    Map<String, String> superMap = const {},
    String? mixinOrigin,
  }) {
    if (m.isGetter) {
      return ClassMethod(
        name: nameOverride ?? m.name.lexeme,
        params: const [],
        isGetter: true,
        body: m.body,
        superMap: superMap,
        mixinOrigin: mixinOrigin,
      );
    }
    if (m.isSetter ||
        (m.isStatic &&
            !(includePrivateStaticMethods &&
                m.name.lexeme.startsWith('_')))) {
      return null;
    }
    return ClassMethod(
      name: nameOverride ?? m.name.lexeme,
      params: jsMethodParams(m),
      isAsync: m.body.isAsynchronous,
      isVoid: isVoidReturn(m),
      returnsWidget: returnsWidgetOf(m),
      body: m.body,
      superMap: superMap,
      mixinOrigin: mixinOrigin,
    );
  }

  for (final m in decl.members) {
    if (m is FieldDeclaration) {
      for (final v in m.fields.variables) {
        final f = ClassField(
          name: v.name.lexeme,
          typeName: fieldTypeName(m, v),
          initializer: v.initializer,
          isStatic: m.isStatic,
        );
        if (m.isStatic) {
          staticFields.add(f);
        } else {
          instanceFields.add(f);
        }
      }
    } else if (m is MethodDeclaration) {
      final cm = methodOf(m);
      if (cm != null) methods.add(cm);
    }
  }

  // --- mixin 线性化合并 -----------------------------------------------------
  // ordered：优先级从高到低（with 书写顺序反转）。先完成全部方法的 JS 命名
  //（高优先级占原名、低优先级改名保留），再据此给每个方法算 superMap。
  if (mixins.isNotEmpty) {
    final ordered = mixins.reversed.toList();
    final taken = <String>{for (final m in methods) m.name};
    final jsNames = <MixinDeclaration, Map<String, String>>{};
    for (final mx in ordered) {
      final table = <String, String>{};
      for (final member in mx.members.whereType<MethodDeclaration>()) {
        if (methodOf(member) == null) continue; // setter/static 口径一致
        final name = member.name.lexeme;
        table[name] = taken.add(name) ? name : '_m\$${mx.name.lexeme}\$$name';
      }
      jsNames[mx] = table;
    }

    // 链上（比某位置更低优先级的全部 mixin）各方法的第一个实现。
    Map<String, String> superMapOf(Iterable<MixinDeclaration> lower) {
      final map = <String, String>{};
      for (final mx in lower) {
        for (final e in jsNames[mx]!.entries) {
          map.putIfAbsent(e.key, () => e.value);
        }
      }
      return map;
    }

    // 类自身方法：super 链 = 全部 mixin（高 → 低取第一个实现）。
    final classSuper = superMapOf(ordered);
    if (classSuper.isNotEmpty) {
      for (var i = 0; i < methods.length; i++) {
        final m = methods[i];
        methods[i] = ClassMethod(
          name: m.name,
          params: m.params,
          isAsync: m.isAsync,
          isGetter: m.isGetter,
          isVoid: m.isVoid,
          returnsWidget: m.returnsWidget,
          body: m.body,
          bodyJs: m.bodyJs,
          nativeChannel: m.nativeChannel,
          nativeMessage: m.nativeMessage,
          superMap: classSuper,
          mixinOrigin: m.mixinOrigin,
        );
      }
    }

    // mixin 实例字段：高优先级先收，同名去重（类自身字段已先入列）。
    final seenFields = {for (final f in instanceFields) f.name};
    for (final mx in ordered) {
      for (final member in mx.members.whereType<FieldDeclaration>()) {
        if (member.isStatic) continue;
        for (final v in member.fields.variables) {
          if (seenFields.add(v.name.lexeme)) {
            instanceFields.add(ClassField(
              name: v.name.lexeme,
              typeName: fieldTypeName(member, v),
              initializer: v.initializer,
              mixinOrigin: mx.name.lexeme,
            ));
          }
        }
      }
    }

    // mixin 方法：super 链 = 比它低优先级的其余 mixin。
    for (var i = 0; i < ordered.length; i++) {
      final mx = ordered[i];
      final superMap = superMapOf(ordered.sublist(i + 1));
      for (final member in mx.members.whereType<MethodDeclaration>()) {
        final cm = methodOf(
          member,
          nameOverride: jsNames[mx]![member.name.lexeme],
          superMap: superMap,
          mixinOrigin: mx.name.lexeme,
        );
        if (cm != null) methods.add(cm);
      }
    }
  }

  String? superType;
  final ext = decl.extendsClause;
  if (ext != null) superType = ext.superclass.toSource();

  return ClassInfo(
    name: decl.name.lexeme,
    sourceFile: sourceFile,
    superType: superType,
    instanceFields: instanceFields,
    staticFields: staticFields,
    methods: methods,
    ctorParams: ctorParams,
    ctorDefaults: ctorDefaults,
    isComponent: isComponent,
    dependencies: dependencies,
  );
}

/// 字段类型：优先显式类型注解；无注解时从初始化器推断
/// （`final _model = MyModel();` 在无 resolution 解析下 type 为 null，
/// 会退化成 dynamic 被当基础类型，需从构造名推回 MyModel）。
String fieldTypeName(FieldDeclaration member, VariableDeclaration variable) {
  final t = member.fields.type?.toSource();
  if (t != null && t.isNotEmpty) return t;
  final init = variable.initializer;
  if (init is InstanceCreationExpression) {
    return init.constructorName.type.name2.lexeme;
  }
  if (init is MethodInvocation &&
      init.target == null &&
      init.typeArguments == null) {
    final n = init.methodName.name;
    if (n.isNotEmpty && n[0] == n[0].toUpperCase()) return n;
  }
  return 'dynamic';
}

/// 一个类引用到的其它类名：**实例字段类型** + **方法体内构造调用** 的并集。
///
/// 依赖发现是「类 → ClassInfo」这一层的产物：组件与普通类共用同一处，builder
/// 只按名字递归翻译依赖组件、并按 ClassInfo.sourceFile 决定同文件内联还是跨
/// 文件 import。基础类型与 widget 构造名由调用方与类表求交后自然丢弃
/// （类表里只有真正的 Dart 类）。
///
/// [mixins]：本类合并的 mixin 声明（见 classInfoOf）——mixin 的字段类型与
/// 方法体构造调用同样是本类的依赖，漏扫会让「只在 mixin 里引用的模型类」
/// 不被连带翻译。
Set<String> referencedClassNames(
  ClassDeclaration decl, {
  List<MixinDeclaration> mixins = const [],
}) {
  final names = <String>{};
  final collector = _CtorNameCollector();
  void scanMembers(List<ClassMember> members) {
    for (final m in members.whereType<MethodDeclaration>()) {
      m.body.accept(collector);
    }
    for (final member in members.whereType<FieldDeclaration>()) {
      if (member.isStatic) continue;
      for (final v in member.fields.variables) {
        final t = eraseType(fieldTypeName(member, v));
        if (!isBasicType(t) && t.isNotEmpty) names.add(t);
      }
    }
  }

  scanMembers(decl.members);
  for (final mx in mixins) {
    scanMembers(mx.members);
  }
  names.addAll(collector.names);
  return names;
}

/// 任意表达式里构造调用的类名集合（顶层常量初始化器用：`const List<Spot> kSpots
/// = [Spot(...)]` 里被构造出来的模型类必须跟着常量一起产出）。与
/// [referencedClassNames] 共用同一个收集器，口径一致。
Set<String> ctorClassNames(Expression? expression) {
  if (expression == null) return const {};
  final collector = _CtorNameCollector();
  expression.accept(collector);
  return collector.names;
}

/// 收集表达式树里全部类型构造调用名（与类发现共用：字段类型 + 构造调用）。
class _CtorNameCollector extends RecursiveAstVisitor<void> {
  final names = <String>{};

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    names.add(node.constructorName.type.name2.lexeme);
    super.visitInstanceCreationExpression(node);
  }

  /// 无 `new`/`const` 的构造调用（parseString 下是 MethodInvocation）：
  /// `MyModel()` / `(_) => MyModel()` 里的模型构造。仅收 UpperCamel 且无
  /// target/泛型的形态（与 [fieldTypeName] 同启发式），widget 构造（Text/Column
  /// 等）也会被收进来，但与类表求交后自然丢弃。
  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target == null && node.typeArguments == null) {
      final n = node.methodName.name;
      if (n.isNotEmpty && n[0] == n[0].toUpperCase()) names.add(n);
    }
    super.visitMethodInvocation(node);
  }
}

/// 类声明 → JS（export 可选）。含 constructor / 方法 / getter / extends 基类，
/// 并数据驱动地追加响应式 builder 子方法（[ClassInfo.builders] 非空）。
///
/// 组件与普通类共用这一条渲染路径——方法体翻译**只有这一处**：所有方法
/// （含 build）都交给 [translateClassMethodBody]，`return Text(...)` 这类返回
/// widget 的表达式统一走 widget 层渲染，不存在「是不是 build」的判断。
/// **没有对外工厂函数**：元素的 type 就是类本身（宿主 widget 则是类型名字符串），
/// 由渲染层统一写成 `__h(type, props, children)`。
///
/// [widgetCtx]：方法体里返回 Widget 的表达式（如 `return Container(...)`）与
/// builder 子方法的渲染上下文。只需满足 [WidgetExprRenderer]（widget2js 的
/// WidgetTranslateContext 实现它），因此本文件不依赖 widget2js。
String renderClassDecl(
  ClassInfo info,
  Map<String, ClassInfo> classes, {
  bool exported = false,
  WidgetExprRenderer? widgetCtx,
}) {
  final b = StringBuffer();
  b.write(exported ? 'export class ' : 'class ');
  b.write(info.name);
  final base = sdkBaseName(info);
  if (base != null) b.write(' extends $base');
  b.write(' {\n');

  // constructor：有无 this.x 构造形参决定形态（组件与普通类同一规则）：
  // 无参 → `constructor()`（JS 侧多传实参无害）；有参 → `constructor(args)`，
  // 构造参数**统一经 `__applyProps(args)` 派生**（构造参数 → 实例字段只有这一处
  // 映射，构造函数首行调用）。
  //
  // 为什么单独成方法：运行时 patch 复用组件实例时（props 变了）**不会重跑构造
  // 函数**，只更新实例的 `this.props`；参数↔字段映射若只写在构造函数里，子组件
  // 就会永远拿着旧 props 派生的字段（表现为「切换排序/筛选后列表内容不更新」）。
  // 运行时在 patch 的复用路径上会再调一次 `__applyProps(el.props)` 同步字段
  // （见 mini_react_js 的 patch）。
  //
  // 参数先于其它字段派生：Dart 里 `this.x` 形参在构造体开头即已可用，状态字段
  // 可能依赖它（如 `_status = widget.initialStatus ?? kOrderStatus.first`）。
  b.write(info.ctorParams.isEmpty ? '  constructor() {\n' : '  constructor(args) {\n');
  if (base != null) b.write('    super();\n');
  if (info.ctorParams.isNotEmpty) b.write('    this.__applyProps(args);\n');
  // mixin 来源的字段集中尾部、按来源注释分隔（类自身字段在前，注释只标
  // mixin 段），定位问题时一眼分清「类自己的状态 / 混入的状态」。
  String? lastFieldOrigin;
  for (final f in info.instanceFields) {
    if (info.ctorParams.contains(f.name)) continue;
    if (f.mixinOrigin != lastFieldOrigin) {
      if (f.mixinOrigin != null) {
        b.write('    // ---- mixin ${f.mixinOrigin} ----\n');
      }
      lastFieldOrigin = f.mixinOrigin;
    }
    b.write('    this.${f.name} = ${_fieldDefaultJs(f)};\n');
  }
  b.write('  }\n');

  // 构造参数 → 实例字段的唯一映射：构造函数首行调用；实例被 patch 复用
  // （props 变更）时由运行时再调一次 `__applyProps`，保证字段与最新 props 同步。
  if (info.ctorParams.isNotEmpty) {
    b.write('  __applyProps(args) {\n');
    for (final f in info.instanceFields) {
      if (!info.ctorParams.contains(f.name)) continue;
      b.write(
        '    this.${f.name} = (args && args.${f.name} !== undefined) '
        '? args.${f.name} : ${_fieldDefaultJs(f)};\n',
      );
    }
    b.write('  }\n');
  }

  // 方法 + getter：**同一套方法体翻译**（只有这一个入口）。getter 体里有局部
  // 变量 / 集合过滤 / switch 等语句时，必须走完整语句翻译——旧实现只取单条
  // `return <expr>` 再用 exprToJs 翻译，块体 getter（`get _list`）会静默产出
  // `return null`，运行时 `list.length` 直接崩。
  // mixin 来源的方法集中尾部（classInfoOf 合并时已排好序）、按来源注释分隔。
  String? lastMethodOrigin;
  for (final m in info.methods) {
    if (m.mixinOrigin != lastMethodOrigin) {
      if (m.mixinOrigin != null) {
        b.write('  // ---- mixin ${m.mixinOrigin} ----\n');
      }
      lastMethodOrigin = m.mixinOrigin;
    }
    final fn = m.isAsync ? 'async ' : '';
    // 方法体多行可读：语句各自成行、按方法体深度缩进（翻译器已带缩进），
    // 大括号独占行。
    final body = (m.bodyJs ??
            translateClassMethodBody(info, m, classes,
                hostMethods: info.hostMethods,
                widgetCtx: widgetCtx,
                globalConsts: widgetCtx?.globalConsts ?? const {}))
        .trimRight();
    if (m.isGetter) {
      b.write('  get ${m.name}() {\n');
      if (body.isNotEmpty) b.write('$body\n');
      b.write('  }\n');
    } else {
      b.write('  $fn${m.name}(${m.params.join(', ')}) {\n');
      if (body.isNotEmpty) b.write('$body\n');
      b.write('  }\n');
    }
  }

  // 响应式 builder 闭包子方法（ListenableBuilder/Consumer）→ 实例方法
  // `_lbBuilderN()` / `_consumerBuilderN(value)`。运行时时模型 notify 后
  // 重新调用本方法拿到最新子树（含已求值的 this._model.n / value.count），
  // 做「仅此节点」的局部重建。方法名与形参由 translator 在翻译期声明。
  if (info.builders.isNotEmpty && widgetCtx != null) {
    for (var i = 0; i < info.builders.length; i++) {
      final name =
          i < info.builderNames.length ? info.builderNames[i] : '_lbBuilder$i';
      final param = i < info.builderParams.length ? info.builderParams[i] : null;
      final prelude =
          i < info.builderPreludes.length ? info.builderPreludes[i] : '';
      b.write('  $name(${param ?? ''}) {\n');
      if (prelude.isNotEmpty) b.write('      $prelude\n');
      b.write('      return ${widgetCtx.renderJs(info.builders[i], 2)};\n');
      b.write('  }\n');
    }
  }

  b.write('}');
  return b.toString();
}

/// 实例字段的 JS 默认值：翻译期预渲染好的 [ClassField.jsInitial] 优先，
/// 否则由字段初始化器字面量求值，都没有则 `undefined`。
///
/// 构造函数（非构造参数字段）与 `__applyProps`（构造参数字段在实参缺省时）
/// 共用这一处默认值口径，避免两处走样。
String _fieldDefaultJs(ClassField f) =>
    f.jsInitial ??
    (f.initializer != null
        ? (literalToJs(f.initializer) ?? 'undefined')
        : 'undefined');

/// 纯 static 类 → JS const 对象：`const MyColors = { a: v, b: v };`。
/// [valueRenderer] 由调用方提供（颜色/字符串/字面量统一求值）。
String _renderStaticConst(
  ClassInfo info, {
  required String Function(ClassField field) valueRenderer,
  bool exported = false,
}) {
  final prefix = exported ? 'export const ' : 'const ';
  final entries =
      info.staticFields.map((f) => '  ${f.name}: ${valueRenderer(f)}').join(',\n');
  return '$prefix${info.name} = {\n$entries\n};';
}

/// ===========================================================================
/// 统一入口：Dart 类 → JS 源码。
///
/// 只有这一处决定「类 → JS」的渲染：普通类（模型/状态类/静态单例）与组件
/// （@PatchEntry widget，widget 与 state 已在建模期合并为同一 [ClassInfo]）
/// 全部走这里，没有任何按用途分叉的模式开关——所有差异都由 [ClassInfo] 数据
/// 驱动（类名、方法体、builder 子方法、字段的 JS 初值）。
///
/// 因此新增一种「类结构能力」只需改这一处，组件与普通类同时生效。表达式/语句/
/// 字面量语法见 [js_translator]，widget 相关见 [widget2js]。
///
/// 参数：
///   - [exported]：类声明是否 `export`。
///   - [classes]：方法体内构造调用（`new X({...})`）用的类表。
///   - [widgetCtx]：类方法体里 `return Container(...)` 与 builder 子方法的
///     widget 翻译上下文。
///   - [singletonValueRenderer]：纯 static 类的字段值渲染器（颜色/字面量求值）。
///
/// `@HostInjected` 通道表不在参数里：它随 [ClassInfo.hostMethods] 一起由
/// [translateClass] 在翻译期算好挂在模型上（组件与普通类同一份数据）。
/// ===========================================================================
String dart2js(
  ClassInfo info, {
  bool exported = false,
  Map<String, ClassInfo> classes = const {},
  WidgetExprRenderer? widgetCtx,
  String Function(ClassField field)? singletonValueRenderer,
}) {
  if (info.isStaticOnly && singletonValueRenderer != null) {
    return _renderStaticConst(info,
        valueRenderer: singletonValueRenderer, exported: exported);
  }
  return renderClassDecl(info, classes,
      exported: exported,
      widgetCtx: widgetCtx);
}

