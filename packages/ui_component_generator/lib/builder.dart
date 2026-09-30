import 'dart:async';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:build/build.dart';

import 'builtin_translators.dart';
import 'class_translator.dart';
import 'style_translators.dart';
import 'widget_translator.dart';

/// build_runner 工厂入口（build.yaml 的 builder_factories 指向这里）
Builder componentBuilder(_) => const ComponentBuilder();

Builder modelBuilder(_) => const ModelBuilder();

/// 把带 @UIComponent 注解的「正常 Flutter widget」翻译为两份产物：
///
///   1. `*.component.js`          —— 运行时 JS 描述模块（build/handleEvent）
///   2. （可选扩展）`*.component.schema.json` —— 组件 schema，按需自行输出
///
/// 组件本身 100% 正常可用（普通 StatefulWidget）；注解只是构建期元数据，
/// 生成器全程静态解析，不执行任何 Dart 代码。
///
/// # 架构
///
/// ComponentBuilder 只负责「总控」：
///   - 解析 @UIComponent widget → State 类
///   - 提取 @UIProp 状态 / @UIAction 动作（方法体静态翻译为 JS）
///   - 把 build() 的 widget 树交给 WidgetTranslateContext 翻译
///   - 组装两份产物
///
/// 「某个 widget 怎么翻译成 JSON/JS」是策略，由 WidgetTranslator 实现：
///   - 抽象类与注册表见 widget_translator.dart
///   - 内置 Column/Row/Text/ElevatedButton 见 builtin_translators.dart
///   - 新增/自定义 widget = 写一个 WidgetTranslator 并 register，
///     核心代码零改动。
class ComponentBuilder implements Builder {
  const ComponentBuilder();

  @override
  Map<String, List<String>> get buildExtensions => const {
        '^lib/{{}}.dart': [
          'assets/components/{{}}.component.js',
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

    // 组件名 → 依赖产物 jsAsset 路径。规则：
    //   本文件注解组件 / 本文件私有组件 → 本文件产物（同产物注册）；
    //   本文件无注解非私有组件（如 LabeledDivider）→ null（运行时原生注入）；
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
    // 产物采用**相对路径**（相对当前产物所在目录，如 'banner_component.component.js'）：
    // 未来 JS 产物整体发布（CDN / 包内迁移）时，主产物与依赖产物的相对关系
    // 不变，运行时按当前 jsAsset 的目录解析即可，绝对路径会随部署位置失效。
    final ownProduct = _productPath(inputId.path); // assets/components/.../x.component.js
    final ownName = ownProduct.substring(ownProduct.lastIndexOf('/') + 1);
    String? importResolver(String name) {
      if (parsedNames.contains(name)) {
        if (annotatedNames.contains(name) || name.startsWith('_')) {
          return ownName;
        }
        return null;
      }
      final abs = _resolveImportProduct(parsed.unit, inputId.path);
      if (abs == null) return null;
      return _relativeProduct(ownProduct, abs);
    }

    // 统一「类表」：把同文件 + 跨文件的所有普通 Dart 类（去 @UIComponent/
    // 私有/抽象/widget 类）收集成 ClassInfo 索引。User/CounterModel/静态单例
    // 都由此统一发现，不再按用途分流（见 class_translator.dart）。
    final classIndex = _buildClassIndex(parsed.unit, inputId.path);

    // 跨文件「静态单例类」映射：照旧，供 build 树里 `PanelColors.x` 静态引用
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
      ));
    }
    if (components.isEmpty) {
      // 无组件文件：若本文件声明了「静态单例类」（含 static 字段的普通类），
      // 产出对应单例产物（export const PanelColors = {...}）；否则不产出
      // （模型文件由 modelBuilder 处理）。
      if (sameFileSingletonInfos.isNotEmpty) {
        final outputs = buildStep.allowedOutputs.toList();
        final jsOutput =
            outputs.firstWhere((a) => a.path.endsWith('.component.js'));
        await buildStep.writeAsString(
          jsOutput,
          _renderSingletonJs(sameFileSingletonInfos, inputId.path, registry),
        );
      }
      return;
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
      // 翻译本文件内的组件类（build 树里 Component 兜底的同文件类：
      // 私有 _Xxx 或无注解公共 widget 如 LabeledDivider），转成 inline
      // 组件类（export class，与主组件同产物注册）。已收集的主组件跳过。
      if (!parsedNames.contains(dep)) continue;
      if (annotatedNames.contains(dep)) continue;
      if (components.any((c) => c.name == dep)) continue;
      final decl = parsed.unit.declarations
          .whereType<ClassDeclaration>()
          .firstWhere((d) => d.name.lexeme == dep);
      final nested = _parseNestedComponent(
          decl, parsed.unit, dep, registry, inputId.path, importResolver,
          classIndex: classIndex, singletons: singletons);
      components.add(nested);
      depQueue.addAll(nested.deps);
    }
    // ignore: avoid_print - 构建期日志
    print(
      '[ui_component_generator] $inputId: '
      '${components.map((c) => c.name).join(', ')}',
    );

    // 一次渲染合并产物：一个文件 → 一个 JS（注册多个组件）
    final outputs = buildStep.allowedOutputs.toList();
    final jsOutput = outputs.firstWhere((a) => a.path.endsWith('.component.js'));

    await buildStep.writeAsString(
      jsOutput,
      _renderJs(components, inputId.path, registry, importResolver,
          singletons: singletons,
          sameFileSingletonInfos: sameFileSingletonInfos),
    );
  }
}

