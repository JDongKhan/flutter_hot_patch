import '../../shared/sdk_icons_index.dart';

/// `IconData` 值类 + `Icons` 常量表（写进 `patch/flutter.js`）。
///
/// 与翻译层对偶：Dart 里 `Icons.edit` 是 `IconData` 常量对象，产物原样引用
/// `Icons.edit`，因此 JS 侧是**真实对象**。跨桥 `toJSON()` 发码点与字体族，
/// 宿主 `iconFromJson` 按对象还原（不再靠「图标名 → 手写表」的猜测）。
///
/// 表按 SDK 源码 `material/icons.dart` 自动抽取（见 [sdkIcons]），与 Dart 侧
/// 导出的常量一一对应，不存在漏项或未命中回退。
String iconValuesJsSource() {
  final icons = sdkIcons();
  final b = StringBuffer()
    ..writeln()
    ..writeln('  // ===== IconData / Icons（由 SDK icons.dart 自动生成，勿手改）=====')
    ..writeln('  export class IconData {')
    ..writeln('    constructor(props) {')
    ..writeln('      this.codePoint = props.codePoint;')
    ..writeln('      this.fontFamily = props.fontFamily == null ? null : props.fontFamily;')
    ..writeln('      this.matchTextDirection = props.matchTextDirection === true;')
    ..writeln('    }')
    ..writeln('    toJSON() {')
    ..writeln('      return { codePoint: this.codePoint, fontFamily: this.fontFamily,')
    ..writeln('        matchTextDirection: this.matchTextDirection };')
    ..writeln('    }')
    ..writeln('  }')
    ..writeln()
    ..writeln('  export const Icons = {');
  for (final i in icons.values) {
    b.writeln("    ${i.name}: new IconData({ codePoint: ${i.codePoint}, "
        "fontFamily: '${i.fontFamily}', "
        "matchTextDirection: ${i.matchTextDirection} }),");
  }
  b.writeln('  };');
  return b.toString();
}
