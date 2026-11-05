// GENERATED CODE - DO NOT EDIT
// 由 hot_patch_generator 从 lib/base/app_log_console.dart 自动生成
// 重新生成：dart run build_runner build

import { ChangeNotifier, DateTime } from '../flutter.js';

export const AppLogLevel = (function () { const __values = []; function __mk(name, index) { return { name: name, index: index, toString: function () { return "AppLogLevel." + name; } }; } const info = __mk("info", 0); __values.push(info); const warn = __mk("warn", 1); __values.push(warn); const error = __mk("error", 2); __values.push(error); return { info: info, warn: warn, error: error, values: __values }; })();
export const appLogZoneSpecification = new ZoneSpecification({print: (self, parent, zone, line) => { AppLogCenter.instance.add(line);
    parent.print(zone, line); }});

// 模型 AppLogRecord
export class AppLogRecord {
  constructor(args) {
    this.__applyProps(args);
  }
  __applyProps(args) {
    this.time = (args && args.time !== undefined) ? args.time : null;
    this.text = (args && args.text !== undefined) ? args.text : '';
    this.level = (args && args.level !== undefined) ? args.level : null;
  }
}

// 模型 AppLogCenter
export class AppLogCenter extends ChangeNotifier {
  static instance = AppLogCenter._();
  static maxRecords = 1000;
  constructor(args) {
    super(args);
    this._records = [];
    this._notifyScheduled = false;
  }
  get records() {
    return List.unmodifiable({elements: this._records});
  }
  add(text) {
    this._records.add(new AppLogRecord({
      "time": DateTime.now({}),
      "text": text,
      "level": AppLogCenter._levelOf(text)
    }));
    if ((this._records.length > AppLogCenter.maxRecords)) {
      this._records.removeRange(0, (this._records.length - AppLogCenter.maxRecords));
    }
    this._scheduleNotify();
  }
  clear() {
    if (this._records.isEmpty) {
      return;
    }
    this._records.clear();
    this.notifyListeners();
  }
  _scheduleNotify() {
    if (this._notifyScheduled) {
      return;
    }
    this._notifyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => { this._notifyScheduled = false;
      this.notifyListeners(); });
    WidgetsBinding.instance.scheduleFrame();
  }
  static _levelOf(text) {
    if (text.contains("[ERROR]")) {
      return AppLogLevel.error;
    }
    if ((text.contains("[WARN]") || text.contains("[WARNING]"))) {
      return AppLogLevel.warn;
    }
    return AppLogLevel.info;
  }
  // 命名构造 AppLogCenter._
  static _(args) {
    const __o = new AppLogCenter(args);
    return __o;
  }
}

