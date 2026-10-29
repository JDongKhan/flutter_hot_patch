/// 给 String 扩展打印日志的方法（**跨包**声明，用于验证生成器对 extension 的翻译）。
///
/// 用法：`'hello'.logText()`，输出 `[StringLogExtension] hello`。
extension StringLogExtension on String {
  /// 打印当前字符串：`[tag] $this`。
  void logText([String tag = 'StringLogExtension']) {
    // ignore: avoid_print
    print('[$tag] $this 依赖库日志');
  }
}
