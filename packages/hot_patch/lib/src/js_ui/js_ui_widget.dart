import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/builtin_host_methods.dart';
import '../services/js_runtime_manager.dart';
import '../utils/hot_patch_log.dart';
import '../utils/remote_asset_loader.dart';
import 'capabilities/build_context/build_context_bridge.dart';
import 'capabilities/core/handle_registry.dart';
import 'capabilities/js_ui_capabilities.dart';
import 'capabilities/key/key_bridge.dart';
import 'js_leak_snapshot.dart';
import 'js_ui_store.dart';
import 'js_widget_registry.dart';

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

  /// 实际加载的入口模块（网络补丁解压后为 zip 内虚拟路径）。
  late String _entryJsAsset;

  String? _rootId;
  String? _error;
  bool _loading = true;

  /// 所加载补丁的打包时间（包根 `manifest.json` 的 `buildTime`）；无清单为 null。
  String? _buildTime;

  /// 页面进入前的 JS 泄漏基线快照（仅 debug；dispose 时取第二次做 diff）。
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
    // 泄漏观测基线：进入前取一次（仅 debug），dispose 清理后再取一次做 diff。
    if (kDebugMode) _leakBaseline = JsLeakSnapshot.capture(_pageKey);
    _boot();
  }

  Future<void> _boot() async {
    try {
      // 运行时骨架先就位（`__jsui` + `__modules['js_ui/core']`）。
      _manager.ensureJsUiRuntime();
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
        final bundle = await RemoteAssetLoader.load(realAsset, component: component, entryPath: entryPath);
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
      // 挂载必须用 evaluateOrThrow：JS 侧 `component not found`（典型是 patch.zip
      // 陈旧 / 组件名拼错）时 evaluate 只记日志，root 永不下发 → 页面一直转圈。
      // 抛出来才能落进下面的 catch，进错误兜底视图。
      _manager.evaluateOrThrow(
        '__jsui.mount(${jsonEncode(_pageKey)}, ${jsonEncode(_entryJsAsset)}, '
        '${jsonEncode(component)}, '
        '${jsonEncode(jsonEncode(widget.props))});',
        where: 'mount',
      );
      if (mounted && _loading) setState(() => _loading = false);
    } catch (e) {
      HotPatchLog.log('js_ui boot failed: $e');
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  /// 宿主 → JS 的事件回传（按钮点击等）。
  ///
  /// handler 是运行时登记的句柄 `{'__fn': id}`（生成器在构建期把事件表达式
  /// 绑到产出该结点的组件实例，绑定信息随 props 传下来）→ `invoke`。
  ///
  /// [args] 是**参数数组**：0 参事件 `[]`、onChanged `[v]`、多参事件 `[a,b]`…；
  /// JS 侧句柄（__bind/__bindFn 生成的 wrapper）对它 apply 摊开成位置实参，
  /// 故任意形参个数的事件共用同一条通路。
  void _invoke(Object? handler, [List<Object?> args = const []]) {
    if (handler is! Map) {
      // handler 形态不对 → 静默丢弃，点了没反应。
      return;
    }
    final id = handler['__fn'];
    if (id is! String) {
      // 句柄缺 __fn → 静默丢弃。
      return;
    }
    // args 双重编码：内层把数组变成 JSON 文本，外层再包成 JS 字符串字面量；
    // JS 侧 invoke 对字符串参数做一次 JSON.parse 还原为数组。单层编码会把
    // 字符串 payload 解析失败置 null。
    _manager.evaluate('__jsui.invoke(${jsonEncode(id)}, ${jsonEncode(jsonEncode(args))});');
  }

  @override
  void dispose() {
    _manager.evaluate('if (typeof __jsui !== "undefined") __jsui.dispose(${jsonEncode(_pageKey)});');
    // 页面级兜底：本页登记的跨语言句柄在当前页面销毁时统一释放（正常路径下
    // JS 的 disposeRoot 已逐个通知到本端，此处为空操作；异常路径兜底）。
    releasePageHandles(_pageKey);
    // 注销页面锚点（根组件的 `this.context` 用它反查真值 BuildContext）。
    unregisterJsBuildContext(jsBuildContextPageAnchor(_pageKey));
    // 注销本页 store：jsuiCommit 处理器按 key 查不到即丢弃（页面已销毁）。
    jsUiPageStores.remove(_pageKey);
    // 泄漏观测：清理全部完成后取第二次快照做本页归属判定，残留即打印
    //（含 JS 端对象构造名）。仅 debug 构建启用。
    if (kDebugMode) {
      JsLeakSnapshot.capture(_pageKey)?.reportLeaks(_pageKey, _leakBaseline);
    }
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
      invoke: _invoke,
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
    });
    _boot();
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
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  '页面补丁资源不可用，请确认资源已打包或重新下发。',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
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
          style: const TextStyle(color: Colors.white, fontSize: 10, height: 1.2),
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
    required this.invoke,
    required this.pageKey,
  });

  final JsUiStore store;
  final String id;

  /// 本结点所属页面。BuildContext 锚点登记时一并下发，供 debug 泄漏观测按页
  /// 归属统计（见 capabilities/build_context/build_context_bridge.dart）。
  final String pageKey;

  /// 事件回传：`(handler, args)`——handler 是运行时登记的句柄，args 为参数数组。
  final void Function(Object? handler, [List<Object?> args]) invoke;

  @override
  State<_JsNode> createState() => _JsNodeState();
}

