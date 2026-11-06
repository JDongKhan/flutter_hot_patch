/// 类信息模型：Dart 类 → JS 的中立描述。
///
/// 只描述「类有什么」，不含翻译逻辑：字段、方法与构造参数，以及收集阶段
/// 已经产出的依赖 / widget 用量 / builder 子方法体。渲染层只读本模型。
library;

import 'package:analyzer/dart/ast/ast.dart';

/// 类的一个字段（实例或 static）。
///
/// [jsInitial] 是收集阶段预渲染好的 JS 初值（渲染层直接使用）；
/// [initializer] 保留原 AST，供类表/依赖解析与字面量兜底求值。
class ClassField {
  final String name;
  final String typeName;
  final Expression? initializer; // 无初始化则 null
  final bool isStatic;
  final String? jsInitial; // 预渲染 JS 初始值（非 null 时优先于 initializer）

  /// 声明处的 AST 结点（构建期告警定位到 `文件:行 | 源码行` 用，不参与翻译）。
  final AstNode? node;

  const ClassField({
    required this.name,
    required this.typeName,
    this.initializer,
    this.isStatic = false,
    this.jsInitial,
    this.node,
  });
}

/// 扩展成员的种类：显式分派要据此选形态
/// （方法 `E.m.call(x, …)` / getter `E.g.get.call(x)` / setter `E.g.set.call(x, v)`）。
enum ExtensionMemberKind { method, getter, setter }

/// 一个可见具名 extension 的分派信息（声明文件 + 成员表）。
///
/// 显式调用 `E(x).m()` 必须按**扩展身份**分派（Dart 的第三条规则）；原型只承接
/// 隐式调用（实例成员优先 + 原型链特异性）。
class ExtensionScope {
  const ExtensionScope(this.sourceFile, this.target, this.members);

  /// 声明该扩展的源文件（跨文件时据此 import 扩展命名空间）。
  final String sourceFile;

  /// 擦除后的目标类型名（`extension E on List<int>` → `List`）；无名 / 非具名
  /// 目标为 null。用于构建期发现「同目标同名成员」的歧义。
  final String? target;

  /// 实例成员名 → 种类集合（同名 get / set 可并存，故用集合而非单值）。
  final Map<String, Set<ExtensionMemberKind>> members;
}

/// 类的实例方法 / getter。
///
/// **方法体翻译只有一条路径**：收集阶段（analyze_dart_class）统一翻译所有
/// 方法体（含 getter 与 builder 子树），结果存进 [bodyJs]。方法体里
/// `return Text(...)` 这类「返回 widget」的表达式一律走 widget 层渲染——
/// build 与其它返回 widget 的方法没有任何区别（不存在「是不是 build」的判断）。
///
/// [body] 是原 AST（保留给告警定位与后续能力扩展）；[bodyJs] 是渲染层唯一
/// 读取的产物，收集完成后必定非空。
class ClassMethod {
  final String name;
  final List<String> params; // 形参名（JS 一比一）
  final bool isAsync;
  final bool isGetter;

  /// Dart `static` 方法：JS 侧发射为类的静态成员，裸调用落成 `<类名>.<name>(...)`
  /// （Dart 的 static 与实例成员在同一名字空间，调用点看不出差别，靠这个标记区分）。
  final bool isStatic;

  /// 返回类型为 void：箭头体会被译为语句（不加 `return`）。
  final bool isVoid;

  /// 返回值是否为 widget：`return Text(...)` 只有在此为真时才走 widget 树
  /// 渲染路径。普通类里返回模型的方法（`User makeUser() => User(...)`）返回
  /// 的是数据而非 widget，按普通表达式翻译，不会被误判成组件占位节点。
  final bool returnsWidget;
  final FunctionBody? body;
  final String? bodyJs; // 预渲染方法体（非 null 时优先于 body）

  /// 方法形参 AST（默认值 / 可选 / 具名形态的来源）。翻译阶段据此生成 JS
  /// 签名前导（可选位置默认值、具名实参从尾参对象解构）；渲染层只读预渲染的
  /// [bodyJs]，不直接使用本字段。getter 为 null。
  final FormalParameterList? parameters;

