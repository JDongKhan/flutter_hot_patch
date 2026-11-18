// ===== Dialog 能力：宿主侧封装 =====
//
// Flutter 侧打开弹层的唯一入口（内部才调原生 `showDialog`）。
//
// 为什么要封装：弹层的生命周期在两端各有一半——宿主 push 路由、JS 挂载独立
// root，关闭必须汇成**一条**路径（barrier / 返回键 / Navigator.pop 都落到路由
// pop）。若业务直接调原生 `showDialog`，它拿到的 `builder` 在 Flutter 侧重建、
// 关掉的时机与 JS 侧无从对齐。统一走本方法（JS 侧 `showDialog` 走同一条通道，
// 见 dialog_bridge.dart），关闭语义只有一份。
//
// 本方法支持任意 Widget：既可以是 JS 内容（`JsUiWidget` / `JsUiContent`），也是
// 普通 Flutter widget——封装不限制内容来源。
import 'package:flutter/material.dart';

/// 打开一个弹层，返回关闭时由 `Navigator.pop` 回传的结果（未回传为 null）。
///
/// 参数与原生 `showDialog` 同名同义，宿主侧只做透传，不引入新语义。
Future<T?> showJsDialog<T>(
  BuildContext context,
  Widget content, {
  bool barrierDismissible = true,
  Color? barrierColor,
  String? barrierLabel,
  bool useRootNavigator = true,
  bool useSafeArea = true,
  RouteSettings? routeSettings,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    barrierLabel: barrierLabel,
    useRootNavigator: useRootNavigator,
    useSafeArea: useSafeArea,
    routeSettings: routeSettings,
    builder: (_) => content,
  );
}
