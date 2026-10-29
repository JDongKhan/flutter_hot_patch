// Focus 能力的 JS 片段：FocusNode 代理类。
//
// 与 ScrollController 同一套句柄层（三件套见【4】defineController）：JS 实例与
// 宿主真实 FocusNode 按**句柄 id** 绑定；本类只写差异——
//   - init：镜像字段（hasFocus / 构造参数）；
//   - onHost：宿主 Focus 回传 hasFocus → 更新镜像并通知 listeners；
//   - meta：构造参数交给宿主创建真实 FocusNode（debugLabel 等）。
//
// requestFocus / unfocus 走通用 op（call），宿主侧分派见
// capabilities/focus/focus_bridge.dart。hasFocus 读**镜像**（不是同步往返），
// 因此 addListener 回调里读到的值始终与刚触发的变化一致。
const String focusJsSource = r'''
  export const FocusNode = defineController('ctrl/Focus', {
    init: function (opts) {
      var o = opts || {};
      this.__hasFocus = false;
      this.__debugLabel = (o.debugLabel != null) ? String(o.debugLabel) : null;
      this.__skipTraversal = o.skipTraversal === true;
      this.__canRequestFocus = o.canRequestFocus !== false;
      this.__descendantsAreFocusable = o.descendantsAreFocusable !== false;
    },
    onHost: function (self, v) {
      self.__hasFocus = v === true;
      self.__notify();
    },
    meta: function (self) {
      return {
        debugLabel: self.__debugLabel,
        skipTraversal: self.__skipTraversal,
        canRequestFocus: self.__canRequestFocus,
        descendantsAreFocusable: self.__descendantsAreFocusable
      };
    }
  });
  FocusNode.prototype.requestFocus = function () {
    if (this.__id != null) { handleOp(this.__id, 'call', { method: 'requestFocus' }); }
  };
  FocusNode.prototype.unfocus = function () {
    if (this.__id != null) { handleOp(this.__id, 'call', { method: 'unfocus' }); }
  };
  Object.defineProperty(FocusNode.prototype, 'hasFocus', {
    get: function () { return this.__hasFocus === true; }
  });
''';
