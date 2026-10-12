import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/builtin_host_methods.dart';
import '../services/js_runtime_manager.dart';
import '../utils/hot_patch_log.dart';
import '../utils/remote_asset_loader.dart';
import 'capabilities/js_ui_capabilities.dart';
import 'js_ui_store.dart';
import 'js_widget_registry.dart';

/// JS-UI 页面的宿主入口。
///
/// 职责边界（刻意压到最小）：
///   1. 把 JS 下发的 `type` 映射成真实 Flutter widget（[JsWidgetRegistry]）；
///   2. 应用 JS 算好的增量补丁（[JsUiStore]）。
///
/// **不理解任何状态语义**：provider / setState / 任何状态库都在 JS 侧，
/// 最终都归约为「JS 重建子树 → 下发 patch → 宿主重建受影响结点」。
/// 因此宿主代码不随状态库增加而改动。
///
/// 每个实例按 `pageKey` 在共享 JS 运行时里隔离自己的根（结点树 / provider /
/// 订阅 / 脏队列），同屏多实例、多 runtime 分组都互不影响。
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
    this.nativeComponents = const {},
    this.sharedManager,
    this.localRoot,
    this.registry,
  });

  /// 补丁入口 JS（asset 路径或 http(s):// zip 网络补丁）。
  ///
  /// 网络补丁时可带 query 参数：`?component=Xxx&entry=path/to.js`——
  /// 下载 zip 前会剥离 query，只用 path 部分请求。
  final String jsAsset;

  /// 传给组件构造的 props（如 `MyStatelessCard(title: ...)` 的 {title: ...}）。
  final Map<String, dynamic> props;

  /// 无 JS 产物的组件（Component 节点）的原生注入：组件名 → 构造。
  /// 运行时（hot_patch 包）不 import 业务类，由业务方注册。
  final Map<String, Widget Function(Map<String, dynamic> args)> nativeComponents;

  /// 共享运行时；多组件共用一个引擎时传入。
  final JsRuntimeManager? sharedManager;

  /// 嵌套组件透传的本地补丁根目录（网络补丁解压后的本地根）。
  final String? localRoot;

  /// 宿主 widget 翻译注册表；null 用内置集合。
  final JsWidgetRegistry? registry;

  @override
  State<JsUiWidget> createState() => JsUiWidgetState();
}

class JsUiWidgetState extends State<JsUiWidget> {
  static int _seq = 0;

  late final JsRuntimeManager _manager;
  late final JsWidgetRegistry _registry;
  final JsUiStore _store = JsUiStore();
  final String _pageKey = 'jsui_${_seq++}';

  /// 实际加载的入口模块（网络补丁解压后为 zip 内虚拟路径）。
  late String _entryJsAsset;
  String? _localRoot;

