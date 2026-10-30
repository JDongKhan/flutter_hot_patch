import '../../shared/sdk_enum_index.dart';

/// SDK 枚举的 JS 值类（写进 `patch/flutter.js`）。
///
/// 与翻译层严格对偶：Dart 里 `Owner.member` 是**常量对象**，产物里原样引用
/// `Owner.member`（见 value_forms.dart），因此 JS 侧也必须是一个真实类，静态
/// 成员就是这个类的实例。这样 `.name` / `.index` / `values` / 判等 / `switch`
/// 全部与 Dart 语义一致，不再靠「按类型转成员名字符串」的翻译特判。
///
/// 跨桥形态保持不变（已发布协议）：`toJSON()` 返回成员名字符串，宿主既有的
/// `xxxFromJson` 无需改动。
///
/// 只生成**公开**枚举；带常量参数的枚举由 [sdkPublicEnums] 在构建期出声跳过。
String enumValuesJsSource() {
  final enums = sdkPublicEnums();
  final b = StringBuffer()
    ..writeln()
    ..writeln('  // ===== SDK 枚举值类（由源码 enum 声明自动生成，勿手改）=====')
    ..writeln('  // 翻译层对 `Owner.member` 一律原样引用，跨桥 toJSON() 发成员名。');
  for (final e in enums.values) {
    final n = e.name;
    b
      ..writeln()
      ..writeln('  export class $n {')
      ..writeln('    constructor(name, index) {')
      ..writeln('      this.name = name;')
      ..writeln('      this.index = index;')
      ..writeln('    }')
      ..writeln('    toJSON() { return this.name; }')
      ..writeln("    toString() { return '$n.' + this.name; }");
    for (var i = 0; i < e.members.length; i++) {
      final m = e.members[i];
      b.writeln("    static $m = new $n('$m', $i);");
    }
    b
      ..writeln('  }')
      ..writeln('  $n.values = [${e.members.map((m) => '$n.$m').join(', ')}];');
  }
  return b.toString();
}
