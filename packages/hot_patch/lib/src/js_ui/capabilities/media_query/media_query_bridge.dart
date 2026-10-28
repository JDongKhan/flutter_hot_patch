// ===== 基础能力：MediaQuery（宿主侧 = Flutter 真值的实时代理）=====
//
// JS 里 `MediaQuery.of(context)` / `MediaQuery.sizeOf(context)` 等**一律实时代理到
// Flutter 的 `MediaQuery.of(context)`**：JS 的 `context` 代理与宿主真值
// BuildContext 本来就有 1:1 绑定（句柄 `ctx/BuildContext`，见
// build_context_bridge.dart 的 `jsBuildContextOf`），故这里按 ctx 句柄 id 取到
// **该组件自己所在位置**的 BuildContext，再读它上方的 `MediaQuery` 真值。
//
// 两端分工（同步约束决定的，不是设计选择）：
//   - JS 侧读值必须同步（build 里直接读 `.size` / `.orientation`），而 JS→宿主
//     只有异步桥 —— 故 JS 首次读取时发一次 `mediaQuery` op 拿到真值，之后读缓存；
//   - 真值变化（旋转 / 缩放 / 字号 / 深色模式 / 无障碍开关）由本文件**按 ctx
//     句柄**回推给 JS（`__jsuiSetMediaQuery(ctxId, json)`），JS 侧标脏重建。
//
// 粒度是 **ctx（即组件实例）**，不是页面：同一个 JS 页面里不同位置的组件各自
// 拿自己 BuildContext 上的 MediaQuery —— 页面内部若存在嵌套 `MediaQuery` 覆盖，
// 各组件读到的就是各自那一份，与 Dart 语义一致。
//
// 读值用 `getInheritedWidgetOfExactType` 而**不是** `MediaQuery.of`：后者会登记
// 依赖，而这里是在 build 之外（op 回调 / 系统回调）读取，登记依赖属于非法用法。
// 它返回的就是 `MediaQuery.of` 查找的那一个 InheritedWidget，取值完全等价。
import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../../../services/js_runtime_manager.dart';
import '../../../utils/hot_patch_log.dart';
import '../build_context/build_context_bridge.dart';

/// ctx 句柄 id → 上次下发的 payload 文本（用于「没变就不推」）。
/// 键的存在即表示该 ctx 已订阅（JS 读过 MediaQuery）。
final Map<String, String> _subscribed = {};

bool _mediaQueryOpRegistered = false;

/// 把 `mediaQuery` 这个 context op 注册进核心的分发缝（由 MediaQueryLibrary 调用）。
void ensureMediaQueryContextOps() {
  if (_mediaQueryOpRegistered) return;
  _mediaQueryOpRegistered = true;
  registerContextOp(
    'mediaQuery',
    // 同步返回真值：JS 侧 `MediaQuery.of(context)` 的首次读值。
    onOp: (ctxId, op, payload) => _readForCtx(ctxId),
    // 组件卸载 → 句柄释放：停止回推（否则会给已释放的 id 发消息）。
    onRelease: _subscribed.remove,
  );
  WidgetsBinding.instance.addObserver(_MediaQueryWatcher());
}

/// `MediaQuery` 相关的系统级变化 → 给所有订阅者回推新值。
///
/// 覆盖 `MediaQueryData` 的全部外部来源：窗口尺寸 / 字号 / 深色模式 / 无障碍
/// 开关 / 语言。页面内部**代码构造**的 `MediaQuery` 变化不在其中（那需要依赖
/// 登记，见文件头说明）——这种场景请直接由 JS 侧重建。
class _MediaQueryWatcher with WidgetsBindingObserver {
  @override
  void didChangeMetrics() => _refreshAll();

  @override
  void didChangeTextScaleFactor() => _refreshAll();

  @override
  void didChangePlatformBrightness() => _refreshAll();

  @override
  void didChangeAccessibilityFeatures() => _refreshAll();

  @override
  void didChangeLocales(List<Locale>? locales) => _refreshAll();
}

/// 首次读取（op 回调）：订阅该 ctx，并**在返回值里**给出真值。
Object? _readForCtx(String ctxId) {
  final ctx = jsBuildContextOf(ctxId);
  if (ctx == null) return null;
  final payload = mediaQueryPayloadOf(ctx);
  if (payload == null) return null;
  _subscribed[ctxId] = jsonEncode(payload);
  return payload;
}

/// 系统级变化时逐订阅者重读、有变化才回推。
void _refreshAll() {
  if (_subscribed.isEmpty) return;
  if (!JsRuntimeManager.instance.isJsUiRuntimeReady) return;
  for (final ctxId in _subscribed.keys.toList()) {
    final ctx = jsBuildContextOf(ctxId);
    if (ctx == null) {
      // 结点已卸载（句柄释放通知可能还没到）→ 顺手摘除。
      _subscribed.remove(ctxId);
      continue;
    }
    final payload = mediaQueryPayloadOf(ctx);
    if (payload == null) continue;
    final key = jsonEncode(payload);
    if (key == _subscribed[ctxId]) continue;
    _subscribed[ctxId] = key;
    JsRuntimeManager.instance.evaluate(
      '__jsuiSetMediaQuery(${jsonEncode(ctxId)}, ${jsonEncode(payload)});',
    );
  }
}

/// 读该 BuildContext 上方的 `MediaQuery` 真值（不登记依赖），转成 JS 侧镜像的
/// JSON 形态；上方没有 MediaQuery 时返回 null。
Map<String, Object?>? mediaQueryPayloadOf(BuildContext context) {
  final data = context.getInheritedWidgetOfExactType<MediaQuery>()?.data;
  if (data == null) {
    HotPatchLog.warn('[jsui] 该位置上方没有 MediaQuery，MediaQuery.of 返回空值');
    return null;
  }
  return {
    'size': {'width': data.size.width, 'height': data.size.height},
    'padding': _edgesJson(data.padding),
    'viewPadding': _edgesJson(data.viewPadding),
    'viewInsets': _edgesJson(data.viewInsets),
    'devicePixelRatio': data.devicePixelRatio,
    'textScaleFactor': data.textScaler.scale(1.0),
    'orientation': data.orientation.name,
    'platformBrightness': data.platformBrightness.name,
    'alwaysUse24HourFormat': data.alwaysUse24HourFormat,
    'accessibleNavigation': data.accessibleNavigation,
    'disableAnimations': data.disableAnimations,
    'invertColors': data.invertColors,
    'highContrast': data.highContrast,
    'boldText': data.boldText,
    'navigationMode': data.navigationMode.name,
  };
}

/// `EdgeInsets` → JS 侧同形值对象（与产物里 padding 类属性的 JSON 形态一致）。
Map<String, Object?> _edgesJson(EdgeInsets e) => {
      'left': e.left,
      'top': e.top,
      'right': e.right,
      'bottom': e.bottom,
    };
