/// 请求分发：只判断前缀，具体处理交给对应路由文件。
library;

import 'dart:io';

import 'mock_route.dart';
import 'patch_route.dart';

class ServerRouter {
  ServerRouter({required String repoRoot})
      : patchRoute = PatchRoute(repoRoot: repoRoot),
        mockRoute = MockRoute(repoRoot: repoRoot);

  final PatchRoute patchRoute;
  final MockRoute mockRoute;

  Directory get patchRoot => patchRoute.root;
  Directory get mockRoot => mockRoute.root;

  /// `/` 与 `/patch/*` 走静态产物；其余一律按普通接口处理。
  Future<void> handle(HttpRequest request) async {
    final path = request.uri.path;
    if (path.isEmpty || path == '/' || path.startsWith('/patch/')) {
      await patchRoute.handle(request);
      return;
    }
    await mockRoute.handle(request);
  }
}
