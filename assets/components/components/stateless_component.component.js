// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/components/stateless_component.dart 自动生成
// 重新生成：dart run build_runner build


export class StatelessCard {
  constructor(args) {
    this.title = (args && args.title !== undefined) ? args.title : '';
    this.subtitle = (args && args.subtitle !== undefined) ? args.subtitle : '';
    this.badge = (args && args.badge !== undefined) ? args.badge : '';
  }
  build() {
      return {
      "type": "Card",
      "props": {
        "margin": {
          "left": 12.0,
          "top": 12.0,
          "right": 12.0,
          "bottom": 12.0
        }
      },
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
                "mainAxisSize": "min",
                "crossAxisAlignment": "start"
              },
              "children": [
                {
                  "type": "Row",
                  "children": [
                    {
                      "type": "Icon",
                      "props": {
                        "icon": "article",
                        "color": '#009688'
                      }
                    },
                    {
                      "type": "SizedBox",
                      "props": {
                        "width": 8
                      }
                    },
                    {
                      "type": "Expanded",
                      "children": [
                        {
                          "type": "Text",
                          "props": {
                            "data": this.badge + " · " + this.title,
                            "style": {
                              "fontSize": 18,
                              "fontWeight": "bold"
                            }
                          }
                        }
                      ]
                    }
                  ]
                },
                {
                  "type": "Divider",
                  "props": {
                    "height": 24
                  }
                },
                {
                  "type": "Text",
                  "props": {
                    "data": this.subtitle,
                    "style": {
                      "fontSize": 14,
                      "color": '#9E9E9E'
                    }
                  }
                }
              ]
            }
          ]
        }
      ]
    };
  }
}

