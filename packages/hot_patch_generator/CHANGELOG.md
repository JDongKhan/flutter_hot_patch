## 0.8.1

**协议次版本：契约不变，空安全产物形态改为 JS 原生可选链；旧的三元 / IIFE 展开同次删除，不保留兼容。**

- 空安全属性访问 / 下标 / 方法调用改为与 Dart 源码同形：`a?.b` → `a?.b`、`a?[i]` → `a?.[i]`、`a?.m(args)` → `a?.m(args)`（`shared/js_translator.dart` 里三处旧展开删除）。接收者只求值一次、null / undefined 时整链短路，实参 / 下标不求值——链式 `a?.b?.c` 不再逐层展开三元（旧写法在链上会重复求值接收者，且 `a?.b.c` 在 `a` 为 null 时丢短路、直接 TypeError）。
- 空安全赋值 `a?[i] = v` / `a?.b = v`（JS 可选链不能作赋值目标）落成接收者单次求值的守卫 `((__t) => { if (__t != null) __t[i] = v; })(a)`；普通下标赋值 `a[i] = v` 同分支支持。接收者为空时下标与右值均不执行。
- 引擎基线：产物开始依赖 ES2020 可选链（此前已使用 `??`，同一代引擎能力）；`docs/组件支持文档.md` §7.1 与 §6.14 同步更新（iOS 口径 15+）。
- 示例：`BannerCarousel._stopAutoPlay` 删除「先取本地引用再判空」的旧绕行写法，恢复 `_timer?.cancel()`。

## 0.8.0

**破坏性：JS 侧新增原生 InheritedWidget 语义；provider 去掉宿主结点与宿主 context op（旧 `__provides` / `__registerScope` / `__scopeOfContext` 协议与 provider 宿主映射同次删除，不保留兼容）。需与 hot_patch 0.4.0 配套。**

- **InheritedWidget（纯 JS）**：`flutter.js` 新增 `export class InheritedWidget extends Component`（build 返回 `props.child`，`updateShouldNotify(oldWidget)` 与 Flutter 同义）。翻译层把 `InheritedWidget` 加入 SDK 基类表与组件判据，用户子类按常规组件翻译、零宿主注册。
- **运行时继承机制（Flutter 命名）**：结点用 `__inheritedElements`（类型名 → 提供者结点，对应 `Element._inheritedElements`）登记；`__getInheritedElement` / `__dependents` / `__dependencies` / `__notifyClients` 与 `InheritedElement` 的依赖与通知语义一致。`JsBuildContext` 新增 `getInheritedWidgetOfExactType` / `dependOnInheritedWidgetOfExactType`，类型实参沿用 `typeArguments` 元信息。
- **宿主包装类判据修正**：由「原型上是否有自己的 build」改为 Component 构造写入的 `__host`（相对 `Component.prototype.build` 是否重写），继承基类 build 的组件（InheritedWidget 子类）不再被误判为宿主包装类。
- **provider 纯 JS 化**：`ChangeNotifierProvider` 直接返回 child 并在自身结点登记类型键作用域；`Consumer` 直接返回 builder 子树；`context.watch/read` 不再向宿主发 op，取值与订阅全部在 JS 内闭环。
- **删除宿主侧 provider 映射**：`provider_bridge.dart` / `context_ops.dart` 与 `__registerScope` / `__publishScope` 宿主作用域发布机制整体移除；`ChangeNotifier` 宿主镜像保留给 ListenableBuilder 系列。
- **新增示例**：`InheritedCard`（祖先数据共享 + `updateShouldNotify` 精确重建依赖者）。

## 0.7.0

**破坏性：泛型元信息由数组改为 Map（key = 声明侧类型参数名）；新增「类型参数在方法体里可用」的翻译规则（`T == String` / `as T`）。**

- `typeArguments` 形态改为 `{T: 'CounterVm', K: 'String', V: 'int'}`：key 取自类 / 方法的源码声明（`class Pair<K, V>` / `m<T>`），查不到声明时退化为位置序号键。多泛型不再依赖位置顺序，消费方按 key 或 `Object.values(...)[0]` 取。
- 实例保存元信息：泛型类构造把 `typeArguments` 存到内部字段 `__ta`（无参构造 / `__applyProps` 两条路径都覆盖）。
- 方法体里的类型参数：`T` → `this.__ta["T"]`；`T == String` / `!=` 进入「类型值比较」分支，另一侧类型名转字符串（`String` → `"String"`）；`as T` 擦除（类型断言在 JS 侧无运行时语义）。
- 消费方同步：`GlobalKey<T>` 与 provider 的 `watch/read`、作用域登记改取 Map 的第一个值（与 key 写法无关）。
- key 来源：构造按类声明，静态方法按方法声明；调用点定位不到接收者类型时按**方法名**查源码里的泛型方法声明（多个候选时优先 `extension`，仍歧义才退化为位置序号），因此 `context.watch<T>()` / `context.read<T>()` 都是 `{"T": …}`。
- 方法级泛型可用：泛型方法定义侧追加隐藏形参 `__ta` 接收调用尾参对象，方法体里的类型参数（如 `E.toString()`）译成 `((__ta && __ta.typeArguments) || {})["E"]`；`obj.getEType<String>()` 产出 `getEType({typeArguments: {"E": "String"}})`。

