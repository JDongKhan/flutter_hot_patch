import 'dart:async';
import 'dart:convert';

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
///   2. `*.component.schema.json` —— 组件 schema（状态/动作/节点树描述）
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
          'assets/components/{{}}.component.schema.json',
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

    for (final declaration in parsed.unit.declarations) {
      if (declaration is! ClassDeclaration) continue;
      final uiComponent = _findAnnotation(declaration.metadata, 'UIComponent');
      if (uiComponent == null) continue;

      final component = _parseComponent(
        declaration,
        parsed.unit,
        _positionalString(uiComponent, 0) ?? declaration.name.lexeme,
        registry,
      );

      final outputs = buildStep.allowedOutputs.toList();
      final jsOutput = outputs.firstWhere(
        (a) => a.path.endsWith('.component.js'),
      );
      final schemaOutput = outputs.firstWhere(
        (a) => a.path.endsWith('.component.schema.json'),
      );

      await buildStep.writeAsString(
        jsOutput,
        _renderJs(component, inputId.path, registry),
      );
      await buildStep.writeAsString(
        schemaOutput,
        const JsonEncoder.withIndent('  ')
            .convert(_renderSchema(component, inputId.path)),
      );
    }
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
  _Component(this.name, this.props, this.actions, this.tree);
}

class _Prop {
  final String field; // Dart 字段名，如 _count
  final String name; // 状态名，如 count
  final String type; // int / String / bool ...
  final String initial; // JS 初始值字面量
  _Prop(this.field, this.name, this.type, this.initial);
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

  final tree = _translateBuildTree(
    buildMethod,
    propByField,
    actionByMethod,
    registry,
  );

  return _Component(componentName, props, actions, tree);
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

/// 跳过 State 生命周期 / getter / setter / static 方法（不是用户动作）。
bool _skipMethod(MethodDeclaration member) {
  if (member.isGetter || member.isSetter) return true;
  if (member.isStatic) return true;
  return const {
    'initState',
    'dispose',
    'didChangeDependencies',
    'didUpdateWidget',
    'deactivate',
    'activate',
  }.contains(member.name.lexeme);
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

  final inner = _unwrapSetState(body);
  if (inner == null) return '/* 空方法体 */';
  final translated = _translateStateExpr(inner, propByField);
  return translated ?? '/* TODO(codegen): 无法静态翻译的方法体 */';
}

/// 提取 setState(() { ... }) / setState(() => ...) 里的表达式
Expression? _unwrapSetState(FunctionBody body) {
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
  if (outer is MethodInvocation &&
      outer.methodName.name == 'setState' &&
      outer.argumentList.arguments.length == 1) {
    final fn = outer.argumentList.arguments.first;
    if (fn is FunctionExpression) {
      final fb = fn.body;
      if (fb is ExpressionFunctionBody) return fb.expression;
      if (fb is BlockFunctionBody) {
        for (final s in fb.block.statements) {
          if (s is ExpressionStatement) return s.expression;
        }
      }
    }
  }
  return outer;
}

String? _translateStateExpr(Expression e, Map<String, String> propByField) {
  // _count++ / _count--
  if (e is PostfixExpression &&
      e.operand is Identifier &&
      (e.operator.type == TokenType.PLUS_PLUS ||
          e.operator.type == TokenType.MINUS_MINUS)) {
    final prop = _propOf(e.operand as Identifier, propByField);
    final delta = e.operator.type == TokenType.PLUS_PLUS ? '1' : '-1';
    return '$prop += $delta;';
  }
  // ++_count / --_count
  if (e is PrefixExpression &&
      e.operand is Identifier &&
      (e.operator.type == TokenType.PLUS_PLUS ||
          e.operator.type == TokenType.MINUS_MINUS)) {
    final prop = _propOf(e.operand as Identifier, propByField);
    final delta = e.operator.type == TokenType.PLUS_PLUS ? '1' : '-1';
    return '$prop += $delta;';
  }
  // _count = 0 / _count += 1 / ...
  if (e is AssignmentExpression && e.leftHandSide is Identifier) {
    final prop = _propOf(e.leftHandSide as Identifier, propByField);
    final op = e.operator.lexeme;
    final rhs = _renderLiteral(e.rightHandSide);
    if (rhs == null) return null;
    return '$prop $op $rhs;';
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

Map<String, dynamic> _translateBuildTree(
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
  return ctx.translate(e);
}

// ---------------------------------------------------------------------------
// 产物渲染
// ---------------------------------------------------------------------------

String _renderJs(_Component c, String sourcePath, WidgetTranslatorRegistry registry) {
  final b = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT EDIT')
    ..writeln('// 由 ui_component_generator 从 $sourcePath 自动生成')
    ..writeln('// 重新生成：dart run build_runner build')
    ..writeln()
    ..writeln('// 组件注册表：多个 JS 补丁共享，加载顺序无关')
    ..writeln('var __components = __components || {};')
    ..writeln()
    ..writeln('// IIFE 闭包：方法/状态不泄漏到全局，加载多个 JS 不会重名')
    ..writeln("__components['${c.name}'] = (function() {")
    ..writeln('  // 属性一比一：Dart 字段名 = JS 变量名');
  for (final p in c.props) {
    b.writeln('  var ${p.name} = ${p.initial};');
  }
  b.writeln();
  // 方法一比一转换：Dart 方法名 = JS 函数名（方法体静态翻译）
  for (final a in c.actions) {
    b.writeln('  function ${a.name}() { ${a.bodyJs} }');
  }
  b.writeln();
  b.writeln('  function build() {');
  final ctx = WidgetTranslateContext(
    registry: registry,
    propByField: const {},
    actionByMethod: const {},
    sourcePath: sourcePath,
  );
  b.writeln('    return ${ctx.renderJs(c.tree, 2)};');
  b.writeln('  }');
  b.writeln();
  // 导出：属性（getter，只读反射）/ 各方法 / build（渲染入口）
  final exports = [
    for (final p in c.props) 'get ${p.name}() { return ${p.name}; }',
    for (final a in c.actions) '${a.name}: ${a.name}',
    'build: build',
  ].join(', ');
  b.writeln('  return { $exports };');
  b.writeln('})();');
  b.writeln();
  return b.toString();
}

Map<String, dynamic> _renderSchema(_Component c, String sourcePath) {
  return {
    'name': c.name,
    'source': sourcePath,
    'state': [
      for (final p in c.props)
        {
          'field': p.field,
          'name': p.name,
          'type': p.type,
          'initial': p.initial,
        },
    ],
    'actions': [
      for (final a in c.actions)
        {
          'method': a.method,
          'name': a.name,
          'native': a.nativeChannel,
        },
    ],
    'tree': c.tree,
  };
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
