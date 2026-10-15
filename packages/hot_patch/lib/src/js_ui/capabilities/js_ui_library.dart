// ===== 能力接入模板（基座唯一的扩展缝）=====
//
// **设计初衷**：让「支持一个新能力」的全部改动**收敛在一个子类里**，
// hot_patch 的核心文件从此不再变动。这里的「能力」既包括 Flutter 等价物
// （Key / 各 Controller / BuildContext 代理 / NotificationListener），也包括
// 新引入的三方库（provider / GetX / Riverpod …）——两者机制完全一致。
//
// 一个能力在宿主侧的落点无非四类，本模板各留一个可重写钩子：
//   1. [jsFragments]      —— 需要注入 JS 运行时的片段（同一 IIFE 作用域，
//                            可调用核心的 `registerScope` / `scopeOf` / `reg` …）；
//   2. [ensureChannels]   —— 幂等登记本能力用到的跨语言句柄 kind；
//   3. [registerWidgets]  —— 本能力的宿主侧组件映射（`type` → Flutter widget）；
//   4. [resolveWatchTarget] —— `context.watch<T>()` / `read<T>()` 下行的宿主
//                            解析钩子：在**真值 element 树**上按类型名找到可
//                            订阅对象（同步取值仍留在 JS，这里只决定「订阅谁」）。
//
// 接入方式（二选一）：
//   - 内建：在下面的 [_seedBuiltins] 里 `registerJsUiLibrary(...)` 一行；
//   - 完全不动 hot_patch：在 App 自己的 `main()`（`runApp` 之前）调
//     `registerJsUiLibrary(GetxLibrary())` 即可。
//
// **不进模板的地基**（核心本体，不属于任何可插拔能力）：
//   - `ensureHandleChannels()`：句柄注册表本身，必须先于一切能力就绪；
//   - `registerBuiltinJsWidgets(r)`：Text/Column 等 Flutter 基础视觉组件；
//   - JS 骨架（mini-react / emit / host 桥）：见 runtime_source.dart。
//
// **边界（务必知晓）**：本模板覆盖的是**运行时/宿主侧**。若新库还要新增 UI
// 组件类型，其**编译期**翻译（ui_component_generator 的 translator 与
// `patch/<pkg>.js` 里的 JS 组件类）属于另一条缝，不在本文件范围内。
import 'package:flutter/widgets.dart';

import '../js_widget_registry.dart';
import 'build_context/build_context_library.dart';
import 'change_notifier/change_notifier_library.dart';
import 'drawer/drawer_library.dart';
import 'key/key_library.dart';
import 'notification_listener/notification_listener_library.dart';
import 'provider/provider_library.dart';
import 'scroll_controller/scroll_controller_library.dart';
import 'tab/tab_library.dart';
import 'text_editing_controller/text_editing_controller_library.dart';

/// 能力在宿主的接入模板：**新增一个能力 = 继承本类 + 注册**。
///
/// 所有钩子都有空实现，子类只重写真正需要的那些；核心不 import 任何具体库。
abstract class JsUiLibrary {
  const JsUiLibrary();

  /// 库标识（幂等去重键、日志用）。
  String get id;

  /// 注入 JS 运行时的片段：会被拼进**同一个 IIFE**（在核心骨架之后、
  /// 收尾之前），因此可以直接引用核心里已定义的函数（如 `registerScope`）。
  ///
  /// 注意顺序：片段在 IIFE **执行期**运行，故只能依赖核心中**先于它执行**的
  /// 顶层语句（函数声明可任意位置，`var x = …` 的赋值必须先发生）。
  List<String> get jsFragments => const [];

  /// 幂等登记本库的跨语言句柄 kind（宿主侧句柄注册表）。
  /// 在 JS 组件 mount（即 `new` 本库对象 → `reg(...)`）之前调用一次。
  void ensureChannels() {}

  /// 注册本库的宿主侧组件映射（`type` 字符串 → 真实 Flutter widget）。
  void registerWidgets(JsWidgetRegistry r) {}

  /// `context.watch<T>()` / `context.read<T>()` 的**宿主侧权威解析**：
  /// 从该位置的真值 [context] 沿 element 树按类型名 [type] 找到可订阅对象。
  ///
  /// 返回 null = 本库不负责这个类型（交给下一个库）；全部库都返回 null 时，
  /// 核心按「消费点越过了提供者边界」告警。
  ///
  /// **为什么返回值是 [Listenable] 而不是库自己的类型**：核心只做一件事——
  /// 「订阅它、变更时标脏重建」，这与「它是谁」无关（与 Flutter 里
  /// `context.watch` 只要求 Listenable 一致）。库自己的类型在里面即可，
  /// 见 ProviderLibrary 的实现。
  Listenable? resolveWatchTarget(BuildContext context, String type) => null;
}

/// 已注册的库（按注册顺序；解析时**先注册者优先**）。
final List<JsUiLibrary> _libraries = [];

bool _seeded = false;

/// 注册一个能力（幂等：同 [JsUiLibrary.id] 只保留首个）。
///
/// 可在 App 的 `main()` 里调用（`runApp` 之前），从而**完全不改 hot_patch**。
void registerJsUiLibrary(JsUiLibrary library) {
  for (final l in _libraries) {
    if (l.id == library.id) return;
  }
  _libraries.add(library);
}

/// 全部已注册能力。首次访问时注入内建能力——惰性求值，避免 [jsUiRuntimeSource]
/// 在 `ensureJsUiCapabilities` 之前被调用时拿到空清单。
List<JsUiLibrary> get jsUiLibraries {
  _seedBuiltins();
  return List.unmodifiable(_libraries);
}

/// 内建能力清单：**新增内建能力只改这里一行**（外部库走 App 侧 register，
/// 不动本文件）。
///
/// **注册顺序 = JS 片段拼接顺序**（先内建基础能力、后三方库，三方库可依赖
/// 前面的能力），也是 `ensureChannels` / `registerWidgets` 的遍历顺序。
void _seedBuiltins() {
  if (_seeded) return;
  _seeded = true;
  registerJsUiLibrary(const ChangeNotifierLibrary());
  registerJsUiLibrary(const ScrollControllerLibrary());
  registerJsUiLibrary(const TextEditingControllerLibrary());
  registerJsUiLibrary(const TabLibrary());
  registerJsUiLibrary(const KeyLibrary());
  registerJsUiLibrary(const BuildContextLibrary());
  // 纯宿主侧能力（无片段、无通道），位置不影响产物，列在此处便于对照。
  registerJsUiLibrary(const NotificationListenerLibrary());
  registerJsUiLibrary(const DrawerLibrary());
  // ── 三方库 ──
  registerJsUiLibrary(const ProviderLibrary());
}

/// 按类型名解析「可订阅对象」：遍历各能力，第一个非 null 即命中。
///
/// 同名就近遮蔽由各库自己的解析实现保证（provider 用 `jsType == type` 过滤，
/// 不取「最近的那个」——见 ProviderLibrary）。
Listenable? resolveWatchTarget(BuildContext context, String type) {
  if (context is! Element || !context.mounted) return null;
  for (final library in jsUiLibraries) {
    final target = library.resolveWatchTarget(context, type);
    if (target != null) return target;
  }
  return null;
}