  /// 方法体是「宿主通道」形式（如 SnackBar → `nativeToast`）：整体译为
  /// `_app_host_.invoke("通道名", {...})`，[nativeMessage] 是已译好的消息 JS 表达式。
  final String? nativeChannel;
  final String? nativeMessage;

  /// Dart `set` 访问器：JS 侧发射为属性写访问器 `set name(v) { … }`。
  final bool isSetter;

  /// 运算符重载的 Dart 符号（`+` / `==` / `[]` …）；null = 普通方法。
  /// JS 没有运算符重载，成员名按 [operatorJsName] 改写为 `__op$<后缀>`，
  /// 调用点在「操作数静态类型可判定」时按同一张表改写。
  final String? operatorSymbol;

  /// 形参类型（名 → 源码类型），供调用点判定操作数是否走运算符分派。
  /// 无类型注解的形参不登记（unknown 就按 JS 原生运算）。
  final Map<String, String> paramTypes;

  /// `@HostInjected` 通道名（null = 普通方法）。标注方法的 Dart 实现留在宿主，
  /// JS 侧方法仍在类里，只是方法体整体改为
  /// `_app_host_.invoke(通道, 实参载荷)`（见 js_translator 的 [hostMethodBodyJs]）。
  final String? hostChannel;

  /// 位置形参个数（含可选位置形参）。宿主注入方法体据此把前 N 个实参当成
  /// 位置实参（调用点的通用约定：位置实参在前、具名实参合并成尾参对象）。
  final int positionalParamCount;

  /// 是否含具名形参（`{...}`）：宿主注入方法体据此选择实参载荷形态
  /// （纯具名 → 整个尾参对象；混合 → 前 N 个位置 + 尾参对象展开）。
  final bool hasNamedParams;

  /// 本方法声明的类型参数名（`T parse<T>(...)` → `['T']`），按声明顺序。
  /// 方法体里这些名字是类型值（`T == String` / `as T`），运行时从调用尾参对象
  /// 的 `typeArguments` 里按同名 key 取。
  final List<String> typeParams;

  const ClassMethod({
    required this.name,
    required this.params,
    this.isAsync = false,
    this.isGetter = false,
    this.isStatic = false,
    this.isVoid = false,
    this.returnsWidget = true,
    this.body,
    this.bodyJs,
    this.parameters,
    this.nativeChannel,
    this.nativeMessage,
    this.hostChannel,
    this.positionalParamCount = 0,
    this.hasNamedParams = false,
    this.typeParams = const [],
    this.isSetter = false,
    this.operatorSymbol,
    this.paramTypes = const {},
  });
}

/// 方法定义侧的 JS 形参签名。
///
/// 调用点的通用约定（见 `_methodCallJs`）：位置实参在前，**具名实参与类型实参
/// 合并成一个尾参对象**。因此定义侧只发射位置形参 + 一个尾参对象名：
///   - 含具名形参 → `__o`（同时承接 `typeArguments`）；
///   - 仅方法泛型 → `__ta`（保持既有形态）；
///   - 都没有 → 不追加。
/// getter 无形参；setter 恒为一个位置形参（Dart 不允许 setter 带可选/具名形参）。
List<String> jsSignatureParams(ClassMethod m) {
  if (m.isGetter) return const [];
  if (m.isSetter) return m.params;
  final out = <String>[...m.params.take(m.positionalParamCount)];
  final tail = tailParamNameOf(m);
  if (tail != null) out.add(tail);
  return out;
}

/// 尾参对象名（具名实参 / 类型实参的共用载体，见 [jsSignatureParams]）。
String? tailParamNameOf(ClassMethod m) {
  if (m.hasNamedParams) return '__o';
  if (m.typeParams.isNotEmpty) return '__ta';
  return null;
}

