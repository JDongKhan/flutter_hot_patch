import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/builtin_host_methods.dart';
import '../services/js_runtime_manager.dart';
import '../utils/hot_patch_log.dart';
import '../utils/remote_asset_loader.dart';
import 'capabilities/build_context/build_context_bridge.dart';
import 'capabilities/core/binding_cache.dart';
import 'capabilities/core/handle_registry.dart';
import 'capabilities/js_ui_capabilities.dart';
import 'capabilities/key/key_bridge.dart';
import 'leak/js_leak_snapshot.dart';
import 'leak/leak_stats.dart';
import 'js_ui_store.dart';
import 'js_widget_registry.dart';
import 'runtime_switch_coordinator.dart';
import 'ui_fallback.dart';

/// JS-UI 页面的宿主入口。
///
/// 职责边界（刻意压到最小）：
///   1. 把 JS 下发的 `type` 映射成真实 Flutter widget（[JsWidgetRegistry]）；
///   2. 应用 JS 算好的增量补丁（[JsUiStore]）。
///
/// **不理解任何状态语义**：setState / provider / 任何状态库的状态与重建都在
/// JS 侧，最终都归约为「JS 重建子树 → 下发 patch → 宿主重建受影响结点」。
/// 宿主只额外做两件事：把 `type` 映射成 widget、把作用域（context）查询落到
/// 真值 BuildContext 上做权威校验/订阅。故宿主代码不随状态库增加而改动。
///
/// 每个实例按 `pageKey` 在全局共享 JS 运行时（[JsRuntimeManager.instance]）里
/// 隔离自己的根（结点树 / 作用域 / 订阅 / 脏队列），同屏多实例互不影响。
///
/// 用法（组件名与入口都通过 URL query 传入，方便运营配置）：
/// ```dart
/// JsUiWidget(jsAsset: 'http://host/patch/patch.zip?component=Counter&entry=components/counter.js')
/// ```
///
/// query 参数：
/// - `component`（必填）：入口模块里注册进 `__modules` 的组件类名
/// - `entry`（可选）：zip 内入口 .js 的相对路径；不指定则按 component 反查
class JsUiWidget extends StatefulWidget {
  const JsUiWidget({
    super.key,
    required this.jsAsset,
    this.props = const {},
    this.showBuildTime = false,
  });

  /// 补丁入口 JS（asset 路径或 http(s):// zip 网络补丁）。
  ///
  /// 网络补丁时可带 query 参数：`?component=Xxx&entry=path/to.js`——
  /// 下载 zip 前会剥离 query，只用 path 部分请求。
  final String jsAsset;

  /// 传给组件构造的 props（如 `MyStatelessCard(title: ...)` 的 {title: ...}）。
  final Map<String, dynamic> props;

  /// 调试开关：在**右上角**显示所加载补丁的打包时间（取自包根 `manifest.json`
  /// 的 `buildTime`，由 build_runner 产出、随 zip 分发）。
  ///
  /// 角标自身 [IgnorePointer] 包裹，只做展示、**不参与命中测试**，不影响任何
  /// 手势/点击；无清单（如本地 asset 场景或旧包）时自动隐藏。
  final bool showBuildTime;

  @override
  State<JsUiWidget> createState() => JsUiWidgetState();
}

class JsUiWidgetState extends State<JsUiWidget> {
  static int _seq = 0;

  late final JsRuntimeManager _manager;

  /// 本页的结点仓库 / 补丁应用器。页面级重载（补丁版本变化）时整体换新。
  late JsUiStore _store;
  final String _pageKey = 'jsui_${_seq++}';

  /// 页面的人类可读名（日志显示用）：入口组件类名，取自 jsAsset 的
  /// `?component=`（如 `HelloCard`）；解析不到时退化为 asset 路径本身。
  /// 只用于打日志，不参与任何路由/隔离（隔离始终按 [_pageKey]）。
  late final String _pageName = () {
    final name = Uri.parse(widget.jsAsset).queryParameters['component'];
    return (name == null || name.isEmpty) ? widget.jsAsset : name;
  }();

  /// 实际加载的入口模块（网络补丁解压后为 zip 内虚拟路径）。
  late String _entryJsAsset;

  String? _rootId;
  String? _error;
  bool _loading = true;

  /// JS 侧根是否已经 mount 成功。props 更新只在 mount 之后下发；
  /// 首次 mount 会读取调用时刻最新的 `widget.props`。
  bool _jsMounted = false;

  /// 所加载补丁的打包时间（包根 `manifest.json` 的 `buildTime`）；无清单为 null。
  String? _buildTime;

  /// 页面进入时的双端缓存基线快照（仅 debug；dispose 时取第二次做一致比对）。
  /// 取在「运行时就绪、模块加载完、组件尚未 mount」这一刻。
  JsLeakSnapshot? _leakBaseline;

  /// 本页 JS root 挂载时所处的运行时代次由
  /// [JsRuntimeSwitchCoordinator] 维护（页面本身不记录）。

  /// 每次 [_boot] 的令牌：页面级重载会自增，旧的在途 boot 完成后据此丢弃结果。
  int _bootToken = 0;

