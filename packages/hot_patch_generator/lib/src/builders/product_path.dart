/// 产物路径推导：源文件 → JS 产物路径、产物间相对路径、跨文件组件产物解析。
///
/// 产物路径与 build.yaml 的 build_extensions 保持一致（`lib/a/b.dart` →
/// `patch/a/b.js`，直接镜像 lib 路径、文件名与源文件同名），不预设固定目录名。
library;

import 'package:analyzer/dart/ast/ast.dart';

import '../translator/host_injected.dart';
import '../translator/source_index.dart';
import 'patch_entry/class_table.dart';

/// 源文件路径 → 产物路径（与 build.yaml 的 build_extensions 一致）：
/// `lib/a/b.dart` → `patch/a/b.js`（**直接镜像 lib 路径、文件名与源文件
/// 同名**，不预设 `components` 之类固定目录名，也不区分组件/模型）。
String productPath(String sourcePath) {
  if (!sourcePath.startsWith('lib/')) return sourcePath;
  final rel = sourcePath.substring('lib/'.length); // a/b.dart
  if (!rel.endsWith('.dart')) return sourcePath;
  return 'patch/${rel.substring(0, rel.length - '.dart'.length)}.js';
}

/// 两个产物绝对路径 → 相对路径（相对第一个产物所在目录）。
/// 如 'patch/foo_component.js' → 'patch/sub/bar_component.js'
/// 得 'sub/bar_component.js'；跨目录时含 '../'。
String relativeProduct(String from, String to) {
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
/// 「有产物」判定与**本文件根类收集完全同口径**（见 class_table.isWidgetClassDecl）：
/// 带 **@PatchEntry 注解**的类，或 **public 的 widget 类**（继承
/// StatefulWidget / StatelessWidget）——后者与模型文件一样，所在文件会产出同名
/// JS 产物，因此跨文件引用可以直接 import，无需再让使用方逐个补注解。**不按
/// 方法名判断**（build / buildText / 任何返回 widget 的方法一律等价）。
///
/// 不产出产物的类（拿不到 JS，运行时走宿主 registerNativeComponent 注册的原生实现）：
///   - 私有类：私有名不可能出现在别的文件里，不进表；
///   - **@PatchIgnore**：显式「不参与连带转换」；
///   - **@HostInjected**：方法实现留在 Dart，调用点被翻译为 `_app_host_.invoke`。
///
/// 按**类名**绑定（而非「第一条 import」），多 import 文件不会串台；命中即让
/// build 树里的组件结点渲染成类引用元素并 import 该产物。
Map<String, String> resolveImportedComponentProducts(
  CompilationUnit unit,
  String sourcePath,
) {
  final out = <String, String>{};
  for (final file in resolveImportFiles(unit, sourcePath)) {
    final importUnit = parseUnitFile(file);
    if (importUnit == null) continue;
    for (final decl in importUnit.declarations.whereType<ClassDeclaration>()) {
      final name = decl.name.lexeme;
      if (name.startsWith('_') || decl.abstractKeyword != null) continue;
      if (!isWidgetClassDecl(decl)) continue;
      if (findAnnotation(decl.metadata, 'PatchIgnore') != null) continue;
      if (classHasHostInjectedMethod(decl)) continue;
      out[name] = productPath(file);
    }
  }
  return out;
}