## 0.6.0

**只做加法：新增 `flutter.js` 的 `Future` 同名镜像；删除翻译层 `Future.delayed` → Promise 的特判（替换即删除，旧路径不存在）。**

- **翻译层回归一比一**：`await Future.delayed(const Duration(seconds: 1))` 不再被反向映射成 `new Promise(function(r){ setTimeout(r, 1000); })`。`await` 的内层表达式按普通表达式翻译，`Future.delayed` 与其它构造 / 静态调用同一条规则——`Future.delayed({duration: new Duration({seconds: 1})})`（`shared/js_translator.dart` 的 `_awaitInnerJs` / `delayedMsJs` 同次删除）。
- **新增 `export class Future`**（`builders/runtime/js/future_js.dart`，随 `flutter.js` 发布）：构造与 `delayed` / `value` / `error` / `sync` / `microtask` / `wait` / `any`，实例 `then` / `catchError` / `whenComplete`；内部持有一个原生 Promise，`await` / thenable 语义与 Dart 一致（`Future(...)` 异步启动、`Future.sync` 同步启动）。
- **import 自动可见**：`export class` 由导出名自动抽取，产物按实际出现的名字 `import { Future } from '../flutter.js'`，无需登记。
- **宿主通道不变**：`_app_host_.invoke` 仍返回原生 Promise，JS 侧可直接 `await`，与 `Future` 互操作（`then` 兼容 `await` 传入的裸回调与具名实参尾对象）。

## 0.5.0

**破坏性：泛型实参协议统一为 `typeArguments`，删除 `props.model` 与泛型方法的「位置参数」形态（不保留兼容）。**

- **一条规则**：源码里显式写的 `<T,...>` 一律产出 `typeArguments: ['T1', ...]`（按位置顺序、保留源码文本），作为元信息随**构造 props**（值构造与组件结点）或**调用尾参对象**（泛型方法，与具名实参合并）下发。类型实参不再占位置参数。
- **删除语义化键名**：组件结点的 `props.model`（只取第一个类型实参）删除；`Consumer` / `ChangeNotifierProvider` 与 provider 作用域登记改读 `props.typeArguments`。多类型实参（如 `Pair<K, V>`、`Consumer2<A, B>`）不再丢失。
- **删除 provider 专属特判**：`context.watch<T>()` / `context.read<T>()` 不再由翻译层按 `receiver == context` + 方法名特判，统一走泛型方法调用规则（`watch({typeArguments: ['T']})`）；provider.js 的 `watch/read` 改读尾参对象。
- **擦除边界**：泛型方法有位置实参且无具名实参时，尾对象会被目标当成位置实参（如原生 `Array.reduce<T>` 的 initialValue），故擦除元信息并输出构建期告警，与 dart2js 的擦除行为一致。
- **`firstTypeArgOf` 删除**：组件结点与值构造共用唯一解析 `typeArgsOf`。

## 0.4.0

**破坏性：宿主入口 `__jsui.mount` 更名为 `__jsui.mountRoot`（需与 hot_patch 0.3.4 配套；不保留旧别名）。**

- 内部函数一直是 `__mountRoot`（挂载整个页面根），与 reconciler 的 `__mount`（挂载单个结点）区分；此前对外 api 键写成 `mount`，日志与调用链里容易混淆。现统一为 `__jsui.mountRoot(...)`，宿主 `JsUiWidget` 挂载点同步更新。

## 0.3.9

**InputDecoration / BottomNavigationBarItem / DropdownMenuItem 改为值类，删除「数据载体类型表」（协议只做加法：props 里新增 `{type, props, children, element: true}` 元素描述形态，老产物行为不变；需与 hot_patch 0.3.3 配套）。**

- **值对象不再当宿主元素**：这三类不再生成 `extends Component` 的宿主包装类，改为 `flutter.js` 值类区的普通类（构造镜像 Dart 字段 + `toJSON`）——构造即值，留在父级 props，不再进 reconciler 树。
- **新增通用元素描述通道**：运行时新增 `__descriptorOf`（`__element` 元素 → `{type, props, children, element: true}`，数组 / delegate 列表递归，JS 组件、builder 槽与回调值明确告警并丢弃）；值类 `toJSON` 复用它；宿主 renderer 直接读字段 JSON，再用 `c.element(...)` 就地还原成 Flutter widget（无 patch/diff）。
- **删除类型表**：`_dataCarrierTypes` 与 `registerJsDataCarrierType` / `isJsDataCarrierType` 一并删除，生成器 `host_types.dart` 不再扫描数据载体；`hostWrapperTypes` 只剩宿主 widget。三项独立宿主 renderer（`BottomNavigationBarItem` / `DropdownMenuItem`）与 `_JsBottomNavItem` 同步删除。

## 0.3.8

**JS 运行时整理（纯内部重构：`patch/runtime.js` 与 `patch/flutter.js` 同步重出即可，宿主通道与补丁协议字段不变）。**

