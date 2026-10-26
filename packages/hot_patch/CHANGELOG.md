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