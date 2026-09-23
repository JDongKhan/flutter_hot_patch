/// ui_component —— 声明式 UI 组件注解包。
///
/// 用法：在正常 widget 类上标 [UIComponent]；构建期由
/// ui_component_generator 默认全量收集字段/方法并生成对应的
/// JS 描述模块（build / handleEvent），客户端用 HotPatchWidget 加载渲染。
library;

export 'src/annotations.dart';
