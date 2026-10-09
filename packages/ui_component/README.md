# ui_component

声明式注解包：把一个**完全正常的 Flutter widget** 标记为「可动态下发的 UI 组件」。

注解只是**构建期元数据**，不会改变组件的任何运行时行为——组件照旧在被引用处正常工作；
线上出问题时，再由运行时加载对应的 JS 版本做热修复，无需发版。

## 安装

```yaml
dependencies:
  ui_component: ^0.1.0
```

## 使用

```dart
import 'package:flutter/material.dart';
import 'package:ui_component/ui_component.dart';

@UIComponent('Counter')
class Counter extends StatefulWidget {
  const Counter({super.key});

  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  int _count = 0;

  void _inc() => setState(() => _count++);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('count = $_count'),
        ElevatedButton(onPressed: _inc, child: const Text('+1')),
      ],
    );
  }
}
```

这个类仍然是一个普通的 `StatefulWidget`，可以直接使用。把 `ui_component_generator`
加进 `dev_dependencies` 后，`build_runner` 会在构建期把它翻译成同名的 JS 模块，
由 `hot_patch` 的 `JsUiWidget` 在运行时加载渲染。

## 注解

### `@UIComponent(name)`

标记一个类为可动态下发的 UI 组件。

- `name`：组件名。运行时用 `JsUiWidget(component: name)` 实例化 JS 版本。
- 热更基于**整个 widget**，不做字段/方法级标注。生成器默认全量收集：
  - 所有非 static 字段 → JS 状态（`_count` → `count`）
  - 所有方法（除 build / 生命周期）→ JS 事件方法（构建期以 `this.__bind` 绑定）
  - `build()` → JS 渲染入口
  - SnackBar 形式的方法 → 自动识别为原生通道（`sendMessage`）

### `@UIComponentIgnore()`

标记一个组件「不参与连带转换」。

默认情况下，`@UIComponent` 组件 build 里用到的本文件私有组件或无注解公共组件，
会被生成器**连带翻译**成 JS 类注册进同一产物。标上本注解后：

- 生成器跳过该组件（不生成 JS 类、不注册）；
- build 树里引用它的位置保持 Component 节点（无 import），运行时由原生注入渲染
  （`JsUiWidget.nativeComponents`）。

适用场景：组件逻辑复杂 / 含原生依赖，不适合翻译成 JS，希望线上热更时始终使用原生实现。

## 相关包

| 包 | 作用 |
| --- | --- |
| `ui_component` | 本包：注解 |
| `ui_component_generator` | 构建期把注解组件静态翻译为 JS 模块（dev_dependency） |
| `hot_patch` | 运行时加载 JS 补丁渲染组件，由 JS 驱动逻辑 |

## License

MIT