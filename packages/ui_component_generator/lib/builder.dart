import 'dart:async';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:build/build.dart';

import 'builtin_translators.dart';
import 'class_translator.dart';
import 'host_method_scan.dart';
import 'style_translators.dart';
import 'widget_translator.dart';

/// build_runner 工厂入口（build.yaml 的 builder_factories 指向这里）
/// 本 builder 不读任何 options（种子路径只对 [WidgetModuleBuilder] 有意义）。
Builder componentBuilder(BuilderOptions _) => const ComponentBuilder();

Builder widgetModuleBuilder(BuilderOptions options) =>
    WidgetModuleBuilder(seedPath: _seedPathFrom(options));

/// 把 lib/ 下的 Dart 源文件翻译为**同名** JS 产物（`lib/a/b.dart` → `assets/a/b.js`）：
/// 文件名与 Dart 源文件一一对应，不区分组件/模型，也不预设目录结构——源码
/// 怎么组织、有哪些目录，由使用方决定，产物跟着走。
///
/// 按**文件内容**分流（与目录无关）：
///   - 含 `@UIComponent` 类 → 组件产物（Component 类 + build + 事件绑定）；
///   - 仅含普通类（非私有、非抽象、无 build()）→ 模型/单例产物
///     （`export class` / `export const`，供组件产物 import）；
///   - 都没有（如 main.dart）→ 不产出。
///
/// 组件本身 100% 正常可用（普通 StatefulWidget）；注解只是构建期元数据，
/// 生成器全程静态解析，不执行任何 Dart 代码。
///
/// # 架构
///
/// ComponentBuilder 只负责「总控」：
///   - 解析 @UIComponent widget → State 类
///   - 把 build() 的 widget 树交给 WidgetTranslateContext 翻译
///   - 组装产物
///
/// 「某个 widget 怎么翻译成 JSON/JS」是策略，由 WidgetTranslator 实现：
///   - 抽象类与注册表见 widget_translator.dart
///   - 内置 Column/Row/Text/ElevatedButton 见 builtin_translators.dart
///   - 新增/自定义 widget = 写一个 WidgetTranslator 并 register，
///     核心代码零改动。
class ComponentBuilder implements Builder {
  const ComponentBuilder();

  /// JS widget 模块（`patch/flutter.js` / `patch/provider.js` …）
  /// 由 [WidgetModuleBuilder] 产出；本 builder 只产出与源文件同名的产物。
  ///
  /// 输出路径**直接镜像 lib 源码路径**（`lib/a/b.dart` → `patch/a/b.js`），
  /// 文件名与 Dart 源文件一致，不预设目录名、不区分组件/模型。
  @override
  Map<String, List<String>> get buildExtensions => const {
        '^lib/{{}}.dart': [
          'patch/{{}}.js',
        ],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final inputId = buildStep.inputId;
    final source = await buildStep.readAsString(inputId);
    final parsed = parseString(
      content: source,
      throwIfDiagnostics: false,
      path: inputId.path,
    );

    // 策略注册表：目前注册内置 widget；业务方可在此扩展自定义 translator。
    final registry = WidgetTranslatorRegistry();
    registerBuiltinTranslators(registry);

    // 按内容分流（与目录无关）：文件里没有 @UIComponent → 模型/单例产物
    // （模型放哪个目录都行）；有 → 组件产物。
    final hasComponent = parsed.unit.declarations
        .whereType<ClassDeclaration>()
        .any((d) => _findAnnotation(d.metadata, 'UIComponent') != null);
    // 宿主注入方法表（类名 → {方法名 → 通道名}）：组件与模型两条路径都要用。
    final hostMethods = _buildHostMethods(parsed.unit, inputId.path);
    if (!hasComponent) {
      await _writeModelProduct(
          buildStep, parsed.unit, inputId, registry, hostMethods);
      return;
    }

    // 组件名 → 依赖产物 jsAsset 路径。规则：
    //   本文件注解组件 / 本文件私有组件 → 本文件产物（同产物注册）；
    //   本文件无注解非私有组件（如 MyCustomCard）→ null（运行时原生注入）；
    //   跨文件组件 → 从 import directives 推导源文件产物。
    // （提前于 components 收集构造：_parseComponent 内部翻译 Component
    //   节点时即会调用 importResolver，闭包必须已初始化）
    final parsedNames = <String>{
      for (final d in parsed.unit.declarations)
        if (d is ClassDeclaration) d.name.lexeme,
    };
    final annotatedNames = <String>{
      for (final d in parsed.unit.declarations)
        if (d is ClassDeclaration &&
            _findAnnotation(d.metadata, 'UIComponent') != null)
          d.name.lexeme,
    };
    // 产物采用**相对路径**（相对当前产物所在目录，如 'bar_component.js'）：
    // 未来 JS 产物整体发布（CDN / 包内迁移）时，主产物与依赖产物的相对关系
    // 不变，运行时按当前 jsAsset 的目录解析即可，绝对路径会随部署位置失效。
    final ownProduct = _productPath(inputId.path); // patch/.../x.js
    final ownName = ownProduct.substring(ownProduct.lastIndexOf('/') + 1);
    // 跨文件组件名 → 产物路径（按**类名**精确绑定；见 _resolveImportedComponentProducts）。
    final importProducts =
        _resolveImportedComponentProducts(parsed.unit, inputId.path);
    String? importResolver(String name) {
      // @UIComponentIgnore：显式「不参与连带转换」的类 → null
      // （保持 Component 节点，运行时原生注入，等价于无注解公共组件路径）。
      if (_isIgnoredClass(parsed.unit, name)) return null;
      if (parsedNames.contains(name)) {
        if (annotatedNames.contains(name) || name.startsWith('_')) {
          return ownName;
        }
        return null;
      }
      final abs = importProducts[name];
      if (abs == null) return null;
      return _relativeProduct(ownProduct, abs);
    }

    // 统一「类表」：把同文件 + 跨文件的所有普通 Dart 类（去 @UIComponent/
    // 私有/抽象/widget 类）收集成 ClassInfo 索引。User/MyModel/静态单例
    // 都由此统一发现，不再按用途分流（见 class_translator.dart）。
    final classIndex = _buildClassIndex(parsed.unit, inputId.path);

    // 跨文件「静态单例类」映射：照旧，供 build 树里 `MyColors.x` 静态引用
    // 翻译成 JS 表达式（见 style_translators._colorExpr）。产物渲染统一走
    // class_translator.renderStaticConst。
    final singletons = _buildSingletonResolver(parsed.unit, inputId.path);

    // 本文件声明的「静态单例类」→ inline 进本产物（const X = {...}，不 import）
    final sameFileSingletonInfos = <ClassInfo>[
      for (final d in _findSingletonClasses(parsed.unit))
        if (classIndex.containsKey(d.name.lexeme)) classIndex[d.name.lexeme]!,
    ];

    // 收集本文件内全部 @UIComponent 组件（支持单文件多组件 / 文件内共享普通类）
    final components = <_Component>[];
    for (final declaration in parsed.unit.declarations) {
      if (declaration is! ClassDeclaration) continue;
      final uiComponent = _findAnnotation(declaration.metadata, 'UIComponent');
      if (uiComponent == null) continue; // 普通类（共享基类等）直接跳过

      components.add(_parseComponent(
        declaration,
        parsed.unit,
        _positionalString(uiComponent, 0) ?? declaration.name.lexeme,
        registry,
        inputId.path,
        importResolver,
        classIndex: classIndex,
        singletons: singletons,
        hostMethods: hostMethods,
      ));
    }

    // BFS 收集嵌套依赖：主组件 build 里用到的本文件**私有组件**（_Xxx）
    // 同样翻译成 JS 注册进同一产物；非私有组件保持 Component 节点，
    // 运行时由业务方注入原生 widget（nativeComponents）或占位。
    final doneDeps = <String>{};
    final depQueue = <String>[
      for (final c in components) ...c.deps,
    ];
    while (depQueue.isNotEmpty) {
      final dep = depQueue.removeLast();
      if (doneDeps.contains(dep)) continue;
      doneDeps.add(dep);
      // 翻译本文件内**有产物**的同文件组件（私有 _Xxx / 注解组件）为
      // inline 工厂（与主组件同产物）。判定与 importResolver 对齐：
      // 仅「同文件且有产物」（返回本产物名）才翻译；@UIComponentIgnore 与
      // 无注解公共组件（如 MyCustomCard）返回 null，保持 Component 节点走
      // 原生注入，不产出无用 JS 类。已收集的主组件跳过。
      if (!parsedNames.contains(dep)) continue;
      if (importResolver(dep) != ownName) continue;
      if (components.any((c) => c.name == dep)) continue;
      final decl = parsed.unit.declarations
          .whereType<ClassDeclaration>()
          .firstWhere((d) => d.name.lexeme == dep);
      final nested = _parseNestedComponent(
          decl, parsed.unit, dep, registry, inputId.path, importResolver,
          classIndex: classIndex, singletons: singletons,
          hostMethods: hostMethods);
      components.add(nested);
      depQueue.addAll(nested.deps);
    }
    // ignore: avoid_print - 构建期日志
    print(
      '[ui_component_generator] $inputId: '
      '${components.map((c) => c.name).join(', ')}',
    );

    // 一次渲染合并产物：一个文件 → 一个同名 JS（注册多个组件）
    final jsOutput = buildStep.allowedOutputs.first;
    await buildStep.writeAsString(
      jsOutput,
      _renderJs(components, inputId.path, registry, importResolver,
          singletons: singletons,
          sameFileSingletonInfos: sameFileSingletonInfos,
          hostMethods: hostMethods),
    );
  }
}

