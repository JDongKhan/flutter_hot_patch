// ===== 基础能力：父约束值（JS 侧片段）=====
//
// `LayoutBuilder` 的 builder 在 JS 侧执行，但父约束只有宿主布局阶段才知道：
// 宿主用真实 `LayoutBuilder` 承载该结点，布局时**调用结点 props 上的 builder
// 句柄**（`{__fn: id}`），参数是约束的 JSON。本片段负责把这份 JSON 折算成
// `BoxConstraints`（值类见 dart_values_js.dart），供 builder 按 Dart 语义读取。
//
// 无界维度（Dart 的 double.infinity）：`jsonEncode` 不能表达 Infinity，宿主统一
// 发 null，这里还原成 `+∞`——`maxWidth > maxHeight` 等比较语义与 Dart 完全一致。
const String layoutBuilderJsSource = r'''
  // 宿主下发的约束 JSON → BoxConstraints。
  // 挂 G：包模块（flutter.js）只能裸引用全局，IIFE 内的局部声明它看不见。
  G.__jsuiBoxConstraints = function (json) {
    json = json || {};
    return new BoxConstraints({
      minWidth: json.minWidth == null ? 0 : json.minWidth,
      maxWidth: json.maxWidth == null ? Infinity : json.maxWidth,
      minHeight: json.minHeight == null ? 0 : json.minHeight,
      maxHeight: json.maxHeight == null ? Infinity : json.maxHeight,
    });
  };
''';
