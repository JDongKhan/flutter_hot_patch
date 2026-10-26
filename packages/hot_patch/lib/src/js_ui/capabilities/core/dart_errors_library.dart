// ===== 基础能力：Dart 内置异常镜像（接入声明）=====
import '../js_ui_library.dart';

/// Dart 内置异常（StateError / ArgumentError / …）的接入声明。
///
/// 依赖 `__posArgs`（dart-values 能力），故注册顺序在它之后。
class DartErrorsLibrary extends JsUiLibrary {
  const DartErrorsLibrary();

  @override
  String get id => 'dart-errors';

}
