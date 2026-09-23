/// 标记一个类为可动态下发的 UI 组件（正常 Flutter widget）。
///
/// 生成器（ui_component_generator）据此把该组件翻译为 JS 描述模块 + schema：
///   - [name]：组件名，客户端用 HotPatchWidget(component: name) 实例化 JS 版本
///
/// 热更是**基于整个 widget** 的，不做字段/方法级标注：
/// 生成器默认全量收集——
///   所有非 static 字段 → JS 状态 __state（_count → count）
///   所有方法（除 build/生命周期）→ JS 事件分支（handleEvent）
///   build()           → JS 渲染入口（原封不动翻译为 build 函数）
///   SnackBar 形式的方法 → 自动识别为 native 通道（sendMessage）
///
/// 注解只是构建期元数据，不影响组件正常运行：
/// 线上出 bug 时，运行时切换到 HotPatchWidget 加载 JS 版本即可热修复，无需发版。
class UIComponent {
  final String name;
  const UIComponent(this.name);
}
