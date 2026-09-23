// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/components/hello_component.dart 自动生成
// 重新生成：dart run build_runner build

var __state = {
  count: 0,
};

function create() {
  return { type: "Column", children: [
    { type: "Text", props: { data: "Hello from JS logic", style: "title" } },
    { type: "Text", props: { data: "count = " + __state.count, style: "body" } },
    { type: "Row", children: [
      { type: "Button", props: { label: "+1", event: "inc" } },
      { type: "Button", props: { label: "Reset", event: "reset" } },
      { type: "Button", props: { label: "Native", event: "native" } }
    ] }
  ] };
}

function handleEvent(action, payload) {
  if (action === "inc") { __state.count += 1; }
  if (action === "reset") { __state.count = 0; }
  if (action === "native") { sendMessage("nativeToast", JSON.stringify({ message: "Hello from native (JS-driven)" })); }
  return create();
}