/// 模型 builder：lib/model/ 下的 .dart → .model.js 产物。
/// export class 供组件产物 import（组件产物由 ui_component builder 生成），
/// 与组件 builder 解耦：模型文件不依赖任何注解。
class ModelBuilder implements Builder {
  const ModelBuilder();

  @override
  Map<String, List<String>> get buildExtensions => const {
        '^lib/model/{{}}.dart': [
          'assets/components/model/{{}}.model.js',
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
    final models = _collectModelDecls(parsed.unit);
    if (models.isEmpty) return;
    final output = buildStep.allowedOutputs.first;
    await buildStep.writeAsString(output, _renderModelJs(models));
  }
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

  /// ListenableBuilder 抽出的 builder 子树（译成组件方法 `_lbBuilderN()`，
  /// 运行时时模型 notify 后重新调用拿最新子树做局部重建）。
  final List<Object?> builders; // 节点或 JS 表达式（三目）

  /// build() return 前的局部变量声明（`final isAdult = ...;` → `var isAdult = ...;`），
  /// 产物 build() 方法体内先输出声明再 return 树；树里 Identifier 直接引用。
  final List<String> localDecls;

  const _Component(this.name, this.props, this.actions, this.tree,
      {this.ctorArgs = const [],
      this.deps = const {},
      this.models = const {},
      this.builders = const [],
      this.localDecls = const []});
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
Map<String, ClassInfo> _usedClasses(
  Set<String> candidates,
  Map<String, ClassInfo> index,
) =>
    {
      for (final n in candidates)
        if (index.containsKey(n)) n: index[n]!,
    };

/// 字段类型：优先显式类型注解；无注解时从初始化器推断
/// （`final _model = CounterModel();` 在无 resolution 解析下 type 为 null，
/// 会退化成 dynamic 被当基础类型，需从构造名推回 CounterModel）。
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
  );