  /// 页面级重载进行中（防止同一页重复进入重载流程）。
  bool _reloading = false;

  /// 初始化本页的 store 并挂根回调（首次进入与页面级重载都走这里）。
  void _initStore() {
    _store = JsUiStore();
    _store.onRoot = (id) {
      _rootId = id;
      if (mounted) setState(() => _loading = false);
    };
  }

  @override
  void initState() {
    super.initState();
    // 运行时是全局单例（所有实例共用一个 JS 引擎），不支持从外部注入。
    _manager = JsRuntimeManager.instance;
    // 宿主 widget 注册表是**进程内单例**（懒建一次性注册全部内建/能力/三方库
    // 组件，见 js_ui_capabilities 的 jsWidgetRegistry）——不需要、也不由外部传入。
    registerBuiltinHostMethods();
    _initStore();
    // 能力桥接通道（ScrollController / TextEditingController …）：必须在任何
    // JS 组件 mount（new XxxController → host 登记）前就位。新增能力只改
    // js_ui_capabilities.ensureJsUiCapabilities，本文件不再变动。
    ensureJsUiCapabilities();
    // jsuiCommit 补丁按页面 key 路由：登记本页 store（key 由 JS 补丁带下来）。
    jsUiPageStores[_pageKey] = _store;
    // 页面名登记（仅日志显示）：让 `[binding] + …` 与 `leak-check …` 里的 jsui_N
    // 显示成组件类名，而不是人类看不懂的 id。
    LeakStats.registerPage(_pageKey, _pageName);
    // 活跃页注册表：版本切换时据此找到所有需要重载的页面（含 Navigator 栈下方
    // 仍 mounted 的离屏路由）。调度与提示逻辑在 runtime_switch_coordinator.dart。
    JsRuntimeSwitchCoordinator.instance.registerPage(
      pageKey: _pageKey,
      contextOf: () => context,
      isMounted: () => mounted,
      reload: (reason) => _reloadFromScratch(reason: reason),
    );
    _boot();
  }

  Future<void> _boot({bool allowBundleSwitch = true}) async {
    final token = ++_bootToken;
    try {
      // 运行时骨架不在这里注入：runtime.js 在补丁包内（需要 localRoot 才知道
      // 从哪读），由 loadModule 在求值任何模块之前自动加载（见下面 loadModule）。
      // 从 jsAsset URL 解析组件名与入口路径（query 参数，方便运营配置）：
      //   ?component=HelloCard&entry=components/hello.js
      // 实际下载 zip 时剥离 query，只用 path 部分。
      final uri = Uri.parse(widget.jsAsset);
      final component = uri.queryParameters['component'];
      final entryPath = uri.queryParameters['entry'];
      if (component == null || component.isEmpty) {
        throw StateError('jsAsset 缺少 ?component=xxx 参数：${widget.jsAsset}');
      }
      // 剥离 query 后的真实资源地址（zip 下载 / asset 加载用）。
      final realAsset = uri.replace(queryParameters: {}).toString();

      // 网络补丁包：http(s):// → 下载 zip 解压到本地根；入口改为包内虚拟路径，
      // 其余（递归 import / 实例化 / 相对路径）与 asset 场景一致。
      var entry = realAsset;
      // localRoot 只由「网络包解压」产生：asset 场景为 null（直接按 asset 读）。
      String? localRoot;
      if (RemoteAssetLoader.isRemote(realAsset)) {
        final bundle = await RemoteAssetLoader.load(
          realAsset,
          component: component,
          entryPath: entryPath,
        );
        if (_bootSuperseded(token)) return;
        if (bundle == null) {
          throw StateError('远程补丁加载失败（需 http(s):// zip）：$realAsset');
        }
        // 包版本记入内存：与内存中已加载的版本不一致 → 清空模块缓存与运行时
        // 标记，下一次 ensureJsUiRuntime 会重新求值 runtime.js，loadModule 会
        // 重新加载全部产物。
        // 自动重载（allowBundleSwitch=false）只允许加载**当前运行时版本**的
        // 产物：不同补丁源的页面无法混在一个运行时里，宁可让该页进错误态，
        // 也不能来回切换造成「A 重载 B / B 重载 A」的无限循环。
        if (!allowBundleSwitch &&
            _manager.loadedBundleVersion != null &&
            bundle.version != _manager.loadedBundleVersion) {
          throw StateError('页面补丁包版本（${bundle.version ?? 'unknown'}）'
              '与当前运行时（${_manager.loadedBundleVersion}）不一致，'
              '无法自动重载；请统一所有 JsUiWidget 的补丁源');
        }
        final switched =
            _manager.syncBundleVersion(bundle.version, fresh: bundle.fresh);
        if (switched) {
          // 通知活跃页协调器：除本页（即将用新版本重新 boot）外，其余已挂载
          // 页面全部 stale，需要页面级重载。
          JsRuntimeSwitchCoordinator.instance
              .onRuntimeSwitched(bootingPageKey: _pageKey);
        }
        // 记录该包的打包时间（调试展示用，见 showBuildTime）。
        _buildTime = bundle.buildTime;
        entry = bundle.entryJsAsset;
        localRoot = bundle.localRoot;
      }
      _entryJsAsset = entry;
      // 运行时就绪 → 内建能力模块（如 patch/packages/provider.js 的作用域声明与
      // context.watch/read 原型补丁）→ 入口模块。顺序是硬约束：能力模块必须在
      // 任何组件 build 之前求值；且必须在 [loadModule] 之外单独加载（能力模块
      // 普遍 import flutter.js，混在模块加载内部会自等 → 死锁）。
      await _manager.ensureJsUiRuntime(
        localRoot: localRoot,
        moduleAsset: _entryJsAsset,
      );
      if (_bootSuperseded(token)) return;
      await _manager.loadCapabilityModules(
        localRoot: localRoot,
        moduleAsset: _entryJsAsset,
      );
      if (_bootSuperseded(token)) return;
      await _manager.loadModule(_entryJsAsset, localRoot: localRoot);
      if (_bootSuperseded(token)) return;
      // 模块加载**汇总成一条**：连带依赖常有几十个（model/xxx.js、flutter.js…），
      // 逐条打印会把进入页面的日志刷满。顺序即加载顺序（依赖先于自身）。
      final loaded = _manager.drainLoadedModules();
      if (loaded.isNotEmpty) {
        HotPatchLog.log('模块加载完成（${loaded.length} 个）：${loaded.join(', ')}');
      }
      // 泄漏观测基线（仅 debug）：运行时就绪、本页模块已加载完（模块级单例已
      // 登记），但组件还没 mount——此刻的双端缓存就是「进入时」的基准；dispose
      // 清理后再取一次做一致性比对（见 js_leak_snapshot.dart）。
      if (kDebugMode && mounted) {
        _leakBaseline = JsLeakSnapshot.capture(_pageKey);
      }
      // 挂载必须用 evaluateOrThrow：JS 侧 `component not found`（典型是 patch.zip
      // 陈旧 / 组件名拼错）时 evaluate 只记日志，root 永不下发 → 页面一直转圈。
      // 抛出来才能落进下面的 catch，进错误兜底视图。
      _manager.evaluateOrThrow(
        '__jsui.mountRoot(${jsonEncode(_pageKey)}, ${jsonEncode(_entryJsAsset)}, '
        '${jsonEncode(component)}, '
        '${jsonEncode(jsonEncode(widget.props))});',
        where: 'mountRoot',
      );
      _jsMounted = true;
      // boot 期间可能又发生了版本切换：以当前代次为准（本页已是新版本）。
      JsRuntimeSwitchCoordinator.instance.markPageBooted(_pageKey);
      if (mounted && _loading) setState(() => _loading = false);
    } catch (e) {
      if (_bootSuperseded(token)) return;
      HotPatchLog.error('js_ui boot failed: $e', error: e);
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    } finally {
      // 只有仍是当前这次 boot 才结束重载标记（被新 boot 覆盖的旧流程不能清）。
      if (token == _bootToken) _reloading = false;
    }
  }