/// 非组件文件（无 @UIComponent）的产物渲染：把文件里的「可导出类」写成 JS。
///
/// 判定与目录无关（模型放哪个目录都行），只看内容：
///   - 静态单例类（含非私有 static 字段）→ `export const X = {...}`；
///   - 其余普通类（非私有、非抽象、无 build()）→ `export class X`；
///   - widget / State（有 build()）与私有类跳过，避免 main.dart 这类文件
///     产出无用 JS。
/// 无任何可导出类 → 不产出。
Future<void> _writeModelProduct(
  BuildStep buildStep,
  CompilationUnit unit,
  AssetId inputId,
  WidgetTranslatorRegistry registry,
  Map<String, Map<String, String>> hostMethods,
) async {
  // 复用组件路径的「普通类」判定（非私有 / 非抽象 / 非注解 / 无 build()）。
  // classIndex 还含 import 文件的类，需按 sourceFile 只取本文件声明的类。
  final own = <String, ClassInfo>{
    for (final e in _buildClassIndex(unit, inputId.path).entries)
      if (e.value.sourceFile == inputId.path) e.key: e.value,
  };
  // 静态单例类：本文件里「有非私有 static 字段」的普通类（widget 类已被
  // classIndex 剔除，故 MyPage 这类含 build() 的页面不会误产出）。
  final singletonNames = <String>{
    for (final d in _findSingletonClasses(unit))
      if (own.containsKey(d.name.lexeme)) d.name.lexeme,
  };
  final singletons = <ClassInfo>[for (final n in singletonNames) own[n]!];
  final models = <ClassInfo>[
    for (final e in own.entries)
      if (!singletonNames.contains(e.key)) e.value,
  ];
  if (models.isEmpty && singletons.isEmpty) return;
  await buildStep.writeAsString(
    buildStep.allowedOutputs.first,
    _renderModelJs(models, singletons, inputId.path, registry, hostMethods),
  );
}

// ---------------------------------------------------------------------------
// 组件模型
// ---------------------------------------------------------------------------

class _Component {
  final String name;
  final List<_Prop> props;
  final List<_Action> actions;
  final Object? tree; // 节点树（Map = 节点；String = 根 build 三目/if 的 JS 表达式）

  /// 构造参数（私有嵌套组件）：`this.x = args && args.x !== undefined ? args.x : def`。
  final List<String> ctorArgs;

  /// build 树里依赖的自定义组件名（Component 兜底收集）。
  final Set<String> deps;

  /// 组件（含私有嵌套组件）按调用链用到的类（State 字段类型 + 构造调用）。
  /// 统一由 class_translator 翻译（见 _usedClasses / _buildClassIndex）。
  final Map<String, ClassInfo> models;

  /// 响应式 builder 闭包（ListenableBuilder/Consumer）抽出的子树
  /// （译成实例方法，运行时时模型 notify 后重新调用拿最新子树局部重建）。
  final List<Object?> builders; // 节点或 JS 表达式（三目）

  /// 与 [builders] 同步的方法名（`_lbBuilderN` / `_consumerBuilderN`）。
  final List<String> builderNames;

  /// 与 [builders] 同步的形参名（null = 无参；Consumer 为 value）。
  final List<String?> builderParams;

  /// 与 [builderNames] 同步的「方法体前置语句」（Builder 闭包块体里的
  /// 局部声明/日志 → JS 语句串），产物 builder 方法体内先输出再 return 树。
  final List<String> builderPreludes;

  /// build() return 前的局部变量声明（`final isAdult = ...;` → `var isAdult = ...;`），
  /// 产物 build() 方法体内先输出声明再 return 树；树里 Identifier 直接引用。
  final List<String> localDecls;

  /// 本组件 build 树**实际用到**的 widget 类型（package → {type}）：
  /// 由渲染期收集，生成器据此按 package 产出 JS widget 模块（只转换用到的，
  /// 不默认全量）。
  final Map<String, Set<String>> usedWidgetPackages;

  const _Component(this.name, this.props, this.actions, this.tree,
      {this.ctorArgs = const [],
      this.deps = const {},
      this.models = const {},
      this.builders = const [],
      this.builderNames = const [],
      this.builderParams = const [],
      this.builderPreludes = const [],
      this.localDecls = const [],
      this.usedWidgetPackages = const {}});
}

/// 统一「类表」：把一个文件（同文件 + 跨文件 import）的全部普通 Dart 类
/// 收集成 ClassInfo 索引。去 @UIComponent / 私有 / 抽象 / widget 类。
Map<String, ClassInfo> _buildClassIndex(CompilationUnit unit, String sourcePath) {
  final out = <String, ClassInfo>{};
  void addFile(ClassDeclaration d, String file) {
    final name = d.name.lexeme;
    if (name.startsWith('_') || out.containsKey(name)) return;
    if (d.abstractKeyword != null) return;
    if (_findAnnotation(d.metadata, 'UIComponent') != null) return;
    // @HostInjected 类：方法实现留在 Dart，不产出 JS（调用点被翻译为
    // __jsui.host，见 _buildHostMethods 与 class_translator.methodCallExprJs）。
    if (_classHasHostInjectedMethod(d)) return;
    // widget 类（有 build 方法）不是普通类，走组件/嵌套翻译路径
    if (d.members
        .whereType<MethodDeclaration>()
        .any((m) => m.name.lexeme == 'build')) {
      return;
    }
    out[name] = classInfoOf(d, file);
  }

  for (final d in unit.declarations.whereType<ClassDeclaration>()) {
    addFile(d, sourcePath);
  }
  for (final file in _resolveImportFiles(unit, sourcePath)) {
    final f = File(file);
    if (!f.existsSync()) continue;
    final parsed = parseString(content: f.readAsStringSync());
    for (final d in parsed.unit.declarations.whereType<ClassDeclaration>()) {
      addFile(d, file);
    }
  }
  return out;
}

/// 候选类名：State 实例字段类型 + 方法体/build 树构造调用 并集。
Set<String> _candidateClassNames(
  ClassDeclaration hostClass,
  List<MethodDeclaration> methods,
  MethodDeclaration buildMethod,
) {
  final collector = _CtorCollector();
  for (final m in methods) {
    m.body.accept(collector);
  }
  buildMethod.body.accept(collector);
  final names = collector.names;
  for (final member in hostClass.members) {
    if (member is FieldDeclaration && !member.isStatic) {
      for (final v in member.fields.variables) {
        final t = _eraseType(_fieldTypeName(member, v));
        if (!_isBasicType(t) && t.isNotEmpty) names.add(t);
      }
    }
  }
  return names;
}

/// 候选类名 ∩ 类表 → 实际使用的类（统一翻译的集合）。
/// [excludeTypes]：已注册 WidgetTranslator 的 widget 构造名（如业务侧自定义
/// 受控滚动组件 ControlledScrollView）——它们由 translator 接管翻译成 JS
/// 构造调用（经 flutter.js 工厂 + 宿主注册表），不能再当模型类翻译进产物，
/// 否则与 import 的工厂函数同名冲突（ES module 重复声明直接加载失败）。
Map<String, ClassInfo> _usedClasses(
  Set<String> candidates,
  Map<String, ClassInfo> index,
  [Set<String>? excludeTypes]
) =>
    {
      for (final n in candidates)
        if (index.containsKey(n) &&
            (excludeTypes == null || !excludeTypes.contains(n)))
          n: index[n]!,
    };

