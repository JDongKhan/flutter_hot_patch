# flutter_hot

「注解组件 → JS 热更」框架的 monorepo（Dart **pub workspace**）。

## 目录结构

| 目录 | 说明 |
|---|---|
| `packages/hot_patch_annotations` | 声明式注解（`@PatchEntry` / `@UIComponent` / `@HostInjected` / `@UIComponentIgnore`） |
| `packages/hot_patch_generator` | 编译期：Dart widget → JS 翻译与产物组装（build_runner builders） |
| `packages/hot_patch` | 运行期：JS 运行时 + 宿主渲染 + 能力桥 |
| `example/` | 示例 App：原生 vs JS 热更对比 Demo（业务 Dart 单源在 `example/lib/`，产物在 `example/patch/`） |
| `tool/patch_server.dart`、`start_patch_server.sh` | 本地 patch 静态服务（服务于 `example/patch/`） |

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

架构与设计契约见 [docs/项目架构文档.md](docs/项目架构文档.md)。
