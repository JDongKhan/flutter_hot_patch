import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/builtin_host_methods.dart';
import '../services/js_runtime_manager.dart';
import '../utils/hot_patch_log.dart';
import '../utils/remote_asset_loader.dart';
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
/// 用法：
/// ```dart
/// JsUiWidget(jsAsset: 'assets/components/counter.js',
///            component: 'Counter')
/// ```
class JsUiWidget extends StatefulWidget {
  const JsUiWidget({
    super.key,
    required this.jsAsset,
    required this.component,
    this.props = const {},
    this.nativeComponents = const {},
    this.sharedManager,
    this.localRoot,
    this.entryPath,
    this.registry,
  });

  /// 补丁入口 JS（asset 路径或 http(s):// zip 网络补丁）。
  final String jsAsset;

  /// 入口模块里注册进 `__modules` 的组件类名（@UIComponent 的 name）。
  final String component;

  /// 传给组件构造的 props（如 `MyStatelessCard(title: ...)` 的 {title: ...}）。
  final Map<String, dynamic> props;

  /// 无 JS 产物的组件（Component 节点）的原生注入：组件名 → 构造。
  /// 运行时（hot_patch 包）不 import 业务类，由业务方注册。
  final Map<String, Widget Function(Map<String, dynamic> args)>
      nativeComponents;

  /// 共享运行时；多组件共用一个引擎时传入。
  final JsRuntimeManager? sharedManager;

  /// 嵌套组件透传的本地补丁根目录（网络补丁解压后的本地根）。
  final String? localRoot;

  /// 网络补丁包（zip）内入口 .js 的相对路径。仅网络补丁生效：
  /// 指定时直接用它；不指定则按 [component] 名反查声明位置。
  final String? entryPath;

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
      registerBuiltinJsWidgets(_registry);
    }
    // 框架内建宿主方法（log / nativeToast / jsuiCommit）：全局一次。
    registerBuiltinHostMethods();
    _store.onRoot = (id) {
      _rootId = id;
      if (mounted) setState(() => _loading = false);
    };
    // ScrollController 桥接通道（JS ScrollController ↔ Dart ScrollController）：
    // 必须在任何 JS 组件 mount（new ScrollController → host 登记）前就位。
    ensureScrollControllerChannels();
    // jsuiCommit 补丁按页面 key 路由：登记本页 store（key 由 JS 补丁带下来）。
    jsUiPageStores[_pageKey] = _store;
    _boot();
  }

  Future<void> _boot() async {
    try {
      // 运行时骨架先就位（`__jsui` + `__modules['js_ui/core']`）。
      _manager.ensureJsUiRuntime();
      // 网络补丁包：http(s):// → 下载 zip 解压到本地根；入口改为包内虚拟路径，
      // 其余（递归 import / 实例化 / 相对路径）与 asset 场景一致。
      var entry = widget.jsAsset;
      String? localRoot = widget.localRoot;
      if (RemoteAssetLoader.isRemote(widget.jsAsset)) {
        final bundle = await RemoteAssetLoader.load(
          widget.jsAsset,
          component: widget.component,
          entryPath: widget.entryPath,
        );
        if (bundle == null) {
          throw StateError('远程补丁加载失败（需 http(s):// zip）：${widget.jsAsset}');
        }
        entry = bundle.entryJsAsset;
        localRoot = bundle.localRoot;
      }
      _entryJsAsset = entry;
      _localRoot = localRoot;
      await _manager.loadModule(_entryJsAsset, localRoot: _localRoot);
      _manager.evaluate(
        '__jsui.mount(${jsonEncode(_pageKey)}, ${jsonEncode(_entryJsAsset)}, '
        '${jsonEncode(widget.component)}, '
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
    _manager.evaluate(
      '__jsui.invoke(${jsonEncode(id)}, ${jsonEncode(jsonEncode(payload))});',
    );
  }

  @override
  void dispose() {
    _manager.evaluate(
      'if (typeof __jsui !== "undefined") __jsui.dispose(${jsonEncode(_pageKey)});',
    );
    // 注销本页 store：jsuiCommit 处理器按 key 查不到即丢弃（页面已销毁）。
    jsUiPageStores.remove(_pageKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('JS 组件加载失败：$_error', style: const TextStyle(color: Color(0xFFB00020))),
        ),
      );
    }
    if (_loading || _rootId == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return _JsNode(
      store: _store,
      id: _rootId!,
      registry: _registry,
      nativeComponents: widget.nativeComponents,
      invoke: _invoke,
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
  final Map<String, Widget Function(Map<String, dynamic> args)>
      nativeComponents;

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
      childContexts.add(JsBuildContext(
        props: childNode?.props ?? const {},
        children: const [],
        childTypes: const [],
        childContexts: const [],
        propChildren: {
          for (final e in childNode?.propChildIds.entries ??
              const <MapEntry<String, String>>[])
            e.key: _node(e.value),
        },
        nativeComponents: widget.nativeComponents,
        invoke: widget.invoke,
      ));
    }

    final propChildren = <String, Widget>{};
    for (final entry in node.propChildIds.entries) {
      propChildren[entry.key] = _node(entry.value);
    }

    final builder = widget.registry.lookup(node.type);
    if (builder == null) return buildMissingJsWidget(node.type, children);

    return builder(JsBuildContext(
      props: node.props,
      children: children,
      childTypes: childTypes,
      childContexts: childContexts,
      propChildren: propChildren,
      nativeComponents: widget.nativeComponents,
      invoke: widget.invoke,
    ));
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