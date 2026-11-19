> 注：本文件是历史版本记录，早期协议名称可能与当前实现不同；当前协议见 `docs/项目架构文档.md`。

## 未发布

**修复 Android（QuickJS）上 JS 侧 `await` 宿主调用后不恢复，界面一直 loading；无协议变更。**

- `JsRuntimeManager` 的求值统一走 `_evaluateAndDrainJobs`：`evaluate` 之后调用 `runtime.executePendingJob()` 排空 Promise 微任务。QuickJS（Android）的 `evaluate` 不会自动执行微任务，宿主 `_app_host_.resolve(...)` 回填后 `await` 的续体停在队列里（如 `Network.post` 成功后 `AppShellVm.load()` 永不返回、也无报错）；JSC（iOS/macOS）的 `executePendingJob` 是空实现，无副作用。
- 引擎**内部**执行的回调同样要排空：flutter_js 自己实现的 `setTimeout`（`Future.delayed` / `Timer` 走它）在回调里 resolve Promise 后也不会跑续体。Android 上包一层 flutter_js 的 `SetTimeout` 通道，**每次 JS 注册定时器时**在相同延迟之后再排空一次微任务（按需触发，无常驻轮询、没有定时器就零开销）；JSC 不处理。修复异步 demo 一直停「等待 complete…」、`Future.delayed` 不恢复的问题。
- 文档：最低系统版本更正为 **iOS 14.5+ / macOS 11.0+**（产物含静态类字段，Safari 14.1 起支持）；example 的 `IPHONEOS_DEPLOYMENT_TARGET` / `MACOSX_DEPLOYMENT_TARGET` 与 Podfile 同步改为 `14.5` / `11.0`。无代码与协议变更。
- **循环 import 不再中止加载**：`_loadModule` 命中依赖链上的模块时改为告警 + 占位导出（`__modules[key] = {}`）并返回，不再抛 `StateError`；命名 import 从 `const { A } = __modules[...]` 改为 `let` + `__onImportReady` 回填，模块尾部用 `Object.assign` 原地填充并 `__flushImportFixups`。方法体 / `build` 内的互相引用可正常执行；模块顶层 `extends` / 静态字段 / `new` 使用环对面仍会失败，并追加「拆分共用模块」提示。`invalidateModules` 同步清理回填队列与就绪标记。无协议变更。

## 0.6.2

**仅文档修正（无代码变更）**：README 安装示例中的依赖版本号由 `^0.4.0` 更正为 `^0.6.2`（首次以新包名发布 0.6.1 时，安装示例仍沿用旧包 README 的版本号，`^0.4.0` 在新包上无法解析）。

## 0.6.1

**包更名**：`hot_patch` → `dynamic_flutter`（同一实现、同一版本线；包名之外无代码与协议变更，`protocol` 仍为 `0.14.1`）。旧包保留在 pub 上但不再更新。

**破坏性变更（运行时策略收敛）：宿主侧对象只在 JS 构造时创建；删除「控制器 Host」包装层。**

- **`JsObjectBridge.create` 改为必填**（`T Function(String id, Object? meta)`）：真实对象随 JS 侧 `__bindHandle` 的 create 消息建立，构造参数经 `spec.meta(self)` 随 create 下发——TabController 的 `length/initialIndex`、PageController 的 `initialPage/viewportFraction`、ScrollController 的 `initialScrollOffset/keepScrollOffset/debugLabel`、TextEditingController 的 `text`、AnimationController 的 `value/lowerBound/upperBound/durationMs`、FixedExtentScrollController 的 `initialItem`、EasyRefreshController 的 `controlFinish*`。renderer 的 props 里只剩 `{__handle: id}`。**JS 侧自定义 `__bindHandle` 类必须补 `meta`**，否则宿主按默认参数建对象。
- **删除 `JsControllerHost` / `_JsControllerHostState` / `controllerOf` / `markAttachedOnFirst`**：渲染组件的宿主侧改为 `bridge.require(id)` 取对象后直接交给真实 widget；取不到即抛 `FlutterError`（消息说明「JS 侧必须先构造该对象」），不再渲染期兜底创建。ScrollController / PageController / TabController / FocusNode / KeyboardListener / CupertinoPicker / OverlayPortal / AnimationController / EasyRefresh 全部改走这条路径；`jsDoubleAnimationOf` 取不到对象时按无动画处理并告警。
- **宿主 → JS 镜像的回传收进桥**：新增 `forward: (T controller) => List<Object?>?`（`null` = 此刻无内容可发），`onCreate` 在对象是 `Listenable` 时挂一次 listener，渲染方在挂上组件那一帧调 `forwardOnNextFrame(id)` 补首帧快照。AnimationController 的逐帧 value 回传由它承担（删除 `_attachValueMirror`）。
- **`extraJSON` 死载荷清理**：宿主不再从 props 读构造参数，`ScrollController` / `FixedExtentScrollController` / `AnimationController` / `EasyRefreshController` 的 `extraJSON` 全部删除（`__bindHandle` 的 `extraJSON` 扩展点保留，供 toJSON 追加字段的其它场景使用）。
- **`onOp` 缺句柄时出声**：同 `{id}|{op}` 组合只告警一次（按 null 返回），不再完全静默。
- **新增可选能力 `capabilities/core/ticker_mode_binding.dart`（TickerMode 绑定，可开关）**：TabController / AnimationController 的 vsync 由它提供（`jsTickerProviderFor(id)`，`debugLabel` = 句柄 id），渲染方在挂上组件那一帧调 `jsBindTickerMode(id, c.context)` 把裸 Ticker 的 `muted` 绑到该子树的 `TickerMode`——子树被 Offstage / 非活跃 route / `TickerMode(enabled:false)` 遮住时动画暂停，恢复后接着跑（与 Flutter 同语义）。模块与 `object_bridge`、各能力文件零耦合，只被 Tab / Animation 引用两处；`jsTickerModeBindingEnabled`（**默认关闭**，关闭态即「裸 Ticker 不静音」的现状；需要时在 `main()` 里置 `true` 打开），其它代码不用动。同一控制器多视图共享时以最先登记的挂载点为准；id→provider 用弱引用，随控制器释放自动失效。

