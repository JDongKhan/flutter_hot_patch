// Navigator（Dart 类名 1:1）：只在弹层（showDialog 系列）内有意义。
//
// 面板的路由栈在宿主侧，打开/关闭的 JS 侧落点（`panelPop` / `panelOf`）与
// `showDialog` 系列同属 Flutter SDK 面子层，都在本模块（flutter.js）里——
// 见 dialogs_js.dart。二者同一模块作用域，直接互调，不再经 `G.__core`。
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
