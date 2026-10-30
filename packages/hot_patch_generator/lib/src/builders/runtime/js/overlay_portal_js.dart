// OverlayPortal 三件套的 JS 值类（`patch/flutter.js` 值类区）。
//
// OverlayPortal / CompositedTransformTarget / CompositedTransformFollower 本身是
// **宿主组件**（渲染与图层锚定都在 Flutter 侧），JS 侧只需要两个「跨语言对象」：
//
//   - LayerLink：目标与跟随者共享同一个锚点。JS 侧只是一张句柄（宿主持真实
//     `LayerLink()` 实例），元素 props 里传 `{__handle:id}`，宿主按 id 复用同一
//     实例——两端看的是同一个锚，不需要传任何几何数据。
//   - OverlayPortalController：show/hide 改变的是宿主 `OverlayPortal` 的挂载状态，
//     只能由宿主执行；JS 侧发命令（handleOp）并镜像 `isShowing`。
//
// 两者与 GlobalKey / ScrollController 走同一套通用句柄层（defineHandleKind +
// reg），随组件实例释放：组件卸载 → 句柄 release → 宿主侧真实对象同步摘除。
const String overlayPortalJsSource = r'''
  // ── LayerLink：CompositedTransform 的锚点，句柄即身份 ──
  defineHandleKind('layer/Link', {});
  export class LayerLink {
    constructor(props) {
      this.__id = reg(this, 'layer/Link', {});
    }
    toJSON() {
    return { __handle: this.__id };
    }
  }

  // ── OverlayPortalController：命令发往宿主，本侧只镜像 isShowing ──
  // show() / hide() 在未 attach 时也不会丢：宿主 OverlayPortalController 自身
  // 记录 z 序，attach 时接管，故可以在 initState 里直接 show()。
  defineHandleKind('overlay/Portal', {});
  export class OverlayPortalController {
    constructor(props) {
      var debugLabel = __posArgs(props, ['debugLabel']).debugLabel;
      this.__showing = false;
      this.__id = reg(this, 'overlay/Portal', {
        meta: debugLabel == null ? null : { debugLabel: debugLabel }
      });
    }
    toJSON() {
    return { __handle: this.__id };
    }
    show() {
    this.__showing = true;
    if (this.__id != null) { handleOp(this.__id, 'call', { method: 'show' }); }
    }
    hide() {
    this.__showing = false;
    if (this.__id != null) { handleOp(this.__id, 'call', { method: 'hide' }); }
    }
    toggle() {
    if (this.__showing) { this.hide(); } else { this.show(); }
    }
    get isShowing() { return this.__showing; }
  }
''';
