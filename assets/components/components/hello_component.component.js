// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/components/hello_component.dart 自动生成
// 重新生成：dart run build_runner build

// 组件注册表：多个 JS 补丁共享，加载顺序无关
var __components = __components || {};

// IIFE 闭包：方法/状态不泄漏到全局，加载多个 JS 不会重名
__components['HelloCard'] = (function() {
  var __state = {
    _count: 0,
  };

  function inc() { __state._count += 1; }
  function reset() { __state._count = 0; }
  function showNative() { sendMessage("nativeToast", JSON.stringify({ message: "Hello from native (JS-driven)" })); }

  function build() {
    return { type: "Column", children: [
      { type: "Text", props: { data: "Hello from JS logic", style: "title" } },
      { type: "Text", props: { data: "count = " + __state._count, style: "body" } },
      { type: "Row", children: [
        { type: "Button", props: { label: "+1", event: "inc" } },
        { type: "Button", props: { label: "Reset", event: "reset" } },
        { type: "Button", props: { label: "Native", event: "showNative" } }
      ] }
    ] };
  }

  return { __state: __state, inc: inc, reset: reset, showNative: showNative, build: build };
})();