  /// 本次 boot 是否已被页面级重载 / 卸载取代：取代后不再落任何状态。
  bool _bootSuperseded(int token) => !mounted || token != _bootToken;

  @override
  void didUpdateWidget(covariant JsUiWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // jsAsset 变更需要重走加载/挂载流程，当前不做热切换；出声而不是静默忽略。
    if (oldWidget.jsAsset != widget.jsAsset) {
      HotPatchLog.warn(
        'JsUiWidget: jsAsset 变更当前不支持热切换（需重建 widget）：'
        '${oldWidget.jsAsset} -> ${widget.jsAsset}',
      );
      return;
    }
    // 首次 mount 尚未完成时无需下发：mount 会读取此刻最新的 widget.props。
    if (!_jsMounted) return;
    try {
      _manager.evaluate(
        '__jsui.updateProps(${jsonEncode(_pageKey)}, '
        '${jsonEncode(jsonEncode(widget.props))});',
      );
    } catch (e, s) {
      HotPatchLog.error('js_ui updateProps failed: $e',
          error: e, stackTrace: s);
    }
  }

  @override
  void dispose() {
    // 取消仍在途的 boot（异步完成后不再落状态），并从活跃页协调器摘除。
    _bootToken++;
    JsRuntimeSwitchCoordinator.instance.unregisterPage(_pageKey);
    _teardownJsRoot(reportLeaks: true);
    super.dispose();
  }

