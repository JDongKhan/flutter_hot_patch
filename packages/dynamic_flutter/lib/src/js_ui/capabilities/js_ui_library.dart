// ===== 能力接入模板（基座唯一的扩展缝）=====
//
// **设计初衷**：让「支持一个新能力」的全部改动**收敛在一个子类里**，
// dynamic_flutter 的核心文件从此不再变动。这里的「能力」既包括 Flutter 等价物
// （Key / 各 Controller / BuildContext 代理 / NotificationListener），也包括
// 新引入的三方库（provider / GetX / Riverpod …）——两者机制完全一致。
//
// 一个能力在宿主侧的落点分两类，本模板各留一个可重写钩子：
//   1. [ensureChannels]   —— 幂等登记本能力用到的跨语言句柄 kind，以及把本库的
//                            `context.<op>(...)` 处理注册进核心的通用缝
//                            （`registerContextOp`，见 build_context_bridge.dart）；
//   2. [registerWidgets]  —— 本能力的宿主侧组件映射（`type` → Flutter widget）。
//
// **JS 侧代码不进本模板**：核心机制写进 `patch/runtime.js`（生成器
// `builders/runtime/js/**`，随补丁发布）；库自己的 API 面写进该包的
// `patch/<pkg>.js` 或宿主维护的 `js/<pkg>.js`。
//
// **本类刻意没有 context 语义的钩子**：`context.watch/read` 是 provider 那类
// `extension BuildContextX on BuildContext`，属库自己；JS 侧补丁由宿主维护在
// `js/provider.js`（构建拷贝到 `patch/packages/provider.js`）。
// 核心不认识具体 op 名；provider 的取值与订阅都在 JS 内闭环，宿主不再注册 op。
//
// 接入方式：
//   - 内建：在下面的 [_seedBuiltins] 里 `registerJsUiLibrary(...)` 一行；
//   - 业务 / 三方库：写一个本类子类，放进 App `main()` 的
//     `initJsUi(libraries: [...])`（js_ui_bootstrap.dart）——一次调用完成
//     「注册 + 通道就位 + 宿主组件建表」，dynamic_flutter 包零改动。
//
// **不进模板的地基**（核心本体，不属于任何可插拔能力）：
//   - `ensureHandleChannels()`：句柄注册表本身，必须先于一切能力就绪；
//   - `registerBaseWidgets(r)`：Text/Column 等 Flutter 基础视觉组件；
//   - JS 骨架（mini-react / emit / host 桥）：见 runtime_js.dart。
//
// **边界（务必知晓）**：本模板覆盖的是**运行时/宿主侧**。若新库还要新增 UI
// 组件类型，其**编译期**翻译（dynamic_flutter_generator 的统一翻译入口
// element_json.dart / value_forms.dart 与 `patch/<pkg>.js` 里的 JS 组件类）
// 属于另一条缝，不在本文件范围内。
import '../../utils/dynamic_flutter_log.dart';
import '../js_widget_registry.dart';
import 'animated_list/animated_list_library.dart';
import 'animation/animation_library.dart';
import 'build_context/build_context_library.dart';
import 'cached_network_image/cached_network_image_library.dart';
import 'canvas/canvas_library.dart';
import 'change_notifier/change_notifier_library.dart';
import 'core/dart_values_library.dart';
import 'core/dart_errors_library.dart';
import 'core/color_library.dart';
import 'cupertino_picker/cupertino_picker_library.dart';
import 'dialog/dialog_library.dart';
import 'dismissible/dismissible_library.dart';
import 'drag/drag_library.dart';
import 'drawer/drawer_library.dart';
import 'focus/focus_library.dart';
import 'key/key_library.dart';
import 'keyboard_listener/keyboard_listener_library.dart';
import 'layout_builder/layout_builder_library.dart';
import 'media_query/media_query_library.dart';
import 'notification_listener/notification_listener_library.dart';
import 'overlay_portal/overlay_portal_library.dart';
import 'pop_scope/pop_scope_library.dart';
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
/// 正常姿势是把能力放进装配入口 `initJsUi(libraries: [...])` 的清单里（见
/// js_ui_bootstrap.dart），它在 `main()` 里一次完成「注册 + 通道就位 + 建表」。
/// 单独调用本函数也有效，但必须在宿主组件注册表建表之前（即任何 `JsUiWidget`
/// 渲染之前）；建表之后再注册的库拿不到 [JsUiLibrary.registerWidgets] 回调，
/// 这里会告警而不是静默丢映射。
void registerJsUiLibrary(JsUiLibrary library) {
  _seedBuiltins();
  for (final l in _libraries) {
    if (l.id == library.id) return;
  }
  _libraries.add(library);
  if (jsWidgetRegistryBuilt) {
    JsLog.warn('JsUiLibrary「${library.id}」在宿主组件注册表建表之后注册：'
        'ensureChannels 仍生效，但 registerWidgets 不会被回调（该库的宿主组件'
        '会渲染成未注册占位）。放进 initJsUi(libraries: [...]) 或任何 JsUiWidget '
        '渲染之前。');
  }
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
  // Dart 内置异常（StateError / ArgumentError / …）：JS 实现在 flutter.js 值类区。
  registerJsUiLibrary(const DartErrorsLibrary());
  // Color 类族（Color / MaterialColor / ColorSwatch）：依赖 __positionalArgs。
  registerJsUiLibrary(const ColorLibrary());
  // CustomPaint：JS painter 句柄 sync:false，宿主同步求值录制指令后重放。
  registerJsUiLibrary(const CanvasLibrary());
  registerJsUiLibrary(const ChangeNotifierLibrary());
  // 动画值类 / AnimationController 镜像：显式动画经此逐帧回传 value。
  registerJsUiLibrary(const AnimationLibrary());
  registerJsUiLibrary(const ScrollControllerLibrary());
  // CupertinoPicker：FixedExtentScrollController 句柄 + 滚轮组件宿主渲染。
  registerJsUiLibrary(const CupertinoPickerLibrary());
  // AnimatedList：currentState 命令经 key 桥接的 state op 扩展点接入。
  registerJsUiLibrary(const AnimatedListLibrary());
  // Dismissible：confirmDismiss 需要 JS→宿主的异步回程通道。
  registerJsUiLibrary(const DismissibleLibrary());
  registerJsUiLibrary(const TextEditingControllerLibrary());
  // Focus：FocusNode 句柄 + Focus 组件（焦点变化经 Host 回传镜像）。
  registerJsUiLibrary(const FocusLibrary());
  // KeyboardListener：复用 FocusNode 句柄，按键事件经 __keyEvent 回 JS。
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
  // OverlayPortal：弹层挂载点 + LayerLink 锚定跟随（引导气泡那类悬浮提示）。
  registerJsUiLibrary(const OverlayPortalLibrary());
  // ── 三方库 ──
  registerJsUiLibrary(const CachedNetworkImageLibrary());
}
