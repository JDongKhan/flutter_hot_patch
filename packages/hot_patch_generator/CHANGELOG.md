## 0.3.8

**JS 运行时整理（纯内部重构：`patch/runtime.js` 与 `patch/flutter.js` 同步重出即可，宿主通道与补丁协议字段不变）。**

- **内部符号统一 `__` 前缀**：`emitOp` / `commitOps` / `mount` / `patch` / `unmount` / `registerHandle` / `handleOp` / `markDirty` / `pullComponent` / `scopeOf` / `nodeIdOf` / `keySig` / `objectToken` 等只在框架内使用的函数与状态表（`roots` / `handles` / `hostNodes` …）全部改名，开发者可据此一眼分辨「框架内部」与「对外契约」。
- **日志统一走宿主通道**：删除 runtime.js / flutter.js 中全部 `console.*`，内部诊断改走 `__logText`（warn / error 级别，经 `_app_host_.invoke('log')` 进 `HotPatchLog`）；缓存追踪切面改用 `debugPrint`，release 下零跨桥。
- **合并重复设计**：新增 `__openRoot` / `__closeRoot` 统一「页面根 / 弹层独立根」的建树与卸载事务，`mountRoot` / `disposeRoot` / `Panel.mount` / `Panel.closed` 收敛为薄封装；新增 `__withBuilding` / `__callLifecycle` 收敛 6 处构建锚点与卸载生命周期样板；`ListenableBuilder` / `ValueListenableBuilder` / `AnimatedBuilder` / `TweenAnimationBuilder` 共用 `__ListenableSubscriber`；逻辑组件的 props 摘除统一走 `Component.__propsExcept`。
- **`Component` 内聚**：`__captureKey` / `__splitHost` 从模块级函数收进 `Component` 静态成员；空无参构造从宿主包装类与逻辑组件中删除（继承默认构造即等价）。
- **删除无用/兼容逻辑**：移除 `newRoot`、`releaseHandleFromHost`、`__isBuilderFn`、`__jsui.fn` / `__jsui.reg`（宿主未使用）、`keySig` 的 `__handle` 兜底，以及 flutter.js 模块级 `G.__str` / `G.objectToken` 单点交接（并入 `G.__core`）。
- **纯内部命名澄清**：`G.__scopeOf`（接收 BuildContext 代理）改名 `G.__scopeOfContext`，与核心 `__scopeOf(instance, type)` 区分；`JsBuildContext` 改回 ES class 写法。
- **修复 JS 侧组件回调被降级成句柄**（社区 / 订单列表点击报 `this.onTap/onOpen is not a function`）：`element_json` 本来按「目标是不是 JS 侧组件」分派——JS 组件下发可调用闭包，宿主 widget 下发 `__fn` 句柄；但 `element2js.functionJs` 在通用闭包翻译失败时（典型：闭包体内是 `@HostInjected` 静态调用，只有事件作用域支持）直接返回 null，调用方**静默回退成 `__bindFn` 句柄**，破坏了这一分派。现改为回退到事件闭包翻译、但**仍产出普通函数**（绝不降级成句柄）。组件间回调恢复「就是函数」，宿主边界仍走 `__bindFn`（位点缓存，无重复 bind），不引入 `__invokeCallback`。
- **规则定死**：JS 消费方（JS 组件 / 逻辑组件）只接收**普通函数**，宿主 widget 才接收 `__fn` 句柄；`element_json` 不再在 JS 侧回调翻译失败时回退成句柄，改为明确构建期告警并丢弃该回调。`functionJs` 同时补齐了 `父级.receiver` 回调引用、条件表达式、括号 / `as` 包装等普通函数形态（这些**仅限回调位置** `callbackJs`，值位置仍按值翻译，静态常量如 `Colors.white` 不会被误包成闭包）。

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