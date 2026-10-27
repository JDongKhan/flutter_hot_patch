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

  /// 来源 mixin 名（线性化展开进本类的成员）；null = 类自身声明。
  /// 仅用于产物分组注释（mixin 成员集中尾部、按来源分隔），不影响翻译。
  final String? mixinOrigin;
  const ClassField({
    required this.name,
    required this.typeName,
    this.initializer,
    this.isStatic = false,
    this.jsInitial,
    this.mixinOrigin,
  });
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

  /// 返回类型为 void：箭头体会被译为语句（不加 `return`）。
  final bool isVoid;

  /// 返回值是否为 widget：`return Text(...)` 只有在此为真时才走 widget 树
  /// 渲染路径。普通类里返回模型的方法（`User makeUser() => User(...)`）返回
  /// 的是数据而非 widget，按普通表达式翻译，不会被误判成组件占位节点。
  final bool returnsWidget;
  final FunctionBody? body;
  final String? bodyJs; // 预渲染方法体（非 null 时优先于 body）

  /// 方法体是「宿主通道」形式（如 SnackBar → `nativeToast`）：整体译为
  /// `_app_host_.invoke("通道名", {...})`，[nativeMessage] 是已译好的消息 JS 表达式。
  final String? nativeChannel;
  final String? nativeMessage;

  /// super 调用映射（mixin 线性化展开的产物）：`super.foo()` 语句里 super 的
  /// 方法名 → 链上下一个实现的 JS 方法名（如 `initState` → `_m$TestMixin$initState`）。
  /// 查不到 = 链上无更多实现（基类无 JS 等价物），super 语句按原策略忽略。
  /// 空表 = 本类无 mixin，完全走原路径。
  final Map<String, String> superMap;

  /// 来源 mixin 名（线性化展开进本类的方法）；null = 类自身声明。
  /// 仅用于产物分组注释（mixin 成员集中尾部、按来源分隔），不影响翻译。
  final String? mixinOrigin;
  const ClassMethod({
    required this.name,
    required this.params,
    this.isAsync = false,
    this.isGetter = false,
    this.isVoid = false,
    this.returnsWidget = true,
    this.body,
    this.bodyJs,
    this.nativeChannel,
    this.nativeMessage,
    this.superMap = const {},
    this.mixinOrigin,
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
  final List<ClassField> instanceFields;
  final List<ClassField> staticFields;
  final List<ClassMethod> methods; // 含 getter
  final Set<String> ctorParams; // this.x 构造形参名

  /// 构造形参默认值（`this.banners = kBanners`）：字段名 → 默认值表达式。
  /// 建模期（classInfoOf）随构造参数一并收集；翻译期作为字段初值的兜底
  ///（JS 侧漏传 props 时用它，而不是类型默认值 `[]`/`''`）。
  final Map<String, Expression> ctorDefaults;

  /// 是否为 @PatchEntry 组件（仅用于产物注释标注，不参与结构分叉）。
  final bool isComponent;

  // --- 翻译期发现的依赖信息（组件/普通类同一份模型，builder 据此递归、import）---

  /// 翻译本类时引用到的其它类/组件名：字段类型 + 方法体里构造调用 + 嵌套组件。
  /// builder 据此**递归翻译**依赖组件，并按 [sourceFile] 决定同文件内联还是
  /// 跨文件 import。依赖发现与「类 → JS」是同一次翻译的产物（不在 builder 里另起一套）。
  final Set<String> dependencies;

  /// 本类实际用到的 widget 类型（package → {type}）：据「只转换用到的」按 package
  /// 产出 JS widget 模块。
  final Map<String, Set<String>> usedWidgetPackages;

  /// 方法体里是否用到结点工厂 `__h`（决定产物是否 import `__h`）。
  final bool usedNodeHelper;


  /// 本文件 `@HostInjected` 声明的通道表（类名 → {方法名 → 通道名}；顶层函数
  /// 挂在空串 key 下）。由收集阶段自行扫好挂在模型上，方法体翻译据此把调用点
  /// 整体换成 `_app_host_.invoke(通道, 载荷)`——组件与普通类同一份数据、
  /// 同一条路径，构建层不参与。
  final Map<String, Map<String, String>> hostMethods;

  const ClassInfo({
    required this.name,
    required this.sourceFile,
    this.superType,
    required this.instanceFields,
    required this.staticFields,
    required this.methods,
    this.ctorParams = const {},
    this.ctorDefaults = const {},
    this.isComponent = false,
    this.dependencies = const {},
    this.usedWidgetPackages = const {},
    this.usedNodeHelper = false,
    this.hostMethods = const {},
  });

  bool get isStaticOnly => instanceFields.isEmpty && methods.isEmpty;

  Set<String> get instanceFieldNames =>
      {for (final f in instanceFields) f.name};

  Set<String> get methodNames => {for (final m in methods) m.name};
}
