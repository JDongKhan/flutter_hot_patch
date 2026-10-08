# 统一 JS 渲染入口：保留新运行时 JsUiWidget，删除 HotPatchWidget

## Context（为什么做）

项目现在对外暴露了两个「加载生成式 JS 组件包并渲染」的入口：

- **(A) `HotPatchWidget`**：JSON 树 + `WidgetRendererRegistry`（~33 个宿主类型），支持嵌套自定义组件（`type:"Component"`）、`nativeComponents` 原生注入、多实例（`__instances[key]`）、`ListenableBuilder`、网络 zip。**当前 14 个 demo 全用它。**
- **(B) `JsUiWidget`**：`__jsui` 运行时（element/component/reconciler + 增量 patch），支持 **JS 类组件**（provider/Builder/Consumer 状态全在 JS）。只有 19 个宿主类型，不认 `Component` 节点、无 `nativeComponents`、单根（多实例串台）。**目前仅 ProviderCard / WatchDemo 用它。**

「provider 状态全在 JS」这一架构决定只有在 (B) 里成立——旧运行时的组件模型无法承载 JS 类组件。因此本例决定**统一到 (B)，删除 (A)**，一次性补齐能力并迁移全部 demo，最终只留 `JsUiWidget` 一个入口。

## 目标

1. 唯一公开入口 = `JsUiWidget`（`__jsui` 运行时）。
2. 删除 `HotPatchWidget` / `WidgetRendererRegistry` / `widget_renderer.dart` / `builtin_renderers.dart` 及配套服务。
3. 全部 14 个 demo 行为对齐（含多实例、网络 zip、nativeComponents、Listenable）。

## 需要先补齐的 4 个结构性差异

| # | 差异 | 影响 |
|---|---|---|
| 1 | JS 侧全局单例 `rootInst`/`pageKey`/`providerByType` | 同屏多 `JsUiWidget` 串台（`_TwinTest`/`_RuntimeGroupTest`/WidgetShowcase 详情） |
| 2 | (B) 缺 ~14 个宿主 type | WidgetShowcase 各详情页红占位 |
| 3 | (B) 不认 `type:"Component"` | 嵌套 `@UIComponent` / `nativeComponents` 全失效（DashboardCard 等） |
| 4 | props 里含「element 值」（`ListTile.leading/trailing`、`ClipRRect.child`） | (B) 的扁平 patch store 无法重建这些子树 |

---

## 实施步骤（按序）

### 步骤 1：生成器——嵌套组件产出构造调用

文件：`packages/ui_component_generator/lib/widget_translator.dart`、`lib/builder.dart`

- `widget_translator.dart:241` 当前 `if (type == 'Component') return jsLiteral(json, depth);`。改为：**当 `emitConstructorCalls` 且该组件名有 JS 产物（`importResolver?.call(name) != null`）时**，渲染成构造调用 `__h(Name, {…args}, [])`（复用现有构造调用/`_renderValue` 逻辑）；否则维持 `jsLiteral`（走宿主 `nativeComponents`）。
- 修复既有缺陷 `_resolveImportProduct`（`builder.dart:1247-1278`）：现在只返回**第一条**相对 import，多 import 文件会给出错误产物 → 构造调用取到 `undefined`。改为**按类名解析**：先扫描各 import 源文件收集 `类名 → 产物路径` 映射，`importResolver(name)` 查表返回。
- 跨文件组件：`_renderJs`（`builder.dart:1439-1452`）已为 `c.deps` 输出 `import { BannerCard } from '…';`——改造后该 import 由「死代码」变为真正被引用的绑定。

### 步骤 2：运行时——多根隔离

文件：`packages/hot_patch/lib/src/js_ui/runtime_source.dart`

- 把模块级单例 `pageKey` / `rootInst` / `providerByType` / `dirtySet` / `ops` 收敛为按 root 的注册表 `var roots = {};`，每项 `{ inst, providers, dirty, flushing, ops }`。
- 结点打标 `inst.__root`（HOST 与 COMP 都打）；`emit`/`commit` 写入「当前 root」（mount/patch 期间设 `activeRoot`）；`markDirty(inst)` 取 `inst.__root` 入队并 `flush(root)`；`commit(root)` 用 `root.key`。
- `findProvider`/`registerProvides`/`unregisterProvides` 改用 `inst.__root.providers`。
- `sendHost(channel, obj, key)` → `obj.key = key`。
- 入口签名统一带 root key：`mount(pageKey, moduleKey, className, propsJson)`、`dispose(pageKey)`、`invokeEvent(pageKey, expr, payload)`；删除 `setPageKey`/`getPageKey`。（`handlers` 回调表仍可全局唯一，`invoke(id,payload)` 不变。）

