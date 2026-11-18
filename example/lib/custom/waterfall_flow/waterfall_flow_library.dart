// ===== 自定义能力：WaterfallFlow 瀑布流（三方包 waterfall_flow）=====
//
// 登记本能力 id 并把组件渲染函数挂到 [JsWidgetRegistry]；桥接细节见
// `waterfall_flow_bridge.dart`。
import 'package:dynamic_flutter/dynamic_flutter.dart';

import 'waterfall_flow_bridge.dart';

/// 瀑布流（WaterfallFlow）能力接入声明。
class CustomWaterfallFlowLibrary extends JsUiLibrary {
  const CustomWaterfallFlowLibrary();

  @override
  String get id => 'waterfall_flow';

  @override
  void registerWidgets(JsWidgetRegistry r) => registerWaterfallFlowWidgets(r);
}
