// ===== 基础能力：MediaQuery（JS 侧片段）=====
//
// JS 里 `MediaQuery.of(context)` / `MediaQuery.sizeOf(context)` 等**全部实时代理到
// Flutter 的 `MediaQuery.of(context)`**：
//   - `context` 代理与宿主真值 BuildContext 本来就是 1:1 绑定（`__handle()` 返回
//     ctx 句柄，宿主凭它反查**该组件自己位置**的 BuildContext）；
//   - `__jsuiMqOf` 首次读发一次 `handleOp(ctxId, 'mediaQuery')`，宿主读
//     `MediaQuery.of` 真值回填（见 hot_patch 的 media_query_bridge.dart）；
//   - 真值变化（旋转 / 缩放 / 字号 / 深色模式 / 无障碍）由宿主按 **ctx 句柄**回推
//     `__jsuiSetMediaQuery(ctxId, json)`，本端标脏该组件重建。
//
// 只有**读**（`__jsuiMqOf` / `__jsuiSetMediaQuery`）两个入口：前者是从缓存同步读、
// 缺值时向宿主取；后者是宿主回填同一份缓存的唯一写口。缓存不是第二套数据源，而是
// 「同步读」在异步桥上的必要底座——build 里 `mq.size.width` 必须同步拿到值，而
// JS→宿主只能返回 Promise（见 runtime 的 `send()`）。
//
// 粒度是 **ctx（组件实例）**：同一页面不同位置的组件各读各自 BuildContext 上的
// MediaQuery，页内嵌套 `MediaQuery` 覆盖也各归各位。
const String mediaQueryJsSource = r'''
  // ctx 句柄 id -> { data, key, pending, missing, anchor }。
  var __jsuiMqByCtx = {};
  // 最近一次解析到的真值：新 ctx 首次读时先读它（同一运行时同一窗口，基本等价），
  // 避免「先显示 0x0 再校正」的闪一帧。
  var __jsuiMqLast = null;
  // 真值到达前的兜底常量（构造一次）：字段齐全，避免读崩。
  var __jsuiMqFallback = null;

  function __jsuiMqEmpty() {
    if (__jsuiMqFallback == null) {
      __jsuiMqFallback = __jsuiMqBuild({
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
    return __jsuiMqFallback;
  }

  function __jsuiMqScale(factor) {
    return { __factor: factor, scale: function (x) { return this.__factor * x; } };
  }

  // 宿主下发的 JSON → JS 侧 MediaQueryData 同形对象。
  function __jsuiMqBuild(json) {
    var s = json.size || { width: 0, height: 0 };
    var f = json.textScaleFactor != null ? json.textScaleFactor : 1;
    return {
      size: new Size({ width: s.width, height: s.height }),
      padding: json.padding,
      viewPadding: json.viewPadding,
      viewInsets: json.viewInsets,
      devicePixelRatio: json.devicePixelRatio,
      textScaleFactor: f,
      textScaler: __jsuiMqScale(f),
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

  // 唯一写口：宿主回填 / 变化回推（ctx 句柄 id + MediaQueryData 的 JSON 形态）。
  // **与缓存不同才标脏**消费它的组件实例（一次真值变化只重建一次）。
  function __jsuiSetMediaQuery(ctxId, json) {
    var id = String(ctxId);
    var e = __jsuiMqByCtx[id];
    if (!e) {
      e = __jsuiMqByCtx[id] = {
        data: null, key: '', pending: false, missing: false, anchor: null
      };
    }
    if (json == null) {
      // 上方没有 MediaQuery（宿主读不到真值）：标记后不再重试，避免每次 build
      // 都发一次桥消息。
      e.missing = true;
      return;
    }
    e.missing = false;
    var key = JSON.stringify(json);
    if (e.key === key) { return; }
    e.key = key;
    e.data = __jsuiMqBuild(json);
    __jsuiMqLast = e.data;
    var a = e.anchor;
    if (a && a.__unmounted) {
      // 组件已卸载（句柄即将/已被释放）：丢掉这条缓存，不再标脏。
      delete __jsuiMqByCtx[id];
      return;
    }
    if (a) { markDirty(a); }
  }

  // 与 Flutter 同形的 `MediaQuery.of(context)`：同步返回缓存值，**首次**读取时向
  // 宿主取该位置的真值（之后的变化由宿主按 ctx 句柄回推）。
  function __jsuiMqOf(context) {
    var id = null;
    try { id = context.__handle(); } catch (err) { id = null; }
    if (id == null) { return __jsuiMqLast || __jsuiMqEmpty(); }
    var e = __jsuiMqByCtx[id];
    if (!e) {
      e = __jsuiMqByCtx[id] = {
        data: null, key: '', pending: false, missing: false,
        anchor: context.__anchor
      };
    }
    if (e.data == null && !e.pending && !e.missing) {
      e.pending = true;
      try {
        var p = handleOp(id, 'mediaQuery', null);
        if (p && typeof p.then === 'function') {
          p.then(function (json) {
            e.pending = false;
            __jsuiSetMediaQuery(id, json);
          }, function () { e.pending = false; });
        } else {
          e.pending = false;
        }
      } catch (err2) {
        e.pending = false;
      }
    }
    return e.data || __jsuiMqLast || __jsuiMqEmpty();
  }

  // Dart 的静态取值方法：全部是 `__jsuiMqOf(context)` 的取值投影，走同一条代理
  // （因此同样会向宿主取真值、并由宿主回推后标脏重建）。
  var MediaQuery = {
    of: function (context) { return __jsuiMqOf(context); },
    // `maybeOf` 语义：没有 MediaQuery 祖先时返回 null；这里退化为兜底对象
    // （字段齐全，读不崩），与 `of` 同源。
    maybeOf: function (context) { return __jsuiMqOf(context); },
    sizeOf: function (context) { return __jsuiMqOf(context).size; },
    paddingOf: function (context) { return __jsuiMqOf(context).padding; },
    viewPaddingOf: function (context) { return __jsuiMqOf(context).viewPadding; },
    viewInsetsOf: function (context) { return __jsuiMqOf(context).viewInsets; },
    devicePixelRatioOf: function (context) {
      return __jsuiMqOf(context).devicePixelRatio;
    },
    textScalerOf: function (context) { return __jsuiMqOf(context).textScaler; },
    orientationOf: function (context) { return __jsuiMqOf(context).orientation; },
    platformBrightnessOf: function (context) {
      return __jsuiMqOf(context).platformBrightness;
    },
    navigationModeOf: function (context) {
      return __jsuiMqOf(context).navigationMode;
    },
    alwaysUse24HourFormatOf: function (context) {
      return __jsuiMqOf(context).alwaysUse24HourFormat;
    },
    accessibleNavigationOf: function (context) {
      return __jsuiMqOf(context).accessibleNavigation;
    },
    boldTextOf: function (context) { return __jsuiMqOf(context).boldText; },
    disableAnimationsOf: function (context) {
      return __jsuiMqOf(context).disableAnimations;
    },
    highContrastOf: function (context) { return __jsuiMqOf(context).highContrast; },
    invertColorsOf: function (context) { return __jsuiMqOf(context).invertColors; },
  };

  // Dart 枚举 / 常量镜像：产物里 `Orientation.portrait` 等是原样引用，
  // 值取同一套字符串（宿主 JSON 里也是这套字符串）。
  var Orientation = { portrait: 'portrait', landscape: 'landscape' };
  var Brightness = { dark: 'dark', light: 'light' };
  var NavigationMode = { traditional: 'traditional', directional: 'directional' };

  G.MediaQuery = MediaQuery;
  G.Orientation = Orientation;
  G.Brightness = Brightness;
  G.NavigationMode = NavigationMode;
  G.__jsuiSetMediaQuery = __jsuiSetMediaQuery;
''';