/// 类的一个**命名构造**（`X.b(...)` / `factory X.b(...)`）。
///
/// 调用点按源码签名翻译成 `X.b({...})`（位置实参映射成形参名），JS 侧必须有
/// 同名静态方法承接；[bodyJs] 是已预渲染的静态方法体（形参局部化、初始化列表、
/// 构造体/工厂体全部在收集阶段译好，渲染层只拼装）。
class ClassCtor {
  final String name;

  /// 是否 factory 构造（factory 体直接 `return`，不构造实例）。
  final bool isFactory;

  /// 位置形参名（顺序与声明一致），供调用点把位置实参映射成 props 键。
  final List<String> positional;

  /// 具名形参名（`X.b({required this.x})` → `{x}`）。
  final Set<String> named;

  /// 静态方法体（缩进已按类体内方法体口径预渲染）。
  final String bodyJs;

  const ClassCtor({
    required this.name,
    required this.bodyJs,
    this.isFactory = false,
    this.positional = const [],
    this.named = const {},
  });
}

/// 一层 mixin application 类（`class C extends B with M1, M2` 的一步）。
///
/// 按 dart2js 的结构：mixin 本身在**原文件产物**里是独立类；本类只描述消费者
/// 文件里合成的中间类（`_C_B_M1` / `_C_B_M1_M2`），最终 `C` 继承最后一层。
/// [layer] 是这层 application 类的中立描述（字段 / 带 super 的方法）；不带
/// super 的成员留在 [mixinName] 指向的 mixin 类里，由 `__mixinHard` 复制。
class MixinApplication {
  /// 导入的 mixin 类名（mixin class 同名；纯 mixin 也是同名类）。
  final String mixinName;

  /// mixin 声明所在源文件（import 产物路径推导用）。
  final String sourceFile;

  /// 这层 application 类（字段 + 带 super 的方法），已预翻译。
  final ClassInfo layer;

  const MixinApplication({
    required this.mixinName,
    required this.sourceFile,
    required this.layer,
  });
}

/// 一个 Dart 类翻译成 JS 后的中立描述（按「声明」建模，不看用途）。
///
/// 组件（@PatchEntry）与普通类都是 Dart 类，用**完全相同**的模型描述：
/// 字段、方法（方法体已在收集阶段预渲染）、构造参数。
/// 组件只是额外带一项数据：[isComponent] —— 仅用于产物注释标注。
class ClassInfo {
  final String name;
  final String sourceFile; // dart 源文件路径（用于推导 import/相对产物）
  final String? superType; // extends 的类名（如 ChangeNotifier）

  /// 组件类**widget 侧**的 extends 类名（`StatelessWidget` / `StatefulWidget` /
  /// 项目内组件基类）。组件把 State 合并进同一个类，[superType] 因此恒为 null；
  /// 但 JS 产物仍按这个基类发射 `extends StatelessWidget / StatefulWidget`。
  final String? widgetSuperType;
  final List<ClassField> instanceFields;
  final List<ClassField> staticFields;
  final List<ClassMethod> methods; // 含 getter

  /// 命名构造（`X.b`）→ 类上的同名静态方法；无名构造由 `constructor(args)`
  /// 承接，不在这里。
  final List<ClassCtor> ctors;

  final Set<String> ctorParams; // this.x 构造形参名

  /// 无名构造（默认构造）的形参局部绑定：`const p = args.p;`（带默认值时同
  /// 命名构造。仅当无名构造有初始化列表 / 构造体时才生成——widget 的
  /// `const A({super.key})` 保持既有 `constructor(args)` 形态不变）。
  final List<String> ctorParamJs;

  /// 无名构造的初始化列表语句：`this.x = <expr>;` / `assert(...)`。
  final List<String> ctorInitJs;

  /// 无名构造的构造体语句（已按 4 空格缩进；空串 = 无构造体）。
  final String ctorBodyJs;

  /// 构造形参默认值（`this.banners = kBanners`）：字段名 → 默认值表达式。
  /// 建模期（classInfoOf）随构造参数一并收集；翻译期作为字段初值的兜底
  ///（JS 侧漏传 props 时用它，而不是类型默认值 `[]`/`''`）。
  final Map<String, Expression> ctorDefaults;

