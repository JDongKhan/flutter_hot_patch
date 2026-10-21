## 0.2.0

**适配生成器 0.2.0 的新产物协议；另有一项需随 App 重新构建才生效的运行时补齐。**

- **位置实参按形参名读取**：`Text` 读 `data`、`Icon` 读 `icon`、`Image` 读 `src` / `name` / `image`（由 `props.factory` 决定用 `Image.network` 还是 `Image.asset`）；`$pos` 仅作未登记类型的兜底。
- **列表 / 网格按 `props.factory` 判定形态**：读 `itemBuilder` / `separatorBuilder` / `itemCount` / `childCount`，还原 `ListView.builder` / `.separated`、`SliverList.*`、`GridView.builder`（此前 JS 侧 `ListView.builder` / `.separated` 会整块空白）；`gridDelegate` 改读 JSON 值（同时兼容平铺 props，GridView 不再退化成单列）。
- **ListenableBuilder / ValueListenableBuilder** 改为订阅 `props.listenable`（产物下发的是 listenable **实例本身**，不再是字段名）——修复 notify 不重建、`+1` 点了没反应。
- **组件（JS 类）的 `on*` 参数是可直接调用的闭包**，无需再做句柄转换。
- **事件句柄统一为构建期箭头闭包**：`__bindFn(siteId, captures, f)` 替代 `__bind(expr)`（字符串求值路径已删除）。句柄按「编译期位点号 + 捕获值」复用（对象 / 函数按引用身份比较），重建后句柄 id 稳定、循环项不串味；可等待事件（`EasyRefresh.onRefresh`）仍原样返回 Promise。
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