- **内部符号统一 `__` 前缀**：`emitOp` / `commitOps` / `mount` / `patch` / `unmount` / `registerHandle` / `handleOp` / `markDirty` / `pullComponent` / `scopeOf` / `nodeIdOf` / `keySig` / `objectToken` 等只在框架内使用的函数与状态表（`roots` / `handles` / `hostNodes` …）全部改名，开发者可据此一眼分辨「框架内部」与「对外契约」。
- **日志统一走宿主通道**：删除 runtime.js / flutter.js 中全部 `console.*`，内部诊断改走 `__logText`（warn / error 级别，经 `_app_host_.invoke('log')` 进 `HotPatchLog`）；缓存追踪切面改用 `debugPrint`，release 下零跨桥。
- **合并重复设计**：新增 `__openRoot` / `__closeRoot` 统一「页面根 / 弹层独立根」的建树与卸载事务，`mountRoot` / `disposeRoot` / `Panel.mount` / `Panel.closed` 收敛为薄封装；新增 `__withBuilding` / `__callLifecycle` 收敛 6 处构建锚点与卸载生命周期样板；`ListenableBuilder` / `ValueListenableBuilder` / `AnimatedBuilder` / `TweenAnimationBuilder` 共用 `__ListenableSubscriber`；逻辑组件的 props 摘除统一走 `Component.__propsExcept`。
- **`Component` 内聚**：`__splitHost` 从模块级函数收进 `Component` 静态成员；空无参构造从宿主包装类与逻辑组件中删除（继承默认构造即等价）。
- **删除无用/兼容逻辑**：移除 `newRoot`、`releaseHandleFromHost`、`__isBuilderFn`、`__jsui.fn` / `__jsui.reg`（宿主未使用）、`keySig` 的 `__handle` 兜底，以及 flutter.js 模块级 `G.__str` / `G.objectToken` 单点交接（并入 `G.__core`）。
- **纯内部命名澄清**：`G.__scopeOf`（接收 BuildContext 代理）改名 `G.__scopeOfContext`，与核心 `__scopeOf(instance, type)` 区分；`JsBuildContext` 改回 ES class 写法。
- **翻译层不再判断「是不是回调」**：具名实参一律按**值的形态**字面翻译——闭包 → JS 箭头函数、`Colors.white` → `Colors.white`、方法 tear-off → 绑定 this 的闭包。`autoValue` 删除了「非 builder 闭包内联 body / 下发类引用」的旧分支（它把 `onPressed: () => _a.requestFocus()` 变成**立即调用**、把 `create: (_) => CounterVm()` 变成裸类名）；provider 的 `create` 现在就是普通工厂闭包，provider.js 改为调用 `p.create()`。
- **宿主边界统一生成句柄**：`mini-react` 新增 `__hostProps`，在宿主元素 props 下发前按 `typeof` 把**函数值**换成 `{__fn:id}`（信封只含 id，保证可 JSON 序列化）；句柄缓存在**宿主结点**上、按 prop 名索引——重建复用同一 id 只更新实现（props 不抖动）、兄弟 / 列表项各自独立（天然不串味）、结点卸载随结点释放。回调执行时用 `__core.anchor` 还原产出该元素的组件，`this.context` 与构造期句柄归属语义不变。
- **宿主类型携带函数形参名单**：生成器只为**有回调**的宿主包装类产出 `static __fnProps = [...]`（源码构造签名并集，含类型不可得的形参）；**未声明 = `undefined` = 本类型无回调**（零循环、不拷贝），签名查不到时声明为 `null`。运行时只查名单里的键，`null` / `Component.host` 的字符串类型回退全量扫描——避免为了找回调遍历大 props，同时不会漏掉动态 / 未标注的回调。
- **方法 tear-off 生成精确形参**：`onPressed: _insert` 之前一律产出 `(...__a) => this._insert(...__a)`；现按源码方法声明的位置形参个数生成 `() => this._insert()` / `(__a0) => this._onChanged(__a0)` / `(__a0, __a1) => this._onSelect(__a0, __a1)`，去掉无意义的 rest / spread（含具名形参的方法仍按 `...__a` 原样转发）。闭包字面量本来就按声明形参翻译，不受影响。
- **删除 `__bindFn`**：翻译层不再发射 `this.__bindFn(位点号, [捕获值], …)`，运行时的 `__bindFn` / `__captureKey` / `__boundFn` / 编译期位点号 / `__eventCaptures` / `eventHandle` 一并移除；逻辑组件（LayoutBuilder / SliverPersistentHeader / Draggable / DragTarget）直接下发普通函数，由宿主边界统一折算。
- **构造签名只用于「成员引用怎么渲染」**：`element_json` 仅判断具名形参是否声明为函数类型——函数位置上的 `a.b` 是方法 tear-off（包绑定闭包），普通值位置上是成员读取（原样引用，如 `Colors.white`）；不看属性名、不用 `on*` 约定。`CtorSignatures` 补齐 `super.x` 形参类型（`TextButton` / `ElevatedButton` 的 `required super.onPressed` 沿 `extends` 链取父类字段声明），修复这类构造里回调被当成普通值的问题。
- **JS 侧组件回调**（社区 / 订单列表 `this.onTap` / `this.onOpen is not a function`）：JS 组件 props 不再经过任何句柄化，回调**就是函数**；`functionJs` 在通用闭包翻译失败时回退事件闭包翻译但仍产出普通函数，绝不降级成句柄。


## 0.3.7

**`@HostInjected` 调用点回归一比一：类照常产出 JS，只有被标注方法的**方法体**换成通道调用（产物形态变化，需配套本版本生成器；通道协议与宿主注册不变）。**

