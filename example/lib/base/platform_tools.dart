import 'package:dynamic_flutter_annotations/dynamic_flutter_annotations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// 常用三方库 → 宿主工具类（统一用 `@HostInjected` 收口）。
///
/// 这些库都只是「调个平台能力、拿个值」，没有必要在 JS 侧重新实现：方法体
/// 留在宿主（真实调用 path_provider / package_info_plus / permission_handler），
/// JS 产物里同名类只保留被标注的方法，方法体换成 `_app_host_.invoke(...)`。
/// 调用点与 Dart 一比一。
class PlatformTools {
  /// 临时目录（path_provider）。
  @HostInjected()
  static Future<String> tempPath() async {
    final dir = await getTemporaryDirectory();
    return dir.path;
  }

  /// 文档目录（path_provider）。
  @HostInjected()
  static Future<String> documentsPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  /// 应用名 + 版本（package_info_plus）。
  @HostInjected()
  static Future<String> appVersion() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.appName} ${info.version}+${info.buildNumber}';
  }

  /// 查询相册权限（permission_handler，不弹窗）。
  @HostInjected()
  static Future<String> photoPermissionStatus() => _photoStatus(request: false);

  /// 申请相册权限（permission_handler，会弹系统弹窗）。
  @HostInjected()
  static Future<String> requestPhotoPermission() => _photoStatus(request: true);

  /// 非宿主注入方法：只服务宿主实现，不产出到 JS。
  ///
  /// permission_handler 没有 macOS 实现（`MissingPluginException`），
  /// 这里如实返回「当前平台不支持」而不是让调用方崩掉。
  static Future<String> _photoStatus({required bool request}) async {
    try {
      final status = request
          ? await Permission.photos.request()
          : await Permission.photos.status;
      return '$status';
    } catch (e) {
      return '当前平台不支持：$e';
    }
  }
}
