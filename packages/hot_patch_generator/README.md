# hot_patch_generator

构建期把带 `@PatchEntry` 注解的 Flutter widget **静态翻译**为 JS 模块，
供 `hot_patch` 运行时热更渲染。

全程使用 `analyzer` 静态解析源码，**不执行任何 Dart 代码**，也不要求组件做任何改造：
被翻译的类始终是一个完全正常的 Flutter widget。

## 安装

```yaml
dev_dependencies:
  hot_patch_generator: ^0.1.0
  build_runner: ^2.4.13
```

然后在项目根目录运行：

```sh
dart run build_runner build --delete-conflicting-outputs
```

## 必需的种子文件

`build_runner` 要求 builder 的输出路径在 `build_extensions` 里**静态声明**，
无法按构建期「发现的类型」动态命名文件。因此本生成器需要一个**种子输入文件**
来挂载包级模块产物：

```dart
// lib/js_widgets.dart
// 本文件无需任何内容，只作为 build_runner 的输出声明载体。
```

- 默认路径：`lib/js_widgets.dart`
- 这是**必需项**：没有它，`patch/<package>.js` 这类包级模块不会被产出。
- 可通过 `build.yaml` 的 `options.seed_file` 覆盖（见下）。

## 产物

产物目录 `patch/` 与 `lib/` 源码路径**一一对应**，文件名与 Dart 源文件同名：

| 源码 | 产物 | 说明 |
| --- | --- | --- |
| `lib/components/counter.dart` | `patch/components/counter.js` | 含 `@PatchEntry` 的组件产物 |
| `lib/model/user.dart` | `patch/model/user.js` | 普通类 / 静态单例（`export class` / `export const`） |
| `lib/js_widgets.dart`（种子） | `patch/flutter.js`、`patch/provider.js` | **每个 package 一个文件**的 widget 工厂模块 |
| （包根伪资产，无种子） | `patch/manifest.json` | patch 清单：基本信息 + 打包时间 + 各 JS 资源的内容 hash |

- 按**文件内容**分流（与目录无关）：含 `@PatchEntry` → 组件产物；仅含普通类
  （非私有、非抽象、非组件）→ 模型/单例产物；都没有 → 不产出。
- `patch/flutter.js` 内含共享结点工厂 `__h` 与全部 flutter widget 工厂；
  其它包模块与组件产物统一从它 `import { __h }`。

> 注意：Flutter 的目录 asset 声明**不递归**，需在 `pubspec.yaml` 的 `assets:`
> 里逐目录（或逐文件）显式声明产物路径。

## 配置

在**使用方**的 `build.yaml` 里可以覆盖种子文件路径（只有 `ui_widget` 读这个选项）：

```yaml
targets:
  $default:
    builders:
      hot_patch_generator:ui_widget:
        options:
          seed_file: lib/my_seed.dart
```

## 翻译设计原则

翻译产物必须与 Dart 源码**一比一对应**，这是本框架的核心约束：

1. **Dart 合法写法都要静态翻译支持**。遇到不认识的语法形态，补正式翻译分支（在 `dart2js.dart` 的表达式/语句/类渲染等统一翻译路径上一比一映射成等价 JS），**不降级、不兜底成通用节点、不让用户改 Dart 写法来适配框架**。所有翻译只有一处实现，组件与普通类共用。
2. **禁止临时方案**。报错时不得在 demo 里加临时字段/中间层绕过（如为规避 setState 无 diff 而加的镜像触发字段）；产物 JS 应与 Dart 写法逐行对应，修就修翻译路径本身。
3. **能力按文件隔离**。新增运行时能力（如 ScrollController / TextEditingController id-bridge）时，宿主侧按能力放 `hot_patch/lib/src/js_ui/capabilities/` 独立文件，**不动 `js_widget_registry` / `js_ui_widget` 核心**；JS 运行时片段按能力拆命名字符串、由 `runtime_source.dart` 拼接。
4. **默认值与 Flutter 百分百一致**。宿主渲染时 nullable 属性缺省保持 `null`，不得默认成 `0` / `EdgeInsets.zero` 等覆盖 Flutter 主题默认。
5. **注册 key 与类名一致**。宿主 `r.register('X', ...)` 的 key 与产物 JS 里的 type 字符串保持同名，不另起别名。

## 扩展：新增 widget 支持

「某个 widget 怎么翻译成 JS」是策略，由 `WidgetTranslator` 实现：

```dart
class MyWidgetTranslator extends WidgetTranslator {
  const MyWidgetTranslator();

  @override
  Set<String> get types => {'MyWidget'};

  @override
  Map<String, Object?> toJson(Expression e, WidgetTranslateContext ctx) { ... }
}
```

在 `WidgetTranslatorRegistry` 里 `register` 即可，核心代码零改动。
内置策略见 `lib/src/translator/builtin_translators.dart`
（Column / Row / Text / Scaffold / provider 系列等）。

## 代码结构

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