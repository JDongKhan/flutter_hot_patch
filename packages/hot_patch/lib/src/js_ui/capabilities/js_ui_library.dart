// ===== 能力接入模板（基座唯一的扩展缝）=====
//
// **设计初衷**：让「支持一个新能力」的全部改动**收敛在一个子类里**，
// hot_patch 的核心文件从此不再变动。这里的「能力」既包括 Flutter 等价物
// （Key / 各 Controller / BuildContext 代理 / NotificationListener），也包括
// 新引入的三方库（provider / GetX / Riverpod …）——两者机制完全一致。
//
// 一个能力在宿主侧的落点无非三类，本模板各留一个可重写钩子：
//   1. [jsFragments]      —— 仅**外部库**使用：App 在 runApp 前注册的库，
//                            片段在 `runtime.js` 之后求值（独立 IIFE，只能
//                            用全局出口 `__jsui` / `_app_host_`）。内建能力的
//                            JS 已随产物发布——核心机制写进 `patch/runtime.js`，
//                            库自己的 API 面写进该包的 `patch/<pkg>.js`
//                            （生成器 `builders/runtime/js/**`），内建库的该
//                            钩子为空。
//   2. [ensureChannels]   —— 幂等登记本能力用到的跨语言句柄 kind，以及把本库的
//                            `context.<op>(...)` 处理注册进核心的通用缝
//                            （`registerContextOp`，见 build_context_bridge.dart）；
//   3. [registerWidgets]  —— 本能力的宿主侧组件映射（`type` → Flutter widget）。
//
// **本类刻意没有 context 语义的钩子**：`context.watch/read` 是 provider 那类
// `extension BuildContextX on BuildContext`，属库自己；JS 侧补丁随该包的模块
// 发布（生成器 `builders/runtime/js/provider_module_js.dart` → `patch/provider.js`），
// 宿主侧经 `registerContextOp` 注册（见 capabilities/provider/context_ops.dart）。
// 核心不认识具体 op 名。
//
// 接入方式（二选一）：
//   - 内建：在下面的 [_seedBuiltins] 里 `registerJsUiLibrary(...)` 一行；
//   - 完全不动 hot_patch：在 App 自己的 `main()`（`runApp` 之前）调
//     `registerJsUiLibrary(GetxLibrary())` 即可。
//
// **不进模板的地基**（核心本体，不属于任何可插拔能力）：
//   - `ensureHandleChannels()`：句柄注册表本身，必须先于一切能力就绪；
//   - `registerBuiltinJsWidgets(r)`：Text/Column 等 Flutter 基础视觉组件；
//   - JS 骨架（mini-react / emit / host 桥）：见 runtime_js.dart。
//
// **边界（务必知晓）**：本模板覆盖的是**运行时/宿主侧**。若新库还要新增 UI
// 组件类型，其**编译期**翻译（hot_patch_generator 的统一翻译入口
// element_json.dart / value_forms.dart 与 `patch/<pkg>.js` 里的 JS 组件类）
// 属于另一条缝，不在本文件范围内。
import '../js_widget_registry.dart';
import 'animated_list/animated_list_library.dart';
import 'animation/animation_library.dart';
import 'build_context/build_context_library.dart';
import 'cached_network_image/cached_network_image_library.dart';
import 'change_notifier/change_notifier_library.dart';
import 'core/dart_values_library.dart';
import 'core/dart_errors_library.dart';
import 'core/color_library.dart';
import 'dialog/dialog_library.dart';
import 'dismissible/dismissible_library.dart';
import 'drag/drag_library.dart';
import 'drawer/drawer_library.dart';
import 'easy_refresh/easy_refresh_library.dart';
import 'focus/focus_library.dart';
import 'key/key_library.dart';
import 'keyboard_listener/keyboard_listener_library.dart';
import 'layout_builder/layout_builder_library.dart';
import 'media_query/media_query_library.dart';
import 'notification_listener/notification_listener_library.dart';
import 'pop_scope/pop_scope_library.dart';
import 'provider/provider_library.dart';
import 'scroll_controller/scroll_controller_library.dart';
import 'sliver_persistent_header/sliver_persistent_header_library.dart';
import 'tab/tab_library.dart';
import 'text_editing_controller/text_editing_controller_library.dart';

/// 能力在宿主的接入模板：**新增一个能力 = 继承本类 + 注册**。
///
/// 所有钩子都有空实现，子类只重写真正需要的那些；核心不 import 任何具体库。
abstract class JsUiLibrary {
  const JsUiLibrary();

  /// 库标识（幂等去重键、日志用）。
  String get id;

  /// 注入 JS 运行时的片段：**仅供 App 侧注册的外部库**使用。
  ///
  /// 内建能力的 JS 已在构建期拼进 `patch/runtime.js`（生成器
  /// `builders/runtime/js/**`，随补丁发布，修复无需发版），故内建库都返回空。
  /// 外部库的片段在 runtime.js 之后以独立 IIFE 求值，**不能**再引用核心闭包
  /// 内部函数（`registerScope` / `scopeOf` 等，它们不在全局），只能用 `__jsui`
  /// 与 `_app_host_`；需要核心能力的库应把代码并入运行时产物。
  List<String> get jsFragments => const [];

