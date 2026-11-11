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
// 缓存与读取逻辑收在 `MediaQuery` 类上（静态字段 = 缓存，静态方法 = 读取）。
// **MediaQuery 的 JS 类是手写 Component 子类**（本文件）：宿主注册 `'MediaQuery'`
// 只负责渲染，类登记在 `logicWidgetTypes`（生成器不再重复生成同名包装类）。
// 命名构造 `removePadding / removeViewInsets / removeViewPadding` 与其它组件同构：
// 静态方法把构造名写进 `props.factory`，宿主 renderer 按 factory 分派。
const String mediaQueryJsSource = r'''
  // `MediaQueryData`：宿主回填的整份数据 / `MediaQuery(data: ...)` 的入参。
  // 字段名与宿主 media_query_bridge 的 `_readAspect(null)` 一一对应；缺省值同
  // Flutter `MediaQueryData()` 的默认构造。`copyWith` 支持
  // `MediaQuery.of(context).copyWith(textScaler: ...)` 这类常见写法（函数属性
  // 不参与 JSON，跨桥时自然被丢弃）。
  export class MediaQueryData {
    constructor(props) {
      var p = props || {};
      var zero = new EdgeInsets({});
      this.size = p.size != null ? p.size : new Size({ width: 0, height: 0 });
      this.padding = p.padding != null ? p.padding : zero;
      this.viewPadding = p.viewPadding != null ? p.viewPadding : zero;
      this.viewInsets = p.viewInsets != null ? p.viewInsets : zero;
      this.devicePixelRatio = p.devicePixelRatio != null ? p.devicePixelRatio : 1;
      var scaler = p.textScaler;
      if (scaler == null && p.textScaleFactor != null) {
        scaler = TextScaler.linear({ textScaleFactor: p.textScaleFactor });
      }
      this.textScaler = scaler != null ? scaler : TextScaler.noScaling;
      this.textScaleFactor = this.textScaler.scale ? this.textScaler.scale(1) : 1;
      this.orientation = p.orientation != null ? p.orientation : Orientation.portrait;
      this.platformBrightness = p.platformBrightness != null
          ? p.platformBrightness
          : Brightness.light;
      this.alwaysUse24HourFormat = p.alwaysUse24HourFormat === true;
      this.accessibleNavigation = p.accessibleNavigation === true;
      this.disableAnimations = p.disableAnimations === true;
      this.invertColors = p.invertColors === true;
      this.highContrast = p.highContrast === true;
      this.boldText = p.boldText === true;
      this.navigationMode = p.navigationMode != null
          ? p.navigationMode
          : NavigationMode.traditional;
    }
    copyWith(args) {
      var a = args || {};
      return new MediaQueryData(Object.assign({}, this, a));
    }
  }

  // ===== MediaQuery =====
  //
  // 普通组件（宿主注册 `'MediaQuery'` → 宿主 renderer），但 JS 类由本片段手写并
  // 登记在 `logicWidgetTypes`（生成器不再重复生成同名包装类）：
  //   - 静态取值 API（`of/sizeOf/...`）返回 `MediaQueryData`；
  //   - 命名构造静态方法与其它组件同构：写 `factory` 交给宿主 renderer 分派。
  export class MediaQuery extends Component {
    // 命名构造：与宿主包装类生成的静态方法完全同形（`SizedBox.shrink` 同款）。
    static removePadding(props) {
      return new MediaQuery(Object.assign({}, props, { factory: 'removePadding' }));
    }
    static removeViewInsets(props) {
      return new MediaQuery(Object.assign({}, props, { factory: 'removeViewInsets' }));
    }
    static removeViewPadding(props) {
      return new MediaQuery(Object.assign({}, props, { factory: 'removeViewPadding' }));
    }

    // ctx 句柄 id -> {
    //   anchor, all, allKey, vals: {aspect: value}, keys: {aspect: key},
    //   pending: {aspect: true}, missing: {aspect: true}
    // }
    static __byContext = {};
    // 最近一次解析到的整份真值：新 ctx 首帧尚未回填时先读它（同一运行时同一窗口，
    // 基本等价），避免「先显示 0x0 再校正」的闪一帧。
    static __lastFull = null;
    // 真值到达前的兜底常量（构造一次）：字段齐全，避免读崩。
    static __fallback = null;

    static __empty() {
      if (MediaQuery.__fallback == null) {
        MediaQuery.__fallback = MediaQuery.__build({
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
      return MediaQuery.__fallback;
    }

    // 宿主下发的 JSON → JS 侧 MediaQueryData（字段齐全，含 copyWith）。
    static __build(json) {
      return new MediaQueryData(json);
    }

    // 单 aspect 的宿主原值 → 本端值（size 包成 Size、textScaler 包出 scale 方法，
    // 其余是标量 / 已同形的对象，原样用）。
    static __decode(aspect, raw) {
      if (aspect == null) { return MediaQuery.__build(raw); }
      if (aspect === 'size') {
        return new Size({ width: raw.width, height: raw.height });
      }
      if (aspect === 'textScaler') {
        return TextScaler.linear({ textScaleFactor: raw.__factor });
      }
      return raw;
    }

    static __entry(id, context) {
      var e = MediaQuery.__byContext[id];
      if (!e) {
        e = MediaQuery.__byContext[id] = {
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
    static __set(ctxId, aspect, raw) {
      var id = String(ctxId);
      var e = MediaQuery.__entry(id, null);
      if (raw == null) {
        // 该位置上方没有 MediaQuery：标记后不再重试，避免每次 build 都发桥消息。
        e.missing[aspect] = true;
        return;
      }
      var key = JSON.stringify(raw);
      if (aspect == null) {
        if (e.allKey === key) { return; }
        e.allKey = key;
        e.all = MediaQuery.__build(raw);
        MediaQuery.__lastFull = e.all;
      } else {
        if (e.keys[aspect] === key) { return; }
        e.keys[aspect] = key;
        e.vals[aspect] = MediaQuery.__decode(aspect, raw);
      }
      var a = e.anchor;
      if (a && a.__unmounted) {
        // 组件已卸载（句柄即将/已被释放）：丢掉这条缓存，不再标脏。
        delete MediaQuery.__byContext[id];
        return;
      }
      if (a) { __cc.__markDirty(a); }
    }

    // 按 aspect 向宿主取一次值（每个 aspect 只取一次，之后靠回推）。
    static __fetch(e, id, aspect) {
      var slot = aspect == null ? 'all' : aspect;
      if (e.pending[slot] || e.missing[slot]) { return; }
      e.pending[slot] = true;
      try {
        var p = __handleOp(id, 'mediaQuery',
          aspect == null ? null : { 'aspect': aspect });
        if (p && typeof p.then === 'function') {
          p.then(function (raw) {
            e.pending[slot] = false;
            MediaQuery.__set(id, aspect, raw);
          }, function () { e.pending[slot] = false; });
        } else {
          e.pending[slot] = false;
        }
      } catch (err) {
        e.pending[slot] = false;
      }
    }

    // `MediaQuery.of(context)`：整份数据（依赖全部 aspect）。
    static __of(context) {
      var id = null;
      try { id = context.__handle(); } catch (err) { id = null; }
      if (id == null) { return MediaQuery.__lastFull || MediaQuery.__empty(); }
      var e = MediaQuery.__entry(id, context);
      if (e.all == null) { MediaQuery.__fetch(e, id, null); }
      return e.all || MediaQuery.__lastFull || MediaQuery.__empty();
    }

    // `MediaQuery.<x>Of(context)`：只依赖该 aspect。
    static __aspect(context, aspect) {
      var id = null;
      try { id = context.__handle(); } catch (err) { id = null; }
      if (id == null) { return (MediaQuery.__lastFull || MediaQuery.__empty())[aspect]; }
      var e = MediaQuery.__entry(id, context);
      var v = e.vals[aspect];
      if (v === undefined) { MediaQuery.__fetch(e, id, aspect); }
      if (v !== undefined) { return v; }
      // 该 aspect 还没回来：从整份数据 / 最近值 / 兜底里取同名字段投影。
      var src = e.all || MediaQuery.__lastFull || MediaQuery.__empty();
      return src[aspect];
    }

    // Dart 的静态取值方法：每个都按自己的 aspect 代理（取值 + 重建粒度都对齐）。
    static of(context) { return MediaQuery.__of(context); }
    // `maybeOf` 语义：没有 MediaQuery 祖先时返回 null；这里退化为兜底对象
    // （字段齐全，读不崩），与 `of` 同源。
    static maybeOf(context) { return MediaQuery.__of(context); }
    static sizeOf(context) { return MediaQuery.__aspect(context, 'size'); }
    static paddingOf(context) { return MediaQuery.__aspect(context, 'padding'); }
    static viewPaddingOf(context) {
      return MediaQuery.__aspect(context, 'viewPadding');
    }
    static viewInsetsOf(context) {
      return MediaQuery.__aspect(context, 'viewInsets');
    }
    static devicePixelRatioOf(context) {
      return MediaQuery.__aspect(context, 'devicePixelRatio');
    }
    static textScalerOf(context) {
      return MediaQuery.__aspect(context, 'textScaler');
    }
    static orientationOf(context) {
      return MediaQuery.__aspect(context, 'orientation');
    }
    static platformBrightnessOf(context) {
      return MediaQuery.__aspect(context, 'platformBrightness');
    }
    static navigationModeOf(context) {
      return MediaQuery.__aspect(context, 'navigationMode');
    }
    static alwaysUse24HourFormatOf(context) {
      return MediaQuery.__aspect(context, 'alwaysUse24HourFormat');
    }
    static accessibleNavigationOf(context) {
      return MediaQuery.__aspect(context, 'accessibleNavigation');
    }
    static boldTextOf(context) {
      return MediaQuery.__aspect(context, 'boldText');
    }
    static disableAnimationsOf(context) {
      return MediaQuery.__aspect(context, 'disableAnimations');
    }
    static highContrastOf(context) {
      return MediaQuery.__aspect(context, 'highContrast');
    }
    static invertColorsOf(context) {
      return MediaQuery.__aspect(context, 'invertColors');
    }
  }

  // 宿主回填写口（宿主经 evaluate 裸引用调用，故挂 G）。
  G.__setMediaQuery = MediaQuery.__set;
''';
