// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/components/timetable_picker_detail.dart 自动生成
// 重新生成：dart run build_runner build

import { TimetableDatePicker } from '../packages/hot_module_base/src/widgets/timetable_date_picker.js';
import { Border, BorderRadius, BoxDecoration, Color, Colors, Column, Container, CrossAxisAlignment, DateTime, Duration, EdgeInsets, FontWeight, SizedBox, StatelessWidget, Text, TextStyle } from '../flutter.js';

// 组件 TimetablePickerDetail
export class TimetablePickerDetail extends StatelessWidget {
  constructor(args) {
    super(args);
  }
  build(context) {
    const today = DateTime.now();
    const initialDate = new DateTime({year: today.year, month: today.month, day: today.day});
    const firstDate = today.subtract(new Duration({days: 30}));
    const lastDate = today.add(new Duration({days: 365}));
    return new Column({
      "crossAxisAlignment": CrossAxisAlignment.start,
      "children": [
        (this.__k0 || (this.__k0 = new Text({
          "data": "时刻表日期选择器",
          "style": new TextStyle({
            "fontWeight": FontWeight.bold
          })
        }))),
        (this.__k1 || (this.__k1 = new SizedBox({
          "height": 4
        }))),
        (this.__k2 || (this.__k2 = new Text({
          "data": "年 / 月 / 日 / 周四列联动滚轮，周列随日期自动居中",
          "style": new TextStyle({
            "fontSize": 12,
            "color": Colors.black54
          })
        }))),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 12
        }))),
        new Container({
          "padding": (this.__k4 || (this.__k4 = EdgeInsets.all({
            "value": 12
          }))),
          "decoration": new BoxDecoration({
            "border": Border.all({
              "color": new Color({
                "value": 0xFFE0E0E0
              }),
              "width": 0.5
            }),
            "borderRadius": BorderRadius.circular({
              "radius": 16
            })
          }),
          "child": new TimetableDatePicker({
            "initialDate": initialDate,
            "firstDate": firstDate,
            "lastDate": lastDate,
            "itemHeight": 44,
            "count": 4
          })
        }),
        (this.__k3 || (this.__k3 = new SizedBox({
          "height": 12
        }))),
        (this.__k5 || (this.__k5 = new Text({
          "data": "拖动任一列可修改日期；周列只读，会自动跟随选择居中。",
          "style": new TextStyle({
            "fontSize": 12,
            "color": Colors.black54
          })
        })))
      ]
    });
  }
}