  /// 释放本页 JS root 及其全部簿记。
  ///
  /// 页面销毁（[dispose]）与页面级重载（[_reloadFromScratch]）共用；后者不比对
  /// 泄漏（基线属于旧的一次生命周期，重载后重新采集）。
  ///
  /// 顺序很关键：
  ///   1) disposeRoot：只走正常卸载（组件逐实例释放自己持有的句柄）；
  ///   2) 宿主自身簿记清理（store / 页面锚点）：这些是 dispose **必定**会摘的
  ///      基础设施，不属于被登记对象的生命周期，先摘掉，避免被当成残留误报；
  ///   3) 快照比对：此时残留的才是真泄漏，可观测；
  ///   4) sweepPage / dropPageEntries：把本页**全部**对象残留静默清干净，作为
  ///      「页面退出即释放」的兜底，因此同一页面挂载多少次都不会累积。
  void _teardownJsRoot({required bool reportLeaks}) {
    final wasMounted = _jsMounted;
    _jsMounted = false;
    _manager.evaluate(
      'if (typeof __jsui !== "undefined") __jsui.dispose(${jsonEncode(_pageKey)});',
    );
    // 注销页面锚点（根组件的 `this.context` 用它反查真值 BuildContext）：属于
    // 页面簿记，dispose 后必然失效，先摘除。
    unregisterJsBuildContext(jsBuildContextPageAnchor(_pageKey));
    // 注销本页 store：jsuiCommit 处理器按 key 查不到即丢弃（页面已销毁）。
    if (identical(jsUiPageStores[_pageKey], _store)) {
      jsUiPageStores.remove(_pageKey);
    }
    if (reportLeaks && kDebugMode && wasMounted) {
      JsLeakSnapshot.capture(_pageKey)?.reportLeaks(_pageKey, _leakBaseline);
    }
    // 页面兜底（拥有端在 JS）：按 pageKey 清掉本页全部句柄——任何 scope，
    // 不只 scope=page。release 幂等，正常已释放的为空操作。
    _manager.evaluate(
      'if (typeof __jsui !== "undefined" && __jsui.sweepPage) '
      '__jsui.sweepPage(${jsonEncode(_pageKey)});',
    );
    // 页面兜底（宿主端）：静默摘除本页登记的全部缓存条目（不发 release 消息，
    // 对象已由 sweepPage 拥有端释放）。
    JsBindingCache.instance.dropPageEntries(_pageKey);
    // 页面级兜底：本页登记、但 JS 侧已不存在的跨语言句柄（如 JS 侧先丢引用）。
    releasePageHandles(_pageKey);
    // 页面名登记随之注销（与 jsUiPageStores 的按页清理同款）——放在 reportLeaks
    // 之后，保证本页最后一条日志仍然显示组件类名；不注销该表会无界增长。
    LeakStats.unregisterPage(_pageKey);
  }

  /// 页面级重载：补丁版本切换 / 首次加载失败重试时，整页重建 JS root 与 store，
  /// **保留 Flutter 路由与 JsUiWidget 本身**（不要求用户退出页面）。
  void _reloadFromScratch({
    String reason = '补丁版本变化',
    bool allowBundleSwitch = false,
  }) {
    if (_reloading) return;
    _reloading = true;
    _bootToken++;
    _teardownJsRoot(reportLeaks: false);
    _rootId = null;
    _error = null;
    _loading = true;
    _buildTime = null;
    _leakBaseline = null;
    _initStore();
    jsUiPageStores[_pageKey] = _store;
    LeakStats.registerPage(_pageKey, _pageName);
    if (!mounted) {
      _reloading = false;
      return;
    }
    setState(() {});
    HotPatchLog.log('页面 $_pageName（$_pageKey）重新加载：$reason');
    _boot(allowBundleSwitch: allowBundleSwitch);
  }

  @override
  Widget build(BuildContext context) {
    // 页面锚点：根组件（COMP 之上没有宿主结点）的 `this.context` 代理按
    // `page:<pageKey>` 反查 —— 见 capabilities/build_context/build_context_js.dart。
    registerJsBuildContext(
      jsBuildContextPageAnchor(_pageKey),
      context,
      _pageKey,
      // 页面锚点不是某个结点，锚在承载 JsUiWidget 的那个 element 上。
      type: 'page',
      owner: 'JsUiWidgetState.build',
    );
    if (_error != null) {
      return _JsLoadErrorView(message: _error!, onRetry: _retry);
    }
    if (_loading || _rootId == null) {
      return Material(
        color: Colors.white,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    // 根结点是唯一的「真实内容」；任何调试叠加层都必须满足两点，否则会顶掉
    // 下方的手势（曾因未包裹的 Stack 顶层全宽 Positioned 让顶部整条区域点不动）：
    //   1. 角标自带 IgnorePointer —— 不参与命中测试；
    //   2. Stack 用 StackFit.passthrough —— 原样透传父约束给内容，不改变既有布局
    //      （loose/expand 都会给内容另一套约束，Column 里会直接改变尺寸）。
    final content = _renderStoreNode(_store, _rootId!, _pageKey);
    final buildTime = _buildTime;
    if (!widget.showBuildTime || buildTime == null) return content;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        content,
        Positioned(
          top: 4,
          right: 4,
          child: _BuildTimeBadge(label: _formatBuildTime(buildTime)),
        ),
      ],
    );
  }

