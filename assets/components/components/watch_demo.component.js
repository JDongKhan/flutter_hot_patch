// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/components/watch_demo.dart 自动生成
// 重新生成：dart run build_runner build


export class WatchDemo {
  constructor() {
  }
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
              "type": "ChangeNotifierProvider",
              "props": {
                "model": "CounterModel",
                "create": {
                  "construct": "CounterModel"
                },
                "child": {
                  "type": "Builder",
                  "props": {
                    "builder": "_builder0"
                  }
                }
              }
            }
          ]
        }
      ]
    };
  }
  _builder0() {
      var model = this.__watch("CounterModel");
      return {
      "type": "Column",
      "props": {
        "mainAxisSize": "min"
      },
      "children": [
        {
          "type": "Text",
          "props": {
            "data": "context.watch<CounterModel>"
          }
        },
        {
          "type": "Text",
          "props": {
            "data": "count = " + model.count,
            "style": {
              "fontSize": 22,
              "fontWeight": "bold",
              "color": '#FF5722'
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
                "event": "model.inc()"
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
                "event": "this.__read(\"CounterModel\").reset()"
              }
            }
          ]
        }
      ]
    };
  }
}