## 0.6.0

**加法：UI 能力装配入口 `initJsUi(...)`；无破坏性 API / 协议变更。**

- **`initJsUi({List<JsUiLibrary> libraries, List<Map<String, Object?>> hostMethods})`**：启动期唯一装配入口，一次完成「注册能力库 → 全部能力通道就位（`ensureJsUiCapabilities`）→ 宿主组件注册表建表（`ensureJsWidgetRegistry`）→ 注册内建宿主方法 → 注册业务宿主方法」。`hostMethods` 每项形状固定 `{'name': 通道名, 'handler': 实现}`，通常直接传 `@HostInjected` 的生成清单（`lib/generated/host_methods.dart` 的 `hostMethods` getter），无需再逐个调 `registerHostMethod`；形状不对启动即抛 `ArgumentError`，同一通道重复装配按通道名去重并告警。**必须**在 App `main()` 里 `runApp` 之前调用；`JsUiWidget` **不再自动装配**，启动时只做契约校验（`assertJsUiInitialized()`：debug 断言失败、release 记一条 error），避免漏调后页面静默渲染成未注册占位。
- **`jsUiInitialized`**：是否已执行过装配。
- **`ensureJsWidgetRegistry()`**：显式触发一次建表（幂等），让首帧不再承担注册工作。
- **`jsWidgetRegistryBuilt` + 晚注册告警**：注册表建表之后才 `registerJsUiLibrary(...)` 的能力仍会就位通道，但拿不到 `registerWidgets` 回调——此时明确告警，不再静默丢映射。建表后单独 `jsWidgetRegistry.register(type, build)` 仍然有效（表可变、查表发生在渲染时刻）。
- **示例收敛**：`example/lib/custom/custom_capabilities.dart` 由「逐个 `registerJsUiLibrary` 的函数」改为能力清单 `customJsUiLibraries`；`main()` 一次 `initJsUi(libraries: customJsUiLibraries, hostMethods: hostMethods)` 装配，原来的 `registerHostMethods()` 调用删除。

## 0.5.0

**加法：`ListView.builder` / `.separated` 支持宿主按槽位拉取；无破坏性协议变更。**

- **`JsRenderContext.lazySlot(int slotIndex)`**：容器 props 带 `__pullItems` 时可用。renderer 在 `itemBuilder` 里返回它，宿主首次布局到该槽位时同步调 `__jsui.pullSlot` 拉取子树；子项高度真实测量，无 `itemExtent` 也能懒。非按槽位拉取的结点调用会返回明确的错误视图。
- **`JsUiStore.removeSubtree(String id)`**：释放不在任何父 slot 里的 item 子树（宿主 `ListView.builder` 按 index 渲染，store 里没有 insert 关系）。
- **`ListView` renderer**：识别 `props.__pullItems = {id, slots}` 并还原成 `ListView.builder` 平铺渲染槽位序列。`.separated` 的交替已在构建期产物里折叠进统一 `item(slotIndex)`，宿主不再按 separated 分叉。
- **`ListView(children: …)` 行为不变**。

## 0.4.2

**加法：`MethodChannel` 宿主通道；无破坏性协议变更。**

- **公开 API 统一 `Js` 前缀（破坏性 Dart API 变更，产物协议不变）**：`HotPatchLog` / `HotPatchLogRecord` / `HotPatchLogSink` / `HotPatchLevel` / `HotPatchAssets` / `HotPatchAssetBundle` 分别更名为 `JsLog` / `JsLogRecord` / `JsLogSink` / `JsLogLevel` / `JsAssets` / `JsAssetBundle`；全局 `widgetRegistry` 更名为 `jsWidgetRegistry`。不保留别名与兼容 shim，接入方按新名迁移。命名约定见 `docs/项目架构文档.md` §5.1。
- **`JsUiWidget.props` → `params`，并与 `jsAsset` query 合并**：最终 props = `jsAsset` query 中的业务参数覆盖 `params`；`component` / `entry` 只用于定位入口，不进入业务 props；query 值一律按字符串处理。运营可直接在 URL 上覆盖同名参数，无需重新发版。
- **移除 `JsUiLibrary` 未使用钩子**：删除 `jsFragments` / `jsModuleAssets` 以及运行时对应的「外部库片段注入 / 能力模块兜底加载」逻辑。三方 JS 统一走工程根 `js/<package>.js`，由页面产物 import 按需加载，不再保留第二条注入通道。