  /// ISO-8601 打包时间 → `YYYY-MM-DD HH:mm:ss`；解析失败原样返回。
  static String _formatBuildTime(String raw) {
    final t = DateTime.tryParse(raw);
    if (t == null) return raw;
    String p(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${p(t.month)}-${p(t.day)} '
        '${p(t.hour)}:${p(t.minute)}:${p(t.second)}';
  }

  /// 失败后整页重来：模块加载按文件幂等，但可能已有半挂载状态，统一切干净再 boot。
  /// 用户主动重试，允许按本页补丁源重新判定版本切换。
  void _retry() => _reloadFromScratch(
        reason: '加载失败后重试',
        allowBundleSwitch: true,
      );
}

/// 弹层内容的宿主入口：把**已经存在的一份独立 [JsUiStore]** 渲染成 widget 树。
///
/// 与 [JsUiWidget] 的区别只在「谁负责挂载 JS 根」：
///   - [JsUiWidget] 自己按 URL 加载补丁并 `mount`；
///   - 本类用于 JS 侧命令式弹层（`showDialog` 系列）：builder 在 JS 端已执行
///     完毕，元素树要在本 widget 首帧之后才挂到 JS 侧独立 root 上（见
///     builders/runtime/js/dialogs_js.dart 的 panelMount）。**首帧之后**是硬约束：
///     `jsuiPanelOpen` 的宿主处理器运行在 JS 求值期内，此刻再回调 JS 会重入引擎。
///
/// 本类不做任何弹层判断：它只认「一份 store + 一个 pageKey」，页面/弹层/任何
/// 别的地方都可以用它渲染独立根。
class JsUiContent extends StatefulWidget {
  const JsUiContent({
    super.key,
    required this.store,
    required this.pageKey,
    this.onMountFailed,
  });

  /// 该根的全部结点与补丁（由调用方创建并登记到 `jsUiPageStores`）。
  final JsUiStore store;

  /// 独立根的 key（= JS 侧 panelKey），补丁按它路由。
  final String pageKey;

  /// 首帧后挂载 JS 根失败时的回调（弹层的宿主用它关闭这条已经打开的路由，
  /// 避免留下一个空白弹层）。
  final VoidCallback? onMountFailed;

  @override
  State<JsUiContent> createState() => _JsUiContentState();
}

class _JsUiContentState extends State<JsUiContent> {
  bool _mountRequested = false;

  @override
  void initState() {
    super.initState();
    // root op 可能在本 widget 之前就已到达（store 先收补丁、后建 widget）：
    // 两条路径都只触发一次 setState。
    widget.store.onRoot = (id) {
      if (mounted) setState(() {});
    };
    WidgetsBinding.instance.addPostFrameCallback((_) => _mountJsRoot());
  }

  void _mountJsRoot() {
    if (!mounted || _mountRequested) return;
    _mountRequested = true;
    try {
      JsRuntimeManager.instance.evaluateOrThrow(
        'if (typeof __jsui !== "undefined" && __jsui.panelMount) '
        '__jsui.panelMount(${jsonEncode(widget.pageKey)});',
        where: 'panelMount',
      );
    } catch (e) {
      HotPatchLog.error('js_ui panel mount failed: $e', error: e);
      widget.onMountFailed?.call();
    }
  }

