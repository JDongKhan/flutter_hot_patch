// ===== 基础能力：MediaQuery（JS 侧片段）=====
//
// **取值优先级**：先查「最近一个 JS 侧 `MediaQuery(data:)` / `remove*` 结点」
// （运行时【8】的继承机制，同步、真值），查不到才回落到宿主桥：
//   - 页面根 / 上方没有 JS 声明 MediaQuery 的位置：`MediaQuery.of(context)` 按
//     位置向宿主取一次值（每个 aspect 一次），回填后标脏调用方重建；
//   - 上方有 JS 声明的 MediaQuery：本类在 build 里把自己登记为类型名
//     `'MediaQuery'` 的继承结点，子孙 `dependOnInheritedWidgetOfExactType`
//     直接读它的 `data`，数据变化时 `__notifyClients` 通知依赖者重建。
//     这条链路完全在 JS 内，不再逐位置发桥消息，也不会出现「值变了但缓存
//     不失效」。
//
// 缓存与读取逻辑收在 `MediaQuery` 类上（静态字段 = 桥路径缓存，静态方法 = 读取）。
// **MediaQuery 的 JS 类是手写 Component 子类**（本文件）：build 产出宿主
// `'MediaQuery'` 结点（宿主 renderer 负责渲染），类登记在 `logicWidgetTypes`
// （生成器不再重复生成同名包装类）。
// 命名构造 `removePadding / removeViewInsets / removeViewPadding` 与其它组件同构：
// 静态方法把构造名写进 `props.factory`，宿主 renderer 按 factory 分派；同时在
// 构造期按上层数据算出派生 `data`，供 JS 侧继承取值使用。
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
    // 与 Flutter `MediaQueryData.removePadding / removeViewPadding /
    // removeViewInsets` 同义：指定边归零。`remove*` 命名构造在 JS 侧用它算出
    // 派生值（原生结点仍由宿主按自己的 context 调 Flutter 同名 API，两者同源）。
    __removed(args, field) {
      var a = args || {};
      var cur = this[field] || new EdgeInsets({});
      return this.copyWith({
        [field]: new EdgeInsets({
          left: a.removeLeft === true ? 0 : cur.left,
          top: a.removeTop === true ? 0 : cur.top,
          right: a.removeRight === true ? 0 : cur.right,
          bottom: a.removeBottom === true ? 0 : cur.bottom,
        }),
      });
    }
    removePadding(args) { return this.__removed(args, 'padding'); }
    removeViewPadding(args) { return this.__removed(args, 'viewPadding'); }
    removeViewInsets(args) { return this.__removed(args, 'viewInsets'); }
  }

  // ===== MediaQuery =====
  //
  // 普通组件（宿主注册 `'MediaQuery'` → 宿主 renderer），但 JS 类由本片段手写并
  // 登记在 `logicWidgetTypes`（生成器不再重复生成同名包装类）：
  //   - 静态取值 API（`of/sizeOf/...`）返回 `MediaQueryData`；
  //   - 命名构造静态方法与其它组件同构：写 `factory` 交给宿主 renderer 分派。
  export class MediaQuery extends Component {
    // 命名构造：与宿主包装类生成的静态方法完全同形（`SizedBox.shrink` 同款）。
    // 宿主 renderer 仍按 `factory` 走原生 API；这里额外算出派生 `data`，让 JS 侧
    // 的继承取值拿到与原生一致的「去掉指定边」的值。
    static removePadding(props) { return MediaQuery.__removed('removePadding', props); }
    static removeViewInsets(props) { return MediaQuery.__removed('removeViewInsets', props); }
    static removeViewPadding(props) { return MediaQuery.__removed('removeViewPadding', props); }

    static __removed(kind, props) {
      var p = props || {};
      var out = {};
      for (var k in p) {
        if (Object.prototype.hasOwnProperty.call(p, k)) { out[k] = p[k]; }
      }
      out.factory = kind;
      var base = null;
      try { base = p.context ? MediaQuery.of(p.context) : null; } catch (err) { base = null; }
      if (base != null && typeof base[kind] === 'function') {
        out.data = base[kind]({
          removeLeft: p.removeLeft === true,
          removeTop: p.removeTop === true,
          removeRight: p.removeRight === true,
          removeBottom: p.removeBottom === true,
        });
      }
      return new MediaQuery(out);
    }

    // 把自己登记为类型名 `'MediaQuery'` 的继承结点（与 provider 的
    // ChangeNotifierProvider 同一机制），并产出宿主结点负责原生渲染。
    //
    // 重建粒度与 Flutter 的 `dependOnInheritedWidgetOfExactType(aspect:)` 对齐：
    // 依赖者按自己用到的 aspect 登记（见 __recordDep），这里只按**变化的 aspect**
    // 通知交集，`MediaQuery.sizeOf` 不会因字号等无关字段变化而重建。
    build() {
      __inheritElement(this, 'MediaQuery');
      var keys = MediaQuery.__aspectKeys(this.props.data);
      if (this.__mqKeys) {
        var changed = MediaQuery.__changedAspects(this.__mqKeys, keys);
        if (changed) { MediaQuery.__notifyChanged(this, changed); }
      }
      this.__mqKeys = keys;
      return Component.host('MediaQuery', this.props);
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

    // 逐 aspect 的数据指纹：`copyWith` / 每次 build 都会产出新实例，按对象身份
    // 比较会永远「有变化」；这里按字段值折算，只有真变化的 aspect 才通知。
    static __aspectKeys(d) {
      if (d == null) { return {}; }
      function edge(v) {
        return v == null ? '' : [v.left, v.top, v.right, v.bottom].join(',');
      }
      function name(v) {
        if (v == null) { return ''; }
        return v.name != null ? v.name : String(v);
      }
      function scaler(v) {
        return (v != null && typeof v.scale === 'function') ? String(v.scale(1)) : '';
      }
      function flag(v) { return v === true ? '1' : '0'; }
      return {
        size: d.size == null ? '' : d.size.width + ',' + d.size.height,
        padding: edge(d.padding),
        viewPadding: edge(d.viewPadding),
        viewInsets: edge(d.viewInsets),
        devicePixelRatio: String(d.devicePixelRatio),
        textScaler: scaler(d.textScaler),
        orientation: name(d.orientation),
        platformBrightness: name(d.platformBrightness),
        navigationMode: name(d.navigationMode),
        alwaysUse24HourFormat: flag(d.alwaysUse24HourFormat),
        accessibleNavigation: flag(d.accessibleNavigation),
        boldText: flag(d.boldText),
        disableAnimations: flag(d.disableAnimations),
        invertColors: flag(d.invertColors),
        highContrast: flag(d.highContrast),
      };
    }

    // 变化了的 aspect 集合（null = 什么都没变）。
    static __changedAspects(prev, cur) {
      var changed = null;
      for (var k in cur) {
        if (!Object.prototype.hasOwnProperty.call(cur, k)) { continue; }
        if (prev[k] !== cur[k]) {
          if (changed == null) { changed = {}; }
          changed[k] = true;
        }
      }
      return changed;
    }

    // 登记消费位置用到了哪些 aspect（`'all'` = 整份数据）。
    static __recordDep(el, context, aspect) {
      var anchor = context ? context.__anchor : null;
      if (anchor == null) { return; }
      var deps = el.__mqDeps || (el.__mqDeps = new Map());
      var set = deps.get(anchor);
      if (set == null) { set = {}; deps.set(anchor, set); }
      set[aspect == null ? 'all' : aspect] = true;
    }

    // 按「变化 aspect ∩ 消费位置登记的 aspect」通知，`'all'` 直接命中。
    // 顺带修剪陈旧的消费位置（已卸载 / 不再依赖本结点），与 `__dependents` 同寿命。
    static __notifyChanged(provider, changed) {
      var deps = provider.__mqDeps;
      if (deps == null) { return; }
      var live = provider.__dependents || [];
      var dead = [];
      deps.forEach(function (aspects, anchor) {
        if (anchor == null || anchor.__unmounted || live.indexOf(anchor) < 0) {
          dead.push(anchor);
          return;
        }
        var hit = aspects.all === true;
        if (!hit) {
          for (var k in changed) {
            if (Object.prototype.hasOwnProperty.call(changed, k) &&
                aspects[k] === true) {
              hit = true;
              break;
            }
          }
        }
        if (!hit) { return; }
        anchor.__depDirty = true;
        __cc.__markDirty(anchor);
      });
      for (var i = 0; i < dead.length; i++) { deps.delete(dead[i]); }
    }

    // 最近的 JS 侧 MediaQuery 结点提供的值（同步）；没有则返回 null，
    // 由调用方回落到宿主桥。查找同时把当前位置按 [aspect] 登记为该结点的依赖。
    static __provided(context, aspect) {
      if (context == null ||
          typeof context.dependOnInheritedWidgetOfExactType !== 'function') {
        return null;
      }
      var el = null;
      try {
        el = context.dependOnInheritedWidgetOfExactType({
          typeArguments: { 0: 'MediaQuery' },
        });
      } catch (err) {
        el = null;
      }
      if (el == null || el.props == null || el.props.data == null) { return null; }
      MediaQuery.__recordDep(el, context, aspect);
      return el.props.data;
    }

    // `MediaQuery.of(context)`：整份数据（依赖全部 aspect）。
    static __of(context) {
      var inherited = MediaQuery.__provided(context, 'all');
      if (inherited != null) { return inherited; }
      var id = null;
      try { id = context.__handle(); } catch (err) { id = null; }
      if (id == null) { return MediaQuery.__lastFull || MediaQuery.__empty(); }
      var e = MediaQuery.__entry(id, context);
      if (e.all == null) { MediaQuery.__fetch(e, id, null); }
      return e.all || MediaQuery.__lastFull || MediaQuery.__empty();
    }

    // `MediaQuery.<x>Of(context)`：只依赖该 aspect。
    static __aspect(context, aspect) {
      var inherited = MediaQuery.__provided(context, aspect);
      if (inherited != null) { return inherited[aspect]; }
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
