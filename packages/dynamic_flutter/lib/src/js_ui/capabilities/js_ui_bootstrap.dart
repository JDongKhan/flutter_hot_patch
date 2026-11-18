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
// **它必须由 App 自己调用**（`main()` 里、`runApp` 之前）；`JsUiWidget` 不再
// 代劳，只在启动时用 [assertJsUiInitialized] 校验契约——debug 直接断言失败，
// release 记一条 error（禁止「没装配 → 页面静默变占位」）。
//
// **顺序约束（调用时必须满足）**：
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
import '../../services/js_runtime_manager.dart';
import '../../utils/dynamic_flutter_log.dart';
import 'js_ui_capabilities.dart';
import 'js_ui_library.dart';

bool _initialized = false;

/// 是否已经执行过 [initJsUi]。
bool get jsUiInitialized => _initialized;

/// 通过 [initJsUi] 注册过的宿主通道名（重复装配时去重，避免 `registerHostMethod`
/// 在 debug 下因「通道名重复」断言）。
final Set<String> _registeredHostMethodNames = <String>{};

/// UI 能力装配**唯一入口**：注册能力库 → 就位全部通道 → 建宿主组件表 →
/// 注册内建宿主方法 → 注册业务宿主方法。**必须**在 App `main()` 里 `runApp`
/// 之前调用一次。
///
/// ```dart
/// void main() {
///   initJsUi(
///     libraries: customJsUiLibraries,   // 自定义 / 三方能力
///     hostMethods: hostMethods,         // @HostInjected 生成清单
///   );
///   runApp(const App());   // 装配完成后再启动
/// }
/// ```
///
/// [libraries] 是业务 / 三方库的能力清单（顺序 = `ensureChannels` /
/// `registerWidgets` 的遍历顺序，内建能力永远排在最前）。只传清单、不逐个
/// `registerJsUiLibrary`，就不会踩「建表后注册」的时序问题。
///
/// [hostMethods] 是宿主方法清单，每项形状固定：`{'name': 通道名, 'handler': 实现}`。
/// 通常直接传生成器产出的 `hostMethods`（`lib/generated/host_methods.dart`），
/// 无需再逐个 `JsRuntimeManager.registerHostMethod`。通道名与内建通道重名会在
/// debug 断言失败（通道名必须唯一）。
///
/// **幂等**：重复调用不会再建表、不会重复注册（`registerJsUiLibrary` 按 id 去重，
/// 各 `ensure*` 自带一次性标记，宿主方法按通道名去重）。二次调用时传入的新库仍会
/// 拿到通道就位，但组件映射拿不到——`registerJsUiLibrary` 会为此告警，属预期边界
/// 而不是静默。
void initJsUi({
  List<JsUiLibrary> libraries = const <JsUiLibrary>[],
  List<Map<String, Object?>> hostMethods = const <Map<String, Object?>>[],
}) {
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
  // 5) 业务宿主方法（@HostInjected 生成清单）：与内建通道共用同一张表。
  _registerHostMethods(hostMethods);
  _initialized = true;
}

/// 注册业务宿主方法清单：形状不对直接抛（启动期配置错误，不能静默跳过）。
void _registerHostMethods(List<Map<String, Object?>> hostMethods) {
  for (final entry in hostMethods) {
    final name = entry['name'];
    final handler = entry['handler'];
    if (name is! String || name.isEmpty) {
      throw ArgumentError.value(
        entry,
        'hostMethods',
        "每项必须是 {'name': 非空通道名, 'handler': 宿主实现}",
      );
    }
    if (handler is! Function) {
      throw ArgumentError.value(
        entry,
        'hostMethods',
        "通道 \"$name\" 缺少 Function 类型的 'handler'",
      );
    }
    if (!_registeredHostMethodNames.add(name)) {
      JsLog.warn('dynamic_flutter: initJsUi 重复装配宿主方法 "$name"，已忽略后续项');
      continue;
    }
    JsRuntimeManager.registerHostMethod(name, handler);
  }
}

bool _missingReported = false;

/// 契约校验：[initJsUi] 必须由 App 在 `main()` 里调用。
///
/// `JsUiWidget` 启动时调本函数，**不代劳装配**：
///   - debug / profile：直接断言失败，错误信息指向漏调点（早崩好过空白页）；
///   - release：断言被裁掉，记一条 error 日志（只报一次，不随页面数量刷屏）。
void assertJsUiInitialized() {
  if (_initialized) return;
  assert(
    _initialized,
    'dynamic_flutter: 尚未调用 initJsUi()。请在 App 的 main() 里、runApp 之前调用 '
    'initJsUi(libraries: [...])（能力注册 / 通道就位 / 宿主组件建表 / 内建宿主方法'
    '都在那一次完成）；JsUiWidget 不再自动装配。',
  );
  if (_missingReported) return;
  _missingReported = true;
  JsLog.error('dynamic_flutter: 尚未调用 initJsUi()——JS 组件会渲染成未注册占位。'
      '请在 main() 里、runApp 之前调用 initJsUi(libraries: [...])。');
}
