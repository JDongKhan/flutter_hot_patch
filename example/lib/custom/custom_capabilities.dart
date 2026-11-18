// ===== 开发者自定义能力清单 =====
//
// 能力实现放在 `lib/custom/<能力名>/` 下（`JsUiLibrary` 子类 + 宿主桥接），
// 这里只维护**清单本身**。注入由 `main()` 里的 `initJsUi(libraries: ...)` 一次
// 完成（注册 + 通道就位 + 宿主组件建表 + 内建宿主方法），dynamic_flutter 包零改动。
//
// 新增能力：写一个 `JsUiLibrary` 子类，追加到下面的清单末尾即可。
import 'package:dynamic_flutter/dynamic_flutter.dart';

import 'easy_refresh/easy_refresh_library.dart';
import 'note_object/note_object_library.dart';
import 'visibility_detector/custom_visibility_detector_library.dart';
import 'waterfall_flow/waterfall_flow_library.dart';

/// 本工程自定义能力清单（顺序 = `ensureChannels` / `registerWidgets` 遍历顺序）。
const List<JsUiLibrary> customJsUiLibraries = [
  // VisibilityDetector（曝光/可见性检测）：布局阶段回传可见性变化。
  CustomVisibilityDetectorLibrary(),
  // EasyRefresh（三方包 easy_refresh）：下拉刷新容器 + 控制器句柄桥。
  CustomEasyRefreshLibrary(),
  // WaterfallFlow（三方包 waterfall_flow）：瀑布流容器 + 布局 delegate 还原。
  CustomWaterfallFlowLibrary(),
  // NoteObject（自定义实例对象绑定）：JS 同名类 ↔ 宿主真实实例。
  NoteObjectLibrary(),
];
