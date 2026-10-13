/// 「@UIComponent 可达文件」集合：确定「哪些文件产出 JS 产物」的唯一判据。
///
/// 规则（与用户口径一致）：
///   - 文件里有 `@UIComponent` 类 → **根文件**，产出产物；
///   - 否则只有被某个根文件沿 import 链（可传递）依赖时才产出。
///     数据的可翻译性由「被引用」决定，与模型类（`model/user.dart`）同理——
///     没被任何注解组件引用的入口页 / 展示页（`main.dart`、
///     `widget_showcase.dart`、`detail_pages.dart`）不再产出 JS，
///     否则会凭空多出空 `build()` 的坏产物与大把告警。
///
/// 遍历在两类文件处停止（它们不会出现在任何 JS 产物里，其 import 自然无需深入）：
///   - `@UIComponentIgnore` 文件（显式退出翻译，产物里是 Component 占位结点）；
///   - `@HostInjected` 类所在文件（跨库不可见，只在宿主侧实现）。
library;

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';

import '../../translator/source_index.dart';

/// 包内全部 Dart 源码（与 host_register builder 同一扫描口径）。
final Glob _libDartSources = Glob('lib/**.dart');

/// 计算「注解组件可达文件」集合（asset 路径，如 `lib/app/pages/home_page.dart`）。
///
/// 每次调用会扫描整包 `lib/**.dart`（`readAsString` 同时登记依赖：被扫描的文件
/// 改动会触发本步骤重跑），因此调用方应只在确实需要判定时调用——
/// 带 `@UIComponent` 的根文件不必调用。
Future<Set<String>> componentReachableFiles(BuildStep buildStep) async {
  final units = <String, CompilationUnit>{};
  await for (final id in buildStep.findAssets(_libDartSources)) {
    // 生成代码（*.g.dart 等）不参与依赖图。
    if (id.path.endsWith('.g.dart')) continue;
    final content = await buildStep.readAsString(id);
    units[id.path] = parseString(
      content: content,
      throwIfDiagnostics: false,
      path: id.path,
    ).unit;
  }

  final queue = <String>[
    for (final e in units.entries)
      if (_hasComponentAnnotation(e.value)) e.key,
  ];
  final reachable = <String>{};
  while (queue.isNotEmpty) {
    final file = queue.removeLast();
    if (!reachable.add(file)) continue;
    final unit = units[file];
    // 「不参与翻译」的文件仍算可达（自身产出为空，会自行退出），
    // 但不再沿它的 import 深入。
    if (unit == null || _isTranslationStop(unit)) continue;
    for (final imported in resolveImportFiles(unit, file)) {
      if (units.containsKey(imported)) queue.add(imported);
    }
  }
  return reachable;
}

/// 文件里有 `@UIComponent` 类 → 根文件。
bool _hasComponentAnnotation(CompilationUnit unit) => unit.declarations
    .whereType<ClassDeclaration>()
    .any((d) => findAnnotation(d.metadata, 'UIComponent') != null);

/// 本文件**产出为空**（没有任何 public 可翻译类）→ 它的 import 不会被任何 JS
/// 产物引用，遍历到此为止。判据与 builder 自身的产出条件对齐：
///   - 有 `@UIComponent` 类 → 根文件，产出；
///   - 有 public 且未被 `@UIComponentIgnore` / `@HostInjected` 标记的类 → 产出；
///   - 其余（三个 tab 页这类 `@UIComponentIgnore` 页、宿主能力门面）→ 不产出。
bool _isTranslationStop(CompilationUnit unit) {
  for (final d in unit.declarations.whereType<ClassDeclaration>()) {
    if (findAnnotation(d.metadata, 'UIComponent') != null) return false;
    final name = d.name.lexeme;
    if (name.startsWith('_') || d.abstractKeyword != null) continue;
    if (_isIgnoredOrHostInjected(d)) continue;
    return false;
  }
  return true;
}

/// 类是否显式退出翻译（`@UIComponentIgnore`）或只在宿主侧实现
/// （类级 / 方法级 `@HostInjected`）。
bool _isIgnoredOrHostInjected(ClassDeclaration d) =>
    findAnnotation(d.metadata, 'UIComponentIgnore') != null ||
    findAnnotation(d.metadata, 'HostInjected') != null ||
    d.members
        .whereType<MethodDeclaration>()
        .any((m) => findAnnotation(m.metadata, 'HostInjected') != null);