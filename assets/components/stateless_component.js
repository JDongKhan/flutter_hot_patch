// GENERATED CODE - DO NOT EDIT
// 由 ui_component_generator 从 lib/components/stateless_component.dart 自动生成
// 重新生成：dart run build_runner build

import { Card, Column, Divider, Expanded, Icon, Padding, Row, SizedBox, Text, __h } from '../flutter.js';

class StatelessCardComponent {
  constructor(args) {
    this.title = (args && args.title !== undefined) ? args.title : '';
    this.subtitle = (args && args.subtitle !== undefined) ? args.subtitle : '';
    this.badge = (args && args.badge !== undefined) ? args.badge : '';
  }
  build() {
    return Card({
        "margin": {
          "left": 12.0,
          "top": 12.0,
          "right": 12.0,
          "bottom": 12.0
        }
      }, [
        Padding({
            "padding": {
              "left": 16.0,
              "top": 16.0,
              "right": 16.0,
              "bottom": 16.0
            }
          }, [
            Column({
                "mainAxisSize": "min",
                "crossAxisAlignment": "start"
              }, [
                Row({}, [
                    Icon({
                        "icon": "article",
                        "color": '#009688'
                      }),
                    SizedBox({
                        "width": 8
                      }),
                    Expanded({}, [
                        Text({
                            "data": this.badge + " · " + this.title,
                            "style": {
                              "fontSize": 18,
                              "fontWeight": "bold"
                            }
                          })
                      ])
                  ]),
                Divider({
                    "height": 24
                  }),
                Text({
                    "data": this.subtitle,
                    "style": {
                      "fontSize": 14,
                      "color": '#9E9E9E'
                    }
                  })
              ])
          ])
      ]);
  }
}
export function StatelessCard(props, children) {
  return __h(StatelessCardComponent, props, children);
}