- **宿主 JSON 还原统一为 `JsRenderContext` 扩展方法**：`capabilities/**/*_from_json.dart` 的还原入口改为按 props 键取值的短名扩展，例如 `c.color('color')`、`c.textStyle('style')`、`c.edgeInsets('padding')`、`c.boxDecoration('decoration')`。`dynamic_flutter.dart` 统一导出这些扩展，外部自定义 register 只需 `import 'package:dynamic_flutter/dynamic_flutter.dart'`，不必再 import 具体实现文件。嵌套结构、绘制指令、弹层 options、Controller 实参等无渲染上下文的路径继续复用底层 `*FromJson` 函数（`curveFromJson` / `durationFromJson` 保持导出）。
- **`edgeInsets` 统一为单一可空方法**：删除 `nullableEdgeInsets` / 非空 `edgeInsets` 两个入口，只保留返回 `EdgeInsets?` 的 `edgeInsetsFromJson` / `c.edgeInsets(key)`；缺省返回 null 以保留组件/主题默认值。需要非空的位置由调用方按 Flutter 官方默认兜底（如 `?? EdgeInsets.zero`）。
- **`JsRenderContext` 数值入口区分 `num_` / `double_`**：原 `num_` 实际返回 `double?`，更名为 `double_`（调用点统一 `c.double_(key)`）；同时补回语义正确的 `num? num_(String key)`，返回 JSON 原始数字（当前宿主渲染未用到，作为框架通用入口保留）。`int_` / `bool_` 命名保持一致。
- **`styleMap` 合并进 `map`**：`map(key)` 现在同时接受普通 JSON map 与元素描述（`{type, props, ...}`，取内层 props），不再保留样式专用入口；`elementProps(Object?)` 作为脱离 props 键的通用原始值入口保留。
- **移除 `registerNativeComponent` / 原生组件注入表**：纯原生组件统一走 `widgetRegistry.register(type, build)`（与内建能力同一张宿主注册表），未注册类型只给可见占位。全局 `jsWidgetRegistry` 更名为 `widgetRegistry` 并从 `dynamic_flutter.dart` 导出。

- **宿主对象还原不再自带默认值**：JSON → Flutter 值/组件的解析统一以**官方构造器默认值**为准，缺省属性一律不传（`null` = 组件/主题默认），不再用自定义零值覆盖。
  - `Container` / `AnimatedContainer` 的 `padding` / `margin` 改用可空的 `c.edgeInsets`（此前缺省塞 `EdgeInsets.zero`）；
  - `Tooltip` 的 `padding` / `margin` / `verticalOffset` / `excludeFromSemantics` 缺省不再填 0 / 24 / false（这些在 3.41 都是 `null` → `TooltipTheme`）；
  - `CustomPaint` 的 `TextPainter.textAlign` 缺省改为官方 `TextAlign.start`（此前误用 `left`）；
  - `MediaQueryData` 解析由 `const MediaQueryData()` + 仅对存在的字段 `copyWith`（见上一条）。
  其余 `*_from_json` 助手逐项核对：`BorderSide` / `BoxShadow` / `Border` / `OutlinedBorder` / 渐变 / `BoxConstraints` 的兜底值与官方构造默认一致，可选项均返回 `null`。

- **`MediaQuery` 子树数据变化后自动刷新（JS 侧继承，按 aspect 粒度）**：JS 的 `MediaQuery` 类在 `build` 里把自己登记为类型名 `'MediaQuery'` 的继承结点（与 provider 的 `ChangeNotifierProvider` 同一机制），`MediaQuery.of / sizeOf / ...` 优先经 `dependOnInheritedWidgetOfExactType` 同步读最近 JS 声明的值，上方没有 JS 声明的 MediaQuery 时才走宿主桥。依赖按 aspect 登记（`of` = 全部，`sizeOf` 只依赖 `size`…），数据变化时只通知「变化的 aspect ∩ 依赖者用到的 aspect」有交集的位置，与 Flutter 的 `dependOnInheritedWidgetOfExactType(aspect:)` 粒度一致。`remove*` 在 JS 侧按 `MediaQueryData.remove*` 计算派生值供继承取值，原生渲染仍走宿主同名 API。宿主侧无新增组件，同时保留「该位置上方没有 MediaQuery」的一次性告警（`_absentLogged`）。

- **`MediaQuery` 组件（含 `removePadding` / `removeViewPadding` / `removeViewInsets`）**：JS 类是宿主手写的 `Component` 子类（登记 `logicWidgetTypes`，生成器不再重复生成同名包装类），静态取值 API 与命名构造静态方法都写在类体内（后者与其它组件同构：写 `factory`）。宿主注册 `'MediaQuery'` 只负责渲染：无名构造用 `data` 还原 `MediaQueryData`（JS 侧 `MediaQueryData` 值类 + `copyWith`，`MediaQuery.of()` 返回它），`remove*` 用调用位置的 BuildContext 直接调 Flutter 同名 API。为此 `JsRenderContext` 新增 `context`（宿主构建期传入并沿子树透传）；`JsBuildContext` 补 `toJSON()`（代理含组件实例引用，不可直接跨桥序列化）。示例见 `example/lib/components/media_query_detail.dart`。

- **`ClipRRect` 圆角修复**：宿主渲染只按数字读 `borderRadius`（`c.double_`），而 JS 侧 `BorderRadius.circular(14)` 的 `toJSON()` 是 `{radius: 14}` 对象 → 取不到值退回 `BorderRadius.zero`，补丁内所有圆角裁切（banner / 推广图等）变成直角。改为 `borderRadiusFromJson` 解析（`{radius}` / 四角），并兼容旧协议直接下发数字。

