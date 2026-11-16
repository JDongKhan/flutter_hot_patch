// ===== 基础能力：Dart 内置异常镜像（接入声明）=====
import '../js_ui_library.dart';

/// Dart 内置异常（StateError / ArgumentError / …）的接入声明。
///
/// JS 实现在 `flutter.js` 值类区（`export const StateError = …`），依赖同模块
/// dart-values 的 `__positionalArgs`；本类只保留宿主侧能力登记。
class DartErrorsLibrary extends JsUiLibrary {
  const DartErrorsLibrary();

  @override
  String get id => 'dart-errors';

}
