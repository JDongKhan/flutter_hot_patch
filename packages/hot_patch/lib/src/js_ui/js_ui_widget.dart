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
  final JsUiStore _store = JsUiStore();
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

  @override
  void initState() {
    super.initState();
    // 运行时是全局单例（所有实例共用一个 JS 引擎），不支持从外部注入。
    _manager = JsRuntimeManager.instance;
    // 宿主 widget 注册表是**进程内单例**（懒建一次性注册全部内建/能力/三方库
    // 组件，见 js_ui_capabilities 的 jsWidgetRegistry）——不需要、也不由外部传入。
    registerBuiltinHostMethods();
    _store.onRoot = (id) {
      _rootId = id;
      if (mounted) setState(() => _loading = false);
    };
    // 能力桥接通道（ScrollController / TextEditingController …）：必须在任何
    // JS 组件 mount（new XxxController → host 登记）前就位。新增能力只改
    // js_ui_capabilities.ensureJsUiCapabilities，本文件不再变动。
    ensureJsUiCapabilities();
    // jsuiCommit 补丁按页面 key 路由：登记本页 store（key 由 JS 补丁带下来）。
    jsUiPageStores[_pageKey] = _store;
    // 页面名登记（仅日志显示）：让 `[binding] + …` 与 `leak-check …` 里的 jsui_N
    // 显示成组件类名，而不是人类看不懂的 id。
    LeakStats.registerPage(_pageKey, _pageName);
    _boot();
  }

  Future<void> _boot() async {
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
        if (bundle == null) {
          throw StateError('远程补丁加载失败（需 http(s):// zip）：$realAsset');
        }
        // zip 有更新（fresh）→ 清除模块缓存，强制重新 evaluate 最新产物。
        if (bundle.fresh) {
          _manager.invalidateModules();
        }
        // 记录该包的打包时间（调试展示用，见 showBuildTime）。
        _buildTime = bundle.buildTime;
        entry = bundle.entryJsAsset;
        localRoot = bundle.localRoot;
      }
      _entryJsAsset = entry;
      await _manager.loadModule(_entryJsAsset, localRoot: localRoot);
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
        '__jsui.mount(${jsonEncode(_pageKey)}, ${jsonEncode(_entryJsAsset)}, '
        '${jsonEncode(component)}, '
        '${jsonEncode(jsonEncode(widget.props))});',
        where: 'mount',
      );
      _jsMounted = true;
      if (mounted && _loading) setState(() => _loading = false);
    } catch (e) {
      HotPatchLog.error('js_ui boot failed: $e', error: e);
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

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
    // 记录进入过页面：只有 mount 成功过才有「进入 / 销毁」两端可比对。
    final wasMounted = _jsMounted;
    _jsMounted = false;
    // 顺序很关键：
    //   1) disposeRoot：只走正常卸载（组件逐实例释放自己持有的句柄）；
    //   2) 宿主自身簿记清理（store / 页面锚点）：这些是 dispose **必定**会摘的
    //      基础设施，不属于被登记对象的生命周期，先摘掉，避免被当成残留误报；
    //   3) 快照比对：此时残留的才是真泄漏，可观测；
    //   4) sweepPage / dropPageEntries：把本页**全部**对象残留静默清干净，作为
    //      「页面退出即释放」的兜底，因此同一页面挂载多少次都不会累积。
    _manager.evaluate(
      'if (typeof __jsui !== "undefined") __jsui.dispose(${jsonEncode(_pageKey)});',
    );
    // 注销页面锚点（根组件的 `this.context` 用它反查真值 BuildContext）：属于
    // 页面簿记，dispose 后必然失效，先摘除。
    unregisterJsBuildContext(jsBuildContextPageAnchor(_pageKey));
    // 注销本页 store：jsuiCommit 处理器按 key 查不到即丢弃（页面已销毁）。
    jsUiPageStores.remove(_pageKey);
    if (kDebugMode && wasMounted) {
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
    super.dispose();
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
    final content = _JsNode(
      store: _store,
      id: _rootId!,
      pageKey: _pageKey,
    );
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

  /// 失败后重走一遍加载：模块加载按文件幂等，重复调用无副作用。
  void _retry() {
    setState(() {
      _error = null;
      _loading = true;
      _rootId = null;
      _jsMounted = false;
    });
    _boot();
  }
}

/// 弹层内容的宿主入口：把**已经存在的一份独立 [JsUiStore]** 渲染成 widget 树。
///
/// 与 [JsUiWidget] 的区别只在「谁负责挂载 JS 根」：
///   - [JsUiWidget] 自己按 URL 加载补丁并 `mount`；
///   - 本类用于 JS 侧命令式弹层（`showDialog` 系列）：builder 在 JS 端已执行
///     完毕，元素树要在本 widget 首帧之后才挂到 JS 侧独立 root 上（见
///     builders/runtime/js/portal_js.dart 的 panelMount）。**首帧之后**是硬约束：
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
    return _JsNode(store: widget.store, id: rootId, pageKey: widget.pageKey);
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

/// 宿主树里的一个 JS 结点。
///
/// 只做一件事：按 `id` 从 [JsUiStore] 取结点 → 查注册表得到真实 Flutter
/// widget → 递归拼子结点 + prop 子结点。结点被 patch 触碰时由 store 回调
/// 触发重建；未被触碰的结点（相同 id + 相同 key）由 Flutter 复用，状态不丢。
class _JsNode extends StatefulWidget {
  const _JsNode({
    super.key,
    required this.store,
    required this.id,
    required this.pageKey,
  });

  final JsUiStore store;
  final String id;

  /// 本结点所属页面。BuildContext 锚点登记时一并下发，供 debug 泄漏观测按页
  /// 归属统计（见 capabilities/build_context/build_context_bridge.dart）。
  final String pageKey;

  @override
  State<_JsNode> createState() => _JsNodeState();
}

class _JsNodeState extends State<_JsNode> with AutomaticKeepAliveClientMixin {
  /// 本 State 曾登记过 BuildContext 锚点的全部结点 id。
  ///
  /// 同一 key 下 JS 侧重建 host 结点时结点 id 会变、Flutter 复用本 State（见
  /// [didUpdateWidget]），而 JS 侧组件的 `this.context` 代理**缓存了它建立时的
  /// 那个 id**（见 build_context_js.dart 的 buildContextOf）——旧 id 必须继续能
  /// 查到同一个 element，否则那些组件的 watch/read 会查不到真值而静默失效。
  /// 故注销不能在 id 变化时做，只能在 element 真正卸载（dispose）时按这段历史
  /// 一次性做：既不误伤活代理，也不留下永久的簿记残留（残留会被泄漏探针当泄漏报）。
  final Set<String> _anchorIds = <String>{};

  @override
  void initState() {
    super.initState();
    widget.store.bind(widget.id, _rebuild);
    _mountIfLazy();
  }

  /// 懒槽位（props 带 `__lazy` 的占位结点，见 JS 侧 lazyMount）：**本结点的
  /// Element 被真正 inflate 时**才回调 JS 去挂载它待挂载的真实子树——这就是
  /// 「initState 由 _JsNode 生命周期驱动」的落点：宿主没
  /// inflate 到的槽位（TabBarView 离屏子页），JS 侧永远不挂载、initState 不跑。
  ///
  /// - post-frame 触发：回调会经 commit 回来 setState 重建本结点，不能在 build 期做；
  /// - 通道复用事件回传（`__lazyFn` 是 JS 侧登记的句柄 id，args = [本结点 id]），
  ///   不新增任何桥接面。
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
  /// 为什么必须有：JS 侧懒槽位只在宿主 **inflate** 时挂载，若销毁不回收，滚过
  /// 的 item 会永远留在 JS 树里——每次父级重建都要 patch 全量 item（didUpdateWidget
  /// 刷屏、列表越长越重）。与 Flutter 一致：离屏项 State 销毁，滚回来再 initState。
  ///
  /// **必须延后到帧末再通知 JS**：本方法在 element dispose 链路里被调用，而
  /// dispose 发生在 `BuildOwner.finalizeTree` 的 `lockState` 作用域内（框架锁定）。
  /// JS 的 `lazyUnmount` 会同步 commit 补丁回来，`_JsNode` 收到补丁后 setState
  /// 重建**仍存活的父结点**（如 TabBarView 的容器），在锁定期调用必然触发
  /// `setState() or markNeedsBuild() called when widget tree was locked`。
  /// post-frame 回调在本帧 drawFrame/finalizeTree 之后执行，锁已解除。
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

  /// 结点 key 现在可能来自 JS 声明（见 [_JsNodeState._node]）：同一 key 下
  /// 结点 id 变化时（JS 侧重建出新的 host 结点）Flutter 会复用本 State，
  /// 必须把重建回调改绑到新 id，否则 build 里查到的还是旧结点。
  @override
  void didUpdateWidget(covariant _JsNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id ||
        !identical(oldWidget.store, widget.store)) {
      oldWidget.store.unbind(oldWidget.id, _rebuild);
      widget.store.bind(widget.id, _rebuild);
    }
  }

  @override
  void dispose() {
    // 先置位：dispose 期间 JS 侧回调仍可能重建本结点（emit props /
    // propsChild 等），此时 element 已 defunct，setState 会触发框架断言。
    _disposed = true;
    widget.store.unbind(widget.id, _rebuild);
    // 注销本 element 曾用过的全部结点 id（见 [_anchorIds]：id 变化时必须继续
    // 可查，卸载时一次清干净）。
    for (final id in _anchorIds) {
      unregisterJsBuildContext(id);
    }
    _unmountIfLazy();
    super.dispose();
  }

  bool _disposed = false;

  void _rebuild() {
    if (_disposed || !mounted) return;
    setState(() {});
  }

  /// 懒槽位子树声明的「保持存活」来自 JS（`props.__keepAlive`，见 mini-react
  /// 的 subtreeWantsKeepAlive）：true 时向最近的 AutomaticKeepAlive 祖先注册
  /// 保活，TabBarView / PageView 切走的子页 element 不再销毁 → 不会回调
  /// lazyUnmount，JS 侧 State（已加载数据）原样保留。语义与 Flutter 的
  /// AutomaticKeepAliveClientMixin 一致。
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

    // JS 组件的 `this.context` 代理按**最近宿主祖先结点 id** 反查真实
    // BuildContext（见 capabilities/build_context/build_context_bridge.dart）：在此登记/
    // 刷新，element 卸载时连同历史 id 一并注销（见 [_anchorIds]）——这就是
    // 「element 级 scope」。
    registerJsBuildContext(widget.id, context, widget.pageKey, type: node.type);
    _anchorIds.add(widget.id);

    final children = <String, Object?>{};
    // builder 展开结果（内部键 __items）：有序 widget 列表。
    if (node.childIds.isNotEmpty) {
      children['__items'] = [for (final id in node.childIds) _node(id)];
    }
    // 单值 widget slot：按 Dart 实参原名索引。
    for (final entry in node.propChildIds.entries) {
      final childType = widget.store.nodes[entry.value]?.type ?? '';
      children[entry.key] = isJsDataCarrierType(childType)
          ? _dataContext(entry.value)
          : _node(entry.value);
    }
    // 数组 widget slot；数据载体数组给数据上下文，不构建 Widget。
    // 同一 key 同时存在单值与列表条目时（prop 形态从列表切到单值时，JS 侧会先
    // 下发 propsChild、再清空旧列表）以单值为准，避免空列表把刚绑定的 widget 覆盖掉。
    for (final entry in node.propChildLists.entries) {
      if (node.propChildIds.containsKey(entry.key)) continue;
      final ids = entry.value;
      final isData = ids.any(
        (id) => isJsDataCarrierType(widget.store.nodes[id]?.type ?? ''),
      );
      children[entry.key] = isData
          ? [for (final id in ids) _dataContext(id)]
          : [for (final id in ids) _node(id)];
    }
    // delegate 等非 Widget slot 描述。
    for (final entry in node.propData.entries) {
      children[entry.key] = entry.value;
    }


    // 未注册的类型不再降级成统一的 'Component'：元素 type 就是具体类型名，
    // lookup 未命中走单例注册表的默认 builder（原生注入 / 占位）。
    final builder =
        jsWidgetRegistry.lookup(node.type) ?? jsWidgetRegistry.fallback;
    final items = (children['__items'] as List<Widget>?) ?? const <Widget>[];
    if (builder == null) return buildMissingJsWidget(node.type, items);

    return builder(
      JsRenderContext(
        type: node.type,
        props: node.props,
        children: children,
      ),
    );
  }

  /// 子结点数据上下文：只含 type/props/children，不构建 Widget。
  /// 供数据载体（items 等）由父 renderer 直接读数据组装。
  JsRenderContext _dataContext(String id) {
    final n = widget.store.nodes[id];
    final children = <String, Object?>{};
    for (final entry in n?.propChildIds.entries ??
        const <MapEntry<String, String>>[]) {
      children[entry.key] = _node(entry.value);
    }
    for (final entry in n?.propChildLists.entries ??
        const <MapEntry<String, List<String>>>[]) {
      children[entry.key] = [for (final c in entry.value) _node(c)];
    }
    for (final entry in n?.propData.entries ?? const <MapEntry<String, dynamic>>[]) {
      children[entry.key] = entry.value;
    }
    return JsRenderContext(
      type: n?.type ?? '',
      props: n?.props ?? const {},
      children: children,
    );
  }

  Widget _node(String id) {
    final node = widget.store.nodes[id];
    // key：JS 侧声明的 key（ValueKey/ObjectKey/GlobalKey/UniqueKey → 真实 Flutter
    // Key，见 capabilities/key/key_bridge.dart）优先；未声明时退回 `ValueKey(结点 id)`
    // ——保证每个结点都有稳定 key，Flutter 才能复用 element（状态不丢）。
    final declared = jsKeyOf(node?.props['key']);
    return _JsNode(
      key: declared ?? ValueKey(id),
      store: widget.store,
      id: id,
      pageKey: widget.pageKey,
    );
  }
}