  @override
  void dispose() {
    // 页面锚点与本页 store 都是「content 存在即有效」的簿记：先摘除，避免
    // 路由已关闭后仍有补丁被路由进来（关闭回调里的同款清理是幂等的）。
    unregisterJsBuildContext(jsBuildContextPageAnchor(widget.pageKey));
    if (identical(jsUiPageStores[widget.pageKey], widget.store)) {
      jsUiPageStores.remove(widget.pageKey);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 与 JsUiWidget 同一条锚点规则：根组件（COMP 之上没有宿主结点）的
    // `this.context` 代理按 `page:<pageKey>` 反查真值 BuildContext。
    registerJsBuildContext(
      jsBuildContextPageAnchor(widget.pageKey),
      context,
      widget.pageKey,
      type: 'page',
      owner: '_JsUiContentState.build',
    );
    final rootId = widget.store.rootId;
    if (rootId == null) {
      // 根补丁尚未到达（JS 侧还没 post-frame 挂载）：先占零尺寸，等 onRoot
      // 触发的重建再换成真实内容。这是**正常时序**（首帧必经），不是兜底，
      // 故不走 uiFallback（挂载真失败时由面板/页面的 onMountFailed 上报）。
      return const SizedBox.shrink();
    }
    return _renderStoreNode(widget.store, rootId, widget.pageKey);
  }
}

/// JS 补丁加载失败的兜底视图。
///
/// 自带 [Material]（不依赖祖先提供 Material/DefaultTextStyle——缺省时会退化成
/// 无主题的默认文字样式，落得又大又糙），按当前主题排版：图标 + 标题 + 说明 +
/// 错误详情（单独成块、等宽小字、整体可滚动），而不是把整段错误串直接铺满屏幕。
class _JsLoadErrorView extends StatelessWidget {
  const _JsLoadErrorView({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.cloud_off_rounded, size: 56, color: scheme.error),
                const SizedBox(height: 16),
                Text(
                  'JS 组件加载失败',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '页面补丁资源不可用，请确认资源已打包或重新下发。',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                      height: 1.5,
                    ),
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.center,
                    child: FilledButton.tonalIcon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('重新加载'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 右上角「补丁打包时间」角标（纯调试展示）。
///
/// 自带 [IgnorePointer]：叠加层只做展示、绝不参与命中测试——否则会吃掉下方
/// 真实内容的手势（历史上出现过顶部整条区域点不动）。尺寸只随文字内容收缩，
/// 不做任何拉伸，进一步压缩干扰面。
class _BuildTimeBadge extends StatelessWidget {
  const _BuildTimeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

/// 按结点 id 渲染一个 widget。
///
/// 三类结点走三条路径：
///   - **组件结点**（JS 的 COMP，类上重写了 `build`）→ [_JsComponentHost]：宿主的
///     挂载边界，build 里先登记 BuildContext 锚点、再同步拉取 JS build 结果；
///   - **懒槽位 / 未注册类型** → [_JsPlainNodeHost]：需要 element 生命周期（懒挂载/
///     卸载、KeepAlive）或需要独立重建回调与兜底告警；
///   - **已注册的宿主类型** → 直接建真实 widget，**不再包一层 [_JsPlainNodeHost]**。
///     它的重建由最近的组件 wrapper 驱动（父级重建 → 子树 widget 重建，
///     Flutter 复用 element / State），与原生 Flutter 的更新模型同构。
Widget _renderStoreNode(JsUiStore store, String id, String pageKey) {
  final node = store.nodes[id];
  if (node == null) {
    return uiFallback('结点 "$id" 不在 store.nodes 中（页面 $pageKey）');
  }
  final declared = jsKeyOf(node.props['key']);
  if (node.hasBuild) {
    return _JsComponentHost(
      key: declared ?? ValueKey(id),
      store: store,
      id: id,
      pageKey: pageKey,
    );
  }
  final builder = jsWidgetRegistry.lookup(node.type);
  if (node.props['__lazy'] == true || builder == null) {
    return _JsPlainNodeHost(
      key: declared ?? ValueKey(id),
      store: store,
      id: id,
      pageKey: pageKey,
    );
  }
  final widget = builder(_renderContextOf(store, node, pageKey));
  // 未声明 key 时交给 Flutter 的默认语义（按位置 + 类型复用 element），与原生
  // 一致；声明了 key 才套一层 KeyedSubtree（保证列表重排时 element 跟着 key 走）。
  return declared == null ? widget : KeyedSubtree(key: declared, child: widget);
}

/// 结点 → renderer 的输入：props + 按 Dart 实参原名索引的 slot
/// （子 widget / 数据载体 / delegate）。
JsRenderContext _renderContextOf(
  JsUiStore store,
  JsUiNode node,
  String pageKey,
) {
  final children = <String, Object?>{};
  // builder 展开结果（内部键 __items）：有序 widget 列表。
  if (node.childIds.isNotEmpty) {
    children['__items'] = [
      for (final id in node.childIds) _renderStoreNode(store, id, pageKey),
    ];
  }
  // 单值 widget slot：按 Dart 实参原名索引。
  for (final entry in node.propChildIds.entries) {
    children[entry.key] = _renderStoreNode(store, entry.value, pageKey);
  }
  // 数组 widget slot。
  // 同一 key 同时存在单值与列表条目时（prop 形态从列表切到单值时，JS 侧会先下发
  // propsChild、再清空旧列表）以单值为准，避免空列表把刚绑定的 widget 覆盖掉。
  for (final entry in node.propChildLists.entries) {
    if (node.propChildIds.containsKey(entry.key)) continue;
    children[entry.key] = [
      for (final id in entry.value) _renderStoreNode(store, id, pageKey),
    ];
  }
  // delegate 等非 Widget slot 描述。
  for (final entry in node.propData.entries) {
    children[entry.key] = entry.value;
  }
  return JsRenderContext(type: node.type, props: node.props, children: children);
}

/// 两类宿主共用的「结点绑定」基类。
///
/// 宿主侧把一个 store 结点 id 变成 widget 只有两种形态（见下），公共部分是
/// 同一件事：**把结点 id 与本地重建回调绑到 store**，并在 id / store 变化时改绑、
/// 卸载时解绑。差异通过两个钩子交给子类，避免两处各维护一份生命周期胶水：
///   - [_JsComponentHost]：JS 侧有 `build` 的组件结点（宿主 build 驱动 JS build）；
///   - [_JsPlainNodeHost]：普通结点（懒槽位 / 未注册类型，直接按注册表渲染）。
abstract class _JsHostBase extends StatefulWidget {
  const _JsHostBase({
    super.key,
    required this.store,
    required this.id,
    required this.pageKey,
  });

  final JsUiStore store;

  /// 本宿主承载的 store 结点 id。
  final String id;

  /// 本结点所属页面（日志与泄漏观测归属用）。
  final String pageKey;
}

abstract class _JsHostBaseState<T extends _JsHostBase> extends State<T> {
  /// 本 element 已进入 / 进入 dispose：JS 侧回调仍可能重建本结点，需拦住。
  bool _hostDisposed = false;

  @override
  void initState() {
    super.initState();
    widget.store.bind(widget.id, _rebuildHost);
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id ||
        !identical(oldWidget.store, widget.store)) {
      oldWidget.store.unbind(oldWidget.id, _rebuildHost);
      widget.store.bind(widget.id, _rebuildHost);
      onRebound();
    }
  }

  @override
  void dispose() {
    _hostDisposed = true;
    widget.store.unbind(widget.id, _rebuildHost);
    // 子类收尾（注销 BuildContext 锚点 / 通知 JS 卸载懒子树）必须在解绑之后、
    // super.dispose() 之前执行。
    onHostDispose();
    super.dispose();
  }

  /// 结点 id / store 改绑后调用：子类清掉「只对旧结点有效」的缓存。
  void onRebound() {}

  /// 子树卸载前的额外清理。
  void onHostDispose() {}

  void _rebuildHost() {
    if (_hostDisposed || !mounted) return;
    setState(() {});
  }
}

/// **JS 组件结点**（有 `build` 的那类）的宿主 wrapper ——「Flutter build 驱动
/// JS build」的落点。
///
/// 生命周期：Flutter 为该组件结点建立 element 时（本 wrapper 的 build），
///   1. 先登记 `组件结点 id → 真实 BuildContext` 的锚点；
///   2. 首次 build 同步调用 `__jsui.pull(pageKey, id)`，把 JS 侧 build 产生的
///      补丁就地落到 store（不触发其它 wrapper 的 setState）；
///   3. 按 store 里该组件的 `child` 槽渲染它的渲染根。
///
/// 由此 `MediaQuery.of(context)` / `context.watch` 这类「按位置取值」的能力在
/// 首次 build 时锚点必然存在，不再出现「先 build 后挂载」导致的取不到值。
class _JsComponentHost extends _JsHostBase {
  const _JsComponentHost({
    super.key,
    required super.store,
    required super.id,
    required super.pageKey,
  });

  @override
  State<_JsComponentHost> createState() => _JsComponentHostState();
}

class _JsComponentHostState extends _JsHostBaseState<_JsComponentHost> {
  /// 首次 build 是否已拉取过 JS build 结果（pull 只做一次；后续重建走 patch）。
  bool _pulled = false;

  /// 首次 build 失败的原因（非 null 时渲染明确的错误视图，不静默降级）。
  String? _error;

  @override
  void onRebound() {
    _pulled = false;
    _error = null;
  }

  @override
  void onHostDispose() {
    unregisterJsBuildContext(widget.id);
  }

  /// 同步拉取该组件的首次 build 结果并落到 store。
  void _pullOnce() {
    if (_pulled) return;
    _pulled = true;
    final result = JsRuntimeManager.instance.evaluate(
      'JSON.stringify(__jsui.pull(${jsonEncode(widget.pageKey)}, '
      '${jsonEncode(widget.id)}))',
    );
    if (result.isError) {
      _error = 'JS pull 失败：${result.stringResult}';
      HotPatchLog.error('js_ui component pull failed: ${result.stringResult}');
      return;
    }
    final text = result.stringResult;
    if (text.isEmpty || text == 'undefined' || text == 'null') {
      _error = 'JS 侧未返回补丁（组件 "${widget.id}"）';
      HotPatchLog.error('js_ui component pull returned empty: ${widget.id}');
      return;
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } catch (e) {
      _error = '补丁不是合法 JSON: $text';
      HotPatchLog.error('js_ui component pull decode failed: $e');
      return;
    }
    if (decoded is Map && decoded['error'] != null) {
      // JS 侧已记录详细日志，这里只把原因呈现到界面上。
      _error = '${decoded['error']}';
      return;
    }
    if (decoded is! List) {
      _error = '补丁形态非法: $text';
      HotPatchLog.error('js_ui component pull payload invalid: $text');
      return;
    }
    // pull 发生在 build 期间：只落数据，不触发任何 wrapper 的 setState
    // （build 期标脏会触发框架断言），渲染由本次 build 直接按新数据产出。
    widget.store.apply(decoded, notify: false);
  }

  @override
  Widget build(BuildContext context) {
    // 锚点**必须先于** JS build 登记：JS 侧 build 里的 MediaQuery / provider 查询
    // 靠它反查该组件位置的真实 BuildContext。
    registerJsBuildContext(
      widget.id,
      context,
      widget.pageKey,
      type: 'component',
      owner: '_JsComponentHostState.build',
    );
    _pullOnce();
    final error = _error;
    if (error != null) {
      return uiFallback('组件构建失败（${widget.id}）：$error');
    }
    final childId = widget.store.nodes[widget.id]?.propChildIds['child'];
    if (childId == null) {
      return uiFallback('组件 "${widget.id}" 尚未产出渲染根');
    }
    return _renderStoreNode(widget.store, childId, widget.pageKey);
  }
}

/// **普通结点**（JS 侧没有 build 可拉）的宿主 wrapper：懒槽位 / 未注册类型。
///
/// 与 [_JsComponentHost] 的唯一区别是「不拉 JS build」：直接按 `type` 查注册表
/// 建真实 Flutter widget。之所以还需要一个 element，是因为懒槽位要在 Flutter
/// 的 element 生命周期上挂两件事：inflate → 通知 JS 挂载真实子树；dispose →
/// 通知 JS 卸载；另外 `__keepAlive` 的保活注册也在这里。
class _JsPlainNodeHost extends _JsHostBase {
  const _JsPlainNodeHost({
    super.key,
    required super.store,
    required super.id,
    required super.pageKey,
  });

  @override
  State<_JsPlainNodeHost> createState() => _JsPlainNodeHostState();
}

class _JsPlainNodeHostState extends _JsHostBaseState<_JsPlainNodeHost>
    with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    super.initState();
    _mountIfLazy();
  }

  /// 懒槽位（props 带 `__lazy` 的占位结点，见 JS 侧 lazyMount）：**本结点的
  /// Element 被真正 inflate 时**才回调 JS 去挂载它待挂载的真实子树——这就是
  /// 「initState 由 element 生命周期驱动」的落点：宿主没 inflate 到的槽位
  /// （TabBarView 离屏子页），JS 侧永远不挂载、initState 不跑。
  ///
  /// - post-frame 触发：回调会经 commit 回来 setState 重建本结点，不能在 build 期做；
  /// - 通道复用事件回传（`__lazyFn` 是 JS 侧登记的句柄 id，args = [本结点 id]）。
  void _mountIfLazy() {
    final node = widget.store.nodes[widget.id];
    if (node == null || node.props['__lazy'] != true) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      invokeJsHandler(node.props['__lazyFn'], [widget.id]);
    });
  }

