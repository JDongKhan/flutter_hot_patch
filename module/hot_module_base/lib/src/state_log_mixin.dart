import 'package:flutter/widgets.dart';

/// 给 State 扩展功能的 mixin（**跨包**声明，用于验证生成器对 mixin 的翻译）。
///
/// 用法：`class _FooState extends State<Foo> with StateLogMixin<Foo>`，
/// 之后在 State 里直接调用 [logState] 打日志，无需再定义一遍。
///
/// 目前只做日志（后续 mixin 能力落地时再补状态相关的通用方法）。
mixin StateLogMixin<T extends StatefulWidget> on State<T> {
  /// 打印一条状态日志：`[StateLogMixin] xxx`。
  void logState(String message) {
    // ignore: avoid_print
    print('[StateLogMixin] $message');
  }
}
