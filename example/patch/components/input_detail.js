// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/input_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { Align, Alignment, Checkbox, Colors, Column, CrossAxisAlignment, DropdownButton, DropdownMenuItem, FilledButton, FontWeight, InputDecoration, Radio, Row, SizedBox, Slider, StatefulWidget, Switch, Text, TextEditingController, TextField, TextStyle } from '../flutter.js';

// 组件 InputDetail
export class InputDetail extends StatefulWidget {
  constructor(args) {
    super(args);
    this._controller = new TextEditingController();
    this._text = "";
    this._choice = "A";
    this._dropdown = "苹果";
    this._switchOn = false;
    this._checked = false;
    this._slider = 0.4;
  }
  initState() {
    super.initState();
    this._controller.addListener((...args) => this._onControllerChanged(...args));
  }
  _onControllerChanged() {
    if (!this.__unmounted) {
      this.setState(() => { this._text = this._controller.text; });
    }
  }
  _onTextChanged(v) {
    this.setState(() => { this._text = v; });
  }
  _onChoiceChanged(v) {
    this.setState(() => { this._choice = v; });
  }
  _onDropdownChanged(v) {
    this.setState(() => { this._dropdown = v; });
  }
  _onSwitchChanged(v) {
    this.setState(() => { this._switchOn = (v ?? false); });
  }
  _onCheckChanged(v) {
    this.setState(() => { this._checked = v; });
  }
  _onSliderChanged(v) {
    this.setState(() => { this._slider = v; });
  }
  build(context) {
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.stretch,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "TextField",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        new TextField({
          "controller": this._controller,
          "onChanged": (...__a) => this._onTextChanged(...__a),
          "decoration": (this.__k1 || (this.__k1 = new InputDecoration({
            "hintText": "请输入文本",
            "labelText": "用户名"
          }))),
          "maxLines": 1,
          "style": (this.__k2 || (this.__k2 = new TextStyle({
            "fontSize": 16
          })))
        }),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 4
        }))),
        new Text({
          "style": (this.__k4 || (this.__k4 = new TextStyle({
            "color": Colors.grey,
            "fontSize": 14
          }))),
          "data": "输入内容：" + this._text
        }),
        new Text({
          "style": (this.__k5 || (this.__k5 = new TextStyle({
            "color": Colors.deepPurple,
            "fontSize": 14
          }))),
          "data": "controller.text：" + this._controller.text
        }),
        (this.__k6 || (this.__k6 = new SizedBox({
          "height": 8
        }))),
        new Align({
          "alignment": Alignment.centerLeft,
          "child": new FilledButton({
            "onPressed": () => { return this._controller.clear(); },
            "child": (this.__k7 || (this.__k7 = new Text({
              "data": "清空输入"
            })))
          })
        }),
        (this.__k8 || (this.__k8 = new SizedBox({
          "height": 12
        }))),
        (this.__k9 || (this.__k9 = new Text({
          "data": "Radio 单选",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        new Row({
          "children": [
            new Radio({
              "value": "A",
              "groupValue": this._choice,
              "onChanged": (...__a) => this._onChoiceChanged(...__a),
              "activeColor": Colors.deepPurple
            }),
            (this.__k10 || (this.__k10 = new Text({
              "data": "选项 A"
            }))),
            new Radio({
              "value": "B",
              "groupValue": this._choice,
              "onChanged": (...__a) => this._onChoiceChanged(...__a),
              "activeColor": Colors.deepPurple
            }),
            (this.__k11 || (this.__k11 = new Text({
              "data": "选项 B"
            })))
          ]
        }),
        new Text({
          "style": (this.__k4 || (this.__k4 = new TextStyle({
            "color": Colors.grey,
            "fontSize": 14
          }))),
          "data": "当前选择：" + this._choice
        }),
        (this.__k8 || (this.__k8 = new SizedBox({
          "height": 12
        }))),
        (this.__k12 || (this.__k12 = new Text({
          "data": "DropdownButton",
          "style": new TextStyle({
            "fontSize": 16,
            "fontWeight": FontWeight.bold
          })
        }))),
        new DropdownButton({
          "value": this._dropdown,
          "isExpanded": true,
          "onChanged": (...__a) => this._onDropdownChanged(...__a),
          "items": [
            new DropdownMenuItem({
              "value": "苹果",
              "child": new Text({
                "data": "苹果"
              })
            }),
            new DropdownMenuItem({
              "value": "香蕉",
              "child": new Text({
                "data": "香蕉"
              })
            }),
            new DropdownMenuItem({
              "value": "橙子",
              "child": new Text({
                "data": "橙子"
              })
            })
          ]
        }),
        (this.__k8 || (this.__k8 = new SizedBox({
          "height": 12
        }))),
        new Row({
          "children": [
            new Switch({
              "value": this._switchOn,
              "onChanged": (...__a) => this._onSwitchChanged(...__a),
              "activeColor": Colors.white,
              "activeTrackColor": Colors.deepPurple,
              "inactiveThumbColor": Colors.grey,
              "inactiveTrackColor": Colors.grey.shade300
            }),
            (this.__k13 || (this.__k13 = new SizedBox({
              "width": 8
            }))),
            new Text({
              "data": "Switch：" + (this._switchOn ? "开" : "关")
            })
          ]
        }),
        new Row({
          "children": [
            new Checkbox({
              "value": this._checked,
              "onChanged": (...__a) => this._onCheckChanged(...__a),
              "activeColor": Colors.deepPurple,
              "checkColor": Colors.white
            }),
            (this.__k13 || (this.__k13 = new SizedBox({
              "width": 8
            }))),
            new Text({
              "data": "Checkbox：" + (this._checked ?? false)
            })
          ]
        }),
        (this.__k6 || (this.__k6 = new SizedBox({
          "height": 8
        }))),
        new Text({
          "style": (this.__k14 || (this.__k14 = new TextStyle({
            "fontSize": 14
          }))),
          "data": "Slider 值：" + this._slider
        }),
        new Slider({
          "value": this._slider,
          "min": 0,
          "max": 1,
          "divisions": 10,
          "label": ((this._slider * 100)).round() + "%",
          "activeColor": Colors.deepPurple,
          "inactiveColor": Colors.grey.shade300,
          "onChanged": (...__a) => this._onSliderChanged(...__a)
        })
      ]
    });
  }
}