  // 字段收集：基础类型 / 类类型字段（含对象字段 `_model = CounterModel()` →
  // `this._model = new CounterModel({})`、`User? _user` → `this._user = null`）
  // 一律进 JS 实例属性，跨 build 持久。
  for (final member in hostClass.members) {
    if (member is FieldDeclaration) {
      for (final variable in member.fields.variables) {
        final fieldName = variable.name.lexeme;
        final typeName = _fieldTypeName(member, variable);
        if (member.isStatic) continue;
        final erased = _eraseType(typeName);
        final isBasic = _isBasicType(typeName);
        final cls = used[erased];
        if (!isBasic && cls == null) {
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
        } else {
          final init = variable.initializer;
          String? ctorJs;
          if (init is InstanceCreationExpression) {
            ctorJs = modelCtorToJs(init, const FieldScope(), used);
          } else if (init is MethodInvocation &&
              init.target == null &&
              init.typeArguments == null) {
            // `_model = CounterModel()` 在无 resolution 的 parseString 下会被解析成
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

  // 方法翻译（带类表）
  for (final member in methods) {
    final methodName = member.name.lexeme;
    final actionName = _defaultActionName(methodName);
    // 方法体是 SnackBar 形式 → 自动识别为 native 通道
    final nativeChannel =
        _snackMessage(member.body) != null ? 'nativeToast' : null;
    try {
      actions.add(_Action(
        methodName,
        actionName,
        nativeChannel,
        _translateActionBody(
          member.body,
          propByField,
          nativeChannel,
          _methodParams(member),
          used,
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

  final (tree, deps, builders, localDecls) = _translateBuildTree(
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
    localDecls: localDecls,
  );
}

/// 解析「嵌套组件」：build 树里出现的本文件私有组件（_Xxx），
/// 与主组件同产物注册（__components['_Xxx']），运行时 ComponentHost 递归渲染。
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
        final cls = used[erased];
        if (!isBasic && cls == null) {
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
        } else {
          final init = variable.initializer;
          String? ctorJs;
          if (init is InstanceCreationExpression) {
            ctorJs = modelCtorToJs(init, const FieldScope(), used);
          } else if (init is MethodInvocation &&
              init.target == null &&
              init.typeArguments == null) {
            // `_model = CounterModel()` 在无 resolution 的 parseString 下会被解析成
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

  for (final member in methods) {
    final methodName = member.name.lexeme;
    final actionName = _defaultActionName(methodName);
    final nativeChannel =
        _snackMessage(member.body) != null ? 'nativeToast' : null;
    try {
      actions.add(_Action(
        methodName,
        actionName,
        nativeChannel,
        _translateActionBody(
          member.body,
          propByField,
          nativeChannel,
          _methodParams(member),
          used,
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

  final (tree, deps, builders, localDecls) = _translateBuildTree(
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
    localDecls: localDecls,
  );
}

// ---------------------------------------------------------------------------
// 默认全量收集：命名与过滤规则
// ---------------------------------------------------------------------------

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
      // `_HelloCardState()`：下划线开头不是合法类型名，语法解析器会当成
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

String? _positionalString(Annotation a, int index) {
  final args = a.arguments;
  if (args == null || index >= args.arguments.length) return null;
  final e = args.arguments[index];
  return e is StringLiteral ? e.stringValue : null;
}

String? _renderLiteral(Expression? e) {
  if (e == null) return null;
  if (e is StringLiteral) return _jsStringLiteral(e.stringValue ?? '');
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
// @UIAction：方法体静态翻译 → JS
// ---------------------------------------------------------------------------

String _translateActionBody(
  FunctionBody body,
  Map<String, String> propByField,
  String? nativeChannel,
  List<String> params,
  Map<String, ClassInfo> classes,
) {
  // 组件动作的可用引用：State 字段（propByField）+ 方法形参。表达式/语句
  // 统一交给 class_translator.exprStmtToJs（以 FieldScope 为键），与模型
  // 方法体翻译共用同一套逻辑。
  final scope = FieldScope(
    propByField: propByField,
    params: params.toSet(),
  );
  if (nativeChannel != null) {
    final msg = _snackMessage(body);
    if (msg == null) {
      throw FormatException(
          'native 动作需要方法体是 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("消息"))) 形式');
    }
    // JS 消息统一携带页面 key（this._key 由运行时挂载），
    // 运行时按 key 定位页面级处理器。
    return 'sendMessage(${_jsStringLiteral(nativeChannel)}, JSON.stringify({ key: this._key, message: $msg }));';
  }

  // 逐语句翻译：setState(...) 展开、await Future.delayed(...)、
  // super.xxx() 忽略、无法翻译的语句降级跳过。
  final stmts = <String>[];
  if (body is ExpressionFunctionBody) {
    final t = _translateExprStatement(body.expression, scope, classes);
    if (t != null) stmts.add(t);
  } else if (body is BlockFunctionBody) {
    for (final s in body.block.statements) {
      if (s is ExpressionStatement) {
        final e = s.expression;
        // super.initState() 等 super 调用：JS 无 super 语义，忽略
        if (e is MethodInvocation && e.target is SuperExpression) continue;
        final t = _translateExprStatement(e, scope, classes);
        if (t != null) stmts.add(t);
      }
    }
  }
  if (stmts.isEmpty) return '/* 空方法体 */';
  return stmts.join(' ');
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
  // await Future.delayed(Duration(...)) → Promise/setTimeout（模拟网络延迟）
  if (e is AwaitExpression) {
    final delay = _delayedMsJs(e.expression);
    if (delay != null) return 'await new Promise(function(r){ setTimeout(r, $delay); });';
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

/// `await Future.delayed(Duration(seconds: n))` → setTimeout 毫秒数。
/// 只映射这一种 Dart 异步延迟 API（JS 无等价物），其余 await 不支持。
String? _delayedMsJs(Expression e) {
  if (e is! MethodInvocation || e.methodName.name != 'delayed') return null;
  final target = e.target;
  if (target == null || target.toSource() != 'Future') return null;
  final args = e.argumentList.arguments;
  if (args.isEmpty) return null;
  final dur = args.first;
  String? unit;
  double? value;
  if (dur is InstanceCreationExpression &&
      dur.constructorName.type.name2.lexeme == 'Duration') {
    for (final a in dur.argumentList.arguments) {
      if (a is NamedExpression) {
        final lit = a.expression;
        if (lit is IntegerLiteral) {
          if (unit != null) return null; // 多个时间单位不支持
          unit = a.name.label.name;
          value = (lit.value ?? 0).toDouble();
        } else if (lit is DoubleLiteral) {
          if (unit != null) return null;
          unit = a.name.label.name;
          value = lit.value;
        }
      }
    }
  }
  if (unit == null || value == null) return null;
  final ms = switch (unit) {
    'seconds' => value * 1000,
    'milliseconds' => value,
    'microseconds' => value / 1000,
    'minutes' => value * 60 * 1000,
    _ => null,
  };
  if (ms == null) return null;
  return ms == ms.roundToDouble() ? '${ms.round()}' : '$ms';
}

/// 方法形式参数名列表（解 DefaultFormalParameter 包裹）。
List<String> _methodParams(MethodDeclaration m) => [
      for (final p in m.parameters!.parameters)
        (p is DefaultFormalParameter ? p.parameter : p).name?.lexeme ?? '',
    ];

/// 提取 SnackBar 消息字符串
String? _snackMessage(FunctionBody body) {
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
      // 统一用 _ctorOf 取构造名与参数。
      final (snackCtor, snackArgs) = _ctorOf(snack);
      if (snackCtor == 'SnackBar') {
        final content = _namedArg(snackArgs, 'content');
        if (content != null) {
          final (textCtor, textArgs) = _ctorOf(content);
          if (textCtor == 'Text') {
            final data = _positionalArg(textArgs, 0);
            if (data is StringLiteral) return _jsStringLiteral(data.stringValue ?? '');
          }
        }
      }
    }
  }
  return null;
}

(String?, List<Expression>) _ctorOf(Expression e) {
  if (e is InstanceCreationExpression) {
    return (
      e.constructorName.type.name2.lexeme,
      e.argumentList.arguments.toList(),
    );
  }
  if (e is MethodInvocation) {
    return (e.methodName.name, e.argumentList.arguments.toList());
  }
  return (null, const []);
}

Expression? _positionalArg(List<Expression> args, int i) =>
    i < args.length ? args[i] : null;

Expression? _namedArg(List<Expression> args, String name) {
  for (final a in args) {
    if (a is NamedExpression && a.name.label.name == name) return a.expression;
  }
  return null;
}

// ---------------------------------------------------------------------------
// 产物路径推导：组件名 → 依赖产物 jsAsset
// ---------------------------------------------------------------------------

/// 源文件路径 → 产物路径（与 build.yaml 的 build_extensions 约定一致）：
/// `lib/a/b.dart` → `assets/components/a/b.component.js`。
String _productPath(String sourcePath) {
  if (!sourcePath.startsWith('lib/')) return sourcePath;
  final rel = sourcePath.substring('lib/'.length); // a/b.dart
  if (!rel.endsWith('.dart')) return sourcePath;
  return 'assets/components/${rel.substring(0, rel.length - '.dart'.length)}.component.js';
}

/// 模型源文件（lib/model/user.dart）→ 模型产物路径
/// （assets/components/model/user.model.js，镜像 lib 目录结构）。
String _modelProductPath(String sourcePath) {
  if (!sourcePath.startsWith('lib/')) return sourcePath;
  final rel = sourcePath.substring('lib/'.length);
  if (!rel.endsWith('.dart')) return sourcePath;
  return 'assets/components/${rel.substring(0, rel.length - '.dart'.length)}.model.js';
}

/// 收集表达式树里全部模型构造调用名（与类发现共用：State 字段类型 + 构造调用）。
class _CtorCollector extends RecursiveAstVisitor<void> {
  final names = <String>{};

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    names.add(node.constructorName.type.name2.lexeme);
    super.visitInstanceCreationExpression(node);
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
    // 精确匹配：'package:flutter/' 才是 SDK 包，'package:flutter_hot/' 是业务包
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
/// 如 'assets/components/components/composite_component.component.js' →
/// 'assets/components/components/banner_component.component.js'
/// 得 'banner_component.component.js'；跨目录时含 '../'。
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

/// 从当前文件的 import directives 推导「依赖组件所在文件」的产物路径。
/// 规则：**相对导入优先**（同目录/子目录的组件文件，如 'banner_component.dart'）；
/// 相对导入不存在时才尝试 package: 导入（跳过 dart: / flutter —— 注解包
/// ui_component 等跨包库不在本项目的 assets/components 产物约定内，跳过）。
/// 把 import uri 映射到 lib 相对路径再换算产物路径。
String? _resolveImportProduct(CompilationUnit unit, String sourcePath) {
  final slash = sourcePath.lastIndexOf('/');
  final dir = slash >= 0 ? sourcePath.substring(0, slash + 1) : ''; // 含尾 /
  final imports = unit.directives.whereType<ImportDirective>().toList();
  // 第一轮：相对导入
  for (final d in imports) {
    final uri = d.uri.stringValue;
    if (uri == null || uri.startsWith('package:') || uri.startsWith('dart:')) {
      continue;
    }
    final libRel = _relativeToLib(uri, dir);
    if (libRel == null || !libRel.endsWith('.dart')) continue;
    return 'assets/components/${libRel.substring(0, libRel.length - '.dart'.length)}.component.js';
  }
  // 第二轮：package: 导入（跳过 dart:/flutter 与注解/生成器包）
  for (final d in imports) {
    final uri = d.uri.stringValue;
    if (uri == null || !uri.startsWith('package:') ||
        uri.startsWith('package:flutter/') ||
        uri.startsWith('package:ui_component/') ||
        uri.startsWith('package:ui_component_generator/')) {
      continue;
    }
    // package:<项目名>/<lib 下路径> → 取 '/' 之后部分
    final slashIdx = uri.indexOf('/');
    if (slashIdx <= 0 || slashIdx >= uri.length - 1) continue;
    final libRel = uri.substring(slashIdx + 1);
    if (!libRel.endsWith('.dart')) continue;
    return 'assets/components/${libRel.substring(0, libRel.length - '.dart'.length)}.component.js';
  }
  return null;
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

(Object?, Set<String>, List<Object?>, List<String>)
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
      }
    }
  }
  return (
    ctx.translate(e),
    {...ctx.dependencies},
    ctx.builderTrees,
    localDecls,
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
}) {
  // 统一类表按「同文件 inline / 跨文件 import」分组渲染：
  //  - 同文件模型（sourceFile == 当前组件文件）→ 产物内 inline class（不 export，
  //    与 Dart 源文件里同文件使用一致）；
  //  - 跨文件模型（lib/model/ 等 import 文件）→ import 该文件的 .model.js 产物，
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

  final b = StringBuffer()
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
    b.writeln("import { $cls } from '$rel';");
  }
  for (final m in allModels.values) {
    final abs = _modelProductPath(m.sourceFile);
    final rel = _relativeProduct(ownProduct, abs);
    b.writeln("import { ${m.name} } from '$rel';");
  }

  // 跨文件组件：build 树里 Component 兜底、且产物在其他文件的依赖组件，
  // 同样用 ES module import（'banner_component.component.js' 相对本产物目录）。
  // 模块级 import 让依赖关系直观可见；JSON 树里 Component 节点不再携带
  // import 字段（运行时按组件索引：导出类名 → jsAsset 反查递归）。
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
      b.writeln("import { $dep } from '$rel';");
    }
  }

  // 同文件模型：inline class（不 export，本产物内共享）。统一由
  // class_translator.renderClassDecl 翻译（含字段/方法/getter/extends
  // NotifierBase），与跨文件模型、模型产物共用同一处理器。
  for (final m in inlineModels.values) {
    b
      ..writeln()
      ..writeln('// 模型 ${m.name}（同文件，仅本产物内可见）')
      ..writeln(renderClassDecl(m, const {}, exported: false));
  }

  // 同文件 static 单例类：inline export const（exported: true —— 运行时
  // 预处理层按 export 名收集并注册进 __modules，跨文件组件才能
  // `import { PanelColors }` 解构拿到；仅 const 会被收集器漏掉）
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
    b.writeln();
    // 组件：export class（运行时按组件名从 __modules[jsAsset] 取类）
    b.writeln('export class ${c.name} {');
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
    // build：树结构 JSON（由 WidgetTranslateContext 翻译）
    b.writeln('  build() {');
    final ctx = WidgetTranslateContext(
      registry: registry,
      propByField: const {},
      actionByMethod: const {},
      sourcePath: sourcePath,
    );
    for (final d in c.localDecls) {
      b.writeln(d);
    }
    b.writeln('    return ${ctx.renderJs(c.tree, 2)};');
    b.writeln('  }');
    // ListenableBuilder 的 builder 闭包子树 → 方法 `_lbBuilderN()`。
    // 运行时时模型 notify 后重新调用本方法拿到最新子树（含已求值的
    // this._model.n），做「仅此节点」的局部重建。
    for (var i = 0; i < c.builders.length; i++) {
      b.writeln('  _lbBuilder$i() {');
      b.writeln('      return ${ctx.renderJs(c.builders[i], 2)};');
      b.writeln('  }');
    }
    b.writeln('}');
  }
  b.writeln();
  return b.toString();
}

/// 收集模型文件（lib/model/）中全部可导出的类（非私有、非抽象），
/// 统一经 classInfoOf 提取为 ClassInfo（与组件产物同处理器，见 class_translator）。
List<ClassInfo> _collectModelDecls(CompilationUnit unit) {
  final out = <ClassInfo>[];
  for (final decl in unit.declarations.whereType<ClassDeclaration>()) {
    final name = decl.name.lexeme;
    if (name.startsWith('_')) continue;
    out.add(classInfoOf(decl, ''));
  }
  return out;
}

/// 模型产物渲染：export class（ES module，运行时加载器收集导出名）。
String _renderModelJs(List<ClassInfo> models) {
  final b = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT EDIT')
    ..writeln('// 模型模块：由 ui_component_generator 生成')
    ..writeln('// export class 供组件产物 import（运行时按相对路径加载）')
    ..writeln();
  for (final m in models) {
    b
      ..writeln('// 模型 ${m.name}')
      ..writeln(renderClassDecl(m, const {}, exported: true));
  }
  return b.toString();
}

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
/// 供 build 树里 `PanelColors.background` 这类静态引用翻译与依赖登记使用。
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

/// 独立单例产物渲染（无组件文件时用）：`export const PanelColors = { ... };`。
String _renderSingletonJs(
  List<ClassInfo> classes,
  String sourcePath,
  WidgetTranslatorRegistry registry,
) {
  final b = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT EDIT')
    ..writeln('// 静态单例类：由 ui_component_generator 自动生成')
    ..writeln('// 重新生成：dart run build_runner build')
    ..writeln();
  final ctx = WidgetTranslateContext(
    registry: registry,
    propByField: const {},
    actionByMethod: const {},
    sourcePath: sourcePath,
  );
  for (final cls in classes) {
    b
      ..writeln()
      ..writeln('// 静态单例类 ${cls.name}')
      ..writeln(renderStaticConst(
        cls,
        valueRenderer: (f) => _singletonFieldValue(f.initializer, ctx),
        exported: true,
      ));
  }
  return b.toString();
}

/// 生成 JS 双引号字符串字面量（与 WidgetTranslateContext.jsString 一致）。
String _jsStringLiteral(String s) {
  final escaped = s
      .replaceAll(r'\', r'\\')
      .replaceAll('"', r'\"')
      .replaceAll('\n', r'\n')
      .replaceAll('\r', r'\r')
      .replaceAll('\t', r'\t');
  return '"$escaped"';
}
