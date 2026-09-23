import 'dart:async';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:build/build.dart';

import 'builtin_translators.dart';
import 'widget_translator.dart';

/// build_runner 工厂入口（build.yaml 的 builder_factories 指向这里）
Builder componentBuilder(_) => const ComponentBuilder();

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
      ));
    }
    if (components.isEmpty) return; // 无组件文件不产出

    // BFS 收集嵌套依赖：主组件 build 里用到的本文件**私有组件**（_Xxx）
    // 同样翻译成 JS 注册进同一产物；非私有组件保持 Component 节点，
    // 运行时由业务方注入原生 widget（nativeComponents）或占位。
    final parsedNames = <String>{
      for (final d in parsed.unit.declarations)
        if (d is ClassDeclaration) d.name.lexeme,
    };
    final doneDeps = <String>{};
    final depQueue = <String>[
      for (final c in components) ...c.deps,
    ];
    while (depQueue.isNotEmpty) {
      final dep = depQueue.removeLast();
      if (doneDeps.contains(dep)) continue;
      doneDeps.add(dep);
      // 只翻译本文件内的私有组件（_ 开头、未注解、非已注册主组件）
      if (!dep.startsWith('_')) continue;
      if (!parsedNames.contains(dep)) continue;
      if (components.any((c) => c.name == dep)) continue;
      final decl = parsed.unit.declarations
          .whereType<ClassDeclaration>()
          .firstWhere((d) => d.name.lexeme == dep);
      final nested = _parseNestedComponent(decl, parsed.unit, dep, registry);
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
      _renderJs(components, inputId.path, registry),
    );
  }
}

// ---------------------------------------------------------------------------
// 组件模型
// ---------------------------------------------------------------------------

class _Component {
  final String name;
  final List<_Prop> props;
  final List<_Action> actions;
  final Map<String, dynamic> tree; // 节点树（data 以 JS 表达式字符串内嵌）

  /// 构造参数（私有嵌套组件）：`this.x = args && args.x !== undefined ? args.x : def`。
  final List<String> ctorArgs;

  /// build 树里依赖的自定义组件名（Component 兜底收集）。
  final Set<String> deps;

  _Component(this.name, this.props, this.actions, this.tree,
      {this.ctorArgs = const [], this.deps = const {}});
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
  _Action(this.method, this.name, this.nativeChannel, this.bodyJs);
}

// ---------------------------------------------------------------------------
// 注解 / 类解析
// ---------------------------------------------------------------------------

