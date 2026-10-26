// 由 runtime_source_js.dart 拆出的 TextEditingController JS 片段（能力内聚）。
// runtime_source 把骨架与各能力片段拼接后注入（同一 IIFE 作用域）。
const String textEditingControllerJsSource = r'''
  // TextEditingController：JS 侧代理类，与宿主真实 TextEditingController 按
  // **句柄 id** 绑定（通用层，同 ScrollController 模式）。
  // 三件套基座（__listeners / 回传句柄 / 句柄登记 / dispose / toJSON）由通用
  // 工厂 defineController 提供（见【1c】）；本类只写差异：
  //   - text：本地镜像（宿主经 textFn 回传更新），setter 发 host set 同步宿主；
  //   - selection：本地镜像，setter 发 host setSelection；
  //   - clear()：发 host clear + 清镜像；
  //   - TextField(controller: 句柄) 渲染时宿主按 id 取真实实例，用户输入经
  //     textFn 回传 JS 镜像并触发 listeners。
  // 跨桥序列化：props 里的实例经 toJSON 输出 `{__handle: id}`。
  var TextEditingController = defineController('ctrl/Text', {
    init: function (initial) {
      this.__text =
        (initial && typeof initial.text === 'string') ? initial.text : '';
      this.__selection = null;
    },
    // 宿主回传（TextField 输入后同步镜像 + 触发 listeners）。
    onHost: function (self, t) {
      self.__text = (t == null) ? '' : String(t);
      self.__notify();
    },
  });
  TextEditingController.prototype.clear = function () {
    this.__text = '';
    if (this.__id != null) { handleOp(this.__id, 'call', { method: 'clear' }); }
    this.__notify();
  };
  Object.defineProperty(TextEditingController.prototype, 'text', {
    get: function () { return this.__text; },
    set: function (v) {
      this.__text = (v == null) ? '' : String(v);
      if (this.__id != null) {
        handleOp(this.__id, 'set', { name: 'text', value: this.__text });
      }
      this.__notify();
    }
  });
  Object.defineProperty(TextEditingController.prototype, 'selection', {
    get: function () { return this.__selection; },
    set: function (s) {
      this.__selection = s;
      if (this.__id != null) {
        var b = (s && typeof s.baseOffset === 'number') ? s.baseOffset : 0;
        var e = (s && typeof s.extentOffset === 'number') ? s.extentOffset : b;
        handleOp(this.__id, 'call', { method: 'setSelection', args: [b, e] });
      }
    }
  });
  G.TextEditingController = TextEditingController;
''';
