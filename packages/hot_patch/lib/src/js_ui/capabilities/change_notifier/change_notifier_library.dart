// ===== 能力：ChangeNotifier 状态基类（JS 侧）=====
//
// 本能力只有 JS 片段（ChangeNotifier 基类本体），没有句柄通道、没有宿主组件、
// 也不参与 context.watch 解析——因此只重写 [jsFragments]。
//
// 它是「模型类可被订阅」的前提（provider 的 VM、通用作用域的 subscribeListenable
// 都依赖它），故排在其它能力之前注入。
import '../js_ui_library.dart';
import 'change_notifier_js.dart';

/// ChangeNotifier 基类的接入声明（provider / 任何状态库的共同地基）。
class ChangeNotifierLibrary extends JsUiLibrary {
  const ChangeNotifierLibrary();

  @override
  String get id => 'change-notifier';

  @override
  List<String> get jsFragments => const [changeNotifierSource];
}
