# hot_patch_annotations

[English](#english) | [简体中文](#简体中文)

## English

Declarative annotations that mark a **completely ordinary Flutter widget** as a "dynamically shippable UI component".

Annotations are **build-time metadata only** and change nothing about the component's runtime behavior — the
widget keeps working exactly as before wherever it is referenced. When something breaks in production, the
runtime loads the matching JS version as a hot fix, with no app release needed.

### Installation

```yaml
dependencies:
  hot_patch_annotations: ^0.1.0
```

### Usage

```dart
import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

@PatchEntry('Counter')
class Counter extends StatefulWidget {
  const Counter({super.key});

  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  int _count = 0;

  void _inc() => setState(() => _count++);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('count = $_count'),
        ElevatedButton(onPressed: _inc, child: const Text('+1')),
      ],
    );
  }
}
```

The class is still a plain `StatefulWidget` and can be used directly. After adding
`hot_patch_generator` to `dev_dependencies`, `build_runner` translates it at build time into a JS module
of the same name, which the `hot_patch` runtime loads and renders through `JsUiWidget`.

### Annotations

#### `@PatchEntry()` / `@PatchEntry(name)`

Marks a class as a dynamically shippable UI component.

- `name`: the component name, **optional**; when omitted (`@PatchEntry()`) the component name is the
  **class name**. At runtime the name is passed to `JsUiWidget` through the `component` query parameter of
  `jsAsset` (e.g. `jsAsset: 'assets/patch/components/counter.js?component=Counter'`).
- Hot patching works on the **whole widget**; there are no field- or method-level annotations. The
  generator collects everything by default:
  - all non-static fields → JS state (`_count` → `count`)
  - all methods (except `build` / lifecycle) → JS event methods (bound to `this.__bind` at build time)
  - `build()` → the JS render entry point
  - SnackBar-style methods → automatically recognized as a native channel (`sendMessage`)

#### `@PatchIgnore()`

Marks a component as "excluded from transitive translation".

By default, private components declared in the same file, or un-annotated public components, that are used
inside a `@PatchEntry` component's `build`, are **transitively translated** into JS classes registered in
the same output. With this annotation:

- the generator skips the component (no JS class, no registration);
- references to it in the build tree stay as Component nodes (no import), and at runtime they are rendered
  by the native implementation registered by the app in `main()`
  (`registerNativeComponent(name, constructor)`).

Use it when a component is complex or depends on native code, and you want hot patches to always use the
native implementation.

#### `@HostInjected()` / `@HostInjected(name)`

Marks a **static method (or top-level function)** as a "host injected" capability, so it can be called from
a JS component (`@PatchEntry`).

The implementation **stays on the Dart side** (it can reach caches, the network, routing, WebView and other
native capabilities) and is **never translated into JS — it produces no JS output**. The generator only
rewrites the **call site** into a host channel call:

```dart
// Dart source: the implementation stays on the host side and is still callable directly
class AccountCenter {
  @HostInjected()                          // channel name defaults to the method name 'getUserName'
  static Future<String> getUserName() async => '22';
}

class Network {
  @HostInjected()
  static Future<Map> post({required String url, dynamic params}) async {
    return {'data': params, 'code': 200};
  }
}
```

```js
// Translated output (JS side): the call site is replaced wholesale
// AccountCenter.getUserName()   →  _app_host_.invoke("getUserName", [])
// Network.post(url: u, params: p) →  _app_host_.invoke("post", {"url": u, "params": p})
```

Key points:

- `name`: the message **channel name**, **optional**; when omitted (`@HostInjected()`) the channel name is
  the **method name**.
- **Only static methods / top-level functions work.** For an instance method the receiver on the JS side is
  a JS object and can never reach the host instance, and private declarations are not visible across
  libraries — neither takes effect even if annotated.
- **The payload follows the shape of the actual arguments**: positional only → array; named only → object;
  mixed → object plus an `"@args"` key holding the positional arguments. The host restores Dart call
  semantics with `Function.apply(fn, positional, named)`, so any number of positional/named arguments is
  fine, omitted parameters fall back to the implementation's own defaults, and the return type is
  unconstrained.
- The call returns a **Promise that can be `await`ed**; if the host implementation throws, the error is
  rethrown to the JS caller; an unregistered channel also resolves with `null`, leaving no dangling Promise.
- Dependency scanning **stops** at a `@HostInjected` class — it is not transitively translated.

Host-side registration is handled by `hot_patch_generator` automatically: it scans every `@HostInjected`
method in the package and generates all registration calls into a single Dart file
`lib/generated/host_methods.dart`, which the app calls once in `main()`:

```dart
import 'package:my_app/generated/host_methods.dart';

void main() {
  registerHostMethods();          // registers every @HostInjected channel of this package
  runApp(const MyApp());
}
```

By default registration targets `JsRuntimeManager.registerHostMethod(channel, fn)` from the companion
runtime `package:hot_patch/hot_patch.dart`, with **no configuration required**; only when swapping in a
different runtime implementation do you override `register_import` / `register_call` in your own
`build.yaml`. Arbitrary channels can also be registered manually:

```dart
JsRuntimeManager.registerHostMethod('myChannel', (String a) => ...);
```

Typical use case: most of a component should be hot-patchable, but some capability (network, routing,
WebView, a native SDK) can only run on the host.

Browse the JS actually generated for the example app online:
[example/patch/](https://github.com/JDongKhan/flutter_hot_patch/tree/main/example/patch).

### Related packages

| Package | Role |
| --- | --- |
| `hot_patch_annotations` | This package: annotations |
| `hot_patch_generator` | Translates annotated components into JS modules at build time (dev_dependency) |
| `hot_patch` | Runtime: loads and renders JS patch components, driven by JS |

---

## 简体中文

声明式注解包：把一个**完全正常的 Flutter widget** 标记为「可动态下发的 UI 组件」。

注解只是**构建期元数据**，不会改变组件的任何运行时行为——组件照旧在被引用处正常工作；
线上出问题时，再由运行时加载对应的 JS 版本做热修复，无需发版。

### 安装

```yaml
dependencies:
  hot_patch_annotations: ^0.1.0
```

### 使用

```dart
import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

@PatchEntry('Counter')
class Counter extends StatefulWidget {
  const Counter({super.key});

  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  int _count = 0;

  void _inc() => setState(() => _count++);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('count = $_count'),
        ElevatedButton(onPressed: _inc, child: const Text('+1')),
      ],
    );
  }
}
```

这个类仍然是一个普通的 `StatefulWidget`，可以直接使用。把 `hot_patch_generator`
加进 `dev_dependencies` 后，`build_runner` 会在构建期把它翻译成同名的 JS 模块，
由 `hot_patch` 的 `JsUiWidget` 在运行时加载渲染。

### 注解

#### `@PatchEntry()` / `@PatchEntry(name)`

标记一个类为可动态下发的 UI 组件。

- `name`：组件名，**可省略**；不传（写 `@PatchEntry()`）时组件名即**类名**。
  运行时通过 `JsUiWidget` 的 `jsAsset` query 参数传入
  （如 `jsAsset: 'assets/patch/components/counter.js?component=Counter'`）。
- 热更基于**整个 widget**，不做字段/方法级标注。生成器默认全量收集：
  - 所有非 static 字段 → JS 状态（`_count` → `count`）
  - 所有方法（除 build / 生命周期）→ JS 事件方法（构建期以 `this.__bind` 绑定）
  - `build()` → JS 渲染入口
  - SnackBar 形式的方法 → 自动识别为原生通道（`sendMessage`）

#### `@PatchIgnore()`

标记一个组件「不参与连带转换」。

默认情况下，`@PatchEntry` 组件 build 里用到的本文件私有组件或无注解公共组件，
会被生成器**连带翻译**成 JS 类注册进同一产物。标上本注解后：

- 生成器跳过该组件（不生成 JS 类、不注册）；
- build 树里引用它的位置保持 Component 节点（无 import），运行时由业务方在
  `main()` 里注册的原生实现渲染（`registerNativeComponent(名字, 构造)`）。

适用场景：组件逻辑复杂 / 含原生依赖，不适合翻译成 JS，希望线上热更时始终使用原生实现。

#### `@HostInjected()` / `@HostInjected(name)`

标记一个 **static 方法（或顶层函数）**为「宿主注入」（Host Injected）能力，让它在
JS 组件（`@PatchEntry`）的方法体里可以被调用。

这类方法的实现**留在 Dart 侧**（可访问缓存、网络、路由、WebView 等原生能力），
**不翻译成 JS、不产出任何 JS 产物**；生成器只在遇到调用点时，把**调用点**换成宿主通道调用：

```dart
// Dart 源码：实现留在宿主侧，照旧可直接调用
class AccountCenter {
  @HostInjected()                          // 通道名缺省 = 方法名 'getUserName'
  static Future<String> getUserName() async => '22';
}

class Network {
  @HostInjected()
  static Future<Map> post({required String url, dynamic params}) async {
    return {'data': params, 'code': 200};
  }
}
```

```js
// 翻译产物（JS 侧）：调用点被整体替换
// AccountCenter.getUserName()   →  _app_host_.invoke("getUserName", [])
// Network.post(url: u, params: p) →  _app_host_.invoke("post", {"url": u, "params": p})
```

要点：

- `name`：消息**通道名**，**可省略**；不传（写 `@HostInjected()`）时通道名即**方法名**。
- **只有 static 方法 / 顶层函数可用**。实例方法的 receiver 在 JS 侧是 JS 对象、回不到宿主
  实例，私有声明又跨库不可见——这两类标了注解也不生效。
- **参数载荷按实参形态给**：纯位置 → 数组；纯具名 → 对象；混合 → 对象 + `"@args"` 键装位置
  实参。宿主侧按 `Function.apply(fn, 位置实参, 具名实参)` 还原 Dart 调用语义，因此位置/具名
  实参个数不限、未传参数走实现自身的默认值，返回值类型也不限。
- 调用返回 **Promise，可 `await`**；宿主实现抛错时异常抛回 JS 调用者；通道未注册也会回填
  `null` 收尾，不留悬空 Promise。
- 依赖扫描遇到 `@HostInjected` 类会**直接断链**，不会连带把它翻译进产物。

宿主侧注册由 `hot_patch_generator` 自动完成：它扫描全包的 `@HostInjected` 方法，把注册调用
集中生成到一个 Dart 文件 `lib/generated/host_methods.dart`，业务在 `main()` 里调用一次即可：

```dart
import 'package:my_app/generated/host_methods.dart';

void main() {
  registerHostMethods();          // 注册本包全部 @HostInjected 通道
  runApp(const MyApp());
}
```

注册目标默认指向配套运行时 `package:hot_patch/hot_patch.dart` 的
`JsRuntimeManager.registerHostMethod(channel, fn)`，**无需任何配置**；仅当换用别的运行时实现时
才在自己的 `build.yaml` 里用 `register_import` / `register_call` 覆盖。也可以手动注册任意通道：

```dart
JsRuntimeManager.registerHostMethod('myChannel', (String a) => ...);
```

适用场景：组件大部分逻辑要热更，但涉及的能力（网络 / 路由 / WebView / 原生 SDK）只能由宿主执行。

示例 App 的实际产物（生成的 JS 文件）可在线查看：
[example/patch/](https://github.com/JDongKhan/flutter_hot_patch/tree/main/example/patch)。

### 相关包

| 包 | 作用 |
| --- | --- |
| `hot_patch_annotations` | 本包：注解 |
| `hot_patch_generator` | 构建期把注解组件静态翻译为 JS 模块（dev_dependency） |
| `hot_patch` | 运行时加载 JS 补丁渲染组件，由 JS 驱动逻辑 |

## License

MIT
