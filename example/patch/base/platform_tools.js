// GENERATED CODE - DO NOT EDIT
// 由 dynamic_flutter_generator 从 lib/base/platform_tools.dart 自动生成
// 重新生成：dart run build_runner build


// 模型 PlatformTools
export class PlatformTools {
  constructor() {
  }
  static async tempPath() {
    return _app_host_.invoke("tempPath", Array.prototype.slice.call(arguments));
  }
  static async documentsPath() {
    return _app_host_.invoke("documentsPath", Array.prototype.slice.call(arguments));
  }
  static async appVersion() {
    return _app_host_.invoke("appVersion", Array.prototype.slice.call(arguments));
  }
  static photoPermissionStatus() {
    return _app_host_.invoke("photoPermissionStatus", Array.prototype.slice.call(arguments));
  }
  static requestPhotoPermission() {
    return _app_host_.invoke("requestPhotoPermission", Array.prototype.slice.call(arguments));
  }
}

