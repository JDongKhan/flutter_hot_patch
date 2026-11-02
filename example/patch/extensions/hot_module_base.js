// GENERATED CODE - DO NOT EDIT
// Dart extension 注册（package:hot_module_base）：由 hot_patch_generator 生成
// 使用方 import 本文件即完成注册（`registerExtension(...)`），无需预热。


// 扩展 StringLogExtension（package:hot_module_base/src/string_log_extension.dart）
export const StringLogExtension = registerExtension("String", (function () {
  "use strict";
  return {
    logText: function (tag) {
      print("[" + tag + "] " + this + " 依赖库日志");
    },
  };
})(), { id: "package:hot_module_base/src/string_log_extension.dart#StringLogExtension" });
