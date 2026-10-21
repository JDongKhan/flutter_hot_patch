/// patch 静态文件服务。
///
/// 把示例 App 根 `example/patch/` 目录暴露为 http 静态资源，供 demo 里的
/// JsUiWidget 通过 `http://127.0.0.1:8765/patch/...` 加载（散 .js 与 patch.zip
/// 都可访问）。示例 App 位于 example/，其 build_runner 产物落在 example/patch/。
///
/// 启动：在仓库根 `dart run tool/patch_server.dart`（建议用 start_patch_server.sh，
/// 它会先杀旧进程再打包并启动）。
///
/// 路由规则：
///   GET /patch/<相对路径>  → 返回 example/patch/ 下对应文件（Content-Type 按后缀识别）
///   GET /                 → 列目录（调试用）
library;

import 'dart:io';

const String _host = '127.0.0.1';
const int _port = 8765;

/// 示例 App 的 patch 产物目录（相对启动时的仓库根）。
final Directory _patchRoot = Directory('${Directory.current.path}/example/patch');

const Map<String, String> _mime = {
  '.js': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.zip': 'application/zip',
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
};

Future<void> main(List<String> args) async {
  if (!_patchRoot.existsSync()) {
    stderr.writeln('[patch_server] patch 目录不存在：${_patchRoot.path}');
    stderr.writeln('先在 example/ 跑 `dart run build_runner build --delete-conflicting-outputs` 生成产物。');
    exit(1);
  }

  final server = await HttpServer.bind(_host, _port);
  stdout.writeln('[patch_server] 已启动 http://$_host:$_port/');
  stdout.writeln('[patch_server] patch 根：${_patchRoot.path}');
  stdout.writeln('[patch_server] 试访问：http://$_host:$_port/patch/patch.zip');

  await for (final request in server) {
    unawaited(_handle(request));
  }
}

Future<void> _handle(HttpRequest request) async {
  final path = request.uri.path;
  try {
    if (path == '/' || path.isEmpty) {
      await _listIndex(request);
      return;
    }
    // 只服务 /patch/ 前缀，其余 404。
    if (!path.startsWith('/patch/')) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    final rel = path.substring('/patch/'.length);
    final file = File('${_patchRoot.path}/$rel');
    if (!file.existsSync()) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
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
    try {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write('$e');
      await request.response.close();
    } catch (_) {}
  }
}

Future<void> _listIndex(HttpRequest request) async {
  final files = _patchRoot
      .listSync(recursive: true)
      .whereType<File>()
      .map((f) => f.path.substring(_patchRoot.path.length + 1))
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

void unawaited(Future<void> f) {}
