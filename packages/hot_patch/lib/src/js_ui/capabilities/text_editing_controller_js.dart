// 由 runtime_source.dart 拆出的 TextEditingController JS 片段（能力内聚）。
// runtime_source 把骨架与各能力片段拼接后注入（同一 IIFE 作用域）。
const String textEditingControllerJsSource = r'''
  // TextEditingController：JS 侧代理类，与宿主真实 TextEditingController 按
  // **句柄 id** 绑定（通用层，同 ScrollController 模式，见【1b】句柄注册表）：
  //   - 构造：登记 kind=ctrl/Text 句柄（scope=page）+ host 通知宿主创建真实
  //     controller 并登记输入回传句柄；TextField(controller: 句柄) 渲染时宿主按
  //     id 取真实实例，用户输入经 textFn 回传 JS 镜像并触发 listeners。
  //   - text：本地镜像（宿主回传更新），setter 发 host SetText 同步宿主；
  //   - selection：本地镜像，setter 发 host SetSelection；
  //   - clear()：发 host Clear + 清镜像；
  //   - dispose：通用 releaseHandle（释放内部句柄 + 通知宿主释放真实 controller）。
  // 跨桥序列化：props 里的实例经 toJSON 输出 `{__handle: id}`。
  defineHandleKind('ctrl/Text', {
    release: function (h) {
      var tec = h.obj;
      if (!tec) { return; }
      if (tec.__textFn) { releaseHandle(tec.__textFn.__fn, false); tec.__textFn = null; }
      tec.__listeners = [];
    }
  });
  function TextEditingController(initial) {
    this.__listeners = [];
    this.__text =
      (initial && typeof initial.text === 'string') ? initial.text : '';
    this.__selection = null;
    var self = this;
    this.__textFn = fn(function (t) { self.__onHostText(t); });
    // 登记为句柄（scope=page）：自动同步宿主 onCreate（meta 携带输入回传句柄）。
    this.__id = reg(this, 'ctrl/Text', { meta: { fn: this.__textFn } });
  }
  TextEditingController.prototype.addListener = function (f) {
    if (typeof f === 'function') { this.__listeners.push(f); }
  };
  TextEditingController.prototype.removeListener = function (f) {
    var i = this.__listeners.indexOf(f);
    if (i >= 0) { this.__listeners.splice(i, 1); }
  };
  TextEditingController.prototype.__notify = function () {
    var fs = this.__listeners;
    for (var i = 0; i < fs.length; i++) { fs[i](); }
  };
  TextEditingController.prototype.clear = function () {
    this.__text = '';
    if (this.__id != null) { handleOp(this.__id, 'call', { method: 'clear' }); }
    this.__notify();
  };
  TextEditingController.prototype.dispose = function () {
    releaseHandle(this.__id);
    this.__id = null;
  };
  TextEditingController.prototype.toJSON = function () {
    return { __handle: this.__id };
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
  // 宿主回传（TextField 输入后同步镜像 + 触发 listeners）。
  TextEditingController.prototype.__onHostText = function (t) {
    this.__text = (t == null) ? '' : String(t);
    var fs = this.__listeners;
    for (var i = 0; i < fs.length; i++) { fs[i](); }
  };
  G.TextEditingController = TextEditingController;
''';