### 步骤 3：运行时 + store——支持「值为 element 的 props」

文件：`runtime_source.dart`、`packages/hot_patch/lib/src/js_ui/js_ui_store.dart`

- `mount` 的 HOST 分支：遍历 `el.props`，值为 element（含 `.type`）的项额外 mount，记入 `hi.__propsChildren[key]`，并 `emit({op:'propsChild', id, key, childId})`。
- `patch` HOST 分支：逐 key 复用/新建/移除（移除发 `{op:'propsChildRemove', id, key}`）；`markUnmounted` 一并卸载 `__propsChildren`。
- `JsUiNode` 增 `Map<String,String> propChildIds`；`apply` 处理两个新 op 并 `touched` 父节点；`_removeSubtree`/`_unlink` 同步清理。
- `js_ui_widget.dart` 的 `_JsNodeState.build` 把 propChildIds 对应子 widget 建好，作为 `propChildren` 传入 `JsBuildContext`。

> 这是本次最大且最易出错的改动，建议单独提交并配单测（见「测试」）。

### 步骤 4：宿主注册表补齐

文件：`packages/hot_patch/lib/src/js_ui/js_widget_registry.dart`

- `JsBuildContext` 增 `nativeComponents`、`propChildren`、`Widget? propChild(String key)`。
- 补齐缺失 type（照搬 `builtin_renderers.dart`，复用 `json/flutter_from_json.dart` 转换器）：
  - demo 必需：`Chip`、`ListTile`（title/subtitle + `propChild('leading'/'trailing')` + 事件）、`ClipRRect`（`propChild('child')`）、`Align`、`Flexible`、`Positioned`、`SingleChildScrollView`、`Wrap`、`Image`、`CircleAvatar`。
  - parity：`InkWell`/`GestureDetector`（事件 + child）、`Switch`/`Checkbox`/`Slider`（带值事件 `c.invoke(handler, newValue)`；生成产物事件键统一为 `event`）。
- **`Builder` 冲突**：不移植 `BuilderRenderer`——`Builder` 现已是 JS 逻辑组件（`builder.dart` 的 `_jsBuilderComponent`）。
- 注册 `'Component'` 处理器：`name=props.component`、`args=props.args` → `nativeComponents[name]?.call(args)`，否则 `buildMissingJsWidget`。
- **`ListenableBuilder` 改为 JS 逻辑组件**（加入 `_logicWidgetSources`），而非宿主 type：`build()` 沿 `__parent` 找拥有 `props.builder` 的组件 → `owner[props.listenable].addListener(...)`（只挂一次，`setState` 局部重建）→ `return owner[name].call(owner)`；`dispose()` 里 `removeListener`。彻底删除旧 `lbRefreshCallbacks`/`_LbNotifyService`。

### 步骤 5：宿主入口 `JsUiWidget`

文件：`packages/hot_patch/lib/src/js_ui/js_ui_widget.dart`

- `_boot`/`_invoke`/`dispose` 改用带 `pageKey` 的新签名。
- 新增参数：`entryPath`、`nativeComponents`（`props` 语义与旧 `componentArgs` 一致）。
- 网络 zip 支持：照搬 `hot_patch_widget.dart:170-191` —— `RemoteAssetLoader.isRemote(jsAsset)` → `RemoteAssetLoader.load(...)` 得 `entryJsAsset`/`localRoot` → `loadModule(entry, localRoot: …)` → `mount(pageKey, entry, …)`（`loadModule` 已支持递归相对 import 与 localRoot 回退，无需改）。

### 步骤 6：Demo 迁移

文件：`lib/main.dart`、`lib/components/widget_showcase.dart`

- `_demos` 内全部 `HotPatchWidget(...)` → `JsUiWidget(jsAsset:…, component:…, props: componentArgs, nativeComponents:…, sharedManager:…)`（约 13 处）。
- `_CompareTest` 文案 "JS 热更（HotPatchWidget）" → "JsUiWidget"。
- 网络包 demo 传 `entryPath: 'components/components/hello_component.component.js'`。
- `_TwinTest` / `_RuntimeGroupTest` 结构不变（各自独立 pageKey → 多根隔离；不同 `sharedManager`）。

### 步骤 7：删除旧路径

