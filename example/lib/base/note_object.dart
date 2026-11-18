import 'package:dynamic_flutter/dynamic_flutter.dart';
import 'package:dynamic_flutter_annotations/dynamic_flutter_annotations.dart';

/// 宿主自定义类 → JS 同名类（`example/js/NoteObject.js`）的绑定示例。
///
/// 这是「实例对象绑定」的通用姿势：JS 侧 `new NoteObject({...})` 经句柄
/// `obj/NoteObject` 在宿主创建**本类真实实例**，之后 JS 侧的每一次成员调用
/// （方法 / 读字段 / 写字段）都按成员名打到这个实例上。
///
/// 开发者成本只有两处：
///   1. 本类实现 [JsHandleMembers]：`jsMember` 里一行一个成员（Dart 无反射，
///      字符串成员名只能由类自己声明映射）；
///   2. 一个 5 行的 `JsObjectBridge` 注册（见 `custom/note_object/`）。
/// `@PatchIgnore()`：本类不翻译（Dart 无反射，成员分派只能在这里声明），
/// JS 侧同名实现由宿主 `js/<类名>.js` 提供（产物 `patch/packages/NoteObject.js`）。
@PatchIgnore()
class NoteObject implements JsHandleMembers {
  NoteObject({String title = '未命名'}) : _title = title;

  String _title;
  int calls = 0;

  String get title => _title;

  /// 方法：返回字符串（演示用，真实场景可以是任意可 JSON 化的值）。
  String greet(String name) {
    calls = calls + 1;
    return 'Flutter 侧问候：你好，$name';
  }

  /// 方法：读宿主自己的状态，证明调用确实落在宿主实例上。
  String bump() {
    calls = calls + 1;
    return '宿主实例第 $calls 次被调用';
  }

  /// 方法：读字段（JS 侧字段镜像可能过期，这里演示「以宿主为准」）。
  String readTitle() => _title;

  @override
  Object? jsMember(String op, Map payload) {
    if (op == 'call') {
      final method = '${payload['method']}';
      final args = payload['args'] is List ? payload['args'] as List : const [];
      if (method == 'greet') {
        return greet(args.isEmpty ? '' : '${args[0]}');
      }
      if (method == 'bump') return bump();
      if (method == 'readTitle') return readTitle();
    } else if (op == 'get') {
      final name = '${payload['name']}';
      if (name == 'title') return _title;
      if (name == 'calls') return calls;
    } else if (op == 'set') {
      final name = '${payload['name']}';
      if (name == 'title') _title = '${payload['value']}';
    }
    return null;
  }
}
