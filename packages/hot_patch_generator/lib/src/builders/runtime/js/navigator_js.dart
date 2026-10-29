// Navigator（Dart 类名 1:1）：只在弹层（showDialog 系列）内有意义。
//
// 面板的路由栈在宿主侧，打开/关闭的 JS 侧落点（`panelPop` / `panelOf`）由
// runtime.js 的 portal 能力拥有。本类只是**值类风格的对外形状**，跨模块
// 经 `G.__core` 取那两个函数（见 runtime_js.dart【11.5】），不新开通道。
const String navigatorJsSource = r'''
  export class Navigator {
    constructor(context) { this.__context = context; }
    static of(context, opts) { return new Navigator(context); }
    static maybeOf(context, opts) { return new Navigator(context); }
    static pop(context, result) { return panelPop(context, result); }
    static maybePop(context, result) { return panelPop(context, result); }
    pop(result) { return panelPop(this.__context, result); }
    maybePop(result) { return panelPop(this.__context, result); }
    canPop() { return panelOf(this.__context) !== null; }
  }
''';
