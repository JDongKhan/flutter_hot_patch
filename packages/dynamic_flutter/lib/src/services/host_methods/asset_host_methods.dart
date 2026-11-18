import '../../utils/dynamic_flutter_assets.dart';
import 'builtin_host_method_group.dart';

/// `assetLoadString`：JS 侧 `rootBundle.loadString(key)` 的宿主落点。
///
/// 解析顺序与图片一致：补丁包根下同名文件优先，缺失或读取失败回退 Flutter
/// assets（见 [JsAssets]）。
final class AssetHostMethods extends BuiltinHostMethodGroup {
  const AssetHostMethods();

  @override
  Map<String, Function> get methods => {'assetLoadString': _assetLoadString};

  Future<String> _assetLoadString(String key) =>
      JsAssets.bundle.loadString(key);
}
