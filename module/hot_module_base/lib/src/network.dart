import 'dart:convert';
import 'dart:io';

import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// @author jd
///
/// 示例 App 的网络出口：**直接请求本地 mock 服务**
/// （`tool/patch_server.dart`，默认 `http://127.0.0.1:8765`）。
///
/// 服务端按 URL 路径读取 `tool/mock/<路径>.json` 并原样返回，所以新增一个
/// 接口只需加一个 json 文件。JS 产物里本方法调用点仍走 `@HostInjected` 通道
/// （`_app_host_.invoke('post', ...)`），由宿主执行这里的真实 http 请求。
class Network {
  static const String _baseUrl = 'http://127.0.0.1:8765';

  @HostInjected()
  static Future<Map> post({required String url, dynamic params}) async {
    final path = url.startsWith('/') ? url : '/$url';
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final request = await client.openUrl('POST', Uri.parse('$_baseUrl$path'));
      request.headers.contentType = ContentType.json;
      final body = params == null ? '' : jsonEncode(params);
      request.write(body);
      final response = await request.close().timeout(const Duration(seconds: 5));
      final text = await response.transform(utf8.decoder).join();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'mock 接口请求失败: $path → HTTP ${response.statusCode} $text',
        );
      }
      return jsonDecode(text) as Map;
    } finally {
      client.close(force: true);
    }
  }
}
