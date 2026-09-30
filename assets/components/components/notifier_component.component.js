// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/components/notifier_component.dart 自动生成
// 重新生成：dart run build_runner build

import { CounterModel } from '../model/counter_model.model.js';

export class NotifierCard {
  constructor() {
    this._model = new CounterModel({});
  }
  _inc() { this._model.inc(); }
  _reset() { this._model.reset(); }
  dispose() { this._model.dispose(); }
  build() {
    return {
      "type": "Card",
      "children": [
        {
          "type": "Padding",
          "props": {
            "padding": {
              "left": 16.0,
              "top": 16.0,
              "right": 16.0,
              "bottom": 16.0
            }
          },
          "children": [
            {
              "type": "Column",
              "props": {
                "mainAxisSize": "min"
              },
              "children": [
                {
                  "type": "ListenableBuilder",
                  "props": {
                    "listenable": "_model",
                    "builder": "_lbBuilder0"
                  }
                },
                {
                  "type": "SizedBox",
                  "props": {
                    "height": 12
                  }
                },
                {
                  "type": "Row",
                  "props": {
                    "mainAxisAlignment": "center"
                  },
                  "children": [
                    {
                      "type": "Button",
                      "props": {
                        "kind": "elevated",
                        "label": "+1",
                        "event": "_inc"
                      }
                    },
                    {
                      "type": "SizedBox",
                      "props": {
                        "width": 12
                      }
                    },
                    {
                      "type": "Button",
                      "props": {
                        "kind": "elevated",
                        "label": "Reset",
                        "event": "_reset"
                      }
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
    };
  }
  _lbBuilder0() {
      return {
      "type": "Text",
      "props": {
        "data": "count = " + this._model.count,
        "style": {
          "fontSize": 24,
          "fontWeight": "bold"
        }
      }
    };
  }
}

