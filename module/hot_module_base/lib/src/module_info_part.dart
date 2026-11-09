part of 'module_symbols.dart';

/// 顶层常量 [moduleBaseInfo] 的载体：声明在 part 文件里，产物随库根
/// `module_symbols.js` 发射（part 自身不产出 JS）。
class ModuleBaseInfo {
  const ModuleBaseInfo({required this.id});

  final int id;
}
