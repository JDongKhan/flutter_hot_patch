// GENERATED CODE - DO NOT EDIT
// 跨包产物（package: hot_module_base）：由 hot_patch_generator 生成
// 源文件：package:hot_module_base/src/widgets/timetable_date_picker.dart（一个源文件一份产物）

import { Component, DateTime, Expanded, IgnorePointer, Row, SizedBox, StatefulWidget, ValueKey } from '../../../../flutter.js';

// 组件 TimetableDatePicker
export class TimetableDatePicker extends StatefulWidget {
  static _weekdayCycleCount = 3;
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

// 原生组件包装 TimetableWheelColumn（@PatchIgnore(isComponent: true)）
export class TimetableWheelColumn extends Component {
  // 宿主包装类：实例**自身**就是宿主元素。类型名直接取类名（`__type.name`），
  // props 由基类构造期统一拆分；懒规则通过覆盖 `__lazy` 声明。
  static __fnProps = ["onSelectedItemChanged"];
}
