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