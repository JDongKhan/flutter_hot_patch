/// 收集入口：Dart AST → 完整可渲染的 [ClassInfo]。
///
/// 本文件是「先收集、后渲染」的唯一收集层：
///   - classInfoOf：结构建模（字段 / 方法 / 构造参数 / mixin 线性化）；
///   - translateClass：在结构之上完成字段初值、方法体、getter、builder 子树与
///     依赖的预翻译，产出的 ClassInfo 可直接交给 dart2js；
///   - StatefulWidget 与 State 的合并发生在本层（收集期的特殊处理）。
///
/// 翻译只发生一次：渲染层不再遍历 AST，也不接收任何翻译上下文。
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../../shared/js_widget_defs.dart';
import '../class_info.dart';
import '../../shared/host_injected.dart';
import '../translator/js_translator.dart';
import '../translator/js_value.dart';
import '../../shared/source_index.dart';
import '../translator/widget2js.dart';

/// 方法形参 → JS 形参名列表（解 DefaultFormalParameter 包裹）。
///
/// **一一对应**：Dart 是什么形参，JS 就是什么形参（形参名、顺序、个数完全一致），
/// 不做任何类型剔除——`BuildContext` 也有对应物（运行时以最近宿主祖先结点为锚
/// 的代理，由 build 传参）。形参名在作用域内保持裸引用；仅事件等延迟作用域因
/// 看不见形参，才由作用域别名译成 `this.context`（见 WidgetTranslateContext._eventScope）。
/// 组件与普通类共用这一处。
List<String> jsMethodParams(MethodDeclaration m) {
  final out = <String>[];
  for (final p in m.parameters?.parameters ?? const <FormalParameter>[]) {
    final inner = p is DefaultFormalParameter ? p.parameter : p;
    final name = inner.name?.lexeme;
    if (name == null || name.isEmpty) continue;
    out.add(name);
  }
  return out;
}

/// 方法是否 `void`：返回类型为 `void`（箭头体译为语句，不产生 `return`）。
bool isVoidReturn(MethodDeclaration m) {
  final t = m.returnType?.toSource().trim();
  return t == 'void';
}

/// 方法返回值是否为 widget：显式返回类型里出现 `Widget`（`Widget` / `Widget?` /
/// `Future<Widget>` / `XxxWidget`）即视为 widget 方法，`return Text(...)` 走
/// widget 树渲染；返回模型等数据类型的普通方法（`User makeUser()`）按普通表达
/// 式翻译，不会被误判成组件占位节点。无显式返回类型时按 widget 处理（保守）。
bool returnsWidgetOf(MethodDeclaration m) {
  final t = m.returnType?.toSource().trim() ?? '';
  if (t.isEmpty) return true;
  return t.contains('Widget');
}

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

/// 任意表达式里构造调用的类名集合（顶层常量初始化器用：
/// `const List<Spot> kSpots = [...]` 里被构造出来的模型类必须跟着常量一起产出）。
/// 与 [referencedClassNames] 共用同一个收集器，口径一致。
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

// JS 运行时同名代理类（ScrollController / PageController / TextEditingController
// / TabController）的集合与构造翻译统一维护在 js_translator 的
// [jsRuntimeClassNames] / [jsRuntimeCtorJs]，字段初始化与内联构造共用一条路径。

