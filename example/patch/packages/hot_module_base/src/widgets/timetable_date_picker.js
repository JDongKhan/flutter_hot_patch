// GENERATED CODE - DO NOT EDIT
// 跨包产物（package: hot_module_base）：由 dynamic_flutter_generator 生成
// 源文件：package:hot_module_base/src/widgets/timetable_date_picker.dart（一个源文件一份产物）

import { Border, BorderRadius, BorderSide, BoxDecoration, BoxShadow, Center, Color, Colors, Column, Container, CrossAxisAlignment, CupertinoPicker, DateTime, Duration, EdgeInsets, Expanded, FilledButton, FixedExtentScrollController, FontWeight, Future, GestureDetector, GlobalKey, HitTestBehavior, IgnorePointer, MainAxisSize, Navigator, Offset, Padding, Radius, RoundedRectangleBorder, Row, SafeArea, Size, SizedBox, StatefulWidget, Text, TextAlign, TextOverflow, TextStyle, ValueKey, showModalBottomSheet } from '../../../../flutter.js';

const _themeBorder = () => { return Border.all({color: new Color({value: 0xFFE0E0E0}), width: 0.5}); };
const _todayLabel = () => { return "今天"; };

// 组件 TimetableDatePicker
export class TimetableDatePicker extends StatefulWidget {
  constructor(args) {
    super(args);
    this.__applyProps(args);
    this._firstDate = null;
    this._lastDate = null;
    this._selectedDate = null;
    this._years = [];
    this._months = [];
    this._days = [];
    this._weekdayItems = [];
  }
  __applyProps(args) {
    this.initialDate = (args && args.initialDate !== undefined) ? args.initialDate : null;
    this.firstDate = (args && args.firstDate !== undefined) ? args.firstDate : null;
    this.lastDate = (args && args.lastDate !== undefined) ? args.lastDate : null;
    this.itemHeight = (args && args.itemHeight !== undefined) ? args.itemHeight : 44.0;
    this.count = (args && args.count !== undefined) ? args.count : 4;
  }
  get selectedDate() {
    return this._selectedDate;
  }
  get _centeredWeekdayIndex() {
    return ((Math.trunc(this._weekdayItems.length / TimetableDatePicker._weekdayCycleCount) + this._selectedDate.weekday) - 1);
  }
  initState() {
    super.initState();
    const today = this._dateOnly(DateTime.now());
    this._firstDate = this._dateOnly((this.firstDate ?? today));
    this._lastDate = this._dateOnly((this.lastDate ?? new DateTime({year: 2030, month: 12, day: 31})));
    this._selectedDate = this._clampToRange(this._dateOnly((this.initialDate ?? today)));
    this._years = [];
    for (let year = this._firstDate.year; (year <= this._lastDate.year); (year++)) {
      this._years.add(year);
    }
    this._months = this._monthsOf(this._selectedDate.year);
    this._days = this._daysOf(this._selectedDate.year, this._selectedDate.month);
    const weekdayTexts = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"];
    this._weekdayItems = [];
    for (let index = 0; (index < (weekdayTexts.length * TimetableDatePicker._weekdayCycleCount)); (index++)) {
      this._weekdayItems.add(weekdayTexts[__mod(index, weekdayTexts.length)]);
    }
  }
  resetToToday() {
    this.setState(() => {
      this._selectedDate = this._clampToRange(this._dateOnly(DateTime.now()));
      this._months = this._monthsOf(this._selectedDate.year);
      this._days = this._daysOf(this._selectedDate.year, this._selectedDate.month);
    });
  }
  _onYearChanged(index) {
    this.setState(() => {
      this._selectedDate = this._clampToRange(new DateTime({year: this._years[index], month: this._selectedDate.month, day: this._selectedDate.day}));
      this._months = this._monthsOf(this._selectedDate.year);
      this._days = this._daysOf(this._selectedDate.year, this._selectedDate.month);
    });
  }
  _onMonthChanged(index) {
    this.setState(() => {
      this._selectedDate = this._clampToRange(this._buildDate(this._selectedDate.year, this._months[index], this._selectedDate.day));
      this._days = this._daysOf(this._selectedDate.year, this._selectedDate.month);
    });
  }
  _onDayChanged(index) {
    this.setState(() => {
      this._selectedDate = new DateTime({year: this._selectedDate.year, month: this._selectedDate.month, day: this._days[index]});
    });
  }
  _dateOnly(value) {
    return new DateTime({year: value.year, month: value.month, day: value.day});
  }
  _clampToRange(value) {
    if (value.isBefore(this._firstDate)) {
      return this._firstDate;
    }
    if (value.isAfter(this._lastDate)) {
      return this._lastDate;
    }
    return value;
  }
  _buildDate(year, month, day) {
    const maxDay = new DateTime({year: year, month: (month + 1), day: 0}).day;
    return new DateTime({year: year, month: month, day: day.clamp(1, maxDay)});
  }
  _monthsOf(year) {
    const start = ((year === this._firstDate.year) ? this._firstDate.month : 1);
    const end = ((year === this._lastDate.year) ? this._lastDate.month : 12);
    const months = [];
    for (let month = start; (month <= end); (month++)) {
      months.add(month);
    }
    return months;
  }
  _daysOf(year, month) {
    let start = 1;
    let end = new DateTime({year: year, month: (month + 1), day: 0}).day;
    if (((year === this._firstDate.year) && (month === this._firstDate.month))) {
      start = this._firstDate.day;
    }
    if (((year === this._lastDate.year) && (month === this._lastDate.month))) {
      end = this._lastDate.day;
    }
    const days = [];
    for (let day = start; (day <= end); (day++)) {
      days.add(day);
    }
    return days;
  }
  _yearText(year) {
    return year + "年";
  }
  _monthText(month) {
    return month + "月";
  }
  _dayText(day) {
    return day + "日";
  }
  build(context) {
    return new SizedBox({
      "height": (this.itemHeight * this.count),
      "child": new Row({
        "children": [
          new Expanded({
            "flex": 3,
            "child": new TimetableWheelColumn({
              "items": this._years.map((...args) => this._yearText(...args)).toList(),
              "initialItem": this._years.indexOf(this._selectedDate.year),
              "itemHeight": this.itemHeight,
              "onSelectedItemChanged": (__a0) => this._onYearChanged(__a0),
              "key": new ValueKey({value: "year"})
            })
          }),
          new Expanded({
            "flex": 2,
            "child": new TimetableWheelColumn({
              "items": this._months.map((...args) => this._monthText(...args)).toList(),
              "initialItem": this._months.indexOf(this._selectedDate.month),
              "itemHeight": this.itemHeight,
              "onSelectedItemChanged": (__a0) => this._onMonthChanged(__a0),
              "key": new ValueKey({value: "month"})
            })
          }),
          new Expanded({
            "flex": 2,
            "child": new TimetableWheelColumn({
              "items": this._days.map((...args) => this._dayText(...args)).toList(),
              "initialItem": this._days.indexOf(this._selectedDate.day),
              "itemHeight": this.itemHeight,
              "onSelectedItemChanged": (__a0) => this._onDayChanged(__a0),
              "key": new ValueKey({value: "day"})
            })
          }),
          new Expanded({
            "flex": 1,
            "child": new IgnorePointer({
              "child": new TimetableWheelColumn({
                "items": this._weekdayItems,
                "initialItem": this._centeredWeekdayIndex,
                "itemHeight": this.itemHeight,
                "onSelectedItemChanged": (_) => {},
                "key": new ValueKey({value: "weekday"})
              })
            })
          })
        ]
      })
    });
  }
}
TimetableDatePicker._weekdayCycleCount = 3;

