// ===== 开发者自定义能力注册入口 =====
//
// 能力实现放在 `lib/custom/<能力名>/` 下（`JsUiLibrary` 子类 + 宿主注册），
// 这里统一在 `runApp` 之前注册；hot_patch 包本身不需要任何改动。
import 'package:hot_patch/hot_patch.dart';

import 'visibility_detector/custom_visibility_detector_library.dart';

/// 注册本工程自定义的宿主能力（新增能力时在这里追加一行）。
void registerCustomCapabilities() {
  registerJsUiLibrary(const CustomVisibilityDetectorLibrary());
}
