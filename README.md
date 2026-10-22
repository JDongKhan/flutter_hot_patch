# flutter_hot_patch

「注解组件 → JS 热更」框架的 monorepo（Dart **pub workspace**）。

## 目录结构

| 目录 | 说明 |
|---|---|
| `packages/hot_patch_annotations` | 声明式注解（`@PatchEntry` / `@PatchIgnore` / `@HostInjected`） |
| `packages/hot_patch_generator` | 编译期：Dart widget → JS 翻译与产物组装（build_runner builders） |
| `packages/hot_patch` | 运行期：JS 运行时 + 宿主渲染 + 能力桥 |
| `example/` | 示例 App：原生 vs JS 热更对比 Demo（业务 Dart 单源在 `example/lib/`，生成的 JS 产物在 [example/patch/](example/patch/)） |
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

## 发布

```bash
# 预检并发布三个包（已发布的版本自动跳过）
bash publish_packages.sh

# 只做发布预检，不上传
bash publish_packages.sh --dry-run
```

脚本固定使用 `PUB_HOSTED_URL=https://pub.dev`：本机默认的 `pub.flutter-io.cn`
是只读镜像，不能直接上传（会报 `Authentication failed`）；发布到 pub.dev 后
镜像会自动同步。凭证失效时先执行 `dart pub login`。

## 文档

| 文档 | 内容 |
|---|---|
| [使用手册](docs/使用手册.md) | 接入四步、注解速查、构建配置、运行时接入、本地联调、常见问题 |
| [项目架构文档](docs/项目架构文档.md) | 核心设计定律、架构总览、核心机制、设计红线、扩展指引、关键文件索引 |
| [组件支持文档](docs/组件支持文档.md) | 组件支持矩阵、样式/值/事件协议、通用翻译能力、已知限制、JS 引擎能力基线 |
| [TODO.md](TODO.md) | 待办任务、实施顺序、详细 TODO 与暂缓项 |
| [app-prototype.html](docs/app-prototype.html) | 示例 App 原型（HTML） |
| [hot_patch_annotations](packages/hot_patch_annotations/README.md) | 注解包：`@PatchEntry` / `@PatchIgnore` |
| [hot_patch_generator](packages/hot_patch_generator/README.md) | 生成器：产物布局、配置项、翻译设计原则、新增 widget 支持 |
| [hot_patch](packages/hot_patch/README.md) | 运行时：补丁加载、宿主能力桥、日志 |
