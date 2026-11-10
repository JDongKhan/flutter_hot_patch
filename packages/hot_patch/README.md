# hot_patch

[简体中文](https://github.com/JDongKhan/flutter_hot_patch/blob/main/packages/hot_patch/README_ZH.md)

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
[Widget Support Reference §7](https://github.com/JDongKhan/flutter_hot_patch/blob/main/docs/组件支持文档.md) for the full baseline.

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
   (full list: [Widget Support Reference §6](https://github.com/JDongKhan/flutter_hot_patch/blob/main/docs/组件支持文档.md)). Uncovered Dart syntax fails with a
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
[User Manual §4.3](https://github.com/JDongKhan/flutter_hot_patch/blob/main/docs/使用手册.md).

### Related packages

| Package | Role |
| --- | --- |
| `hot_patch_annotations` | Annotations |
| `hot_patch_generator` | Translates annotated components into JS modules at build time (dev_dependency) |
| `hot_patch` | This package: loads and renders JS patch components at runtime, driven by JS |

## License

MIT
