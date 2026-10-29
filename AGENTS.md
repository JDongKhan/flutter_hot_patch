# AGENTS.md

本仓库由两部分构成：

- **翻译器（编译期）**：`hot_patch_generator`，把 Dart 源码按**语言/语法**规则翻译成 JS 协议产物。
- **运行时（运行期）**：`hot_patch` 内的 JS runtime + Flutter 宿主，按协议执行逻辑并渲染。

设计基线：`docs/项目架构文档.md`。本文与架构文档冲突时，先改文档再改代码。

## 0. 总则

- **职责边界**：翻译器只做「语法 → 等价的 JS 协议」，不承载业务语义；运行时只做「按协议执行与渲染」，不理解业务状态。
- **稳定性目标**：
  - 同一条 Dart 语法，在任何组件、任何上下文、任何版本下，都产出**同一形态**的 JS。翻译规则是语法级的，不随特性演进增加分支。
  - 已发布的 JS 协议与运行时策略**只增不改**：新能力靠扩展点叠加，老路径行为不变。
- **稳定性 ≠ 不演进**：演进必须走「预留的生命周期 / 扩展点 / 协议版本」，而不是改老逻辑或给单场景打补丁。
- **设计变更即清理**：一旦确认某项设计变更（L2/L3），旧设计的代码、分支、注册项、配置表项、产物与文档必须在**同一次变更内删除**。禁止新旧并存、兼容 shim、双实现、注释掉的死代码。验收标准是「旧设计已不存在」，而不是「新旧都能跑」。
- **通用优先**：任何「为某个组件 / 某个功能临时特殊处理」的实现都不合格；做不到通用时，先给方案与开发确认。

## 1. 翻译器（编译期）原则

- **一条语法一个规则**：同一语法现象只有一处实现（多个入口共用同一份逻辑），不存在 per-widget / per-class 的翻译器子类或专门分支。
- **判据只来自源码事实**：类型与构造签名（`CtorSignatures`）、`extends` 链（`isWidgetCtorName`）、import 链与文件/package 归属。**禁止**用类名、方法名、属性名白名单判断执行。
- **构造翻译唯一规则**：`A(args)` → `new A({...})`，`A.b(args)` → `A.b({...})`；位置实参由源码构造签名映射为形参名。未知签名 → 构建期告警并丢弃，不生成下标键或占位兜底。
- **属性原样下发**：Dart 构造实参按原名进 props，**禁止**对 `child` / `children` / `slivers` / `tabs` 等固定属性名做特殊判断。
- **翻译只增不改**：新增语法支持只能新增分支/新模块，不得改变既有语法产出的 JS 形态，避免产物协议随版本漂移。
- **无静默**：翻译失败、未覆盖语法、无法识别的引用，必须输出构建期告警，禁止静默丢弃或降级。
- **能力扩展不进翻译器**：SDK 新增颜色、Controller、值类等同类能力，只新增能力模块（注入同名类 / 由源码自动抽取 / from_json 放回归属目录），翻译器与运行时框架都不动；翻译器只保留语法规则。

## 2. 运行时（执行层）原则

- **协议冻结**：`__h`、element 形态、`__delegate` / `factory`、children 拆分、patch ops、句柄信封、颜色序列化、`lazyChildren` 等已发布协议只增不改语义。破坏性改动必须升主协议版本、给兼容或迁移方案，并与开发确认。
- **老策略不改**：已发布的调度、生命周期、句柄释放、懒容器等策略不因新特性而改变；缺陷修复允许，但不得改变已发布协议的语义。
- **扩展优先**：新增能力 = 新增能力模块（`capabilities/<name>/`：Dart 桥 + kind 描述符 + JS 片段 + `JsUiLibrary` 子类注册），核心文件（reconciler / `JsUiWidget` / `disposeRoot` / 桥 / 句柄注册表）零改动。
- **唯一出口**：JS → 宿主只有 `_app_host_.invoke`；宿主侧只有 `JsRuntimeManager.registerHostMethod`。禁止新开平行通道。
- **封装而非散落**：runtime.js 中重复操作必须抽成 `__` 前缀的内部方法（如 `__scopeOf`、`__defineProtoGetter`），禁止零散直接调用。
- **API 通用**：运行时 API 不为单个功能特设；上下文查找统一走通用入口（如 `__scopeOf`）。
- **生命周期单入口**：页面资源只由 `disposeRoot` 释放；JS 组件生命周期只由 mini-react 派发；句柄随持有它的组件释放，页面销毁兜底。
- **状态在 JS**：宿主不感知 setState / provider 等状态语义，状态变化终点永远是 JS 下发的 patch。
- **构建期表驱动**：懒容器、builder 形态、宿主类型等由构建期表/自动抽取决定，运行时**不维护任何类型白名单**。

