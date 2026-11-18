// GENERATED CODE - DO NOT EDIT
// 由 dynamic_flutter_generator 从 lib/components/third_party_tools_card.dart 自动生成
// 重新生成：dart run build_runner build

import { PlatformTools } from '../base/platform_tools.js';
import { HostHttp } from '../base/host_http.js';
import { devServerBaseUrl } from '../base/dev_server.js';
import { Card, Colors, Column, CrossAxisAlignment, EdgeInsets, ElevatedButton, FontWeight, MainAxisSize, Padding, SizedBox, StatefulWidget, StatelessWidget, Text, TextStyle, Wrap } from '../flutter.js';

// 组件 ThirdPartyToolsCard
export class ThirdPartyToolsCard extends StatefulWidget {
  constructor(args) {
    super(args);
    this._temp = "未读取";
    this._docs = "未读取";
    this._version = "未读取";
    this._permission = "未查询";
    this._http = "尚未请求";
  }
  async _load() {
    const temp = await PlatformTools.tempPath();
    const docs = await PlatformTools.documentsPath();
    const version = await PlatformTools.appVersion();
    this.setState(() => {
      this._temp = temp;
      this._docs = docs;
      this._version = version;
    });
  }
  async _checkPermission() {
    const status = await PlatformTools.photoPermissionStatus();
    this.setState(() => {
      this._permission = status;
    });
  }
  async _requestPermission() {
    const status = await PlatformTools.requestPhotoPermission();
    this.setState(() => {
      this._permission = status;
    });
  }
  async _callHttp() {
    try {
      const res = await HostHttp.get(devServerBaseUrl + "/hello");
      this.setState(() => {
        this._http = "HTTP " + res["statusCode"] + " · " + (res["statusMessage"] ?? "");
      });
    } catch (__e) {
      const e = __e;
      this.setState(() => {
        this._http = "请求失败：" + e;
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
              "data": "PlatformTools / HostHttp（@HostInjected）",
              "style": new TextStyle({
                "fontSize": 16,
                "fontWeight": FontWeight.bold,
                "color": Colors.blue
              })
            }))),
            (this.__k2 || (this.__k2 = new SizedBox({
              "height": 8
            }))),
            new _Line({
              "label": "临时目录",
              "value": this._temp
            }),
            new _Line({
              "label": "文档目录",
              "value": this._docs
            }),
            new _Line({
              "label": "应用版本",
              "value": this._version
            }),
            new _Line({
              "label": "相册权限",
              "value": this._permission
            }),
            new _Line({
              "label": "HTTP（dio）",
              "value": this._http
            }),
            (this.__k2 || (this.__k2 = new SizedBox({
              "height": 8
            }))),
            new Wrap({
              "spacing": 8,
              "runSpacing": 8,
              "children": [
                new ElevatedButton({
                  "onPressed": () => this._load(),
                  "child": (this.__k3 || (this.__k3 = new Text({
                    "data": "读取路径/版本"
                  })))
                }),
                new ElevatedButton({
                  "onPressed": () => this._checkPermission(),
                  "child": (this.__k4 || (this.__k4 = new Text({
                    "data": "查询权限"
                  })))
                }),
                new ElevatedButton({
                  "onPressed": () => this._requestPermission(),
                  "child": (this.__k5 || (this.__k5 = new Text({
                    "data": "申请权限"
                  })))
                }),
                new ElevatedButton({
                  "onPressed": () => this._callHttp(),
                  "child": (this.__k6 || (this.__k6 = new Text({
                    "data": "dio 请求 mock"
                  })))
                })
              ]
            }),
            (this.__k2 || (this.__k2 = new SizedBox({
              "height": 8
            }))),
            (this.__k7 || (this.__k7 = new Text({
              "data": "path_provider / package_info_plus / permission_handler / dio 全部由宿主执行，" + "JS 侧不翻译这些库",
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
      "padding": (this.__k0 || (this.__k0 = EdgeInsets.symmetric({
        "vertical": 2
      }))),
      "child": new Text({
        "style": (this.__k1 || (this.__k1 = new TextStyle({
          "fontSize": 13
        }))),
        "data": this.label + "：" + this.value
      })
    });
  }
}

