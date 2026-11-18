import '../../utils/dynamic_flutter_log.dart';
import 'builtin_host_method_group.dart';

/// `log`：JS 侧 `print` / `debugPrint` → JsLog。级别由 JS 侧一并传来
/// （见 runtime_js 的 `G.print` / `G.debugPrint`：info / debug），未知级别
/// 按 info 处理。
final class LogHostMethods extends BuiltinHostMethodGroup {
  const LogHostMethods();

  @override
  Map<String, Function> get methods => {'log': _log};

  void _log(String? level, Object? message) =>
      JsLog.emit(_levelOf(level), '[js-log] $message');

  JsLogLevel _levelOf(String? name) => switch (name) {
    'debug' => JsLogLevel.debug,
    'warn' => JsLogLevel.warn,
    'error' => JsLogLevel.error,
    _ => JsLogLevel.info,
  };
}
