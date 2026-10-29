// KeyboardListener 能力的 JS 片段：KeyEvent / LogicalKeyboardKey 镜像 +
// 宿主 → JS 的按键事件派发。
//
// 为什么事件不在宿主直接 invoke：`__jsui.invoke` 只能传 JSON 值，而 Dart 侧的
// 事件是**类实例**（`event.logicalKey` / `event.character` / `event is KeyDownEvent`
// 都是对象成员与类型）。因此宿主把原生 KeyEvent 归一成 JSON，经
// `__jsuiKeyEvent(句柄 id, 事件 JSON)` 交给本片段还原成实例后调用事件句柄——
// 与 Dismissible 的 `__jsuiAwaitValue` 同一约定（唯一出口仍是 `handles[id].obj`）。
//
// 常量身份：Dart 的 LogicalKeyboardKey 是**常量实例**，源码里的
// `event.logicalKey == LogicalKeyboardKey.enter` 比较的是同一个常量对象。JS 侧
// 按 keyId 归一（同一 keyId 永远返回同一实例），常量与宿主回传的事件因此指向
// 同一对象，比较语义与 Dart 一致。
//
// 类型判别：Dart 用 `event is KeyDownEvent` 区分按下 / 重复 / 抬起，JS 侧因此
// 生成三个**真子类**（同一构造体 + 各自原型的 `instanceof`），`is` 表达式由
// 生成器翻成 `instanceof`（见 translator/js_value.dart 的 typeTestJs）。
const String keyboardListenerJsSource = r'''
  // LogicalKeyboardKey：keyId → 实例（身份去重，常量与事件共用同一张表）。
  var __keyInstances = {};
  function __logicalKey(keyId, label) {
    var k = __keyInstances[keyId];
    if (!k) {
      k = { keyId: keyId, keyLabel: label || '', debugName: label || '' };
      __keyInstances[keyId] = k;
    }
    return k;
  }

  // 常量表：名字 → [keyId, keyLabel]。宿主回传的事件按 keyId 归一，所以这里
  // 只登记「JS 源码里可能出现的名字」，两端读到的仍是同一实例。
  var __KEY_CONSTS = {
    space: [0x00000000020, 'Space'],
    enter: [0x0010000000D, 'Enter'],
    escape: [0x0010000001B, 'Escape'],
    tab: [0x00100000009, 'Tab'],
    backspace: [0x00100000008, 'Backspace'],
    delete: [0x0010000007F, 'Delete'],
    capsLock: [0x00100000104, 'Caps Lock'],
    arrowUp: [0x00100000304, 'Arrow Up'],
    arrowDown: [0x00100000301, 'Arrow Down'],
    arrowLeft: [0x00100000302, 'Arrow Left'],
    arrowRight: [0x00100000303, 'Arrow Right'],
    home: [0x00100000306, 'Home'],
    end: [0x00100000305, 'End'],
    pageUp: [0x00100000308, 'Page Up'],
    pageDown: [0x00100000307, 'Page Down'],
    controlLeft: [0x00200000100, 'Control Left'],
    controlRight: [0x00200000101, 'Control Right'],
    shiftLeft: [0x00200000102, 'Shift Left'],
    shiftRight: [0x00200000103, 'Shift Right'],
    altLeft: [0x00200000104, 'Alt Left'],
    altRight: [0x00200000105, 'Alt Right'],
    metaLeft: [0x00200000106, 'Meta Left'],
    metaRight: [0x00200000107, 'Meta Right']
  };
  // 数字与字母键：logical keyId 就是字符码（digit0 = 0x30，keyA = 0x61），
  // keyLabel 与 Flutter 一致（大写字母 / 数字本身）。
  for (var __d = 0; __d < 10; __d++) {
    __KEY_CONSTS['digit' + __d] = [0x30 + __d, String(__d)];
  }
  for (var __c = 0; __c < 26; __c++) {
    var __letter = String.fromCharCode(0x61 + __c).toUpperCase();
    __KEY_CONSTS['key' + __letter] = [0x61 + __c, __letter];
  }
  var LogicalKeyboardKey = {};
  for (var __name in __KEY_CONSTS) {
    __defineProtoGetter(LogicalKeyboardKey, __name, (function (name) {
      return function () { return __logicalKey(__KEY_CONSTS[name][0], __KEY_CONSTS[name][1]); };
    })(__name));
  }
  G.LogicalKeyboardKey = LogicalKeyboardKey;

  // PhysicalKeyboardKey：`event.physicalKey.usbHidUsage` 按 usb 码归一。
  var __physKeys = {};
  export class PhysicalKeyboardKey {
    constructor(props) {
      props = props || {};
      this.usbHidUsage = props.usbHidUsage;
      this.debugName = props.debugName || '';
    }
  }
  G.PhysicalKeyboardKey = PhysicalKeyboardKey;
  function __physicalKey(usb, label) {
    var k = __physKeys[usb];
    if (!k) {
      k = new PhysicalKeyboardKey({ usbHidUsage: usb, debugName: label });
      __physKeys[usb] = k;
    }
    return k;
  }

  // KeyEvent：Dart 的 KeyEvent 是抽象基类，按下 / 抬起 / 重复是三个子类，
  // 源码用 `event is KeyDownEvent` 区分——这里生成真子类以保持同一语义。
  export class KeyEvent {
    constructor(props) {
      props = props || {};
      this.physicalKey = props.physicalKey;
      this.logicalKey = props.logicalKey;
      this.character = props.character == null ? null : String(props.character);
      this.timeStamp = props.timeStamp;
    }
  }
  G.KeyEvent = KeyEvent;

  // 按键事件子类：Dart 侧各自是 KeyEvent 的子类，JS 侧原生 extends（这样
  // `instanceof KeyDownEvent` 与 `instanceof KeyEvent` 同时成立）。
  class KeyDownEvent extends KeyEvent {
    constructor(props) { super(props); }
  }
  class KeyUpEvent extends KeyEvent {
    constructor(props) { super(props); }
  }
  class KeyRepeatEvent extends KeyEvent {
    constructor(props) { super(props); }
  }
  G.KeyDownEvent = KeyDownEvent;
  G.KeyUpEvent = KeyUpEvent;
  G.KeyRepeatEvent = KeyRepeatEvent;

  // 宿主桥接见 capabilities/keyboard_listener/keyboard_listener_bridge.dart：
  // 原生 KeyEvent → JSON（kind / character / keyId / keyLabel / usbHidUsage /
  // timeStamp），这里还原成实例并调事件句柄。挂 G：宿主经 evaluate 裸引用调用。
  G.__jsuiKeyEvent = function (handleId, eventJson) {
    var h = handles[handleId];
    if (!h || typeof h.obj !== 'function') { return; }
    var m = {};
    try { m = JSON.parse(eventJson) || {}; } catch (e) { return; }
    var Ctor = __KEY_EVENT_SUBCLASSES[m.kind] || KeyEvent;
    h.obj(new Ctor({
      character: m.character,
      logicalKey: __logicalKey(m.logicalKeyId, m.logicalKeyLabel),
      physicalKey: __physicalKey(m.physicalKeyUsb, m.physicalKeyLabel),
      timeStamp: new Duration({ microseconds: m.timeStampUs || 0 })
    }));
  };
''';
