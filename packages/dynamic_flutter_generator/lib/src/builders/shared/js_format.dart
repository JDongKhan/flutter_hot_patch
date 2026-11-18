/// 生成产物（JS）的缩进规范化。
///
/// 产物是逐层字符串拼装出来的：每个构造自己按传进来的 depth 缩进，外层再按
/// 「各行最小缩进」做一次归一（`_reindentMultiline`）。这套做法下，同一份 AST
/// 在不同拼装路径上会整体偏移 2 个空格——翻译层任何改动（哪怕语义无关）都会
/// 让大量无关产物出现纯格式 diff，评审时噪音淹没真实改动。
///
/// 这里在写出前做一次**只依赖括号嵌套深度**的重排：
///   - 行首缩进 = 2 × 当前未闭合的 `{` / `[` 层数；以 `}` / `]` 开头的行减一层；
///   - 字符串 / 模板串 / 注释里的内容原样保留，绝不改动；
///   - 空行不产生尾随空格。
///
/// 结果只由 AST 结构决定：同一份 Dart 源码始终产出完全相同的字节，
/// 与翻译层的拼装顺序解耦。重复执行是幂等的。
String canonicalizeJsIndent(String source) {
  final out = StringBuffer();
  var depth = 0;
  var i = 0;
  var lineStart = true;
  // null / 'single' / 'double' / 'template' / 'lineComment' / 'blockComment'
  String? mode;

  bool isSpace(String c) => c == ' ' || c == '\t';

  while (i < source.length) {
    // 行首：丢弃原有缩进，按括号深度重排（模板串内保留原样）。
    if (lineStart) {
      lineStart = false;
      if (mode == 'template') {
        // 模板串跨行内容原样输出。
      } else {
        var j = i;
        while (j < source.length && isSpace(source[j])) {
          j++;
        }
        final blank = j >= source.length || source[j] == '\n';
        i = j;
        final startsWithClose =
            j < source.length && (source[j] == '}' || source[j] == ']');
        if (blank) continue;
        final effective = depth - (startsWithClose ? 1 : 0);
        out.write('  ' * (effective < 0 ? 0 : effective));
      }
    }

    final c = source[i];

    if (mode == 'lineComment') {
      out.write(c);
      i++;
      if (c == '\n') {
        mode = null;
        lineStart = true;
      }
      continue;
    }
    if (mode == 'blockComment') {
      if (c == '*' && i + 1 < source.length && source[i + 1] == '/') {
        out.write('*/');
        i += 2;
        mode = null;
        continue;
      }
      out.write(c);
      i++;
      if (c == '\n') lineStart = true;
      continue;
    }
    if (mode == 'template') {
      if (c == r'\' && i + 1 < source.length) {
        out
          ..write(c)
          ..write(source[i + 1]);
        i += 2;
        continue;
      }
      out.write(c);
      i++;
      if (c == '`') {
        mode = null;
      } else if (c == '\n') {
        lineStart = true;
      }
      continue;
    }
    if (mode == 'single' || mode == 'double') {
      if (c == r'\' && i + 1 < source.length) {
        out
          ..write(c)
          ..write(source[i + 1]);
        i += 2;
        continue;
      }
      out.write(c);
      i++;
      if ((mode == 'single' && c == "'") || (mode == 'double' && c == '"')) {
        mode = null;
      }
      continue;
    }

    // 代码态
    if (c == '/' && i + 1 < source.length) {
      final next = source[i + 1];
      if (next == '/') {
        out.write('//');
        i += 2;
        mode = 'lineComment';
        continue;
      }
      if (next == '*') {
        out.write('/*');
        i += 2;
        mode = 'blockComment';
        continue;
      }
    }
    switch (c) {
      case "'":
        mode = 'single';
      case '"':
        mode = 'double';
      case '`':
        mode = 'template';
      case '{' || '[':
        depth++;
      case '}' || ']':
        depth--;
    }
    out.write(c);
    i++;
    if (c == '\n') lineStart = true;
  }
  return out.toString();
}
