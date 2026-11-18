// ===== 自定义组件能力：VisibilityDetector（可见性 / 曝光检测）=====
//
// 这是一个**示例级自定义能力**：VisibilityDetector 来自三方包
// `visibility_detector`，不是所有 App 都会用到，因此不放进 `dynamic_flutter` 内建
// 能力，而是由业务方在自己的工程里按同一套扩展点接入：
//
//   1. 继承 `JsUiLibrary`，在 `registerWidgets` 里注册 type → Flutter widget；
//   2. 在 `main()`（runApp 之前）`registerJsUiLibrary(...)`；
//   3. 生成器构建期扫描工程 `lib/**` 的 `r.register('X', …)`，把 `X` 补进
//      `flutter.js` 的宿主包装类（与内建能力同一份清单，无需改 dynamic_flutter 包）。
//
// 可见性判定依赖宿主的 render object 与帧间通知，JS 侧只接收结果：
//   - 子树：`child`；
//   - 事件：`onVisibilityChanged(VisibilityInfo)`，可见比例变化时回传。
import 'package:flutter/material.dart';
import 'package:dynamic_flutter/dynamic_flutter.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// `VisibilityInfo` → JSON（JS 侧按普通对象读取：`info.visibleFraction` /
/// `info.size.width` …）。只下发宿主侧才能真正算出的可见性事实。
Map<String, Object?> _visibilityInfoJson(VisibilityInfo info) {
  return {
    'visibleFraction': info.visibleFraction,
    'size': <String, Object?>{
      'width': info.size.width,
      'height': info.size.height,
    },
  };
}

/// VisibilityDetector 能力：宿主组件注册。
void registerVisibilityDetectorWidgets(JsWidgetRegistry r) {
  r.register('VisibilityDetector', (c) {
    final handler = c.props['onVisibilityChanged'];
    return VisibilityDetector(
      // JS 侧 `new VisibilityDetector({ key: new UniqueKey(), … })` 声明的 key：
      // 用 `c.key` 取出对应的**宿主 Key 实例**（与 JS 句柄同一实例、跨帧稳定），
      // 而不是自己再造一把——否则原生侧身份与 JS 侧不一致。
      // VisibilityDetector 的 key 是必填；JS 侧漏传时用常量占位（不新建实例）。
      key: c.key ?? const ValueKey<String>('js.visibilityDetector'),
      onVisibilityChanged: handler == null
          ? null
          : (info) => c.invoke(handler, [_visibilityInfoJson(info)]),
      child: (c.children['child'] as Widget?) ?? const SizedBox.shrink(),
    );
  });
}
