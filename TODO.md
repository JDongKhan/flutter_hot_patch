# 待办事项（TODO）

> 本文件集中维护项目的待办任务、实施顺序与暂缓项。
> 约定：代码里的 TODO 只保留简短指针，详细说明统一放在本文件；每完成一项在此更新状态，待负责人验证通过后再进入下一项。
>
> 最后更新：2026-10-22

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

## 2. 详细 TODO

### 2.1 跨包 import 解析（任务 2）

- **现状**：`resolveImportFiles` 在 `lib/src/builders/shared/source_index.dart` 中，把任意 `package:foo/x.dart` 映射成当前包的 `lib/x.dart`。
- **影响**：跨包共享组件库（如 `package:shared_ui/src/card.dart`）无法进入依赖分析，相关类型只能退回原生注入 / 可见占位。
- **目标**：读取 `.dart_tool/package_config.json` 的 `rootUri` / `packageUri` 解析真实文件路径；或随 resolved AST 一起解决。
- **入口**：`packages/hot_patch_generator/lib/src/builders/shared/source_index.dart`。
- **验收**：新建一个本地共享 UI 包并在 `example` 中依赖，`@PatchEntry` 组件 import 其组件后能正常产出 JS、运行时无占位。
- **备注**：在解析能力就位前，不要在该分支做启发式猜测。

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
> `new X({...})`；`__h` 下沉到 `flutter.js` 的宿主包装类内部；局部变量 / 字段 /
> 列表 / 三目不再需要 widget 特判。
>
> 采用方案：**构造即实例 + 消费时归一化**（不做构造函数双模、不生成 XxxElement）。
>
> 分支：`feature/widget-class-protocol`
> 起点：`5f3b5ac`（任务 9、局部 widget 变量、spread 修复已提交）

### 4.1 运行时协议

- `__element(type, props)`：组件类元素描述（`{type, props, children, element}`）。
- `__h(type, props)`：`type` 是函数时返回 `__element(type, props)`，不实例化。
- `__asElement(v)` / `__asElementList(v)`：组件实例按普通类语义构造后，父级消费
  时折算成元素描述。判据是原型上有没有 `build`（组件类的语言级特征），
  **不查类型名表**，也不需要 `toJson` / 内部 token / 特殊标记。
- `mount` / `patch` 入口、`__h` 的每个 props 值（含数组）都走同一归一化。
- 生成类构造函数恢复普通语义：`new CommunityPage(props)` 即实例，首行保留
  `this.props = args`，供归一化还原元素 props。

### 4.2 宿主包装类生成（已完成）

- `flutter.js` 为 `hostWrapperTypes`（宿主 widget + 数据载体，排除逻辑组件 /
  builder 代理）生成包装类：`class Text { constructor(props) { return __h('Text', props); } }`。
- 数据载体 `InputDecoration` 同样生成包装类。
- builder 命名构造类型（ListView 等）保持真实类，供 `.builder/.separated`
  挂载；普通构造 / delegate 形态仍由翻译层发 `__h('ListView', ...)` 宿主结点。

### 4.3 翻译器统一发射 `new`（已完成）

- 有 JS 类的类型（宿主包装 / 组件 / 逻辑组件 / 代理）→ `new Type(props)`；
  无 JS 类的原生注入类型 → `__h('Type', props)` 兜底。
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
- 更新架构文档、组件支持文档、使用手册与生成器 README（中英文）：产物协议改为
  `new Type(props)`、宿主包装类、`__asElement` 归一化。
- 版本协议兼容边界：
  - **旧产物在新运行时下可用**：`__h('X', props)` 仍产出元素描述；旧组件类忽略多余实参，
    构造即实例，`__asElement` 按原型 `build` 归一化；
  - **新产物需要新运行时 / 新 `flutter.js`**：产物会 `import` 宿主包装类与 `__asElement`，
    旧运行时缺少这些导出；补丁包按整包更新，不存在新旧混载；
  - 无 JS 类的类型（无产物自定义组件 / 原生注入）继续走 `__h('X', props)` 兜底。
- 全量 demo 验证：TestWidget、Provider、PageView、列表页、详情页均由用户手动确认。

### 4.5 已知风险

| 风险 | 处理 |
|---|---|
| 自定义组件的用户代码构造会执行字段初始化（控制器 / Key 句柄） | 已修复二次构造：实例随元素下发（`el.inst`），mount 直接复用、不再 new 第二次；patch 复用旧实例保持状态 |
| 懒容器声明式子项（`TabBarView(children:)` / `PageView(children:)`）一次性挂载全部子页 | **已修复（2026-10-23 重构）**：懒与否改为**构建期配置**——生成器 `js_widget_defs.dart` 的 `lazyChildHostTypes` 写入 `flutter.js`，`__h` 给元素打 `lazyChildren` 标记；运行时只认元素标记，零类型表。懒槽位协议不变：先下发零尺寸占位，宿主 inflate 时经 `__lazyFn` 回调 `lazyMount`、dispose 时经 `__lazyOffFn` 回调 `lazyUnmount`；真实子树挂成占位结点的 `child` slot（占位 id/key 不变）。builder 形态（`ListView.builder` / `GridView.builder`）在懒容器下**连 itemBuilder 调用也推迟**，宿主 inflate 到该项时才执行 |
| builder 代理类型（ListView 等）无宿主包装类 | 普通构造 / delegate 形态仍发 `__h('ListView', …)` 宿主结点；`.builder/.separated` 才 `new ListView(props)` |
| 数据载体 / InputDecoration | 生成包装类，保持宿主 renderer 读取方式不变 |
| 宿主包装类名与本地组件类名同名 | 暂未处理（JS 会重复声明）；命名冲突时需单独约定 |
| const widget 身份 | 仍按 props/key diff，不依赖对象身份 |
| 旧产物兼容 | 旧产物里的 `__h(X, props)` / 实例构造继续按原语义工作 |
