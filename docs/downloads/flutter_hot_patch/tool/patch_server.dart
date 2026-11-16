/// 本地服务入口：启动 HTTP 服务并交给 [ServerRouter] 分发。
///
/// 两类路由（各自一个文件，互不掺杂）：
///   - `/patch/*`、`/`        → [PatchRoute]（example/patch/ 静态产物）
///   - 其余路径                → [MockRoute]（tool/mock/ 下按路径对应的 json）
///
/// 启动：在仓库根 `dart run tool/patch_server.dart`（建议用 start_patch_server.sh）。
library;

import 'dart:async';
import 'dart:io';

import 'server/router.dart';

const String _host = '127.0.0.1';
const int _port = 8765;

Future<void> main(List<String> args) async {
  final router = ServerRouter(repoRoot: Directory.current.path);

  if (!router.patchRoot.existsSync()) {
    stderr.writeln('[patch_server] patch 目录不存在：${router.patchRoot.path}');
    stderr.writeln('先在 example/ 跑 `dart run build_runner build --delete-conflicting-outputs` 生成产物。');
    exit(1);
  }
  if (!router.mockRoot.existsSync()) {
    stderr.writeln('[patch_server] mock 目录不存在：${router.mockRoot.path}（普通接口会全部 404）');
  }

  final server = await HttpServer.bind(_host, _port);
  stdout.writeln('[patch_server] 已启动 http://$_host:$_port/');
  stdout.writeln('[patch_server] patch 根：${router.patchRoot.path}');
  stdout.writeln('[patch_server] mock 根：${router.mockRoot.path}');
  stdout.writeln('[patch_server] 试访问：http://$_host:$_port/patch/patch.zip');
  stdout.writeln('[patch_server] 试访问：http://$_host:$_port/app/home');

  await for (final request in server) {
    unawaited(router.handle(request));
  }
}
