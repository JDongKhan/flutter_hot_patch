// ===== 基础能力：MediaQuery（宿主侧 = Flutter 真值的实时代理）=====
//
// JS 里 `MediaQuery.of(context)` / `MediaQuery.sizeOf(context)` 等**一律实时代理到
// Flutter 对应的静态方法**：JS 的 `context` 代理与宿主真值 BuildContext 本来就是
// 1:1 绑定（ctx 句柄，见 build_context_bridge.dart 的 `jsBuildContextOf`），故按
// ctx 句柄 id 取到**该组件自己位置**的 BuildContext，直接调用
// `MediaQuery.sizeOf(ctx)` / `MediaQuery.textScalerOf(ctx)` / `MediaQuery.maybeOf(ctx)`…
// ——aspect 语义、嵌套 MediaQuery 取最近者，全部由 Flutter 自己保证，本文件不做
// 字段搬运与自行判等。
//
// 两端分工（同步约束决定的，不是设计选择）：JS 读值必须同步（build 里直接读
// `.size` / `.orientation`），而 JS→宿主只有异步桥 —— 故 JS 每个静态方法首次调用
// 发一次 `mediaQuery` op（载荷带 aspect）拿到值，之后读缓存；真值变化（旋转 /
// 缩放 / 字号 / 深色模式 / 无障碍开关）由本文件按 **ctx + aspect** 回推给 JS，
// 只有订阅了该 aspect 的组件会被标脏——与 Flutter 里 `sizeOf` 只依赖 size 一致。
import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../../../services/js_runtime_manager.dart';
import '../../../utils/dynamic_flutter_log.dart';
import '../../js_widget_registry.dart';
import '../build_context/build_context_bridge.dart';

/// ctx 句柄 id → {aspect(null=整份) → 上次下发的 payload 文本}。
/// 键的存在即表示该 ctx 订阅过（JS 读过 MediaQuery），值用于「没变就不推」。
final Map<String, Map<String?, String>> _subscribed = {};

/// 已告警过「取不到 BuildContext」的 ctx（同一次运行只出声一次）。
final Set<String> _unresolvedLogged = {};

/// 已告警过「该位置上方没有 MediaQuery」的 ctx（同一次运行只出声一次）。
final Set<String> _absentLogged = {};

bool _mediaQueryOpRegistered = false;

/// 把 `mediaQuery` 这个 context op 注册进核心的分发缝（由 MediaQueryLibrary 调用）。
void ensureMediaQueryContextOps() {
  if (_mediaQueryOpRegistered) return;
  _mediaQueryOpRegistered = true;
  registerContextOp(
    'mediaQuery',
    // 某个 aspect（null=整份）的真值：JS 侧 `MediaQuery.of/sizeOf/...` 的首次取值。
    onOp: (ctxId, op, payload) {
      final aspect = _aspectOf(payload);
      final value = _readAspect(ctxId, aspect);
      if (value == null) return null;
      _subscribed.putIfAbsent(ctxId, () => {})[aspect] = jsonEncode(value);
      return value;
    },
    // 组件卸载 → 句柄释放：停止回推（否则会给已释放的 id 发消息）。
    onRelease: _subscribed.remove,
  );
  WidgetsBinding.instance.addObserver(_MediaQueryWatcher());
}

String? _aspectOf(Object? payload) {
  if (payload is Map) {
    final a = payload['aspect'];
    if (a is String && a.isNotEmpty) return a;
  }
  return null;
}

