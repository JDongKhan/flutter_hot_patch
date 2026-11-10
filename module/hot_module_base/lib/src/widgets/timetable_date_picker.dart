import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// @author jd
/// 时刻表专用日期选择弹窗：仅选择日期，无出发/到达选项卡
Future<DateTime?> showTimetableDatePicker(BuildContext context, {DateTime? initialDate}) {
  final pickerKey = GlobalKey<_TimetableDatePickerState>();
  // 时间范围：当前日期前 30 天至后 365 天
  final today = DateTime.now();
  final firstDate = DateTime(today.year, today.month, today.day - 30);
  final lastDate = DateTime(today.year, today.month, today.day + 365);
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (sheetContext) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('时间选择器', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          // 日期区域
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(border: _themeBorder(), borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TimetableDatePicker(key: pickerKey, initialDate: initialDate, firstDate: firstDate, lastDate: lastDate),
                  const SizedBox(height: 48),
                  GestureDetector(
                    onTap: () {
                      pickerKey.currentState?.resetToToday();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      decoration: BoxDecoration(border: _themeBorder(), borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                      child: Text(_todayLabel(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 60),
          // 确认按钮
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.only(top: 20, left: 12, right: 12),
              decoration: BoxDecoration(
                // 不用 `Theme.of(...).colorScheme.surface`：JS 侧没有主题查询能力，
                // 与底部弹窗自身的白底保持一致即可。
                color: Colors.white,
                boxShadow: const [BoxShadow(color: Color(0xffefefef), offset: Offset(0, -2), blurRadius: 15)],
              ),
              child: FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: () {
                  Navigator.of(sheetContext).pop(pickerKey.currentState?.selectedDate ?? DateTime.now());
                },
                child: const Text('确定', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      );
    },
  );
}

Border _themeBorder() => Border.all(color: const Color(0xFFE0E0E0), width: 0.5);

String _todayLabel() {
  return '今天';
}

/// 年月日周 4 列日期选择器，年/月/日可独立滚动，周根据当前选择实时计算
class TimetableDatePicker extends StatefulWidget {
  const TimetableDatePicker({
    super.key,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.itemHeight = 44.0,
    this.count = 4,
  });

  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final double itemHeight;
  final int count;

  @override
  State<TimetableDatePicker> createState() => _TimetableDatePickerState();
}

class _TimetableDatePickerState extends State<TimetableDatePicker> {
  late DateTime _firstDate;
  late DateTime _lastDate;
  late DateTime _selectedDate;

  late List<int> _years;
  late List<int> _months;
  late List<int> _days;

  /// 周列表循环次数：前后各补一份，保证首尾周几也能居中显示
  static const int _weekdayCycleCount = 3;

  late List<String> _weekdayItems;

  DateTime get selectedDate => _selectedDate;

  /// 当前选中日期在周列表中的下标（取中间那一份循环）
  int get _centeredWeekdayIndex => _weekdayItems.length ~/ _weekdayCycleCount + _selectedDate.weekday - 1;

  @override
  void initState() {
    super.initState();
    final today = _dateOnly(DateTime.now());
    _firstDate = _dateOnly(widget.firstDate ?? today);
    _lastDate = _dateOnly(widget.lastDate ?? DateTime(2030, 12, 31));
    _selectedDate = _clampToRange(_dateOnly(widget.initialDate ?? today));
    _years = <int>[];
    for (var year = _firstDate.year; year <= _lastDate.year; year++) {
      _years.add(year);
    }
    _months = _monthsOf(_selectedDate.year);
    _days = _daysOf(_selectedDate.year, _selectedDate.month);
    // 2024-01-01 为周一：一周文案按周一至周日排列，再循环补齐前后各一份
    const weekdayTexts = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    _weekdayItems = <String>[];
    for (var index = 0; index < weekdayTexts.length * _weekdayCycleCount; index++) {
      _weekdayItems.add(weekdayTexts[index % weekdayTexts.length]);
    }
  }

  ///定位到今天
  void resetToToday() {
    setState(() {
      _selectedDate = _clampToRange(_dateOnly(DateTime.now()));
      _months = _monthsOf(_selectedDate.year);
      _days = _daysOf(_selectedDate.year, _selectedDate.month);
    });
  }

  /// 年份变化：重新计算可选月份、天数，并将选中日期收敛到合法范围
  void _onYearChanged(int index) {
    setState(() {
      _selectedDate = _clampToRange(DateTime(_years[index], _selectedDate.month, _selectedDate.day));
      _months = _monthsOf(_selectedDate.year);
      _days = _daysOf(_selectedDate.year, _selectedDate.month);
    });
  }

  /// 月份变化：重新计算天数，并收敛选中日期
  void _onMonthChanged(int index) {
    setState(() {
      _selectedDate = _clampToRange(_buildDate(_selectedDate.year, _months[index], _selectedDate.day));
      _days = _daysOf(_selectedDate.year, _selectedDate.month);
    });
  }

  /// 日期变化：仅更新时间与周几
  void _onDayChanged(int index) {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month, _days[index]);
    });
  }

  DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

  DateTime _clampToRange(DateTime value) {
    if (value.isBefore(_firstDate)) {
      return _firstDate;
    }
    if (value.isAfter(_lastDate)) {
      return _lastDate;
    }
    return value;
  }

  /// 构建合法日期，自动收敛到当月最后一天
  DateTime _buildDate(int year, int month, int day) {
    final maxDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day.clamp(1, maxDay));
  }

  List<int> _monthsOf(int year) {
    final start = year == _firstDate.year ? _firstDate.month : 1;
    final end = year == _lastDate.year ? _lastDate.month : 12;
    final months = <int>[];
    for (var month = start; month <= end; month++) {
      months.add(month);
    }
    return months;
  }

  List<int> _daysOf(int year, int month) {
    var start = 1;
    var end = DateTime(year, month + 1, 0).day;
    if (year == _firstDate.year && month == _firstDate.month) {
      start = _firstDate.day;
    }
    if (year == _lastDate.year && month == _lastDate.month) {
      end = _lastDate.day;
    }
    final days = <int>[];
    for (var day = start; day <= end; day++) {
      days.add(day);
    }
    return days;
  }

  String _yearText(int year) => '$year年';

  String _monthText(int month) => '$month月';

  String _dayText(int day) => '$day日';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.itemHeight * widget.count,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TimetableWheelColumn(
              key: const ValueKey('year'),
              items: _years.map(_yearText).toList(),
              initialItem: _years.indexOf(_selectedDate.year),
              itemHeight: widget.itemHeight,
              onSelectedItemChanged: _onYearChanged,
            ),
          ),
          Expanded(
            flex: 2,
            child: TimetableWheelColumn(
              key: const ValueKey('month'),
              items: _months.map(_monthText).toList(),
              initialItem: _months.indexOf(_selectedDate.month),
              itemHeight: widget.itemHeight,
              onSelectedItemChanged: _onMonthChanged,
            ),
          ),
          Expanded(
            flex: 2,
            child: TimetableWheelColumn(
              key: const ValueKey('day'),
              items: _days.map(_dayText).toList(),
              initialItem: _days.indexOf(_selectedDate.day),
              itemHeight: widget.itemHeight,
              onSelectedItemChanged: _onDayChanged,
            ),
          ),
          // 周几列展示一整周，日期变化时自动将对应周几滚动到中间
          Expanded(
            flex: 1,
            child: IgnorePointer(
              child: TimetableWheelColumn(
                key: const ValueKey('weekday'),
                items: _weekdayItems,
                initialItem: _centeredWeekdayIndex,
                itemHeight: widget.itemHeight,
                onSelectedItemChanged: (_) {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 单列滚轮：内部持有 [FixedExtentScrollController]，配合 [CupertinoPicker.builder]。
///
/// 与上层只交换「选项 / 初始下标 / 单行高度 / 回调」，controller 由本列自己持有；
/// 它随本类一起翻译成 JS（JS 侧 controller 是宿主真实 controller 的镜像句柄）。
class TimetableWheelColumn extends StatefulWidget {
  const TimetableWheelColumn({
    super.key,
    required this.items,
    required this.initialItem,
    required this.itemHeight,
    required this.onSelectedItemChanged,
    this.selectedColor = 0xFFE53935,
    this.unselectedColor = 0xFF000000,
    this.fontSize = 32,
  });

  final List<String> items;
  final int initialItem;
  final double itemHeight;
  final ValueChanged<int> onSelectedItemChanged;
  final int selectedColor;
  final int unselectedColor;
  final double fontSize;

  @override
  State<TimetableWheelColumn> createState() => _TimetableWheelColumnState();
}

class _TimetableWheelColumnState extends State<TimetableWheelColumn> {
  late FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _createController();
    _controller.addListener(_onScroll);
  }

  FixedExtentScrollController _createController() {
    final maxItem = widget.items.isEmpty ? 0 : widget.items.length - 1;
    return FixedExtentScrollController(initialItem: widget.initialItem.clamp(0, maxItem));
  }

  @override
  void didUpdateWidget(covariant TimetableWheelColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    final maxItem = widget.items.isEmpty ? 0 : widget.items.length - 1;
    final target = widget.initialItem.clamp(0, maxItem);
    if (oldWidget.items.length != widget.items.length) {
      _replaceController();
    } else if (_controller.hasClients) {
      if (_controller.selectedItem != target) {
        // 不能在 didUpdateWidget 里同步 jumpToItem：它会立刻派发滚动通知，
        // 上层 onSelectedItemChanged 随即 setState，撞上「build 中 setState」
        // 断言（原生与 JS 两侧同一条规则）。延后一拍再跳。
        Future.delayed(const Duration(milliseconds: 1), () {
          if (!mounted || !_controller.hasClients) {
            return;
          }
          final maxIndex = widget.items.isEmpty ? 0 : widget.items.length - 1;
          final next = widget.initialItem.clamp(0, maxIndex);
          if (_controller.selectedItem != next) {
            _controller.jumpToItem(next);
          }
        });
      }
    } else if (oldWidget.initialItem != widget.initialItem) {
      _replaceController();
    }
  }

  void _replaceController() {
    final old = _controller;
    _controller = _createController();
    _controller.addListener(_onScroll);
    // 旧 controller 仍被上一帧的 picker 持有：延后一拍再释放（宿主下一帧
    // 重建完 picker 之后再 dispose，避免释放时仍被引用）。
    Future.delayed(const Duration(milliseconds: 32), () {
      old.dispose();
    });
  }

  void _onScroll() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  /// 选中项样式（用 getter：builder 闭包里引用时才折算得成字段引用）。
  TextStyle get _selectedStyle =>
      TextStyle(fontSize: widget.fontSize, color: Color(widget.selectedColor), fontWeight: FontWeight.bold);

  /// 未选中项样式。
  TextStyle get _unselectedStyle => TextStyle(fontSize: widget.fontSize, color: Color(widget.unselectedColor));

  @override
  Widget build(BuildContext context) {
    return CupertinoPicker.builder(
      key: ValueKey(_controller),
      scrollController: _controller,
      itemExtent: widget.itemHeight,
      onSelectedItemChanged: widget.onSelectedItemChanged,
      magnification: 1.2,
      squeeze: 1,
      diameterRatio: 4,
      useMagnifier: true,
      selectionOverlay: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: const Color(0xffe4e4e4), width: 0.5),
            bottom: BorderSide(color: const Color(0xffe4e4e4), width: 0.5),
          ),
        ),
      ),
      childCount: widget.items.length,
      itemBuilder: (context, index) {
        return Center(
          child: Text(
            widget.items[index],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _controller.selectedItem == index ? _selectedStyle : _unselectedStyle,
          ),
        );
      },
    );
  }
}