// 组件 TimetableWheelColumn
export class TimetableWheelColumn extends StatefulWidget {
  constructor(args) {
    super(args);
    this.__applyProps(args);
    this._controller = null;
  }
  __applyProps(args) {
    this.items = (args && args.items !== undefined) ? args.items : [];
    this.initialItem = (args && args.initialItem !== undefined) ? args.initialItem : 0;
    this.itemHeight = (args && args.itemHeight !== undefined) ? args.itemHeight : 0;
    this.onSelectedItemChanged = (args && args.onSelectedItemChanged !== undefined) ? args.onSelectedItemChanged : null;
    this.selectedColor = (args && args.selectedColor !== undefined) ? args.selectedColor : 0xFFE53935;
    this.unselectedColor = (args && args.unselectedColor !== undefined) ? args.unselectedColor : 0xFF000000;
    this.fontSize = (args && args.fontSize !== undefined) ? args.fontSize : 32;
  }
  initState() {
    super.initState();
    this._controller = this._createController();
    this._controller.addListener((...args) => this._onScroll(...args));
  }
  _createController() {
    const maxItem = (this.items.isEmpty ? 0 : (this.items.length - 1));
    return new FixedExtentScrollController({initialItem: this.initialItem.clamp(0, maxItem)});
  }
  didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    const maxItem = (this.items.isEmpty ? 0 : (this.items.length - 1));
    const target = this.initialItem.clamp(0, maxItem);
    if ((oldWidget.items.length !== this.items.length)) {
      this._replaceController();
    } else {
      if (this._controller.hasClients) {
        if ((__nn(this._controller.selectedItem) !== __nn(target))) {
          Future.delayed(new Duration({milliseconds: 1}), () => { if (((!!this.__unmounted) || (!this._controller.hasClients))) {
              return;
            }
            const maxIndex = (this.items.isEmpty ? 0 : (this.items.length - 1));
            const next = this.initialItem.clamp(0, maxIndex);
            if ((__nn(this._controller.selectedItem) !== __nn(next))) {
              this._controller.jumpToItem(next);
            } });
        }
      } else {
        if ((oldWidget.initialItem !== this.initialItem)) {
          this._replaceController();
        }
      }
    }
  }
  _replaceController() {
    const old = this._controller;
    this._controller = this._createController();
    this._controller.addListener((...args) => this._onScroll(...args));
    Future.delayed(new Duration({milliseconds: 32}), () => { old.dispose(); });
  }
  _onScroll() {
    if (!this.__unmounted) {
      this.setState(() => {});
    }
  }
  dispose() {
    this._controller.removeListener((...args) => this._onScroll(...args));
    this._controller.dispose();
    super.dispose();
  }
  get _selectedStyle() {
    return new TextStyle({fontSize: this.fontSize, color: new Color({value: this.selectedColor}), fontWeight: FontWeight.bold});
  }
  get _unselectedStyle() {
    return new TextStyle({fontSize: this.fontSize, color: new Color({value: this.unselectedColor})});
  }
  build(context) {
    return CupertinoPicker.builder({
      "scrollController": this._controller,
      "itemExtent": this.itemHeight,
      "onSelectedItemChanged": this.onSelectedItemChanged,
      "magnification": 1.2,
      "squeeze": 1,
      "diameterRatio": 4,
      "useMagnifier": true,
      "selectionOverlay": new Container({
        "decoration": new BoxDecoration({
          "border": new Border({
            "top": new BorderSide({
              "color": (this.__k0 || (this.__k0 = new Color({
                "value": 0xffe4e4e4
              }))),
              "width": 0.5
            }),
            "bottom": new BorderSide({
              "color": (this.__k0 || (this.__k0 = new Color({
                "value": 0xffe4e4e4
              }))),
              "width": 0.5
            })
          })
        })
      }),
      "childCount": this.items.length,
      "itemBuilder": (context, index) => {
        return new Center({
          "child": new Text({
            "maxLines": 1,
            "overflow": TextOverflow.ellipsis,
            "style": (this._controller.selectedItem === index) ? this._selectedStyle : this._unselectedStyle,
            "data": this.items[index]
          })
        });
      },
      "key": new ValueKey({value: this._controller})
    });
  }
}

