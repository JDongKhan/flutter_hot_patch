// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/components/composite_component.dart 自动生成
// 重新生成：dart run build_runner build

// 组件注册表：多个 JS 补丁共享，加载顺序无关
var __components = __components || {};
// 实例注册表：每个 HotPatchWidget 持有自己的组件实例（状态互不共享）
var __instances = __instances || {};

// IIFE 闭包：不泄漏到全局，加载多个 JS 不会重名
__components['DashboardCard'] = (function() {
  // 构造函数：new 一次得到一个独立组件实例，可重复实例化
  function DashboardCard() {
    this._ticks = 0;
  }

  DashboardCard.prototype.tick = function() { this.setState(function(){ this._ticks += 1; }); };

  DashboardCard.prototype.build = function() {
    return {
      "type": "Column",
      "children": [
        {
          "type": "Text",
          "props": {
            "data": "Dashboard (JS)",
            "style": {
              "fontSize": 22,
              "fontWeight": "w600"
            }
          }
        },
        {
          "type": "Text",
          "props": {
            "data": "ticks = " + this._ticks
          }
        },
        {
          "type": "Component",
          "props": {
            "component": "BannerCard",
            "import": "assets/components/components/banner_component.component.js"
          }
        },
        {
          "type": "SizedBox",
          "props": {
            "height": 12
          }
        },
        {
          "type": "Component",
          "props": {
            "component": "_LabeledDivider",
            "import": "assets/components/components/composite_component.component.js",
            "args": {
              "text": "private widget"
            }
          }
        },
        {
          "type": "SizedBox",
          "props": {
            "height": 8
          }
        },
        {
          "type": "Component",
          "props": {
            "component": "LabeledDivider",
            "args": {
              "text": "public widget"
            }
          }
        },
        {
          "type": "SizedBox",
          "props": {
            "height": 12
          }
        },
        {
          "type": "Button",
          "props": {
            "kind": "elevated",
            "label": "Tick",
            "event": "tick",
            "style": {
              "backgroundColor": '#FF9800',
              "foregroundColor": '#FFFFFF'
            }
          }
        }
      ]
    };
  };

  return DashboardCard;
})();

// IIFE 闭包：不泄漏到全局，加载多个 JS 不会重名
__components['_LabeledDivider'] = (function() {
  // 构造函数：new 一次得到一个独立组件实例，可重复实例化
  function _LabeledDivider(args) {
    this.text = (args && args.text !== undefined) ? args.text : '';
  }


  _LabeledDivider.prototype.build = function() {
    return {
      "type": "Column",
      "children": [
        {
          "type": "Text",
          "props": {
            "data": "— " + this.text + " —",
            "style": {
              "fontSize": 12
            }
          }
        },
        {
          "type": "SizedBox",
          "props": {
            "height": 4
          }
        }
      ]
    };
  };

  return _LabeledDivider;
})();