- **删除调用点的通道改写**：`AccountCenter.getUserName(a)` / `Network.post(url: u, params: p)` 不再整体替换为 `_app_host_.invoke(...)`，产物保持 `类名.方法(...)`（`AppRouter.pop()` / `Network.post({...})`），事件表达式同理（`static` receiver 落成 `类名.方法(...)` 而非 `this.类名.方法(...)`）。
- **宿主注入类照常翻译**：类表 / 翻译范围 / 跨文件产物不再排除 `@HostInjected` 类；类在产物里只保留「类 + 被标注的 static 方法」，字段、其它方法、基类、依赖与 import 一概不产出（它们只服务宿主实现）。
- **方法体改为通道调用**：新增 `hostMethodBodyJs`，按方法形参结构从 `arguments` 重建载荷——纯位置 → `Array.prototype.slice.call(arguments)`（可选参数缺省不补 `undefined`，宿主默认值照旧生效）；纯具名 → 首个实参对象；混合 → 前 N 个实参 + 尾参对象展开（`{"@args": …}`）。
- **依赖扫描跳过方法体**：`dependenciesOf` 不再遍历 `@HostInjected` 方法的方法体，只有宿主实现里用到的类型不会被连带翻译（`new SearchPage(...)` 等页面依赖链在宿主方法体处断掉）。
- **顶层函数仍是唯一例外**：顶层函数没有可承载的 JS 类，调用点继续翻译为 `_app_host_.invoke(...)`（`buildHostFunctions` 只收集顶层函数名）。
- **删除旧通道表**：`ClassInfo.hostMethods` / `FieldScope.hostMethods` / `ElementTranslateContext.hostMethods` / `buildHostMethods` / `classHasHostInjectedMethod` 全部移除。
- **构建告警降噪（不改产物行为）**：带常量参数的 SDK 枚举（`KeyboardLockMode` / `CheckedState` / `Tristate` 等）不再在索引阶段逐条告警，改为**产物真的引用其成员时**才出声（`sdkUnsupportedEnums` + 翻译层一次性告警）；空事件闭包 `() {}` 视为合法空操作，不再误报「事件闭包块体为空」；字段类型判定先擦除 import 前缀（`ui.Image` → `Image`），不再误报「无法从本地源码解析」。

## 0.3.6

**日志调用回归一比一：`print` / `debugPrint` 原样翻译为同名全局函数（产物调用形态变化，需配套本版本 `runtime.js`；日志通道协议不变）。**

- **删除翻译层的日志特殊分支**：不再把 `print` → `console.log`、`debugPrint` → `console.debug`，改为按通用「运行时全局函数」分支一比一产出 `print(...)` / `debugPrint(...)`（含 `wrapWidth` 具名实参的统一信封）。
- **运行时【1】新增日志全局**：`G.print`（`info` 级）、`G.debugPrint`（`debug` 级），统一经 `_app_host_.invoke('log', …)` 进 `HotPatchLog`；release 下 `__log` 直接返回，零跨桥。
- **删除运行时对 `console` 的整套封装**（`G.console` 合并覆盖与级别映射、`__silentLog`）：运行时内部诊断改用引擎自带的 `console`（flutter_js 桥到本地打印）。
- **字符串插值不再借日志分支包 `__str`**：插值统一按 `+` 拼接；`__str` 只保留给值类（`StringBuffer` 等）使用。

## 0.3.5

**Canvas 能力新增文字与图片记录（只做加法：新增值类与 op，既有语法产物不变；使用 `TextPainter` / `drawImage*` 需 `hot_patch` ≥ 0.3.2）。**

- **`TextPainter`**（`canvas_js.dart`，插在 `Canvas` 与 `CustomPainter` 之间）：构造实参按原名保存；`layout(minWidth, maxWidth)` 兼容位置与尾参对象两种形态，`Infinity` 序列化为 null（宿主按 Dart 默认值 `minWidth 0` / `maxWidth infinity`）；`paint(canvas, offset)` 记录 `['drawText', span, offset, opts]`。`width` / `height` / `size` 需要同步测量，JS 侧访问即抛错（不返回假值）。
- **`Canvas.drawImage` / `Canvas.drawImageRect`**：由抛错桩改为记录（`image` 是宿主返回值里的图片句柄 `{__handle, width, height}`，null 时抛错）；`drawImageNine` / `drawAtlas` / `drawVertices` / `drawPoints` / `drawParagraph` 等仍抛错。
- **旋转由矩阵承接**：文字 / 图片的旋转沿用既有 `save` / `translate` / `rotate` 产物形态，不新增协议分支。
- **dart:core 值类补齐**（`dart_core_js.dart`，紧随基础值类之后）：新增 `DateTime` / `Match` / `RegExp` / `StringBuffer`，以及小写静态命名空间 `int` / `double` / `num`（`parse` / `tryParse` / `infinity` 等）。构造仍按唯一规则产出 `new X({...})`、静态调用 `int.parse(...)` 原样下发；翻译层只新增「小写导出名 → 命名空间」的通用解析分支（`runtime_global_types` 从 `export const <小写名> = {` 自动抽取），不维护类型白名单。

## 0.3.4

