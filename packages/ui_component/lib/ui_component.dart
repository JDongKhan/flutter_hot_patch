/// ui_component —— 声明式 UI 组件注解包。
///
/// 用法：在类上标 [UIComponent]，字段标 [UIProp]，方法标 [UIAction]；
/// 构建期由 ui_component_generator 读取这些注解，生成对应的 JS 描述模块
/// （create / handleEvent），客户端用 JsWidget 加载渲染。
library;

export 'src/annotations.dart';