- **宿主通道 `methodChannel`**：JS 侧 `MethodChannel.invokeMethod` 经唯一出口 `_app_host_.invoke('methodChannel', [name, codec, method, args])` 交给宿主，宿主再调真正的 Flutter `MethodChannel(name, codec).invokeMethod` → 原生（不绕过、不新开 JS↔原生通道）。
- **实例绑定**：宿主按 `name#codec` 缓存 Dart 侧 `MethodChannel` 实例；channel 身份即该键，无运行时句柄、无 acquire / release（MethodChannel 无状态、无 dispose，同名实例共享 messenger 路由）。
- **codec**：镜像 `StandardMethodCodec` / `JSONMethodCodec`；未知标记回落标准 codec。参数与返回值走 JSON（`Map` 经运行时的 `toJSON` 归一）。
- **`setMethodCallHandler`（反向）**：JS 侧用 `G.__core.__createFnHandle` 登记回调，宿主通道 `methodChannelHandler` 在原生调用到达时经 `JsRuntimeManager.invokeAwait` 执行 JS handler；结果包成 `{value}` / `{__mcError}`，后者转 `PlatformException` 回给原生。handler 按 `name#codec` 唯一（同名新注册覆盖旧注册，旧 JS 句柄释放）。同时补齐 `invokeListMethod` / `invokeMapMethod`。
- **`BasicMessageChannel`**：JS 镜像 `send` / `setMessageHandler` 对应宿主通道 `basicMessageChannelSend` / `basicMessageChannelHandler`。`send` 调 Dart `BasicMessageChannel.send`；反向由原生发消息，`invokeAwait` 执行 JS 回调并把返回值作为 reply。支持 `StandardMessageCodec` / `StringCodec` / `JSONMessageCodec`；`BinaryCodec` 需要二进制承载，当前显式报错。示例：`module/hot_plugin_device_info`（同插件内第二种通道）。
- **`EventChannel`**：JS 镜像 `receiveBroadcastStream(args)` 返回运行时 `StreamController.broadcast`。首个订阅者出现时经宿主通道 `eventChannelListen` 订阅 Dart `EventChannel`，data / error / done 经 `__jsui.invoke` 转成 Stream 事件；订阅者归零或页面销毁时经 `eventChannelCancel` 取消订阅（回调句柄按 page scope 登记，release 钩子兜底）。示例：`module/hot_plugin_device_info`（原生每 500ms 推送计数）。
- 示例：`module/hot_plugin_device_info`（设备信息）、`module/hot_plugin_counter`（原生计数 + 原生回调 JS）两个模拟三方库插件，各持独立 channel；`example` 新增 `MethodChannelDetail` 展示页。
- **新能力 `capabilities/cupertino_picker/`**：`CupertinoPicker` 宿主渲染（`.builder` 的 `__items` 逐项还原 itemExtent / 放大 / squeeze / 选中框 / 选中回调）+ `FixedExtentScrollController` 句柄桥（kind `ctrl/FixedExtent`，`selectedItem` 回传镜像、`jumpToItem` 走通用 `call` op、释放走通用 release）。核心文件零改动，只新增能力模块并注册进 `JsUiLibrary`。
- **`sizeFromJson` 缺省维度按 0**：`Size.fromHeight` / `Size.fromWidth` 的一侧是 `double.infinity`，JSON 无法表达（`JSON.stringify(Infinity)` → `null`）；取不到的维度按 `0` 还原，`ButtonStyle.minimumSize` / `maximumSize` / `fixedSize` 不再因一侧为 null 整个字段丢失（配套生成器 0.14.0 的 `FilledButton.styleFrom` 支持）。
- **`ButtonStyle` 经 `styleFrom` 下发**：`buttonStyleFromJson` 对 ButtonStyle 各字段按裸值接收并包 `WidgetStatePropertyAll`（原有协议不变）；配套生成器 0.14.0 的 `WidgetStatePropertyAll.toJSON` 透传裸值，`WidgetStatePropertyAll(x)` 与裸值 `x` 两种写法产物一致。
- **`WidgetsBinding` 帧回调宿主支持**：`jsuiRequestFrame` 的 begin-frame 回调在 `flushJsUiPending()` 之后新增 `JsRuntimeManager.tickJsUiFrames(timeStamp)`，把帧开始回传给所有活跃 runtime 的 `__jsui.frameTick(ms)`，供 JS 侧 `addPersistentFrameCallback` 逐帧派发（回调里的 setState 会再次请求下一帧，形成逐帧节奏）；新增内建通道 `jsuiEndOfFrame`，直接 `await WidgetsBinding.instance.endOfFrame` 结算 JS 的 `endOfFrame` Promise（真正的帧末，空闲时自动催帧）。两者都是加法，既有通道与协议不变。
- **公开能力接入 API**：`dynamic_flutter.dart` 导出 `capabilities/js_ui_library.dart`（`JsUiLibrary` / `registerJsUiLibrary`），业务方可在自己的 `lib/custom/**` 里注册自定义宿主组件能力，无需 `package:dynamic_flutter/src/...` 实现级 import。
- **`JsRenderContext.key`**：原生注入 / 自定义组件的 renderer 可直接取到结点声明式 `key`（JS 侧 `new UniqueKey()` / `ValueKey(...)` / `GlobalKey()`）对应的**宿主 Flutter Key 实例**——GlobalKey / UniqueKey 与 JS 句柄是同一实例（跨帧稳定），ValueKey 等按值现造；未声明 key 时为 null。此前只能拿到序列化 props、自定义组件被迫自己造 key，导致原生侧身份与 JS 侧不一致。
- **key 挂到真实 widget**：所有宿主 renderer 统一把 `c.key` 传给真实 widget（基础组件与全部能力域），运行时不再额外包 `KeyedSubtree`，`GlobalKey.currentContext / currentState` 直接指向真实 widget（与原生 Flutter 一致）。漏传时运行期告警并用 `KeyedSubtree` 兜底元素身份，避免静默丢 key。配套删除 `hostStateKey` / `_stateTarget` 映射层：`AnimatedList` / `Dismissible` 也直接把 `c.key` 挂到真实 widget，key 桥的 `__state.*` / `__type` 直接从该 key 取 State。
- **泄漏日志只报差异**：`leak-check` 汇总行不再输出 `2 → 3 条（key/Global +1，fn 2，…）` 这类规模统计，只保留 `<N> 项残留` + 逐条「多余（JS）/ 多余（Dart）」明细（id / kind / scope / 登记方）；干净时只打 `clean`。配套删除 `_scaleText`、kind/桶计数与 `LeakStats` 的登记计数（`debugOnRegister` 挂载点一并移除）。
- **异步回调继承句柄归属**：`Timer` / `Timer.periodic` / `Future` / `Future.delayed` / `Future.microtask` / `then` / `catchError` / `whenComplete` 在创建回调时捕获当前归属（组件实例 → 其 pageKey），执行时经 `__withAsyncOwner` 恢复；异步回调里新建的 `GlobalKey` / Controller 随发起它的组件（或回退页面）释放，不再退化为永久 `global` 句柄。归属创建时固定，页面遮挡/切换不会归错；实例与页面均已销毁时不再登记并告警。
- **运行时生命周期化（阶段 1+2）**：新增 `__implement({...})` 生命周期扩展点与调度器（`__runChain` 责任链 / `__runAll` 广播，异常隔离）。`__registerHandle` / `__releaseHandle` 收敛为「去重 → 解析归属 → 写表 / 广播」，不再内联场景分支；归属策略拆为 6 个内建实现（`asyncOwnership` / `constructFrame` / `ownerAnchor` / `building` / `pageFallback` / `globalFallback`），行为与重构前等价。后续新增归属或清理场景只加功能对象，核心零改动。
- **运行时生命周期化（阶段 3：mount / unmount / 根开关）**：`__mount` 组件分支广播 `onMount`；`__markUnmounted` 不再内联清理分支，改为两段广播——`onUnmount`（自身清理、子树递归之前）与 `onUnmounted`（子树卸载之后）；`__openRoot` / `__closeRoot` 分别广播 `onRootOpen` / `onRootClose`。原有卸载清理迁移为内建实现 `componentLifecycle`（deactivate / dispose）、`scopeSubscriptions`（退订）、`inheritedDependencies`（摘依赖）、`buildContextHandle`（释放 `__ctx` 句柄）、`ownerHandles`（子树后释放实例持有的控制器 / Key），顺序与重构前一致。
- **生命周期扩展点对外**：`G.__core` 新增 `__implement`（只暴露注册，调度器 `__runAll` / `__runChain` 仍为内核私有），能力模块与 `flutter.js` 的 SDK 值类可直接注册挂载 / 卸载 / 页面根开关实现。`WidgetsBinding` 的持久帧回调不再在 `frameTick` 里逐帧判断根是否存活，改由 `onRootClose` 实现摘除本页回调；挂载失败回滚（`__abortRoot`）同样广播 `onRootClose`，挂载期注册的页面级状态不会变成无主状态。
- **EasyRefresh 迁出运行时包**：三方组件不内建。宿主桥接从 `lib/src/js_ui/capabilities/easy_refresh/` 迁到 example 的自定义能力 `example/lib/custom/easy_refresh/`（由 `registerCustomCapabilities()` 注册）；JS 类从 `flutter.js`（生成器 `js/flutter/easy_refresh_js.dart`）迁到 `example/js/easy_refresh.js`，构建期原样拷贝为 `patch/packages/easy_refresh.js`。包内不再依赖 `easy_refresh`，也不再为它生成宿主包装类。未被本次迁移改动的能力（`cached_network_image` 等）保持原路径。
- **自定义能力公开构件**：`dynamic_flutter.dart` 新增导出 `JsControllerBridge`、`curveFromJson`、`durationFromJson`、`HotPatchLog`，App 侧的第三方组件能力（含 Controller 句柄桥）无需再 import `src/` 实现文件。
- **EasyRefresh 只响应触发轴（由业务显式声明）**：桥接只透传业务传入的 `triggerAxis`，未传时沿用 package 默认（不限制方向），不补默认值。显式传 `vertical` 时用 `scrollBehaviorBuilder` 按 `ScrollMetrics.axis` 分流物理——只有触发轴继承 EasyRefresh 的刷新物理，横向滚动（banner / `PageView` / 横向列表）退回平台默认物理。包内物理经 `ScrollConfiguration` 下发到整个子树，`triggerAxis` 本身只拦「任务触发 / infinite 模式」、不拦 `applyBoundaryConditions` 里的指示器偏移，所以仅设置 `triggerAxis` 时横滑仍会出现竖排刷新文案。

