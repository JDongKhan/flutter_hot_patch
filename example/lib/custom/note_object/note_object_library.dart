// ===== 能力：自定义实例对象 ↔ JS 同名类（对象绑定）=====
//
// 全部框架改动为零：句柄机制（create / call / get / set / release）是通用的，
//
//   JS 侧 `new NoteObject({...})` → `__bindHandle('obj/NoteObject')`
//        → 宿主 `jsHandle op:'create'` → 本桥 onCreate 创建真实 NoteObject；
//   JS 侧 `obj.greet('x')` → `__handleOp(id, 'call', {method, args})`
//        → 本桥 onOp → `dispatchJsMember` → `NoteObject.jsMember`。
//
// 命名也去掉了 controller 味：kind 用 `obj/<类名>`，桥是 `JsObjectBridge`。
import 'package:dynamic_flutter/dynamic_flutter.dart';

import '../../base/note_object.dart';

final JsObjectBridge<NoteObject> _noteObjectBridge = JsObjectBridge<NoteObject>(
  kind: 'obj/NoteObject',
  // meta 是 JS 侧构造参数（`new NoteObject({title: ...})`）→ 宿主据此建实例。
  create: (_, meta) {
    final m = meta is Map ? meta : const {};
    return NoteObject(title: m['title'] == null ? '未命名' : '${m['title']}');
  },
  // 通用分派：类实现 JsHandleMembers 就转给它，不需要为每个类写 switch。
  onOp: dispatchJsMember,
  // 默认释放语义是 ChangeNotifier / AnimationController 的 dispose；
  // 本类没有要释放的资源，故不覆写 onRelease。
);

/// 幂等注册（由 `JsUiLibrary.ensureChannels` 在 `initJsUi` 内调用）。
void ensureNoteObjectChannels() => _noteObjectBridge.ensure();

/// 能力接入声明：放进 `customJsUiLibraries`，随 `initJsUi(libraries: …)` 一次完成。
class NoteObjectLibrary extends JsUiLibrary {
  const NoteObjectLibrary();

  @override
  String get id => 'note-object';

  @override
  void ensureChannels() => ensureNoteObjectChannels();
}
