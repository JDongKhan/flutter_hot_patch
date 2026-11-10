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
  hot_patch: ^0.4.0
```

### Requirements & limitations

#### Environment / platform

| Item | Requirement |
| --- | --- |
| Dart SDK | `^3.11.5` |
| Flutter | `>=3.38.4` (developed & verified on `3.41.8`, see `.fvmrc`) |
| Android | Supported. Engine: QuickJS (bundled, `minSdk 21`; the app itself uses `flutter.minSdkVersion`). ABI (flutter_js `abiFilters`): `armeabi-v7a` / `arm64-v8a` / `x86` / `x86_64` |
| iOS | Supported. JavaScriptCore; ES2020 output syntax requires **iOS 15+** as the effective minimum (flutter_js podspec itself declares iOS 8.0) |
| macOS | Supported for development / debugging (JavaScriptCore; example sets `10.15`) |
| Windows / Linux | Not verified (flutter_js declares these platforms, but this package has not validated them) |
| Web | **Not supported** (flutter_js is a native FFI engine; the host uses `dart:io` for downloads / files) |

JS engine baseline: ES2020 + partial ES2021 (iOS 15+ JSC / Android QuickJS 2021-03-27).
`Object.hasOwn`, `.at`, `findLast`, `static {}` blocks, top-level `await`, `structuredClone`,
`WeakRef` are **unavailable** in the engines. See
[组件支持文档 §7](../../docs/组件支持文档.md) for the full baseline.

#### Usage limitations (hard constraints)

1. **Build-time static translation is required.** JS is not written by hand: annotate widgets with
   `@PatchEntry` and run `build_runner` (with `hot_patch_generator`) to generate the `patch/` output.
   The entry component name must be passed via `?component=` in `jsAsset`.
2. **The runtime is a process-wide singleton** (`JsRuntimeManager.instance`): multiple `JsUiWidget`
   instances share one engine and one global module registry (`__modules`). A fresh remote bundle
   invalidates loaded modules of **every** page — two pages must not depend on different versions of
   the same module path. Creating extra engines is not supported.
3. **Protocol major must match.** The runtime refuses patch bundles whose `manifest.json` `protocol`
   major version differs from what the app supports; after upgrading `hot_patch` across a major
   version, patches must be rebuilt with the matching `hot_patch_generator`.
4. **Rendering is limited to the supported widget / API matrix.** Widgets without a host renderer
   need `registerNativeComponent(name, build)`; `Image.memory` / dynamic bytes, `SnackBar`,
   `showMenu` / `showSearch` / date pickers, `RadioGroup`, `Container.transform`, synchronous-return
   callbacks (`DragTarget.onWillAccept*`), `Theme.of(context)` value reads etc. are **not supported**
   (full list: [组件支持文档 §6](../../docs/组件支持文档.md)). Uncovered Dart syntax fails with a
   build-time warning instead of a silent fallback. Deprecated Flutter APIs are not supported.
5. **The patch does not execute arbitrary Dart.** Only statically translated JS runs in the engine;
   no `dart:mirrors` / no dynamic Dart evaluation. Native capabilities must be bridged through
   `@HostInjected` / `registerHostMethod` (async channel calls).
6. **Remote patches need network & zip.** `http(s)://...zip` bundles are downloaded, unzipped and
   cached under the app documents directory; offline first launch must fall back to bundled assets.

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
- **Rendering extension point**: `registerNativeComponent(type, build)` for native widget implementations —
  a global, one-time registration before `runApp`. Item/config value objects (`InputDecoration`,
  `BottomNavigationBarItem`, `DropdownMenuItem`, …) need no registration: they are ordinary JS value classes and
  their nested widgets are materialized in place by the parent renderer.

### Extension: JS → native capabilities

Everything goes through a "host method": on the JS side the only exit is `_app_host_.invoke(channel, args)`
(returns a Promise, usable with `await`); on the host side the only entry is
`JsRuntimeManager.registerHostMethod(channel, impl)`. The `{id, args}` sent from JS is restored to Dart call
semantics (positional/named arguments, defaults) before execution, and the return value is written back to the
Promise through `_app_host_.resolve`; if the host implementation throws, the error is rethrown to the JS caller
through `_app_host_.reject`; an unregistered channel also resolves with `null`, leaving no dangling Promise.

Business methods are annotated with `@HostInjected()` and collected and registered by the generator
automatically (the class is still translated; only the annotated method body becomes the channel call, so
call sites stay 1:1 with Dart); the framework's built-in channels (`log` / `nativeToast` / `jsuiCommit`)
are registered automatically when `JsUiWidget` starts.

```dart
class HostGreeter {
  @HostInjected()
  static String greet(String name) => 'Hi, $name';
}
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

Dart's `print` / `debugPrint` are translated 1:1 to same-named JS globals and bridged to
the same exit with levels (`info` / `debug`; `debugPrint` only emits in kDebugMode). The host
prefixes them with `[js-log] `. For the full level description and typical sources see
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
  hot_patch: ^0.4.0
```

### 支持范围与使用限制

#### 环境 / 平台

