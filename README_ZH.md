# flutter_hot_patch（简体中文）

[English](README.md)

**Flutter 组件热更新框架**：线上组件出 bug 时，不发版也能修复。

Flutter 的 AOT 编译产物无法热更，线上缺陷只能等应用商店审核、重新发版。本框架把「可能出问题的
组件」在编译期翻译成等价的 JS，运行时由 JS 引擎加载补丁并驱动其逻辑，**渲染仍由原生 Flutter
完成**——因此修复一个组件只需下发一份 JS 补丁，无需重新发版。

组件本身不需要任何改造：被热更的类始终是一个完全正常的 Flutter widget，只有真正需要修复时才加载
它的 JS 版本。

## 工作方式

1. 给组件加 `@PatchEntry` 注解（注解来自 `hot_patch_annotations`）；
2. 构建期由 `hot_patch_generator` 把它**静态翻译**为等价的 JS 模块（不执行 Dart 代码）；
3. 运行时由 `hot_patch` 的 `JsUiWidget` 加载这份 JS 补丁：**逻辑在 JS 中执行**，
   结点渲染回落到原生 Flutter。

## 仓库结构

本仓库是一个 Dart **pub workspace** 形式的 monorepo，三块职责按包拆分：

| 目录 | 说明 |
|---|---|
| `packages/hot_patch_annotations` | 声明式注解（`@PatchEntry` / `@PatchIgnore` / `@HostInjected`） |
| `packages/hot_patch_generator` | 编译期：Dart widget → JS 翻译与产物组装（build_runner builders） |
| `packages/hot_patch` | 运行期：JS 运行时 + 宿主渲染 + 能力桥 |
| `example/` | 示例 App：原生 vs JS 热更对比 Demo（业务 Dart 单源在 `example/lib/`，生成的 JS 产物在 [example/patch/](example/patch/)） |
| `tool/patch_server.dart`、`tool/server/`、`start_patch_server.sh` | 本地服务：`/patch/*` 静态产物路由 + 普通接口路由（按 URL 路径读 `tool/mock/<路径>.json`） |

根 `pubspec.yaml` 是 workspace 根，各成员 pubspec 声明 `resolution: workspace`，
全仓共享同一份 `pubspec.lock` 与 `.dart_tool/`。

## 起步

```bash
# 根目录一次性安装全部依赖
flutter pub get

# 启动本地 patch 服务：build_runner 生成产物 → 打包 zip → 起 http 服务
bash start_patch_server.sh

# 运行示例 App（补丁由上面的服务提供）
cd example && flutter run
```

## 文档

| 文档 | 内容 |
|---|---|
| [使用手册](docs/使用手册.md) | 接入四步、注解速查、构建配置、运行时接入、本地联调、常见问题 |
| [项目架构文档](docs/项目架构文档.md) | 核心设计定律、架构总览、核心机制、设计红线、扩展指引、关键文件索引 |
| [组件支持文档](docs/组件支持文档.md) | 组件支持矩阵、样式/值/事件协议、通用翻译能力、已知限制、JS 引擎能力基线 |
| [TODO.md](TODO.md) | 待办任务、实施顺序、详细 TODO 与暂缓项 |
| [app-prototype.html](docs/app-prototype.html) | 示例 App 原型（HTML） |
| [hot_patch_annotations](packages/hot_patch_annotations/README_ZH.md) | 注解包：`@PatchEntry` / `@PatchIgnore` |
| [hot_patch_generator](packages/hot_patch_generator/README_ZH.md) | 生成器：产物布局、配置项、翻译设计原则、新增 widget 支持 |
| [hot_patch](packages/hot_patch/README_ZH.md) | 运行时：补丁加载、宿主能力桥、日志 |
