// ===== rootBundle：assets 读取（flutter.js 值类区）=====
//
// Dart 的 `rootBundle` 是 `dart:services` 的顶层对象，产物里按名保持
// `rootBundle.loadString(key)`。宿主实现按「补丁包内同名资源优先，缺失或
// 读取失败回退 Flutter assets」解析（见 HotPatchAssets）。
//
// 只登记当前运行时真正承接的成员：`loadString` 返回 `Future<String>`，
// 与 Dart 同名方法同义。`load` / `loadStructuredData` 尚未实现，写入源码时
// 由宿主侧引用解析给出构建期告警，不做占位兜底。
const String assetBundleJsSource = r'''
  // ----- rootBundle ---------------------------------------------------------
  // 普通顶层对象调用原样产出；唯一的跨语言点是宿主通道 assetLoadString。
  export const rootBundle = {
    loadString(key) {
      return Future.__wrap(G._app_host_.invoke('assetLoadString', [key]));
    },
  };
''';
