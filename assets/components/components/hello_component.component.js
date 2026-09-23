// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/components/hello_component.dart 自动生成
// 重新生成：dart run build_runner build

// 组件注册表：多个 JS 补丁共享，加载顺序无关
var __components = __components || {};
// 实例注册表：每个 HotPatchWidget 持有自己的组件实例（状态互不共享）
var __instances = __instances || {};

// IIFE 闭包：不泄漏到全局，加载多个 JS 不会重名
__components['HelloCard'] = (function() {
  // 构造函数：new 一次得到一个独立组件实例，可重复实例化
  function HelloCard() {
    this._count = 0;
  }

  HelloCard.prototype.inc = function() { this.setState(function(){ this._count += 1; }); };
  HelloCard.prototype.reset = function() { this.setState(function(){ this._count = 0; }); };
  HelloCard.prototype.showNative = function() { sendMessage("nativeToast", JSON.stringify({ message: "Hello from native (JS-driven)" })); };

  HelloCard.prototype.build = function() {
    return { type: "Column", children: [
      { type: "Text", props: { data: "Hello from JS logic", style: "title" } },
      { type: "Text", props: { data: "count = " + this._count, style: "body" } },
      { type: "Row", children: [
        { type: "Button", props: { label: "+1", event: "inc" } },
        { type: "Button", props: { label: "Reset", event: "reset" } },
        { type: "Button", props: { label: "Native", event: "showNative" } }
      ] }
    ] };
  };

  return HelloCard;
})();

// IIFE 闭包：不泄漏到全局，加载多个 JS 不会重名
__components['HelloPanel'] = (function() {
  // 构造函数：new 一次得到一个独立组件实例，可重复实例化
  function HelloPanel() {
    this._taps = 0;
  }

  HelloPanel.prototype.tap = function() { this.setState(function(){ this._taps += 1; }); };
  HelloPanel.prototype.clear = function() { this.setState(function(){ this._taps = 0; }); };

  HelloPanel.prototype.build = function() {
    return { type: "Column", children: [
      { type: "Text", props: { data: "HelloPanel (JS)", style: "title" } },
      { type: "Text", props: { data: "taps = " + this._taps, style: "body" } },
      { type: "Row", children: [
        { type: "Button", props: { label: "Tap", event: "tap" } },
        { type: "Button", props: { label: "Clear", event: "clear" } }
      ] }
    ] };
  };

  return HelloPanel;
})();

