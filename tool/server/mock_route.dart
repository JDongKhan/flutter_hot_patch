/// 普通接口路由：**一套统一逻辑**——URL 路径即 json 文件路径。
///
///   GET|POST /app/home        → tool/mock/app/home.json
///   GET|POST /app/orders/list → tool/mock/app/orders/list.json
///   GET|POST /hello           → tool/mock/hello.json
///
/// 新增接口只要在 tool/mock 下放一个同路径的 json 文件，无需改服务端代码。
/// 查询参数不参与文件定位（读哪个文件只由路径决定），返回文件原文。
library;

import 'dart:io';

class MockRoute {
  MockRoute({required String repoRoot}) : root = Directory('$repoRoot/tool/mock');

  final Directory root;

  Future<void> handle(HttpRequest request) async {
    try {
      final file = _fileOf(request.uri.path);
      if (file == null) {
        await _notFound(request, '非法路径');
        return;
      }
      if (!file.existsSync()) {
        await _notFound(request, '没有对应的 json 文件');
        return;
      }
      stdout.writeln('[mock] ${request.method} ${request.uri.path} -> ${_relative(file)}');
      request.response.headers.contentType =
          ContentType('application', 'json', charset: 'utf-8');
      // 与 patch 产物一致：改完 json 立即生效，不做主动缓存。
      request.response.headers.set('Cache-Control', 'no-cache');
      await request.response.addStream(file.openRead());
      await request.response.close();
    } catch (e) {
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write('{"error":"${e.toString().replaceAll('"', r'\"')}"}');
        await request.response.close();
      } catch (_) {}
    }
  }

  /// URL 路径 → `tool/mock/<路径>.json`。含 `..` 等越界片段时返回 null。
  File? _fileOf(String path) {
    final segments = Uri.parse(path).pathSegments.where((s) => s.isNotEmpty).toList();
    for (final s in segments) {
      if (s == '.' || s == '..' || s.contains('\\')) return null;
    }
    final rel = segments.join('/');
    final name = rel.isEmpty
        ? 'index'
        : (rel.endsWith('.json') ? rel : '$rel.json');
    final file = File('${root.path}/$name');
    // 双保险：解析后的绝对路径必须仍在 mock 根下。
    final rootPath = root.absolute.path;
    if (!file.absolute.path.startsWith('$rootPath/')) return null;
    return file;
  }

  String _relative(File file) => file.path.substring(root.path.length + 1);

  Future<void> _notFound(HttpRequest request, String reason) async {
    request.response.statusCode = HttpStatus.notFound;
    request.response.headers.contentType =
        ContentType('application', 'json', charset: 'utf-8');
    request.response.write(
      '{"error":"mock not found","reason":"$reason",'
      '"path":"${request.uri.path}","file":"${_relativeOrRaw(request.uri.path)}"}',
    );
    await request.response.close();
  }

  String _relativeOrRaw(String path) {
    final file = _fileOf(path);
    return file == null ? path : _relative(file);
  }
}
