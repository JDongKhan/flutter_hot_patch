// ===== Dialog 能力：跨语言桥 =====
//
// 与 builders/runtime/js/portal_js.dart **对称**：JS 侧的 `showDialog` 在弹层里
// 执行 builder、把元素树挂在独立 root 上，宿主的唯一职责是「按 kind push 一条
// 路由 → 内容承载那份独立 store」。
//
// 通道（JS 只发起、宿主只应答）：
//   - `jsuiPanelOpen`：`[{key, kind, anchor, options}]` → 宿主持 ctx 打开路由；
//     路由内容首帧后调 `__jsui.panelMount(key)`，JS 才真正挂载元素树；
//   - `jsuiPanelPop` ：`[key]` → 宿主 pop 该面板的路由（结果留在 JS 端）。
//
// 关闭只有一条路径：barrier / 返回键 / Navigator.pop 最终都是「宿主路由 pop」
// → 路由 Future 完成 → 本文件回调 `__jsui.panelClosed(key)`（JS 卸载独立 root
// 并结算 showDialog 的 Promise）→ 清理宿主侧簿记。
//
// 为什么结果不过桥：`Navigator.pop(ctx, result)` 的 result 可能是 JS 侧的任意
// 对象（ChangeNotifier / 回调 / 实例），JSON 过不去。故 result 留在 JS 端，
// 宿主路由只负责关闭，回调时由 JS 自己结算。
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../services/js_runtime_manager.dart';
import '../../../utils/hot_patch_log.dart';
import '../../js_ui_store.dart';
import '../../js_ui_widget.dart';
import '../../leak/leak_stats.dart';
import '../build_context/build_context_bridge.dart';
import '../core/binding_cache.dart';
import '../core/from_json/dart_values_from_json.dart';
import '../core/handle_registry.dart';

/// 一个已打开的面板（宿主侧记录）。
class _Panel {
  _Panel({required this.key, required this.navigator});

  final String key;

  /// 打开时捕获的路由栈（root 或就近 Navigator）——`Navigator.pop` 请求、
  /// 挂载失败回关闭都只操作它，避免再沿 ctx 重新查找（面板已卸载时查不到）。
  final NavigatorState navigator;
}

final Map<String, _Panel> _panels = {};

bool _channelsReady = false;

/// 幂等登记弹层通道（由 DialogLibrary.ensureChannels 调用）。
void ensureDialogChannels() {
  if (_channelsReady) return;
  _channelsReady = true;
  JsRuntimeManager.registerHostMethod('jsuiPanelOpen', _onPanelOpen);
  JsRuntimeManager.registerHostMethod('jsuiPanelPop', _onPanelPop);
}

/// 当前是否还有已打开面板（供宿主业务/调试查询）。
bool get hasOpenJsPanel => _panels.isNotEmpty;

