// ===== 基础能力：MediaQuery 同步镜像（JS 侧片段）=====
//
// 宿主把 `MediaQueryData` 归一成 JSON 下发（`__jsuiSetMediaQuery`，见
// capabilities/media_query/media_query_bridge.dart），本片段负责在 JS 侧建出
// 同形对象，并让 `MediaQuery.of(context)` 能在**同步**语义下返回它。
//
// 为什么必须由宿主推：JS 侧没有 SDK 的 `MediaQuery` 树，也没有同步调用宿主的
// 能力（JS→宿主是 Promise）。而 `MediaQuery.of(context).orientation` 这类读法
// 出现在 build / builder 里，必须是同步值。
//
// 依赖登记沿用 provider 的同一套语义：`MediaQuery.of(context)` 把消费它的
// 组件实例（`context.__anchor`）登记下来；数据变化时只把它们标脏，
// 由正常的帧级 flush 重建（与 Flutter 中 MediaQuery 变化触发依赖者重建一致）。
const String mediaQueryJsSource = r'''
  // 当前数据（初始为空值对象，避免首帧 before 推送时读崩）。
  var __jsuiMqData = null;
  // 上次下发的**原始 JSON 文本**：宿主在页面 build 时都会推一次，用文本比较
  // 即可廉价判「是否变化」，不必在 JS 里做深比较（宿主构造顺序固定）。
  var __jsuiMqKey = '';
  // 依赖者（消费过 `MediaQuery.of` 的组件实例）。
  var __jsuiMqDeps = [];

  function __jsuiMqEmpty() {
    return {
      size: new Size({ width: 0, height: 0 }),
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
    };
  }

  // 宿主推送入口：参数是 MediaQueryData 的 JSON 形态。
  function __jsuiSetMediaQuery(json) {
    var key = JSON.stringify(json);
    if (__jsuiMqData != null && key === __jsuiMqKey) { return; }
    __jsuiMqKey = key;
    var s = json.size || { width: 0, height: 0 };
    __jsuiMqData = {
      size: new Size({ width: s.width, height: s.height }),
      padding: json.padding,
      viewPadding: json.viewPadding,
      viewInsets: json.viewInsets,
      devicePixelRatio: json.devicePixelRatio,
      textScaleFactor: json.textScaleFactor,
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
    // 依赖者统一标脏；本帧内重建时会重新登记（未再消费的自然脱落）。
    var deps = __jsuiMqDeps;
    __jsuiMqDeps = [];
    for (var i = 0; i < deps.length; i++) {
      var d = deps[i];
      if (!d || d.__unmounted) { continue; }
      markDirty(d);
    }
  }

  // 与 Flutter 同形的 `MediaQuery.of(context)`：登记依赖 + 返回当前数据。
  var MediaQuery = {
    of: function (context) {
      var anchor = context && context.__anchor;
      if (anchor && __jsuiMqDeps.indexOf(anchor) < 0) {
        __jsuiMqDeps.push(anchor);
      }
      return __jsuiMqData || __jsuiMqEmpty();
    },
    // `maybeOf` 语义：没有 MediaQuery 祖先时返回 null。镜像里数据总是存在
    // （宿主一定会推），故等价于 `of`。
    maybeOf: function (context) {
      return MediaQuery.of(context);
    },
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
