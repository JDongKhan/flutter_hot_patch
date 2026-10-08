/// 标记一个类为可动态下发的 UI 组件（正常 Flutter widget）。
///
/// 生成器（ui_component_generator）据此把该组件翻译为 JS 描述模块 + schema：
///   - [name]：组件名，客户端用 JsUiWidget(component: name) 实例化 JS 版本
///
/// 热更是**基于整个 widget** 的，不做字段/方法级标注：
/// 生成器默认全量收集——
///   所有非 static 字段 → JS 状态 __state（_count → count）
///   所有方法（除 build/生命周期）→ JS 事件分支（handleEvent）
///   build()           → JS 渲染入口（原封不动翻译为 build 函数）
///   SnackBar 形式的方法 → 自动识别为 native 通道（sendMessage）
///
/// 注解只是构建期元数据，不影响组件正常运行：
/// 线上出 bug 时，运行时切换到 JsUiWidget 加载 JS 版本即可热修复，无需发版。
class UIComponent {
  final String name;
  const UIComponent(this.name);
}

/// 标记一个组件「不参与连带转换」。
///
/// 默认情况下，@UIComponent 组件的 build 里用到的本文件私有组件
/// （如 `_LabeledDivider`）或无注解公共组件，会被生成器**连带翻译**成
/// JS 类注册进同一产物。标上本注解后：
///   - 生成器跳过该组件（不生成 JS 类、不注册）；
///   - build 树里引用它的位置保持 Component 节点（无 import），
///     运行时由原生注入渲染（nativeComponents / rendererRegistry）。
///
/// 适用场景：某组件逻辑复杂/含原生依赖、不适合翻译成 JS，希望线上
/// 热更时始终使用原生实现；或临时下线某个嵌套组件的 JS 版本。
///
/// 注解只是构建期元数据，不影响组件正常运行。
class UIComponentIgnore {
  const UIComponentIgnore();
}
