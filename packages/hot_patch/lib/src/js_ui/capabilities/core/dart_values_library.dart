// ===== 基础能力：Dart 值类镜像（接入声明）=====
//
// Duration / Size / Offset / Radius 是跨能力的公共值对象（动画、布局、手势等
// 都可能下发），故作为**基础能力**最先注入，其它能力的 JS 片段可直接引用
// （如动画片段里的 `__durationMs`）。
import '../js_ui_library.dart';

/// 公共值类镜像的接入声明（无宿主通道、无组件映射，仅注入 JS 片段）。
class DartValuesLibrary extends JsUiLibrary {
  const DartValuesLibrary();

  @override
  String get id => 'dart-values';

}
