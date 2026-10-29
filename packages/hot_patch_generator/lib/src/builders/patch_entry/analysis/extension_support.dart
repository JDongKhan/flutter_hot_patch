/// Dart `extension` 声明 → JS 注册语句（`__jsExtension(...)`）。
///
/// **翻译只有一条路径**：扩展成员体与类方法体共用 [translateClassMethodBody]
/// （同一个 FieldScope / 表达式渲染器），因此在扩展里写什么、能调什么，与在
/// 类里写什么**完全一致**——`this` 就是接收者、形参/局部变量同一套解析、
/// `return Text(...)` 同一套 widget 渲染、`@HostInjected` 同一张通道表。
///
/// 产物在**扩展声明处**发射（见 component_builder）：
///
///   export const StringLogExtension = __jsExtension("String", {
///     logText: function (tag) { ... }
///   }, { id: "lib/src/x.dart#StringLogExtension" });
///
/// 调用点不需要任何处理：`'a'.logText('t')` 在 Dart 与 JS 里是同一个方法调用
/// 形态（成员由运行时【27.5】装到目标类型的原型上）。
///
/// 构建期只拒绝**运行时必然失败**的注册（扩展名撞类名 / 目标类型在 JS 侧没有
/// 对应构造函数），出声跳过，而不是产出必然报错的代码。
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:build/build.dart' show log;

import '../class_info.dart';
import '../translator/js_translator.dart';
import '../translator/js_value.dart';
import '../translator/element2js.dart';
import '../../shared/host_injected.dart';
import '../../shared/js_class_defs.dart';
import '../../shared/paths.dart';
import '../../shared/runtime_global_types.dart';
import '../../shared/source_index.dart';
import 'analyze_dart_class.dart';

/// 一个已翻译的 extension 声明（产物里的一条 `__jsExtension(...)`）。
class ExtensionInfo {
  /// Dart 扩展名（产物里的 `export const <name>`）；无名扩展为空串（不 export）。
  final String name;

  /// 稳定标识 `<sourcePath>#<name>`：同 id 再注册时运行时会先卸载旧成员。
  final String id;

  /// 交给运行时的目标：JS 类引用（同一产物 / import 到）或类型名字面量。
  final String targetJs;

  /// 目标类的 import 语句（null = 不需要 import：同产物内的类 / 语言核心类型 /
  /// 运行时注入类型）。
  final String? targetImport;

  /// 原型成员：成员名 → JS 源码（函数体源码 / `{ get: ... }` 描述符）。
  final Map<String, String> membersJs;

  /// 静态成员：完整的对象字面量成员项（`foo: function () {...}` / `get foo() {...}`）。
  final List<String> staticsEntries;

  /// 成员体里构造调用到的类名（builder 据此递归翻译 / import）。
  final Set<String> dependencies;

  /// 成员体里实际用到的 widget 类型（package → {type}）。
  final Map<String, Set<String>> usedWidgetPackages;

  const ExtensionInfo({
    required this.name,
    required this.id,
    required this.targetJs,
    this.targetImport,
    required this.membersJs,
    this.staticsEntries = const [],
    this.dependencies = const {},
    this.usedWidgetPackages = const {},
  });

  /// 注册语句（顶层语句：模块求值时执行一次，成员随产物装到目标原型上）。
  ///
  /// **成员必须由严格模式函数承载**：产物是脚本（非模块）求值，非严格模式下
  /// 以原始值作接收者调用方法时 `this` 会被**装箱**（`new String(...)`），
  /// 于是 Dart 里等价的 `this == 'a'` / `this.length` / 日志里的 `this` 全都
  /// 变成对象语义（`String(this)` 得到 `[object String]`、`__str(this)` 展开成
  /// `{0:'a'…}`）。严格函数的 `this` 才是接收者本身（与 Dart 一致）。严格模式
  /// 对嵌套函数**词法继承**，故整个成员表包一层即可。
  String toJs() {
    final call = StringBuffer()
      ..writeln('__jsExtension($targetJs, (function () {')
      ..writeln('  "use strict";')
      ..writeln('  return {');
    for (final e in membersJs.entries) {
      call.writeln('    ${e.key}: ${e.value},');
    }
    call.write('  };\n})()');
    call.write(', { id: ${jsString(id)}');
    if (staticsEntries.isNotEmpty) {
      call.write(', statics: {');
      for (final e in staticsEntries) {
        call.write(' $e,');
      }
      call.write(' }');
    }
    call.write(' })');
    return name.isEmpty ? '$call;' : 'export const $name = $call;';
  }
}

