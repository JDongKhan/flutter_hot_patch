/// 标记一个类为可动态下发的 UI 组件（正常 Flutter widget）。
///
/// 生成器（ui_component_generator）据此把该组件翻译为 JS 描述模块 + schema：
///   - [name]：组件名，客户端用 JsWidget(component: name) 实例化 JS 版本
///   - 生成器从 createState() 找到 State 类，读取：
///       @UIProp 字段 → JS 状态 __state
///       build()    → JS 节点树（create）
///       @UIAction 方法 → JS 事件分支（handleEvent）
///
/// 注解只是构建期元数据，不影响组件正常运行：
/// 线上出 bug 时，运行时切换到 JsWidget 加载 JS 版本即可热修复，无需发版。
class UIComponent {
  final String name;
  const UIComponent(this.name);
}

/// 标记 State 里的一个字段为组件对外暴露的状态。
///
/// 进入 JS 侧的 __state 初始状态；build() 里对它的引用（含 `$字段` 插值）
/// 会被翻译为 `__state.xxx`。字段名建议用下划线私有名，[name] 是公开状态名。
class UIProp {
  final String name;
  const UIProp(this.name);
}

/// 标记 State 里的一个方法为组件可被事件触发的动作。
///
/// 生成器为其生成 handleEvent 分支（方法体需是静态可翻译的写法）：
///   - `void _inc() => setState(() => _count++);`   → `__state.count += 1`
///   - `void _reset() { setState(() { _count = 0; }); }` → `__state.count = 0`
///   - [native] 非空时（如 'nativeToast'）：方法体按 SnackBar 模式翻译，
///     生成 `sendMessage('nativeToast', JSON.stringify({message: ...}))`，
///     由 Flutter 原生侧接住展示（JS→Flutter 方向）。
class UIAction {
  final String name;

  /// 非空：该动作改为调用 Flutter 原生通道（JS→Flutter 方向）
  final String? native;
  const UIAction(this.name, {this.native});
}
