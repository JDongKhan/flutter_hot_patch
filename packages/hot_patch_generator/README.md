# hot_patch_generator

[English](#english) | [简体中文](#简体中文)

## English

Translates Flutter widgets annotated with `@PatchEntry` **statically** into JS modules at build time, so the
`hot_patch` runtime can hot-patch and render them.

It parses sources statically with `analyzer`, **never executes any Dart code**, and requires no changes to the
component: the translated class stays a completely ordinary Flutter widget.

### Installation

```yaml
dev_dependencies:
  hot_patch_generator: ^0.1.0
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
| (package-root pseudo asset `$package$`) | `patch/flutter.js`, `patch/provider.js` | Widget factory modules, **one file per package** |
| (package-root pseudo asset `$package$`) | `patch/manifest.json` | Patch manifest: basic info + build time + content hash of every JS asset |

- Splitting is driven by **file content** (not by directory): contains `@PatchEntry` → component output;
  contains only plain classes (non-private, non-abstract, non-component) → model/singleton output; neither →
  no output.
- Package-level modules (`patch/<package>.js`) and the manifest hang off the package-root pseudo asset
  `$package$`: the input is the whole package and the output path is static, so **users need no seed file and
  no configuration** — just depend on this package and run `build_runner`.
- `patch/flutter.js` contains the shared node factory `__h` and every Flutter widget factory; other package
  modules and component outputs all `import { __h }` from it.

Browse the JS actually generated for the example app online:
[example/patch/](https://github.com/JDongKhan/flutter_hot_patch/tree/main/example/patch).

> Note: Flutter's directory asset declaration is **not recursive**, so every output path must be declared
> explicitly in `pubspec.yaml` under `assets:` (per directory or per file).

### Configuration

`ui_widget` (package modules) and `patch_entry` (component/model outputs) **read no options**. The options of
the remaining two builders are all optional and work out of the box:

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

1. **Every legal Dart construct must be statically translatable.** When you meet an unknown syntax form, add a
   proper translation branch (mapped one-to-one onto equivalent JS in the shared expression/statement/class
   rendering paths of `dart2js.dart`). **Never degrade, never fall back to a generic node, never ask users to
   change their Dart to fit the framework.** All translation has a single implementation shared by components
   and plain classes.
2. **No temporary workarounds.** When something fails, do not bypass it in the demo with temporary fields or
   shim layers (e.g. adding a mirror trigger field just because setState has no diff); the JS output must map
   line-by-line onto the Dart source — fix the translation path itself.
3. **Capabilities are isolated per file.** When adding a runtime capability (e.g. ScrollController /
   TextEditingController id-bridge), put it on the host side as a separate file under
   `hot_patch/lib/src/js_ui/capabilities/` and **do not touch the `js_widget_registry` / `js_ui_widget` core**;
   JS runtime fragments are split into named strings per capability and assembled by `runtime_source.dart`.
4. **Defaults match Flutter 100%.** When the host renders, nullable properties stay `null` by default; never
   default them to `0` / `EdgeInsets.zero` etc. and override Flutter theme defaults.
5. **Registration keys match class names.** The key in the host's `r.register('X', ...)` must have the same name
   as the type string in the JS output; no aliases.

### Extension: adding widget support

There is **no per-widget translator**: every widget — built-in, custom or third-party — goes through the
single translation path (`lib/src/translator/widget_json.dart`), which dispatches on

- **generic parameter names**: `child` / `children` / `slivers` / `tabs` / `on*` / `delegate`;
- **value shapes** (`lib/src/translator/value_forms.dart`): literals, constructors, static factories,
  constant references (enums / colors / icons), lists, closures — structured styles are converted by the
  `xxxToJson` helpers in `style_translators.dart`.

Supporting a new widget therefore needs **no code**. Two opt-in tables in
`lib/src/builders/js_widget_defs.dart` only tune the *output shape*:

| Table | Purpose |
|---|---|
| `widgetPositionalArgNames` | positional arguments go into props under **Flutter's own parameter name** (`Text('hi')` → `{data: 'hi'}`, `Image.network(url)` → `{src: url}`); unlisted types fall back to `props['$pos']` (index array; the host reads it by position) |
| `builtinWidgetTypes` | mirror of the host's `JsWidgetRegistry` keys (tells built-in widgets apart from business classes) |

Named constructors / static factories keep their name in the output, so the runtime can select the exact
factory per type: `ListView.builder` → `{factory: 'builder', itemBuilder: …}`,
`ListView.separated` → `{factory: 'separated', itemBuilder: …, separatorBuilder: …}`,
`Image.network` → `{factory: 'network', src: …}`, `ChangeNotifierProvider.value` →
`{factory: 'value', …}`. Callbacks, sizes and counts always keep their Dart parameter names
(`itemBuilder` / `separatorBuilder` / `itemCount`).

Widgets with no host renderer are not dropped silently: the output keeps their **concrete type name**, and
at runtime the host resolves it via `registerNativeComponent(name, build)` — business code needs no
translation code for those cases.

### Code structure

This package is organised by function (under `lib/src/`), with acyclic one-way dependencies:

| Directory / file | Role |
| --- | --- |
| `lib/builder.dart` | **Public entry**: the four builder factory functions for `build.yaml` |
| `lib/src/translator/` | Translation core: Dart AST → JS (single entry `translateClass`) |
| `lib/src/builders/` | build_runner Builder implementations and output assembly |

```
translator/  ←  builders/  ←  builder.dart
```

In `lib/src/translator/`: `js_translator` (shared language layer) · `dart2js` (class declarations) ·
`widget2js` (widget trees) · `class_translator` (single entry) · `source_index` (annotation detection /
imported source parsing) · `host_injected` (@HostInjected channel table, scanned by the translation layer) ·
`style_translators` · `builtin_translators` (built-in widget policies).

`lib/src/builders/` is split per builder:

- `patch_entry/`: `component_builder` (collects the root classes of the file and calls `translateClass`
  uniformly, then assembles the result into a same-named JS output) · `class_table` · `singleton_support`
- `ui_widget/`: `widget_module_builder` (package module output + the JS class sources of every logic
  component/sliver proxy; used only by this builder)
- `ui_host_register/`: `host_register_builder` (host-side registration list generation; the detection rules for
  @HostInjected live in `translator/host_injected.dart`)
- `ui_patch_manifest/`: `patch_manifest_builder` (produces `patch/manifest.json`; thanks to
  `required_inputs: [".js"]` it is scheduled after `patch_entry` / `ui_widget`, and uses
  `findAssets('patch/**.js')` to list every JS output and hash each one)
- at the root: shared output foundations for all builders — `product_path` · `js_widget_defs`
  (`nodeHelperPackage` / `packageModulePath` / the set of widget types that have JS classes)

Other packages of the framework:

| Package | Role |
| --- | --- |
| `hot_patch_annotations` | Declarative annotations |
| `hot_patch_generator` | **This package**: `build.yaml` + factory entry + translation/build implementation |
| `hot_patch` | Runtime: loads and renders JS patch components, driven by JS |

Users only need to depend on `hot_patch_generator` in `dev_dependencies`.

---

## 简体中文

构建期把带 `@PatchEntry` 注解的 Flutter widget **静态翻译**为 JS 模块，
供 `hot_patch` 运行时热更渲染。

全程使用 `analyzer` 静态解析源码，**不执行任何 Dart 代码**，也不要求组件做任何改造：
被翻译的类始终是一个完全正常的 Flutter widget。

### 安装

```yaml
dev_dependencies:
  hot_patch_generator: ^0.1.0
  build_runner: ^2.4.13
```

然后在项目根目录运行：

```sh
dart run build_runner build --delete-conflicting-outputs
```

### 产物

产物目录 `patch/` 与 `lib/` 源码路径**一一对应**，文件名与 Dart 源文件同名：

| 源码 | 产物 | 说明 |
| --- | --- | --- |
| `lib/components/counter.dart` | `patch/components/counter.js` | 含 `@PatchEntry` 的组件产物 |
| `lib/model/user.dart` | `patch/model/user.js` | 普通类 / 静态单例（`export class` / `export const`） |
| （包根伪资产 `$package$`） | `patch/flutter.js`、`patch/provider.js` | **每个 package 一个文件**的 widget 工厂模块 |
| （包根伪资产 `$package$`） | `patch/manifest.json` | patch 清单：基本信息 + 打包时间 + 各 JS 资源的内容 hash |

- 按**文件内容**分流（与目录无关）：含 `@PatchEntry` → 组件产物；仅含普通类
  （非私有、非抽象、非组件）→ 模型/单例产物；都没有 → 不产出。
- package 级模块（`patch/<package>.js`）与清单都挂在包根伪资产 `$package$` 下：
  输入是整包、输出路径静态，**使用方无需任何种子文件或配置**——依赖本包并跑
  `build_runner` 即可产出。
- `patch/flutter.js` 内含共享结点工厂 `__h` 与全部 flutter widget 工厂；
  其它包模块与组件产物统一从它 `import { __h }`。

示例 App 的实际产物（生成的 JS 文件）可在线查看：
[example/patch/](https://github.com/JDongKhan/flutter_hot_patch/tree/main/example/patch)。

> 注意：Flutter 的目录 asset 声明**不递归**，需在 `pubspec.yaml` 的 `assets:`
> 里逐目录（或逐文件）显式声明产物路径。

### 配置

`ui_widget`（package 模块）与 `patch_entry`（组件/模型产物）**不读任何 options**。
其余两个 builder 的选项均为可选，缺省即开箱可用：

```yaml
targets:
  $default:
    builders:
      # 宿主注入注册产物（lib/generated/host_methods.dart）的目标运行时；
      # 仅当换用别的运行时实现时才需要覆盖。
      hot_patch_generator:ui_host_register:
        options:
          register_import: "package:<runtime>/<runtime>.dart"
          register_call: "<Runtime>.registerHostMethod"
      # patch/manifest.json 里的基本信息；缺省取包名 / 省略版本。
      hot_patch_generator:ui_patch_manifest:
        options:
          name: my_app
          version: 1.2.3
```

### 翻译设计原则

翻译产物必须与 Dart 源码**一比一对应**，这是本框架的核心约束：

1. **Dart 合法写法都要静态翻译支持**。遇到不认识的语法形态，补正式翻译分支（在 `dart2js.dart` 的表达式/语句/类渲染等统一翻译路径上一比一映射成等价 JS），**不降级、不兜底成通用节点、不让用户改 Dart 写法来适配框架**。所有翻译只有一处实现，组件与普通类共用。
2. **禁止临时方案**。报错时不得在 demo 里加临时字段/中间层绕过（如为规避 setState 无 diff 而加的镜像触发字段）；产物 JS 应与 Dart 写法逐行对应，修就修翻译路径本身。
3. **能力按文件隔离**。新增运行时能力（如 ScrollController / TextEditingController id-bridge）时，宿主侧按能力放 `hot_patch/lib/src/js_ui/capabilities/` 独立文件，**不动 `js_widget_registry` / `js_ui_widget` 核心**；JS 运行时片段按能力拆命名字符串、由 `runtime_source.dart` 拼接。
4. **默认值与 Flutter 百分百一致**。宿主渲染时 nullable 属性缺省保持 `null`，不得默认成 `0` / `EdgeInsets.zero` 等覆盖 Flutter 主题默认。
5. **注册 key 与类名一致**。宿主 `r.register('X', ...)` 的 key 与产物 JS 里的 type 字符串保持同名，不另起别名。

### 扩展：新增 widget 支持

**没有 per-widget 的 translator**：内建、自定义、三方组件全部走同一条翻译路径
（`lib/src/translator/widget_json.dart`），分派依据只有两项：

- **通用参数名**：`child` / `children` / `slivers` / `tabs` / `on*` / `delegate`；
- **值的形态**（`lib/src/translator/value_forms.dart`）：字面量、构造、静态工厂、常量引用
  （枚举 / 颜色 / 图标）、列表、闭包——结构化样式由 `style_translators.dart` 的 `xxxToJson` 转换。

因此接入新 widget **零实现**。`lib/src/builders/js_widget_defs.dart` 里两张可选登记表只调
**产物形态**：

| 表 | 用途 |
|---|---|
| `widgetPositionalArgNames` | 位置实参按 **Flutter 自己声明的形参名**下发（`Text('hi')` → `{data: 'hi'}`、`Image.network(url)` → `{src: url}`）；未登记的类型退回 `props['$pos']`（下标数组，运行时按位取） |
| `builtinWidgetTypes` | 宿主 `JsWidgetRegistry` 注册键的镜像（用于区分内建 widget 与业务类） |

命名构造 / 静态工厂的名字会保留在产物里，运行时据此**按类型选工厂**：`ListView.builder` →
`{factory: 'builder', itemBuilder: …}`、`ListView.separated` → `{factory: 'separated', itemBuilder: …,
separatorBuilder: …}`、`Image.network` → `{factory: 'network', src: …}`、
`ChangeNotifierProvider.value` → `{factory: 'value', …}`。回调 / 尺寸 / 计数一律保留 Dart 形参名
（`itemBuilder` / `separatorBuilder` / `itemCount`）。

宿主没有对应 renderer 的 widget 不会被静默丢弃：产物保留其**具体类型名**，运行时由宿主
`registerNativeComponent(name, build)` 解析——这类场景业务代码无需任何翻译代码。

### 代码结构

本包按功能分目录组织（`lib/src/` 下），依赖单向无环：

| 目录 / 文件 | 作用 |
| --- | --- |
| `lib/builder.dart` | **对外入口**：`build.yaml` 的四个 builder 工厂函数 |
| `lib/src/translator/` | 翻译内核：Dart AST → JS（唯一入口 `translateClass`） |
| `lib/src/builders/` | build_runner Builder 实现与产物组装 |

```
translator/  ←  builders/  ←  builder.dart
```

`lib/src/translator/`：`js_translator`（公共语言层）· `dart2js`（类声明）·
`widget2js`（widget 树）· `class_translator`（唯一入口）·
`source_index`（注解识别 / import 源文件解析）·
`host_injected`（@HostInjected 通道表，翻译层自扫）·
`style_translators` · `builtin_translators`（内置 widget 策略）。

`lib/src/builders/` 按 builder 再分目录：

- `patch_entry/`：`component_builder`（收集本文件根类并统一调
  `translateClass`，并把结果拼装为同名 JS 产物）· `class_table` ·
  `singleton_support`
- `ui_widget/`：`widget_module_builder`（package 模块产物 + 各逻辑
  组件/sliver 代理的 JS 类源码，仅本 builder 使用）
- `ui_host_register/`：`host_register_builder`（宿主侧注册清单生成；
  @HostInjected 的识别口径在 `translator/host_injected.dart`）
- `ui_patch_manifest/`：`patch_manifest_builder`（产出 `patch/manifest.json`；
  靠 `required_inputs: [".js"]` 排到 `patch_entry` / `ui_widget` 之后的阶段，
  用 `findAssets('patch/**.js')` 列出全部 JS 产物逐个算 hash）
- 根下为各 builder 共用的产物基础：`product_path` ·
  `js_widget_defs`（`nodeHelperPackage` / `packageModulePath` /
  有 JS 类的 widget 类型集合）

框架的其它包：

| 包 | 作用 |
| --- | --- |
| `hot_patch_annotations` | 声明式注解 |
| `hot_patch_generator` | **本包**：`build.yaml` + 工厂入口 + 翻译/构建实现 |
| `hot_patch` | 运行时加载 JS 补丁渲染组件，由 JS 驱动逻辑 |

使用方只需在 `dev_dependencies` 里依赖 `hot_patch_generator`。

## License

MIT
