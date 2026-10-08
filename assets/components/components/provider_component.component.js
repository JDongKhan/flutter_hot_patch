// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/components/provider_component.dart 自动生成
// 重新生成：dart run build_runner build

import { CounterModel } from '../model/counter_model.model.js';

export class ProviderCard {
  constructor() {
    this._modelA = new CounterModel({});
    this._modelB = new CounterModel({});
  }
  _incA() { this._modelA.inc(); }
  _resetA() { this._modelA.reset(); }
  _incB() { this._modelB.inc(); }
  _resetB() { this._modelB.reset(); }
  dispose() { this._modelB.dispose(); }
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
              "type": "MultiProvider",
              "props": {
                "providers": [
                  {
                    "type": "ChangeNotifierProvider",
                    "props": {
                      "model": "CounterModel",
                      "create": {
                        "ref": "_modelA"
                      }
                    }
                  },
                  {
                    "type": "ChangeNotifierProvider",
                    "props": {
                      "model": "CounterModel",
                      "value": {
                        "ref": "_modelB"
                      }
                    }
                  }
                ],
                "child": {
                  "type": "Column",
                  "props": {
                    "mainAxisSize": "min"
                  },
                  "children": [
                    {
                      "type": "Text",
                      "props": {
                        "data": "MultiProvider · 两个模型各自局部重建"
                      }
                    },
                    {
                      "type": "SizedBox",
                      "props": {
                        "height": 8
                      }
                    },
                    {
                      "type": "Consumer",
                      "props": {
                        "model": "CounterModel",
                        "builder": "_consumerBuilder0"
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
                            "label": "A +1",
                            "event": "_incA"
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
                            "label": "A Reset",
                            "event": "_resetA"
                          }
                        }
                      ]
                    },
                    {
                      "type": "SizedBox",
                      "props": {
                        "height": 8
                      }
                    },
                    {
                      "type": "Consumer",
                      "props": {
                        "model": "CounterModel",
                        "builder": "_consumerBuilder1"
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
                            "label": "B +1",
                            "event": "_incB"
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
                            "label": "B Reset",
                            "event": "_resetB"
                          }
                        }
                      ]
                    }
                  ]
                }
              }
            }
          ]
        }
      ]
    };
  }
  _consumerBuilder0(value) {
      return {
      "type": "Text",
      "props": {
        "data": "A = " + value.count,
        "style": {
          "fontSize": 22,
          "fontWeight": "bold",
          "color": '#2196F3'
        }
      }
    };
  }
  _consumerBuilder1(value) {
      return {
      "type": "Text",
      "props": {
        "data": "B = " + value.count,
        "style": {
          "fontSize": 22,
          "fontWeight": "bold",
          "color": '#4CAF50'
        }
      }
    };
  }
}

