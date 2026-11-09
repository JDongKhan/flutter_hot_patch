# 待办事项（TODO）

> 本文件集中维护项目的待办任务、实施顺序与暂缓项。
> 约定：代码里的 TODO 只保留简短指针，详细说明统一放在本文件；每完成一项在此更新状态，待负责人验证通过后再进入下一项。
>
> 最后更新：2026-10-27

## 1. 当前实施顺序（按改动范围从小到大）

| # | 任务 | 改动范围 | 状态 | 对应评审项 | 验证方式 |
|---|---|---|---|---|---|
| 1 | `jsString` 转义修复并合并重复实现 | 小 | 已完成 | P0-1 / P1-重复实现 | `dart analyze` + 转义用例输出 |
| 2 | 跨包 import 解析标注 TODO | 小 | 已完成 | P1-12 | 注释 / 文档，无行为变化 |
| 3 | 远程 zip：路径穿越校验 + 大小上限 | 小 | 已完成 | P0-7 | 构造含 `../` 与超大条目的 zip，确认被拒绝并回退旧缓存 |
| 4 | `translateStmtList` 未覆盖语句告警 + `try/catch/throw/assert` 基础翻译 | 小~中 | 已完成 | P0-2 | HelloCard 的 Try/Catch 按钮可执行并输出日志；剩余未覆盖语句仍有构建期告警 |
| 5 | `eq` 深比较深度改为可配置 / 足够深 | 小 | 已完成 | P1-11 | 深层嵌套 props 变更能触发 patch |
| 6 | `JsUiWidget` 支持 `props` 更新 | 小~中 | 已完成 | P1-10 | 父组件重建传入新 props，JS 字段与 UI 同步 |
| 7 | `PageController` / 构造类字段补齐 | 中 | 已完成 | P0-5 / P1-17 | PageView 外部 controller 可创建、可跳页 |
| 8 | 移除方法名映射，改为 JS 原型注入 | 中 | 已完成 | P1-8 | `where/add/removeAt/insert/toList/compareTo/first/last` 原样翻译并通过 demo |
| 9 | `registerNativeComponent` 支持 children / slots | 中 | 已完成 | P0-4 | 未注册容器组件的子树不再丢失（5f3b5ac） |
| 10 | `builtinWidgetTypes` 改为直接父类判定 | 中 | 已完成 | P1-9 | 字段 / 依赖判定移除白名单后 demo 产物 JS 无变化（仅 manifest 时间戳） |
| 11 | 跨包 import 解析 + 跨包翻译 | 中~大 | 待验证 | P1-12 | 新建 `module/hot_module_base` 并迁移 `Network` / `AccountCenter` / `User`；`host_methods.dart` 跨包注册、组件产物跨包 import、`patch/hot_module_base.js` 产出 |

## 2. 详细 TODO

### 2.1 跨包 import 解析（任务 11，待验证）

- **原状**：`resolveImportFiles` 把任意 `package:foo/x.dart` 映射成当前包的 `lib/x.dart`，跨包共享组件库无法进入依赖分析。
- **已实现**（2026-10-27）：
  - 新增 `shared/package_sources.dart`：从 `.dart_tool/package_config.json` 解析包名 → lib 目录，区分**本地包**（path 依赖 / workspace 成员，`rootUri` 是相对 URI）与三方宿主包（pub cache）；workspace 下「当前包」由构建入口脚本路径反推。
  - `shared/source_index.dart`：源文件身份分两种——项目内 `lib/...` 与跨包 `package:<pkg>/<rel>`；`export` 转发（barrel）递归展开（import 目标自身不深入，但其 export 要展开）。
  - `shared/paths.dart`：跨包源文件 → 包模块产物 `patch/<package>.js`（一个本地依赖包一个文件，避免不同包的 `lib/` 结构互相撞名）。
  - `ui_host_register`：扫描范围扩到「本包 + 沿 import 可达的本地依赖包文件」，跨包条目用 `package:` URI import，实现跨包 `@HostInjected` 注册。
  - 新增 `patch_entry/project_module_builder.dart`（builder `ui_project_module`）：把本地依赖包里**被项目组件引用到**的类聚合产出为 `patch/<package>.js`，复用 `componentTranslationScope` 做「被引用」判定。
  - `component_scope`：把跨包依赖文件纳入依赖图（`parseUnitFile` 直接读盘，非本包资产）。
