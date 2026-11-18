import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:dynamic_flutter_annotations/dynamic_flutter_annotations.dart';

import '../base/dev_server.dart';

/// dio 对比 demo（左原生 / 右 JS 热更）。
///
/// **两侧源码是同一份 Dart**：`final Dio _dio = Dio();` +
/// `await _dio.get(url, queryParameters: …)` + `res.statusCode` / `res.data`，
/// 没有任何为了可翻译而改写的写法。
///
/// 区别只在「谁发请求」：
/// - 原生侧 `_dio` 是真实的 `package:dio`，走原生 HTTP；
/// - JS 侧 `_dio` 是 `example/js/dio.js` 的同名类，`await` 落到宿主通道
///   `dioRequest`，由宿主用真实 dio 执行（见 `example/lib/base/dio_bridge.dart`）。
@PatchEntry('DioCard')
class DioCard extends StatefulWidget {
  const DioCard({super.key});

  @override
  State<DioCard> createState() => _DioCardState();
}

class _DioCardState extends State<DioCard> {
  /// 与 Dart 完全一致的构造：无参 `Dio()`。
  final Dio _dio = Dio();

  String _hello = '尚未请求';
  String _helloBody = '—';
  String _community = '尚未请求';
  String _communityDetail = '—';

  Future<void> _callHello() async {
    setState(() => _hello = '请求中…');
    try {
      final res = await _dio.get('$devServerBaseUrl/hello');
      final body = res.data;
      final message = body == null ? '' : '${body['message']}';
      final name = body == null ? '' : '${body['data']['name']}';
      setState(() {
        _hello = 'HTTP ${res.statusCode} · ${res.statusMessage ?? ''}';
        _helloBody = '$message / name=$name';
      });
    } catch (e) {
      setState(() => _hello = '失败：$e');
    }
  }

  Future<void> _callCommunity() async {
    setState(() => _community = '请求中…');
    try {
      // 带 query 参数：`queryParameters` 与 Dart 同名同样传。
      final res = await _dio.get(
        '$devServerBaseUrl/app/community',
        queryParameters: {'tab': 'recommend', 'page': 2},
      );
      final uri = '${res.requestOptions.uri}';
      final root = res.data;
      final tabs = root == null ? '' : '${root['tabs']}';
      setState(() {
        _community = 'HTTP ${res.statusCode} · $uri';
        _communityDetail = 'tabs = $tabs';
      });
    } catch (e) {
      setState(() => _community = '失败：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'final Dio _dio = Dio();  await _dio.get(url, queryParameters: …)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00897B),
              ),
            ),
            const SizedBox(height: 8),
            _Line(label: 'GET /hello', value: _hello),
            _Line(label: '响应体', value: _helloBody),
            const SizedBox(height: 8),
            _Line(label: 'GET /app/community', value: _community),
            _Line(label: 'query 参数', value: _communityDetail),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _callHello,
                  child: const Text('GET /hello'),
                ),
                ElevatedButton(
                  onPressed: _callCommunity,
                  child: const Text('带 query 请求'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'API 与 Dart 一比一（Dio / Options / Response / DioException 同名）：'
              'JS 侧由 js/dio.js 承接，底层调用宿主真实 dio',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
