// GENERATED CODE - DO NOT EDIT
// 跨包产物（package: hot_module_base）：由 hot_patch_generator 生成
// 源文件：package:hot_module_base/src/module_symbols.dart（一个源文件一份产物）


export const ModuleBaseLevel = (function () {
  const __enumValues = [];
  function __makeEnumValue(name, index) {
    return {
      name: name,
      index: index,
      toString: function () { return "ModuleBaseLevel." + name; }
    };
  }
  const low = __makeEnumValue("low", 0);
  __enumValues.push(low);
  const high = __makeEnumValue("high", 1);
  __enumValues.push(high);
  return {
    low: low,
    high: high,
    values: __enumValues,
    byName: function (name) {
      for (var i = 0; i < __enumValues.length; i++) {
        if (__enumValues[i].name === name) { return __enumValues[i]; }
      }
      throw new Error("Invalid argument(s): Invalid value: " + name);
    }
  };
})();
export const moduleBaseTag = "module-base";
export const moduleBaseHigh = ModuleBaseLevel.high;
export const moduleBaseLabel = (__o) => { let prefix = (__o && __o.prefix !== undefined) ? __o.prefix : "tag"; return prefix + ":" + moduleBaseTag + "/" + moduleBaseInfo.id; };
export const moduleBaseLevelText = () => { return ModuleBaseLevel.high.name; };

// 模型 ModuleBaseInfo
export class ModuleBaseInfo {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.id = (args && args.id !== undefined) ? args.id : 0;
  }
}

export const moduleBaseInfo = new ModuleBaseInfo({id: 7});
