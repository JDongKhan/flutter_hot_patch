// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/rich_text_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Colors, Column, Divider, Expanded, FontWeight, RichText, Row, SizedBox, Text, TextButton, TextDecoration, TextSpan, TextStyle } from '../flutter.js';

// 组件 RichTextDetail
export class RichTextDetail {
  constructor(args) {
    this.props = args || {};
    this._highlight = false;
    this._clampLines = false;
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": "stretch",
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "RichText · TextSpan 富文本树",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 10
        }))),
        new RichText({
          "textAlign": "center",
          "textDirection": "ltr",
          "text": new TextSpan({
            "text": "一段文字里可以混排：",
            "style": (this.__k2 || (this.__k2 = new TextStyle({
              "color": Colors.black87,
              "fontSize": 15
            }))),
            "children": [
              new TextSpan({
                "text": "不同颜色",
                "style": new TextStyle({
                  "color": this._highlight ? Colors.deepPurple : Colors.teal,
                  "fontWeight": FontWeight.bold
                })
              }),
              (this.__k3 || (this.__k3 = new TextSpan({
                "text": "、"
              }))),
              (this.__k4 || (this.__k4 = new TextSpan({
                "style": new TextStyle({
                  "fontSize": 20,
                  "color": Colors.orange
                }),
                "text": "更大字号"
              }))),
              (this.__k3 || (this.__k3 = new TextSpan({
                "text": "、"
              }))),
              (this.__k5 || (this.__k5 = new TextSpan({
                "style": new TextStyle({
                  "decoration": TextDecoration.underline,
                  "decorationColor": Colors.blue,
                  "decorationStyle": "wavy"
                }),
                "text": "下划线"
              }))),
              (this.__k6 || (this.__k6 = new TextSpan({
                "text": "，并且可以逐级嵌套。"
              })))
            ]
          })
        }),
        (this.__k7 || (this.__k7 = new Divider({
          "height": 24
        }))),
        (this.__k8 || (this.__k8 = new Text({
          "data": "RichText · maxLines + ellipsis 截断",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 10
        }))),
        new RichText({
          "textAlign": "start",
          "textDirection": "ltr",
          "maxLines": this._clampLines ? 1 : null,
          "overflow": this._clampLines ? "ellipsis" : "clip",
          "text": (this.__k9 || (this.__k9 = new TextSpan({
            "style": new TextStyle({
              "fontSize": 14,
              "height": 1.5,
              "color": Colors.black54
            }),
            "text": "这是一段足够长的文字，用来验证 RichText 在多行与单行之间的" + "截断行为：开启单行截断后，超出宽度的部分会以省略号结尾，" + "而关闭截断时文字会自然折行显示完整内容。"
          })))
        }),
        (this.__k10 || (this.__k10 = new SizedBox({
          "height": 8
        }))),
        new Row({
          "children": [
            new Expanded({
              "child": new TextButton({
                "onPressed": this.__bindFn(0, [], () => this.setState(() => {
                  this._highlight = (!this._highlight);
                })),
                "child": new Text({
                  "data": this._highlight ? "还原子串颜色" : "切换子串颜色"
                })
              })
            }),
            new Expanded({
              "child": new TextButton({
                "onPressed": this.__bindFn(1, [], () => this.setState(() => {
                  this._clampLines = (!this._clampLines);
                })),
                "child": new Text({
                  "data": this._clampLines ? "关闭单行截断" : "开启单行截断"
                })
              })
            })
          ]
        })
      ]
    });
  }
}