## 0.4.1

**加法：补丁包 assets 覆盖；无破坏性协议变更。**

- **`HotPatchAssets` / `HotPatchAssetBundle`**：解析资源时优先读补丁包 `localRoot` 下同名文件，缺失或读取失败告警并回退 `rootBundle`；路径含 `..` / 绝对路径直接忽略并告警。补丁包切换时换新 bundle 实例，避免 `AssetImage` 缓存复用旧包图片。
- **图片接入**：`_imageProvider`（`ImageIcon` / `CircleAvatar` / `FadeInImage`）、`Image.asset`、`decorationImageFromJson` 统一传入当前补丁包的 bundle。
- **`rootBundle.loadString`**：新增宿主通道 `assetLoadString`，JS 侧同名顶层对象经该通道按同一规则读取文本资源（配套生成器 0.14.0）。
- 示例新增 `AssetOverrideDetail`（图片 + JSON），补丁包 `patch/assets/` 下放同名文件即覆盖。

## 0.4.0

**破坏性：配套生成器 0.8.0；provider 不再有宿主侧映射，`context.watch/read` 不再注册宿主 op。旧产物（含宿主 `ChangeNotifierProvider` / `Consumer` 结点）需重出补丁包。**

- 删除 `capabilities/provider/provider_bridge.dart` / `context_ops.dart`：`ChangeNotifierProvider` / `Consumer` 的状态、作用域与订阅全部在 JS 侧，宿主不再注册这两个 renderer，也不再注册 `watch/read` 的 context op。
- `ProviderLibrary` 只保留 `jsModuleAssets`（`patch/provider.js`）。
- `ChangeNotifier` 宿主镜像与 `ListenableBuilder` 监听边界保留（供 Listenable 系列组件使用）。

