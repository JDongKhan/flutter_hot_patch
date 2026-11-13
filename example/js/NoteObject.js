// 自定义类的 JS 同名实现（宿主维护）：NoteObject
//
// 落点约定：`js/classes/<ClassName>.js` ↔ 本项目的 `NoteObject`
// （`lib/base/note_object.dart`）。构建时由 `ui_third_party_js` 拷贝到
// `patch/packages/classes/NoteObject.js`，**类名**即文件名（不是包名）；
// 其它产物引用 `NoteObject` 时按「类模块」import：
//
//   import { NoteObject } from '../packages/classes/NoteObject.js';
//
// 本文件**替代**该类的翻译产物：生成器不再为它产出 `patch/app/base/...`，
// JS 侧的一切成员调用都经句柄打到宿主那个真实实例上。
//
// import 路径按**产物**位置写（本文件随拷贝落在 `patch/packages/classes/`，
// 上两级才是 `patch/flutter.js`）。
import { JsHandleObject } from '../flutter.js';

export class NoteObject extends JsHandleObject {
  constructor(opts) {
    super();
    var o = opts || {};
    this._title = o.title || '未命名';
    // kind 与宿主桥一致（`obj/NoteObject`）；meta 即 Dart 构造实参。
    this.__bindHandle('obj/NoteObject', {
      meta: function (self) { return { title: self._title }; }
    });
  }

  // ---- 方法：每次调用都打到 Flutter 侧同一个实例（宿主回填返回值，异步取）----
  async greet(name) {
    return await this.__memberCall('greet', [name]);
  }

  async bump() {
    return await this.__memberCall('bump', []);
  }

  // ---- 字段：本地镜像 + 需要「以宿主为准」时读宿主 ----
  get title() { return this._title; }

  set title(v) {
    this._title = v;
    this.__memberSet('title', v);
  }

  async readTitle() {
    return await this.__memberGet('title');
  }
}
