# hot_patch_annotations

[简体中文](https://github.com/JDongKhan/flutter_hot_patch/blob/main/packages/hot_patch_annotations/README_ZH.md)

Declarative annotations that mark a **completely ordinary Flutter widget** as a "dynamically shippable UI component".

Annotations are **build-time metadata only** and change nothing about the component's runtime behavior — the
widget keeps working exactly as before wherever it is referenced. When something breaks in production, the
runtime loads the matching JS version as a hot fix, with no app release needed.

### Installation

```yaml
dependencies:
  hot_patch_annotations: ^0.1.5
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
  - all non-static fields → JS instance state (the field name is kept as-is: `_count` → `_count`)
  - all methods (except `build` / lifecycle) → JS methods that events invoke
    (`this.__bindFn(siteId, captures, arrowClosure)` — every event is translated to a build-time arrow
    closure, so it captures build locals exactly like a Dart closure)
  - `build()` → the JS render entry point
  - SnackBar-style methods → automatically recognized as a native channel
    (`_app_host_.invoke('nativeToast', {message})`)

#### `@PatchIgnore()`

Marks a component as "excluded from transitive translation".

By default, private components declared in the same file, or un-annotated public components, that are used
inside a `@PatchEntry` component's `build`, are **transitively translated** into JS classes registered in
the same output. With this annotation:

- the generator skips the component (no JS class, no registration);
- references to it in the build tree keep their **concrete type name** as the node type (no import, no
  degrading to a generic `Component` placeholder); at runtime they are rendered by the native implementation
  registered by the app in `main()` (`registerNativeComponent(name, constructor)`).

Use it when a component is complex or depends on native code, and you want hot patches to always use the
native implementation.

#### `@HostInjected()` / `@HostInjected(name)`

Marks a **static method (or top-level function)** as a "host injected" capability, so it can be called from
a JS component (`@PatchEntry`).

The implementation **stays on the Dart side** (it can reach caches, the network, routing, WebView and other
native capabilities). For a class method the class itself is still translated into a same-named JS class
and the annotated method still exists on it — only the **method body** becomes a host channel call.
Call sites stay **1:1 with Dart**:

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
// Translated output (JS side)
//   class AccountCenter { static async getUserName() { return _app_host_.invoke("getUserName", ...); } }
//   class Network       { static async post(...)       { return _app_host_.invoke("post", ...); } }
// Call sites are unchanged:
//   AccountCenter.getUserName()      →  AccountCenter.getUserName()
//   Network.post(url: u, params: p)  →  Network.post({"url": u, "params": p})
```

Key points:

- `name`: the message **channel name**, **optional**; when omitted (`@HostInjected()`) the channel name is
  the **method name**.
- **Only static methods / top-level functions work.** For an instance method the receiver on the JS side is
  a JS object and can never reach the host instance, and private declarations are not visible across
  libraries — neither takes effect even if annotated.
- **A host-injected class only exposes the class and its annotated methods** in JS; its fields, other
  methods and imports are not emitted (they only serve the host implementation).
- **Top-level functions are the one exception**: they have no JS class to carry them, so the call site itself
  is translated into a channel call.
- **The payload follows the shape of the actual arguments**: positional only → array; named only → object;
  mixed → object plus an `"@args"` key holding the positional arguments. The host restores Dart call
  semantics with `Function.apply(fn, positional, named)`, so any number of positional/named arguments is
  fine, omitted parameters fall back to the implementation's own defaults, and the return type is
  unconstrained.
- The call returns a **Promise that can be `await`ed**; if the host implementation throws, the error is
  rethrown to the JS caller; an unregistered channel also resolves with `null`, leaving no dangling Promise.
- Dependency scanning skips the **body** of an `@HostInjected` method, so types only used there are not
  transitively translated.

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

## License

MIT
