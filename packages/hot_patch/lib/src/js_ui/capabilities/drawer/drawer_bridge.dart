// ===== Drawer 家族 能力域 =====
//
// 一个能力 = 桥接表 + 通道 + 桥接组件 + 组件注册（见 js_ui_capabilities.dart
// 的能力文件规范）。Tab 家族是**另一个能力**，见 capabilities/tab/。
//
// 本能力做什么：
//   - Drawer / DrawerHeader：还原为真实 Drawer。Scaffold.drawer 接进真实
//     Scaffold 后 AppBar 自动出现汉堡按钮，开启抽屉原生可用。
//   - 抽屉关闭：Drawer 是 Scaffold 的后代，其子树内 `Scaffold.maybeOf(context)`
//     即拿得到 ScaffoldState。抽屉**打开时** DrawerController 才构建 Drawer
//     内容（关闭态只返回拖拽热区）→ 作用域登记 closer；关闭后内容被移除 →
//     dispose 注销。故「登记表非空 ⟺ 有抽屉打开」。业务侧 @HostInjected 方法
//     转调 [closeOpenDrawer] 即可关闭当前抽屉。
//
// 本能力**无 JS 片段、无句柄通道**：纯宿主侧组件映射（与 notification_listener
// 同构）。
import 'package:flutter/material.dart';

import '../../../json/flutter_from_json.dart';
import '../../js_widget_registry.dart';

/// 当前已打开的抽屉关闭回调（抽屉内容不构建即被移出，故集合非空 ⟺ 有抽屉
/// 打开）。
final Set<VoidCallback> _openDrawerClosers = {};

/// 关闭当前打开的抽屉（drawer / endDrawer 均可）；无打开抽屉时 no-op。
/// 供业务侧 @HostInjected 方法转调（JS 侧 `_app_host_.invoke('closeDrawer')`）。
void closeOpenDrawer() {
  for (final closer in _openDrawerClosers.toList()) {
    closer();
  }
}

/// Drawer 作用域：登记「关闭当前抽屉」的回调。
///
/// 只在抽屉内容被构建（= 抽屉打开）期间存在，卸载即注销。
class _JsDrawerScope extends StatefulWidget {
  const _JsDrawerScope({required this.child});

  final Widget child;

  @override
  State<_JsDrawerScope> createState() => _JsDrawerScopeState();
}

class _JsDrawerScopeState extends State<_JsDrawerScope> {
  ScaffoldState? _scaffold;

  /// 稳定的闭包实例（同一实例 add/remove，Set 身份可靠）。
  late final VoidCallback _closer = _close;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Drawer 由 Scaffold 的 DrawerController 构建 → 沿祖先链取 ScaffoldState。
    _scaffold = Scaffold.maybeOf(context);
    _openDrawerClosers.add(_closer);
  }

  void _close() {
    final s = _scaffold;
    if (s == null || !s.mounted) return;
    if (s.isDrawerOpen) {
      s.closeDrawer();
    } else if (s.isEndDrawerOpen) {
      s.closeEndDrawer();
    }
  }

  @override
  void dispose() {
    _openDrawerClosers.remove(_closer);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Drawer 家族的宿主注册。
void registerDrawerWidgets(JsWidgetRegistry r) {
  // Drawer：真实 Drawer + 关闭作用域包装。
  r.register('Drawer', (c) => _JsDrawerScope(
        child: Drawer(
          backgroundColor: colorFromJson(c.props['backgroundColor']),
          elevation: c.num_('elevation'),
          shape: shapeFromJson(c.props['shape']),
          width: c.num_('width'),
          child: c.child(),
        ),
      ));

  // DrawerHeader：decoration / padding / margin + child（缺省 padding/margin
  // 与 Flutter 默认一致）。
  r.register('DrawerHeader', (c) => DrawerHeader(
        decoration: boxDecorationFromJson(c.map('decoration')),
        padding: nullableEdgeInsets(c.map('padding')) ??
            const EdgeInsets.fromLTRB(16, 16, 16, 8),
        margin: nullableEdgeInsets(c.map('margin')) ??
            const EdgeInsets.only(bottom: 8),
        child: c.child() ?? const SizedBox.shrink(),
      ));
}