/// 任意 Dart 类声明 → 已翻译的 [ClassInfo]（方法体 [ClassMethod.bodyJs]
/// 在本次调用中全部预渲染好，依赖 / 用到的 widget 类型也已收集齐）。
///
/// 参数：
///   - [decl]：待翻译类（@PatchEntry widget 类或普通类）。
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
  required Map<String, ClassInfo> classTable,
  required String? Function(String name) importResolver,
  SingletonResolver? singletons,
  Set<String> jsClassWidgets = const {},
  Set<String> delegateClassWidgets = const {},
  Set<String> globalConsts = const {},
  bool isComponent = false,
}) {
  // @HostInjected 通道表：翻译层自己扫（本文件 + import 源文件）。方法体里
  // `Foo.bar(...)` 命中即整体换成 `_app_host_.invoke("通道", 载荷)`，组件与普通类
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

  // 结构建模唯一入口 classInfoOf：构造参数（含形参默认值）、实例字段
  //（fieldTypeName 推断、声明序）、方法（getter 保留、setter 跳过、
  // 私有 static 按实例方法收）都来自它，本函数只做翻译增强（可翻译性
  // 过滤 / 初值预渲染 / 方法体翻译 / native 通道识别）。
  // StatefulWidget 场景：widget 类出构造参数与参数字段，State 类出方法与
  // 状态字段。build 与其它返回 widget 的方法一视同仁，不做「是不是 build」的判断。
  //
  // mixin：解析 hostClass（State 类 / 普通类自身）的 with 子句并传入建模，
  // 字段/方法按线性化合并、super 语句落成 mixin 方法调用（见 classInfoOf）。
  final mixins = resolveMixinDecls(hostClass, unit, sourcePath);
  final widgetInfo = classInfoOf(widgetClass, sourcePath,
      includePrivateStaticMethods: true,
      // 普通类（无 State 分离）时 widgetClass 就是 hostClass：mixin 必须挂进
      // widgetInfo，否则 hostInfo 复用 widgetInfo 时 mixin 成员整批丢失。
      mixins: identical(hostClass, widgetClass) ? mixins : const []);
  final hostInfo = identical(hostClass, widgetClass)
      ? widgetInfo
      : classInfoOf(hostClass, sourcePath,
          includePrivateStaticMethods: true, mixins: mixins);
  final ctorArgs = widgetInfo.ctorParams;
  final ctorDefaults = widgetInfo.ctorDefaults;
  final methods = hostInfo.methods;

  // 依赖发现：字段类型 + 方法体构造调用（referencedClassNames）∩ 全量类表。
  // 类表同时包含组件与普通类——普通类方法体里构造自定义组件（如
  // CounterVm.buildText() → BannerCard()）与组件 build 里构造模型走同一套。
  // 内建 widget（宿主渲染 / JS 类）由统一翻译路径接管，不能再当模型类。
  final used = <String, ClassInfo>{};
  for (final name in referencedClassNames(hostClass, mixins: mixins)) {
    final info = classTable[name];
    if (info == null) continue;
    if (builtinWidgetTypes.contains(name)) continue;
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
  // classInfoOf 产出未过滤、声明序的实例字段，这里只合并去重（widget 字段
  // 优先）；可翻译性过滤与初值预渲染在下循环。
  final fieldDecls = <ClassField>[];
  final seenField = <String>{};
  for (final info in [if (stateClassName != null) widgetInfo, hostInfo]) {
    for (final f in info.instanceFields) {
      if (seenField.add(f.name)) fieldDecls.add(f);
    }
  }
  // 字段名全集：字段初始化器可能引用其它字段（`widget.x` → `this.x`），
  // 解析初值的作用域需先知道全部字段名（propByField 在下循环里才逐步填充）。
  final fieldNames = {for (final f in fieldDecls) f.name};
  for (final field in fieldDecls) {
    {
      final fieldName = field.name;
      final typeName = field.typeName;
      final erased = eraseType(typeName);
      final isBasic = isBasicType(typeName) || _valueSdkTypes.contains(erased);
      final jsRuntime = jsRuntimeClassNames.contains(erased);
      if (!_fieldTranslatable(typeName, classTable, builtinWidgetTypes)) {
        // 对象类型字段（Controller/Widget/Key 等）没有 JS 等价物，自动跳过。
        // ignore: avoid_print - 构建期日志
        print(
          '[hot_patch_generator] 跳过字段 $fieldName（类型 $typeName 不可翻译）',
        );
        continue;
      }
      final init = field.initializer;
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
        // JS 运行时同名代理类（ScrollController / PageController / …）：
        // 构造按命名实参透传（代理类自行取用，如 PageController 的 initialPage）。
        initial = init == null
            ? 'null'
            : (jsRuntimeCtorJs(init, initScope, used) ?? 'new $erased()');
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
        // 有初始化器时按集合/表达式翻译（`final _items = ['a','b']` → `["a","b"]`）；
        // 翻译不出来（如宿主 widget 引用）才退化为 null。
        initial = ctorJs ??
            (init == null
                ? _defaultInitial(typeName)
                : (rhsToJs(init, initScope, used) ?? 'null'));
      }
      instanceFields.add(ClassField(
        name: fieldName,
        typeName: typeName,
        jsInitial: initial,
        mixinOrigin: field.mixinOrigin,
      ));
      propByField[fieldName] = fieldName;
    }
  }

  // 类表里的普通类（模型）名：值位置上的构造只排除这些类与值对象，其余类
  // 构造一律按组件元素翻译——不再维护「哪些类型是 widget」的白名单。
  final modelClassNames = <String>{
    for (final e in classTable.entries)
      if (!e.value.isComponent) e.key,
  };

  // 翻译上下文：实例字段表（propByField）+ 实例方法名表（actionByMethod）
  // ——widget 层据此解析标识符（`_count` → `this._count`）、区分本类实例
  // 方法与嵌套组件构造、事件绑定（`__bindFn`）。普通类与组件同一个上下文。
  final parseCtx = WidgetTranslateContext(
    propByField: propByField,
    actionByMethod: {
      for (final m in methods)
        if (!m.isGetter) m.name: m.name,
    },
    // 本类全部实例方法 / getter 名（含非动作方法）：数据表达式里的裸调用
    // （`Text(_likeText(post.like))`）与 setState/事件体里的 this.xxx(...) 都
    // 依赖它解析为本类方法，而不只限于注册为动作的方法。
    methodNames: {for (final m in methods) m.name},
    // getter 名（`_visiblePosts`）：JS 类里是 `get` 访问器，作为函数值传参时
    // 必须按值读，不能包装成调用（见 [WidgetTranslateContext.getterNames]）。
    getterNames: {
      for (final m in methods)
        if (m.isGetter) m.name,
    },
    sourcePath: sourcePath,
    importResolver: importResolver,
    singletons: singletons,
    globalConsts: globalConsts,
    hostMethods: hostMethods,
    jsClassWidgets: jsClassWidgets,
    delegateClassWidgets: delegateClassWidgets,
    modelClassNames: modelClassNames,
  );

  // 字段初始化器里的 widget 值（`Widget _w = Text();` / `final w = Text();`）：
  // 上面按「值表达式」翻译会失败（裸 Text() 不是模型构造），这里用 widget
  // 上下文补译，保证字段持有真正的元素对象；非 widget 字段保持原值。
  for (var i = 0; i < instanceFields.length; i++) {
    final f = instanceFields[i];
    final init = f.initializer;
    if (init == null) continue;
    final widgetJs = parseCtx.widgetValueJs(init, 2);
    if (widgetJs == null) continue;
    instanceFields[i] = ClassField(
      name: f.name,
      typeName: f.typeName,
      initializer: f.initializer,
      isStatic: f.isStatic,
      jsInitial: widgetJs,
      mixinOrigin: f.mixinOrigin,
    );
  }


  // 方法增强：classInfoOf 已建好结构（形参 / async / void / 返回 widget
  // 判定），这里只叠加翻译产物——预渲染方法体 [bodyJs] 与 native 通道识别
  //（方法体是 SnackBar 形式时整体改译 nativeToast）。getter 也在这里译好，
  // 渲染层不再需要回读 AST。
  ClassMethod buildMethod(ClassMethod cm, {String? bodyJs}) {
    if (cm.isGetter) {
      // getter 也要带上收集期译好的方法体（渲染层不再回读 AST）。
      return ClassMethod(
        name: cm.name,
        params: cm.params,
        isGetter: true,
        body: cm.body,
        bodyJs: bodyJs,
        superMap: cm.superMap,
        mixinOrigin: cm.mixinOrigin,
      );
    }
    final body = cm.body;
    final msg = body == null ? null : _snackMessage(body, parseCtx);
    return ClassMethod(
      name: cm.name,
      params: cm.params,
      isAsync: cm.isAsync,
      isVoid: cm.isVoid,
      returnsWidget: cm.returnsWidget,
      body: cm.body,
      bodyJs: bodyJs,
      nativeChannel: msg != null ? 'nativeToast' : null,
      nativeMessage: msg,
      superMap: cm.superMap,
      mixinOrigin: cm.mixinOrigin,
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
        bodyJs: translateClassMethodBody(proto, buildMethod(m), used,
            hostMethods: hostMethods,
            widgetCtx: parseCtx,
            globalConsts: globalConsts),
      ),
  ];

  // builder 子树同样在收集期渲染成 JS：渲染层只按名拼装，不再持有
  // WidgetTranslateContext。渲染过程会顺带登记用到的 widget 类型 / `__h`，
  // 因此必须在读取 usedWidgetPackages / usedNodeHelper 之前完成。
  final builderBodies = <String>[
    for (final tree in parseCtx.builderTrees) parseCtx.renderJs(tree, 2),
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
    builderBodies: builderBodies,
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

/// 有 JS 运行时对应物的 SDK 字段类型（字段可持有 / 转发，初值走通用表达式翻译）：
///   - `Color` → `'#aarrggbb'`、`IconData` → 图标名（运行时映射回真实对象）；
///   - `ValueNotifier` → JS 侧注入的同名类实例（句柄式，见 hot_patch 的
///     change_notifier_js.dart），构造走 [sdkValueCtorJs] → `new ValueNotifier(0)`。
/// 缺了它，`_OrderCard.statusColor` / `_DevRow.icon` 这类字段会被整条跳过，
/// 传进来也用不上（子组件里 `color: statusColor` 解析失败）；`_count` 同理
/// （`ValueListenableBuilder(valueListenable: _count)` 会取不到字段）。
const Set<String> _valueSdkTypes = {'Color', 'IconData', 'ValueNotifier'};

/// 字段类型是否可翻译（进 JS 实例属性）：
///   - 基础类型（int/double/num/String/bool/dynamic）；
///   - JS 运行时同名代理类（ScrollController / TextEditingController / …）；
///   - 已登记**非组件**类（模型，如 `Spot`）；
///   - 有 JS 运行时对应物的 SDK 类型（Color / IconData / ValueNotifier）；
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
  // 带类型实参的 SDK 类型（`ValueNotifier<int>`）：JS 侧没有泛型，实参只是
  // 静态信息，字段本体是可持有 / 转发的对象，直接放行。必须早于下面的
  // 容器分支——`ValueNotifier` 不在 `_containerTypes` 里，否则显式标注
  // `final ValueNotifier<int> _count = ValueNotifier<int>(0);` 会被整条跳过。
  if (lt >= 0 && t.endsWith('>') && _valueSdkTypes.contains(base)) return true;
  if (lt >= 0 && t.endsWith('>')) {
    if (!_containerTypes.contains(base)) return false;
    final args = _typeArgs(t.substring(lt + 1, t.length - 1));
    return args.isNotEmpty &&
        args.every((a) => _fieldTranslatable(a, classTable, widgetTypes));
  }
  if (t.isEmpty) return false;
  if (jsRuntimeClassNames.contains(t)) return true;
  // Key 字段（`final _formKey = GlobalKey<FormState>()` / `ValueKey k`）：
  // JS 侧有同名代理类（值对象，见 capabilities/key/key_js.dart），可持有/转发。
  if (keyClassNames.contains(t)) return true;
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