class _JsNodeState extends State<_JsNode> {
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

  /// 懒槽位（props 带 `__lazy` 的占位结点，见 JS 侧 registerLazyChildHost /
  /// lazyMount）：**本结点的 Element 被真正 inflate 时**才回调 JS 去挂载它待挂载
  /// 的真实子树——这就是「initState 由 _JsNode 生命周期驱动」的落点：宿主没
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
      widget.invoke(node.props['__lazyFn'], [widget.id]);
    });
  }

  /// 结点 key 现在可能来自 JS 声明（见 [_JsNodeState._node]）：同一 key 下
  /// 结点 id 变化时（JS 侧重建出新的 host 结点）Flutter 会复用本 State，
  /// 必须把重建回调改绑到新 id，否则 build 里查到的还是旧结点。
  @override
  void didUpdateWidget(covariant _JsNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id || !identical(oldWidget.store, widget.store)) {
      oldWidget.store.unbind(oldWidget.id, _rebuild);
      widget.store.bind(widget.id, _rebuild);
    }
  }

  @override
  void dispose() {
    widget.store.unbind(widget.id, _rebuild);
    // 注销本 element 曾用过的全部结点 id（见 [_anchorIds]：id 变化时必须继续
    // 可查，卸载时一次清干净）。
    for (final id in _anchorIds) {
      unregisterJsBuildContext(id);
    }
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.store.nodes[widget.id];
    if (node == null) return const SizedBox.shrink();

    // JS 组件的 `this.context` 代理按**最近宿主祖先结点 id** 反查真实
    // BuildContext（见 capabilities/build_context/build_context_bridge.dart）：在此登记/
    // 刷新，element 卸载时连同历史 id 一并注销（见 [_anchorIds]）——这就是
    // 「element 级 scope」。
    registerJsBuildContext(widget.id, context, widget.pageKey, type: node.type);
    _anchorIds.add(widget.id);

    final children = <Widget>[];
    final childTypes = <String>[];
    final childContexts = <JsRenderContext>[];
    for (final childId in node.childIds) {
      final childNode = widget.store.nodes[childId];
      final childType = childNode?.type ?? '';
      childTypes.add(childType);
      children.add(_node(childId));
      // 数据载体型子结点（BottomNavigationBarItem / DropdownMenuItem 等
      // 非 Widget 类型）：父 renderer 直接读其 props/propChildren 组装。
      childContexts.add(
        JsRenderContext(
          type: childType,
          props: childNode?.props ?? const {},
          children: const [],
          childTypes: const [],
          childContexts: const [],
          propChildren: {
            for (final e in childNode?.propChildIds.entries ?? const <MapEntry<String, String>>[])
              e.key: _node(e.value),
          },
          invoke: widget.invoke,
        ),
      );
    }

    final propChildren = <String, Widget>{};
    for (final entry in node.propChildIds.entries) {
      propChildren[entry.key] = _node(entry.value);
    }

    // 未注册的类型不再降级成统一的 'Component'：元素 type 就是具体类型名，
    // lookup 未命中走单例注册表的默认 builder（原生注入 / 占位）。
    final builder = jsWidgetRegistry.lookup(node.type) ?? jsWidgetRegistry.fallback;
    if (builder == null) return buildMissingJsWidget(node.type, children);

    return builder(
      JsRenderContext(
        type: node.type,
        props: node.props,
        children: children,
        childTypes: childTypes,
        childContexts: childContexts,
        propChildren: propChildren,
        invoke: widget.invoke,
      ),
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
      invoke: widget.invoke,
      pageKey: widget.pageKey,
    );
  }
}