export const showTimetableDatePicker = (context, __o) => { let initialDate = (__o && __o.initialDate !== undefined) ? __o.initialDate : null; const pickerKey = new GlobalKey({typeArguments: {"T": "_TimetableDatePickerState"}});
  const today = DateTime.now();
  const firstDate = new DateTime({year: today.year, month: today.month, day: (today.day - 30)});
  const lastDate = new DateTime({year: today.year, month: today.month, day: (today.day + 365)});
  return showModalBottomSheet({"context": context, "isScrollControlled": true, "backgroundColor": Colors.white, "shape": new RoundedRectangleBorder({borderRadius: BorderRadius.vertical({top: Radius.circular({radius: 16})})}), "builder": (sheetContext) => { return new Column({mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [new Padding({padding: EdgeInsets.symmetric({vertical: 16}), child: new Text({data: "时间选择器", textAlign: TextAlign.center, style: new TextStyle({fontSize: 16, fontWeight: FontWeight.bold})})}), new SizedBox({height: 12}), new Padding({padding: EdgeInsets.symmetric({horizontal: 24}), child: new Container({decoration: new BoxDecoration({border: _themeBorder(), borderRadius: BorderRadius.circular({radius: 16})}), padding: EdgeInsets.symmetric({vertical: 48, horizontal: 12}), child: new Column({mainAxisSize: MainAxisSize.min, children: [new TimetableDatePicker({key: pickerKey, initialDate: initialDate, firstDate: firstDate, lastDate: lastDate}), new SizedBox({height: 48}), new GestureDetector({onTap: () => { pickerKey.currentState?.resetToToday(); }, behavior: HitTestBehavior.opaque, child: new Container({decoration: new BoxDecoration({border: _themeBorder(), borderRadius: BorderRadius.circular({radius: 8})}), padding: EdgeInsets.symmetric({vertical: 10, horizontal: 18}), child: new Text({data: _todayLabel(), style: new TextStyle({fontWeight: FontWeight.bold})})})})]})})}), new SizedBox({height: 60}), new SafeArea({top: false, child: new Container({padding: EdgeInsets.only({top: 20, left: 12, right: 12}), decoration: new BoxDecoration({color: Colors.white, boxShadow: [new BoxShadow({color: new Color({value: 0xffefefef}), offset: new Offset({dx: 0, dy: (-2)}), blurRadius: 15})]}), child: new FilledButton({style: FilledButton.styleFrom({ "minimumSize": Size.fromHeight({height: 48}) }), onPressed: () => { Navigator.of(sheetContext).pop((pickerKey.currentState?.selectedDate ?? DateTime.now())); }, child: new Text({data: "确定", style: new TextStyle({fontSize: 16, fontWeight: FontWeight.bold})})})})})]}); }, typeArguments: {"T": "DateTime"}}); };
