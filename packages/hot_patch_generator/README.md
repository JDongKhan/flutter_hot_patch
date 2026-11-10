# hot_patch_generator

[简体中文](https://github.com/JDongKhan/flutter_hot_patch/blob/main/packages/hot_patch_generator/README_ZH.md)

Translates Flutter widgets annotated with `@PatchEntry` **statically** into JS modules at build time, so the
`hot_patch` runtime can hot-patch and render them.

It parses sources statically with `analyzer`, **never executes any Dart code**, and requires no changes to the
component: the translated class stays a completely ordinary Flutter widget.

### Installation

```yaml
dev_dependencies:
  hot_patch_generator: ^0.13.0
  build_runner: ^2.4.13
```

Then run this at the project root:

```sh
dart run build_runner build --delete-conflicting-outputs
```

### Output

The `patch/` output directory **mirrors** the `lib/` source paths one-to-one, and file names match the Dart
source file names:

| Source | Output | Notes |
| --- | --- | --- |
| `lib/components/counter.dart` | `patch/components/counter.js` | Component output containing `@PatchEntry` |
| `lib/model/user.dart` | `patch/model/user.js` | Plain classes / static singletons (`export class` / `export const`) |
| (package-root pseudo asset `$package$`) | `patch/flutter.js` | Package module: `Component` base + host-widget wrapper classes + value classes + JS logic-component / builder-proxy classes, **one file per package** |
| `js/<package>.js` (host-maintained third-party JS) | `patch/packages/<package>.js` | Third-party library JS lives in the host project's `js/` directory (file name = Dart package name) and is copied verbatim by `ui_third_party_js` (filesystem scan, no `build.yaml` changes needed). Business outputs import it as `../packages/<package>.js` |
| (package-root pseudo asset `$package$`) | `patch/runtime.js` | The whole JS runtime (mini-react, handle registry, capability fragments) as one file, sections separated by `// ===== 【n】… =====`. Shipped with the patch, so JS fixes never need an app release. Its content hash is baked into `G.__jsuiVersion`; a new hash rebuilds the runtime in place |
| (package-root pseudo asset `$package$`) | `patch/manifest.json` | Patch manifest: basic info + **artifact protocol version** (`protocol`, currently `0.13.0`) + build time + content hash of every JS asset. The runtime refuses bundles whose protocol **major** differs from what the app supports |

- Splitting is driven by **file content + reference reachability** (not by directory): a file containing
  `@PatchEntry` classes is a root file and emits those components; otherwise only classes actually referenced
  by a reachable class are emitted (model / singleton output, `export class` / `export const`); a file with
  only top-level constants emits those constants; files neither reachable nor referenced emit nothing.
- Package-level modules (`patch/<package>.js`) and the manifest hang off the package-root pseudo asset
  `$package$`: the input is the whole package and the output path is static, so **users need no seed file and
  no configuration** — just depend on this package and run `build_runner`.
- `patch/flutter.js` defines the `Component` base and generates **same-named wrapper classes**
  for host widgets (`Text`, `Column`, …) and data carriers (`InputDecoration`). Component outputs emit
  `new Text({...})`; the wrapper instance is itself the host element (`__host=true`), and the base
  constructor splits props into props / `__children`. Other modules import the classes they use.
  Component instances created with `new X(props)` are elements; nested widgets inside value objects are
  normalized to descriptors by `__descriptorOf`.

Browse the JS actually generated for the example app online:
[example/patch/](https://github.com/JDongKhan/flutter_hot_patch/tree/main/example/patch).

> Note: Flutter's directory asset declaration is **not recursive**, so every output path must be declared
> explicitly in `pubspec.yaml` under `assets:` (per directory or per file).

### Configuration

`ui_widget` (package modules), `ui_runtime` (the JS runtime) and `patch_entry` (component/model outputs)
**read no options**. The options of the remaining two builders are all optional and work out of the box:

```yaml
targets:
  $default:
    builders:
      # Target runtime of the host-injection registration output
      # (lib/generated/host_methods.dart); only override when swapping in another runtime.
      hot_patch_generator:ui_host_register:
        options:
          register_import: "package:<runtime>/<runtime>.dart"
          register_call: "<Runtime>.registerHostMethod"
      # Basic info in patch/manifest.json; by default the package name / no version.
      hot_patch_generator:ui_patch_manifest:
        options:
          name: my_app
          version: 1.2.3
```

### Translation design principles

The output must correspond to the Dart source **one-to-one**; this is the core constraint of the framework:

1. **Legal Dart constructs should be statically translated, not worked around.** When you meet an unknown
   syntax form, add a proper translation branch (mapped one-to-one onto equivalent JS — expression/statement
   translation lives in `translator/js_translator.dart`, class rendering in `translator/dart2js.dart`) instead
   of asking users to change their Dart to fit the framework. Current uncovered forms are reported at build
   time and degrade to a placeholder node; that placeholder is a diagnostic fallback, **not** the intended
   long-term behavior (see "Known limitations" in the component-support doc). All translation has a single
   implementation shared by components and plain classes.
2. **No temporary workarounds.** When something fails, do not bypass it in the demo with temporary fields or
   shim layers (e.g. adding a mirror trigger field just because setState has no diff); the JS output must map
   line-by-line onto the Dart source — fix the translation path itself.
3. **Capabilities are isolated per file.** When adding a runtime capability (e.g. ScrollController /
   TextEditingController id-bridge), put it on the host side as a separate file under
   `hot_patch/lib/src/js_ui/capabilities/` and **do not touch the `js_widget_registry` / `js_ui_widget` core**;
   the capability's JS lives in `builders/runtime/js/` here and ships inside `patch/runtime.js`.
4. **Defaults match Flutter 100%.** When the host renders, nullable properties stay `null` by default; never
   default them to `0` / `EdgeInsets.zero` etc. and override Flutter theme defaults.
5. **Registration keys match class names.** The key in the host's `r.register('X', ...)` must have the same name
   as the type string in the JS output; no aliases.

### Extension: adding widget support

There is **no per-widget translator**: every widget — built-in, custom or third-party — goes through the
single translation path (`lib/src/builders/patch_entry/translator/element_json.dart`), which dispatches on

- **output protocol**: build trees are emitted as `new Type(props)`. Host widgets / data carriers use the
  wrapper classes exported by `flutter.js`; custom components, logic components and builder proxies use
  the classes exported by their own outputs. All Dart arguments go into props under their original names;
  `child` / `children` / `slivers` / `tabs` are **ordinary named props**; host wrapper classes split them
  at construction time (`Component.__splitHost`) by **value shape** — element values / element arrays /
  `__builder` / delegate descriptors move into `__children` under their original names, regardless of the
  key name;
- **construct-as-element**: generated classes follow plain-class semantics (`new X(props)` yields an
  element instance marked `__element`, with `__type`; host wrappers set `__host=true`). The reconciler
  only checks `__element`; it does not guess components from a prototype `build`. Value objects are
  normalized to descriptors by `__descriptorOf` when their nested widgets cross the bridge. Translation
  therefore no longer asks "is this class a widget"; it only excludes known model classes and value objects;
- **value shapes** (`lib/src/builders/patch_entry/translator/value_forms.dart`): literals, constructors, static factories,
  constant references (enums / colors / icons), lists, closures — structured style values are runtime
  classes in `lib/src/builders/runtime/js/style_values_js.dart`.

The translation path itself needs **no per-widget code**. Supporting a new widget still requires a host
renderer (`JsWidgetRegistry` or a capability library) because the Flutter widget has to be reconstructed;
three opt-in tables in `lib/src/builders/shared/js_class_defs.dart` additionally tune the *output shape*:

| Table | Purpose |
|---|---|
| `hostWidgetTypes` | extracted at build time from the runtime source (`hot_patch/lib/src/js_ui/**`: `r.register('X', …)`); drives which host-wrapper classes are generated in `flutter.js` and which class names component outputs import. No hand-maintained list. Value objects (decorations / items) are ordinary classes in the `flutter.js` value section instead |
| `builderFormTypes` | types with `.builder` / `.separated` named constructors; a JS proxy class is generated for them (the runtime only consumes the `factory` / `__delegate` protocol, never a type whitelist) |

Positional arguments are resolved from the **source constructor signature** (`shared/ctor_signatures.dart`):
`Text('hi')` → `{data: 'hi'}`, `Image.network(url)` → `{src: url}`. No per-type table is maintained; when the
signature cannot be indexed, the node produces a build warning and is dropped (no `$pos` index fallback).

Adding a visual widget therefore touches two sides: the host renderer, and — when the output shape differs —
the generator tables above.

Named constructors / static factories are translated **1:1** into a static call — `SizedBox.shrink(p)` →
`SizedBox.shrink({...})`, `Image.network(p)` → `Image.network({...})`. The constructor name never enters
`props`; it only lives in the call shape. JS has no named constructors, so each wrapper class on the JS side
(`flutter.js`) generates a **static method with the same name**, which records the constructor name into
`props.factory` — that key is the host's only signal for selecting the native factory:
`ListView.separated` → `{factory: 'separated', itemBuilder: …, separatorBuilder: …}`,
`Image.network` → `{factory: 'network', src: …}`, `ChangeNotifierProvider.value` → `{factory: 'value', …}`.
Callbacks, sizes and counts always keep their Dart parameter names (`itemBuilder` / `separatorBuilder` /
`itemCount`).

Widgets with no host renderer are not dropped silently: the output keeps their **concrete type name**, and
at runtime the host resolves it via `registerNativeComponent(name, build)`. The callback receives the full
`JsRenderContext` (`props` + `children` slots + `invoke`), so native implementations can render child widgets
and forward events.

### Code structure

This package is organised by function (under `lib/src/`), with acyclic one-way dependencies:

| Directory / file | Role |
| --- | --- |
| `lib/builder.dart` | **Public entry**: the seven builder factory functions for `build.yaml` |
| `lib/src/builders/shared/` | Foundations shared by more than one builder |
| `lib/src/builders/patch_entry/` | The complete `componentBuilder` chain: collection (`analysis/`) + translation (`translator/`) + output assembly |
| `lib/src/builders/ui_widget/`, `ui_host_register/`, `ui_patch_manifest/` | One directory per builder |

```
shared/  ←  patch_entry/{analysis,translator}  ←  builder.dart
```

`builders/shared/`: `source_index` (annotation detection / imported source parsing) · `host_injected`
(@HostInjected recognition / channel name / top-level host functions) · `js_class_defs` (`nodeHelperPackage` /
`packageModulePath` / widget type tables) · `paths` (output path derivation).

`builders/patch_entry/` — only used by `componentBuilder`:

- `component_builder`: collects the root classes of the file, calls `translateClass` uniformly, then
  assembles the result into a same-named JS output;
- `class_info`: the neutral class model shared by collection and translation;
- `analysis/`: `analyze_dart_class` (the single collection entry) · `class_table` · `component_scope` ·
  `const_support` · `singleton_support` · `imported_components`;
- `translator/`: `js_translator` (shared language layer) · `js_value` (shared value tools) · `dart2js`
  (class declarations) · `element2js` (widget trees) · `element_json` (the single unified widget entry
  `elementToJson`) · `value_forms` (value-shape dispatch `autoValue`). Structured style values are
  generated into `flutter.js` from `builders/runtime/js/style_values_js.dart`.

The other builders are self-contained:

- `ui_widget/`: `widget_module_builder` (package module output + the JS class sources of every logic
  component/sliver proxy; used only by this builder)
- `runtime/`: `runtime_builder` (emits the whole JS runtime — mini-react, handle registry, capability
  fragments — as one `patch/runtime.js`; the runtime package only loads it, so JS fixes ship with the patch
  and never require an app release. Sections are separated by `// ===== 【n】… =====` comments)
- `ui_host_register/`: `host_register_builder` (host-side registration list generation; the detection rules for
  @HostInjected live in `builders/shared/host_injected.dart`)
- `ui_patch_manifest/`: `patch_manifest_builder` (produces `patch/manifest.json`; thanks to
  `required_inputs: [".js"]` it is scheduled after `patch_entry` / `ui_widget` / `ui_runtime`, and uses
  `findAssets('patch/**.js')` to list every JS output and hash each one)

Other packages of the framework:

| Package | Role |
| --- | --- |
| `hot_patch_annotations` | Declarative annotations |
| `hot_patch_generator` | **This package**: `build.yaml` + factory entry + translation/build implementation |
| `hot_patch` | Runtime: loads and renders JS patch components, driven by JS |

Users only need to depend on `hot_patch_generator` in `dev_dependencies`.

## License

MIT
