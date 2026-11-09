/// 顶层常量 / 枚举 / 顶层函数：验证 barrel 的 `export` 转发（含 show / hide）
/// 与跨包产物按「被引用」发射。
library;

/// 顶层常量：barrel 转发后可用 `base.moduleBaseTag` 引用。
const String moduleBaseTag = 'module-base';

/// 顶层常量引用的跨文件模型（验证跨包产物按需补 import）。
const ModuleBaseInfo moduleBaseInfo = ModuleBaseInfo(id: 7);

/// 枚举：与顶层常量同一产物形态（`export const ModuleBaseLevel = ...`）。
enum ModuleBaseLevel { low, high }

/// 引用本文件枚举的顶层常量：barrel 需同时转发枚举与常量。
const ModuleBaseLevel moduleBaseHigh = ModuleBaseLevel.high;

/// 顶层函数：barrel 转发后可用 `base.moduleBaseLabel()` 调用。
String moduleBaseLabel({String prefix = 'tag'}) =>
    '$prefix:$moduleBaseTag/${moduleBaseInfo.id}';

/// 枚举值的文本形态：在声明文件内解析枚举，跨文件只按顶层函数转发。
String moduleBaseLevelText() => ModuleBaseLevel.high.name;

/// 顶层常量 [moduleBaseInfo] 的载体。
class ModuleBaseInfo {
  const ModuleBaseInfo({required this.id});

  final int id;
}
