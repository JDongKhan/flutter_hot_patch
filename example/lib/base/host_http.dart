import 'package:dio/dio.dart';
import 'package:dynamic_flutter_annotations/dynamic_flutter_annotations.dart';

/// 网络请求（dio）→ 宿主通道。
///
/// dio 的拦截器 / 适配器 / 取消令牌等语义太重，不适合在 JS 侧重写一套同名类；
/// 这里把它收口成工具类：调用点只认 [get]，由宿主用真实 dio 访问本地 mock
/// 服务（`tool/mock/`）。方法体不参与依赖扫描，因此 dio 不会进 JS 产物。
class HostHttp {
  @HostInjected('httpGet')
  static Future<Map> get(String url) async {
    final res = await Dio().get<dynamic>(url);
    return {
      'statusCode': res.statusCode,
      'statusMessage': res.statusMessage,
      'data': res.data,
    };
  }
}
