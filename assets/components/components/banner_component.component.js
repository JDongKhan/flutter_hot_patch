// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/components/banner_component.dart 自动生成
// 重新生成：dart run build_runner build

// 组件注册表：多个 JS 补丁共享，加载顺序无关
var __components = __components || {};
// 实例注册表：每个 HotPatchWidget 持有自己的组件实例（状态互不共享）
var __instances = __instances || {};

// IIFE 闭包：不泄漏到全局，加载多个 JS 不会重名
__components['BannerCard'] = (function() {
  // 构造函数：new 一次得到一个独立组件实例，可重复实例化
  function BannerCard() {
    this._views = 0;
  }

  BannerCard.prototype.initState = function() { this._views = 5; };
  BannerCard.prototype.bump = function() { this.setState(function(){ this._views += 1; }); };

  BannerCard.prototype.build = function() {
    return {
      "type": "Column",
      "children": [
        {
          "type": "Text",
          "props": {
            "data": "Banner from another file",
            "style": {
              "fontSize": 20,
              "color": '#009688'
            }
          }
        },
        {
          "type": "Text",
          "props": {
            "data": "views = " + this._views
          }
        },
        {
          "type": "Button",
          "props": {
            "label": "Bump",
            "event": "bump"
          }
        }
      ]
    };
  };

  return BannerCard;
})();

