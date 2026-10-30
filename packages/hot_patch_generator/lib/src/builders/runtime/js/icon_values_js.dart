import 'dart:convert';

import '../../shared/sdk_icons_index.dart';

/// SDK `IconData` 的默认字体族（与 `IconData` 构造的默认值一致）。
const _defaultFontFamily = 'MaterialIcons';

/// `IconData` 值类 + `Icons` 常量表（写进 `patch/flutter.js`）。
///
/// 与翻译层对偶：Dart 里 `Icons.edit` 是 `IconData` 常量对象，产物原样引用
/// `Icons.edit`，因此 JS 侧访问到的是**真实对象**。跨桥 `toJSON()` 发码点与
/// 字体族，宿主 `iconFromJson` 按对象还原（不再靠「图标名 → 手写表」的猜测）。
///
/// 表按 SDK 源码 `material/icons.dart` 自动抽取（见 [sdkIcons]），与 Dart 侧
/// 导出的常量一一对应，不存在漏项或未命中回退。
///
/// **表的存储形态**：8825 条常量若逐条写成 `new IconData({...})`，每条都会是一个
/// 独立的对象字面量站点（引擎按站点各留一份 boilerplate，V8 实测 533B/条、
/// 源码 1MB），而实际用到的往往只有几十个。因此这里把表压成一个分隔字符串
/// `name:code[|family][|R]`（R = matchTextDirection），`Icons` 用 Proxy 在**首次
/// 访问**时才实例化并缓存：文本约 220KB，堆占用与「真正用到的图标数」成正比
/// （未访问的只有字符串本身）。名字空间仍与 SDK 全量一致，不做项目级裁剪。
String iconValuesJsSource() {
  final icons = sdkIcons();
  final table = StringBuffer();
  var first = true;
  for (final i in icons.values) {
    if (!first) table.write(',');
    first = false;
    table
      ..write(i.name)
      ..write(':')
      ..write(i.codePoint);
    if (i.fontFamily != _defaultFontFamily) table.write('|${i.fontFamily}');
    if (i.matchTextDirection) table.write('|R');
  }
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
    ..writeln('  // 常量表：`name:code[|family][|R]`，逗号分隔（名字不含这三种分隔符）。')
    ..writeln('  const __ICON_SRC = ${jsonEncode(table.toString())};')
    ..writeln('  const __ICON_CACHE = new Map();')
    ..writeln('  // 名字 → IconData（命中即缓存，同一名字始终同一实例，对齐 Dart const 规范化）。')
    ..writeln('  function __iconOf(name) {')
    ..writeln('    var hit = __ICON_CACHE.get(name);')
    ..writeln('    if (hit !== undefined) { return hit; }')
    ..writeln('    var head = name + \':\';')
    ..writeln('    var at = -1;')
    ..writeln('    if (__ICON_SRC.slice(0, head.length) === head) {')
    ..writeln('      at = 0;')
    ..writeln('    } else {')
    ..writeln('      var found = __ICON_SRC.indexOf(\',\' + head);')
    ..writeln('      if (found < 0) { return undefined; }')
    ..writeln('      at = found + 1;')
    ..writeln('    }')
    ..writeln('    var end = __ICON_SRC.indexOf(\',\', at);')
    ..writeln('    var spec = end < 0 ? __ICON_SRC.slice(at) : __ICON_SRC.slice(at, end);')
    ..writeln('    var parts = spec.slice(head.length).split(\'|\');')
    ..writeln("    var family = '$_defaultFontFamily';")
    ..writeln('    var rtl = false;')
    ..writeln('    for (var k = 1; k < parts.length; k++) {')
    ..writeln("      if (parts[k] === 'R') { rtl = true; } else { family = parts[k]; }")
    ..writeln('    }')
    ..writeln('    var icon = new IconData({ codePoint: Number(parts[0]),')
    ..writeln('      fontFamily: family, matchTextDirection: rtl });')
    ..writeln('    __ICON_CACHE.set(name, icon);')
    ..writeln('    return icon;')
    ..writeln('  }')
    ..writeln('  // `Icons`：与 SDK 常量表同名一一对应的只读视图。表里没有的名字（含')
    ..writeln('  // toString 这类对象方法）落回普通对象行为，与直接写对象字面量一致。')
    ..writeln('  export const Icons = new Proxy({}, {')
    ..writeln('    get: function (target, name) {')
    ..writeln("      if (typeof name !== 'string') { return Reflect.get(target, name); }")
    ..writeln('      var icon = __iconOf(name);')
    ..writeln('      return icon === undefined ? Reflect.get(target, name) : icon;')
    ..writeln('    }')
    ..writeln('  });');
  return b.toString();
}
