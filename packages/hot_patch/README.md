# hot_patch

[English](#english) | [简体中文](#简体中文)

## English

Hot update runtime: it loads build-time generated JS patches, where **JS drives the logic**, while rendering
still happens on the native Flutter side.

It targets the "bug in production → switch to a JS patch at runtime, no release needed" scenario. Components
need no changes at all: the hot-patched class stays a completely ordinary Flutter widget and its JS version is
loaded only when something goes wrong.

### Installation

```yaml
dependencies:
  hot_patch: ^0.2.1
```

### Usage

```dart
JsUiWidget(
  // The component name and the entry are both passed as query parameters
  // (convenient for operations configuration).
  jsAsset: 'assets/patch/components/counter.js?component=Counter',
)
```

`jsAsset` accepts three kinds of patch source:

- `assets/...`: a bundled asset;
- `http(s)://...zip`: a network patch bundle, downloaded and unzipped, then loaded through the same logic as
  an asset;
- another already-loaded module inside the same JS runtime.

#### Main parameters

| Parameter | Description |
| --- | --- |
| `jsAsset` | Patch entry JS (asset path, or `http(s)` zip), **required**; it carries the query `?component=<name>` (**required**, the component class name registered by the entry module) and optionally `&entry=<path/to.js>` (entry `.js` inside a network zip; when omitted it is resolved from `component`) |
| `props` | Props passed to the component constructor |
| `showBuildTime` | Debug flag: shows the patch build time in the top-right corner (from `buildTime` in `manifest.json`); it does not participate in hit testing |

The component name is not a constructor parameter — it is read from the `?component=` query of `jsAsset`, and
the query is stripped before the zip/asset is actually fetched. The host widget registry is an in-process
singleton and cannot be injected from outside.

The generated JS of the example app can be browsed online:
[example/patch/](https://github.com/JDongKhan/flutter_hot_patch/tree/main/example/patch).

### Architecture

- **Render entry**: [`JsUiWidget`] (host) plus the JS-side `__jsui` runtime
  (element / component / reconciler / context / commit protocol).
- **All state semantics live in JS**: provider / setState / any state library is implemented in JS and is
  ultimately reduced to "JS rebuilds a subtree → a patch is dispatched → the host rebuilds the affected nodes".
  Host code therefore never changes as state libraries are added — the host **understands no state semantics**.
- **The host does exactly two things**: map JS nodes to Flutter widgets (`JsWidgetRegistry`) and apply
  incremental patches (`JsUiStore`).
- **Per-instance isolation**: the runtime is a global singleton (`JsRuntimeManager.instance`; all instances
  share one engine and it cannot be injected from outside); every `JsUiWidget` instance isolates its own root
  (node tree / provider / subscriptions / dirty queue) inside it by `pageKey`, so multiple instances on screen
  do not affect each other. Note that the **module registry (`__modules`) is runtime-global**: a fresh remote
  bundle invalidates loaded modules for every page, so two pages must not depend on different versions of the
  same module path.
- **Rendering extension points**: `registerNativeComponent(type, build)` for native widget implementations and
  `registerJsDataCarrierType(type)` for non-widget data carriers (custom nav items / dropdown items) — both are
  global, one-time registrations before `runApp`.

### Extension: JS → native capabilities

Everything goes through a "host method": on the JS side the only exit is `_app_host_.invoke(channel, args)`
(returns a Promise, usable with `await`); on the host side the only entry is
`JsRuntimeManager.registerHostMethod(channel, impl)`. The `{id, args}` sent from JS is restored to Dart call
semantics (positional/named arguments, defaults) before execution, and the return value is written back to the
Promise through `_app_host_.resolve`; if the host implementation throws, the error is rethrown to the JS caller
through `_app_host_.reject`; an unregistered channel also resolves with `null`, leaving no dangling Promise.

Business methods are annotated with `@HostInjected()` and collected and registered by the generator
automatically; the framework's built-in channels (`log` / `nativeToast` / `jsuiCommit`) are registered
automatically when `JsUiWidget` starts.

```dart
@HostInjected()
static String greet(String name) => 'Hi, $name';
```

```dart
// Or register an arbitrary channel manually
JsRuntimeManager.registerHostMethod('myChannel', (String a) => ...);
```

### Logging

All output of this package goes through the single exit `HotPatchLog`
(levels: `debug` / `info` / `warn` / `error`). Local printing and reporting are **independent of each other** —
register a `sink` to pipe everything into your logging platform:

```dart
HotPatchLog.sink = (r) => MyLogPlatform.upload(
      level: r.level.name,
      message: r.message,
      error: r.error,
      stack: r.stackTrace,
      time: r.time,
    );
HotPatchLog.minSinkLevel = HotPatchLevel.warn; // default: only warn/error are reported
HotPatchLog.enabled = false; // only turns off local printing (default kDebugMode); reporting is unaffected
```

`console.*` inside the JS output is bridged to the same exit with levels (`error` / `warn` / `info` / `debug`;
the host prefixes them with `[js-log] `). For the full level description and typical sources see
[使用手册 §4.3](../../docs/使用手册.md).

### Related packages

| Package | Role |
| --- | --- |
| `hot_patch_annotations` | Annotations |
| `hot_patch_generator` | Translates annotated components into JS modules at build time (dev_dependency) |
| `hot_patch` | This package: loads and renders JS patch components at runtime, driven by JS |

---

## 简体中文

热更新运行时：加载构建期生成的 JS 补丁，**由 JS 驱动逻辑**，渲染仍发生在原生 Flutter 侧。

面向「线上出 bug → 运行时切到 JS 补丁修复，无需发版」的场景。组件不需要做任何改造：
被热更的类始终是一个完全正常的 Flutter widget，出问题时才加载它的 JS 版本。

### 安装

```yaml
dependencies:
  hot_patch: ^0.2.1
```

### 使用

```dart
JsUiWidget(
  // 组件名与入口都走 query 参数（方便运营配置）
  jsAsset: 'assets/patch/components/counter.js?component=Counter',
)
```

`jsAsset` 支持三种补丁源：

- `assets/...`：随包资源；
- `http(s)://...zip`：网络补丁包，下载解压后走与 asset 一致的加载逻辑；
- 同一 JS 运行时里的其它已加载模块。

#### 主要参数

| 参数 | 说明 |
| --- | --- |
| `jsAsset` | 补丁入口 JS（asset 路径或 `http(s)` zip），**必填**；可带 query `?component=<组件名>`（**必填**，入口模块里注册的组件类名），以及可选的 `&entry=<path/to.js>`（网络 zip 内入口 `.js` 的相对路径，不传则按 `component` 反查） |
| `props` | 传给组件构造的 props |
| `showBuildTime` | 调试开关：右上角显示补丁打包时间（取自 `manifest.json` 的 `buildTime`），不参与命中测试 |

组件名**不是构造参数**，而是从 `jsAsset` 的 `?component=` query 读取，且请求 zip / asset 前会剥离 query。
宿主 widget 注册表是进程内单例，不从外部注入。

示例 App 的实际产物（生成的 JS 文件）可在线查看：
[example/patch/](https://github.com/JDongKhan/flutter_hot_patch/tree/main/example/patch)。

### 架构

- **渲染入口**：[`JsUiWidget`]（宿主）+ JS 侧的 `__jsui` 运行时
  （element / component / reconciler / context / commit 协议）。
- **状态语义全在 JS 侧**：provider / setState / 任何状态库都在 JS 里实现，
  最终都归约为「JS 重建子树 → 下发 patch → 宿主重建受影响结点」。
  因此宿主代码不随状态库增加而改动——宿主**不理解任何状态语义**。
- **宿主只做两件事**：JS 结点 → Flutter widget 映射（`JsWidgetRegistry`）、
  增量补丁应用（`JsUiStore`）。
- **多实例隔离**：运行时是全局单例（`JsRuntimeManager.instance`，所有实例共用一个引擎，
  不从外部注入）；每个 `JsUiWidget` 实例按 `pageKey` 在其中隔离自己的根
  （结点树 / provider / 订阅 / 脏队列），同屏多实例互不影响。注意：**模块注册表
  `__modules` 是运行时全局的**——任一远程包 fresh 会清空全部页面已加载的模块，因此
  两个页面不能依赖同一模块路径的不同版本。
- **渲染扩展点**：`registerNativeComponent(type, build)` 注册原生 widget 实现；
  `registerJsDataCarrierType(type)` 注册非 Widget 数据载体（自定义导航项 / 下拉项）。
  两者都是全局一次性注册，放在 `runApp` 之前。

### 扩展：JS → 原生能力

统一走「宿主方法」：JS 侧唯一出口 `_app_host_.invoke(channel, args)`（返回 Promise，
可用 `await`），宿主侧唯一入口 `JsRuntimeManager.registerHostMethod(channel, impl)`。
JS 传来的 `{id, args}` 按 Dart 调用语义（位置/具名实参、默认值）还原后执行，
返回值经 `_app_host_.resolve` 回填 Promise；宿主实现抛错则经 `_app_host_.reject`
把异常抛回 JS 调用者；通道未注册也会回填 `null` 收尾（不留悬空 Promise）。

业务方法用 `@HostInjected()` 注解，由生成器自动收集并注册；框架内建通道
（`log` / `nativeToast` / `jsuiCommit`）在 `JsUiWidget` 启动时自动注册。

```dart
@HostInjected()
static String greet(String name) => 'Hi, $name';
```

```dart
// 或手动注册任意通道
JsRuntimeManager.registerHostMethod('myChannel', (String a) => ...);
```

### 日志

包内所有输出走唯一出口 `HotPatchLog`（级别：`debug` / `info` / `warn` / `error`）。
本地打印与上报**彼此独立**——注册 `sink` 即可统一接入日志平台：

```dart
HotPatchLog.sink = (r) => MyLogPlatform.upload(
      level: r.level.name,
      message: r.message,
      error: r.error,
      stack: r.stackTrace,
      time: r.time,
    );
HotPatchLog.minSinkLevel = HotPatchLevel.warn; // 默认：只上报 warn/error
HotPatchLog.enabled = false; // 只关本地打印（默认 kDebugMode），不影响上报
```

JS 产物里的 `console.*` 也桥到同一出口且带级别（`error` / `warn` / `info` / `debug`，
宿主侧带 `[js-log] ` 前缀）。完整级别说明与典型来源见
[使用手册 §4.3](../../docs/使用手册.md)。

### 相关包

| 包 | 作用 |
| --- | --- |
| `hot_patch_annotations` | 注解 |
| `hot_patch_generator` | 构建期把注解组件静态翻译为 JS 模块（dev_dependency） |
| `hot_patch` | 本包：运行时加载 JS 补丁渲染组件，由 JS 驱动逻辑 |

## License

MIT