/// `jsuiPanelOpen`：按 JS 请求的种类 push 一条路由。
///
/// **必须让出当前栈再干活**：本处理器由 JS 侧 `_app_host_.invoke` 同步调用，
/// 此刻仍处在 JS 求值期内。直接 push 路由没事，但失败路径要把异常 reject 回
/// JS（那是又一次 evaluate），在求值期内重入引擎不安全；`await` 一次即把整段
/// 逻辑推到微任务里，之后的一切都在求值期之外。
Future<void> _onPanelOpen(Map payload) async {
  await Future<void>.value();
  final key = payload['key']?.toString() ?? '';
  final kind = payload['kind']?.toString() ?? 'dialog';
  if (key.isEmpty) return;
  final rawOptions = payload['options'];
  final options = rawOptions is Map
      ? rawOptions.cast<String, dynamic>()
      : const <String, dynamic>{};
  final anchorNode = payload['anchor']?.toString();

  // 打开位置：JS 调用点的 BuildContext（宿主真实 element），取不到时退回
  // MaterialApp.navigatorKey 的 context（页面根组件锚点未登记时的兜底）。
  final ctx = (anchorNode == null ? null : jsBuildContextOfNode(anchorNode)) ??
      JsRuntimeManager.navigatorKey?.currentContext;
  if (ctx == null || !ctx.mounted) {
    HotPatchLog.warn(
      'jsuiPanelOpen: 找不到可用的 BuildContext（anchor=${anchorNode ?? '-'}），'
      '弹层无法打开',
    );
    // 抛回 JS：让 `showDialog(...)` 的 Promise 以异常结束（JS 侧据此撤销面板
    // 记录），而不是留下一个永远悬着的 Promise。
    throw StateError('JS 弹层没有可用的 BuildContext');
  }

  final useRootNavigator = options['useRootNavigator'] as bool? ?? true;
  final navigator = Navigator.of(ctx, rootNavigator: useRootNavigator);
  final store = JsUiStore();
  // 补丁按 key 路由：先登记 store，JS 侧的 panelMount 才有人接。
  jsUiPageStores[key] = store;
  LeakStats.registerPage(key, 'panel:$kind');
  _panels[key] = _Panel(key: key, navigator: navigator);

  final content = JsUiContent(
    store: store,
    pageKey: key,
    onMountFailed: () => _popPanel(key),
  );

  final barrierDismissible = options['barrierDismissible'] as bool? ?? true;
  final barrierColor = colorFromJson(options['barrierColor']);
  final barrierLabel = options['barrierLabel']?.toString();

  Future<Object?> route;
  switch (kind) {
    case 'sheet':
      route = showModalBottomSheet<Object?>(
        context: ctx,
        useRootNavigator: useRootNavigator,
        isScrollControlled: options['isScrollControlled'] as bool? ?? false,
        backgroundColor: colorFromJson(options['backgroundColor']),
        barrierColor: barrierColor,
        elevation: (options['elevation'] as num?)?.toDouble(),
        enableDrag: options['enableDrag'] as bool? ?? true,
        isDismissible: options['isDismissible'] as bool? ?? true,
        showDragHandle: options['showDragHandle'] as bool?,
        useSafeArea: options['useSafeArea'] as bool? ?? false,
        builder: (_) => content,
      );
    case 'cupertino':
      route = showCupertinoDialog<Object?>(
        context: ctx,
        useRootNavigator: useRootNavigator,
        barrierDismissible: barrierDismissible,
        barrierLabel: barrierLabel,
        builder: (_) => content,
      );
    case 'general':
      route = showGeneralDialog<Object?>(
        context: ctx,
        useRootNavigator: useRootNavigator,
        barrierDismissible: barrierDismissible,
        barrierLabel: barrierLabel ?? 'Dismiss',
        // showGeneralDialog 的 barrierColor 非空（缺省 black54），不像 showDialog
        // 接受 null；JS 没给时显式沿用同一缺省值。
        barrierColor: barrierColor ?? Colors.black54,
        pageBuilder: (_, _, _) => content,
      );
    default:
      route = showDialog<Object?>(
        context: ctx,
        useRootNavigator: useRootNavigator,
        barrierDismissible: barrierDismissible,
        barrierColor: barrierColor,
        barrierLabel: barrierLabel,
        useSafeArea: options['useSafeArea'] as bool? ?? true,
        builder: (_) => content,
      );
  }
  // 路由关闭（barrier / 返回键 / Navigator.pop）后统一做本端与 JS 端的清理。
  // 结果只用于日志：JS 侧自己留着，不需要过桥。
  route.then((_) => _closePanel(key));
}

/// `jsuiPanelPop`：JS 的 `Navigator.pop(context, result)` 请求关闭所属面板。
///
/// 同样先让出当前栈（见 [_onPanelOpen] 的说明）：pop 会启动路由退场并可能在
/// 极短路径上完成 Future，其 `.then` 里的清理要 evaluate 回 JS。
Future<void> _onPanelPop(String key) async {
  await Future<void>.value();
  _popPanel(key);
}

void _popPanel(String key) {
  final panel = _panels[key];
  if (panel == null) return;
  if (!panel.navigator.mounted) {
    // 路由栈已不可用（页面先被销毁）：直接做关闭清理，避免面板永久残留。
    _closePanel(key);
    return;
  }
  panel.navigator.pop();
}

/// 关闭一个面板：JS 卸载独立 root，宿主摘除簿记。
///
/// **幂等**：路由 Future 与挂载失败回调可能各来一次，重复调用只在第一次生效。
void _closePanel(String key) {
  if (_panels.remove(key) == null) return;
  // 1) JS 侧：卸载独立 root（逐实例 dispose → 释放实例句柄）并结算 Promise。
  JsRuntimeManager.evaluateAll(
    'if (typeof __jsui !== "undefined" && __jsui.panelClosed) '
    '__jsui.panelClosed(${_jsString(key)});',
  );
  // 2) 宿主簿记：与 JsUiWidgetState.dispose 同一套收尾（各自幂等）。
  jsUiPageStores.remove(key);
  unregisterJsBuildContext(jsBuildContextPageAnchor(key));
  JsBindingCache.instance.dropPageEntries(key);
  releasePageHandles(key);
  LeakStats.unregisterPage(key);
}

String _jsString(String s) {
  final escaped = s
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll('\n', r'\n')
      .replaceAll('\r', r'\r');
  return "'$escaped'";
}