/// `MediaQuery` 组件（含 `removePadding` / `removeViewPadding` /
/// `removeViewInsets` 三个命名构造）的宿主渲染。
///
/// 它就是**普通宿主组件**：JS 类由宿主包装类生成（`export class MediaQuery
/// extends Component`），命名构造由生成器写成同名静态方法并带 `factory`——
/// 与 `SizedBox.shrink` 等完全同构。renderer 按 `factory` 分派到 Flutter 对应
/// API，语义与原生一致：
///   - 无名构造 → `MediaQuery(data:, child:)`；
///   - `remove*` → 用**调用位置**的 BuildContext 调 Flutter 同名方法（
///     [JsRenderContext.context]，宿主构建期传入并沿子树透传）。
void registerMediaQueryWidgets(JsWidgetRegistry r) {
  r.register('MediaQuery', (c) {
    final child =
        (c.children['child'] as Widget?) ?? const SizedBox.shrink();
    final factory = c.str('factory');
    if (factory == 'removePadding' ||
        factory == 'removeViewPadding' ||
        factory == 'removeViewInsets') {
      final context = c.context;
      if (context == null) {
        JsLog.warn(
          'js_ui: MediaQuery.$factory 取不到 BuildContext，按原样渲染 child',
        );
        return child;
      }
      final removeLeft = c.bool_('removeLeft') ?? false;
      final removeTop = c.bool_('removeTop') ?? false;
      final removeRight = c.bool_('removeRight') ?? false;
      final removeBottom = c.bool_('removeBottom') ?? false;
      switch (factory) {
        case 'removePadding':
          return MediaQuery.removePadding(
            key: c.key,
            context: context,
            removeLeft: removeLeft,
            removeTop: removeTop,
            removeRight: removeRight,
            removeBottom: removeBottom,
            child: child,
          );
        case 'removeViewPadding':
          return MediaQuery.removeViewPadding(
            key: c.key,
            context: context,
            removeLeft: removeLeft,
            removeTop: removeTop,
            removeRight: removeRight,
            removeBottom: removeBottom,
            child: child,
          );
        default:
          return MediaQuery.removeViewInsets(
            key: c.key,
            context: context,
            removeLeft: removeLeft,
            removeTop: removeTop,
            removeRight: removeRight,
            removeBottom: removeBottom,
            child: child,
          );
      }
    }
    final data = _mediaQueryDataFromJson(c.map('data'));
    return MediaQuery(
      key: c.key,
      data: data ?? const MediaQueryData(),
      child: child,
    );
  });
}

/// JS 侧 `MediaQueryData`（`{size, padding, viewPadding, viewInsets,
/// devicePixelRatio, textScaler, orientation, platformBrightness, 各开关}`）→
/// Flutter `MediaQueryData`。
///
/// **不引入自己的默认值**：从 `const MediaQueryData()` 起步，只对 JS 里**真实存在**
/// 的字段 `copyWith`，缺字段一律沿用 Flutter 官方默认构造值（`Size.zero` /
/// `devicePixelRatio: 1` / `TextScaler.noScaling` / 各开关 false /
/// `NavigationMode.traditional` …）。这样两端默认值只有一处在维护。
MediaQueryData? _mediaQueryDataFromJson(Map<String, dynamic>? json) {
  if (json == null || json.isEmpty) return null;
  var data = const MediaQueryData();

  final size = _sizeOf(json['size']);
  if (size != null) data = data.copyWith(size: size);

  final dpr = json['devicePixelRatio'];
  if (dpr is num) data = data.copyWith(devicePixelRatio: dpr.toDouble());

  final scaler = json['textScaler'];
  double? factor;
  if (scaler is Map && scaler['linear'] is num) {
    factor = (scaler['linear'] as num).toDouble();
  } else if (json['textScaleFactor'] is num) {
    factor = (json['textScaleFactor'] as num).toDouble();
  }
  if (factor != null) {
    data = data.copyWith(textScaler: TextScaler.linear(factor));
  }

  final brightness = json['platformBrightness'];
  if (brightness is String) {
    data = data.copyWith(
      platformBrightness:
          brightness == 'dark' ? Brightness.dark : Brightness.light,
    );
  }

  final padding = _edgesOf(json['padding']);
  if (padding != null) data = data.copyWith(padding: padding);

  final viewPadding = _edgesOf(json['viewPadding']);
  if (viewPadding != null) data = data.copyWith(viewPadding: viewPadding);

  final viewInsets = _edgesOf(json['viewInsets']);
  if (viewInsets != null) data = data.copyWith(viewInsets: viewInsets);

  bool? flag(String key) => json[key] is bool ? json[key] as bool : null;
  final alwaysUse24HourFormat = flag('alwaysUse24HourFormat');
  if (alwaysUse24HourFormat != null) {
    data = data.copyWith(alwaysUse24HourFormat: alwaysUse24HourFormat);
  }
  final accessibleNavigation = flag('accessibleNavigation');
  if (accessibleNavigation != null) {
    data = data.copyWith(accessibleNavigation: accessibleNavigation);
  }
  final disableAnimations = flag('disableAnimations');
  if (disableAnimations != null) {
    data = data.copyWith(disableAnimations: disableAnimations);
  }
  final invertColors = flag('invertColors');
  if (invertColors != null) data = data.copyWith(invertColors: invertColors);
  final highContrast = flag('highContrast');
  if (highContrast != null) data = data.copyWith(highContrast: highContrast);
  final boldText = flag('boldText');
  if (boldText != null) data = data.copyWith(boldText: boldText);

  final navigationMode = json['navigationMode'];
  if (navigationMode is String) {
    data = data.copyWith(
      navigationMode: navigationMode == 'directional'
          ? NavigationMode.directional
          : NavigationMode.traditional,
    );
  }
  return data;
}

