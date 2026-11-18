import '../../js_ui/js_ui_store.dart';
import '../../utils/dynamic_flutter_log.dart';
import 'builtin_host_method_group.dart';

/// `jsuiCommit`：把 JS 算好的增量补丁按页面 key 应用到对应 [JsUiStore]。
final class JsUiCommitHostMethods extends BuiltinHostMethodGroup {
  const JsUiCommitHostMethods();

  @override
  Map<String, Function> get methods => {'jsuiCommit': _commit};

  void _commit({required String key, required List ops}) {
    final store = jsUiPageStores[key];
    if (store == null) {
      // 页面已销毁 / 还没登记：补丁无处可落，整批丢弃。属于正常竞态，但必须留痕。
      JsLog.debug(
        'jsuiCommit: 页面 "$key" 已销毁或未登记，'
        '${ops.length} 条补丁已丢弃',
      );
      return;
    }
    store.apply(ops);
  }
}
