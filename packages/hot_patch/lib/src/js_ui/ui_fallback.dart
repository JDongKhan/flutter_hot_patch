import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../utils/hot_patch_log.dart';

/// UI 兜底统一出口。
///
/// 「本该渲染出内容，却没渲染出来」的异常路径（未注册类型、结点丢失、
/// 子元素解析失败、builder 下标越界……）全部收敛到本文件，避免各处零散地
/// 返回 `SizedBox.shrink()` 静默吞掉问题：
///
///   - debug：返回**可见占位**（红底小字 + 原因）并打一条 error 日志，
///     界面上能直接看到是哪一块出的问题；
///   - release：返回 `SizedBox.shrink()`，静默降级——不把内部诊断信息暴露给
///     用户，也不影响布局。
///
/// 注意：**可选 slot 缺省**（`child ?? const SizedBox.shrink()`，如
/// `Visibility.replacement`、`Dialog.child`、`CupertinoActionSheet.cancelButton`）
/// 是合法语义，不属于兜底，不要走这里。
Widget uiFallback(String reason, {List<Widget> children = const <Widget>[]}) {
  _reportOnce(reason);
  if (!kDebugMode) return const SizedBox.shrink();
  return Container(
    padding: const EdgeInsets.all(4),
    color: const Color(0x22FF0000),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '<ui fallback: $reason>',
          style: const TextStyle(fontSize: 11, color: Color(0xFFB00020)),
        ),
        ...children,
      ],
    ),
  );
}

/// 已提示过的兜底原因（见 [_reportOnce] 的去重）。
final Set<String> _reported = <String>{};

/// 同一原因只报一次：build 会随帧反复执行，否则日志 / 上报会被刷屏。
void _reportOnce(String reason) {
  if (_reported.contains(reason)) return;
  if (_reported.length >= 512) _reported.clear();
  _reported.add(reason);
  HotPatchLog.error('js_ui: $reason');
}