_Component _parseComponent(
  ClassDeclaration widgetClass,
  CompilationUnit unit,
  String componentName,
  WidgetTranslatorRegistry registry,
) {
  final stateClassName = _stateClassName(widgetClass);
  if (stateClassName == null) {
    throw FormatException('$componentName 未实现 createState()，无法定位 State 类');
  }

  ClassDeclaration? stateClass;
  for (final d in unit.declarations) {
    if (d is ClassDeclaration && d.name.lexeme == stateClassName) {
      stateClass = d;
      break;
    }
  }
  if (stateClass == null) {
    throw FormatException('找不到 State 类 $stateClassName（需与 widget 同文件）');
  }

  final props = <_Prop>[];
  final actions = <_Action>[];
  final propByField = <String, String>{};
  final actionByMethod = <String, String>{};
  MethodDeclaration? buildMethod;

  for (final member in stateClass.members) {
    if (member is FieldDeclaration) {
      // 默认全量：所有非 static 字段自动进 state。
      for (final variable in member.fields.variables) {
        final fieldName = variable.name.lexeme;
        final typeName = member.fields.type?.toSource() ?? 'dynamic';
        final initial =
            _renderLiteral(variable.initializer) ?? _defaultInitial(typeName);
        if (member.isStatic) continue;
        if (!_isBasicType(typeName)) {
          // 对象类型字段（Controller/Widget/Key 等）没有 JS 等价物，自动跳过。
          // ignore: avoid_print - 构建期日志
          print(
            '[ui_component_generator] 跳过字段 $fieldName（类型 $typeName 不可翻译）',
          );
          continue;
        }
        final propName = _defaultPropName(fieldName);
        props.add(_Prop(fieldName, propName, typeName, initial));
        propByField[fieldName] = propName;
      }
    }

    if (member is MethodDeclaration) {
      if (member.name.lexeme == 'build') {
        buildMethod = member;
        continue;
      }
      if (_skipMethod(member)) continue;
      // 默认全量：所有非生命周期方法自动进 action。
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
          _translateActionBody(member.body, propByField, nativeChannel),
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
  }

  if (buildMethod == null) {
    throw FormatException('State 类 $stateClassName 缺少 build() 方法');
  }

  final (tree, deps) = _translateBuildTree(
    buildMethod,
    propByField,
    actionByMethod,
    registry,
  );

  return _Component(
    componentName,
    props,
    actions,
    tree,
    deps: deps,
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
  ClassDeclaration widgetClass,
  CompilationUnit unit,
  String componentName,
  WidgetTranslatorRegistry registry,
) {
  // 承载 build 的类：widget 类 或 其 State 类
  ClassDeclaration hostClass = widgetClass;
  final stateClassName = _stateClassName(widgetClass);
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
  MethodDeclaration? buildMethod;

  for (final member in hostClass.members) {
    if (member is FieldDeclaration) {
      for (final variable in member.fields.variables) {
        final fieldName = variable.name.lexeme;
        final typeName = member.fields.type?.toSource() ?? 'dynamic';
        if (member.isStatic) continue;
        if (!_isBasicType(typeName)) {
          // ignore: avoid_print - 构建期日志
          print(
            '[ui_component_generator] 嵌套组件跳过字段 $fieldName（类型 $typeName 不可翻译）',
          );
          continue;
        }
        final fromArgs = ctorArgs.contains(fieldName);
        final initial =
            _renderLiteral(variable.initializer) ?? _defaultInitial(typeName);
        final propName = _defaultPropName(fieldName);
        props.add(_Prop(fieldName, propName, typeName, initial,
            fromArgs: fromArgs));
        propByField[fieldName] = propName;
      }
    }
    if (member is MethodDeclaration) {
      if (member.name.lexeme == 'build') {
        buildMethod = member;
        continue;
      }
      if (_skipMethod(member)) continue;
      final methodName = member.name.lexeme;
      final actionName = _defaultActionName(methodName);
      final nativeChannel =
          _snackMessage(member.body) != null ? 'nativeToast' : null;
      try {
        actions.add(_Action(
          methodName,
          actionName,
          nativeChannel,
          _translateActionBody(member.body, propByField, nativeChannel),
        ));
        actionByMethod[methodName] = actionName;
      } on FormatException catch (e) {
        // ignore: avoid_print - 构建期日志
        print(
          '[ui_component_generator] 嵌套组件跳过方法 $methodName（无法静态翻译: ${e.message}）',
        );
      }
    }
  }

  if (buildMethod == null) {
    throw FormatException('嵌套组件 $componentName 缺少 build() 方法');
  }

  final (tree, deps) = _translateBuildTree(
    buildMethod,
    propByField,
    actionByMethod,
    registry,
  );

  return _Component(
    componentName,
    props,
    actions,
    tree,
    ctorArgs: ctorArgs,
    deps: deps,
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
) {
  if (nativeChannel != null) {
    final msg = _snackMessage(body);
    if (msg == null) {
      throw FormatException(
          'native 动作需要方法体是 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("消息"))) 形式');
    }
    return 'sendMessage(${_jsStringLiteral(nativeChannel)}, JSON.stringify({ message: $msg }));';
  }

  // 逐语句翻译：setState(...) 展开、super.xxx() 忽略、无法翻译的语句降级跳过。
  final stmts = <String>[];
  if (body is ExpressionFunctionBody) {
    final t = _translateExprStatement(body.expression, propByField);
    if (t != null) stmts.add(t);
  } else if (body is BlockFunctionBody) {
    for (final s in body.block.statements) {
      if (s is ExpressionStatement) {
        final e = s.expression;
        // super.initState() 等 super 调用：JS 无 super 语义，忽略
        if (e is MethodInvocation && e.target is SuperExpression) continue;
        final t = _translateExprStatement(e, propByField);
        if (t != null) stmts.add(t);
      }
    }
  }
  if (stmts.isEmpty) return '/* 空方法体 */';
  return stmts.join(' ');
}

/// 翻译一条表达式语句：setState((){...}) / 裸赋值 / 状态自增等。
///
/// setState 按 Dart 原封翻译：`setState(() => _taps++)` →
/// `this.setState(function(){ this._taps += 1; });`。
/// JS 实例上挂载的 setState 由运行时注入（执行回调 + 通知宿主重建），
/// 生成器不展开、不特殊处理。
String? _translateExprStatement(
  Expression e,
  Map<String, String> propByField,
) {
  if (e is MethodInvocation &&
      e.methodName.name == 'setState' &&
      e.argumentList.arguments.length == 1) {
    final fn = e.argumentList.arguments.first;
    if (fn is FunctionExpression) {
      final bodyJs = _translateFunctionBodyJs(fn.body, propByField);
      if (bodyJs == null) return 'this.setState(function(){});';
      return 'this.setState(function(){ $bodyJs });';
    }
    return null;
  }
  return _translateStateExpr(e, propByField);
}

/// 翻译函数体（setState 回调等）：表达式体或块体，逐语句翻译。
String? _translateFunctionBodyJs(
  FunctionBody body,
  Map<String, String> propByField,
) {
  if (body is ExpressionFunctionBody) {
    return _translateStateExpr(body.expression, propByField);
  }
  if (body is BlockFunctionBody) {
    final parts = <String>[];
    for (final st in body.block.statements) {
      if (st is ExpressionStatement) {
        final t = _translateStateExpr(st.expression, propByField);
        if (t != null) parts.add(t);
      }
    }
    return parts.isEmpty ? null : parts.join(' ');
  }
  return null;
}

String? _translateStateExpr(Expression e, Map<String, String> propByField) {
  // _count++ / _count--
  if (e is PostfixExpression &&
      e.operand is Identifier &&
      (e.operator.type == TokenType.PLUS_PLUS ||
          e.operator.type == TokenType.MINUS_MINUS)) {
    final prop = _propOf(e.operand as Identifier, propByField);
    final delta = e.operator.type == TokenType.PLUS_PLUS ? '1' : '-1';
    return 'this.$prop += $delta;';
  }
  // ++_count / --_count
  if (e is PrefixExpression &&
      e.operand is Identifier &&
      (e.operator.type == TokenType.PLUS_PLUS ||
          e.operator.type == TokenType.MINUS_MINUS)) {
    final prop = _propOf(e.operand as Identifier, propByField);
    final delta = e.operator.type == TokenType.PLUS_PLUS ? '1' : '-1';
    return 'this.$prop += $delta;';
  }
  // _count = 0 / _count += 1 / ...
  if (e is AssignmentExpression && e.leftHandSide is Identifier) {
    final prop = _propOf(e.leftHandSide as Identifier, propByField);
    final op = e.operator.lexeme;
    final rhs = _renderLiteral(e.rightHandSide);
    if (rhs == null) return null;
    return 'this.$prop $op $rhs;';
  }
  return null;
}

String _propOf(Identifier id, Map<String, String> propByField) {
  final prop = propByField[id.name];
  if (prop != null) return prop;
  throw FormatException('"${id.name}" 不是状态字段（或已被跳过）');
}

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
// build()：widget 树 → 节点树（策略分发到 WidgetTranslator）
// ---------------------------------------------------------------------------

(Map<String, dynamic>, Set<String>) _translateBuildTree(
  MethodDeclaration buildMethod,
  Map<String, String> propByField,
  Map<String, String> actionByMethod,
  WidgetTranslatorRegistry registry,
) {
  final e = _methodExpression(buildMethod);
  if (e == null) {
    throw FormatException('build() 需要返回 widget 树（return 或 =>）');
  }
  final ctx = WidgetTranslateContext(
    registry: registry,
    propByField: propByField,
    actionByMethod: actionByMethod,
    sourcePath: '',
  );
  return (ctx.translate(e), {...ctx.dependencies});
}

// ---------------------------------------------------------------------------
// 产物渲染
// ---------------------------------------------------------------------------

String _renderJs(
  List<_Component> components,
  String sourcePath,
  WidgetTranslatorRegistry registry,
) {
  final b = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT EDIT')
    ..writeln('// 由 ui_component_generator 从 $sourcePath 自动生成')
    ..writeln('// 重新生成：dart run build_runner build')
    ..writeln()
    ..writeln('// 组件注册表：多个 JS 补丁共享，加载顺序无关')
    ..writeln('var __components = __components || {};')
    ..writeln('// 实例注册表：每个 HotPatchWidget 持有自己的组件实例（状态互不共享）')
    ..writeln('var __instances = __instances || {};');

  for (final c in components) {
    final isNested = c.ctorArgs.isNotEmpty;
    b
      ..writeln()
      ..writeln('// IIFE 闭包：不泄漏到全局，加载多个 JS 不会重名')
      ..writeln("__components['${c.name}'] = (function() {")
      ..writeln('  // 构造函数：new 一次得到一个独立组件实例，可重复实例化')
      ..writeln(isNested
          ? '  function ${c.name}(args) {'
          : '  function ${c.name}() {');
    for (final p in c.props) {
      if (p.fromArgs) {
        // 构造参数：来自调用点 args，缺省回退默认值
        b.writeln(
          '    this.${p.name} = (args && args.${p.name} !== undefined) '
          '? args.${p.name} : ${p.initial};',
        );
      } else {
        b.writeln('    this.${p.name} = ${p.initial};');
      }
    }
    b.writeln('  }');
    b.writeln();
    // 方法一比一：prototype 方法（含 initState/dispose 等生命周期，由运行时回调）
    for (final a in c.actions) {
      b.writeln('  ${c.name}.prototype.${a.name} = function() { ${a.bodyJs} };');
    }
    b.writeln();
    b.writeln('  ${c.name}.prototype.build = function() {');
    final ctx = WidgetTranslateContext(
      registry: registry,
      propByField: const {},
      actionByMethod: const {},
      sourcePath: sourcePath,
    );
    b.writeln('    return ${ctx.renderJs(c.tree, 2)};');
    b.writeln('  };');
    b.writeln();
    b.writeln('  return ${c.name};');
    b.writeln('})();');
  }
  b.writeln();
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
