// ===== 基础能力：Color 类族（接入声明）=====
import '../js_ui_library.dart';

/// Color / MaterialColor / ColorSwatch 的同名类注入。
///
/// 依赖 `__posArgs`（dart-values 能力），故注册顺序在它之后。`Colors` 常量
/// 不在此处：由构建期从 SDK `colors.dart` 自动生成到 `flutter.js`。
class ColorLibrary extends JsUiLibrary {
  const ColorLibrary();

  @override
  String get id => 'color';

}