## 0.3.4

**破坏性：配套生成器 0.4.0，宿主挂载入口由 `__jsui.mount` 更名为 `__jsui.mountRoot`。**

- `JsUiWidget` 首次挂载改为调用 `__jsui.mountRoot(...)`；需与生成器 0.4.0 产出的 `patch/runtime.js` 配套使用。

## 0.3.3

**值对象携带的 Widget 就地下发（需与生成器 0.3.9 配套；协议只做加法）。**

- **嵌套 Widget 就地下发**：值对象字段里携带的元素描述（`{type, props, children, element: true}`）由 `JsRenderContext.element(...)`（`buildJsElement`）还原成 Flutter widget。这些子级**不进 reconciler 树**（父级每次重建重建一次，与 Flutter 每次 build 重建 items 一致），因此不需要类型表或挂载协议。
- **`BottomNavigationBar`**：`items` 从 props 读（`BottomNavigationBarItem` 已是普通值类），`icon` / `activeIcon` 就地下发；删除该类型独立的宿主 renderer 与 `_JsBottomNavItem`。
- **`DropdownButton`**：`items` 从 props 读（`DropdownMenuItem` 已是普通值类），`child` 就地下发；删除该类型独立的宿主 renderer。
- **`TextField`**：`decoration` 从 props 读（`InputDecoration` 已是普通值类），并把 `icon` / `label` / `prefixIcon` / `suffixIcon` 透传给原生 `InputDecoration`，不再丢弃这些 Widget 字段。
- **删除「数据载体类型表」**：`_dataCarrierTypes` / `registerJsDataCarrierType` / `isJsDataCarrierType` 及相关槽位分支全部移除（值对象走值类通道后已无存在意义）。

## 0.3.2

**CustomPaint 新增文字与图片绘制（只做加法：新 op、图片句柄与宿主返回值编码器均为新增，老产物行为不变；需与生成器 0.3.5 配套）。**

- **文字（`drawText`）**：JS `TextPainter` 只录制构造实参（text span / textDirection / textAlign / maxLines / ellipsis）与 `layout` 约束；宿主 `canvas_from_json.dart` 用真实 `TextPainter` 排版后绘制，字体与换行和原生一致。白名单之外的构造实参（`textScaler` / `strutStyle` / `locale` …）报错并跳过该指令，不静默用默认值。
- **文字旋转**：复用已有 `save` / `translate` / `rotate` 矩阵能力，无新协议。
- **图片（`drawImage` / `drawImageRect`）**：图片以句柄 `{__handle, width, height}` 跨桥；新增 `canvas_image_registry.dart` 维护 id ↔ `ui.Image`，`canvasImageFromJson` 按 id 还原，未知 id 报错。
- **`JsRuntimeManager.registerHostValueEncoder<T>`**：新增通用「宿主返回值编码器」缝，`_settleHost` 改为 `jsonEncode(..., toEncodable:)`；`ui.Image` 等无 JSON 形态的对象由能力库登记编码（`CanvasLibrary.ensureChannels()`）。未登记的对象沿用 Dart 默认语义（有 `toJson` 就调它，否则抛 `JsonUnsupportedObjectError`），不改老行为。
- **图片生命周期**：句柄与图片常驻进程（同 Flutter `imageCache` 语义），不随页面销毁释放；重复加载同一 URL 命中解码缓存。
- **不支持项出声**：`drawImageNine` / `drawAtlas` / `drawParagraph` 等仍在 JS 侧抛错；未知绘制指令、未知 TextPainter 属性、未知图片句柄由宿主 `HotPatchLog.error`。

## 0.3.1

**新增 Canvas 绘制重放能力（只做加法，需随 App 重新构建生效；CustomPaint 需与生成器 0.3.4 配套）。**

- **`capabilities/canvas/`**：`CanvasLibrary` 注册 `CustomPaint` renderer，支持 `painter` / `foregroundPainter` / `size` / `isComplex` / `willChange` / `child` 全量属性。
- **同步录制 → 宿主重放**：JS 侧 `CustomPainter` 以 `canvasPainter` 句柄（`sync:false`）存在；宿主 `paint` 时调 `__jsui.call(id, 'call', {method:'__record', args:[size]})` 同步取回 `{v:1, ops:[…]}`，用 `dart:ui Canvas` 逐条重放，并按 `(handle, size)` 缓存，避免每帧重复求值。
- **协议还原**：`canvas_from_json.dart` 负责 `Rect` / `RRect` / `Path` / `Paint` / 渐变 shader 与绘制枚举的 JSON 还原；`Canvas` op 覆盖 save/restore/saveLayer/translate/scale/rotate/clipRect/clipRRect/clipPath/drawRect/drawRRect/drawPath/drawLine/drawCircle/drawOval/drawArc/drawPaint。
- **不支持项出声**：未知 op、未知 Paint 属性、未知 Path 指令、`clipOp: difference` 均走 `HotPatchLog.error`，不静默丢弃；`drawImage*` / `drawParagraph` / `toImage*` 等在 JS 侧直接抛错。

