// ===== 补丁版本切换协调器（非核心工具）=====
//
// 运行时是全局唯一的，补丁版本切换会整体失效所有已挂载页面的 JS root。
// 「需要重载的范围」不是某个路由，而是**所有仍 mounted 的 JsUiWidget**：
// Navigator push 不会销毁栈下方的页面，它们的 State 仍然活着、JS root 仍然存在。
//
// 本类只做「登记 + 代次 + 待重载调度 + 原生提示」，不感知 JsUiWidget 内部状态：
//   - 页面在 initState 时 registerPage，dispose 时 unregisterPage；
//   - 核心在 boot 成功 / 页面级重载开始时调 markPageBooted；
//   - 核心检测到版本切换时调 onRuntimeSwitched，本类据此找出其余旧代次页面；
//   - 可见页弹一次原生 dialog，确认后回调页面的 reload 闭包统一重载；
//     离屏页不弹窗，直接静默重载。
//
// 这样 js_ui_widget.dart 只保留「什么时候注册 / 什么时候通知」的接线，
// 版本切换的调度与提示逻辑全部收敛在这里。

import 'package:flutter/material.dart';

import '../utils/hot_patch_log.dart';

/// 一个已挂载页面的最小契约（由 JsUiWidgetState 在注册时提供）。
class _ActivePage {
  _ActivePage({
    required this.pageKey,
    required this.epoch,
    required this.contextOf,
    required this.isMounted,
    required this.reload,
  });

  final String pageKey;

  /// 该页 JS root 挂载时的运行时代次。
  int epoch;

  /// 取页面 BuildContext（仅用于判断可见性与承载原生 dialog）。
  final BuildContext Function() contextOf;

  /// 页面是否仍 mounted（post-frame 调度与 dialog 之间可能已卸载）。
  final bool Function() isMounted;

  /// 页面级重载回调：重建 JS root 与 store，保留 Flutter 路由。
  final void Function(String reason) reload;
}

/// 补丁版本切换协调器（进程内唯一）。
class JsRuntimeSwitchCoordinator {
  JsRuntimeSwitchCoordinator._();

  static final JsRuntimeSwitchCoordinator instance =
      JsRuntimeSwitchCoordinator._();

  /// pageKey → 当前 mounted 的页面。
  final Map<String, _ActivePage> _pages = {};

  /// 待重载页面（按代次筛选后执行；页面卸载时自动摘除）。
  final Set<_ActivePage> _pending = {};

  /// 运行时代次：每次补丁版本切换 +1。
  int _epoch = 0;

  /// 当前运行时代次（核心 boot 成功时用它标记页面已就绪）。
  int get currentEpoch => _epoch;

  /// 已调度一次 post-frame 处理（同一批切换合并）。
  bool _flowScheduled = false;

  /// 原生更新提示 dialog 正在显示（全局最多一个）。
  bool _dialogShowing = false;

  /// 登记一个已挂载页面。epoch 由本类维护，页面无需自己记录。
  void registerPage({
    required String pageKey,
    required BuildContext Function() contextOf,
    required bool Function() isMounted,
    required void Function(String reason) reload,
  }) {
    _pages[pageKey] = _ActivePage(
      pageKey: pageKey,
      epoch: _epoch,
      contextOf: contextOf,
      isMounted: isMounted,
      reload: reload,
    );
  }

  /// 页面销毁：从注册表与待重载集合中摘除。
  void unregisterPage(String pageKey) {
    _pages.remove(pageKey);
    _pending.removeWhere((page) => page.pageKey == pageKey);
  }

  /// 页面 boot 成功（首次挂载 / 页面级重载完成）：追平当前代次。
  void markPageBooted(String pageKey) {
    final page = _pages[pageKey];
    if (page != null) page.epoch = _epoch;
  }

  /// 运行时版本发生切换（由触发切换的页面在 boot 中调用）。
  ///
  /// [bootingPageKey] 是本次用新版本重新 boot 的页面，不计入待重载集合。
  void onRuntimeSwitched({required String bootingPageKey}) {
    _epoch += 1;
    for (final page in _pages.values.toList()) {
      if (page.pageKey == bootingPageKey) continue;
      if (page.epoch < _epoch) _pending.add(page);
    }
    if (_pending.isEmpty) return;
    HotPatchLog.log('补丁版本切换：${_pending.length} 个已打开页面待重新加载'
        '（代次 $_epoch）');
    _flush();
  }

  /// 合并处理一批待重载页：可见页先弹 dialog，确认后统一页面级重载。
  void _flush() {
    if (_flowScheduled || _dialogShowing) return;
    _flowScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _flowScheduled = false;
      if (_dialogShowing) {
        // 已有 dialog 流程在走：新加入的页面留给那一轮结束后的再次 flush。
        return;
      }
      // 过滤掉已卸载 / 已被别的流程重载（代次已追平）的页面。
      _pending.removeWhere(
        (page) => !page.isMounted() || page.epoch >= _epoch,
      );
      final stale = _pending.toList();
      _pending.clear();
      if (stale.isEmpty) return;

      final visible = stale.where(_isVisible).toList();
      if (visible.isNotEmpty) {
        _dialogShowing = true;
        try {
          await _showReloadDialog(visible.first);
        } catch (e) {
          HotPatchLog.warn('补丁更新提示弹窗失败，直接重载页面: $e');
        } finally {
          _dialogShowing = false;
        }
      }
      for (final page in stale) {
        if (!page.isMounted()) continue;
        if (page.epoch >= _epoch) continue;
        // 先追平代次再重载：同一页不会被后续批次重复调度。
        page.epoch = _epoch;
        page.reload('补丁版本更新（代次 $_epoch）');
      }
      // dialog 期间可能又有页面 stale：继续下一轮。
      if (_pending.isNotEmpty) _flush();
    });
  }

  /// 页面是否处于当前可见路由（栈下方离屏页不弹窗，静默重载）。
  bool _isVisible(_ActivePage page) {
    if (!page.isMounted()) return false;
    try {
      return ModalRoute.of(page.contextOf())?.isCurrent ?? false;
    } catch (_) {
      // 取 context 时页面可能刚好进入 deactivate：按不可见处理。
      return false;
    }
  }

  /// 原生更新提示（禁止用 JS dialog：那会再创建一个属于旧运行时的根）。
  Future<void> _showReloadDialog(_ActivePage page) {
    return showDialog<void>(
      context: page.contextOf(),
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('组件已更新'),
          content: const Text('检测到新的补丁版本，已打开的页面需要重新加载。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('立即重新加载'),
            ),
          ],
        ),
      ),
    );
  }
}
