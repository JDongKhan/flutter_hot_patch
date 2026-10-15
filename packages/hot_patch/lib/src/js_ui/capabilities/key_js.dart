// 由 runtime_source.dart 拆出的 Key 代理类 JS 片段（能力内聚，见 capabilities/ 设计规范）。
//
// Key 与 Controller 不同：它是**值**（元素 props 里的 `key`），不是结点，也不
// 绑定到某个宿主 widget。生成器把 Dart 侧 `key: ValueKey(item)` / `key: _formKey`
// 翻译成 `props.key = new ValueKey(item)` / `this._formKey`；reconciler 只按
// **签名**比较（见 patchChildren 的 keySig），宿主按序列化形态还原真实 Flutter
// Key（见 capabilities/key_bridge.dart）。
//
// 五类语义（与 Flutter 对齐）：
//   - ValueKey ：按**值**相等。纯值 codec、不登记句柄；跨桥 `{__vkey:value}`，
//     值本身是对象时退化为 `{__vtok:token}`（对象无跨语言同一性）；宿主现造
//     ValueKey（Flutter 的 ValueKey 相等即值相等，无需映射表——否则每次 build
//     新实例会让表无限增长）。签名：原始值 `v:<typeof>:<值>`，对象按身份。
//   - PageStorageKey：值相等，但宿主造**真实** PageStorageKey（滚动位置持久化
//     是宿主端行为）。codec 与 ValueKey 同构、另加 `__psk` 标记；签名前缀 `p:`，
//     故同值的 ValueKey 与 PageStorageKey 不等（对齐 Dart 的 runtimeType 相等）。
//   - ObjectKey：按**被包裹对象的身份**相等（Dart `identical(value, other.value)`）。
//     身份 token 由 WeakMap + 序号给出（原始值没有身份，退化为值 string）；
//     跨桥 `{__okey:token}`——跨语言保持不了对象同一性，用 token 等价复现
//     （同一对象恒等、不同对象不等）。
//   - GlobalKey / UniqueKey：登记为**句柄**（kind=key/Global、key/Unique），宿主侧
//     持真实 GlobalKey() / UniqueKey()，按句柄 id 复用同一实例（GlobalKey 身份
//     跨帧稳定；页面退出随句柄释放）。跨桥 `{__handle:id}`，签名 `h:<id>`。
//
// keySig 是 reconciler 唯一的 key 比较入口：把 key 归一成可比较字符串（null =
// 无 key），patchChildren 据此做「带 key 优先按 key、无 key 按位置」匹配。
// 判据用**结构**（__vkey / __okey / __id）而非 instanceof——key 可能来自父级
// props 透传，形态必须与宿主侧 key_bridge 的解析保持一致。
const String keyJsSource = r'''
  // ===== 【10.6】Key 代理类（ValueKey / ObjectKey / UniqueKey / GlobalKey）===
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

  // ValueKey：按值相等，纯值 codec（不登记句柄）。
  // 实例的**自有字段名 = 序列化字段名**（__vkey）：reconciler 的 keySig 用字段
  // 形态判据，而 props.key 传的是 live 实例（不是 toJSON 产物），两边必须同形。
  // 对象值跨语言保不住同一性，序列化退化为身份 token（与 keyValueSig 同源）。
  function ValueKey(value) { this.__vkey = value; }
  ValueKey.prototype.toJSON = function () {
    var v = this.__vkey;
    if (v !== null && (typeof v === 'object' || typeof v === 'function')) {
      return { __vtok: objectToken(v) };
    }
    return { __vkey: v };
  };

  // ObjectKey：按被包裹对象的身份相等（只留身份 token，不再持有对象引用）。
  function ObjectKey(value) { this.__okey = objectToken(value); }
  ObjectKey.prototype.toJSON = function () { return { __okey: this.__okey }; };

  // PageStorageKey：Dart 侧 `extends ValueKey`（按**值**相等），但宿主必须造
  // **真实** PageStorageKey——它的意义是滚动位置按 key 存进 PageStorage bucket，
  // 那是宿主端行为（JS 侧只有一个值本体）。故 codec 与 ValueKey 同构另加 `__psk`
  // 标记：宿主据此造 PageStorageKey 而非 ValueKey，keySig 前缀 `p:` 使它与
  // 同值的 ValueKey 不等（与 Dart 的 runtimeType 参与相等一致）。
  function PageStorageKey(value) {
    this.__psk = (value !== null && (typeof value === 'object' || typeof value === 'function'))
        ? { __vtok: objectToken(value) }
        : value;
  }
  PageStorageKey.prototype.toJSON = function () { return { __psk: this.__psk }; };

  // GlobalKey / UniqueKey：登记为句柄（scope=page，随页面回收），宿主持真实实例。
  defineHandleKind('key/Global', {});
  function GlobalKey(debugLabel) {
    this.__id = reg(this, 'key/Global', {
      meta: debugLabel == null ? null : { debugLabel: debugLabel }
    });
  }
  GlobalKey.prototype.toJSON = function () { return { __handle: this.__id }; };

  // GlobalKey.currentContext / findRenderObject()：BuildContext 与 RenderObject 是
  // **宿主端**概念——JS 侧既没有真实对象，也没有同步取值的能力（JS→宿主只有异步
  // 桥，见 handleOp）。故 currentContext 返回一个只携带 key 句柄 id 的代理，链式
  // 调用在 JS 侧是空壳，最后一次调用经通用 op 落到宿主，由宿主用**真实**对象把
  // Flutter 原生语义补全——位置/尺寸只在真正算得出来的一端计算。
  //   - showOnScreen()：void 语义，fire-and-forget，宿主算出该结点位置并滚动；
  //   - measure()：Flutter 的 `box.size` / `box.localToGlobal(Offset.zero)` 是
  //     **同步属性**，而 JS→宿主只能异步，故这里返回 Promise（单源侧 `await`
  //     后即为真实值，见 widget_details 的 _measureFixed）。
  function KeyRef(id) { this.__key = id; }
  KeyRef.prototype.findRenderObject = function () { return new KeyRef(this.__key); };
  KeyRef.prototype.showOnScreen = function () {
    if (this.__key != null) { handleOp(this.__key, 'showOnScreen', {}); }
  };
  KeyRef.prototype.measure = function () {
    if (this.__key == null) { return Promise.resolve(null); }
    return handleOp(this.__key, 'measure', {});
  };
  Object.defineProperty(GlobalKey.prototype, 'currentContext', {
    get: function () { return this.__id == null ? null : new KeyRef(this.__id); }
  });

  defineHandleKind('key/Unique', {});
  function UniqueKey() {
    this.__id = reg(this, 'key/Unique', {});
  }
  UniqueKey.prototype.toJSON = function () { return { __handle: this.__id }; };

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
    return 'x:' + String(k);
  }

  G.ValueKey = ValueKey;
  G.ObjectKey = ObjectKey;
  G.PageStorageKey = PageStorageKey;
  G.UniqueKey = UniqueKey;
  G.GlobalKey = GlobalKey;
''';