/// 字段类型：优先显式类型注解；无注解时从初始化器推断
/// （`final _model = MyModel();` 在无 resolution 解析下 type 为 null，
/// 会退化成 dynamic 被当基础类型，需从构造名推回 MyModel）。
String _fieldTypeName(FieldDeclaration member, VariableDeclaration variable) {
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

/// 去除可空 / 泛型：`User?` → `User`，`List<User>` → `User`。
String _eraseType(String type) {
  var t = type.trim();
  if (t.endsWith('?')) t = t.substring(0, t.length - 1);
  final lt = t.indexOf('<');
  if (lt >= 0) t = t.substring(0, lt).trim();
  return t;
}

class _Prop {
  final String field; // Dart 字段名，如 _count
  final String name; // 状态名，如 count
  final String type; // int / String / bool ...
  final String initial; // JS 初始值字面量
  final bool fromArgs; // 由构造参数（args）初始化
  _Prop(this.field, this.name, this.type, this.initial, {this.fromArgs = false});
}

class _Action {
  final String method; // Dart 方法名，如 _inc
  final String name; // 事件名，如 inc
  final String? nativeChannel;
  final String bodyJs;
  final List<String> params; // 方法形式参数名（JS 一比一透传，如 v）

  /// 方法是 async（`Future<void> load() async {...}`）→ 产物输出
  /// `async function`（await 只能在 async 函数内使用）。
  final bool isAsync;

  _Action(this.method, this.name, this.nativeChannel, this.bodyJs,
      {this.params = const [], this.isAsync = false});
}

// ---------------------------------------------------------------------------
// 注解 / 类解析
// ---------------------------------------------------------------------------

_Component _parseComponent(
  ClassDeclaration widgetClass,
  CompilationUnit unit,
  String componentName,
  WidgetTranslatorRegistry registry,
  String sourcePath,
  String? Function(String component) importResolver, {
  required Map<String, ClassInfo> classIndex,
  SingletonResolver? singletons,
  Map<String, Map<String, String>> hostMethods = const {},
}) {
  // 承载 build 的类：StatefulWidget → 其 State 类；StatelessWidget →
  // widget 类自身（无 createState）。与 _parseNestedComponent 同一规则，
  // 保证主组件与嵌套组件对 Stateful/Stateless 的支持一致。
  ClassDeclaration hostClass = widgetClass;
  final stateClassName = _stateClassName(widgetClass);
  if (stateClassName != null) {
    for (final d in unit.declarations) {
      if (d is ClassDeclaration && d.name.lexeme == stateClassName) {
        hostClass = d;
        break;
      }
    }
    if (identical(hostClass, widgetClass)) {
      throw FormatException('找不到 State 类 $stateClassName（需与 widget 同文件）');
    }
  }

  // 构造参数：widget 类构造函数的 this.xxx 命名形参（props 从 args 初始化）。
  // 主组件也支持（StatelessWidget / 带业务参数的 StatefulWidget 都需要）。
  final ctorArgs = <String>[];
  for (final m in widgetClass.members) {
    if (m is ConstructorDeclaration) {
      for (final param in m.parameters.parameters) {
        final inner = param is DefaultFormalParameter ? param.parameter : param;
        if (inner is FieldFormalParameter) ctorArgs.add(inner.name.lexeme);
      }
    }
  }

  final props = <_Prop>[];
  final actions = <_Action>[];
  final propByField = <String, String>{};
  final actionByMethod = <String, String>{};
  final methods = <MethodDeclaration>[];
  MethodDeclaration? buildMethod;

  // Pass 1：只收集方法（含 build），为「按调用链发现模型」做准备
  for (final member in hostClass.members) {
    if (member is MethodDeclaration) {
      if (member.name.lexeme == 'build') {
        buildMethod = member;
        continue;
      }
      if (_skipMethod(member)) continue;
      methods.add(member);
    }
  }

  if (buildMethod == null) {
    throw FormatException('$componentName 缺少 build() 方法（StatefulWidget 需在 State 类、StatelessWidget 需在 widget 类）');
  }

  // 统一类发现：State 实例字段类型 → 类（State 维度，用户强调），
  // 方法体/build 树构造调用兜底（如 hello 里的 `User(...)`），并集进 classIndex
  // 命中的类统一翻译（见 class_translator.dart，不再按用途分流）。
  final used = _usedClasses(
    _candidateClassNames(hostClass, methods, buildMethod),
    classIndex,
    registry.registeredTypes,
  );

  // 字段收集：基础类型 / 类类型字段（含对象字段 `_model = MyModel()` →
  // `this._model = new MyModel({})`、`User? _user` → `this._user = null`）
  // 一律进 JS 实例属性，跨 build 持久。
  for (final member in hostClass.members) {
    if (member is FieldDeclaration) {
      for (final variable in member.fields.variables) {
        final fieldName = variable.name.lexeme;
        final typeName = _fieldTypeName(member, variable);
        if (member.isStatic) continue;
        final erased = _eraseType(typeName);
        final isBasic = _isBasicType(typeName);
        // JS 运行时类型（ScrollController）：JS 侧有同名类（new ScrollController()），
        // 字段进 JS 实例属性，方法/属性调用一比一翻译，不再跳过。
        final jsRuntime = _jsRuntimeTypes.contains(erased);
        final cls = used[erased];
        if (!isBasic && cls == null && !jsRuntime) {
          // 对象类型字段（Controller/Widget/Key 等）没有 JS 等价物，自动跳过。
          // ignore: avoid_print - 构建期日志
          print(
            '[ui_component_generator] 跳过字段 $fieldName（类型 $typeName 不可翻译）',
          );
          continue;
        }
        String initial;
        if (isBasic) {
          initial = _renderLiteral(variable.initializer) ??
              _defaultInitial(typeName);
        } else if (jsRuntime) {
          // `ScrollController()` → `new ScrollController()`；可空字段 → null。
          initial = variable.initializer == null
              ? 'null'
              : (_jsRuntimeCtor(erased) ?? 'null');
        } else {
          final init = variable.initializer;
          String? ctorJs;
          if (init is InstanceCreationExpression) {
            ctorJs = modelCtorToJs(init, const FieldScope(), used);
          } else if (init is MethodInvocation &&
              init.target == null &&
              init.typeArguments == null) {
            // `_model = MyModel()` 在无 resolution 的 parseString 下会被解析成
            // MethodInvocation 而非 InstanceCreationExpression（类名即无参构造），
            // 统一按模型构造处理（见 modelCtorFromPartsJs）。
            ctorJs = modelCtorFromPartsJs(init.methodName.name,
                init.argumentList.arguments.toList(), const FieldScope(), used);
          }
          initial = ctorJs ?? 'null';
        }
        final propName = _defaultPropName(fieldName);
        props.add(_Prop(fieldName, propName, typeName, initial,
            fromArgs: ctorArgs.contains(fieldName)));
        propByField[fieldName] = propName;
      }
    }
  }

  // 方法翻译（带类表）：SnackBar 识别与动作体翻译复用翻译上下文的解析能力
  // （ctorOf/namedArg/positionalArg/jsString），不在本地另建一套。
  final parseCtx = WidgetTranslateContext(
    registry: registry,
    propByField: propByField,
    actionByMethod: actionByMethod,
    sourcePath: sourcePath,
    importResolver: importResolver,
    singletons: singletons,
  );
  // 本组件全部方法名（裸调/方法引用白名单）：initState、dispose、
  // 事件方法、builder 等都在内，methodCallExprJs 据此把命名方法引用参数
  // 包装成箭头函数。
  final methodNames = {for (final m in methods) m.name.lexeme};
  for (final member in methods) {
    final methodName = member.name.lexeme;
    final actionName = _defaultActionName(methodName);
    // 方法体是 SnackBar 形式 → 自动识别为 native 通道
    final nativeChannel =
        _snackMessage(member.body, parseCtx) != null ? 'nativeToast' : null;
    try {
      actions.add(_Action(
        methodName,
        actionName,
        nativeChannel,
        _translateActionBody(
          member.body,
          parseCtx,
          nativeChannel,
          _methodParams(member),
          used,
          hostMethods: hostMethods,
          methods: methodNames,
        ),
        params: _methodParams(member),
        isAsync: member.body.isAsynchronous,
      ));
      actionByMethod[methodName] = actionName;
    } on FormatException catch (e) {
      // 默认全量收集的方法翻译失败则跳过并提示。
      // ignore: avoid_print - 构建期日志
      print(
        '[ui_component_generator] 跳过方法 $methodName（无法静态翻译: ${e.message}）',
      );
    }
  }

  final (tree, deps, builders, builderNames, builderParams, localDecls,
      builderPreludes, usedWidgetPackages) =
      _translateBuildTree(
    buildMethod,
    propByField,
    actionByMethod,
    registry,
    sourcePath,
    importResolver,
    singletons: singletons,
  );

  return _Component(
    componentName,
    props,
    actions,
    tree,
    ctorArgs: ctorArgs,
    deps: deps,
    models: used,
    builders: builders,
    builderNames: builderNames,
    builderParams: builderParams,
    builderPreludes: builderPreludes,
    localDecls: localDecls,
    usedWidgetPackages: usedWidgetPackages,
  );
}

/// 解析「嵌套组件」：build 树里出现的本文件私有组件（_Xxx），
/// 与主组件同产物注册（export 同名工厂函数），运行时按类 type 递归渲染。
///
/// 与主组件的差异：
///   - 定位承载 build 的类：有 createState 用 State 类，否则（StatelessWidget）
///     直接用 widget 类本身；
///   - 收集 widget 构造函数的命名参数（this.x 形参）→ ctorArgs，
///     产物构造函数接受 args 并按调用点参数初始化；
///   - 私有组件默认不强制要求 build 在 State 类上。
_Component _parseNestedComponent(
  ClassDeclaration decl,
  CompilationUnit unit,
  String componentName,
  WidgetTranslatorRegistry registry,
  String sourcePath,
  String? Function(String component) importResolver, {
  required Map<String, ClassInfo> classIndex,
  SingletonResolver? singletons,
  Map<String, Map<String, String>> hostMethods = const {},
}) {
  // 承载 build 的类：widget 类 或 其 State 类
  ClassDeclaration hostClass = decl;
  final stateClassName = _stateClassName(decl);
  if (stateClassName != null) {
    for (final d in unit.declarations) {
      if (d is ClassDeclaration && d.name.lexeme == stateClassName) {
        hostClass = d;
        break;
      }
    }
  }

  // 构造参数：widget 类构造函数的 this.xxx 命名形参
  // （required this.x 在无 resolution 下是 DefaultFormalParameter 包裹
  //  FieldFormalParameter，需要解包）
  final ctorArgs = <String>[];
  for (final m in decl.members) {
    if (m is ConstructorDeclaration) {
      for (final param in m.parameters.parameters) {
        final inner = param is DefaultFormalParameter ? param.parameter : param;
        if (inner is FieldFormalParameter) ctorArgs.add(inner.name.lexeme);
      }
    }
  }

  final props = <_Prop>[];
  final actions = <_Action>[];
  final propByField = <String, String>{};
  final actionByMethod = <String, String>{};
  final methods = <MethodDeclaration>[];
  MethodDeclaration? buildMethod;

  for (final member in hostClass.members) {
    if (member is MethodDeclaration) {
      if (member.name.lexeme == 'build') {
        buildMethod = member;
        continue;
      }
      if (_skipMethod(member)) continue;
      methods.add(member);
    }
  }

  if (buildMethod == null) {
    throw FormatException('嵌套组件 $componentName 缺少 build() 方法');
  }

  // 统一类发现（与主组件同规则）：State 字段类型为主 + 构造调用兜底。
  final used = _usedClasses(
    _candidateClassNames(hostClass, methods, buildMethod),
    classIndex,
    registry.registeredTypes,
  );

  // 字段收集：基础类型 / 类类型字段进 JS 属性（对象字段 this._x）
  for (final member in hostClass.members) {
    if (member is FieldDeclaration) {
      for (final variable in member.fields.variables) {
        final fieldName = variable.name.lexeme;
        final typeName = _fieldTypeName(member, variable);
        if (member.isStatic) continue;
        final erased = _eraseType(typeName);
        final isBasic = _isBasicType(typeName);
        final jsRuntime = _jsRuntimeTypes.contains(erased);
        final cls = used[erased];
        if (!isBasic && cls == null && !jsRuntime) {
          // ignore: avoid_print - 构建期日志
          print(
            '[ui_component_generator] 嵌套组件跳过字段 $fieldName（类型 $typeName 不可翻译）',
          );
          continue;
        }
        final fromArgs = ctorArgs.contains(fieldName);
        String initial;
        if (isBasic) {
          initial = _renderLiteral(variable.initializer) ??
              _defaultInitial(typeName);
        } else if (jsRuntime) {
          initial = variable.initializer == null
              ? 'null'
              : (_jsRuntimeCtor(erased) ?? 'null');
        } else {
          final init = variable.initializer;
          String? ctorJs;
          if (init is InstanceCreationExpression) {
            ctorJs = modelCtorToJs(init, const FieldScope(), used);
          } else if (init is MethodInvocation &&
              init.target == null &&
              init.typeArguments == null) {
            // `_model = MyModel()` 在无 resolution 的 parseString 下会被解析成
            // MethodInvocation 而非 InstanceCreationExpression（类名即无参构造），
            // 统一按模型构造处理（见 modelCtorFromPartsJs）。
            ctorJs = modelCtorFromPartsJs(init.methodName.name,
                init.argumentList.arguments.toList(), const FieldScope(), used);
          }
          initial = ctorJs ?? 'null';
        }
        final propName = _defaultPropName(fieldName);
        props.add(_Prop(fieldName, propName, typeName, initial,
            fromArgs: fromArgs));
        propByField[fieldName] = propName;
      }
    }
  }

  final parseCtx = WidgetTranslateContext(
    registry: registry,
    propByField: propByField,
    actionByMethod: actionByMethod,
    sourcePath: sourcePath,
    importResolver: importResolver,
    singletons: singletons,
  );
  // 本组件全部方法名（裸调/方法引用白名单）：initState、dispose、
  // 事件方法、builder 等都在内，methodCallExprJs 据此把命名方法引用参数
  // 包装成箭头函数。
  final methodNames = {for (final m in methods) m.name.lexeme};
  for (final member in methods) {
    final methodName = member.name.lexeme;
    final actionName = _defaultActionName(methodName);
    final nativeChannel =
        _snackMessage(member.body, parseCtx) != null ? 'nativeToast' : null;
    try {
      actions.add(_Action(
        methodName,
        actionName,
        nativeChannel,
        _translateActionBody(
          member.body,
          parseCtx,
          nativeChannel,
          _methodParams(member),
          used,
          hostMethods: hostMethods,
          methods: methodNames,
        ),
        params: _methodParams(member),
        isAsync: member.body.isAsynchronous,
      ));
      actionByMethod[methodName] = actionName;
    } on FormatException catch (e) {
      // ignore: avoid_print - 构建期日志
      print(
        '[ui_component_generator] 嵌套组件跳过方法 $methodName（无法静态翻译: ${e.message}）',
      );
    }
  }

  final (tree, deps, builders, builderNames, builderParams, localDecls,
      builderPreludes, usedWidgetPackages) =
      _translateBuildTree(
    buildMethod,
    propByField,
    actionByMethod,
    registry,
    sourcePath,
    importResolver,
    singletons: singletons,
  );

  return _Component(
    componentName,
    props,
    actions,
    tree,
    ctorArgs: ctorArgs,
    deps: deps,
    models: used,
    builders: builders,
    builderNames: builderNames,
    builderParams: builderParams,
    builderPreludes: builderPreludes,
    localDecls: localDecls,
    usedWidgetPackages: usedWidgetPackages,
  );
}

// ---------------------------------------------------------------------------
// 注解 / 类解析
// ---------------------------------------------------------------------------

/// JS 运行时已有同名类的 Dart 类型（翻译成 JS 同名构造，如
/// `ScrollController` → `new ScrollController()`）：字段不再跳过，方法/属性
/// 一比一翻译（`addListener` / `jumpTo` / `offset` / `position` 由 JS 侧
/// 实例提供，宿主按 id 绑定真实对象）。
const Set<String> _jsRuntimeTypes = {'ScrollController', 'TextEditingController'};

/// JS 运行时类型的构造表达式；非运行时类型返回 null。
String? _jsRuntimeCtor(String erased) =>
    _jsRuntimeTypes.contains(erased) ? 'new $erased()' : null;

/// 字段默认状态名：一比一，保持 Dart 字段原名（_count → _count）。
String _defaultPropName(String fieldName) => fieldName;

/// 方法默认事件名：一比一，保持 Dart 方法原名（inc → inc）。
String _defaultActionName(String methodName) => methodName;

/// 基础类型（可翻译为 JS 初始值）：无注解时自动进 state。
bool _isBasicType(String typeName) {
  final t = typeName.trim();
  if (t.endsWith('?')) return _isBasicType(t.substring(0, t.length - 1));
  return switch (t) {
    'int' || 'double' || 'num' || 'String' || 'bool' || 'dynamic' => true,
    _ => false,
  };
}

/// 跳过 getter / setter / static 方法（build 在收集处单独处理；
/// initState/dispose 等 State 生命周期方法**全量生成**，由运行时在对应生命周期回调）。
bool _skipMethod(MethodDeclaration member) {
  if (member.isGetter || member.isSetter) return true;
  if (member.isStatic) return true;
  return false;
}

String? _stateClassName(ClassDeclaration widgetClass) {
  for (final m in widgetClass.members) {
    if (m is MethodDeclaration && m.name.lexeme == 'createState') {
      final e = _methodExpression(m);
      if (e is InstanceCreationExpression) {
        return e.constructorName.type.name2.lexeme;
      }
      // `_MyCardState()`：下划线开头不是合法类型名，语法解析器会当成
      // MethodInvocation（parseString 无 resolution 时的行为），这里统一处理。
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

Annotation? _findAnnotation(List<Annotation> metadata, String simpleName) {
  for (final a in metadata) {
    final name = a.name;
    if (name is SimpleIdentifier && name.name == simpleName) return a;
    if (name is PrefixedIdentifier && name.identifier.name == simpleName) {
      return a;
    }
  }
  return null;
}

/// 类是否声明了带 @HostInjected 的方法（static 宿主注入能力）。
bool _classHasHostInjectedMethod(ClassDeclaration d) {
  for (final m in d.members.whereType<MethodDeclaration>()) {
    if (_findAnnotation(m.metadata, 'HostInjected') != null) return true;
  }
  return false;
}

/// 收集宿主注入方法表：`类名 → {方法名 → 通道名}`（见 @HostInjected）；
/// 顶层函数挂在空串 key 下（`'' → {函数名 → 通道名}`）。
///
/// 扫描本文件 + import 源文件（调用点能写出来，就必然 import 得到）；
/// 只有 [HostMethodDecl.usable] 的声明进表——与注册清单（host_register_builder）
/// 用同一个扫描器、同一个判定，保证「翻译了的都注册了」，不因两套逻辑分叉。
///
/// 供翻译上下文把调用点整体替换为 `__jsui.host("通道", 参数载荷)`
/// （参数个数、是否具名、返回值类型都不参与判定）。
Map<String, Map<String, String>> _buildHostMethods(
  CompilationUnit unit,
  String sourcePath,
) {
  final out = <String, Map<String, String>>{};
  void scan(CompilationUnit u) {
    scanHostMethods(u, (h) {
      if (!h.usable) return;
      (out[h.owner] ??= {})[h.name] = h.channel;
    });
  }

  scan(unit);
  for (final file in _resolveImportFiles(unit, sourcePath)) {
    final f = File(file);
    if (!f.existsSync()) continue;
    scan(parseString(content: f.readAsStringSync()).unit);
  }
  return out;
}

/// 判断本文件里名为 [className] 的类是否带 @UIComponentIgnore。
/// 带注解 → 不参与连带转换（生成器跳过翻译，运行时原生注入）。
bool _isIgnoredClass(CompilationUnit unit, String className) {
  for (final d in unit.declarations) {
    if (d is ClassDeclaration && d.name.lexeme == className) {
      return _findAnnotation(d.metadata, 'UIComponentIgnore') != null;
    }
  }
  return false;
}

String? _positionalString(Annotation a, int index) {
  final args = a.arguments;
  if (args == null || index >= args.arguments.length) return null;
  final e = args.arguments[index];
  return e is StringLiteral ? e.stringValue : null;
}

String? _renderLiteral(Expression? e) {
  if (e == null) return null;
  if (e is StringLiteral) return jsString(e.stringValue ?? '');
  if (e is IntegerLiteral) return e.value?.toString();
  if (e is DoubleLiteral) return e.value.toString();
  if (e is BooleanLiteral) return e.value.toString();
  if (e is BinaryExpression) {
    final l = _renderLiteral(e.leftOperand);
    final r = _renderLiteral(e.rightOperand);
    if (l != null && r != null) return '($l ${e.operator.lexeme} $r)';
  }
  return null;
}

String _defaultInitial(String typeName) {
  if (typeName.contains('String')) return "''";
  if (typeName.contains('bool')) return 'false';
  return '0';
}

// ---------------------------------------------------------------------------
// 方法体静态翻译 → JS
// ---------------------------------------------------------------------------

String _translateActionBody(
  FunctionBody body,
  WidgetTranslateContext ctx,
  String? nativeChannel,
  List<String> params,
  Map<String, ClassInfo> classes, {
  Map<String, Map<String, String>> hostMethods = const {},
  Set<String> methods = const {},
}) {
  // 组件动作的可用引用：State 字段（ctx.propByField）+ 方法形参。表达式/
  // 语句统一交给 class_translator.exprStmtToJs（以 FieldScope 为键），与模型
  // 方法体翻译共用同一套逻辑。
  // params 用**可变集合**：方法体内声明的局部变量（`String? name = ...`）
  // 边翻译边登记，后续语句里的 `$name` / `name` 才能解析。
  final locals = <String>{...params};
  final scope = FieldScope(
    propByField: ctx.propByField,
    params: locals,
    hostMethods: hostMethods,
    methods: methods,
  );
  if (nativeChannel != null) {
    final msg = _snackMessage(body, ctx);
    if (msg == null) {
      throw FormatException(
          'native 动作需要方法体是 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("消息"))) 形式');
    }
    // 出口统一走 `__jsui.host`（唯一 JS→宿主入口）；消息体给具名参数
    // {message}，宿主内建 `nativeToast` 处理器用 navigatorKey 取 context
    // 弹 SnackBar。不要再裸调 sendMessage，否则宿主收不到。
    return '__jsui.host(${jsString(nativeChannel)}, { message: $msg });';
  }

  // 逐语句翻译：setState(...) 展开、await Future.delayed(...)、
  // super.xxx() 忽略、无法翻译的语句降级跳过。
  final stmts = <String>[];
  if (body is ExpressionFunctionBody) {
    final t = _translateExprStatement(body.expression, scope, classes);
    if (t != null) stmts.add(t);
  } else if (body is BlockFunctionBody) {
    stmts.add(_translateStmtList(body.block.statements, scope, classes, locals));
  }
  if (stmts.isEmpty) return '/* 空方法体 */';
  return stmts.join(' ');
}

/// 翻译语句列表（Block 内容或 if 分支体），无法翻译的语句降级跳过。
/// 支持 ExpressionStatement / VariableDeclarationStatement / IfStatement（含
/// else，条件走 exprToJs，故 `if (mounted) setState(...)` 一比一翻译）。
String _translateStmtList(
  List<Statement> stmts,
  FieldScope scope,
  Map<String, ClassInfo> classes,
  Set<String> locals,
) {
  final out = <String>[];
  for (final s in stmts) {
    if (s is ExpressionStatement) {
      final e = s.expression;
      // super.initState() 等 super 调用：JS 无 super 语义，忽略
      if (e is MethodInvocation && e.target is SuperExpression) continue;
      final t = _translateExprStatement(e, scope, classes);
      if (t != null) {
        out.add(t);
      } else {
        // 不静默：丢语句会让 JS 版逻辑悄悄比 Dart 版少一截。
        log.warning('[ui_component_generator] 语句无法翻译，已在 JS 产物中'
            '丢弃：${e.toSource()}');
      }
    } else if (s is VariableDeclarationStatement) {
      // 局部变量声明 `String? name = await X.y();` → `var name = ...;`，
      // 名字登记进 scope，后续语句（含插值）可直接引用。
      for (final v in s.variables.variables) {
        final init = v.initializer == null
            ? 'undefined'
            : rhsToJs(v.initializer!, scope, classes);
        if (init == null) {
          // 变量没声明 → 后面引用它的语句（含插值）会连带失效，必须出声。
          log.warning('[ui_component_generator] 局部变量声明无法翻译，已在 JS '
              '产物中丢弃：${s.toSource()}');
          continue;
        }
        locals.add(v.name.lexeme);
        out.add('var ${v.name.lexeme} = $init;');
      }
    } else if (s is IfStatement) {
      final condJs = exprToJs(s.expression, scope, classes);
      if (condJs == null) {
        log.warning('[ui_component_generator] if 条件无法翻译，已在 JS 产物中'
            '丢弃：${s.toSource()}');
        continue;
      }
      final thenStmts = s.thenStatement is Block
          ? (s.thenStatement as Block).statements
          : [s.thenStatement];
      var js =
          'if ($condJs) { ${_translateStmtList(thenStmts, scope, classes, locals)} }';
      final els = s.elseStatement;
      if (els != null) {
        final elseStmts = els is Block ? els.statements : [els];
        js +=
            ' else { ${_translateStmtList(elseStmts, scope, classes, locals)} }';
      }
      out.add(js);
    }
  }
  return out.join(' ');
}

/// 翻译一条表达式语句：setState((){...}) / await Future.delayed / 其余走
/// class_translator.exprStmtToJs（赋值 / 自增 / `_model.inc()` 对象方法调用等）。
///
/// setState 按 Dart 原封翻译：`setState(() => _taps++)` →
/// `this.setState(function(){ this._taps += 1; });`。
String? _translateExprStatement(
  Expression e,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  if (e is MethodInvocation &&
      e.methodName.name == 'setState' &&
      e.argumentList.arguments.length == 1) {
    final fn = e.argumentList.arguments.first;
    if (fn is FunctionExpression) {
      final bodyJs = _translateFunctionBodyJs(fn.body, scope, classes);
      if (bodyJs == null) return 'this.setState(function(){});';
      return 'this.setState(function(){ $bodyJs });';
    }
    return null;
  }
  return exprStmtToJs(e, scope, classes);
}

/// 翻译函数体（setState 回调等）：表达式体或块体，逐语句翻译。
String? _translateFunctionBodyJs(
  FunctionBody body,
  FieldScope scope,
  Map<String, ClassInfo> classes,
) {
  if (body is ExpressionFunctionBody) {
    return exprStmtToJs(body.expression, scope, classes);
  }
  if (body is BlockFunctionBody) {
    final parts = <String>[];
    for (final st in body.block.statements) {
      if (st is ExpressionStatement) {
        final t = exprStmtToJs(st.expression, scope, classes);
        if (t != null) parts.add(t);
      }
    }
    return parts.isEmpty ? null : parts.join(' ');
  }
  return null;
}



/// 方法形式参数名列表（解 DefaultFormalParameter 包裹）。
List<String> _methodParams(MethodDeclaration m) => [
      for (final p in m.parameters!.parameters)
        (p is DefaultFormalParameter ? p.parameter : p).name?.lexeme ?? '',
    ];

/// 提取 SnackBar 消息字符串
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

// ---------------------------------------------------------------------------
// 产物路径推导：组件名 → 依赖产物 jsAsset
// ---------------------------------------------------------------------------

/// 源文件路径 → 产物路径（与 build.yaml 的 build_extensions 一致）：
/// `lib/a/b.dart` → `patch/a/b.js`（**直接镜像 lib 路径、文件名与源文件
/// 同名**，不预设 `components` 之类固定目录名，也不区分组件/模型）。
String _productPath(String sourcePath) {
  if (!sourcePath.startsWith('lib/')) return sourcePath;
  final rel = sourcePath.substring('lib/'.length); // a/b.dart
  if (!rel.endsWith('.dart')) return sourcePath;
  return 'patch/${rel.substring(0, rel.length - '.dart'.length)}.js';
}

/// package 模块产物路径：`patch/<package>.js`（**一个 package 一个文件**）。
///
/// 这类产物是 **package 级**（`flutter` / `provider` 等，与 lib 源码目录无关），
/// 因此直接落在 patch 根下；而组件/模型产物落在 `patch/` 下镜像 lib 源码路径。
/// 同包的 widget 工厂/逻辑组件集中在一个文件里，避免按类型拆成大量小文件难以
/// 维护，也天然只保留一份实现。
String _packageModulePath(String package) => 'patch/$package.js';

/// 共享结点工厂 `__h` 的宿主 package：并入基础包 flutter 的模块
/// （`patch/flutter.js`）。其它 package 模块与组件产物统一从它
/// `import { __h }`，使 `__h` 全局只定义一次。
const String _nodeHelperPackage = 'flutter';

/// widget 模块 builder 的**种子输入默认路径**（构建期固定文件，不含运行时代码）。
///
/// build_runner 的输出名必须在 buildExtensions 里静态声明，无法按构建期发现
/// 的类型动态命名，因此把「全部 package 模块产物」挂在本文件下，包清单由
/// [_registeredWidgetPackages] 静态推导。
///
/// 该路径可由使用方 `build.yaml` 的 `options: { seed_file: ... }` 覆盖
/// （见 [_seedPathFrom]）；使用方**必须**在包内提供该种子文件。
const String _defaultSeedPath = 'lib/js_widgets.dart';

/// 从 builder options 读取种子输入路径：`options: { seed_file: <path> }`，
/// 缺省或非法值回退 [_defaultSeedPath]。
String _seedPathFrom(BuilderOptions options) {
  final value = options.config['seed_file'];
  if (value is String && value.isNotEmpty) return value;
  return _defaultSeedPath;
}

/// 已注册 widget 类型 → (package → {type})：由 translator 注册表推导，
/// 作为 package 模块产物清单（每个包一个文件）的唯一来源。
Map<String, Set<String>> _registeredWidgetPackages() {
  final registry = WidgetTranslatorRegistry();
  registerBuiltinTranslators(registry);
  final out = <String, Set<String>>{};
  for (final t in registry.registeredTypes) {
    final tr = registry.lookup(t);
    if (tr == null) continue;
    (out[tr.packageName] ??= <String>{}).addAll(tr.jsonTypes);
  }
  return out;
}

/// widget 模块 builder：把**每个 package** 的全部已注册 widget 类型产出为
/// 一个共享 JS 模块 `assets/<package>.js`（工厂函数 + 逻辑组件类，全局唯一
/// 一份，消除各组件产物里内联同类工厂函数造成的重复与文件爆炸）。
///
/// 输出挂在种子输入 [seedPath] 下（默认 [_defaultSeedPath]，可由使用方
/// `build.yaml` 的 `options: { seed_file: ... }` 覆盖）；输出名从
/// [_registeredWidgetPackages] 静态推导，构建时按包名渲染整包即可。
///
/// **使用方必须提供该种子文件**——本 builder 无降级路径，缺少种子输入即
/// 不产出任何 package 模块，组件产物的 import 会因此悬空。
class WidgetModuleBuilder implements Builder {
  const WidgetModuleBuilder({this.seedPath = _defaultSeedPath});

  /// 种子输入路径（见 [_defaultSeedPath]），可由 builder options 覆盖。
  final String seedPath;

  @override
  Map<String, List<String>> get buildExtensions {
    final pkgs = <String>{
      // `__h` 宿主（基础包 flutter）即使未注册任何 flutter widget 也要产出。
      _nodeHelperPackage,
      ..._registeredWidgetPackages().keys,
    }.toList()..sort();
    return {
      '^$seedPath': [for (final p in pkgs) _packageModulePath(p)],
    };
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    final packages = _registeredWidgetPackages();
    for (final out in buildStep.allowedOutputs) {
      // 输出路径形如 patch/<package>.js → 反推 package
      final segs = out.path.split('/');
      if (segs.length != 2 || segs[0] != 'patch' || !segs[1].endsWith('.js')) {
        continue;
      }
      final pkg = segs[1].substring(0, segs[1].length - '.js'.length);
      await buildStep.writeAsString(
        out,
        _renderPackageModule(pkg, packages[pkg] ?? const <String>{}),
      );
    }
  }
}

/// 收集表达式树里全部模型构造调用名（与类发现共用：State 字段类型 + 构造调用）。
class _CtorCollector extends RecursiveAstVisitor<void> {
  final names = <String>{};

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    names.add(node.constructorName.type.name2.lexeme);
    super.visitInstanceCreationExpression(node);
  }

  /// 无 `new`/`const` 的构造调用（parseString 下是 MethodInvocation）：
  /// `MyModel()` / `(_) => MyModel()` 里的模型构造。仅收
  /// UpperCamel 且无 target/泛型的形态（与 [_fieldTypeName] 同启发式），
  /// widget 构造（Text/Column 等）也会被收进来，但与类表求交后自然丢弃。
  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target == null && node.typeArguments == null) {
      final n = node.methodName.name;
      if (n.isNotEmpty && n[0] == n[0].toUpperCase()) names.add(n);
    }
    super.visitMethodInvocation(node);
  }
}

/// 组件文件的业务 import → lib 相对 dart 路径列表。
/// 相对导入优先；package: 跳过 dart:/flutter 与注解包（ui_component / generator）。
List<String> _resolveImportFiles(CompilationUnit unit, String sourcePath) {
  final slash = sourcePath.lastIndexOf('/');
  final dir = slash >= 0 ? sourcePath.substring(0, slash + 1) : '';
  final out = <String>[];
  for (final d in unit.directives.whereType<ImportDirective>()) {
    final uri = d.uri.stringValue;
    if (uri == null) continue;
    // 精确匹配：'package:flutter/' 才是 SDK 包，'package:my_app/' 是业务包
    if (uri.startsWith('package:flutter/') ||
        uri.startsWith('package:ui_component/') ||
        uri.startsWith('package:ui_component_generator/') ||
        uri.startsWith('dart:')) {
      continue;
    }
    if (uri.startsWith('package:')) {
      final idx = uri.indexOf('/');
      if (idx <= 0 || idx >= uri.length - 1) continue;
      final rel = uri.substring(idx + 1);
      if (rel.endsWith('.dart')) out.add('lib/$rel');
      continue;
    }
    final rel = _relativeToLib(uri, dir);
    if (rel != null && rel.endsWith('.dart')) out.add('lib/$rel');
  }
  return out;
}

/// 两个产物绝对路径 → 相对路径（相对第一个产物所在目录）。
/// 如 'patch/foo_component.js' → 'patch/sub/bar_component.js'
/// 得 'sub/bar_component.js'；跨目录时含 '../'。
String _relativeProduct(String from, String to) {
  final fromDir = from.substring(0, from.lastIndexOf('/') + 1);
  final fromSegs = fromDir.split('/').where((p) => p.isNotEmpty).toList();
  final toSegs = to.split('/').where((p) => p.isNotEmpty).toList();
  // 公共前缀长度
  var common = 0;
  while (common < fromSegs.length &&
      common < toSegs.length - 1 &&
      fromSegs[common] == toSegs[common]) {
    common++;
  }
  final ups = List.filled(fromSegs.length - common, '..');
  final downs = toSegs.skip(common).toList();
  return [...ups, ...downs].join('/');
}

/// 扫描当前文件 import 的源文件，收集「有 JS 产物的组件类名 → 产物路径」。
///
/// 与 [_parseNestedComponent] 的连带转换规则一致，「有产物」判定为：
///   - 类带 @UIComponent 注解；或
///   - 私有类（_Xxx）且声明了 build() 方法。
/// 按**类名**绑定（而非「第一条 import」），多 import 文件不会串台；
/// 命中即让 build 树里的 Component 节点渲染成工厂调用并 import 该产物。
Map<String, String> _resolveImportedComponentProducts(
  CompilationUnit unit,
  String sourcePath,
) {
  final out = <String, String>{};
  for (final file in _resolveImportFiles(unit, sourcePath)) {
    final f = File(file);
    if (!f.existsSync()) continue;
    final parsed = parseString(content: f.readAsStringSync());
    for (final decl in parsed.unit.declarations.whereType<ClassDeclaration>()) {
      final name = decl.name.lexeme;
      final annotated = _findAnnotation(decl.metadata, 'UIComponent') != null;
      final privateWithBuild =
          name.startsWith('_') && _hasBuildMethod(decl);
      if (!annotated && !privateWithBuild) continue;
      out[name] = _productPath(file);
    }
  }
  return out;
}

/// 类（或其 State 类）是否声明了 build() 方法。
bool _hasBuildMethod(ClassDeclaration decl) {
  for (final m in decl.members) {
    if (m is MethodDeclaration && m.name.lexeme == 'build') return true;
  }
  final stateName = _stateClassName(decl);
  return stateName != null;
}

/// 相对导入 uri（'foo.dart' / './foo.dart' / '../x.dart'）→ lib 相对路径。
String? _relativeToLib(String uri, String dir) {
  final segments = <String>[];
  if (dir.startsWith('lib/')) {
    // dir 含尾斜杠（'lib/components/'），去掉尾 / 再入段
    final rel = dir.substring('lib/'.length);
    if (rel.endsWith('/')) {
      segments.add(rel.substring(0, rel.length - 1));
    } else {
      segments.add(rel);
    }
  } else {
    segments.add(dir.endsWith('/') ? dir.substring(0, dir.length - 1) : dir);
  }
  for (final part in uri.split('/')) {
    if (part == '.' || part.isEmpty) continue;
    if (part == '..') {
      if (segments.isNotEmpty) segments.removeLast();
    } else {
      segments.add(part);
    }
  }
  return segments.join('/');
}

// ---------------------------------------------------------------------------
// build()：widget 树 → 节点树（策略分发到 WidgetTranslator）
// ---------------------------------------------------------------------------

(Object?, Set<String>, List<Object?>, List<String>, List<String?>, List<String>, List<String>,
        Map<String, Set<String>>)
      _translateBuildTree(
  MethodDeclaration buildMethod,
  Map<String, String> propByField,
  Map<String, String> actionByMethod,
  WidgetTranslatorRegistry registry,
  String sourcePath,
  String? Function(String component) importResolver, {
  SingletonResolver? singletons,
}) {
  final e = _methodExpression(buildMethod);
  if (e == null) {
    throw FormatException('build() 需要返回 widget 树（return 或 =>）');
  }
  final ctx = WidgetTranslateContext(
    registry: registry,
    propByField: propByField,
    actionByMethod: actionByMethod,
    sourcePath: sourcePath,
    importResolver: importResolver,
    singletons: singletons,
  );
  // build() return 前的局部变量声明（`final isAdult = <expr>;`）：
  // 收集名字进 ctx 局部作用域（树里直接引用），initializer 翻译成 JS 声明语句。
  final localDecls = <String>[];
  final body = buildMethod.body;
  if (body is BlockFunctionBody) {
    for (final st in body.block.statements) {
      if (st is ReturnStatement) break;
      if (st is VariableDeclarationStatement) {
        for (final v in st.variables.variables) {
          final name = v.name.lexeme;
          ctx.addLocal(name);
          final js = v.initializer == null
              ? 'undefined'
              : ctx.jsDataExpr(v.initializer!);
          localDecls.add('    var $name = $js;');
        }
      } else if (st is ExpressionStatement) {
        // build 内 Dart 日志 → JS 原生日志方法（运行时注入 console 对象，
        // 桥到 log 服务）：debugPrint → console.debug、print → console.log。
        // 参数走 jsDataExpr（插值/字段/模型属性）。
        final ex = st.expression;
        if (ex is MethodInvocation && ex.target == null) {
          final name = ex.methodName.name;
          if (name == 'debugPrint' || name == 'print') {
            final args = ex.argumentList.arguments;
            final argJs = args.isEmpty ? '""' : ctx.jsDataExpr(args.first);
            final method = name == 'debugPrint' ? 'debug' : 'log';
            localDecls.add('    console.$method($argJs);');
          }
        }
      }
    }
  }
  return (
    ctx.translate(e),
    {...ctx.dependencies},
    ctx.builderTrees,
    ctx.builderNames,
    ctx.builderParams,
    localDecls,
    ctx.builderPreludes,
    ctx.usedWidgetPackages,
  );
}

// ---------------------------------------------------------------------------
// 产物渲染
// ---------------------------------------------------------------------------

String _renderJs(
  List<_Component> components,
  String sourcePath,
  WidgetTranslatorRegistry registry,
  String? Function(String component) importResolver, {
  SingletonResolver? singletons,
  List<ClassInfo> sameFileSingletonInfos = const [],
  Map<String, Map<String, String>> hostMethods = const {},
}) {
  // 统一类表按「同文件 inline / 跨文件 import」分组渲染：
  //  - 同文件模型（sourceFile == 当前组件文件）→ 产物内 inline class（不 export，
  //    与 Dart 源文件里同文件使用一致）；
  //  - 跨文件模型（其它文件 import 的普通类）→ import 该文件的同名 JS 产物，
  //    模型全局共享一份（export class），运行时模块加载器按相对路径加载；
  //  - 同文件静态单例类 → inline const（renderStaticConst）。
  final allModels = <String, ClassInfo>{};
  final inlineModels = <String, ClassInfo>{};
  for (final c in components) {
    for (final e in c.models.entries) {
      if (e.value.sourceFile == sourcePath) {
        inlineModels[e.key] = e.value;
      } else {
        allModels[e.key] = e.value;
      }
    }
  }
  final inlineSingletons = <String, ClassInfo>{
    for (final s in sameFileSingletonInfos) s.name: s,
  };

  // 头部（注释 + import 区）：widget 模块 import 依赖「实际用到的类型」，
  // 只能在各组件渲染完成后得知，所以先渲染 body 再拼装 import，见函数末尾。
  final head = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT EDIT')
    ..writeln('// 由 ui_component_generator 从 $sourcePath 自动生成')
    ..writeln('// 重新生成：dart run build_runner build')
    ..writeln();

  // 跨文件模型：import（ES module 语法；flutter_js 无原生 module 支持，
  // 运行时 JsRuntimeManager 模块加载器会按相对路径解析并预置 __modules）
  final ownProduct = _productPath(sourcePath);
  // 跨文件静态单例类：import（export const 单例对象，运行时注入 __modules 共享）
  for (final cls in singletons?.used ?? <String>[]) {
    final src = singletons?.sourceFileOf(cls);
    if (src == null || src == sourcePath) continue;
    final rel = _relativeProduct(ownProduct, _productPath(src));
    head.writeln("import { $cls } from '$rel';");
  }
  for (final m in allModels.values) {
    final rel = _relativeProduct(ownProduct, _productPath(m.sourceFile));
    head.writeln("import { ${m.name} } from '$rel';");
  }

  // 跨文件组件：build 树里 Component 兜底、且产物在其他文件的依赖组件，
  // 同样用 ES module import（'bar_component.js' 相对本产物目录）。
  // 模块级 import 让依赖关系直观可见；Component 节点据此渲染成对应工厂调用。
  // 同文件组件（importResolver 返回本文件产物名）是 inline export class，
  // 不需要 import；null（无 JS 产物的 lib 普通组件）走原生注入。
  final ownName = ownProduct.substring(ownProduct.lastIndexOf('/') + 1);
  final importedComponents = <String>{};
  for (final c in components) {
    for (final dep in c.deps) {
      if (importedComponents.contains(dep)) continue;
      final rel = importResolver(dep);
      if (rel == null || rel == ownName) continue;
      importedComponents.add(dep);
      head.writeln("import { $dep } from '$rel';");
    }
  }

  // body：模型/单例/组件类主体（不动 import 区；末尾拼装）。
  final b = StringBuffer();

  // 各 package 实际用到的 widget 类型（渲染期收集）：末尾据此为每个 package
  // 拼一条 import（`import { Text } from '../flutter.js'`）。
  final usedWidgets = <String, Set<String>>{};

  // 同文件模型：inline class（不 export，本产物内共享）。统一由
  // class_translator.renderClassDecl 翻译（含字段/方法/getter/extends
  // NotifierBase），与跨文件模型、模型产物共用同一处理器。
  for (final m in inlineModels.values) {
    b
      ..writeln()
      ..writeln('// 模型 ${m.name}（同文件，仅本产物内可见）')
      ..writeln(renderClassDecl(m, const {}, exported: false,
          hostMethods: hostMethods));
  }

  // 同文件 static 单例类：inline export const（exported: true —— 运行时
  // 预处理层按 export 名收集并注册进 __modules，跨文件组件才能
  // `import { MyColors }` 解构拿到；仅 const 会被收集器漏掉）
  if (inlineSingletons.isNotEmpty) {
    final ctx = WidgetTranslateContext(
      registry: registry,
      propByField: const {},
      actionByMethod: const {},
      sourcePath: sourcePath,
    );
    for (final cls in inlineSingletons.values) {
      b
        ..writeln()
        ..writeln('// 同文件静态单例类 ${cls.name}（export，供跨文件 import）')
        ..writeln(renderStaticConst(
          cls,
          valueRenderer: (f) => _singletonFieldValue(f.initializer, ctx),
          exported: true,
        ));
    }
  }

  for (final c in components) {
    // 翻译阶段（含三目/if/for 内联渲染）已收集的类型并入总表；
    // 渲染阶段 ctx 会再次收集主树/builders 用到的类型。
    _mergeUsedWidgets(usedWidgets, c.usedWidgetPackages);
    b.writeln();
    // 组件类（不导出，避免与同名工厂冲突）：由本产物的工厂函数实例化。
    b.writeln('class ${c.name}Component {');
    final isNested = c.ctorArgs.isNotEmpty;
    b.writeln(isNested ? '  constructor(args) {' : '  constructor() {');
    for (final p in c.props) {
      if (p.fromArgs) {
        b.writeln(
          '    this.${p.name} = (args && args.${p.name} !== undefined) '
          '? args.${p.name} : ${p.initial};',
        );
      } else {
        b.writeln('    this.${p.name} = ${p.initial};');
      }
    }
    b.writeln('  }');
    // 方法一比一：class 方法（async 方法带 async 前缀，await 仅限 async 内）
    for (final a in c.actions) {
      final fn = a.isAsync ? 'async ' : '';
      b.writeln('  $fn${a.name}(${a.params.join(', ')}) { ${a.bodyJs} }');
    }
    // build：返回 widget 树（由 WidgetTranslateContext 渲染为 JS 构造调用）
    b.writeln('  build() {');
    final ctx = WidgetTranslateContext(
      registry: registry,
      propByField: const {},
      actionByMethod: const {},
      sourcePath: sourcePath,
      importResolver: importResolver,
    );
    for (final d in c.localDecls) {
      b.writeln(d);
    }
    b.writeln('    return ${ctx.renderJs(c.tree, 2)};');
    b.writeln('  }');
    // 响应式 builder 闭包子树（ListenableBuilder/Consumer）→ 实例方法
    // `_lbBuilderN()` / `_consumerBuilderN(value)`。运行时时模型 notify 后
    // 重新调用本方法拿到最新子树（含已求值的 this._model.n / value.count），
    // 做「仅此节点」的局部重建。方法名与形参由 translator 声明。
    for (var i = 0; i < c.builders.length; i++) {
      final name = i < c.builderNames.length ? c.builderNames[i] : '_lbBuilder$i';
      final param = i < c.builderParams.length ? c.builderParams[i] : null;
      final prelude =
          i < c.builderPreludes.length ? c.builderPreludes[i] : '';
      b.writeln('  $name(${param ?? ''}) {');
      if (prelude.isNotEmpty) b.writeln('      $prelude');
      b.writeln('      return ${ctx.renderJs(c.builders[i], 2)};');
      b.writeln('  }');
    }
    b.writeln('}');
    // 对外工厂：与 widget 模块契约一致，返回 element（type = 组件类）。
    // 运行时 mountRoot / 嵌套引用都以工厂调用取 element（不再 new 类）。
    b.writeln('export function ${c.name}(props, children) {');
    b.writeln('  return __h(${c.name}Component, props, children);');
    b.writeln('}');
    _mergeUsedWidgets(usedWidgets, ctx.usedWidgetPackages);
  }

  // 按 package 拼装模块 import：`import { Text, Column } from '../flutter.js'`。
  // 一个 package 一个文件（全局一份、无重复），故每个 package 一条 import；
  // 结点工厂 `__h` 组件工厂恒需（`return __h(Component, ...)`），并入其宿主
  // package（flutter）那一条，避免单独 import。
  final importsByPackage = <String, Set<String>>{
    _nodeHelperPackage: {'__h'},
  };
  for (final entry in usedWidgets.entries) {
    (importsByPackage[entry.key] ??= <String>{}).addAll(entry.value);
  }
  final importLines = <String>[
    for (final entry in importsByPackage.entries)
      "import { ${(entry.value.toList()..sort()).join(', ')} } from "
          "'${_relativeProduct(ownProduct, _packageModulePath(entry.key))}';",
  ]..sort();
  for (final line in importLines) {
    head.writeln(line);
  }

  b.writeln();
  return head.toString() + b.toString();
}

/// 合并「用到的 widget 类型」：dst[package] ∪= src[package]。
void _mergeUsedWidgets(
  Map<String, Set<String>> dst,
  Map<String, Set<String>> src,
) {
  if (src.isEmpty) return;
  for (final e in src.entries) {
    (dst[e.key] ??= <String>{}).addAll(e.value);
  }
}

/// 非组件文件产物渲染：普通类 → `export class`；静态单例类 → `export const`
/// （均为 ES module，运行时加载器收集导出名后供组件产物 import）。
String _renderModelJs(
  List<ClassInfo> models,
  List<ClassInfo> singletons,
  String sourcePath,
  WidgetTranslatorRegistry registry,
  Map<String, Map<String, String>> hostMethods,
) {
  final b = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT EDIT')
    ..writeln('// 模型模块：由 ui_component_generator 从 $sourcePath 生成')
    ..writeln('// export class / export const 供组件产物 import（运行时按相对路径加载）')
    ..writeln();
  for (final m in models) {
    b
      ..writeln('// 模型 ${m.name}')
      ..writeln(renderClassDecl(m, const {}, exported: true,
          hostMethods: hostMethods));
  }
  if (singletons.isNotEmpty) {
    final ctx = WidgetTranslateContext(
      registry: registry,
      propByField: const {},
      actionByMethod: const {},
      sourcePath: sourcePath,
    );
    for (final cls in singletons) {
      b
        ..writeln()
        ..writeln('// 静态单例类 ${cls.name}')
        ..writeln(renderStaticConst(
          cls,
          valueRenderer: (f) => _singletonFieldValue(f.initializer, ctx),
          exported: true,
        ));
    }
  }
  return b.toString();
}

/// 共享结点工厂源码：`export function __h(...)`，归一化 props/children，
/// 返回 {type, props, children} 元素描述（与 JSON 字面量树同形状）。它是
/// [_nodeHelperPackage] 包模块的一部分，全局只有这一处定义。
const String _jsNodeHelperSource = '''
// 共享结点工厂：所有 package 模块与组件产物共用（本文件是它的唯一定义处）。
// 归一化 props/children，返回 {type, props, children} 元素描述，供运行时按
// type 映射 Flutter widget 或组件类。
export function __h(type, props, children) {
  return {
    type: type,
    props: props || {},
    children: children == null
        ? []
        : (Array.isArray(children) ? children : [children]),
  };
}''';

/// package 模块产物：把该 package 的**全部** widget 类型导出为 JS 工厂函数
/// （`Text({...}, [...])` → `{type:'Text', props, children}`），逻辑组件
/// （provider 状态处理 / Builder 委托）则内联为普通类 + 工厂。
///
/// 一个 package 一个文件（文件名即包名）。结点工厂 `__h` 只在其宿主包
/// （[_nodeHelperPackage]）里定义一次，其它包从 `<host>.js` 相对 import。
/// 产物自包含（不依赖运行时 `__jsui`），宿主既有渲染路径与 JS 运行时都能
/// 消费同一份产物。
String _renderPackageModule(String package, Set<String> types) {
  final sorted = types.toList()..sort();
  final b = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT EDIT')
    ..writeln('// package 模块（package: $package）：由 ui_component_generator 生成')
    ..writeln('// 本包全部 widget 工厂集中于此文件；工厂返回 {type, props, children}')
    ..writeln();
  if (package == _nodeHelperPackage) {
    b
      ..writeln(_jsNodeHelperSource)
      ..writeln();
  } else {
    final nodeRel =
        _relativeProduct(_packageModulePath(package), _packageModulePath(_nodeHelperPackage));
    b
      ..writeln("import { __h } from '$nodeRel';")
      ..writeln();
  }
  for (final t in sorted) {
    // 逻辑 widget（provider 状态处理 / Builder 委托）：产物返回**组件**
    // 元素（type 为 JS 类），状态与订阅逻辑全部在 JS 侧，宿主零感知。
    final logic = _logicWidgetSources[t];
    if (logic != null) {
      b
        ..writeln()
        ..writeln(logic);
      continue;
    }
    // Sliver builder 代理：`SliverList({delegateBuilder, childCount})` 形态
    // 走内联组件（build 时循环调用拥有者方法收集子树）；普通形态仍是宿主
    // 节点工厂。
    if (_sliverBuilderTypes.contains(t)) {
      b
        ..writeln()
        ..writeln(_sliverBuilderSource(t));
      continue;
    }
    b
      ..writeln()
      ..writeln('export function $t(props, children) {')
      ..writeln("  return __h('$t', props, children);")
      ..writeln('}');
  }
  return b.toString();
}

/// 支持 builder/factory 写法的滚动视图与 sliver 组件（产物带
/// `delegateBuilder` 时走内联代理组件，普通 children 形态走宿主节点）。
const Set<String> _sliverBuilderTypes = {
  'GridView',
  'SliverList',
  'SliverGrid',
  'SliverFixedExtentList',
  'SliverFillViewport',
};

/// SliverChildBuilderDelegate 的 JS 侧代理组件源码（按 [type] 参数化类名与
/// 工厂）：`props.delegateBuilder` 是拥有者组件上的 `_sliverBuilderN(index)`
/// 方法名、`childCount` 指定数量；build 时循环调用收集子树，包回同名的宿主
/// 节点（children 交给宿主 SliverChildListDelegate 还原）。与
/// ListenableBuilder 的 `__owner()` 向上找拥有者方法机制一致。
String _sliverBuilderSource(String type) {
  final cls = '${type}BuilderComponent';
  return '''
class $cls {
  constructor(props, children) {
    this.props = props || {};
    this.children = children || [];
  }
  __owner() {
    var name = this.props.delegateBuilder;
    var owner = this.__parent;
    while (owner && typeof owner[name] !== 'function') { owner = owner.__parent; }
    return owner;
  }
  build() {
    var owner = this.__owner();
    if (!owner) { return null; }
    var out = [];
    // 计数键兼容两种写法：sliver 的 childCount / GridView.builder 的 itemCount。
    var n = this.props.childCount !== undefined
        ? this.props.childCount
        : (this.props.itemCount || 0);
    for (var i = 0; i < n; i++) { out.push(owner[this.props.delegateBuilder].call(owner, i)); }
    var p = {};
    for (var k in this.props) {
      if (k !== 'delegateBuilder' && k !== 'childCount' && k !== 'itemCount') {
        p[k] = this.props[k];
      }
    }
    return __h('$type', p, out);
  }
}
export function $type(props, children) {
  if (props && props.delegateBuilder !== undefined) {
    return __h($cls, props, children);
  }
  return __h('$type', props, children);
}''';
}

/// 「逻辑 widget」类型 → JS 组件源码（在本模块里内联一个普通类 + 工厂函数）。
///
/// 与宿主 type 节点不同：这些 widget 的**状态/订阅逻辑必须跑在 JS 里**，
/// 因此产物是 `__h(ComponentClass, props, children)`，运行时按组件路径挂载，
/// 由组件 `build()` 自行消费 props（provider 提供/消费 VM、Builder 委托
/// 拥有者方法返回子树）。运行时会给普通类实例补挂 `props/setState/watch/
/// read/__watch/__read/__bind`（见 js_ui/runtime_source.dart）。
const Map<String, String> _logicWidgetSources = {
  'Builder': _jsBuilderComponent,
  'ChangeNotifierProvider': _jsChangeNotifierProviderComponent,
  'MultiProvider': _jsMultiProviderComponent,
  'Consumer': _jsConsumerComponent,
  'ListenableBuilder': _jsListenableBuilderComponent,
};

/// Builder：无状态委托组件——调用拥有者组件上的 `props.builder` 方法
/// （`_builderN()`，含 `var model = this.__watch(...)` 前置语句）拿子树。
const String _jsBuilderComponent = '''
class BuilderComponent {
  constructor(props, children) {
    this.props = props || {};
    this.children = children || [];
  }
  build() {
    var name = this.props.builder;
    var owner = this.__parent;
    while (owner && typeof owner[name] !== 'function') { owner = owner.__parent; }
    if (!owner) { return null; }
    return owner[name].call(owner);
  }
}
export function Builder(props, children) {
  return __h(BuilderComponent, props, children);
}''';

/// ChangeNotifierProvider：把 create/value 解析出的 VM 挂成「提供者结点」
/// （`__provides[model]` + `__value`）。provider 是**纯值结点：不监听、不
/// 记账**——订阅由消费者（`watch`）自己给 VM 挂监听并持有台账，notify 时只
/// 标记该订阅位置重建，作用域最小。生命周期与原生一致：`create` 语义下
/// provider 拥有 VM（类引用时 provider 内 new，实例时直接复用），卸载时
/// dispose；`value` 语义下不拥有、不释放。
const String _jsChangeNotifierProviderComponent = '''
class ChangeNotifierProviderComponent {
  constructor(props, children) {
    this.props = props || {};
    this.children = children || [];
  }
  initState() {
    var p = this.props;
    var vm = null, owns = false;
    if (p.create !== undefined && p.create !== null) {
      if (typeof p.create === 'function') { vm = new p.create(); }
      else { vm = p.create; }
      owns = true;
    } else if (p.value !== undefined && p.value !== null) {
      vm = p.value;
    }
    this.__value = vm;
    this.__ownsValue = owns;
    this.__provides = {};
    this.__provides[p.model] = this;
  }
  build() {
    // child 两种传入方式：直接使用时是 `props.child`（命名参数翻译成 prop）；
    // 被 MultiProvider 包裹时由 `__h(type, props, [node])` 放进 children。
    if (this.props.child != null) { return this.props.child; }
    return this.children.length ? this.children[0] : null;
  }
  dispose() {
    if (this.__ownsValue && this.__value &&
        typeof this.__value.dispose === 'function') {
      this.__value.dispose();
    }
  }
}
export function ChangeNotifierProvider(props, children) {
  return __h(ChangeNotifierProviderComponent, props, children);
}''';

/// MultiProvider：把 providers 数组按「嵌套 Provider」语义组合——
/// providers[0] 最外层，最后一个最内层（离 child 最近），与原生一致。
const String _jsMultiProviderComponent = '''
class MultiProviderComponent {
  constructor(props, children) {
    this.props = props || {};
    this.children = children || [];
  }
  build() {
    var provs = this.props.providers || [];
    var node = this.props.child;
    for (var i = provs.length - 1; i >= 0; i--) {
      node = __h(provs[i].type, provs[i].props, [node]);
    }
    return node;
  }
}
export function MultiProvider(props, children) {
  return __h(MultiProviderComponent, props, children);
}''';

/// Consumer：消费 VM——沿祖先找提供者取 VM 并订阅（watch），再调用拥有者
/// 组件上的 `props.builder` 方法（`_consumerBuilderN(value)`）渲染局部子树。
const String _jsConsumerComponent = '''
class ConsumerComponent {
  constructor(props, children) {
    this.props = props || {};
    this.children = children || [];
  }
  build() {
    var vm = this.watch(this.props.model);
    var name = this.props.builder;
    var owner = this.__parent;
    while (owner && typeof owner[name] !== 'function') { owner = owner.__parent; }
    if (!owner) { return null; }
    return owner[name].call(owner, vm);
  }
}
export function Consumer(props, children) {
  return __h(ConsumerComponent, props, children);
}''';

/// ListenableBuilder：局部重建——订阅 `listenable`（拥有者组件上的模型字段），
/// 模型 notify 时仅重建本结点子树（`setState` 只标记本结点 dirty）。
/// 子树抽在拥有者组件的 `props.builder` 方法（`_lbBuilderN()`）里。
const String _jsListenableBuilderComponent = '''
class ListenableBuilderComponent {
  constructor(props, children) {
    this.props = props || {};
    this.children = children || [];
  }
  __owner() {
    var name = this.props.builder;
    var owner = this.__parent;
    while (owner && typeof owner[name] !== 'function') { owner = owner.__parent; }
    return owner;
  }
  initState() {
    var owner = this.__owner();
    if (!owner) { return; }
    var l = owner[this.props.listenable];
    if (l && typeof l.addListener === 'function') {
      var self = this;
      this.__listenable = l;
      this.__listener = function () { self.setState(function () {}); };
      l.addListener(this.__listener);
    }
  }
  build() {
    var owner = this.__owner();
    if (!owner) { return null; }
    return owner[this.props.builder].call(owner);
  }
  dispose() {
    if (this.__listenable && this.__listener) {
      this.__listenable.removeListener(this.__listener);
    }
  }
}
export function ListenableBuilder(props, children) {
  return __h(ListenableBuilderComponent, props, children);
}''';

// ---------------------------------------------------------------------------
// 静态单例类：识别 / 跨文件解析 / 单例产物渲染
// ---------------------------------------------------------------------------

/// 判断是否「静态单例类」：普通类（无 @UIComponent、非 private、非抽象）、
/// 且含至少一个非 private **static** 字段。
bool _isSingletonClass(ClassDeclaration decl) {
  final name = decl.name.lexeme;
  if (name.startsWith('_')) return false;
  if (decl.abstractKeyword != null) return false;
  if (_findAnnotation(decl.metadata, 'UIComponent') != null) return false;
  // @HostInjected 类不产出 JS（无同名产物可 import），不登记为静态单例。
  if (_classHasHostInjectedMethod(decl)) return false;
  for (final m in decl.members) {
    if (m is FieldDeclaration && m.isStatic) {
      for (final v in m.fields.variables) {
        if (!v.name.lexeme.startsWith('_')) return true;
      }
    }
  }
  return false;
}

/// 收集某文件里声明的全部「静态单例类」（用于无组件文件的单例产物产出）。
List<ClassDeclaration> _findSingletonClasses(CompilationUnit unit) => [
      for (final d in unit.declarations.whereType<ClassDeclaration>())
        if (_isSingletonClass(d)) d,
    ];

/// 收集类里全部非私有 static 字段名。
Set<String> _publicStaticFieldNames(ClassDeclaration decl) {
  final fields = <String>{};
  for (final m in decl.members) {
    if (m is FieldDeclaration && m.isStatic) {
      for (final v in m.fields.variables) {
        if (!v.name.lexeme.startsWith('_')) fields.add(v.name.lexeme);
      }
    }
  }
  return fields;
}

/// 解析「静态单例类」映射（类名 → {非私有 static 字段, sourceFile}）：
/// 同文件的单例类（sourceFile == 当前文件，inline 不 import）与本文件
/// import 的其它文件单例类（独立产物 + import）一并登记。
/// 供 build 树里 `MyColors.background` 这类静态引用翻译与依赖登记使用。
SingletonResolver _buildSingletonResolver(
  CompilationUnit unit,
  String sourcePath,
) {
  final resolver = SingletonResolver();
  // 同文件 static 单例类：inline 进本产物（sourceFile == sourcePath，不 import）
  for (final decl in unit.declarations.whereType<ClassDeclaration>()) {
    if (!_isSingletonClass(decl)) continue;
    resolver.add(decl.name.lexeme, _publicStaticFieldNames(decl), sourcePath);
  }
  // 跨文件 static 单例类：独立产物 + import
  for (final file in _resolveImportFiles(unit, sourcePath)) {
    final f = File(file);
    if (!f.existsSync()) continue;
    final parsed = parseString(content: f.readAsStringSync());
    for (final decl in parsed.unit.declarations.whereType<ClassDeclaration>()) {
      if (!_isSingletonClass(decl)) continue;
      resolver.add(decl.name.lexeme, _publicStaticFieldNames(decl), file);
    }
  }
  return resolver;
}

/// 静态单例字段初始值 → JS 值（返回带引号的 JS 字面量，如字符串
/// `'demo'`、颜色 `'#f5f5f5'`、数字/布尔原样）。支持类型：
/// Color(...) / Colors.xxx（复用颜色求值）、String / int / double / bool
/// 及简单字面量表达式；求不出（如复杂对象）→ 抛 FormatException，
/// 让开发者构建期看到错误，而不是静默得到 undefined（与 Dart 语义一致）。
String _singletonFieldValue(Expression? init, WidgetTranslateContext ctx) {
  if (init == null) {
    throw FormatException('static 字段缺少初始化表达式，无法翻译');
  }
  // 颜色：Color(...) / Colors.xxx → '#...'（复用现有颜色求值）
  final c = colorToJson(init, ctx);
  if (c != null) return c;
  // 字符串：单引号字面量（与单例对象内其它值一致）
  if (init is SimpleStringLiteral) return _singletonString(init.value);
  // 简单字面量：int / double / bool / 简单二元运算
  final lit = _renderLiteral(init);
  if (lit != null) return lit;
  throw FormatException(
    '无法把 static 字段初始值翻译成 JS 值: ${init.toSource()}',
  );
}

/// Js单引号字符串字面量。
String _singletonString(String s) {
  final escaped = s
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll('\n', r'\n')
      .replaceAll('\r', r'\r')
      .replaceAll('\t', r'\t');
  return "'$escaped'";
}
