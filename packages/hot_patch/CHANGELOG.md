## 0.1.0

- 首个版本。
- `JsUiWidget` 宿主渲染 + JS 侧 `__jsui` 运行时（element / component / reconciler / context / commit）。
- 状态语义（provider / setState / 其它状态库）全部在 JS 侧实现，宿主不感知状态库。
- 补丁源支持 asset 路径与 http(s) zip 网络补丁包。
- `JsWidgetRegistry` 负责 JS 结点 → Flutter widget 映射，`JsUiStore` 负责增量补丁应用。
- JS → 原生能力统一走「宿主方法」：JS 侧唯一出口 `__jsui.host`，宿主侧唯一入口 `registerHostMethod`（@HostInjected 方法由生成器注册，内建 log / nativeToast / jsuiCommit 自动注册）。
- 每个实例按 `pageKey` 隔离根（结点树 / provider / 订阅 / 脏队列），支持同屏多实例与多 runtime 分组。