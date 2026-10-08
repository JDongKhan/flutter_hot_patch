/// ui_component —— 声明式 UI 组件注解包。
///
/// 用法：在正常 widget 类上标 [UIComponent]；构建期由
/// ui_component_generator 默认全量收集字段/方法并生成对应的
/// JS 组件模块（build / 方法 / 状态），客户端用 JsUiWidget 加载渲染。
library;

export 'src/annotations.dart';