| 项 | 要求 |
| --- | --- |
| Dart SDK | `^3.11.5` |
| Flutter | `>=3.38.4`（开发与验证环境为 `3.41.8`，见 `.fvmrc`） |
| Android | 支持。引擎：QuickJS（内置，`minSdk 21`；应用本身用 `flutter.minSdkVersion`）。ABI（flutter_js `abiFilters`）：`armeabi-v7a` / `arm64-v8a` / `x86` / `x86_64` |
| iOS | 支持。引擎：JavaScriptCore；产物为 ES2020 语法，**有效最低 iOS 15+**（flutter_js podspec 自身声明 iOS 8.0） |
| macOS | 支持（开发 / 调试；引擎 JavaScriptCore，example 设为 `10.15`） |
| Windows / Linux | 未验证（flutter_js 声明了这两个平台，但本包未实测） |
| Web | **不支持**（flutter_js 是原生 FFI 引擎；宿主下载 / 文件走 `dart:io`） |

JS 引擎基线：ES2020 + 部分 ES2021（iOS 15+ JSC / Android QuickJS 2021-03-27）。
引擎**未实现** `Object.hasOwn`、`.at`、`findLast`、`static {}` 块、top-level `await`、
`structuredClone`、`WeakRef`，产物与运行时均禁止使用。
完整基线见 [组件支持文档 §7](../../docs/组件支持文档.md)。

#### 使用限制（硬约束）

1. **必须构建期静态翻译**。JS 不手写：组件加 `@PatchEntry` 注解后跑 `build_runner`
   （配 `hot_patch_generator`）生成 `patch/` 产物；入口组件名必须经 `jsAsset` 的
   `?component=` 传入。
2. **运行时是进程级单例**（`JsRuntimeManager.instance`）：多个 `JsUiWidget` 共用一个引擎与
   全局模块注册表（`__modules`）。任一远程包 fresh 会清空**全部页面**已加载的模块——两个页面
   不能依赖同一模块路径的不同版本；不允许另建引擎实例。
3. **协议主版本必须匹配**。运行时拒绝 `manifest.json` 中 `protocol` 主版本与应用不支持的包；
   `hot_patch` 跨主版本升级后，必须用配套的 `hot_patch_generator` 重新生成补丁。
4. **渲染受组件 / API 支持矩阵限制**。宿主无 renderer 的 widget 需 `registerNativeComponent(name, build)`
   注册；`Image.memory` / 动态字节、`SnackBar`、`showMenu` / `showSearch` / 日期选择器、`RadioGroup`、
   `Container.transform`、需同步返回值的回调（`DragTarget.onWillAccept*`）、`Theme.of(context)` 取值等
   **均不支持**（完整清单见 [组件支持文档 §6](../../docs/组件支持文档.md)）。未覆盖的 Dart 写法
   构建期告警，不做静默兜底；Flutter 废弃 API 不支持。
5. **补丁不执行任意 Dart**。引擎里只跑静态翻译出的 JS，无 `dart:mirrors` / 无动态 Dart 求值；
   原生能力必须经 `@HostInjected` / `registerHostMethod` 桥接（通道调用为异步）。
6. **远程补丁依赖网络与 zip**。`http(s)://...zip` 包下载解压后缓存到应用文档目录；
   离线首启必须回退到随包 asset。

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
- **渲染扩展点**：`registerNativeComponent(type, build)` 注册原生 widget 实现，
  全局一次性注册，放在 `runApp` 之前。条目 / 配置类值对象
  （`InputDecoration` / `BottomNavigationBarItem` / `DropdownMenuItem` …）无需登记：
  它们是普通 JS 值类，携带的 Widget 由父 renderer 就地还原。

### 扩展：JS → 原生能力

统一走「宿主方法」：JS 侧唯一出口 `_app_host_.invoke(channel, args)`（返回 Promise，
可用 `await`），宿主侧唯一入口 `JsRuntimeManager.registerHostMethod(channel, impl)`。
JS 传来的 `{id, args}` 按 Dart 调用语义（位置/具名实参、默认值）还原后执行，
返回值经 `_app_host_.resolve` 回填 Promise；宿主实现抛错则经 `_app_host_.reject`
把异常抛回 JS 调用者；通道未注册也会回填 `null` 收尾（不留悬空 Promise）。

业务方法用 `@HostInjected()` 注解，由生成器自动收集并注册（类照常翻译，只有被标注方法的
方法体换成通道调用，故调用点与 Dart 一比一）；框架内建通道
（`log` / `nativeToast` / `jsuiCommit`）在 `JsUiWidget` 启动时自动注册。

```dart
class HostGreeter {
  @HostInjected()
  static String greet(String name) => 'Hi, $name';
}
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

Dart 的 `print` / `debugPrint` 在 JS 侧是一比一同名全局函数，桥到同一出口且带级别
（`info` / `debug`，`debugPrint` 仅 kDebugMode 输出；宿主侧带 `[js-log] ` 前缀）。
完整级别说明与典型来源见 [使用手册 §4.3](../../docs/使用手册.md)。

### 相关包

| 包 | 作用 |
| --- | --- |
| `hot_patch_annotations` | 注解 |
| `hot_patch_generator` | 构建期把注解组件静态翻译为 JS 模块（dev_dependency） |
| `hot_patch` | 本包：运行时加载 JS 补丁渲染组件，由 JS 驱动逻辑 |

## License

MIT
