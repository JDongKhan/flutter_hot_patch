import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/services.dart' show rootBundle;
import 'package:dynamic_flutter_annotations/dynamic_flutter_annotations.dart';

/// @author jd
///
/// 示例 App 的网络出口：**直接请求本地 mock 服务**
/// （`tool/patch_server.dart`，默认 `http://127.0.0.1:8765`）。
///
/// 服务端按 URL 路径读取 `tool/mock/<路径>.json` 并原样返回，所以新增一个
/// 接口只需加一个 json 文件。JS 产物里本类仍存在，只有本方法的方法体换成
/// `_app_host_.invoke('post', ...)`；调用点与 Dart 一比一（`Network.post(...)`），
/// 由宿主执行这里的真实 http 请求。
class Network {
  /// 本地 mock 服务地址：**由宿主在启动时注入**（example 的 `main()` 从
  /// `base/dev_server.dart` 取值），与补丁 zip 的地址同一处维护。
  /// 未注入时回退到本机默认地址，便于单测 / 独立运行。
  static String baseUrl = 'http://127.0.0.1:8765';

  /// mock 接口的离线副本目录（`example/assets/mock/`，构建时打包进 assets）。
  static const String _localMockRoot = 'assets/mock';

  @HostInjected()
  static Future<Map> post({required String url, dynamic params}) async {
    // release 发给别人时连不到本机的 127.0.0.1 mock 服务：改读打包进
    // assets 的同一份 json（路径规则与服务端一致：`<url>.json`）。
    if (kReleaseMode) {
      debugPrint("release 模式：读取本地 mock $url");
      return _loadLocalMock(url);
    }
    final path = url.startsWith('/') ? url : '/$url';
    debugPrint("开始网络请求：$baseUrl$path");
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final request = await client.openUrl('POST', Uri.parse('$baseUrl$path'));
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

  /// 读 `assets/mock/<路径>.json`（与服务端 [MockRoute] 的路径规则一致）：
  /// `/app/home`、`app/home.json` 都映射到 `assets/mock/app/home.json`。
  static Future<Map> _loadLocalMock(String url) async {
    final segments = Uri.parse(url)
        .pathSegments
        .where((s) => s.isNotEmpty)
        .toList();
    for (final s in segments) {
      if (s == '.' || s == '..' || s.contains('\\')) {
        throw ArgumentError('非法的接口路径：$url');
      }
    }
    var rel = segments.join('/');
    if (rel.isEmpty) rel = 'index';
    if (!rel.endsWith('.json')) rel = '$rel.json';
    final asset = '$_localMockRoot/$rel';
    late final String text;
    try {
      text = await rootBundle.loadString(asset);
    } catch (e) {
      // 不静默：release 读不到离线副本时必须让调用方看到是哪个 asset 缺了。
      throw StateError('release 模式缺少本地 mock：$asset（$e）');
    }
    return jsonDecode(text) as Map;
  }
}
