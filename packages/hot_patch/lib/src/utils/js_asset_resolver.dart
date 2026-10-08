/// JS 产物地址解析工具。
///
/// 生成器产出的 import 是**相对路径**（相对当前组件产物所在目录）：
/// 未来产物整体发布（CDN / 包内迁移）时，主产物与依赖产物的相对关系不变。
/// 运行时以当前 jsAsset 的目录为基准，把相对 import 解析成完整地址。
class JsAssetResolver {
  const JsAssetResolver._();

  /// 以 [base]（目录，含尾 '/'）为基准解析 [rel]（含 './' / '../'）。
  ///
  /// - asset 路径（assets/...）与远端 URL（https://...）通用，
  ///   纯字符串段处理，不区分协议；
  /// - [rel] 本身已是完整地址（http(s)://、assets/、package:）时直接返回。
  static String resolve(String base, String rel) {
    if (rel.startsWith('http://') ||
        rel.startsWith('https://') ||
        rel.startsWith('assets/') ||
        rel.startsWith('package:')) {
      return rel;
    }
    final segs = <String>[];
    if (base.isNotEmpty) {
      segs.addAll(base.split('/').where((p) => p.isNotEmpty));
      if (!base.endsWith('/')) segs.removeLast(); // base 是目录则保留
    }
    for (final part in rel.split('/')) {
      if (part == '.' || part.isEmpty) continue;
      if (part == '..') {
        if (segs.isNotEmpty) segs.removeLast();
      } else {
        segs.add(part);
      }
    }
    return segs.join('/');
  }
}