- 文件：`packages/hot_patch/lib/src/hot_patch_widget.dart`、`lib/src/widgets/widget_renderer.dart`、`lib/src/widgets/builtin_renderers.dart`（`widgets/` 目录随之清空）。
- 符号：`HotPatchWidget`、`RenderNode`、`WidgetRenderContext`、`WidgetRenderer`、`WidgetRendererRegistry`、`lbRefreshCallbacks`、`_SetStateService`、`_LbNotifyService`、`_LbWatchService`、`JsRuntimeManager.resolveComponentAsset` + `_componentIndex`。
- barrel `packages/hot_patch/lib/hot_patch.dart`：移除 `src/widgets/builtin_renderers.dart`、`src/hot_patch_widget.dart`、`src/widgets/widget_renderer.dart` 三条 export。
- 顺手更新仍提及旧概念的注释（`ui_component/annotations.dart`、`native_service.dart`、`builtin_services.dart`、`widget_translator.dart`）。

### 步骤 8：测试

文件：`test/widget_test.dart`

- 保留「注解元信息」「NativeService 注册」。
- 删除 renderer / `HotPatchWidget` 构造测试。
- 新增：`JsUiStore` patch 应用单测（`create/insert/move/props/remove/root/propsChild` 断言 `nodes`、`childIds`、重建回调）；`registerBuiltinJsWidgets` 的 `Text`/`Column`/`Button` 直接构造断言（不需要 JS 引擎）。

---

## 执行顺序

1. 生成器（步骤 1，含 `_resolveImportProduct` 名字解析）→ 先改生成器，产物才正确
2. 运行时多根（步骤 2）→ prop-children（步骤 3）→ 注册表 + ListenableBuilder JS 化（步骤 4）→ 宿主入口（步骤 5）
3. demo 迁移（步骤 6）
4. `dart run build_runner build --delete-conflicting-outputs`
5. 删除旧路径（步骤 7）+ `flutter analyze`
6. 测试（步骤 8）+ 手动验收

## 验证

- 命令：`dart run build_runner build --delete-conflicting-outputs`；`flutter analyze`（root + hot_patch + generator）；`flutter test`。
- 逐条点通：
  - ProviderCard「+1」→ count 增长、仅 Consumer 子树刷新
  - WatchDemo /+1/Reset → count 变化
  - ListenableDemo / NotifierCard → 仅 ListenableBuilder 子树刷新
  - `_TwinTest` 两个 BannerCard → 点 Bump 只影响被点的一个（多根隔离）
  - `_RuntimeGroupTest` 两组 → 互不影响
  - DashboardCard → BannerCard 走 JS 构造调用并行渲染；`LabeledDivider`/`_LabeledDivider` 走 `nativeComponents` 原生文本
  - HelloCard 网络 zip → 需本地 8765 起 zip server
  - WidgetShowcase 每个详情页（重点：ScrollDetail 的 `ListTile(leading: Icon)`、ImageDetail 的 `ClipRRect(child: Image)`、LayoutDetail 的 `Align/Positioned/Wrap/Chip/Flexible`、ScaffoldDetail 的 `Scaffold/AppBar/Center/SingleChildScrollView`）→ **不再出现红色占位**
- 必须真机/模拟器热重启（`__jsui` 运行时注入是幂等的，hot reload 会保留旧运行时）。

## 风险 / 待确认

- **步骤 3（prop-children）是最大风险点**：patch/move/unmount 都要覆盖，建议独立提交 + 单测。
- `_resolveImportProduct` 名字解析若不修，多 import 文件的嵌套组件会静默 `undefined`（红占位）。
- 必须先重跑 build_runner，否则旧产物里嵌套组件仍是 `Component` 节点。
- `ListenableBuilder` 的 `listenable` 若指向「非拥有者组件字段」会失效（现有 demo 均为根组件字段，保持现状即可）。
- 本轮改动量大（运行时 + 生成器 + 宿主 + 14 个 demo），回归面广，建议按上述提交粒度分批落地。

## Critical Files

- `packages/hot_patch/lib/src/js_ui/runtime_source.dart`
- `packages/hot_patch/lib/src/js_ui/js_ui_store.dart`
- `packages/hot_patch/lib/src/js_ui/js_widget_registry.dart`
- `packages/hot_patch/lib/src/js_ui/js_ui_widget.dart`
- `packages/ui_component_generator/lib/widget_translator.dart`
- `packages/ui_component_generator/lib/builder.dart`
- `packages/hot_patch/lib/hot_patch.dart`
- `lib/main.dart`、`lib/components/widget_showcase.dart`
- `test/widget_test.dart`