/// 语言核心类型：Dart 类型名 → 运行时直接映射的 JS 内建（见 `__jsExtensionTargetOf`）。
const Set<String> _coreTargets = {
  'int',
  'num',
  'double',
  'String',
  'bool',
  'List',
  'Iterable',
  'Set',
};

/// 明确没有单一 JS 对应物的目标类型（成员无处可挂 / 挂上去必然误伤其它对象）。
const Set<String> _unsupportedTargets = {
  'dynamic',
  'Object',
  'Map',
  'void',
  'Null',
  'Never',
  'Function',
};

/// 本文件声明的全部 `extension`（含无名扩展）。
List<ExtensionDeclaration> extensionDeclarations(CompilationUnit unit) => [
      for (final d in unit.declarations.whereType<ExtensionDeclaration>()) d,
    ];

/// 本文件是否声明了 extension（纯扩展文件也必须产出产物）。
bool hasExtensionDeclaration(CompilationUnit unit) =>
    extensionDeclarations(unit).isNotEmpty;

/// 一个 extension 在**调用点**会出现的名字（用来判断本文件有没有用到它）。
///
///   - 实例成员（方法 / getter / setter）→ 成员名：`'a'.logText()` 里 `logText`
///     是标识符，与本文件任意标识符同名即视为用到；
///   - 静态成员 → 扩展名：`ExtName.foo()` 里 `ExtName` 是标识符；
///   - 扩展名本身也收：`providesX` 之类的成员名可能与扩展名重合。
///
/// 判定刻意**偏宽松**（任何同名标识符都算命中，不区分接收者类型——无类型解析
/// 时无法判定接收者是谁）：误判方向是「多导入一个产物」，代价只是多执行一次
/// 幂等注册；不会出现「用到却没导入」的漏判。
Set<String> extensionCallSiteNames(ExtensionDeclaration decl) {
  final out = <String>{};
  final name = decl.name?.lexeme;
  if (name != null && name.isNotEmpty) out.add(name);
  for (final member in decl.members.whereType<MethodDeclaration>()) {
    if (member.isStatic) {
      // 静态成员只能写成 `ExtName.foo()`，调用点出现的是扩展名（上面已收）。
      continue;
    }
    out.add(member.name.lexeme);
  }
  return out;
}

/// 本文件里出现过的全部标识符（宽松「用到」判据，见 [extensionCallSiteNames]）。
Set<String> identifierNamesIn(CompilationUnit unit) {
  final collector = _IdentifierCollector();
  unit.accept(collector);
  return collector.names;
}

/// 本产物**承载的全部代码**里出现过的标识符：本文件（含 extension 成员）
/// + 被 `with` 的 mixin 成员。
///
/// mixin 成员会被线性化进本产物，其方法体里的 `'x'.logText()` 同样要求声明
/// 该扩展的产物被加载；只扫本文件会漏掉「调用只写在 mixin 里」的场景。
Set<String> identifierNamesInProduct(CompilationUnit unit, String sourcePath) {
  final names = identifierNamesIn(unit);
  for (final d in _productHostClasses(unit)) {
    for (final (mixinDecl, _) in resolveMixinDeclRefs(d, unit, sourcePath)) {
      names.addAll(_identifierNamesOfMembers(mixinDecl.members));
    }
  }
  return names;
}

/// 本产物**承载的代码**能看见的源文件集合：本文件 import 图 + 被 `with` 的
/// mixin 声明文件的 import 图。
///
/// mixin 成员被线性化进本产物，写在 mixin 文件里的 `'x'.logText()` 同样需要
/// 该扩展的产物被加载；只扫本文件的 import 图看不到 mixin 文件 import 的
/// 扩展声明库（`import` 目标不逐层深入）。
Set<String> extensionScopeFiles(CompilationUnit unit, String sourcePath) {
  final files = <String>{...resolveImportFiles(unit, sourcePath)};
  for (final d in _productHostClasses(unit)) {
    for (final (_, mixinFile) in resolveMixinDeclRefs(d, unit, sourcePath)) {
      final mixinUnit = parseUnitFile(mixinFile);
      if (mixinUnit == null) continue;
      files.addAll(resolveImportFiles(mixinUnit, mixinFile));
    }
  }
  return files;
}

