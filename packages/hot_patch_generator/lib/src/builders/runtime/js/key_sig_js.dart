// ---------------------------------------------------------------------------
// Key 签名（reconciler 的 key 比较入口）
//
// 属于**运行时核心**：`patchChildren` 直接调用 `keySig`，必须在 runtime.js 里
// 可用（产物模块（flutter.js）里的 Key 类只负责承载值，签名判据在核心）。
//
// 判据用**结构**（`__vkey` / `__psk` / `__okey` / `__id`）而非 instanceof：
// key 可能经父级 props 透传，形态必须与宿主侧 key_bridge 的解析一致。
// 值类区（flutter.js）的 ValueKey / ObjectKey 构造时通过 `G.objectToken` 取
// 身份 token，与这里共用同一 WeakMap。
// ---------------------------------------------------------------------------

const String keySigJsSource = r'''
  // ObjectKey / ValueKey(对象值) 的身份 token：对象走 WeakMap（不阻止回收），
  // 原始值没有身份，退化为值 string。
  var okeySeq = 0;
  var okeyIdx = new WeakMap();
  function objectToken(v) {
    if (v === null || (typeof v !== 'object' && typeof v !== 'function')) {
      return 'p:' + String(v);
    }
    var t = okeyIdx.get(v);
    if (t == null) { okeySeq += 1; t = 'i:' + okeySeq; okeyIdx.set(v, t); }
    return t;
  }

  // 值 → 签名片段（原始值按「类型 + 值」，对象按身份）。
  function keyValueSig(v) {
    if (v === null || (typeof v !== 'object' && typeof v !== 'function')) {
      return typeof v + ':' + String(v);
    }
    return 'i:' + objectToken(v);
  }

  // key → 可比较签名；null / undefined（无 key）返回 null。
  // 形态判据用**自有字段**（`__vkey` / `__okey`）：ValueKey 的值本身可以是
  // null/undefined，故只能判「有没有这个字段」，不能判它的值。
  function keySig(k) {
    if (k == null) { return null; }
    if (Object.prototype.hasOwnProperty.call(k, '__vkey')) { return 'v:' + keyValueSig(k.__vkey); }
    // PageStorageKey：同值也与 ValueKey 不等（`p:` 前缀），对象值同 ValueKey 走 token。
    if (Object.prototype.hasOwnProperty.call(k, '__psk')) {
      var pv = k.__psk;
      if (pv !== null && typeof pv === 'object' &&
          Object.prototype.hasOwnProperty.call(pv, '__vtok')) {
        return 'p:' + pv.__vtok;
      }
      return 'p:' + keyValueSig(pv);
    }
    if (Object.prototype.hasOwnProperty.call(k, '__okey')) { return 'o:' + k.__okey; }
    var hid = k.__id != null ? k.__id : k.__handle;
    if (hid != null) { return 'h:' + hid; }
    // 兜底：认不出的 key 对象按**引用身份**区分。绝不能 `String(k)` ——
    // 所有对象都会拼成 "[object Object]" 而互相撞车，导致不同 key 复用同一
    // 结点（`x:` 前缀保留，表明这是兜底签名）。
    return 'x:' + objectToken(k);
  }

  G.objectToken = objectToken;
''';
