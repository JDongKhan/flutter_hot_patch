// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/components/composite_component.dart 自动生成
// 重新生成：dart run build_runner build

import { BannerCard } from 'banner_component.component.js';

export class DashboardCard {
  constructor() {
    this._ticks = 0;
  }
  tick() { this.setState(function(){ this._ticks += 1; }); }
  build() {
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
            "component": "BannerCard"
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
  }
}

export class LabeledDivider {
  constructor(args) {
    this.text = (args && args.text !== undefined) ? args.text : '';
  }
  build() {
      return {
      "type": "Text",
      "props": {
        "data": "★ " + this.text + " ★",
        "style": {
          "fontSize": 12,
          "color": '#607D8B'
        }
      }
    };
  }
}

export class _LabeledDivider {
  constructor(args) {
    this.text = (args && args.text !== undefined) ? args.text : '';
  }
  build() {
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
  }
}