/// 本产物承载代码的宿主类：本文件的公共类 + 其同文件 State 类。
///
/// `with` 子句通常写在**私有 State 类**上（`class _XState extends State<X>
/// with M`），只遍历公共类会看不到它携带的 mixin 成员——而那段代码确实会被
/// 线性化进本产物。
Iterable<ClassDeclaration> _productHostClasses(CompilationUnit unit) sync* {
  for (final d in unit.declarations.whereType<ClassDeclaration>()) {
    if (d.name.lexeme.startsWith('_')) continue;
    yield* classAndStateDecls(d, unit);
  }
}

/// 任意成员表里出现过的标识符（与 [identifierNamesIn] 同一收集器）。
Set<String> _identifierNamesOfMembers(Iterable<ClassMember> members) {
  final collector = _IdentifierCollector();
  for (final m in members) {
    m.accept(collector);
  }
  return collector.names;
}

class _IdentifierCollector extends RecursiveAstVisitor<void> {
  final Set<String> names = {};

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    names.add(node.name);
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    names.add(node.identifier.name);
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    names.add(node.propertyName.name);
    super.visitPropertyAccess(node);
  }
}

/// 翻译一个 extension → [ExtensionInfo]；构建期不成立的声明返回 null（已告警）。
///
/// [ownProduct]：本产物的身份（`patch/a/b.js`），用于判断目标类是否就在**同
/// 一个产物**里（是 → 直接传裸类名；否 → 从目标产物 import）。
/// [productOf]：类名 → 该类的**产物身份**（`patch/a/b.js`）；null = 该类在 JS
/// 侧没有产物。与类翻译共用同一份 import 图口径〔同文件 / import 源文件 /
/// 本地依赖包的包模块〕。
ExtensionInfo? translateExtension(
  ExtensionDeclaration decl,
  CompilationUnit unit,
  String sourcePath, {
  required String ownProduct,
  required Map<String, ClassInfo> classTable,
  required String? Function(String name) importResolver,
  Set<String> jsClassWidgets = const {},
  Set<String> delegateClassWidgets = const {},
  Set<String> ignoredTypes = const {},
  Set<String> globalConsts = const {},
  Set<String> classNamesInUnit = const {},
  String? Function(String name)? productOf,
}) {
  final name = decl.name?.lexeme;
  final label = name ?? '<unnamed>';
  if (name != null && classNamesInUnit.contains(name)) {
    log.warning(
      '[hot_patch_generator] $sourcePath: extension $name 与本文件里的类名冲突，'
      '已跳过（Dart 里同名二者无法被引用）。',
    );
    return null;
  }
  final onClause = decl.onClause;
  if (onClause == null) {
    log.warning('[hot_patch_generator] $sourcePath: extension $label 缺少 on 子句，'
        '已跳过。');
    return null;
  }
  final extendedType = onClause.extendedType;
  final target = extendedType is NamedType
      ? extendedType.name2.lexeme
      : extendedType.toSource().trim();
  if (_unsupportedTargets.contains(target)) {
    log.warning(
      '[hot_patch_generator] $sourcePath: extension $label 的目标 $target '
      '在 JS 侧没有单一类型（Map/Object/dynamic…），已跳过。',
    );
    return null;
  }
  if (hostWrapperTypes.contains(target)) {
    // 宿主 widget 的 JS 包装类是「构造即产出元素」：把成员挂到它的原型上不会
    // 作用到宿主真对象，属于必然无效的注册，构建期直接拒绝。
    log.warning(
      '[hot_patch_generator] $sourcePath: extension $label 的目标 $target 是'
      '宿主 widget（JS 侧没有实体原型），已跳过。',
    );
    return null;
  }

  final classInfo = classTable[target];
  final targetPkg = classInfo == null ? null : packageNameOf(classInfo.sourceFile);
  if (classInfo != null &&
      targetPkg != null &&
      nonTranslatedPackages.contains(targetPkg)) {
    log.warning(
      '[hot_patch_generator] $sourcePath: extension $label 的目标 $target '
      '来自未翻译的框架包（$targetPkg），JS 侧没有代理类，已跳过。',
    );
    return null;
  }
  final known = _coreTargets.contains(target) ||
      runtimeGlobalTypes().contains(target) ||
      runtimeTypeAliases().contains(target) ||
      jsClassWidgets.contains(target) ||
      classInfo != null;
  if (!known) {
    log.warning(
      '[hot_patch_generator] $sourcePath: extension $label 的目标 $target '
      '在本文件可见范围内找不到 JS 侧实现，注册会失败，已跳过。',
    );
    return null;
  }

  // 目标表达式：能找到 JS 产物 → 直接传构造函数（同一个模块表保证是同一个类）；
  // 否则传类型名，由运行时按「核心映射 → 私有别名 → G[name]」解析。
  String targetJs;
  String? targetImport;
  final targetProduct = productOf?.call(target);
  if (targetProduct != null) {
    targetJs = target;
    if (targetProduct != ownProduct) {
      targetImport = "import { $target } from "
          "'${relativeProduct(ownProduct, targetProduct)}';";
    }
  } else if (jsClassWidgets.contains(target)) {
    // 有 JS 类、但不在本文件 import 图里的框架组件（provider 等）：按 package 模块取类。
    targetJs = target;
    targetImport = "import { $target } from "
        "'${relativeProduct(ownProduct, packageModulePath(widgetPackageOf(target)))}';";
  } else {
    targetJs = jsString(target);
    if (classInfo != null) {
      // 类在本文件可见（import 到的普通类），但没有可 import 的 JS 产物
      // （不在组件产物图里，也不在 package 模块里）。运行时按类型名 `G[name]`
      // 兜底，而生成的类都包在模块 IIFE 内、不挂 G → 注册会失败。
      // 出声提示（不阻断构建）：该扩展在 JS 侧不会生效。
      log.warning(
        '[hot_patch_generator] $sourcePath: extension $label 的目标 $target '
        '在 ${classInfo.sourceFile} 里，但那个文件没有本文件可引用的 JS 产物'
        '（未被任何组件引用），该扩展在 JS 侧不会生效。',
      );
    }
  }

  // 成员建模：与类完全同一口径（getter / setter 都保留，static 另放）。
  final memberMethods = <ClassMethod>[];
  final memberKinds = <String, String>{};
  for (final member in decl.members) {
    if (member is MethodDeclaration) {
      if (member.isStatic) continue;
      final memberName = member.name.lexeme;
      if (member.isGetter) {
        memberKinds[memberName] = 'getter';
        memberMethods.add(ClassMethod(
          name: memberName,
          params: const [],
          isGetter: true,
          returnsWidget: returnsWidgetOf(member),
          body: member.body,
        ));
      } else if (member.isSetter) {
        memberKinds[memberName] = 'setter';
        memberMethods.add(ClassMethod(
          name: memberName,
          params: jsMethodParams(member),
          isVoid: true,
          returnsWidget: false,
          body: member.body,
        ));
      } else {
        memberKinds[memberName] = 'method';
        memberMethods.add(ClassMethod(
          name: memberName,
          params: jsMethodParams(member),
          isAsync: member.body.isAsynchronous,
          isVoid: isVoidReturn(member),
          returnsWidget: returnsWidgetOf(member),
          body: member.body,
        ));
      }
    } else if (member is ConstructorDeclaration) {
      log.warning('[hot_patch_generator] $sourcePath: extension $label 里声明了'
          '构造函数（Dart 不允许），已忽略。');
    }
  }

  // 依赖：整个扩展声明里出现的类型引用（成员体 / 初始化器 / 字段类型 /
  // `on` 目标），与类共用同一个收集器——不另写扩展专用的启发式。
  final used = <String, ClassInfo>{};
  for (final n in dependenciesOf(decl)) {
    final info = classTable[n];
    if (info != null) used[n] = info;
  }

  final hostMethods = buildHostMethods(unit, sourcePath);
  final modelClassNames = <String>{
    for (final e in classTable.entries)
      if (!e.value.isComponent) e.key,
  };
  final parseCtx = ElementTranslateContext(
    propByField: const {},
    actionByMethod: {
      for (final m in memberMethods)
        if (!m.isGetter && !m.isVoid) m.name: m.name,
    },
    methodNames: {for (final m in memberMethods) m.name},
    getterNames: {
      for (final m in memberMethods)
        if (m.isGetter) m.name,
    },
    sourcePath: sourcePath,
    importResolver: importResolver,
    globalConsts: globalConsts,
    hostMethods: hostMethods,
    jsClassWidgets: jsClassWidgets,
    delegateClassWidgets: delegateClassWidgets,
    ignoredTypes: ignoredTypes,
    modelClassNames: modelClassNames,
  );

  // 扩展没有实例字段：作用域里只有形参 / 局部变量 / 本扩展的其它成员（`this`
  // 就是接收者，故成员间调用落成 `this.xxx(...)`）。
  final hostInfo = ClassInfo(
    name: label,
    sourceFile: sourcePath,
    instanceFields: const [],
    staticFields: const [],
    methods: memberMethods,
    isComponent: false,
  );

  final membersJs = <String, String>{};
  parseCtx.withExprRenderer(() {
    for (final m in memberMethods) {
      final body = translateClassMethodBody(
        hostInfo,
        m,
        used,
        hostMethods: hostMethods,
        renderer: parseCtx,
        globalConsts: globalConsts,
        depth: 0,
      );
      switch (memberKinds[m.name]) {
        case 'getter':
          membersJs[m.name] = '{ get: function () {\n$body\n} }';
        case 'setter':
          membersJs[m.name] =
              '{ set: function (${m.params.join(', ')}) {\n$body\n} }';
        default:
          final fn = m.isAsync ? 'async ' : '';
          membersJs[m.name] =
              '${fn}function (${m.params.join(', ')}) {\n$body\n}';
      }
    }
  });

  // 静态成员：与实例成员同一条翻译（静态里 `this` 是类本身，与 Dart 一致）。
  final staticsEntries = <String>[];
  for (final member in decl.members) {
    if (member is MethodDeclaration && member.isStatic) {
      final memberName = member.name.lexeme;
      final info = ClassMethod(
        name: memberName,
        params: member.isGetter ? const [] : jsMethodParams(member),
        isGetter: member.isGetter,
        isAsync: member.body.isAsynchronous,
        isVoid: isVoidReturn(member),
        returnsWidget: returnsWidgetOf(member),
        body: member.body,
      );
      final body = parseCtx.withExprRenderer(() => translateClassMethodBody(
            hostInfo,
            info,
            used,
            hostMethods: hostMethods,
            renderer: parseCtx,
            globalConsts: globalConsts,
            depth: 0,
          ));
      if (member.isGetter) {
        staticsEntries.add('get $memberName() {\n$body\n}');
      } else {
        final fn = info.isAsync ? 'async ' : '';
        staticsEntries.add(
            '$memberName: ${fn}function (${info.params.join(', ')}) {\n$body\n}');
      }
    } else if (member is FieldDeclaration) {
      if (!member.isStatic) {
        log.warning('[hot_patch_generator] $sourcePath: extension $label 里声明了'
            '实例字段（Dart 不允许），已忽略。');
        continue;
      }
      for (final v in member.fields.variables) {
        final value = literalToJs(v.initializer);
        if (value == null) {
          log.warning('[hot_patch_generator] $sourcePath: extension $label 的静态'
              '字段 ${v.name.lexeme} 初值不是编译期常量，已跳过。');
          continue;
        }
        staticsEntries.add('${v.name.lexeme}: $value');
      }
    }
  }

  return ExtensionInfo(
    name: name ?? '',
    id: '$sourcePath#${name ?? '@on:$target'}',
    targetJs: targetJs,
    targetImport: targetImport,
    membersJs: membersJs,
    staticsEntries: staticsEntries,
    // 目标类本身也是依赖：同文件声明的目标类必须连带产出（`__jsExtension(ProbeModel,
    // …)` 裸引用它）；类表里有它但本产物没有 → ReferenceError。
    dependencies: {
      ...parseCtx.dependencies,
      ...used.keys,
      if (classNamesInUnit.contains(target)) target,
    },
    usedWidgetPackages: parseCtx.usedWidgetPackages,
  );
}
