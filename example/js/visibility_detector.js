// 三方库 JS（宿主维护）：visibility_detector
//
// 生成器不生成该模块 —— 三方库 / 业务自定义组件的 JS 由业务放在工程根 `js/`，
// 构建时由 `ui_third_party_js` 原样拷贝到 `patch/packages/visibility_detector.js`。
// 文件名即 Dart 包名（`js/visibility_detector.js` ↔ `package:visibility_detector`），
// 业务产物按 `import { VisibilityDetector } from '<...>/packages/visibility_detector.js'`
// 取用；它**不会**进 `flutter.js`（框架产物只承载内建宿主组件）。
//
// 可见性判定（render object + 帧间通知）全在宿主侧，见
// `example/lib/custom/visibility_detector/custom_visibility_detector_bridge.dart`；
// 本类只作为宿主元素包装：构造即宿主结点，type 名取类名。
import { Component } from '../flutter.js';

export class VisibilityDetector extends Component {
  // 函数形参名单：只有 onVisibilityChanged 会跨桥换成句柄，其余按普通 props 下发。
  static __fnProps = ["onVisibilityChanged"];
}
