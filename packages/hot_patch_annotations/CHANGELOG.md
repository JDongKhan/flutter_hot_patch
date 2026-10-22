## 0.1.5

- 文档同步：README 中的版本引用更新到当前发布线；与 `hot_patch` 0.2.1 / `hot_patch_generator` 0.2.2 同批发布。注解集与行为无变化。

## 0.1.4

- 清理过时文档：移除已不存在的 `@UIProp` 引用（注解集始终只有 `@PatchEntry` / `@PatchIgnore` / `@HostInjected`，状态字段由生成器全量收集，无需字段级注解）。

## 0.1.3

- 本次**无 API / 行为变更**：注解集、生成器契约与 0.1.2 完全一致。
- 与 `hot_patch_generator` 0.2.0、`hot_patch` 0.2.0 同版本线发版（这一版的重点在生成器的「统一翻译」重构与产物协议变更，`@PatchEntry` / `@HostInjected` 等注解用法不受影响）。

## 0.1.2

- `description` 改为英文，满足 pub.dev 对英文描述的要求（中文描述会被 pana 扣分）。
- README 提供中英双语，顶部可切换。

## 0.1.1

- README 补充 `@HostInjected`（宿主注入）使用手册：标注位置限制、通道名规则、
  调用点翻译形态、参数载荷与 `@args` 协议、Promise 结算语义、`registerHostMethods()` 注册流程。

## 0.1.0

- 首个版本。
- 提供 `@PatchEntry`（标记可动态下发的 UI 组件）与 `@PatchIgnore`（排除连带转换）注解。
- 注解仅为构建期元数据，不影响组件的正常运行。