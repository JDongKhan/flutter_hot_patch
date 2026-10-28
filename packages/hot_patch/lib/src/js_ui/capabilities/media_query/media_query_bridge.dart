// ===== 基础能力：MediaQuery 同步镜像（宿主侧）=====
//
// JS 侧没有 SDK 的 `MediaQuery` 树，也没有同步调用宿主的能力（JS→宿主是
// Promise），而 `MediaQuery.of(context).size / orientation` 这类读法出现在
// build / builder 里，必须是同步值。因此由宿主把 `MediaQueryData` 归一成 JSON
// **推送**给 JS（`__jsuiSetMediaQuery`，见生成器 media_query_js.dart）。
//
// 推送时机：承载 JS 页面的 `JsUiWidgetState.build`（MediaQuery 变化会让它重建：
// 旋转 / 窗口缩放 / 系统字号与深色模式切换都会触发）。JS 侧按文本比较判变化，
// 只有真正变化才通知依赖者重建，重复推送是廉价的。
import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../../../services/js_runtime_manager.dart';

/// 把当前 `MediaQueryData` 推给 JS（幂等；无变化时 JS 侧直接早退）。
void pushMediaQueryToJs(BuildContext context) {
  // 运行时骨架还没求值（首帧早于 patch/runtime.js 加载）时无事可做：
  // `__jsuiSetMediaQuery` 尚未定义，求值只会报「Can't find variable」。
  if (!JsRuntimeManager.instance.isJsUiRuntimeReady) return;
  final mq = MediaQuery.of(context);
  final payload = <String, Object?>{
    'size': {'width': mq.size.width, 'height': mq.size.height},
    'padding': _edgesJson(mq.padding),
    'viewPadding': _edgesJson(mq.viewPadding),
    'viewInsets': _edgesJson(mq.viewInsets),
    'devicePixelRatio': mq.devicePixelRatio,
    'textScaleFactor': mq.textScaler.scale(1.0),
    'orientation': mq.orientation.name,
    'platformBrightness': mq.platformBrightness.name,
    'alwaysUse24HourFormat': mq.alwaysUse24HourFormat,
    'accessibleNavigation': mq.accessibleNavigation,
    'disableAnimations': mq.disableAnimations,
    'invertColors': mq.invertColors,
    'highContrast': mq.highContrast,
    'boldText': mq.boldText,
    'navigationMode': mq.navigationMode.name,
  };
  JsRuntimeManager.instance.evaluate(
    '__jsuiSetMediaQuery(${jsonEncode(payload)});',
  );
}

/// `EdgeInsets` → JS 侧同形值对象（与产物里 padding 类属性的 JSON 形态一致）。
Map<String, Object?> _edgesJson(EdgeInsets e) => {
      'left': e.left,
      'top': e.top,
      'right': e.right,
      'bottom': e.bottom,
    };
