import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// @author jd
///
/// 账号中心：获取用户信息的宿主能力。
///
/// 被设计为 **@HostInjected**：实现留在 Dart 侧（未来会加入缓存、网络请求等
/// 复杂逻辑），不翻译成 JS。@PatchEntry 组件里调用 `AccountCenter.getUserName()`
/// 时，生成器只把调用点替换为 `_app_host_.invoke("getUserName", [])`，
/// 由宿主 `JsRuntimeManager.registerHostMethod` 接回调并回填返回值。
class AccountCenter {
  /// 通道名缺省 = 方法名（'getUserName'）。
  @HostInjected()
  static Future<String> getUserName() async {
    return "22";
  }
}