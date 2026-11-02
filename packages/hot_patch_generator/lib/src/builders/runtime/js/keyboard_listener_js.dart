// KeyboardListener 能力的 JS 片段：KeyEvent / LogicalKeyboardKey 镜像 +
// 宿主 → JS 的按键事件派发。
//
// 为什么事件不在宿主直接 invoke：`__jsui.invoke` 只能传 JSON 值，而 Dart 侧的
// 事件是**类实例**（`event.logicalKey` / `event.character` / `event is KeyDownEvent`
// 都是对象成员与类型）。因此宿主把原生 KeyEvent 归一成 JSON，经
// `__keyEvent(句柄 id, 事件 JSON)` 交给本片段还原成实例后调用事件句柄——
// 句柄对象统一经 `handleObjectOf` 取（与 `__jsui.invokeAwait` 同一约定）。
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
  // 常量身份：Dart 的 LogicalKeyboardKey 是**常量实例**，源码里的
  // `event.logicalKey == LogicalKeyboardKey.enter` 比较的是同一个常量对象。JS 侧
  // 按 keyId 归一（同一 keyId 永远返回同一实例），常量与宿主回传的事件因此指向
  // 同一对象，比较语义与 Dart 一致。
  //
  // 常量是类的**静态 getter**（Dart 里它们本身就是属性）：成员随类声明，
  // 非枚举、无需运行时再往构造函数上动态挂成员。
  export class LogicalKeyboardKey {
    constructor(props) {
      props = props || {};
      this.keyId = props.keyId;
      this.keyLabel = props.keyLabel || '';
      this.debugName = props.debugName || this.keyLabel;
    }
    // keyId → 同一实例（常量与宿主回传的事件因此指向同一对象）。
    static __byId(keyId, label) {
      var k = LogicalKeyboardKey.__instances[keyId];
      if (!k) {
        k = new LogicalKeyboardKey({ keyId: keyId, keyLabel: label || '' });
        LogicalKeyboardKey.__instances[keyId] = k;
      }
      return k;
    }
    static get space() { return LogicalKeyboardKey.__byId(0x00000000020, 'Space'); }
    static get enter() { return LogicalKeyboardKey.__byId(0x0010000000D, 'Enter'); }
    static get escape() { return LogicalKeyboardKey.__byId(0x0010000001B, 'Escape'); }
    static get tab() { return LogicalKeyboardKey.__byId(0x00100000009, 'Tab'); }
    static get backspace() { return LogicalKeyboardKey.__byId(0x00100000008, 'Backspace'); }
    static get delete() { return LogicalKeyboardKey.__byId(0x0010000007F, 'Delete'); }
    static get capsLock() { return LogicalKeyboardKey.__byId(0x00100000104, 'Caps Lock'); }
    static get arrowUp() { return LogicalKeyboardKey.__byId(0x00100000304, 'Arrow Up'); }
    static get arrowDown() { return LogicalKeyboardKey.__byId(0x00100000301, 'Arrow Down'); }
    static get arrowLeft() { return LogicalKeyboardKey.__byId(0x00100000302, 'Arrow Left'); }
    static get arrowRight() { return LogicalKeyboardKey.__byId(0x00100000303, 'Arrow Right'); }
    static get home() { return LogicalKeyboardKey.__byId(0x00100000306, 'Home'); }
    static get end() { return LogicalKeyboardKey.__byId(0x00100000305, 'End'); }
    static get pageUp() { return LogicalKeyboardKey.__byId(0x00100000308, 'Page Up'); }
    static get pageDown() { return LogicalKeyboardKey.__byId(0x00100000307, 'Page Down'); }
    static get controlLeft() { return LogicalKeyboardKey.__byId(0x00200000100, 'Control Left'); }
    static get controlRight() { return LogicalKeyboardKey.__byId(0x00200000101, 'Control Right'); }
    static get shiftLeft() { return LogicalKeyboardKey.__byId(0x00200000102, 'Shift Left'); }
    static get shiftRight() { return LogicalKeyboardKey.__byId(0x00200000103, 'Shift Right'); }
    static get altLeft() { return LogicalKeyboardKey.__byId(0x00200000104, 'Alt Left'); }
    static get altRight() { return LogicalKeyboardKey.__byId(0x00200000105, 'Alt Right'); }
    static get metaLeft() { return LogicalKeyboardKey.__byId(0x00200000106, 'Meta Left'); }
    static get metaRight() { return LogicalKeyboardKey.__byId(0x00200000107, 'Meta Right'); }
    // 数字与字母键：logical keyId 就是字符码（digit0 = 0x30，keyA = 0x61），
    // keyLabel 与 Flutter 一致（数字本身 / 大写字母）。
    static get digit0() { return LogicalKeyboardKey.__byId(0x30, '0'); }
    static get digit1() { return LogicalKeyboardKey.__byId(0x31, '1'); }
    static get digit2() { return LogicalKeyboardKey.__byId(0x32, '2'); }
    static get digit3() { return LogicalKeyboardKey.__byId(0x33, '3'); }
    static get digit4() { return LogicalKeyboardKey.__byId(0x34, '4'); }
    static get digit5() { return LogicalKeyboardKey.__byId(0x35, '5'); }
    static get digit6() { return LogicalKeyboardKey.__byId(0x36, '6'); }
    static get digit7() { return LogicalKeyboardKey.__byId(0x37, '7'); }
    static get digit8() { return LogicalKeyboardKey.__byId(0x38, '8'); }
    static get digit9() { return LogicalKeyboardKey.__byId(0x39, '9'); }
    static get keyA() { return LogicalKeyboardKey.__byId(0x61, 'A'); }
    static get keyB() { return LogicalKeyboardKey.__byId(0x62, 'B'); }
    static get keyC() { return LogicalKeyboardKey.__byId(0x63, 'C'); }
    static get keyD() { return LogicalKeyboardKey.__byId(0x64, 'D'); }
    static get keyE() { return LogicalKeyboardKey.__byId(0x65, 'E'); }
    static get keyF() { return LogicalKeyboardKey.__byId(0x66, 'F'); }
    static get keyG() { return LogicalKeyboardKey.__byId(0x67, 'G'); }
    static get keyH() { return LogicalKeyboardKey.__byId(0x68, 'H'); }
    static get keyI() { return LogicalKeyboardKey.__byId(0x69, 'I'); }
    static get keyJ() { return LogicalKeyboardKey.__byId(0x6A, 'J'); }
    static get keyK() { return LogicalKeyboardKey.__byId(0x6B, 'K'); }
    static get keyL() { return LogicalKeyboardKey.__byId(0x6C, 'L'); }
    static get keyM() { return LogicalKeyboardKey.__byId(0x6D, 'M'); }
    static get keyN() { return LogicalKeyboardKey.__byId(0x6E, 'N'); }
    static get keyO() { return LogicalKeyboardKey.__byId(0x6F, 'O'); }
    static get keyP() { return LogicalKeyboardKey.__byId(0x70, 'P'); }
    static get keyQ() { return LogicalKeyboardKey.__byId(0x71, 'Q'); }
    static get keyR() { return LogicalKeyboardKey.__byId(0x72, 'R'); }
    static get keyS() { return LogicalKeyboardKey.__byId(0x73, 'S'); }
    static get keyT() { return LogicalKeyboardKey.__byId(0x74, 'T'); }
    static get keyU() { return LogicalKeyboardKey.__byId(0x75, 'U'); }
    static get keyV() { return LogicalKeyboardKey.__byId(0x76, 'V'); }
    static get keyW() { return LogicalKeyboardKey.__byId(0x77, 'W'); }
    static get keyX() { return LogicalKeyboardKey.__byId(0x78, 'X'); }
    static get keyY() { return LogicalKeyboardKey.__byId(0x79, 'Y'); }
    static get keyZ() { return LogicalKeyboardKey.__byId(0x7A, 'Z'); }
  }
  // keyId → 实例表（类字段外置，避免求值期用类自身引用做初始化）。
  LogicalKeyboardKey.__instances = {};

  // PhysicalKeyboardKey：`event.physicalKey.usbHidUsage` 按 usb 码归一。
  export class PhysicalKeyboardKey {
    constructor(props) {
      props = props || {};
      this.usbHidUsage = props.usbHidUsage;
      this.debugName = props.debugName || '';
    }
    static __byUsb(usb, label) {
      var keys = PhysicalKeyboardKey.__keys;
      var k = keys[usb];
      if (!k) {
        k = new PhysicalKeyboardKey({ usbHidUsage: usb, debugName: label });
        keys[usb] = k;
      }
      return k;
    }
  }
  PhysicalKeyboardKey.__keys = {};

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

  // 按键事件子类：Dart 侧各自是 KeyEvent 的子类，JS 侧原生 extends（这样
  // `instanceof KeyDownEvent` 与 `instanceof KeyEvent` 同时成立）。
  export class KeyDownEvent extends KeyEvent {
    constructor(props) { super(props); }
  }
  export class KeyUpEvent extends KeyEvent {
    constructor(props) { super(props); }
  }
  export class KeyRepeatEvent extends KeyEvent {
    constructor(props) { super(props); }
  }

  // 宿主回传的 kind → 子类（与 keyboard_listener_bridge.dart 的 `_keyEventJson`
  // 三个取值一一对应）。子类已在本文件前文定义，故用赋值而非静态字段（避免
  // 类求值期的 TDZ）。
  KeyEvent.__subclasses = {
    down: KeyDownEvent,
    repeat: KeyRepeatEvent,
    up: KeyUpEvent
  };

  // 宿主桥接见 capabilities/keyboard_listener/keyboard_listener_bridge.dart：
  // 原生 KeyEvent → JSON（kind / character / keyId / keyLabel / usbHidUsage /
  // timeStamp），这里还原成实例并调事件句柄。挂 G：宿主经 evaluate 裸引用调用。
  G.__keyEvent = function (handleId, eventJson) {
    var f = handleObjectOf(handleId);
    if (typeof f !== 'function') { return; }
    var m = {};
    try { m = JSON.parse(eventJson) || {}; } catch (e) { return; }
    var Ctor = KeyEvent.__subclasses[m.kind] || KeyEvent;
    f(new Ctor({
      character: m.character,
      logicalKey: LogicalKeyboardKey.__byId(m.logicalKeyId, m.logicalKeyLabel),
      physicalKey: PhysicalKeyboardKey.__byUsb(m.physicalKeyUsb, m.physicalKeyLabel),
      timeStamp: new Duration({ microseconds: m.timeStampUs || 0 })
    }));
  };
''';