- **验收**：新建 `module/hot_module_base`，迁移 `Network`（网络请求）、`AccountCenter`（账号能力，均为 `@HostInjected`）与 `User`（普通模型类）；`example` 改为 `package:hot_module_base/...` 引用。产物可见：`host_methods.dart` 跨包 import 并注册 `getUserName` / `post`；`hello_component.js` 内 `import { User } from '../hot_module_base.js'` 且 `_app_host_.invoke("getUserName")` / `("post")` 调用点保持正确；`patch/hot_module_base.js` 含 `export class User`。macOS 端运行无报错。
- **未覆盖**：本地依赖包里的顶层常量与静态单例类产物（构建期出声）；跨包文件的增量失效未接入 build_runner 依赖图（改动跨包源码后需 `--delete-conflicting-outputs` 或触碰使用方文件）。
- **入口**：`packages/hot_patch_generator/lib/src/builders/shared/{package_sources,source_index,paths}.dart`、`patch_entry/project_module_builder.dart`、`ui_host_register/host_register_builder.dart`。

### 2.2 resolved AST 迁移（架构级，暂不排期）

- **原因**：当前全部使用 `parseString`（无符号解析），导致：
  - 静态方法调用与 Widget 构造无法区分（大写开头 receiver 被当作 Widget）；
  - 公共 static 方法 / 顶层函数无法翻译；
  - 跨包依赖断链；
  - 只能靠 `builtinWidgetTypes` 等表格判断类型归属。
- **目标**：改用 `AnalysisContextCollection` / build_runner `Resolver` 获取带类型信息的 AST；翻译内核分批迁移。
- **影响**：翻译层全部文件，需单独立项，不并入本轮小步改造。
- **前置**：先完成本轮 P0 修复，避免迁移期间行为漂移。

### 2.3 `builtinWidgetTypes` 改为直接父类判定（任务 10 / 评审 P1-9，已完成）

- **已确认口径**：只识别直接 `extends StatefulWidget / StatelessWidget / State`；**不处理**自定义 `MyBaseWidget` 的情况；resolved AST 迁移另列 TODO。
- **已完成**：
  - 字段可翻译性（`_fieldTranslatable`）不再接收 widget 类型表：类表能解析到的类直接放行；
    解析不到的类型（如 `package:flutter` 的 `Text` / `Column`、三方类型）按宿主 Widget 值
    处理，并输出构建期告警；
  - 依赖发现中的 `builtinWidgetTypes` 过滤已删除（类表本身只含本地可解析类）；
  - `builtinWidgetTypes` 仅保留为**宿主类型登记表**：决定 `flutter.js` 生成哪些宿主包装类、
    产物 import 哪些类名（协议重构后仍必需）。
- **验收**：重新生成后 `example/patch` 的 JS 产物与改动前逐字一致（仅 manifest 时间戳 / zip 元数据变化）。

### 2.4 暂缓项（本轮不做）

| 项 | 原因 | 后续动作 |
|---|---|---|
| 全局模块表 `__modules` 的多页面 / 多版本隔离 | 已确认先不动 | 单独立项，评估 per-page / per-bundle 模块表与 manifest 协议版本 |
| 远程补丁 hash / 签名校验 | 改动面较大，先做路径穿越与大小上限 | 安全专项统一评估 |
| 构建期 O(N²) 扫描（`componentTranslationScope` 每个文件全包扫描） | 需要构建缓存设计 | 性能专项 |
| 未支持语法（`try/catch`、`throw`、pattern、extension、标准库 shim 等）完整支持 | 属于翻译内核能力扩展 | 随 resolved AST 或独立批次推进 |
| 深层 props diff / 高频事件性能 | 需要基准测试 | 性能专项 |
| 删除 mini-react，改为 Flutter 生命周期驱动渲染（边界 Widget `initState` → JS `build`） | 架构级设想，需先做对照实验拿数据 | 见 `docs/架构设想-生命周期驱动渲染.md` |

## 3. 维护约定

- 新增 TODO：先写入本文件，再在代码处留 `TODO(名称): 见 TODO.md` 指针。
- 状态取值：`待开始` / `进行中` / `待验证` / `已完成`。
- 每项实现完成后，在提交说明或对话中给出验证命令与结果；负责人验证通过后再开始下一项。
- 已完成项保留记录，不删除，便于回溯改动顺序。
- **异常 / 未支持场景必须有日志**：任何翻译失败、分支未覆盖、类型无法识别、运行时异常都至少输出一条 `warn` / `error` 日志，禁止静默返回、静默丢弃或空实现吞掉。新增代码评审时必须检查这一条。

## 4. widget-class 协议重构（已完成）

> 目标：不再让生成器判断「这个类是不是 widget」。所有构造统一翻译成
> `new X({...})`；组件实例自身就是元素；局部变量 / 字段 / 列表 / 三目不再需要 widget 特判。
>
> 采用方案：**构造即元素 + 值对象归一化**（不做构造函数双模、不生成 XxxElement）。
>
> 分支：`feature/widget-class-protocol`
> 起点：`5f3b5ac`（任务 9、局部 widget 变量、spread 修复已提交）

### 4.1 运行时协议

