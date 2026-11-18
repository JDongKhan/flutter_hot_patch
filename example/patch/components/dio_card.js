// GENERATED CODE - DO NOT EDIT
// 由 dynamic_flutter_generator 从 lib/components/dio_card.dart 自动生成
// 重新生成：dart run build_runner build

import { devServerBaseUrl } from '../base/dev_server.js';
import { Card, Color, Colors, Column, CrossAxisAlignment, EdgeInsets, ElevatedButton, Expanded, FontWeight, MainAxisSize, Padding, Row, SizedBox, StatefulWidget, StatelessWidget, Text, TextStyle, Wrap } from '../flutter.js';
import { Dio } from '../packages/dio.js';

// 组件 DioCard
export class DioCard extends StatefulWidget {
  constructor(args) {
    super(args);
    this._dio = new Dio();
    this._hello = "尚未请求";
    this._helloBody = "—";
    this._community = "尚未请求";
    this._communityDetail = "—";
  }
  async _callHello() {
    this.setState(() => {
      this._hello = "请求中…";
    });
    try {
      const res = await this._dio.get(devServerBaseUrl + "/hello");
      const body = res.data;
      const message = ((__nn(body) == null) ? "" : "" + body["message"]);
      const name = ((__nn(body) == null) ? "" : "" + body["data"]["name"]);
      this.setState(() => {
        this._hello = "HTTP " + res.statusCode + " · " + (res.statusMessage ?? "");
        this._helloBody = message + " / name=" + name;
      });
    } catch (__e) {
      const e = __e;
      this.setState(() => {
        this._hello = "失败：" + e;
      });
    }
  }
  async _callCommunity() {
    this.setState(() => {
      this._community = "请求中…";
    });
    try {
      const res = await this._dio.get(devServerBaseUrl + "/app/community", { "queryParameters": new Map([["tab", "recommend"], ["page", 2]]) });
      const uri = "" + res.requestOptions.uri;
      const root = res.data;
      const tabs = ((__nn(root) == null) ? "" : "" + root["tabs"]);
      this.setState(() => {
        this._community = "HTTP " + res.statusCode + " · " + uri;
        this._communityDetail = "tabs = " + tabs;
      });
    } catch (__e) {
      const e = __e;
      this.setState(() => {
        this._community = "失败：" + e;
      });
    }
  }
  build(context) {
    return new Card({
      "child": new Padding({
        "padding": (this.__k0 || (this.__k0 = EdgeInsets.all({
          "value": 16
        }))),
        "child": new Column({
          "mainAxisSize": MainAxisSize.min,
          "crossAxisAlignment": CrossAxisAlignment.start,
          "children": [
            (this.__k1 || (this.__k1 = new Text({
              "data": "final Dio _dio = Dio();  await _dio.get(url, queryParameters: …)",
              "style": new TextStyle({
                "fontSize": 15,
                "fontWeight": FontWeight.bold,
                "color": new Color({
                  "value": 0xFF00897B
                })
              })
            }))),
            (this.__k2 || (this.__k2 = new SizedBox({
              "height": 8
            }))),
            new _Line({
              "label": "GET /hello",
              "value": this._hello
            }),
            new _Line({
              "label": "响应体",
              "value": this._helloBody
            }),
            (this.__k2 || (this.__k2 = new SizedBox({
              "height": 8
            }))),
            new _Line({
              "label": "GET /app/community",
              "value": this._community
            }),
            new _Line({
              "label": "query 参数",
              "value": this._communityDetail
            }),
            (this.__k2 || (this.__k2 = new SizedBox({
              "height": 8
            }))),
            new Wrap({
              "spacing": 8,
              "runSpacing": 8,
              "children": [
                new ElevatedButton({
                  "onPressed": () => this._callHello(),
                  "child": (this.__k3 || (this.__k3 = new Text({
                    "data": "GET /hello"
                  })))
                }),
                new ElevatedButton({
                  "onPressed": () => this._callCommunity(),
                  "child": (this.__k4 || (this.__k4 = new Text({
                    "data": "带 query 请求"
                  })))
                })
              ]
            }),
            (this.__k2 || (this.__k2 = new SizedBox({
              "height": 8
            }))),
            (this.__k5 || (this.__k5 = new Text({
              "data": "API 与 Dart 一比一（Dio / Options / Response / DioException 同名）：" + "JS 侧由 js/dio.js 承接，底层调用宿主真实 dio",
              "style": new TextStyle({
                "fontSize": 12,
                "color": Colors.grey
              })
            })))
          ]
        })
      })
    });
  }
}

// 组件 _Line
export class _Line extends StatelessWidget {
  constructor(args) {
    super(args);
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.label = (args && args.label !== undefined) ? args.label : '';
    this.value = (args && args.value !== undefined) ? args.value : '';
  }
  build(context) {
    return new Padding({
      "padding": (this.__k0 || (this.__k0 = EdgeInsets.only({
        "bottom": 4
      }))),
      "child": new Row({
        "crossAxisAlignment": CrossAxisAlignment.start,
        "children": [
          new SizedBox({
            "width": 132,
            "child": new Text({
              "style": (this.__k1 || (this.__k1 = new TextStyle({
                "color": Colors.grey,
                "fontSize": 12
              }))),
              "data": this.label
            })
          }),
          new Expanded({
            "child": new Text({
              "style": (this.__k2 || (this.__k2 = new TextStyle({
                "fontSize": 12
              }))),
              "data": this.value
            })
          })
        ]
      })
    });
  }
}

