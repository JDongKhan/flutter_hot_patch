// ===== 可选能力：把 JS 句柄控制的 Ticker 绑到宿主 TickerMode（暂停 / 续跑）=====
//
// 为什么需要：AnimationController / TabController 的真实对象在 **JS 构造时**创建
// （见 core/object_bridge.dart 的时序契约），没有「某个 State 的 vsync」可用，也就
// 拿不到 TickerProviderStateMixin 附带的静音语义。本模块用宿主渲染位置的
// TickerMode 手动 mute 裸 Ticker——`Ticker.muted` 的 setter 内部就是
// `unscheduleTick` / 重新 `scheduleTick`，与 Flutter 的「暂停后恢复接着跑」完全同
// 语义。
//
// 独立性（本模块与其它部分**互不依赖**）：
//   - 不 import object_bridge、不 import 任何能力文件；只用 scheduler / widgets；
//   - 能力侧只调两个函数：
//       * `jsTickerProviderFor(id)`：控制器构造时当 vsync（debugLabel 直接用句柄 id）；
//       * `jsBindTickerMode(id, context)`：把控制器交给真实 widget 的那一帧登记挂载点。
//   - **关闭**：把 [jsTickerModeBindingEnabled] 置 false（或删本文件 + 两处调用），
//     行为立刻退回「裸 Ticker 不静音」，其它代码零改动。开关在控制器**构造时**生效，
//     改完开关后新建的控制器才受影响（已有控制器沿用创建时的选择）。
//
// 已知取舍（有意为之，不做「全关才静音」的引用计数）：
//   - 同一控制器被多个视图共享时，以**最先登记**的挂载点所在子树的 TickerMode 为准；
//     再登记直接忽略（TabBar + TabBarView 同属一棵子树，无实际差异）。
//   - 挂载点只记 notifier（不记 BuildContext），provider 用弱引用挂在 id→provider
//     表上：控制器被释放后条目自动失效，无需卸载钩子，也不持有 element 引用。
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/scheduler.dart'
    show Ticker, TickerCallback, TickerProvider;
import 'package:flutter/widgets.dart' show BuildContext, TickerMode;

/// 是否启用本模块（**默认关闭**：实现先留着，需要时一行打开）。
///
/// 关闭时：`jsTickerProviderFor` 返回不带静音的裸 Ticker，`jsBindTickerMode`
/// 变成空操作——与未实现本模块时的行为一致（动画在被遮住的子树里仍后台跑完）。
/// 打开方式：在 App `main()`（`runApp` 之前、任何 JS 控制器构造之前）写
/// `jsTickerModeBindingEnabled = true;`。
bool jsTickerModeBindingEnabled = false;

/// id → Ticker 工厂。弱引用：控制器释放（`Ticker.dispose`）后条目自动失效，
/// 只在下一次插入时顺带清理，不需要任何显式释放调用。
final Map<String, WeakReference<JsTickerProvider>> _providers = {};

/// 控制器构造时取 vsync。
///
/// [id] 是句柄 id（`js:ctrl/Tab#12`），同时用作 Ticker 的 `debugLabel`，debug 下
/// Ticker 列表能直接定位到是哪个 JS 实例。
TickerProvider jsTickerProviderFor(String id) {
  if (!jsTickerModeBindingEnabled) return _PlainTickerProvider(id);
  final existing = _providers[id]?.target;
  if (existing != null) return existing;
  _providers.removeWhere((_, ref) => ref.target == null);
  final provider = JsTickerProvider(id);
  _providers[id] = WeakReference<JsTickerProvider>(provider);
  return provider;
}

/// 把该 id 的 Ticker 绑到 [context] 所在子树的 TickerMode。
///
/// 由「把控制器交给真实 widget」的渲染方调用（每帧调用安全：只登记一次）。
/// [context] 为 null（值对象里就地还原的元素没有宿主构建位置）或控制器已释放时
/// 什么都不做——保持「不静音」而不是报错。
void jsBindTickerMode(String id, BuildContext? context) {
  if (!jsTickerModeBindingEnabled || context == null) return;
  final provider = _providers[id]?.target;
  if (provider == null) return;
  // `TickerMode.getNotifier` 内部用的是非依赖取值（不建立 InheritedWidget 依赖，
  // 不会让本结点因 TickerMode 变化额外重建），只拿一个可监听的 notifier。
  provider.bind(TickerMode.getNotifier(context));
}

/// 每个控制器一个：持有它创建的 Ticker，并把 muted 状态跟到绑定的 TickerMode。
class JsTickerProvider implements TickerProvider {
  JsTickerProvider(this.id);

  final String id;

  Ticker? _ticker;
  ValueListenable<bool>? _mode;

  @override
  Ticker createTicker(TickerCallback onTick) {
    final ticker = _JsTicker(this, onTick, debugLabel: id);
    _ticker = ticker;
    if (_mode != null) {
      _mode!.addListener(_applyMuted);
      _applyMuted();
    }
    return ticker;
  }

  /// 登记挂载点（只认第一次）；控制器尚未创建 Ticker 时先记下 notifier，
  /// Ticker 懒建（首次 `animateTo`）时再挂监听。
  void bind(ValueListenable<bool> mode) {
    if (_mode != null) return;
    _mode = mode;
    if (_ticker != null) {
      mode.addListener(_applyMuted);
      _applyMuted();
    }
  }

  void _applyMuted() {
    final ticker = _ticker;
    final mode = _mode;
    if (ticker == null || mode == null) return;
    ticker.muted = !mode.value;
  }

  /// Ticker 被 controller 释放：摘监听，条目随之失效（弱引用自动回收）。
  void _detach() {
    _mode?.removeListener(_applyMuted);
    _mode = null;
    _ticker = null;
    final ref = _providers[id];
    if (ref != null && ref.target == this) _providers.remove(id);
  }
}

class _JsTicker extends Ticker {
  _JsTicker(this._owner, super.onTick, {super.debugLabel});

  final JsTickerProvider _owner;

  @override
  void dispose() {
    _owner._detach();
    super.dispose();
  }
}

/// 模块关闭时的 vsync：裸 Ticker（只带 debugLabel，不感知 TickerMode）。
class _PlainTickerProvider implements TickerProvider {
  const _PlainTickerProvider(this.id);

  final String id;

  @override
  Ticker createTicker(TickerCallback onTick) =>
      Ticker(onTick, debugLabel: id);
}
