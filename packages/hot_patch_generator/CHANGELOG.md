## 0.3.3

**产物按归属拆分（协议不变：补丁通道 / patch ops / 句柄信封一致，可与 `hot_patch` 0.3.0 搭配）。**

- `runtime.js` 只留语言层 + mini-react 核心 + 通用缝（作用域查找 / BuildContext 代理 / 独立根挂载 / 宿主桥），不再含任何库或 Flutter SDK 的 API 面。
- provider 的自有登记（`registerScope('ChangeNotifierProvider')` + `JsBuildContext.prototype.watch/read`）移进它的**包模块** `patch/provider.js`（生成器 `provider_module_js.dart`，由 `widget_module_builder` 的 `_packageModuleEpilogues` 追加）；`context.watch/read` 的对齐结论不变。
- `showDialog` 系列（dialog / adaptive / general / cupertino / sheet / cupertinoSheet）连同面板独立根机制（`openPanel` / `panelMount` / `panelClosed` / `panelPop` / `panelOf`）与 `Navigator` 移到 `patch/flutter.js`（`dialogs_js.dart` / `navigator_js.dart`），从 `export function` 导出：产物按名 import 后裸调用，与 Dart 一比一。`__jsui.panelMount` / `panelClosed` 由该模块求值时安装（宿主调用点已有存在性守卫）。
- `G.__core` 交接面补齐：作用域机制、结点归属、独立根 mount/unmount/commit，以及 `building` / `activeRoot` 的访问器（闭包 var 必须实时读写）。
- **命名构造改为 1:1 发射**：翻译层不再往 `props` 写 `factory`，而是把构造名作为结点中间态（`ctor`）只用于发射 `X.b({...})`（`SizedBox.shrink(...)` / `Image.network(...)` / `ListView.separated(...)` / `ChangeNotifierProvider.value(...)`）。JS 没有 Dart 的命名构造，故 `flutter.js` 的包装类与逻辑组件对每个源码构造名生成**同名静态方法**，由静态方法把构造名写进 `props.factory`——宿主仍只按 `props.factory` 选原生工厂，协议不变。

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