## 0.3.0

**新增动画能力；JS 运行时改为构建期产物（需与生成器 0.3.0 配套）。**

- **JS 运行时迁出运行时包**：mini-react / 句柄表 / 颜色 / 动画 / 各 Controller / Key / BuildContext / provider 等全部 JS 片段改由生成器的 `ui_runtime` builder 产出 `patch/runtime.js`，运行时只负责读取与求值。**JS 侧修复随补丁发布即可生效，不再需要发版 App**；产物按 `// ===== 【n】标题 =====` 分区，便于定位。
- **`runtime.js` 支持同进程更新**：头部守卫由「已初始化即返回」改为按**内容哈希**判断——补丁包带来新版 runtime.js（哈希变化）时原地重建运行时，同哈希短路不丢状态；`invalidateModules` 同步重置初始化标记，否则新包会被旧标记挡住。
- **编译期标志改由宿主注入**：`kDebugMode` / `kReleaseMode` / `Platform.isXxx` 在求值 runtime.js 前注入全局，产物里不再烘焙具体值（构建期无从得知 App 的编译模式与平台）。
- **清单新增 `protocol`（当前 `1.0`）**：远程补丁包加载时校验主版本，与应用不匹配则拒绝挂载并留日志，避免老 App 消费新协议产物时静默错乱；清单缺少该字段的历史产物按兼容处理。
- **能力库 `jsFragments` 仅服务外部库**：内建能力的 JS 已在 runtime.js 中，该钩子恒为空；App 侧 `registerJsUiLibrary` 注册的片段在 runtime.js 之后独立求值，只能使用全局出口 `__jsui` / `_app_host_`。
- **隐式动画 / 过渡动画**：宿主注册 `AnimatedContainer` / `AnimatedOpacity` / `AnimatedPadding` / `AnimatedAlign` / `AnimatedScale` / `AnimatedRotation` / `AnimatedSlide` / `AnimatedSize` / `AnimatedSwitcher` / `AnimatedCrossFade` / `AnimatedDefaultTextStyle` / `AnimatedPositioned` 与 `FadeTransition` / `ScaleTransition` / `RotationTransition` / `SizeTransition`；插值仍由 Flutter 原生组件完成，JS 只下发 duration / curve / 目标值。
- **显式动画**：JS 侧 `AnimationController` 是镜像 + 句柄（`ctrl/Flash`），真实控制器带 Ticker 跑在宿主；`forward` / `reverse` / `repeat` / `stop` / `reset` 经通用句柄操作下发，宿主每帧把 `value` 回传到 JS 镜像，触发 `AnimatedBuilder` 等 JS 逻辑组件只重建自己的子树。
- **`AnimatedBuilder` 逻辑组件**（JS 类）：订阅 `animation`，`builder` 回调按产物协议抽成组件方法，避免逐帧整页重建。
- **JS 运行时的动画值 / 代理类**：`Curves`（成员名字符串口径）、`CrossFadeState`、`Tween`、`CurvedAnimation`、`AnimationController`；`CurvedAnimation` / Tween 下发时带 `{__handle, __curve}`，宿主按父控制器 + 同名曲线驱动。
- **公共值类迁到基础层**：`Duration` / `Size` / `Offset` / `Radius` 从动画能力移到 `capabilities/core`（新增 `DartValuesLibrary`，最先注入），后续任何能力都可直接复用；时长换算统一为 `__durationMs`。
- **JSON 还原按领域拆分**：原 `src/json/flutter_from_json.dart` 拆分到 `capabilities/core/from_json/`（公共值 / 布局 / 绘制 / 杂项枚举）、`capabilities/base_widget/`（文本样式 / ButtonStyle / IconData）、`capabilities/animation/` 与 `capabilities/tab/`，避免单文件随能力增长而臃肿；`src/json` 目录已删除。

## 0.2.2

**widget-class 协议：构造即实例 + 消费时归一化（需与生成器 0.2.3 配套）。**

- **新增 `__asElement` 归一化**：生成类与普通类一样「构造即实例」（`new CommunityPage(props)` 得到实例）；当它以子结点被消费时，`__h` / `mount` / `patch` 入口统一把实例折算成元素描述（`{type, props, children, element: true}`）。判据只看原型上有没有 `build`，不查类型名表、不需要 `toJson` / 内部 token。
- **`__h(type, props)` 不再实例化组件**：函数类型只返回元素描述；真正实例化仍只由 reconciler 的 `mount` 完成。
- **mount 复用元素携带的实例**：翻译层 `new X(props)` 产出的实例随元素下发（`el.inst`），reconciler mount 直接复用、**不再 new 第二次**；patch 复用旧实例保持状态，丢弃重建产生的新实例。构造函数里的字段初始化恢复原样。
- **props 值与数组同样归一化**：`child` / `children` / `providers` 等任意原名 prop 里的组件实例（含数组逐项）都会被折算，自定义键名不特殊处理。
- **兼容旧产物**：旧产物里的 `__h('X', props)` 与组件类构造继续按原语义工作；新产物会 `import` 生成器 0.2.3 产出的宿主包装类与 `__asElement`，需整包更新补丁。

## 0.2.1

**builder 形态判定统一为产物协议（只改运行时 Dart，需完全重启 App 生效）。**

