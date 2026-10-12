// 由 runtime_source.dart 拆出的 TextEditingController JS 片段（能力内聚）。
// runtime_source 把骨架与各能力片段拼接后注入（同一 IIFE 作用域）。
const String textEditingControllerJsSource = r'''
  // TextEditingController：JS 侧代理类，与宿主真实 TextEditingController 按
  // id 绑定（同 ScrollController 模式）：
  //   - 构造：host('textEditingControllerRegister', [id, textFn]) → 宿主创建
  //     真实 controller 并登记输入回传句柄；TextField(controller: 句柄) 渲染时
  //     宿主按 id 取真实实例，用户输入经 textFn 回传 JS 镜像并触发 listeners。
  //   - text：本地镜像（宿主回传更新），setter 发 host SetText 同步宿主；
  //   - selection：本地镜像，setter 发 host SetSelection；
  //   - clear()：发 host Clear + 清镜像；
  //   - dispose：释放登记句柄 + 通知宿主释放真实 controller（幂等）。
  // 跨桥序列化：props 里的实例经 toJSON 输出 `{__jsuiTextEditingController: id}`。
  function TextEditingController(initial) {
    this.__id = nextId('tec');
    this.__listeners = [];
    this.__text =
      (initial && typeof initial.text === 'string') ? initial.text : '';
    this.__selection = null;
    var self = this;
    this.__textFn = fn(function (t) { self.__onHostText(t); });
    if (activeRoot) {
      var list = pageControllers[activeRoot.key] ||
        (pageControllers[activeRoot.key] = []);
      list.push(this);
    }
    host('textEditingControllerRegister', [this.__id, this.__textFn]);
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
    if (this.__id != null) { host('textEditingControllerClear', [this.__id]); }
    this.__notify();
  };
  TextEditingController.prototype.dispose = function () {
    if (this.__textFn) { delete handlers[this.__textFn.__fn]; this.__textFn = null; }
    if (this.__id != null) {
      host('textEditingControllerDispose', [this.__id]);
      this.__id = null;
    }
    this.__listeners = [];
  };
  TextEditingController.prototype.toJSON = function () {
    return { __jsuiTextEditingController: this.__id };
  };
  Object.defineProperty(TextEditingController.prototype, 'text', {
    get: function () { return this.__text; },
    set: function (v) {
      this.__text = (v == null) ? '' : String(v);
      if (this.__id != null) {
        host('textEditingControllerSetText', [this.__id, this.__text]);
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
        host('textEditingControllerSetSelection', [this.__id, b, e]);
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