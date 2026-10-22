/// 跨文件组件产物解析：import 源文件里有 JS 产物的组件类 → 产物路径。
///
/// 与类表（class_table）使用同一套「有产物」判定：@PatchEntry 注解类或
/// public widget 类；私有类 / @PatchIgnore / @HostInjected 不登记。
library;

import 'package:analyzer/dart/ast/ast.dart';

import '../../shared/host_injected.dart';
import '../../shared/paths.dart';
import '../../shared/source_index.dart';
import 'class_table.dart';

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