- **删除 builder 类型白名单**：`mini_react` 不再按 `ListView` / `GridView` / `PageView` 等类型名决定是否展开子结点，只消费产物里的两个显式协议——命名构造代理类写入的 `children.__items`，以及 `delegate` 描述的 `{__delegate: 'builder', builder, childCount}`。自定义滚动容器沿用同一协议即可，无需改运行时。
- **滚动 / sliver renderer 按协议判定**：`ListView` / `GridView` / `ReorderableListView` / `SliverList` / `SliverGrid` / `PageView` 只读 `props.factory`（`builder` / `separated`）与 delegate 描述，不再按 `itemBuilder` / `builder` 等属性名猜测形态；计数按形态取 `itemCount`（命名构造）或 delegate 的 `childCount`。
- **槽位解析单点实现**：`buildJsElement` 与数据载体上下文共用 `_childrenFromSlots`，并删除旧形状兜底（children 为裸数组、元素混在 props 里）；协议以 `element: true` + `children` Map 为准。
- **数据载体可注册**：新增 `registerJsDataCarrierType(type)` / `isJsDataCarrierType(type)`，业务自定义导航项 / 下拉项等类型无需改框架源码。
- **空 builder 结果按权威处理**：`__items` 存在但为 0 项时不再回退到普通 children。

## 0.2.0

**适配生成器 0.2.0 的新产物协议；另有一项需随 App 重新构建才生效的运行时补齐。**

- **位置实参按形参名读取**：`Text` 读 `data`、`Icon` 读 `icon`、`Image` 读 `src` / `name` / `image`（由 `props.factory` 决定用 `Image.network` 还是 `Image.asset`）；`$pos` 仅作未登记类型的兜底。
- **列表 / 网格按 `props.factory` 判定形态**：读 `itemBuilder` / `separatorBuilder` / `itemCount` / `childCount`，还原 `ListView.builder` / `.separated`、`SliverList.*`、`GridView.builder`（此前 JS 侧 `ListView.builder` / `.separated` 会整块空白）；`gridDelegate` 改读 JSON 值（同时兼容平铺 props，GridView 不再退化成单列）。
- **ListenableBuilder / ValueListenableBuilder** 改为订阅 `props.listenable`（产物下发的是 listenable **实例本身**，不再是字段名）——修复 notify 不重建、`+1` 点了没反应。
- **组件（JS 类）的 `on*` 参数是可直接调用的闭包**，无需再做句柄转换。
- **事件句柄统一为构建期箭头闭包**：`__bindFn(siteId, captures, f)` 替代 `__bind(expr)`（字符串求值路径已删除）。句柄按「编译期位点号 + 捕获值」复用（对象 / 函数按引用身份比较），重建后句柄 id 稳定、循环项不串味；可等待事件（`EasyRefresh.onRefresh`）仍原样返回 Promise。
- **句柄归属对齐 Flutter 生命周期**：控制器 / Key 等句柄随**持有它的组件实例**释放——构造期（字段初始化）、`initState`、`build`、事件执行期创建的句柄记入实例 `__owns`，组件从树上摘除时整份释放并通知宿主 dispose 真实对象；无组件归属的仍随页面释放。全局 `handles` 表保留为 id 反查入口，`invoke(id)` 协议不变。
- **`Card` 缺省 margin 走 Flutter 默认**：产物未写 `margin` 时不再传 `EdgeInsets.zero`（此前会抹平 Card 默认的 `EdgeInsets.all(4)`，列表项之间没有间隙）。
- **`ReorderableListView` 支持 `scrollController` 与 `.builder`**：controller 走与 ListView 相同的滚动控制器桥接；`.builder`（itemBuilder + itemCount）还原 Flutter 原生 `ReorderableListView.builder`，按已展开子结点取项。
- **删除 `@Colors.*.shade*` 标记解析与 MaterialColor 常量表**：颜色统一 `#RRGGBB` / `#AARRGGBB`（色值已在生成器编译期算好）。
- **补齐 `Number.prototype` 的 Dart `num` 同名方法**（`round` / `floor` / `ceil` / `abs` / `truncate` / `toInt` / `toDouble` / `toStringAsFixed` / `clamp`）：Dart 写法原样翻译出 `(x * 100).round()` 后不再因 "is not a function" 让整页挂载失败。**该项属运行时 Dart 代码，需完全重启 App 才生效。**

## 0.1.1

- 补充 `repository` 字段，修复 pana 仓库校验失败导致的 pub.dev 页面无 GitHub 地址。
- `description` 改为英文，满足 pub.dev 对英文描述的要求（中文描述会被 pana 扣分）。
- README 提供中英双语，顶部可切换。

## 0.1.0

- 首个版本。
- `JsUiWidget` 宿主渲染 + JS 侧 `__jsui` 运行时（element / component / reconciler / context / commit）。
- 状态语义（provider / setState / 其它状态库）全部在 JS 侧实现，宿主不感知状态库。
- 补丁源支持 asset 路径与 http(s) zip 网络补丁包。
- `JsWidgetRegistry` 负责 JS 结点 → Flutter widget 映射，`JsUiStore` 负责增量补丁应用。
- JS → 原生能力统一走「宿主方法」：JS 侧唯一出口 `_app_host_.invoke`，宿主侧唯一入口 `registerHostMethod`（@HostInjected 方法由生成器注册，内建 log / nativeToast / jsuiCommit 自动注册）。
- 每个实例按 `pageKey` 在全局单例运行时（`JsRuntimeManager.instance`）里隔离根（结点树 / provider / 订阅 / 脏队列），支持同屏多实例。