**新增 CustomPaint / CustomPainter 绘制支持（只做加法：新协议键与句柄 kind 均为新增，老产物行为不变，仍可与 `hot_patch` 0.3.0 搭配；使用 CustomPaint 需 `hot_patch` ≥ 0.3.1）。**

- **值类（`patch/flutter.js`）**：新增 `Rect` / `RRect` / `Path` / `Paint` / `Canvas` / `CustomPainter`（`builders/runtime/js/canvas_js.dart`，插在 Dart 值类之后、异常之前）。`Canvas` 是**录制型**：每次调用压入一条 `[方法名, …实参]`，`toJSON()` 产出 `{v:1, ops:[…]}`；`Rect → [l,t,r,b]`、`RRect → 12 项`、`Path → {ops}`、`Paint → 非空属性`。
- **`CustomPainter` 是值类 + 句柄**（kind `canvasPainter`，`sync:false`）：宿主不创建真实对象，只用 `__jsui.call(id, 'call', {method:'__record', args:[size]})` 同步取回录制结果。宿主侧重放与还原见 `hot_patch` 的 `capabilities/canvas/`。
- **`Gradient.createShader(rect)`**：下发 `{__gradient, rect}`，供 `Paint.shader` 跨桥还原。
- **SDK 基类表**新增 `CustomPainter`：`class X extends CustomPainter` 产物为 `extends CustomPainter` + `constructor(args){ super(args); }`。
- **私有依赖分类改为源码事实**：`component_builder` 不再用 `_` 前缀推断「是不是组件」，改为 `isWidgetClassDecl`（`extends StatefulWidget/StatelessWidget/State` 或 `@PatchEntry`）。私有非 widget 类（如 `_XxxPainter extends CustomPainter`、`_XxxDelegate`）按普通类翻译并保留 `extends`，修复私有 painter 丢失基类能力的问题。
- **不支持项出声**：`drawImage*` / `drawParagraph` / `drawPicture` / `drawShadow` / `drawPoints` / `drawColor` / `toImage*` / `getTransform` 等在 JS 侧直接抛错；未知绘制指令、Paint 属性、Path 指令由宿主 `HotPatchLog.error`。

## 0.3.3

**产物按归属拆分（协议不变：补丁通道 / patch ops / 句柄信封一致，可与 `hot_patch` 0.3.0 搭配）。**

- `runtime.js` 只留语言层 + mini-react 核心 + 通用缝（作用域查找 / BuildContext 代理 / 独立根挂载 / 宿主桥），不再含任何库或 Flutter SDK 的 API 面。
- provider 的自有登记（`registerScope('ChangeNotifierProvider')` + `JsBuildContext.prototype.watch/read`）移进它的**包模块** `patch/provider.js`（生成器 `provider_module_js.dart`，由 `widget_module_builder` 的 `_packageModuleEpilogues` 追加）；`context.watch/read` 的对齐结论不变。
- `showDialog` 系列（dialog / adaptive / general / cupertino / sheet / cupertinoSheet）连同面板独立根机制（`openPanel` / `panelMount` / `panelClosed` / `panelPop` / `panelOf`）与 `Navigator` 移到 `patch/flutter.js`（`dialogs_js.dart` / `navigator_js.dart`），从 `export function` 导出：产物按名 import 后裸调用，与 Dart 一比一。`__jsui.panelMount` / `panelClosed` 由该模块求值时安装（宿主调用点已有存在性守卫）。
- `G.__core` 交接面补齐：作用域机制、结点归属、独立根 mount/unmount/commit，以及 `building` / `activeRoot` 的访问器（闭包 var 必须实时读写）。
- **命名构造改为 1:1 发射**：翻译层不再往 `props` 写 `factory`，而是把构造名作为结点中间态（`ctor`）只用于发射 `X.b({...})`（`SizedBox.shrink(...)` / `Image.network(...)` / `ListView.separated(...)` / `ChangeNotifierProvider.value(...)`）。JS 没有 Dart 的命名构造，故 `flutter.js` 的包装类与逻辑组件对每个源码构造名生成**同名静态方法**，由静态方法把构造名写进 `props.factory`——宿主仍只按 `props.factory` 选原生工厂，协议不变。
- 宿主补齐此前「静态方法写了 `factory` 但 renderer 没消费」的构造：`SizedBox.shrink/expand/square/fromSize`、`Positioned.fill/directional`、`Transform.rotate/scale/flip`、`Card.filled/outlined`、`Visibility.maintain`、`SliverVisibility.maintain`、`Text.rich`、`IconButton.filled/filledTonal/outlined`、`FloatingActionButton.extended/large/small`、`ElevatedButton/TextButton/OutlinedButton/FilledButton.icon/tonal/tonalIcon`、`Dialog.fullscreen`、`AlertDialog.adaptive`、`TabBar.secondary`、`SliverAppBar.large/medium`、`SliverGrid.count/extent`、`SliverFixedExtentList.builder`。
- **删除生成器里的静态工厂硬编码表**（原 `_wrapperStaticFactories = {'styleFrom': 'ButtonStyle'}`）：它不按类型生效，会给每个包装类（含 `@PatchIgnore` 的 `_LabeledDivider`）都生成 `static styleFrom`。改为源码事实驱动——`CtorSignatures.staticMethodsOf(type)` 返回**返回类型是镜像值类**的静态方法（`ElevatedButton.styleFrom` → `static styleFrom(props) { return new ButtonStyle(props); }`），并排除形参含 `BuildContext`（`X.of(context)` / `Divider.createBorderSide(context, …)`）与私有方法。
- 逻辑组件的命名构造静态方法改为**类体内的 `static`**（`ChangeNotifierProvider` 的 `static value(props)`），不再生成类外赋值 `X.name = function…`；`_LabeledDivider` 一类包装类不会再出现无主的静态转发。
- `TextStyle` / `ButtonStyle` 去掉 `__pos` / `factory` 过滤：二者构造参数全为具名参、无命名构造，产物不可能下发这些协议键，直接按原名拷贝。
- 结点判定去掉结构猜测（原 `_isNodeMap` 按「`type` 是带引号字符串 + 键集合白名单」猜）：结点 Map 由 `elementToJson` 统一打内部标记 `__node`，渲染层只认标记，props 里 `Foo(type: …)` 这类普通容器不再可能被误判。

