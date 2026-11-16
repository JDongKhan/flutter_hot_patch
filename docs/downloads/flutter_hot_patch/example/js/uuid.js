// 三方库 JS（宿主维护）：uuid
//
// 文件名即 Dart 包名（`js/uuid.js` ↔ `package:uuid`），构建时原样拷贝到
// `patch/packages/uuid.js`。
//
// `Uuid` 属于「必须先构造才能用」的库：
//   final id = Uuid();
//   id.v4();
// 这里提供最小同名实现：构造实参由生成器按 Dart 构造签名映射成对象
// （`new Uuid({ options: ... })`），v4 直接用平台 crypto，缺失时退回
// Math.random 拼装（仅用于演示）。
export class Uuid {
  constructor(args) {
    var a = args || {};
    this.options = a.options || null;
  }

  v4() {
    var crypto = typeof globalThis !== 'undefined' ? globalThis.crypto : null;
    if (crypto && typeof crypto.randomUUID === 'function') {
      return crypto.randomUUID();
    }
    var bytes = [];
    for (var i = 0; i < 16; i++) {
      bytes.push(Math.floor(Math.random() * 256));
    }
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    var hex = bytes.map(function (b) {
      return (b + 0x100).toString(16).substring(1);
    }).join('');
    return hex.substring(0, 8) + '-' + hex.substring(8, 12) + '-'
      + hex.substring(12, 16) + '-' + hex.substring(16, 20) + '-'
      + hex.substring(20);
  }
}
