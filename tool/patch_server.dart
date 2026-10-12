/// patch 静态文件服务。
///
/// 把项目根 `patch/` 目录暴露为 http 静态资源，供 demo 里的 JsUiWidget
/// 通过 `http://127.0.0.1:8765/patch/...` 加载（散 .js 与 patch.zip 都可访问）。
///
/// 启动：`dart run tool/patch_server.dart`（建议用 tool/start_patch_server.sh，
/// 它会先杀旧进程再打包并启动）。
///
/// 路由规则：
///   GET /patch/<相对路径>  → 返回 patch/ 下对应文件（Content-Type 按后缀识别）
///   GET /                 → 列目录（调试用）
library;

import 'dart:io';

const String _host = '127.0.0.1';
const int _port = 8765;

/// patch/ 根目录（脚本所在目录的上一级）。
final Directory _patchRoot = Directory('${Directory.current.path}/patch');

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
    stderr.writeln('先跑 `dart run build_runner build --delete-conflicting-outputs` 生成产物。');
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
    final ext = rel.contains('.') ? rel.substring(rel.lastIndexOf('.')) : '';
    request.response.headers.contentType = ContentType.parse(
      _mime[ext] ?? 'application/octet-stream',
    );
    // 关缓存：改完 js 立即生效。
    request.response.headers.set('Cache-Control', 'no-store');
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
