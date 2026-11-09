// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/grammar/top_level_helper.dart 自动生成
// 重新生成：dart run build_runner build

import { CounterVm } from '../model/counter_vm.js';

export const topLevelPrefix = (value) => { return "顶层:" + value; };
export const topLevelGreet = (__o) => { let name = (__o && __o.name !== undefined) ? __o.name : null; let prefix = (__o && __o.prefix !== undefined) ? __o.prefix : "Hi"; return prefix + ":" + name; };
export const topLevelCounter = () => { return new CounterVm(); };
export const topLevelNums = () => (function* () { yield 1;
  yield 2; }).bind(this)();

