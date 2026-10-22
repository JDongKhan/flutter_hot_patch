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
| 8 | 移除方法名映射，改为 JS 原型注入 | 中 | 待开始 | P1-8 | `where/add/removeAt/insert/toList/compareTo/first/last` 原样翻译并通过 demo |
| 9 | `registerNativeComponent` 支持 children / slots | 中 | 待开始 | P0-4 | 未注册容器组件的子树不再丢失 |
| 10 | `builtinWidgetTypes` 改为直接父类判定 | 中 | 待开始 | P1-9 | 删除表后 demo 产物与页面表现一致 |

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

### 2.3 `builtinWidgetTypes` 改为直接父类判定（任务 10 / 评审 P1-9）

- **已确认口径**：只识别直接 `extends StatefulWidget / StatelessWidget / State`；**不处理**自定义 `MyBaseWidget` 的情况；resolved AST 迁移另列 TODO。
- **方案**：
  - 能解析到声明的类：按直接父类判定是否 Widget；
  - 完全解析不到的类型（如 `package:flutter` 提供的 `Text` / `Column`）：按宿主 Widget 值处理；
  - 对“解析不到但又不确定是否为 Widget”的类型增加构建期告警，避免静默误判。
- **风险**：未知类型可能被误当成 Widget 值，需要告警兜底。
- **验收**：删除 `builtinWidgetTypes` 后，现有 demo 的字段类型判定、依赖扫描与产物输出保持一致。

### 2.4 暂缓项（本轮不做）

| 项 | 原因 | 后续动作 |
|---|---|---|
| 全局模块表 `__modules` 的多页面 / 多版本隔离 | 已确认先不动 | 单独立项，评估 per-page / per-bundle 模块表与 manifest 协议版本 |
| 远程补丁 hash / 签名校验 | 改动面较大，先做路径穿越与大小上限 | 安全专项统一评估 |
| 构建期 O(N²) 扫描（`componentTranslationScope` 每个文件全包扫描） | 需要构建缓存设计 | 性能专项 |
| 未支持语法（`try/catch`、`throw`、pattern、extension、标准库 shim 等）完整支持 | 属于翻译内核能力扩展 | 随 resolved AST 或独立批次推进 |
| 深层 props diff / 高频事件性能 | 需要基准测试 | 性能专项 |

## 3. 维护约定

- 新增 TODO：先写入本文件，再在代码处留 `TODO(名称): 见 TODO.md` 指针。
- 状态取值：`待开始` / `进行中` / `待验证` / `已完成`。
- 每项实现完成后，在提交说明或对话中给出验证命令与结果；负责人验证通过后再开始下一项。
- 已完成项保留记录，不删除，便于回溯改动顺序。
- **异常 / 未支持场景必须有日志**：任何翻译失败、分支未覆盖、类型无法识别、运行时异常都至少输出一条 `warn` / `error` 日志，禁止静默返回、静默丢弃或空实现吞掉。新增代码评审时必须检查这一条。
