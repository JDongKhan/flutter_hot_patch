// ScrollController / PageController / FixedExtentScrollController 的 JS 片段
// （随 flutter.js 发布）。
//
// 生成器把 Dart 侧 `final ScrollController _scrollController = ScrollController();`
// 翻译成 `this._scrollController = new ScrollController()`；实例与宿主侧真实
// ScrollController 按**句柄 id** 绑定。
//
// 句柄层（listeners / 回传句柄 / 句柄登记 / dispose / toJSON）由 flutter.js 的
// `JsHandleObject` 提供（见 object_handle_js.dart）；本类只写差异：
//   - offset / position / hasClients：本地镜像（宿主回传 metrics 更新）；
//   - jumpTo/animateTo：实例级 host 通道（载荷带 id，多实例互不干扰）；
//   - addListener/removeListener：JS 闭包直接登记——**匿名闭包天然支持**，
//     无需生成器合成方法名，不存在重名问题。
// 跨桥序列化：props 里的实例经 toJSON 输出 `{__handle: id}`，宿主据此取/建
// 真实 controller（见 scroll_object_bridge.dart）。
//
// 动画实参归一由 `JsHandleObject.__animateArgs` 提供（Scroll / Page 共用）。
const String scrollControllerJsSource = r'''
  export class ScrollController extends JsHandleObject {
    constructor(opts) {
      super();
      var o = opts || {};
      this.offset = 0;
      this.initialScrollOffset =
        (typeof o.initialScrollOffset === 'number') ? o.initialScrollOffset : 0;
      this.keepScrollOffset = (o.keepScrollOffset !== false);
      this.debugLabel = (o.debugLabel != null) ? o.debugLabel : null;
      this.__maxScrollExtent = 0;
      this.__viewportDimension = 0;
      this.__extentAfter = 0;
      // 宿主回传 metrics 快照 → 更新镜像并触发 listeners（listener 无参，
      // 与 Dart addListener 语义一致；闭包内读 this._scrollController.offset）。
      this.__bindHandle('ctrl/Scroll', {
        meta: function (self) {
          return {
            initialScrollOffset: self.initialScrollOffset,
            keepScrollOffset: self.keepScrollOffset,
            debugLabel: self.debugLabel
          };
        },
        onHost: function (self, p) {
          if (!p) { return; }
          self.offset = p.pixels;
          self.__maxScrollExtent = p.maxScrollExtent;
          self.__viewportDimension = p.viewportDimension;
          self.__extentAfter = p.extentAfter;
          self.__notify();
        }
      });
    }
    jumpTo(offset) {
      if (this.__id != null) {
        __handleOp(this.__id, 'call', { method: 'jumpTo', args: [offset] });
      }
    }
    animateTo(offset, opts, curveArg) {
      if (this.__id == null) { return; }
      var a = this.__animateArgs(opts, curveArg);
      __handleOp(this.__id, 'call', { method: 'animateTo', args: [offset, a.ms, a.curve] });
    }
    get position() {
      return {
        pixels: this.offset,
        maxScrollExtent: this.__maxScrollExtent,
        viewportDimension: this.__viewportDimension,
        extentAfter: this.__extentAfter
      };
    }
    get hasClients() { return this.__id != null; }
  }

  // ===== PageController 代理类（对应 Flutter 官方 PageController）=====
  // 与 ScrollController 同一套句柄层；镜像字段只有 page / initialPage。
  // 构造参数（initialPage / viewportFraction）随句柄 create 的 meta 下发给
  // 宿主，真实 PageController 在 JS 构造时就建好。
  export class PageController extends JsHandleObject {
    constructor(opts) {
      super();
      var o = opts || {};
      this.initialPage = (o.initialPage != null) ? o.initialPage : 0;
      this.page = this.initialPage;
      this.viewportFraction = (o.viewportFraction != null) ? o.viewportFraction : 1.0;
      this.__bindHandle('ctrl/Page', {
        // 构造参数（initialPage / viewportFraction）随 create 下发：宿主在
        // JS 构造时就建出参数一致的 PageController（渲染期不再补建，props 里
        // 只有 `{__handle: id}`）。
        meta: function (self) {
          return {
            initialPage: self.initialPage,
            viewportFraction: self.viewportFraction
          };
        },
        onHost: function (self, p) {
          if (p && p.page != null) { self.page = p.page; }
          self.__notify();
        }
      });
    }
    jumpToPage(page) {
      if (this.__id != null) {
        __handleOp(this.__id, 'call', { method: 'jumpToPage', args: [page] });
      }
    }
    animateToPage(page, opts, curveArg) {
      if (this.__id == null) { return; }
      var a = this.__animateArgs(opts, curveArg);
      __handleOp(this.__id, 'call', { method: 'animateToPage', args: [page, a.ms, a.curve] });
    }
    nextPage(opts, curveArg) {
      if (this.__id == null) { return; }
      var a = this.__animateArgs(opts, curveArg);
      __handleOp(this.__id, 'call', { method: 'nextPage', args: [a.ms, a.curve] });
    }
    previousPage(opts, curveArg) {
      if (this.__id == null) { return; }
      var a = this.__animateArgs(opts, curveArg);
      __handleOp(this.__id, 'call', { method: 'previousPage', args: [a.ms, a.curve] });
    }
    get hasClients() { return this.__id != null; }
  }

  // ===== FixedExtentScrollController 代理类（对应 Flutter 官方同名类）=====
  // 供 `CupertinoPicker` / `ListWheelScrollView` 这类「整项滚动」组件使用：
  //   - selectedItem：**宿主回传的镜像**（picker 滚动 → 宿主 listener → 回传
  //     选中项 → 本实例更新并通知 listeners），业务侧只读；
  //   - jumpToItem：走通用 op（call），宿主按 `itemIndex` 计算偏移并跳转；
  //   - initialItem / itemExtent 随句柄 create 的 meta 下发，宿主据此创建真实
  //     controller（渲染期只按 `{__handle}` 取同一实例）。
  export class FixedExtentScrollController extends JsHandleObject {
    constructor(opts) {
      super();
      var o = opts || {};
      this.initialItem = (o.initialItem != null) ? o.initialItem : 0;
      this.itemExtent = (o.itemExtent != null) ? o.itemExtent : null;
      this.selectedItem = this.initialItem;
      this.__bindHandle('ctrl/FixedExtent', {
        onHost: function (self, p) {
          if (p && p.selectedItem != null) { self.selectedItem = p.selectedItem; }
          self.__notify();
        },
        meta: function (self) {
          return { initialItem: self.initialItem, itemExtent: self.itemExtent };
        }
      });
    }
    jumpToItem(index) {
      if (this.__id != null) {
        __handleOp(this.__id, 'call', { method: 'jumpToItem', args: [index] });
      }
    }
    get hasClients() { return this.__id != null; }
  }
''';