  /// 是否为 @PatchEntry 组件（仅用于产物注释标注，不参与结构分叉）。
  final bool isComponent;

  /// 是否为 `abstract class`：抽象成员（无方法体）在 JS 侧生成抛错兜底，
  /// 其余与普通类完全同一条翻译路径（抽象类照常产出 JS class 并被 extends）。
  final bool isAbstract;

  /// 本类是否为**可调用对象**（声明了非 static 的实例方法 `call`）。
  /// 声明侧 `call` 改名为 `invoke`（避免与 `Function.prototype.call` 混淆，
  /// 见手册 `call(...)` 行）；调用侧按静态类型把 `obj(...)` / `obj.call(...)`
  /// 改写为 `obj.invoke(...)`。
  final bool isCallable;

  /// 类声明的类型参数名（`class Pair<K, V>` → `['K', 'V']`），按声明顺序。
  /// 实例构造时把 `typeArguments` 存到 `__ta`，方法体里的 `T` 据此读运行时类型名。
  final List<String> typeParams;

  // --- 翻译期发现的依赖信息（组件/普通类同一份模型，builder 据此递归、import）---

  /// 翻译本类时引用到的其它类/组件名：字段类型 + 方法体里构造调用 + 嵌套组件。
  /// builder 据此**递归翻译**依赖组件，并按 [sourceFile] 决定同文件内联还是
  /// 跨文件 import。依赖发现与「类 → JS」是同一次翻译的产物（不在 builder 里另起一套）。
  final Set<String> dependencies;

  /// 本类实际用到的 widget 类型（package → {type}）：据「只转换用到的」按 package
  /// 产出 JS widget 模块。
  final Map<String, Set<String>> usedWidgetPackages;

  /// 本类用到的 import 前缀（`import '...' as p;`）→ 该前缀的模块产物路径。
  /// builder 据此为产物补 `import * as p from '<产物>';`（Dart 前缀消解同名类，
  /// JS 侧由模块命名空间承接）。
  final Map<String, String> namespaceImports;

  /// `with` 生成的一串 application 类（顺序与 `with` 书写顺序一致，
  /// 最终类继承最后一层）。空 = 本类没有 mixin。
  final List<MixinApplication> mixinApplications;

  const ClassInfo({
    required this.name,
    required this.sourceFile,
    this.superType,
    this.widgetSuperType,
    required this.instanceFields,
    required this.staticFields,
    required this.methods,
    this.ctors = const [],
    this.ctorParams = const {},
    this.ctorParamJs = const [],
    this.ctorInitJs = const [],
    this.ctorBodyJs = '',
    this.ctorDefaults = const {},
    this.isComponent = false,
    this.isAbstract = false,
    this.isCallable = false,
    this.typeParams = const [],
    this.dependencies = const {},
    this.usedWidgetPackages = const {},
    this.namespaceImports = const {},
    this.mixinApplications = const [],
  });

  Set<String> get instanceFieldNames =>
      {for (final f in instanceFields) f.name};

  Set<String> get methodNames => {for (final m in methods) m.name};

  /// 复制并替换命名构造表：构造体翻译时需要一份「带本类全部命名构造签名」的
  /// 类表视图（本类条目在最终 ClassInfo 里才带上 ctors）。
  ClassInfo copyWith({List<ClassCtor>? ctors}) => ClassInfo(
        name: name,
        sourceFile: sourceFile,
        superType: superType,
        widgetSuperType: widgetSuperType,
        instanceFields: instanceFields,
        staticFields: staticFields,
        methods: methods,
        ctors: ctors ?? this.ctors,
        ctorParams: ctorParams,
        ctorParamJs: ctorParamJs,
        ctorInitJs: ctorInitJs,
        ctorBodyJs: ctorBodyJs,
        ctorDefaults: ctorDefaults,
        isComponent: isComponent,
        isAbstract: isAbstract,
        isCallable: isCallable,
        typeParams: typeParams,
        dependencies: dependencies,
        usedWidgetPackages: usedWidgetPackages,
        namespaceImports: namespaceImports,
        mixinApplications: mixinApplications,
      );
}
