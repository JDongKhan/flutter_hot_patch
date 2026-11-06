// GENERATED CODE - DO NOT EDIT
// 跨包产物（package: hot_module_base）：由 hot_patch_generator 生成
// 源文件：package:hot_module_base/src/string_log_extension.dart（一个源文件一份产物）


export const StringLogExtension = registerExtension("String", (function () {
  "use strict";
  return {
    logText: function (tag) {
      tag = (tag === undefined) ? "StringLogExtension" : tag;
      print("[" + tag + "] " + this + " 依赖库日志");
    },
  };
})(), { id: "package:hot_module_base/src/string_log_extension.dart#StringLogExtension" });
