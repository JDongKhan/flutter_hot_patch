// Dart 核心库（dart:core）里「JS 没有同名原生类型」的值类镜像。
//
// 收录标准：Dart 源码里是普通构造 / 静态工厂，而 JS 侧没有同名可用的内建类型。
// 产物按统一规则一比一发射：
//   `DateTime(2024, 1, 2)`     → `new DateTime({year: 2024, month: 1, day: 2})`
//   `DateTime.now()`           → `DateTime.now()`
//   `DateTime.utc(2024, 1, 2)` → `DateTime.utc({year: 2024, month: 1, day: 2})`
//   `RegExp(r'\d+')`           → `new RegExp({source: "\\d+"})`
//   `StringBuffer()`           → `new StringBuffer({})`
//   `int.parse(s)`             → `int.parse(s)`
//
// 成员名必须与 Dart 完全一致（getter 用 `get`），翻译层不认识任何类名。
//
// 与 dart_values_js.dart 的差异：这里放的是「JS 有近似物但 API 不同」的类型
// （Date / RegExp / 字符串缓冲），基础值对象仍留在 dart_values_js.dart。
const String dartCoreJsSource = r'''
  // ---------------------------------------------------------------------------
  // DateTime：内部只存「自纪元起的微秒数 + 时区标记」，所有字段按 Dart 语义
  // 现算。JS Date 只到毫秒，微秒部分自己保留。
  // ---------------------------------------------------------------------------
  function __padNum(n, width) {
    var s = String(Math.abs(n));
    while (s.length < width) { s = '0' + s; }
    return (n < 0 ? '-' : '') + s;
  }

  function __durationUs(d) {
    if (d == null) { return 0; }
    if (typeof d === 'number') { return d * 1000; }
    if (typeof d.inMicroseconds === 'number') { return d.inMicroseconds; }
    var ms = __durationMs(d);
    return ms == null ? 0 : ms * 1000;
  }

  export class DateTime {
    static __names = ['year', 'month', 'day', 'hour', 'minute', 'second',
      'millisecond', 'microsecond'];

    constructor(props) {
      props = __positionalArgs(props, DateTime.__names);
      var y = props.year != null ? props.year : 1970;
      var mo = props.month != null ? props.month : 1;
      var d = props.day != null ? props.day : 1;
      var h = props.hour != null ? props.hour : 0;
      var mi = props.minute != null ? props.minute : 0;
      var s = props.second != null ? props.second : 0;
      var ms = props.millisecond != null ? props.millisecond : 0;
      var us = props.microsecond != null ? props.microsecond : 0;
      var utc = props.isUtc === true;
      var dt = new Date(0);
      // JS Date 的构造函数会把 0..99 年映射到 1900+，setFullYear 不会，
      // 因此统一走 setFullYear / setHours（顺带处理月份、日期溢出）。
      if (utc) {
        dt.setUTCFullYear(y, mo - 1, d);
        dt.setUTCHours(h, mi, s, ms);
      } else {
        dt.setFullYear(y, mo - 1, d);
        dt.setHours(h, mi, s, ms);
      }
      this.__us = dt.getTime() * 1000 + us;
      this.__utc = utc;
    }

    static __fromUs(us, utc) {
      var d = Object.create(DateTime.prototype);
      d.__us = us;
      d.__utc = utc;
      return d;
    }

    __date() { return new Date(Math.trunc(this.__us / 1000)); }
    __part(name) {
      var d = this.__date();
      return this.__utc ? d['getUTC' + name]() : d['get' + name]();
    }

    get year() { return this.__part('FullYear'); }
    get month() { return this.__part('Month') + 1; }
    get day() { return this.__part('Date'); }
    get hour() { return this.__part('Hours'); }
    get minute() { return this.__part('Minutes'); }
    get second() { return this.__part('Seconds'); }
    get millisecond() { return this.__part('Milliseconds'); }
    get microsecond() { return ((this.__us % 1000) + 1000) % 1000; }
    get weekday() { return ((this.__part('Day') + 6) % 7) + 1; }
    get isUtc() { return this.__utc; }
    get millisecondsSinceEpoch() { return Math.trunc(this.__us / 1000); }
    get microsecondsSinceEpoch() { return this.__us; }

    get timeZoneOffset() {
      if (this.__utc) { return new Duration({}); }
      return new Duration({ milliseconds: -this.__date().getTimezoneOffset() * 60000 });
    }

    get timeZoneName() {
      if (this.__utc) { return 'UTC'; }
      try {
        var parts = new Intl.DateTimeFormat('en-US', { timeZoneName: 'short' })
          .formatToParts(this.__date());
        for (var i = 0; i < parts.length; i++) {
          if (parts[i].type === 'timeZoneName') { return parts[i].value; }
        }
      } catch (e) { /* 无 Intl 时走下面的 GMT 兜底 */ }
      var off = -this.__date().getTimezoneOffset();
      var hours = Math.trunc(off / 60);
      var mins = Math.abs(off % 60);
      return 'GMT' + (hours < 0 ? '-' : '+') + Math.abs(hours) +
        (mins === 0 ? '' : ':' + __padNum(mins, 2));
    }

    add(other) { return DateTime.__fromUs(this.__us + __durationUs(other), this.__utc); }
    subtract(other) { return DateTime.__fromUs(this.__us - __durationUs(other), this.__utc); }
    difference(other) { return new Duration({ microseconds: this.__us - other.__us }); }
    isBefore(other) { return this.__us < other.__us; }
    isAfter(other) { return this.__us > other.__us; }
    isAtSameMomentAs(other) { return this.__us === other.__us; }
    compareTo(other) { return this.__us < other.__us ? -1 : (this.__us > other.__us ? 1 : 0); }
    toLocal() { return this.__utc ? DateTime.__fromUs(this.__us, false) : this; }
    toUtc() { return this.__utc ? this : DateTime.__fromUs(this.__us, true); }

    toIso8601String() {
      var s = this.__datePartsString('T');
      if (this.microsecond !== 0) {
        s += __padNum(this.microsecond, 3);
      }
      return this.__utc ? s + 'Z' : s;
    }

    toString() {
      var s = this.__datePartsString(' ');
      return this.__utc ? s + 'Z' : s;
    }

    __datePartsString(separator) {
      return __padNum(this.year, 4) + '-' + __padNum(this.month, 2) + '-' +
        __padNum(this.day, 2) + separator + __padNum(this.hour, 2) + ':' +
        __padNum(this.minute, 2) + ':' + __padNum(this.second, 2) + '.' +
        __padNum(this.millisecond, 3);
    }

    // 跨桥形态：微秒数与 UTC 标记，宿主侧据此还原成 DateTime。
    toJSON() { return { __dateTime: this.__us, __utc: this.__utc }; }

    static now() { return DateTime.__fromUs(Date.now() * 1000, false); }

    static utc(props) {
      props = __positionalArgs(props, DateTime.__names);
      var p = {};
      for (var k in props) { p[k] = props[k]; }
      p.isUtc = true;
      return new DateTime(p);
    }

    static fromMillisecondsSinceEpoch(props) {
      props = __positionalArgs(props, ['millisecondsSinceEpoch']);
      return DateTime.__fromUs(Math.trunc(props.millisecondsSinceEpoch * 1000),
        props.isUtc === true);
    }

    static fromMicrosecondsSinceEpoch(props) {
      props = __positionalArgs(props, ['microsecondsSinceEpoch']);
      return DateTime.__fromUs(Math.trunc(props.microsecondsSinceEpoch),
        props.isUtc === true);
    }

    static parse(text) {
      var r = DateTime.__tryParse(text);
      if (r == null) { throw new FormatException('Invalid date format: ' + text); }
      return r;
    }

    static tryParse(text) { return DateTime.__tryParse(text); }

    // Dart 接受 `yyyy-MM-dd`、`yyyy-MM-dd HH:mm:ss`（空格或 T 分隔）、
    // 可选小数秒与时区标记；带时区标记的结果是 UTC 实例。
    static __tryParse(text) {
      if (typeof text !== 'string') { return null; }
      var m = /^([+-]?\d{4,6})-(\d{1,2})-(\d{1,2})(?:[T ](\d{1,2}):(\d{1,2})(?::(\d{1,2})(?:\.(\d{1,6}))?)?(Z|[+-]\d{2}:?\d{2})?)?$/
        .exec(text);
      if (m == null) { return null; }
      var y = Number(m[1]);
      var mo = Number(m[2]);
      var d = m[3] != null ? Number(m[3]) : 1;
      var h = m[4] != null ? Number(m[4]) : 0;
      var mi = m[5] != null ? Number(m[5]) : 0;
      var s = m[6] != null ? Number(m[6]) : 0;
      var fraction = m[7] != null ? (m[7] + '000000').substring(0, 6) : '000000';
      var us = Number(fraction);
      var zone = m[8];
      if (zone == null) {
        var local = new DateTime({ year: y, month: mo, day: d, hour: h,
          minute: mi, second: s, millisecond: Math.trunc(us / 1000),
          microsecond: us % 1000 });
        return local;
      }
      var base = new Date(0);
      base.setUTCFullYear(y, mo - 1, d);
      base.setUTCHours(h, mi, s, Math.trunc(us / 1000));
      var epochMs = base.getTime();
      if (zone !== 'Z') {
        var sign = zone.charAt(0) === '-' ? -1 : 1;
        var body = zone.substring(1).replace(':', '');
        var offsetMin = Number(body.substring(0, 2)) * 60 + Number(body.substring(2));
        epochMs -= sign * offsetMin * 60000;
      }
      return DateTime.__fromUs(epochMs * 1000 + (us % 1000), true);
    }
  }

  // ---------------------------------------------------------------------------
  // RegExp / Match：Dart 的匹配结果支持 `match[0]` 下标，因此 Match 实例上
  // 直接挂数字属性（不是数组，但 `m[0]` 一样可读）。
  // ---------------------------------------------------------------------------
  export class Match {
    constructor(groups, index, input, named) {
      for (var i = 0; i < groups.length; i++) { this[i] = groups[i]; }
      this.__groups = groups;
      this.__index = index;
      this.__input = input != null ? input : '';
      this.__named = named != null ? named : null;
    }

    get length() { return this.__groups.length; }
    get start() { return this.__index; }
    get end() {
      var g = this.__groups[0];
      return this.__index + (g == null ? 0 : g.length);
    }
    get input() { return this.__input; }
    get groupCount() { return this.__groups.length - 1; }

    group(i) {
      if (i != null && (i < 0 || i >= this.__groups.length)) {
        throw new RangeError('No such group: ' + i);
      }
      return this.__groups[i != null ? i : 0];
    }

    groups(ids) {
      var out = [];
      for (var i = 0; i < ids.length; i++) {
        var g = ids[i];
        out.push(g >= 0 && g < this.__groups.length ? this.__groups[g] : null);
      }
      return out;
    }

    namedGroup(name) {
      return this.__named == null ? null : (this.__named[name] != null ? this.__named[name] : null);
    }
  }

  export class RegExp {
    constructor(props) {
      props = __positionalArgs(props, ['source']);
      this.__source = props.source != null ? props.source : '';
      var flags = '';
      if (props.multiLine === true) { flags += 'm'; }
      if (props.caseSensitive === false) { flags += 'i'; }
      if (props.unicode === true) { flags += 'u'; }
      if (props.dotAll === true) { flags += 's'; }
      this.__flags = flags;
      // 类名遮蔽了原生 RegExp，必须显式走 globalThis。
      this.__probe(flags);
    }

    get pattern() { return this.__source; }
    get isCaseSensitive() { return this.__flags.indexOf('i') < 0; }
    get isMultiLine() { return this.__flags.indexOf('m') >= 0; }
    get isUnicode() { return this.__flags.indexOf('u') >= 0; }
    get isDotAll() { return this.__flags.indexOf('s') >= 0; }

    __probe(flags) { return new globalThis.RegExp(this.__source, flags); }

    hasMatch(input) { return this.__probe(this.__flags).test(__stringOf(input)); }

    firstMatch(input) {
      var text = __stringOf(input);
      var m = this.__probe(this.__flags).exec(text);
      return m == null ? null : new Match(m, m.index, text, m.groups);
    }

    allMatches(input, start) {
      var text = __stringOf(input);
      var re = this.__probe(this.__flags + 'g');
      var out = [];
      var from = start != null ? start : 0;
      re.lastIndex = from;
      while (true) {
        var m = re.exec(text);
        if (m == null) { break; }
        out.push(new Match(m, m.index, text, m.groups));
        if (m[0].length === 0) {
          re.lastIndex = m.index + 1;
          if (re.lastIndex > text.length) { break; }
        }
      }
      return out;
    }

    stringMatch(input) {
      var m = this.firstMatch(input);
      return m == null ? null : m[0];
    }
  }

  function __stringOf(v) { return v == null ? '' : String(v); }

  // ---------------------------------------------------------------------------
  // StringBuffer：只有「追加 + 取串」两件事，直接存分段数组。
  // ---------------------------------------------------------------------------
  export class StringBuffer {
    constructor(props) {
      props = __positionalArgs(props, ['content']);
      this.__parts = [];
      if (props.content != null) { this.__parts.push(__str(props.content)); }
    }

    get length() { return this.toString().length; }
    get isEmpty() { return this.__parts.length === 0; }
    get isNotEmpty() { return this.__parts.length !== 0; }

    write(obj) { this.__parts.push(__str(obj)); }

    writeln(obj) {
      if (obj == null && arguments.length === 0) {
        this.__parts.push('\n');
      } else {
        this.__parts.push(__str(obj) + '\n');
      }
    }

    toString() { return this.__parts.join(''); }
    clear() { this.__parts = []; }
    toJSON() { return this.toString(); }
  }

  // ---------------------------------------------------------------------------
  // int / double / num 的静态成员命名空间。
  //
  // 值本身仍是 JS number（不装箱）；这里只承接 `int.parse(...)` 这类**静态**
  // 调用——静态成员没有原型可挂，只能作为模块级命名空间对象存在。
  // 翻译层按自动抽取的小写导出名解析（见 runtime_global_types）。
  // ---------------------------------------------------------------------------
  function __intTryParse(source, radix) {
    if (typeof source !== 'string') { return null; }
    var s = source.trim();
    var r = radix == null ? 10 : radix;
    if (r < 2 || r > 36) { return null; }
    var negative = false;
    var first = s.charAt(0);
    if (first === '+' || first === '-') {
      negative = first === '-';
      s = s.substring(1);
    }
    if (s.length === 0) { return null; }
    if (r === 16 && (s.indexOf('0x') === 0 || s.indexOf('0X') === 0)) {
      s = s.substring(2);
      if (s.length === 0) { return null; }
    }
    for (var i = 0; i < s.length; i++) {
      var code = s.charCodeAt(i);
      var digit = code >= 48 && code <= 57 ? code - 48
        : (code >= 97 && code <= 122 ? code - 87
          : (code >= 65 && code <= 90 ? code - 55 : -1));
      if (digit < 0 || digit >= r) { return null; }
    }
    var v = parseInt((negative ? '-' : '') + s, r);
    return v === v && isFinite(v) ? v : null;
  }

  function __doubleTryParse(source) {
    if (typeof source !== 'string') { return null; }
    var s = source.trim();
    if (s.length === 0) { return null; }
    if (s === 'NaN') { return NaN; }
    if (s === 'Infinity' || s === '+Infinity') { return Infinity; }
    if (s === '-Infinity') { return -Infinity; }
    var v = Number(s);
    return v === v ? v : null;
  }

  export const int = {
    parse: function (source, opts) {
      opts = opts || {};
      var v = __intTryParse(source, opts.radix);
      if (v == null) {
        if (typeof opts.onError === 'function') { return opts.onError(source); }
        throw new FormatException('Invalid integer: ' + source);
      }
      return v;
    },
    tryParse: function (source, opts) {
      opts = opts || {};
      return __intTryParse(source, opts.radix);
    },
  };

  export const double = {
    parse: function (source, onError) {
      var v = __doubleTryParse(source);
      if (v == null) {
        if (typeof onError === 'function') { return onError(source); }
        throw new FormatException('Invalid double: ' + source);
      }
      return v;
    },
    tryParse: function (source) { return __doubleTryParse(source); },
    infinity: Infinity,
    negativeInfinity: -Infinity,
    nan: NaN,
    maxFinite: 1.7976931348623157e308,
    minPositive: 5e-324,
  };

  export const num = {
    parse: function (source, onError) {
      var i = __intTryParse(source, null);
      if (i != null) { return i; }
      var d = __doubleTryParse(source);
      if (d != null) { return d; }
      if (typeof onError === 'function') { return onError(source); }
      throw new FormatException('Invalid number: ' + source);
    },
    tryParse: function (source) {
      var i = __intTryParse(source, null);
      if (i != null) { return i; }
      return __doubleTryParse(source);
    },
  };
''';
