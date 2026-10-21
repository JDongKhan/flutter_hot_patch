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