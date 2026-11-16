/// 与 extension_detail.dart 里的 `TagA` 同目标（String）同名（tag）的扩展。
///
/// 用途：验证显式调用 `TagB(x).tag()` 按扩展身份分派——同名成员不会互相抢注，
/// 隐式调用在 Dart 里本就是歧义编译错误，不做模拟。
extension TagB on String {
  String tag() => 'B';
}