## 0.3.2

**删除 `runtime.js` 里的无效设计与恒真探测（行为不变）。**

- 删除 `G.__posArgs` 全局导出：该函数只被运行时内部的值类（Color / Duration / Key / 异常）使用，产物与 Dart 侧都不引用它。
- 删除 13 处 `typeof console !== 'undefined' &&` 与 13 处 `if (console.error/warn)` 真值守卫：`console` 在【1】无条件定义，release 下五个方法都是空函数；守卫恒真，等于白读一层。
- `__log` 去掉 `_app_host_` 存在性探测：它在 IIFE 收尾赋值，console 只可能被之后的页面代码调用。
- `capKey` 去掉 `WeakMap` 降级分支：QuickJS 必有 `WeakMap`。
- `requestFlush` 的三重探测收敛为「有宿主桥 / 无宿主桥（纯 JS 单测）」两条。
- 修正 `hot_patch` 侧 `js_leak_snapshot.dart` 的过时说明（原写「release 下 JS 产物不含 leakSnapshot」，实际产物对 debug/release 是同一份，靠调用点门控）。
- **保留**并确认为扩展契约、非死代码：`__jsui.h / fn / reg / Component`（外部能力库的入口，见 `js_ui_library.dart` 的说明）、`sendMessage` 存在性判断（纯 JS 环境兜底）、`Array/String/Number.prototype` 的「已存在则跳过」守卫（同一 JS 上下文重复求值 runtime 时的保护）。

## 0.3.1

**`runtime.js` 性能与可维护性修复（产物协议不变，可与 `hot_patch` 0.3.0 搭配）。**

- **release 下 console 完全静默**：`debug` / `info` / `log` / `warn` / `error` 在 `!kDebugMode` 时全部替换成同一个空函数，**一次都不跨桥**（原实现除 `debug` 外仍会走 `_app_host_.invoke`，每次日志都要格式化 + JSON 编码 + 桥消息 + Promise）。
- **keyed diff 从 O(n²) 降到 O(n)**：`patchChildren` / `patchSlotList` 的匹配逻辑抽成唯一的 `keyedMatcher`（一次建索引 + 无 key 游标 + `__id` 定位），去掉了逐项线性扫 `remaining`、`splice` 搬移与 `indexOf` 判移动，也消除了两份重复实现。
- **`eq` 降分配**：每层从两次 `Object.keys` 降为一次（另一侧用 `for-in` 计数），数组先比长度短路。
- **修 `capKey` 的类型撞车**：原始捕获值改为 `typeof + ':' + String(v)`——数字 `1` 与字符串 `'1'`、`null` / `undefined` / `''` 不再生成同一 key（否则不同捕获值的事件闭包会互相覆盖）。
- **修 `keySig` 的兜底撞车**：认不出的 key 对象改用引用身份 token，不再 `String(k)`（后者会把所有对象压成 `[object Object]`，导致不同 key 复用同一结点）。
- **生命周期异常不再静默**：`deactivate` / `dispose` 抛错时记 `console.error`（release 下即空操作）。
- **文档与注释去重**：删掉各片段内残留的旧分区标题（与产物头部的【n】编号冲突、且 `1b` / `1c` / `10.x` 混排），分区改为严格顺序 1..25；`runtime.js` 顶部同时注明 console 的 release 语义。

## 0.3.0

**新增动画支持；JS 运行时改由生成器产出（运行时需同步升级到 `hot_patch` 0.3.0）。**