Size? _sizeOf(Object? v) =>
    v is Map && v['width'] is num && v['height'] is num
        ? Size(
            (v['width'] as num).toDouble(),
            (v['height'] as num).toDouble(),
          )
        : null;

EdgeInsets? _edgesOf(Object? v) => v is Map
    ? EdgeInsets.fromLTRB(
        (v['left'] as num?)?.toDouble() ?? 0,
        (v['top'] as num?)?.toDouble() ?? 0,
        (v['right'] as num?)?.toDouble() ?? 0,
        (v['bottom'] as num?)?.toDouble() ?? 0,
      )
    : null;

/// `MediaQuery` 相关的系统级变化 → 给所有订阅者回推新值。
///
/// 覆盖 `MediaQueryData` 的全部平台来源：窗口尺寸 / 字号 / 深色模式 / 无障碍
/// 开关 / 语言。
class _MediaQueryWatcher with WidgetsBindingObserver {
  @override
  void didChangeMetrics() => _refreshAll();

  @override
  void didChangeTextScaleFactor() => _refreshAll();

  @override
  void didChangePlatformBrightness() => _refreshAll();

  @override
  void didChangeAccessibilityFeatures() => _refreshAll();

  @override
  void didChangeLocales(List<Locale>? locales) => _refreshAll();
}

/// 逐个订阅者、逐个 aspect 重读真值，有变化才回推。
void _refreshAll() {
  if (_subscribed.isEmpty) return;
  if (!JsRuntimeManager.instance.isJsUiRuntimeReady) return;
  for (final ctxId in _subscribed.keys.toList()) {
    final aspects = _subscribed[ctxId]!;
    for (final aspect in aspects.keys.toList()) {
      final value = _readAspect(ctxId, aspect);
      if (value == null) continue;
      final key = jsonEncode(value);
      if (key == aspects[aspect]) continue;
      aspects[aspect] = key;
      JsRuntimeManager.instance.evaluate(
        '__setMediaQuery(${jsonEncode(ctxId)}, '
        '${aspect == null ? 'null' : jsonEncode(aspect)}, '
        '${jsonEncode(value)});',
      );
    }
  }
}

