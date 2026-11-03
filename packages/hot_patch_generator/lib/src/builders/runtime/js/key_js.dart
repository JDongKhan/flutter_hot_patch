// 由 runtime_js.dart 拆出的 Key 代理类 JS 片段（能力内聚，见 capabilities/ 设计规范）。
//
// Key 与 Controller 不同：它是**值**（元素 props 里的 `key`），不是结点，也不
// 绑定到某个宿主 widget。生成器把 Dart 侧 `key: ValueKey(item)` / `key: _formKey`
// 翻译成 `props.key = new ValueKey(item)` / `this._formKey`；reconciler 只按
// **签名**比较（见 __patchChildren 的 __keySig），宿主按序列化形态还原真实 Flutter
// Key（见 capabilities/key/key_bridge.dart）。
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
// __keySig 是 reconciler 唯一的 key 比较入口：把 key 归一成可比较字符串（null =
// 无 key），__patchChildren 据此做「带 key 优先按 key、无 key 按位置」匹配。
// 判据用**结构**（__vkey / __okey / __id）而非 instanceof——key 可能来自父级
// props 透传，形态必须与宿主侧 key_bridge 的解析保持一致。
const String keyJsSource = r'''
  // __objectToken / __keyValueSig / __keySig 属于**运行时核心**（key_sig_js.dart，随
  // runtime.js 先加载）：identity WeakMap 由核心与这里的 Key 类共用。
  // __objectToken 由本模块头部从 G.__core 解构。

  // ValueKey：按值相等，纯值 codec（不登记句柄）。
  // 实例的**自有字段名 = 序列化字段名**（__vkey）：reconciler 的 __keySig 用字段
  // 形态判据，而 props.key 传的是 live 实例（不是 toJSON 产物），两边必须同形。
  // 对象值跨语言保不住同一性，序列化退化为身份 token（与 __keyValueSig 同源）。
  export class ValueKey {
    constructor(props) { this.__vkey = __positionalArgs(props, ['value']).value; }
    toJSON() {
    var v = this.__vkey;
    if (v !== null && (typeof v === 'object' || typeof v === 'function')) {
  return { __vtok: __objectToken(v) };
    }
    return { __vkey: v };
    }
  }

  // ObjectKey：按被包裹对象的身份相等（只留身份 token，不再持有对象引用）。
  export class ObjectKey {
    constructor(props) { this.__okey = __objectToken(__positionalArgs(props, ['value']).value); }
    toJSON() {
    return { __okey: this.__okey };
    }
  }

  // PageStorageKey：Dart 侧 `extends ValueKey`（按**值**相等），但宿主必须造
  // **真实** PageStorageKey——它的意义是滚动位置按 key 存进 PageStorage bucket，
  // 那是宿主端行为（JS 侧只有一个值本体）。故 codec 与 ValueKey 同构另加 `__psk`
  // 标记：宿主据此造 PageStorageKey 而非 ValueKey，__keySig 前缀 `p:` 使它与
  // 同值的 ValueKey 不等（与 Dart 的 runtimeType 参与相等一致）。
  export class PageStorageKey {
    constructor(props) {
      var value = __positionalArgs(props, ['value']).value;
      this.__psk = (value !== null && (typeof value === 'object' || typeof value === 'function'))
          ? { __vtok: __objectToken(value) }
          : value;
    }
    toJSON() {
    return { __psk: this.__psk };
    }
  }

  // GlobalKey / UniqueKey：登记为句柄（scope=page，随页面回收），宿主持真实实例。
  export class GlobalKey {
    constructor(props) {
      var debugLabel = __positionalArgs(props, ['debugLabel']).debugLabel;
      // 泛型实参由产物下发（`new GlobalKey({typeArguments: ['AnimatedListState']})`）：
      // Dart 的 `GlobalKey<T>` 在 AOT 是 reified 的，T 就是「currentState 的类型」，
      // 取值不需要问宿主、也不靠 runtimeType 猜。
      var ta = (props && props.typeArguments) || [];
      this.__stateType = ta.length ? ta[0] : null;
      this.__id = __registerHandle(this, 'key/Global', {
        meta: debugLabel == null ? null : { debugLabel: debugLabel }
      });
    }
    toJSON() {
    return { __handle: this.__id };
    }
    get currentContext() {
      // 只有**挂载期间**非空（与 Flutter 一致）：挂在哪个结点上由 reconciler 在
      // mount 时经 [__attachContext] 绑定，卸载时经 [__detachContext] 按身份摘除。
      return this.__ctx == null ? null : this.__ctx;
    }
    // 上下文绑定的通用协议（reconciler 只认方法、不认类型，见 mini-react 的
    // __attachKeyContext / __detachKeyContext）。GlobalKey 本身不认识
    // BuildContext 的实现，只持有代理引用。
    __attachContext(ctx) { this.__ctx = ctx; }
    __detachContext(ctx) {
      // 按身份摘除：同一个 GlobalKey 可能已被后来的结点重新挂上
      // （元素换位 / 旧结点卸载晚于新结点挂载），此时不能清掉新绑定。
      if (this.__ctx === ctx) { this.__ctx = null; }
    }
    get currentState() {
      if (this.__id == null) { return null; }
      // 首选泛型实参（`GlobalKey<AnimatedListState>` 的 T）；未声明泛型时才问
      // 宿主 runtimeType。两者都没有则退化为通用句柄（调用时宿主会告警）。
      var type = this.__stateType || __handleOp(this.__id, '__type', {});
      return StateHandle.of(this.__id, type);
    }
  }

  // GlobalKey.currentContext / findRenderObject()：BuildContext 与 RenderObject 是
  // **宿主端**概念——JS 侧既没有真实对象，也没有同步取值的能力（JS→宿主只有异步
  // 桥，见 __handleOp）。故 currentContext 返回**运行时同一份** JsBuildContext
  // （runtime.js 定义、经 G.__core 交接），由 reconciler 在挂载该 key 所在结点时
  // 绑定到 GlobalKey；findRenderObject() 再返回同 id 的 RenderObject 代理：链式
  // 调用在 JS 侧是空壳，最后一次调用经通用 op 落到宿主，由宿主用**真实**对象把
  // Flutter 原生语义补全——位置/尺寸只在真正算得出来的一端计算。
  //   - showOnScreen()：void 语义，fire-and-forget，宿主算出该结点位置并滚动；
  //   - measure()：Flutter 的 `box.size` / `box.localToGlobal(Offset.zero)` 是
  //     **同步属性**，而 JS→宿主只能异步，故这里返回 Promise（单源侧 `await`
  //     后即为真实值，见 sliver_detail 的 _measureFixed）。
  //
  // findRenderObject 补在 JsBuildContext 原型上（与 provider 在 provider.js 补
  // watch/read 同一范式）：类定义在 runtime.js、RenderObject 是本模块的值类，故由
  // 本模块补。句柄来源决定 op 落点——GlobalKey 上下文沿 key 句柄走 key 桥，组件
  // 上下文按 ctx 句柄走 BuildContext 桥。`x is RenderObject` 在 JS 侧即
  // `instanceof RenderObject`（本类是 flutter.js 的导出，由 runtime_global_types
  // 自动抽取并为产物补 import）。
  JsBuildContext.prototype.findRenderObject = function () {
    if (this.__id == null && this.__nodeId == null) { return null; }
    return new RenderObject(this.__handle());
  };

  export class RenderObject {
    constructor(id) { this.__key = id; }
    showOnScreen() {
    if (this.__key != null) { __handleOp(this.__key, 'showOnScreen', {}); }
    }
    measure() {
    if (this.__key == null) { return Promise.resolve(null); }
    return __handleOp(this.__key, 'measure', {});
    }
  }

  // GlobalKey.currentState：StateHandle 与本文件同属 flutter.js 的值类区
  // （state_handle_js.dart 在结点辅助区之后、各类包装之前写出），这里只补
  // `currentState` getter。运行时**不认识任何业务方法**：代理类由生成器随组件
  // 写进 flutter.js，并用 `StateHandle.registerProxy(type, class)` 登记；类型来自
  // GlobalKey<T> 的泛型实参。

  // UniqueKey：句柄即身份（无本端资源需要清理）。
  export class UniqueKey {
    constructor() {
      this.__id = __registerHandle(this, 'key/Unique', {});
    }
    toJSON() {
    return { __handle: this.__id };
    }
  }


''';