  /// 懒槽位的对称生命周期：宿主 element 销毁（ListView 回收离屏项、TabBarView
  /// 换页、整页退出）时通知 JS 卸载已挂载子树。
  ///
  /// **必须延后到帧末再通知 JS**：本方法在 element dispose 链路里被调用，而
  /// dispose 发生在 `BuildOwner.finalizeTree` 的 `lockState` 作用域内（框架锁定）。
  /// JS 的 `lazyUnmount` 会同步 commit 补丁回来，收到补丁后 setState 重建
  /// **仍存活的父结点**会触发 `setState() or markNeedsBuild() called when widget
  /// tree was locked`。post-frame 回调在本帧 drawFrame/finalizeTree 之后执行。
  void _unmountIfLazy() {
    final node = widget.store.nodes[widget.id];
    if (node == null || node.props['__lazy'] != true) return;
    final lazyOffFn = node.props['__lazyOffFn'];
    final nodeId = widget.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        invokeJsHandler(lazyOffFn, [nodeId]);
      } catch (e, s) {
        HotPatchLog.error('js_ui lazy unmount failed: $e',
            error: e, stackTrace: s);
      }
    });
  }

  @override
  void onHostDispose() {
    _unmountIfLazy();
  }

  /// 懒槽位子树声明的「保持存活」来自 JS（`props.__keepAlive`，见 mini-react
  /// 的 subtreeWantsKeepAlive）：true 时向最近的 AutomaticKeepAlive 祖先注册
  /// 保活，TabBarView / PageView 切走的子页 element 不再销毁 → 不会回调
  /// lazyUnmount，JS 侧 State（已加载数据）原样保留。
  @override
  bool get wantKeepAlive =>
      widget.store.nodes[widget.id]?.props['__keepAlive'] == true;

  @override
  Widget build(BuildContext context) {
    // 声明可能随 JS patch 变化：每次 build 同步一次（true 注册 / false 释放）。
    updateKeepAlive();
    // AutomaticKeepAliveClientMixin 的契约：build 必须调用 super.build（返回值忽略）。
    super.build(context);
    final node = widget.store.nodes[widget.id];
    if (node == null) {
      return uiFallback(
        '结点 "${widget.id}" 不在 store.nodes 中（页面 ${widget.pageKey}）',
      );
    }
    final ctx = _renderContextOf(widget.store, node, widget.pageKey);
    // 未注册的类型不再降级成统一的 'Component'：元素 type 就是具体类型名，
    // lookup 未命中走单例注册表的默认 builder（原生注入 / 占位）。
    final builder =
        jsWidgetRegistry.lookup(node.type) ?? jsWidgetRegistry.fallback;
    if (builder == null) {
      _logUnknownType(node);
      final items =
          (ctx.children['__items'] as List<Widget>?) ?? const <Widget>[];
      return buildMissingJsWidget(node.type, items);
    }
    if (jsWidgetRegistry.lookup(node.type) == null) {
      _logUnknownType(node);
    }
    return builder(ctx);
  }

  /// 未注册类型的一次性诊断：结点 id / 页面 / type / props 摘要。
  /// 只报第一次，避免逐帧刷屏；包含定位信息（否则只看到类型名无从排查）。
  void _logUnknownType(JsUiNode node) {
    final key = '${widget.pageKey}|${widget.id}|${node.type}';
    if (!_unknownLogged.add(key)) return;
    if (_unknownLogged.length > 512) _unknownLogged.clear();
    final keys = node.props.keys.take(12).join(',');
    final preview = _previewValue(node.props['data'] ?? node.props['text']);
    HotPatchLog.error(
      'js_ui: 未注册的结点类型 "${node.type}"'
      '（page=${widget.pageKey}, node=${widget.id}, props=[$keys]'
      '${preview == null ? '' : ', data=$preview'}）',
    );
  }

  static String? _previewValue(Object? v) {
    if (v == null) return null;
    final s = '$v';
    return s.length <= 40 ? s : '${s.substring(0, 40)}…';
  }
}

/// 未注册类型已告警过的结点（page|id|type）。
final Set<String> _unknownLogged = <String>{};
