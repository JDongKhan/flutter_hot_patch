// ===== UI 能力装配入口（启动期唯一调用点）=====
//
// **为什么需要它**：能力接入的两个钩子（`ensureChannels` / `registerWidgets`）
// 本身与页面无关，但它们的**触发时机**分散在三处——
//   1. `ensureChannels`：聚合在 `ensureJsUiCapabilities()`，原先只由
//      `JsUiWidget.initState` 调用；
//   2. `registerWidgets`：由 `jsWidgetRegistry` 懒建单例触发，首次访问时
//      **一次性**执行；
//   3. 内建宿主方法：`registerBuiltinHostMethods()`，同样由 initState 触发。
//
// 分散触发有两个真实代价：首帧要顺带做注册工作；App 侧若想在启动时就把能力
// 装好，必须自己记住三者的顺序（且必须先 `registerJsUiLibrary`、再 ensure、
// 最后触发建表，顺序错一步就静默漏注册）。
//
// 本文件把三件事收成**一个入口** [initJsUi]：传 libraries 即可同时完成
// 「注册自定义能力 + 通道就位 + 宿主组件建表 + 内建宿主方法」。
// `JsUiWidget.initState` 仍然调用它——那是**幂等兜底**（App 忘了调也能用），
// 不是第二条实现路径：所有钩子的幂等性由各自的 `ensure*` 内建标记保证。
//
// **顺序约束（提前调用时必须满足）**：
//   - binding 先于一切能力钩子：`MediaQueryLibrary.ensureChannels` 里直接
//     `WidgetsBinding.instance.addObserver(...)`，没有 binding 会抛异常。本入口
//     先调 `WidgetsFlutterBinding.ensureInitialized()`（幂等，与 `runApp` 同 zone
//     调用即可满足 Zone 一致性要求）；
//   - 注册表建表晚于库注册：建表后注册的库拿不到 `registerWidgets`，
//     `registerJsUiLibrary` 会告警（见 js_widget_registry 的 jsWidgetRegistryBuilt）；
//   - 通道就位早于任何 JS mount（`new XxxController` → host 登记）与
//     `ensureJsUiRuntime`（runtime.js 各能力片段的宿主侧登记依赖已就位的 kind /
//     context op）。
import 'package:flutter/widgets.dart';

import '../../services/builtin_host_methods.dart';
import 'js_ui_capabilities.dart';
import 'js_ui_library.dart';

bool _initialized = false;

/// 是否已经执行过 [initJsUi]。
bool get jsUiInitialized => _initialized;

/// UI 能力装配**唯一入口**：注册能力库 → 就位全部通道 → 建宿主组件表 →
/// 注册内建宿主方法。建议在 App `main()` 里 `runApp` 之前调用一次。
///
/// ```dart
/// void main() {
///   initJsUi(libraries: const [
///     CustomVisibilityDetectorLibrary(),
///     CustomEasyRefreshLibrary(),
///     CustomWaterfallFlowLibrary(),
///   ]);
///   runApp(const App());   // 装配完成后再启动
/// }
/// ```
///
/// [libraries] 是业务 / 三方库的能力清单（顺序 = `ensureChannels` /
/// `registerWidgets` 的遍历顺序，内建能力永远排在最前）。只传清单、不逐个
/// `registerJsUiLibrary`，就不会踩「建表后注册」的时序问题。
///
/// **幂等**：重复调用不会再建表、不会重复注册（`registerJsUiLibrary` 按 id 去重，
/// 各 `ensure*` 自带一次性标记）。二次调用时传入的新库仍会拿到通道就位，但
/// 组件映射拿不到——`registerJsUiLibrary` 会为此告警，属预期边界而不是静默。
void initJsUi({List<JsUiLibrary> libraries = const <JsUiLibrary>[]}) {
  // 能力钩子会摸 WidgetsBinding（如 MediaQuery 的 observer），先确保 binding 就绪。
  WidgetsFlutterBinding.ensureInitialized();
  // 1) 注册：必须在建表之前（建表只跑一次，registerWidgets 只在建表时回调）。
  for (final library in libraries) {
    registerJsUiLibrary(library);
  }
  // 2) 通道就位：句柄 kind、context op 等，必须早于任何 JS mount。
  ensureJsUiCapabilities();
  // 3) 建表：一次性注册全部「type → Flutter widget」映射，首帧不再做注册工作。
  ensureJsWidgetRegistry();
  // 4) 内建宿主方法（日志 / toast / commit / 资源 ...）：幂等，全局一次。
  registerBuiltinHostMethods();
  _initialized = true;
}