## 3. 生命周期与扩展点（唯一允许的加法位置）

| 需求 | 扩展点 | 位置 |
|---|---|---|
| 新增 Flutter widget 渲染 | 注册 type → renderer（或能力库 `registerWidgets`） | 宿主 `JsWidgetRegistry` / `capabilities/*` |
| 新增 `.builder` / `.separated` / 懒加载容器 | `builderFormTypes` / `builderCountPropKeys` / `lazyChildHostTypes`（产物组织信息，非运行时白名单） | 生成器 `shared/js_class_defs.dart` |
| 新增 Controller / 平台能力 | `capabilities/<name>/`：Dart 桥 + JS 片段（随 `runtime.js` 发布）+ `JsUiLibrary` 子类 | 运行时 `capabilities/` + 生成器 `builders/runtime/js/` |
| 新宿主方法调用 | `@HostInjected` + `registerHostMethod` | 注解 + `JsRuntimeManager` |
| 纯原生组件 | `registerNativeComponent(name, build)` | App `main()` |
| 自定义数据载体 | `registerJsDataCarrierType(type)` | App `main()` |
| `context.xxx` 扩展（watch/read 等） | `registerContextOp`（核心通用缝，不认识具体 op 名） | `capabilities/build_context/` |
| Dart 标准库缺失方法 | 内建原型同名同义补齐（存在性守卫 + 不可枚举） | 生成器 `builders/runtime/js/runtime_js.dart`【1c】 |
| Dart extension / mixin | `__jsExtension` + `patch/extensions.js` barrel | 生成器 + 运行时加载后汇总 |
| 新增值类 / from_json | 放归属目录（通用值类进 `capabilities/core/from_json`） | 运行时能力目录 |

上表任何新增都**不得**改动：reconciler、`JsUiWidget`、`disposeRoot`、桥接、句柄注册表、翻译器内核。

## 4. 变更分级（决定能不能动核心）

| 级别 | 含义 | 要求 |
|---|---|---|
| L1 加能力 | 只走扩展点，核心零改动 | 默认且首选 |
| L2 加语法 | 翻译器新增语法分支或新产物模块，既有语法产物不变 | 协议次版本（只做加法）；若替换旧语法实现，旧实现同步删除 |
| L3 改协议 / 改老策略 | 触及已发布协议或运行时既有策略 | 必须先沟通确认 + 升主协议版本 + 兼容或迁移方案 + 更新架构文档 + 删除被替换的旧路径 |

未确认前禁止 L3。协议版本写入 `patch/manifest.json` 的 `protocol`（取自生成器包版本）；主版本变化 = 破坏性契约变更，次版本 = 只做加法。

## 5. 禁止清单

- 按类名 / 方法名 / 属性名 / 类型名判断执行，或在运行时维护类型白名单。
- 判断「这个类是不是 Widget / 是不是组件」——**所有类都是普通类**，需要区分时看类来自哪个文件（源文件 → 产物文件 / package 模块）。
- 对固定子组件属性名（`child` / `children` / `slivers` / `tabs` 等）做特殊处理。
- 静默丢弃、静默降级、占位兜底（包括用 `SizedBox` 兜底）。
- 手改 `patch/` 下任何产物（`GENERATED CODE - DO NOT EDIT`）；修 bug 改 Dart 单源或生成器。
- 新开 JS ↔ 宿主通道，或恢复已删除的冗余注册入口。
- 为单个功能设计专用 runtime API，或写 per-widget / per-class 翻译器子类。
- 在翻译层按方法名做映射改写。
- 用类名做命名映射、靠「运行时按属性名猜 builder 形态」等启发式手段。

## 6. 验证与交付

- 改动生成器/运行时后：重新执行 build_runner，核对 `patch/` 产物、`manifest.json` 与 `patch.zip`；`dart analyze` 无错误。
- 涉及组件或运行时行为：在 macOS 桌面端运行 example（`fvm flutter run -d macos`）验证，不占用 iOS 模拟器。
- 涉及协议：同步更新 `CHANGELOG`，写明是否为破坏性变更。
- 开发流程：没有明确「开干」时，先给方案等确认。
- 变更收尾：逐项核对被本次设计替换的旧代码、旧注册项、旧配置表项、旧产物、旧文档是否已彻底删除；残留即视为未完成。
