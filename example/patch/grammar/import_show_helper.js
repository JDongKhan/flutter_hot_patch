// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/grammar/import_show_helper.dart 自动生成
// 重新生成：dart run build_runner build


export const shownConst = "shown";
export const shownGreeting = () => { return "show-greeting"; };

// 模型 ShownModel
export class ShownModel {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.value = (args && args.value !== undefined) ? args.value : 0;
  }
}