- **新增 `ui_runtime` builder**：把 JS 运行时（mini-react / 句柄表 / 各能力片段）拼成**一个** `patch/runtime.js`（分区注释 `// ===== 【n】标题 =====`），运行时包不再内嵌任何 JS——JS 修复只需重出产物，无需发版。产物头部的版本号取内容哈希（FNV-1a），哈希变化即触发运行时原地重建。
- **宿主类型清单自动抽取**：删除手工维护的 `builtinWidgetTypes` / `jsDataCarrierTypes`，改为构建期扫描 `hot_patch/lib/src/js_ui/**` 的 `r.register('X', …)` 与 `_dataCarrierTypes`——新增宿主组件只改运行时注册一行，生成器零登记、两端不再需要人工同步。
- **清单新增 `protocol`**：`patchProtocolVersion = '1.0'` 写入 `patch/manifest.json`；主版本变化表示产物与宿主 Dart 的契约（`__h` / `element` / `__delegate` / 句柄信封 / 颜色序列化）有破坏性改动，次版本只做加法。
- **修复 `PackageSources` 的 `rootUri` 解析基准**：改为相对 `package_config.json` 自身（pub 规范）。此前在工作区里会多退一级，导致依赖包与项目自身的构造签名、类索引全部定位不到。
- **登记动画组件类型**：宿主类型清单追加 `AnimatedContainer` / `AnimatedOpacity` / `AnimatedPadding` / `AnimatedAlign` / `AnimatedScale` / `AnimatedRotation` / `AnimatedSlide` / `AnimatedSize` / `AnimatedSwitcher` / `AnimatedCrossFade` / `AnimatedDefaultTextStyle` / `AnimatedPositioned` / `FadeTransition` / `ScaleTransition` / `RotationTransition` / `SizeTransition`（现由运行时注册自动派生）。
- **`AnimatedBuilder` 作为逻辑组件**（`logicWidgetTypes`）：`builder` 闭包抽成组件方法，产物只下发方法名，逐帧重建只发生在该子树。
- **动画值 / 控制器的翻译**：`Duration` 归入命名实参的 JS 运行时代理（`new Duration({milliseconds: n})`）；`AnimationController` / `CurvedAnimation` 同样按 JS 同名代理类构造；`Tween` / `CurvedAnimation` 作为值对象只在 JS 侧推导 `value`。
- **枚举成员名口径**：`Curves.easeOut` / `CrossFadeState.showFirst` 继续按成员名字符串下发（与既有枚举翻译一致），运行时按名字还原真实对象。

## 0.2.3

**统一 widget 构造协议：宿主包装类 + 翻译统一 `new`（运行时需同步升级到 `hot_patch` 0.2.2）。**

- **宿主包装类**：`patch/flutter.js` 为 `builtinWidgetTypes` 中的宿主 widget（`Text` / `Column` / `Scaffold` …）与数据载体（`InputDecoration`）生成同名包装类——`class Text { constructor(props) { return __h('Text', props); } }`。宿主元素 type 仍是类型名字符串，reconciler 从不 `new` 这些包装类。
- **翻译统一发射 `new Type(props)`**：宿主包装类、自定义组件、逻辑组件、builder 代理一律 `new`；只有无 JS 类的类型（无产物自定义组件 / 原生注入）保留 `__h('Type', props)` 兜底。
- **组件类构造即实例**：删除构造函数内部 token / 双模分支，组件类首行保留 `this.props = args`，字段初始化照常写在构造里；实例随元素下发（`__asElement` 的 `inst`），由运行时 mount 复用，不再二次构造。
- **局部值翻译去掉 widget 白名单**：`widgetValueJs` 只排除已知模型类（classTable 的 `!isComponent`）与值对象 / 结构化样式，其余类构造一律按元素翻译；`widgetClassNames` 字段删除。
- **字段 / 依赖判定不再依赖 `builtinWidgetTypes`**：能解析到的类直接放行；解析不到的类型按宿主 Widget 值处理并输出构建期告警。该表现在只用于生成宿主包装类与决定 import 类名。
- **产物兼容边界**：旧产物在新运行时可用；新产物需要 `hot_patch` 0.2.2 的 `__asElement` 与宿主包装类，按整包更新补丁。

## 0.2.2

**builder 形态与事件目标的判定统一为产物协议；产物仅局部变化。**

- **`usesJsClass` 只认 `factory`**：只有 `builder` / `separated` 命名构造才走 JS 代理类，删除「props 里出现 `builder` / `*Builder` 键」的猜测。顺带修正 `GridView.count` / `.extent` 等普通工厂被误判为代理形态的问题。
- **`builderFormTypes` 校正**：补入 `PageView`（`.builder` 与 ListView 同机制）；移除没有 `.builder` / `.separated` 构造的 `SliverFixedExtentList` / `SliverFillViewport`（它们仍走 delegate 宿主节点）。
- **代理类精简**：命名构造代理只读 `itemBuilder` / `separatorBuilder` / `itemCount`；delegate 形态不再经过代理类。
- **事件目标判定不再依赖内建类型表**：按「有 JS 产物 / 逻辑组件 → 可调用闭包；builder 代理与宿主 → 事件句柄」判定，自定义组件无需维护清单。
- **共享与清理**：`isClassName` 收敛为一处；删除未使用的 `WidgetNode.factory`、`listArg`、`propOf`、`propExpr`、`borderRadiusExpr` 等。

## 0.2.1

- **所有 Dart 实参按原名进 props**（含 `child` / `children` / `slivers` / `tabs`），生成代码不再向 `__h` 传第三参；元素工厂 `__h` 按元素 `type` 拆分：宿主字符串类型把标准结构键抽成 `element.children` 并从 props 剥离，JS 组件类保留全部 props 供 `__applyProps`（修复自定义组件 `child` / `children` 构造参数拿不到值的问题）。`delegate:` 仍归一为 `props.children` 或 `builder` / `childCount`。
- 删除位置实参的下标键兜底：不再生成 `props['$pos']`；未在 `widgetPositionalArgNames` 登记形参名的类型遇到位置实参时，构建期告警并丢弃，避免出现没有语义的下标约定。
- 清理过时文档与提示语：翻译失败提示中的 `@UIProp` 残留改为「组件状态字段（@PatchEntry 组件的实例字段）」；`build.yaml` 里对已删除 translator 注册表的引用改为 `registeredWidgetPackages()`。

