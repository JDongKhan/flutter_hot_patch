// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/base/note_object.dart 自动生成
// 重新生成：dart run build_runner build

import { NoteObject } from '../packages/classes/NoteObject.js';

// 模型 NoteObject
export class NoteObject {
  constructor(args) {
    const title = args.title !== undefined ? args.title : "未命名";
    this._title = '';
    this.calls = 0;
    this._title = title;
  }
  get title() {
    return this._title;
  }
  greet(name) {
    this.calls = (this.calls + 1);
    return "Flutter 侧问候：你好，" + name;
  }
  bump() {
    this.calls = (this.calls + 1);
    return "宿主实例第 " + this.calls + " 次被调用";
  }
  readTitle() {
    return this._title;
  }
  jsMember(op, payload) {
    if ((op === "call")) {
      const method = "" + __nn(__idx(payload, "method"));
      if ((method === "greet")) {

      }
      if ((method === "bump")) {
        return this.bump();
      }
      if ((method === "readTitle")) {
        return this.readTitle();
      }
    } else {
      if ((op === "get")) {
        const name = "" + __nn(__idx(payload, "name"));
        if ((name === "title")) {
          return this._title;
        }
        if ((name === "calls")) {
          return this.calls;
        }
      } else {
        if ((op === "set")) {
          const name = "" + __nn(__idx(payload, "name"));
          if ((name === "title")) {
            this._title = "" + __nn(__idx(payload, "value"));
          }
        }
      }
    }
    return null;
  }
}