- `Component` 实例自身就是元素：构造写入 `__element = true`、`__type = this.constructor`；
  宿主包装类额外写 `__host = true`。reconciler 只认 `__element` 标记，不按原型上有没有
  `build` 猜组件。
- 宿主包装类在构造期由 `Component.__splitHost` 按**值形态**拆分：元素值 / 元素数组 /
  `__builder` / delegate 进 `__children`，其余留在 `props`，与键名无关。
- 值对象里的 Widget 字段由 `__descriptorOf` 摊成元素描述
  `{type, props, children, element: true}`；普通子结点本身就是元素，不需要二次折算。
- 生成类构造恢复普通语义：`new CommunityPage(props)` 即元素，首行保留
  `this.props = args`。

### 4.2 宿主包装类生成（已完成）

- `flutter.js` 为 `hostWrapperTypes`（宿主 widget + 数据载体，排除逻辑组件 /
  builder 代理）生成 `class Text extends Component {}` 形式的包装类：构造即宿主元素，
  props 由基类构造期拆分。
- 数据载体 `InputDecoration` 同样生成包装类。
- builder 命名构造类型（ListView 等）保持真实类，供 `.builder/.separated` 挂载；
  普通构造 / delegate 形态由包装类构造即宿主元素。

### 4.3 翻译器统一发射 `new`（已完成）

- 有 JS 类的类型（宿主包装 / 组件 / 逻辑组件 / 代理）→ `new Type(props)`；
  无 JS 类的原生注入类型由声明它的源文件产物里的同名包装类承接。
- 宿主类型纳入 `usedWidgetPackages`，组件产物从 `flutter.js` import 对应类。
- 局部 widget 变量 / 字段 / 列表 / 三目的产物均为 `new`（如
  `new Text({data: …})`、`new StatelessCard({…})`）。
- 局部值翻译去掉「是不是 widget」的白名单：只排除已知模型类
  （classTable 的 `!isComponent`）与值对象 / 结构化样式，其余类构造一律按
  元素翻译（`_isNodeCtor` + `modelClassNames` + `isValueCtorName`）。

**验收**：现有 demo 页面行为不变；TestWidget 的 `Text text = Text()`、
`StatelessCard card = …`、`...items` 均为 `new` 且渲染正常。

### 4.4 清理与文档（已完成）

- 删除局部值路径的 widget 白名单（`widgetClassNames` / `_isWidgetValueExpr`），改为仅排除
  模型类与值对象。
- 更新架构文档、组件支持文档、使用手册与生成器 README：产物协议改为
  `new Type(props)`、宿主包装类、`__element` / `__children` 拆分、`__descriptorOf` 归一化。
- 兼容边界：
  - 当前运行时不再支持旧产物形态；补丁包需按整包重出；
  - 新产物需要与之配套的 `flutter.js` / `runtime.js`，不存在新旧混载；
  - 无 JS 类的类型由声明它的源文件产物里的同名包装类承接。
- 全量 demo 验证：TestWidget、Provider、PageView、列表页、详情页均由用户手动确认。

### 4.5 已知风险

| 风险 | 处理 |
|---|---|
| 自定义组件的用户代码构造会执行字段初始化（控制器 / Key 句柄） | 已修复二次构造：实例随元素下发，mount 直接复用、不再 new 第二次；patch 复用旧实例保持状态 |
| 懒容器声明式子项（`TabBarView(children:)` / `PageView(children:)`）一次性挂载全部子页 | **已修复（2026-10-23 重构）**：懒与否改为**构建期配置**——生成器 `js_class_defs.dart` 的 `lazyChildHostTypes` 写入 `flutter.js`（包装类 `static __lazy` / `Component.host` 的 lazyRule），`Component.__splitHost` 在构造期给元素打 `lazyChildren` 标记；运行时只认元素标记，零类型表。懒槽位协议不变：先下发零尺寸占位，宿主 inflate 时经 `__lazyFn` 回调 `lazyMount`、dispose 时经 `__lazyOffFn` 回调 `lazyUnmount`；真实子树挂成占位结点的 `child` slot（占位 id/key 不变）。builder 形态（`ListView.builder` / `GridView.builder`）在懒容器下**连 itemBuilder 调用也推迟**，宿主 inflate 到该项时才执行 |
| builder 代理类型（ListView 等）无宿主包装类 | 普通构造 / delegate 形态由包装类构造即宿主元素；`.builder/.separated` 才 `new ListView(props)` |
| 数据载体 / InputDecoration | 生成包装类，保持宿主 renderer 读取方式不变 |
| 宿主包装类名与本地组件类名同名 | 暂未处理（JS 会重复声明）；命名冲突时需单独约定 |
| const widget 身份 | 仍按 props/key diff，不依赖对象身份 |
| 旧产物兼容 | 当前运行时不再支持旧产物形态；补丁包需按整包重出（历史兼容说明见 CHANGELOG） |
