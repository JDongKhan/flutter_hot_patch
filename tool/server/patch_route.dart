/// patch 静态文件路由。
///
/// 把示例 App 根 `example/patch/` 目录暴露为 http 静态资源，供 demo 里的
/// JsUiWidget 通过 `http://127.0.0.1:8765/patch/...` 加载（散 .js 与 patch.zip
/// 都可访问）。
///
/// 路由规则：
///   GET /patch/<相对路径>  → 返回 example/patch/ 下对应文件（Content-Type 按后缀识别）
///   GET /                 → 列目录（调试用）
library;

import 'dart:io';

class PatchRoute {
  PatchRoute({required String repoRoot})
      : root = Directory('$repoRoot/example/patch');

  final Directory root;

  static const Map<String, String> _mime = {
    '.js': 'application/javascript; charset=utf-8',
    '.json': 'application/json; charset=utf-8',
    '.zip': 'application/zip',
    '.html': 'text/html; charset=utf-8',
    '.css': 'text/css; charset=utf-8',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
  };

  Future<void> handle(HttpRequest request) async {
    final path = request.uri.path;
    try {
      if (path.isEmpty || path == '/') {
        await _listIndex(request);
        return;
      }
      final rel = path.substring('/patch/'.length);
      final file = File('${root.path}/$rel');
      if (!file.existsSync()) {
        await _notFound(request);
        return;
      }
      final modified = file.statSync().modified;
      // 304 协商：客户端带 If-Modified-Since 且文件未变 → 返回 304，不发 body。
      // 注意：① 文件 mtime 精确到毫秒，请求头精确到秒——截断到秒再对比；
      // ② 文件 mtime 是本地时区，HttpDate.parse 是 UTC——统一转 UTC 再对比。
      final ifModifiedSince = request.headers.value(HttpHeaders.ifModifiedSinceHeader);
      if (ifModifiedSince != null) {
        final since = HttpDate.parse(ifModifiedSince).toUtc();
        final modUtc = modified.toUtc();
        final modifiedSec = DateTime.utc(
          modUtc.year, modUtc.month, modUtc.day,
          modUtc.hour, modUtc.minute, modUtc.second,
        );
        // 只有文件**严格更旧**才 304：mtime 与 If-Modified-Since 都只到秒，
        // 同一秒内重新打包 zip 时用 isAfter 会误判为未变、让 App 继续用旧产物。
        // 宁可同秒返回 200 重新下载，也不能把新补丁当旧缓存复用。
        if (modifiedSec.isBefore(since)) {
          request.response.statusCode = HttpStatus.notModified;
          request.response.headers.set('Last-Modified', HttpDate.format(modified));
          await request.response.close();
          return;
        }
      }
      final ext = rel.contains('.') ? rel.substring(rel.lastIndexOf('.')) : '';
      request.response.headers.contentType = ContentType.parse(
        _mime[ext] ?? 'application/octet-stream',
      );
      // Last-Modified：客户端据此发 If-Modified-Since 做协商缓存。
      request.response.headers.set('Last-Modified', HttpDate.format(modified));
      // 关主动缓存：改完 js 立即生效；客户端仍可用 Last-Modified 做协商。
      request.response.headers.set('Cache-Control', 'no-cache');
      await request.response.addStream(file.openRead());
      await request.response.close();
    } catch (e) {
      await _error(request, e);
    }
  }

  Future<void> _listIndex(HttpRequest request) async {
    final files = root
        .listSync(recursive: true)
        .whereType<File>()
        .map((f) => f.path.substring(root.path.length + 1))
        .toList()
      ..sort();
    final buf = StringBuffer('<h1>patch/</h1><ul>');
    for (final f in files) {
      buf.write('<li><a href="/patch/$f">/patch/$f</a></li>');
    }
    buf.write('</ul>');
    request.response.headers.contentType = ContentType.html;
    request.response.write(buf.toString());
    await request.response.close();
  }

  Future<void> _notFound(HttpRequest request) async {
    request.response.statusCode = HttpStatus.notFound;
    await request.response.close();
  }

  Future<void> _error(HttpRequest request, Object error) async {
    try {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write('$error');
      await request.response.close();
    } catch (_) {}
  }
}
