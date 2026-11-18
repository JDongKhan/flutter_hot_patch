import 'package:dio/dio.dart';
import 'package:dynamic_flutter_annotations/dynamic_flutter_annotations.dart';

/// 网络请求（真实 dio）→ 宿主通道。
///
/// JS 侧的同名 `Dio` 类（`example/js/dio.js`）不自己发请求，只把「一次请求的
/// 形态」（method / url / query / headers / body）交给本通道；宿主用真实 dio
/// 执行后把 JSON 回填。方法体不参与依赖扫描，因此 dio 不会进 JS 产物。
///
/// 参数/返回值都是可 JSON 序列化的面：请求侧 `method` / `url` / `query` /
/// `headers` / `body`，响应侧 `statusCode` / `statusMessage` / `data` /
/// `headers` / `uri`。dio 的重语义（拦截器 / 适配器 / 取消令牌）留在宿主，
/// 不跨桥。
class DioBridge {
  @HostInjected('dioRequest')
  static Future<Map> request(Map spec) async {
    final headers = (spec['headers'] as Map?)?.map(
      (k, v) => MapEntry('$k', '$v'),
    );
    final res = await Dio().request<dynamic>(
      spec['url'] as String,
      data: spec['body'],
      queryParameters: (spec['query'] as Map?)?.cast<String, dynamic>(),
      options: Options(
        method: (spec['method'] as String?) ?? 'GET',
        headers: headers,
        responseType: ResponseType.json,
      ),
    );
    return {
      'statusCode': res.statusCode,
      'statusMessage': res.statusMessage,
      // mock 服务返回 JSON；非 JSON 响应时原样给字符串，不静默变 null。
      'data': res.data,
      'headers': res.headers.map.map(
        (k, v) => MapEntry(k, v.join(', ')),
      ),
      'uri': res.requestOptions.uri.toString(),
    };
  }
}
