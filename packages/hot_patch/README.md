# hot_patch

热更新运行时：加载构建期生成的 JS 补丁，**由 JS 驱动逻辑**，渲染仍发生在原生 Flutter 侧。

面向「线上出 bug → 运行时切到 JS 补丁修复，无需发版」的场景。组件不需要做任何改造：
被热更的类始终是一个完全正常的 Flutter widget，出问题时才加载它的 JS 版本。

## 安装

```yaml
dependencies:
  hot_patch: ^0.1.0
```

## 使用

```dart
JsUiWidget(
  jsAsset: 'assets/components/counter.js',
  component: 'Counter',
)
```

`jsAsset` 支持三种补丁源：

- `assets/...`：随包资源；
- `http(s)://...zip`：网络补丁包，下载解压后走与 asset 一致的加载逻辑；
- 同一 JS 运行时里的其它已加载模块。

### 主要参数

| 参数 | 说明 |
| --- | --- |
| `jsAsset` | 补丁入口 JS（asset 路径或 http(s) zip） |
| `component` | 入口模块里注册的组件类名（即 `@UIComponent` 的 `name`） |
| `props` | 传给组件构造的 props |
| `nativeComponents` | 无 JS 产物的组件（Component 节点）的原生注入：组件名 → 构造。运行时**不 import 业务类**，由业务方在这里注册 |
| `sharedManager` | 共享运行时；多组件共用一个引擎时传入 |
| `entryPath` | 网络补丁包（zip）内入口 .js 的相对路径；不传则按 `component` 反查 |
| `registry` | 宿主 widget 翻译注册表；`null` 用内置集合 |

## 架构

- **渲染入口**：[`JsUiWidget`]（宿主）+ JS 侧的 `__jsui` 运行时
  （element / component / reconciler / context / commit 协议）。
- **状态语义全在 JS 侧**：provider / setState / 任何状态库都在 JS 里实现，
  最终都归约为「JS 重建子树 → 下发 patch → 宿主重建受影响结点」。
  因此宿主代码不随状态库增加而改动——宿主**不理解任何状态语义**。
- **宿主只做两件事**：JS 结点 → Flutter widget 映射（`JsWidgetRegistry`）、
  增量补丁应用（`JsUiStore`）。
- **多实例隔离**：每个 `JsUiWidget` 实例按 `pageKey` 在共享 JS 运行时里隔离自己的根
  （结点树 / provider / 订阅 / 脏队列），同屏多实例、多 runtime 分组都互不影响。

## 扩展：JS → 原生能力

统一走「宿主方法」：JS 侧唯一出口 `__jsui.host(channel, args)`（返回 Promise，
可用 `await`），宿主侧唯一入口 `JsRuntimeManager.registerHostMethod(channel, impl)`。
JS 传来的 `{id, args}` 按 Dart 调用语义（位置/具名实参、默认值）还原后执行，
返回值经 `__jsui.resolve` 回填 Promise。

业务方法用 `@HostInjected()` 注解，由生成器自动收集并注册；框架内建通道
（`log` / `nativeToast` / `jsuiCommit`）在 `JsUiWidget` 启动时自动注册。

```dart
@HostInjected()
static String greet(String name) => 'Hi, $name';
```

```dart
// 或手动注册任意通道
JsRuntimeManager.registerHostMethod('myChannel', (String a) => ...);
```

## 日志

```dart
HotPatchLog.enabled = false; // 生产环境一行关闭（默认 kDebugMode）
```

## 相关包

| 包 | 作用 |
| --- | --- |
| `ui_component` | 注解 |
| `ui_component_generator` | 构建期把注解组件静态翻译为 JS 模块（dev_dependency） |
| `hot_patch` | 本包：运行时加载 JS 补丁渲染组件，由 JS 驱动逻辑 |

## License

MIT