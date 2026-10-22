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