## 0.2.0

**翻译内核重构：去掉 per-widget 的 `WidgetTranslator`，改为统一翻译；产物协议随之变更（运行时需同步升级到 `hot_patch` 0.2.0）。**

- **统一翻译入口**：`widget_json.dart` 按**通用参数名**（`child` / `children` / `slivers` / `tabs` / `on*` / `delegate`）+ `value_forms.dart` 按**值的形态**（字面量 / 构造 / 静态工厂 / 常量引用 / 列表 / 闭包）分派；内建、自定义、三方组件同一套规则，**接入新组件零实现**。删除 `WidgetTranslator` / `WidgetTranslatorRegistry` / `UnregisteredWidgetTranslator` 与 `builtin_translators.dart`。
- **位置实参按 Flutter 声明的形参名下发**：`Text('hi')` → `{data: 'hi'}`、`Icon(Icons.star)` → `{icon: 'star'}`、`Image.network(url)` → `{src: url}`；未登记的类型退回 `$pos` 下标数组（登记表见 `js_widget_defs.dart` 的 `widgetPositionalArgNames`）。
- **命名构造 / 静态工厂名进产物**：`{factory: 'builder' | 'separated' | 'network' | 'value', ...}`——同类型不同工厂**同 `type`、不同 `factory`**，运行时据此挑选原生 / JS 工厂（不再靠「有没有某个键」猜形态）。
- **枚举引用 → 成员名字符串**：`Axis.horizontal` → `"horizontal"`、`BottomNavigationBarType.fixed` → `"fixed"`（JS 侧没有枚举，裸标识符会让整个组件挂载失败）。
- **`on*` 回调按目标类型分流**：宿主 widget 下发事件句柄 `{__fn:id}`；组件（自定义 / 私有 / `@PatchEntry` 子组件）下发**可调用闭包**（子组件直接 `this.onXxx(...)` 调用，不再报 `is not a function`）。
- **事件统一为构建期箭头闭包**：所有事件（方法引用 / 字段回调 / 箭头闭包 / 块体闭包）统一产出 `this.__bindFn(位点号, [捕获值], (...a) => …)`；闭包天然捕获 build 局部变量 / 循环变量，与 Dart 闭包同语义。删除 `this.__bind("表达式")` 字符串求值路径（`new Function` 丢失构建期作用域，`onPressed: () => model.inc()` 会静默失效）。位点号为编译期稳定编号，捕获值按「对象引用身份 / 原始值」比较，重建后句柄 id 稳定、循环项互不串味（同时修复方法形参未进 key 的碰撞缺陷）。**不再**为特定写法做 `context.read("T")` 之类的按名改写。
- **颜色编译期算值**：`Color(...)` / `Colors.*` / `Colors.*.shade*`（含 `*Accent` 的 100/200/400/700）→ `#RRGGBB` / `#AARRGGBB`；产物里不再出现 `@Colors…` 标记（色板数据取自 Flutter SDK 的 Material 色板，运行时无需色板分支）。
- **结构化值不再变成结点**：`gridDelegate`（`SliverGridDelegateWith*`）等转为 JSON 值下发，避免运行时读不到参数（GridView / SliverGrid 退化成单列）。
- **修复 `MultiProvider` 子结点丢失**：生成产物把 `child:` 放进元素 children，而 JS 模板只读 `props.child`，导致 providers 包住 `undefined`、整段子树静默消失（卡片只剩空壳）；模板现在同时读取 `children[0]`。
- **`ReorderableListView.builder` 支持**：登记进 `builderFormTypes`，`itemBuilder` / `itemCount` 与 ListView.builder 同一套「闭包抽方法 + 代理类展开子树」机制，宿主还原原生命名构造；`scrollController` 参数按 Flutter 形参名原样下发。

## 0.1.1

- 补充 `repository` 字段，修复 pana 仓库校验失败导致的 pub.dev 页面无 GitHub 地址。
- `description` 改为英文，满足 pub.dev 对英文描述的要求（中文描述会被 pana 扣分）。
- README 提供中英双语，顶部可切换。

## 0.1.0

- 首个版本。
- 把带 `@PatchEntry` 注解的 Flutter widget 静态翻译为与 Dart 源文件同名的 JS 模块
  （`analyzer` 静态解析，不执行任何 Dart 代码）。
- 产物按文件内容分流：组件产物 / 普通类与静态单例产物；都不含则不产出。
- package 级 widget 工厂模块：**一个 package 一个文件**（`patch/flutter.js`、
  `patch/provider.js`），共享结点工厂 `__h` 全局只定义一次。
- 事件绑定在构建期注入，归属与 Dart tear-off 语义一致。
- 内置 widget 策略注册表；新增 / 自定义 widget 只需实现 `WidgetTranslator` 并注册，核心代码零改动。
- package 级模块与 patch 清单都挂在包根伪资产 `$package$` 下，使用方无需种子文件或额外配置。