/// aspect（null = 整份）→ Flutter 真值。直接调 Flutter 的静态方法，字段形态与
/// 生成器 media_query_js.dart 的 `__buildMediaQuery` / `__decodeMediaQuery` 一一对应。
Object? _readAspect(String ctxId, String? aspect) {
  final ctx = jsBuildContextOf(ctxId);
  if (ctx == null) {
    if (_unresolvedLogged.add(ctxId)) {
      JsLog.warn(
        'js_ui: mediaQuery 取不到 BuildContext（ctx=$ctxId, aspect=$aspect）'
        '：组件结点的锚点未登记或已卸载',
      );
    }
    return null;
  }
  switch (aspect) {
    case null:
      final d = MediaQuery.maybeOf(ctx);
      if (d == null) {
        // 该位置上方确实没有 MediaQuery（页面根直接挂在无 MaterialApp 的根上）：
        // 不是竞态，JS 侧会记 missing 不再重试——但必须出声，否则就是静默降级。
        if (_absentLogged.add('$ctxId|all')) {
          JsLog.warn(
            'js_ui: mediaQuery 取不到整份数据（ctx=$ctxId）：该位置上方没有 MediaQuery',
          );
        }
        return null;
      }
      return {
        'size': _sizeJson(d.size),
        'padding': _edgesJson(d.padding),
        'viewPadding': _edgesJson(d.viewPadding),
        'viewInsets': _edgesJson(d.viewInsets),
        'devicePixelRatio': d.devicePixelRatio,
        'textScaleFactor': d.textScaler.scale(1.0),
        'orientation': d.orientation.name,
        'platformBrightness': d.platformBrightness.name,
        'alwaysUse24HourFormat': d.alwaysUse24HourFormat,
        'accessibleNavigation': d.accessibleNavigation,
        'disableAnimations': d.disableAnimations,
        'invertColors': d.invertColors,
        'highContrast': d.highContrast,
        'boldText': d.boldText,
        'navigationMode': d.navigationMode.name,
      };
    case 'size':
      final v = MediaQuery.maybeSizeOf(ctx);
      return v == null ? null : _sizeJson(v);
    case 'padding':
      final v = MediaQuery.maybePaddingOf(ctx);
      return v == null ? null : _edgesJson(v);
    case 'viewPadding':
      final v = MediaQuery.maybeViewPaddingOf(ctx);
      return v == null ? null : _edgesJson(v);
    case 'viewInsets':
      final v = MediaQuery.maybeViewInsetsOf(ctx);
      return v == null ? null : _edgesJson(v);
    case 'devicePixelRatio':
      return MediaQuery.maybeDevicePixelRatioOf(ctx);
    case 'textScaler':
      final v = MediaQuery.maybeTextScalerOf(ctx);
      return v == null ? null : {'__factor': v.scale(1.0)};
    case 'orientation':
      return MediaQuery.maybeOrientationOf(ctx)?.name;
    case 'platformBrightness':
      return MediaQuery.maybePlatformBrightnessOf(ctx)?.name;
    case 'alwaysUse24HourFormat':
      return MediaQuery.maybeAlwaysUse24HourFormatOf(ctx);
    case 'accessibleNavigation':
      return MediaQuery.maybeAccessibleNavigationOf(ctx);
    case 'disableAnimations':
      return MediaQuery.maybeDisableAnimationsOf(ctx);
    case 'invertColors':
      return MediaQuery.maybeInvertColorsOf(ctx);
    case 'highContrast':
      return MediaQuery.maybeHighContrastOf(ctx);
    case 'boldText':
      return MediaQuery.maybeBoldTextOf(ctx);
    case 'navigationMode':
      return MediaQuery.maybeNavigationModeOf(ctx)?.name;
  }
  // 未识别的 aspect（JS 侧新增了 Dart 里没有的静态方法）：当整份处理，避免
  // 静默返回 null 让 JS 侧按「上方没有 MediaQuery」永久放弃重试。
  return _readAspect(ctxId, null);
}

Map<String, Object?> _sizeJson(Size s) => {'width': s.width, 'height': s.height};

/// `EdgeInsets` → JS 侧同形值对象（与产物里 padding 类属性的 JSON 形态一致）。
Map<String, Object?> _edgesJson(EdgeInsets e) => {
      'left': e.left,
      'top': e.top,
      'right': e.right,
      'bottom': e.bottom,
    };