  String? _rootId;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _manager = widget.sharedManager ?? JsRuntimeManager.instance;
    _registry = widget.registry ?? JsWidgetRegistry();
    if (widget.registry == null) {
      // 核心注册 + 各能力域注册（滚动/文本/通知…），见 js_ui_capabilities。
      registerAllJsWidgets(_registry);
    }
    // 框架内建宿主方法（log / nativeToast / jsuiCommit）：全局一次。
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
        throw StateError(
            'jsAsset 缺少 ?component=xxx 参数：${widget.jsAsset}');
      }
      // 剥离 query 后的真实资源地址（zip 下载 / asset 加载用）。
      final realAsset = uri.replace(queryParameters: {}).toString();

      // 网络补丁包：http(s):// → 下载 zip 解压到本地根；入口改为包内虚拟路径，
      // 其余（递归 import / 实例化 / 相对路径）与 asset 场景一致。
      var entry = realAsset;
      String? localRoot = widget.localRoot;
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
        entry = bundle.entryJsAsset;
        localRoot = bundle.localRoot;
      }
      _entryJsAsset = entry;
      _localRoot = localRoot;
      await _manager.loadModule(_entryJsAsset, localRoot: _localRoot);
      _manager.evaluate(
        '__jsui.mount(${jsonEncode(_pageKey)}, ${jsonEncode(_entryJsAsset)}, '
        '${jsonEncode(component)}, '
        '${jsonEncode(jsonEncode(widget.props))});',
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
  void _invoke(Object? handler, [Object? payload]) {
    if (handler is! Map) return;
    final id = handler['__fn'];
    if (id is! String) return;
    // payload 双重编码：内层把值变成 JSON 文本（true→"true"、'a'→"\"a\""），
    // 外层再包成 JS 字符串字面量；JS 侧 invoke 对字符串参数做一次
    // JSON.parse 还原原始类型。单层编码会把字符串 payload 解析失败置 null。
    _manager.evaluate('__jsui.invoke(${jsonEncode(id)}, ${jsonEncode(jsonEncode(payload))});');
  }

  @override
  void dispose() {
    _manager.evaluate('if (typeof __jsui !== "undefined") __jsui.dispose(${jsonEncode(_pageKey)});');
    // 注销本页 store：jsuiCommit 处理器按 key 查不到即丢弃（页面已销毁）。
    jsUiPageStores.remove(_pageKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _JsLoadErrorView(message: _error!, onRetry: _retry);
    }
    if (_loading || _rootId == null) {
      return Material(
        color: Colors.white,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return _JsNode(
      store: _store,
      id: _rootId!,
      registry: _registry,
      nativeComponents: widget.nativeComponents,
      invoke: _invoke,
    );
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
    required this.registry,
    required this.nativeComponents,
    required this.invoke,
  });

  final JsUiStore store;
  final String id;
  final JsWidgetRegistry registry;
  final Map<String, Widget Function(Map<String, dynamic> args)> nativeComponents;

  /// 事件回传：`(handler, payload)`——handler 是运行时登记的句柄。
  final void Function(Object? handler, [Object? payload]) invoke;

  @override
  State<_JsNode> createState() => _JsNodeState();
}

class _JsNodeState extends State<_JsNode> {
  @override
  void initState() {
    super.initState();
    widget.store.bind(widget.id, _rebuild);
  }

  @override
  void dispose() {
    widget.store.unbind(widget.id, _rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.store.nodes[widget.id];
    if (node == null) return const SizedBox.shrink();

    final children = <Widget>[];
    final childTypes = <String>[];
    final childContexts = <JsBuildContext>[];
    for (final childId in node.childIds) {
      final childNode = widget.store.nodes[childId];
      final childType = childNode?.type ?? '';
      childTypes.add(childType);
      children.add(_node(childId));
      // 数据载体型子结点（BottomNavigationBarItem / DropdownMenuItem 等
      // 非 Widget 类型）：父 renderer 直接读其 props/propChildren 组装。
      childContexts.add(
        JsBuildContext(
          props: childNode?.props ?? const {},
          children: const [],
          childTypes: const [],
          childContexts: const [],
          propChildren: {
            for (final e in childNode?.propChildIds.entries ?? const <MapEntry<String, String>>[])
              e.key: _node(e.value),
          },
          nativeComponents: widget.nativeComponents,
          invoke: widget.invoke,
        ),
      );
    }

    final propChildren = <String, Widget>{};
    for (final entry in node.propChildIds.entries) {
      propChildren[entry.key] = _node(entry.value);
    }

    final builder = widget.registry.lookup(node.type);
    if (builder == null) return buildMissingJsWidget(node.type, children);

    return builder(
      JsBuildContext(
        props: node.props,
        children: children,
        childTypes: childTypes,
        childContexts: childContexts,
        propChildren: propChildren,
        nativeComponents: widget.nativeComponents,
        invoke: widget.invoke,
      ),
    );
  }

  Widget _node(String id) => _JsNode(
    key: ValueKey(id),
    store: widget.store,
    id: id,
    registry: widget.registry,
    nativeComponents: widget.nativeComponents,
    invoke: widget.invoke,
  );
}
