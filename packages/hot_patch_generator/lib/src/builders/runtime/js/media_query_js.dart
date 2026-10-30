// ===== 基础能力：MediaQuery（JS 侧片段）=====
//
// JS 里 `MediaQuery.of(context)` / `MediaQuery.sizeOf(context)` 等**全部实时代理到
// Flutter 的 `MediaQuery.of` 系列**：
//   - `context` 代理与宿主真值 BuildContext 本来就是 1:1 绑定（`__handle()` 返回
//     ctx 句柄，宿主凭它反查**该组件自己位置**的 BuildContext）；
//   - 每个静态方法按**自己的 aspect** 单独向宿主取一次值：
//       `MediaQuery.of(context)`        → aspect = null（整份）
//       `MediaQuery.sizeOf(context)`    → aspect = 'size'
//       `MediaQuery.textScalerOf(...)`  → aspect = 'textScaler' ……
//     宿主对应调 Flutter 的 `MediaQuery.of` / `sizeOf` / `textScalerOf` 等取值
//     （见 hot_patch 的 media_query_bridge.dart）；
//   - aspect 粒度同时决定**重建粒度**：宿主只在某个 aspect 的值变了才回推
//     `__setMediaQuery(ctxId, aspect, value)`，JS 侧只标脏订阅了该 aspect 的
//     组件——与 Flutter 的 `dependOnInheritedWidgetOfExactType(aspect:)` 一致
//     （只用了 `sizeOf` 的组件不会因字号变化而重建）。
//
// 入口只有两个：`__mediaQueryOf(context)` / `__mediaQueryAspect(context, aspect)` 负责
// 同步读、缺值时向宿主取；`__setMediaQuery` 是宿主回填同一份缓存的唯一写口。
// 缓存不是第二套数据源，而是「同步读」在异步桥上的必要底座——build 里
// `mq.size.width` 必须同步拿到值，而 JS→宿主只能返回 Promise（见 runtime 的 `__sendToHost()`）。
//
// 粒度是 **ctx（组件实例）**：同一页面不同位置的组件各读各自 BuildContext 上的
// MediaQuery，页内嵌套 `MediaQuery` 覆盖也各归各位。
const String mediaQueryJsSource = r'''
  // ctx 句柄 id -> {
  //   anchor, all, allKey, vals: {aspect: value}, keys: {aspect: key},
  //   pending: {aspect: true}, missing: {aspect: true}
  // }
  var __mediaQueryByContext = {};
  // 最近一次解析到的整份真值：新 ctx 首帧尚未回填时先读它（同一运行时同一窗口，
  // 基本等价），避免「先显示 0x0 再校正」的闪一帧。
  var __lastFullMediaQuery = null;
  // 真值到达前的兜底常量（构造一次）：字段齐全，避免读崩。
  var __fallbackMediaQuery = null;

  function __createTextScaler(factor) {
    return { __factor: factor, scale: function (x) { return this.__factor * x; } };
  }

  function __emptyMediaQuery() {
    if (__fallbackMediaQuery == null) {
      __fallbackMediaQuery = __buildMediaQuery({
        size: { width: 0, height: 0 },
        padding: { left: 0, top: 0, right: 0, bottom: 0 },
        viewPadding: { left: 0, top: 0, right: 0, bottom: 0 },
        viewInsets: { left: 0, top: 0, right: 0, bottom: 0 },
        devicePixelRatio: 1,
        textScaleFactor: 1,
        orientation: Orientation.portrait,
        platformBrightness: Brightness.light,
        alwaysUse24HourFormat: false,
        accessibleNavigation: false,
        disableAnimations: false,
        invertColors: false,
        highContrast: false,
        boldText: false,
        navigationMode: NavigationMode.traditional,
      });
    }
    return __fallbackMediaQuery;
  }

  // 宿主下发的 JSON → JS 侧 MediaQueryData 同形对象（aspect = null 时整份）。
  function __buildMediaQuery(json) {
    var s = json.size || { width: 0, height: 0 };
    var f = json.textScaleFactor != null ? json.textScaleFactor : 1;
    return {
      size: new Size({ width: s.width, height: s.height }),
      padding: json.padding,
      viewPadding: json.viewPadding,
      viewInsets: json.viewInsets,
      devicePixelRatio: json.devicePixelRatio,
      textScaleFactor: f,
      textScaler: __createTextScaler(f),
      orientation: json.orientation,
      platformBrightness: json.platformBrightness,
      alwaysUse24HourFormat: json.alwaysUse24HourFormat,
      accessibleNavigation: json.accessibleNavigation,
      disableAnimations: json.disableAnimations,
      invertColors: json.invertColors,
      highContrast: json.highContrast,
      boldText: json.boldText,
      navigationMode: json.navigationMode,
    };
  }

  // 单 aspect 的宿主原值 → 本端值（size 包成 Size、textScaler 包出 scale 方法，
  // 其余是标量 / 已同形的对象，原样用）。
  function __decodeMediaQuery(aspect, raw) {
    if (aspect == null) { return __buildMediaQuery(raw); }
    if (aspect === 'size') {
      return new Size({ width: raw.width, height: raw.height });
    }
    if (aspect === 'textScaler') { return __createTextScaler(raw.__factor); }
    return raw;
  }

  function __mediaQueryEntry(id, context) {
    var e = __mediaQueryByContext[id];
    if (!e) {
      e = __mediaQueryByContext[id] = {
        anchor: context ? context.__anchor : null,
        all: null, allKey: '',
        vals: {}, keys: {}, pending: {}, missing: {},
      };
    }
    return e;
  }

  // 唯一写口：宿主回填 / 变化回推。
  //   aspect = null → 整份数据；否则只更新该 aspect。
  //   **与缓存不同才标脏**（一次真值变化只重建一次）。
  function __setMediaQuery(ctxId, aspect, raw) {
    var id = String(ctxId);
    var e = __mediaQueryEntry(id, null);
    if (raw == null) {
      // 该位置上方没有 MediaQuery：标记后不再重试，避免每次 build 都发桥消息。
      e.missing[aspect] = true;
      return;
    }
    var key = JSON.stringify(raw);
    if (aspect == null) {
      if (e.allKey === key) { return; }
      e.allKey = key;
      e.all = __buildMediaQuery(raw);
      __lastFullMediaQuery = e.all;
    } else {
      if (e.keys[aspect] === key) { return; }
      e.keys[aspect] = key;
      e.vals[aspect] = __decodeMediaQuery(aspect, raw);
    }
    var a = e.anchor;
    if (a && a.__unmounted) {
      // 组件已卸载（句柄即将/已被释放）：丢掉这条缓存，不再标脏。
      delete __mediaQueryByContext[id];
      return;
    }
    if (a) { markDirty(a); }
  }

  // 按 aspect 向宿主取一次值（每个 aspect 只取一次，之后靠回推）。
  function __fetchMediaQuery(e, id, aspect) {
    var slot = aspect == null ? 'all' : aspect;
    if (e.pending[slot] || e.missing[slot]) { return; }
    e.pending[slot] = true;
    try {
      var p = handleOp(id, 'mediaQuery',
        aspect == null ? null : { 'aspect': aspect });
      if (p && typeof p.then === 'function') {
        p.then(function (raw) {
          e.pending[slot] = false;
          __setMediaQuery(id, aspect, raw);
        }, function () { e.pending[slot] = false; });
      } else {
        e.pending[slot] = false;
      }
    } catch (err) {
      e.pending[slot] = false;
    }
  }

  // `MediaQuery.of(context)`：整份数据（依赖全部 aspect）。
  function __mediaQueryOf(context) {
    var id = null;
    try { id = context.__handle(); } catch (err) { id = null; }
    if (id == null) { return __lastFullMediaQuery || __emptyMediaQuery(); }
    var e = __mediaQueryEntry(id, context);
    if (e.all == null) { __fetchMediaQuery(e, id, null); }
    return e.all || __lastFullMediaQuery || __emptyMediaQuery();
  }

  // `MediaQuery.<x>Of(context)`：只依赖该 aspect。
  function __mediaQueryAspect(context, aspect) {
    var id = null;
    try { id = context.__handle(); } catch (err) { id = null; }
    if (id == null) { return (__lastFullMediaQuery || __emptyMediaQuery())[aspect]; }
    var e = __mediaQueryEntry(id, context);
    var v = e.vals[aspect];
    if (v === undefined) { __fetchMediaQuery(e, id, aspect); }
    if (v !== undefined) { return v; }
    // 该 aspect 还没回来：从整份数据 / 最近值 / 兜底里取同名字段投影。
    var src = e.all || __lastFullMediaQuery || __emptyMediaQuery();
    return src[aspect];
  }

  // Dart 的静态取值方法：每个都按自己的 aspect 代理（取值 + 重建粒度都对齐）。
  export const MediaQuery = {
    of: function (context) { return __mediaQueryOf(context); },
    // `maybeOf` 语义：没有 MediaQuery 祖先时返回 null；这里退化为兜底对象
    // （字段齐全，读不崩），与 `of` 同源。
    maybeOf: function (context) { return __mediaQueryOf(context); },
    sizeOf: function (context) { return __mediaQueryAspect(context, 'size'); },
    paddingOf: function (context) { return __mediaQueryAspect(context, 'padding'); },
    viewPaddingOf: function (context) {
      return __mediaQueryAspect(context, 'viewPadding');
    },
    viewInsetsOf: function (context) {
      return __mediaQueryAspect(context, 'viewInsets');
    },
    devicePixelRatioOf: function (context) {
      return __mediaQueryAspect(context, 'devicePixelRatio');
    },
    textScalerOf: function (context) {
      return __mediaQueryAspect(context, 'textScaler');
    },
    orientationOf: function (context) {
      return __mediaQueryAspect(context, 'orientation');
    },
    platformBrightnessOf: function (context) {
      return __mediaQueryAspect(context, 'platformBrightness');
    },
    navigationModeOf: function (context) {
      return __mediaQueryAspect(context, 'navigationMode');
    },
    alwaysUse24HourFormatOf: function (context) {
      return __mediaQueryAspect(context, 'alwaysUse24HourFormat');
    },
    accessibleNavigationOf: function (context) {
      return __mediaQueryAspect(context, 'accessibleNavigation');
    },
    boldTextOf: function (context) {
      return __mediaQueryAspect(context, 'boldText');
    },
    disableAnimationsOf: function (context) {
      return __mediaQueryAspect(context, 'disableAnimations');
    },
    highContrastOf: function (context) {
      return __mediaQueryAspect(context, 'highContrast');
    },
    invertColorsOf: function (context) {
      return __mediaQueryAspect(context, 'invertColors');
    },
  };

  G.__setMediaQuery = __setMediaQuery;
''';