  /// 本库**随补丁包发布的独立 JS 模块**（相对补丁根目录的文件名，如
  /// `'provider.js'`）。
  ///
  /// 用于库自己的 API 面没跟核心机制同文件发布的场合：库的 JS 类产在
  /// `patch/<pkg>.js`（生成器按 package 出模块），而库对运行时提出的额外要求
  /// （作用域声明 / 扩展方法原型补丁）也写在该模块里。这些模块必须在**任何
  /// 组件 build 之前**求值，故由运行时就绪点统一加载（见
  /// `JsRuntimeManager._loadCapabilityModules`），不依赖页面产物是否 import 到它。
  ///
  /// 能力模块也走 `loadModule`（相对 import 递归、幂等），与组件产物 import
  /// 同一份文件时只求值一次。
  List<String> get jsModuleAssets => const [];

  /// 幂等登记本库的跨语言句柄 kind（宿主侧句柄注册表）。
  /// 在 JS 组件 mount（即 `new` 本库对象 → `reg(...)`）之前调用一次。
  void ensureChannels() {}

  /// 注册本库的宿主侧组件映射（`type` 字符串 → 真实 Flutter widget）。
  void registerWidgets(JsWidgetRegistry r) {}
}

/// 已注册的库（按注册顺序；解析时**先注册者优先**）。
final List<JsUiLibrary> _libraries = [];

bool _seeded = false;

/// 注册一个能力（幂等：同 [JsUiLibrary.id] 只保留首个）。
///
/// 可在 App 的 `main()` 里调用（`runApp` 之前），从而**完全不改 hot_patch**。
/// 会先注入内建能力，保证内建片段**永远排在外部库之前**——外部库的片段可以
/// 安全引用内建片段里的东西（如给 `JsBuildContext.prototype` 补方法）。
void registerJsUiLibrary(JsUiLibrary library) {
  _seedBuiltins();
  for (final l in _libraries) {
    if (l.id == library.id) return;
  }
  _libraries.add(library);
}

/// 全部已注册能力。首次访问时注入内建能力——惰性求值，避免能力表在
/// `ensureJsUiCapabilities` 之前被调用时拿到空清单。
List<JsUiLibrary> get jsUiLibraries {
  _seedBuiltins();
  return List.unmodifiable(_libraries);
}

/// 内建能力清单：**新增内建能力只改这里一行**（外部库走 App 侧 register，
/// 不动本文件）。
///
/// 注册顺序 = [ensureChannels] / [registerWidgets] 的遍历顺序。内建能力的
/// **JS 片段**不在这里——它们已随 `patch/runtime.js` 发布，拼接顺序由生成器
/// `builders/runtime/js/runtime_js.dart` 的 `runtimeJsSource()` 维护。
void _seedBuiltins() {
  if (_seeded) return;
  _seeded = true;
  // 公共值类（Duration / Size / Offset / Radius）：跨能力复用，最先注入，
  // 后面的能力片段（如动画的 `__durationMs`）可直接引用。
  registerJsUiLibrary(const DartValuesLibrary());
  // Dart 内置异常（StateError / ArgumentError / …）：依赖 __posArgs。
  registerJsUiLibrary(const DartErrorsLibrary());
  // Color 类族（Color / MaterialColor / ColorSwatch）：依赖 __posArgs。
  registerJsUiLibrary(const ColorLibrary());
  registerJsUiLibrary(const ChangeNotifierLibrary());
  // 动画值类 / AnimationController 镜像：显式动画经此逐帧回传 value。
  registerJsUiLibrary(const AnimationLibrary());
  registerJsUiLibrary(const ScrollControllerLibrary());
  // AnimatedList：currentState 命令经 key 桥接的 state op 扩展点接入。
  registerJsUiLibrary(const AnimatedListLibrary());
  // Dismissible：confirmDismiss 需要 JS→宿主的异步回程通道。
  registerJsUiLibrary(const DismissibleLibrary());
  registerJsUiLibrary(const TextEditingControllerLibrary());
  // Focus：FocusNode 句柄 + Focus 组件（焦点变化经 Host 回传镜像）。
  registerJsUiLibrary(const FocusLibrary());
  // KeyboardListener：复用 FocusNode 句柄，按键事件经 __jsuiKeyEvent 回 JS。
  registerJsUiLibrary(const KeyboardListenerLibrary());
  // LayoutBuilder：父约束在布局阶段回传 JS（OrientationBuilder 基于它实现）。
  registerJsUiLibrary(const LayoutBuilderLibrary());
  // SliverPersistentHeader：delegate.build 在布局阶段回传 JS（同 LayoutBuilder）。
  registerJsUiLibrary(const SliverPersistentHeaderLibrary());
  registerJsUiLibrary(const TabLibrary());
  registerJsUiLibrary(const KeyLibrary());
  registerJsUiLibrary(const BuildContextLibrary());
  // MediaQuery：`MediaQuery.of/sizeOf/...` 按 ctx 句柄实时对齐 Flutter 真值。
  registerJsUiLibrary(const MediaQueryLibrary());
  // 纯宿主侧能力（无片段、无通道），位置不影响产物，列在此处便于对照。
  registerJsUiLibrary(const NotificationListenerLibrary());
  // PopScope：拦截返回（宿主 ModalRoute 语义）+ 回调回 JS。
  registerJsUiLibrary(const PopScopeLibrary());
  registerJsUiLibrary(const DrawerLibrary());
  // Dialog：命令式弹层（showDialog 系列）的宿主通道 + 弹层容器组件。
  registerJsUiLibrary(const DialogLibrary());
  // Drag：拖拽三件套（draggable 的任意 JS 负载经身份 id 对齐原生拖动系统）。
  registerJsUiLibrary(const DragLibrary());
  // ── 三方库 ──
  registerJsUiLibrary(const EasyRefreshLibrary());
  registerJsUiLibrary(const CachedNetworkImageLibrary());
  registerJsUiLibrary(const ProviderLibrary());
}
