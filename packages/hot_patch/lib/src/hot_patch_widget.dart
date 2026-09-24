import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'builtin_renderers.dart';
import 'builtin_services.dart';
import 'js_runtime_manager.dart';
import 'native_service.dart';
import 'widget_renderer.dart';

/// ============================================================
/// HotPatchWidget —— 热更新组件运行时入口
///
/// 使用场景：线上出现 bug 时，下发由 ui_component_generator 从
/// 正常组件静态翻译的 JS 补丁（.component.js），
/// 运行时用本组件替换原组件即可修复，无需发版。
///
/// 流程：
///   1. 加载 JS 补丁源码（本 demo 用 assets；生产环境可改为
///      从远端下载 + 版本/签名校验）
///   2. 使用 [JsRuntimeManager]（默认全局 [JsRuntimeManager.instance]，
///      也可通过 [sharedManager] 传入自建的 manager 分组共享），
///      把补丁组件注册进全局 __components
///   3. 调用 build() 拿首帧节点树（与组件 build() 原封不动对应）
///   4. 事件回流：按钮事件 → 直接调用组件同名方法 → build() 新树 → setState
///   5. JS→Flutter 原生方向：JS 里 sendMessage(channel, ...) 按通道分发
///      到 [NativeService] 实现（默认内置 SnackBar/Log 服务）
///
/// 本组件**不接触任何 JavascriptRuntime**：所有 JS 操作
/// （求值/通道/实例化）都经 [JsRuntimeManager] 内部消化。
///
/// 两个扩展点（均无需改动本组件）：
/// - 渲染层：注入自定义 [rendererRegistry] 支持更多/自定义 widget
/// - 服务层：注入 [nativeServices] 提供各种 JS→原生 能力
/// ============================================================
class HotPatchWidget extends StatefulWidget {
  const HotPatchWidget({
    super.key,
    required this.jsAsset,
    required this.component,
    this.requiredAssets = const [],
    this.rendererRegistry,
    this.nativeServices,
    this.nativeComponents = const {},
    this.sharedManager,
  });

  /// JS 补丁模块的来源。本 demo 用 assets；生产环境换成远端 URL。
  final String jsAsset;

  /// 嵌套组件产物（如 DashboardCard 内嵌 BannerCard）：先于主产物加载，
  /// 使 __components 里注册齐全，渲染层才能递归渲染嵌套组件。
  final List<String> requiredAssets;

  /// 非私有/无注解组件的原生注入：组件名 → Flutter widget 构造。
  /// 运行时（hot_patch 包）不 import 业务类，由业务方在这里注册，
  /// 未注册的组件渲染占位提示（原生场景照常用 Flutter 组件）。
  final Map<String, Widget Function(Map<String, dynamic> args)>
      nativeComponents;

  /// 要实例化的组件名（对应 @UIComponent 注解的 name）。
  final String component;

  /// 渲染策略注册表。默认注入内置策略（Column/Row/Text/Button）；
  /// 业务方可传入扩展后的注册表以支持更多/自定义 widget。
  final WidgetRendererRegistry? rendererRegistry;

  /// 原生服务注入列表。内置服务（nativeToast/log）始终可用；
  /// 传入的服务为增量扩展（同 channel 时覆盖内置实现）。
  final List<NativeService>? nativeServices;

  /// 外部传入的共享 JS 运行时管理器（可选）。不传时使用
  /// [JsRuntimeManager.instance] 全局默认实例（所有组件共享一个 JS 环境）；
  /// 传入时多个 HotPatchWidget 共享该 manager 的 runtime（JS 状态共享，
  /// 实例仍按 key 隔离，互不串台）。传不同的 manager 则分组隔离。
  final JsRuntimeManager? sharedManager;

  @override
  State<HotPatchWidget> createState() => HotPatchWidgetState();
}

class HotPatchWidgetState extends State<HotPatchWidget> {
  late final WidgetRendererRegistry _registry;
  late final NativeServiceRegistry _services;

  /// 本实例使用的 JS 运行时管理器：
  /// 外部传入则用传入的（分组共享），否则用全局默认实例。
  late final JsRuntimeManager _manager =
      widget.sharedManager ?? JsRuntimeManager.instance;

  Object? _tree;
  bool _loading = true;
  String? _error;

  /// JS 实例唯一 key：每个 HotPatchWidget 用 __instances[key] 持有独立组件实例，
  /// 同名组件多处使用（如列表多卡片）时状态互不共享。
  late final String _instanceKey = 'hp_${identityHashCode(this)}';

  /// 页面级内部实现列表：框架内置的页面级服务（如 setState）实例放这里，
  /// 在 _boot 里统一走 register() 注册——不设特例注册方法，
  /// 后续新增内部实现只需往这个数组里加一个 NativeService。
  final List<NativeService> _internalServices = [];

  /// 本页面的实例 key（InstanceNativeService 可通过 state 读取）。
  String get instanceKey => _instanceKey;

  /// 本页面使用的 JS 运行时管理器。
  JsRuntimeManager get runtimeManager => _manager;

  @override
  void initState() {
    super.initState();
    // 渲染层：默认注册内置策略；业务方注入的注册表原样使用。
    _registry = widget.rendererRegistry ?? WidgetRendererRegistry();
    if (widget.rendererRegistry == null) {
      registerBuiltinRenderers(_registry);
    }
    // 服务层：内置服务始终注册，外部注入为增量扩展（同 channel 覆盖内置）。
    _services = NativeServiceRegistry();
    registerBuiltinNativeServices(_services);
    for (final svc in widget.nativeServices ?? const <NativeService>[]) {
      _services.register(svc);
    }
    // 页面级内部实现（setState 即普通 InstanceNativeService）
    _internalServices.add(_SetStateService());
    _boot();
  }

  Future<void> _boot() async {
    try {
      // 1. 加载 JS 补丁源码（生产环境：从远端下载，校验签名与版本）
      final jsSource = await rootBundle.loadString(widget.jsAsset);
      debugPrint('[hot_patch] jsSource loaded: ${jsSource.length} chars');

      // 1.1 服务注册：统一收 NativeService。
      //     - 页面级：内部实现（setState 等）+ 业务方注入的服务 →
      //       register(页面key, service)，按页面 key 隔离、随 dispose 清理；
      //     - 全局级：内置服务（toast/log）与页面无关 → registerGlobal，
      //       全局一份。
      final injected = widget.nativeServices ?? const <NativeService>[];
      final injectedChannels = injected.map((s) => s.channel).toSet();
      for (final svc in _internalServices) {
        _registerPageService(svc);
        debugPrint('[hot_patch] page internal service "${svc.channel}" registered');
      }
      for (final svc in injected) {
        if (svc is InstanceNativeService) {
          _registerPageService(svc);
        } else {
          JsRuntimeManager.registerGlobal(svc);
        }
        debugPrint('[hot_patch] ${svc is InstanceNativeService ? "page" : "global"} service "${svc.channel}" registered');
      }
      for (final channel in _services.channels) {
        if (injectedChannels.contains(channel)) continue;
        final service = _services.lookup(channel)!;
        JsRuntimeManager.registerGlobal(service);
        debugPrint('[hot_patch] global service "$channel" registered');
      }

      // 1.2 本实例的 setState 重建回调：重新取 JS 实例的最新树并 setState。
      //     宿主只在这里 setState 更新节点树；事件回调本身不直接 setState。
      // （setState 已由 _internalServices 里的 _SetStateService 注册，
      //   在 _bootWithLifecycle 之前完成——见 1.1）


      // 2.1 先加载嵌套组件产物（__components 注册齐全）
      for (final asset in widget.requiredAssets) {
        final depSource = await rootBundle.loadString(asset);
        _manager.evaluate(depSource);
        debugPrint('[hot_patch] required asset loaded: $asset');
      }
      // 2.2 加载补丁模块（产物自包含：__components/__instances 注册表 + 组件构造函数）
      _manager.evaluate(jsSource);
      debugPrint('[hot_patch] module loaded');

      // 2.3 实例化组件：new 一个独立实例（可重复实例化，状态互不共享）
      _manager.evaluate(
        '__instances["$_instanceKey"] = new __components["${widget.component}"](); '
        '__instances["$_instanceKey"]._key = "$_instanceKey";',
      );
      // 2.3.1 给 JS 实例挂载 setState：执行回调（更新 JS 状态）+ sendMessage 通知宿主重建。
      // HotPatchWidget 不直接 setState；重建由 JS 侧 setState 驱动（与 Dart 语义一致）。
      _manager.evaluate(
        '(function(){ __instances["$_instanceKey"].setState = function(fn){ '
        '  fn.call(this); '
        '  sendMessage("setState", JSON.stringify({ key: "$_instanceKey" })); '
        '}; })()',
      );
      debugPrint('[hot_patch] instance created: $_instanceKey');

      // 3. 生命周期 + 首帧：调 initState（若存在）再 build 首帧
      _tree = _bootWithLifecycle('initState');
      debugPrint('[hot_patch] first tree: $_tree');
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      debugPrint('[hot_patch] boot error: $e');
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  /// 页面级服务注册：InstanceNativeService 先注入页面 state 再 register。
  void _registerPageService(NativeService svc) {
    if (svc is InstanceNativeService) {
      svc.build(this);
    }
    JsRuntimeManager.register(_instanceKey, svc);
  }

  /// 页面重建（由 setState 实例服务回调）：重新取 JS 实例的最新树并
  /// setState。宿主只在这里 setState 更新节点树；事件回调本身不直接
  /// setState，而是由 JS 侧 setState() → sendMessage 驱动。
  void rebuild() {
    debugPrint('[hot_patch] js setState rebuild: $_instanceKey');
    if (!mounted) return;
    try {
      final r = _manager.evaluate(
        'JSON.stringify(__instances["$_instanceKey"].build())',
      );
      final newTree = jsonDecode(r.stringResult);
      setState(() => _tree = newTree);
    } catch (e) {
      debugPrint('[hot_patch] setState rebuild error: $e');
    }
  }

  /// 调生命周期方法（若 JS 实例导出该方法）并返回最新节点树。
  Object? _bootWithLifecycle(String lifecycle) {
    final r = _manager.evaluate(
      '(function(){ var i = __instances["$_instanceKey"]; '
      'if (typeof i.$lifecycle === "function") { i.$lifecycle(); } '
      'return JSON.stringify(i.build()); })()',
    );
    return jsonDecode(r.stringResult);
  }

  /// 调用 JS 生命周期（无返回值场景，如 dispose/deactivate）。
  void _callLifecycle(String lifecycle) {
    final r = _manager.evaluate(
      '(function(){ var i = __instances["$_instanceKey"]; '
      'if (typeof i.$lifecycle === "function") { i.$lifecycle(); } '
      'return true; })()',
    );
    debugPrint('[hot_patch] lifecycle $lifecycle called: ${r.stringResult}');
  }

  void _onEvent(String event) {
    debugPrint('[hot_patch] onEvent: $event');
    // 事件名 = 组件方法名（一比一）：直接调用同名方法。
    // UI 重建由方法体内的 setState()（挂载在 JS 实例上）驱动，
    // 宿主不直接 setState；方法体未调 setState 则 UI 不刷新（与 Dart 一致）。
    _manager.evaluate('(function(){ __instances["$_instanceKey"].$event(); })()');
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[hot_patch] build: loading=$_loading error=$_error tree=${_tree != null}');
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text('加载失败: $_error', style: const TextStyle(color: Colors.red)),
      );
    }
    final ctx = WidgetRenderContext(
      registry: _registry,
      onEvent: _onEvent,
      componentHost: _RuntimeComponentHost(
        manager: _manager,
        parentKey: _instanceKey,
        onNestedEvent: _onNestedEvent,
        nativeComponents: widget.nativeComponents,
      ),
    );
    final w = ctx.render(_tree);
    debugPrint('[hot_patch] render -> ${w.runtimeType}');
    return w;
  }

  /// 嵌套组件事件回流：调嵌套实例方法 → 重建父组件整棵树。
  void _onNestedEvent(String component, String event) {
    debugPrint('[hot_patch] nested onEvent: $component.$event');
    // 嵌套实例方法里 setState() → sendMessage('setState') → 宿主重建主实例整树
    // （Component 节点递归取嵌套实例最新树）。
    final key = '$_instanceKey::$component';
    _manager.evaluate('(function(){ __instances["$key"].$event(); })()');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loading) _callLifecycle('didChangeDependencies');
  }

  @override
  void didUpdateWidget(covariant HotPatchWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_loading) _callLifecycle('didUpdateWidget');
  }

  @override
  void deactivate() {
    if (!_loading) _callLifecycle('deactivate');
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    if (!_loading) _callLifecycle('activate');
  }

  @override
  void dispose() {
    // 一次性移除本页面 key 下的全部注册（setState、native 服务等）
    JsRuntimeManager.dispose(_instanceKey);
    if (!_loading) _callLifecycle('dispose');
    // manager（及其 runtime）由全局默认/业务方持有，不在此 dispose。
    super.dispose();
  }
}

/// 页面级内部服务：setState —— JS 侧 `this.setState(fn)` → sendMessage
/// → 本服务 handle → 页面重建。
///
/// setState 是框架内部机制，但实现上就是一个普通 [InstanceNativeService]
/// （channel='setState'），由 HotPatchWidgetState._internalServices 持有、
/// 统一走 register() 注册；后续新增页面级内部实现照此办理即可。
class _SetStateService extends InstanceNativeService {
  @override
  String get channel => 'setState';

  @override
  void handle(BuildContext context, dynamic payload) {
    state?.rebuild();
  }
}

/// 嵌套组件宿主实现：通过 JS 运行时管理器实例化/取树/分发事件。
///
/// 嵌套实例 key = 父实例 key + '::' + 组件名（同一父实例内每个组件名一个
/// 嵌套实例；同一组件多处嵌套的场景后续可按序号扩展 key）。
class _RuntimeComponentHost implements ComponentHost {
  _RuntimeComponentHost({
    required this.manager,
    required this.parentKey,
    required this.onNestedEvent,
    required this.nativeComponents,
  });

  final JsRuntimeManager manager;
  final String parentKey;
  final void Function(String component, String event) onNestedEvent;

  /// 业务方注入的原生 widget（非私有/无注解组件）。
  final Map<String, Widget Function(Map<String, dynamic> args)>
      nativeComponents;

  @override
  bool isRegistered(String component) {
    final r = manager.evaluate('typeof __components["$component"] === "function"');
    return r.stringResult == 'true';
  }

  @override
  Object? treeOf(String component, Map<String, dynamic> args) {
    final key = '$parentKey::$component';
    // 首次获取：实例化（构造参数 args）+ 注入 setState + 回调 initState；
    // 后续复用同一实例（状态保留）
    final argsJs = jsonEncode(args);
    final r = manager.evaluate(
      '(function(){ '
      'var key = "$key"; var comp = "$component"; '
      'if (typeof __instances[key] === "undefined") { '
      '  __instances[key] = new __components[comp]($argsJs); '
      '  __instances[key]._key = key; '
      '  __instances[key].setState = function(fn){ '
      '    fn.call(this); '
      '    sendMessage("setState", JSON.stringify({ key: key })); '
      '  }; '
      '  if (typeof __instances[key].initState === "function") '
      '    __instances[key].initState(); '
      '} '
      'return JSON.stringify(__instances[key].build()); })()',
    );
    return jsonDecode(r.stringResult);
  }

  @override
  void dispatch(String component, String event) {
    onNestedEvent(component, event);
  }

  @override
  Widget? nativeOf(String component, Map<String, dynamic> args) {
    final builder = nativeComponents[component];
    if (builder == null) return null;
    return builder(args);
  }
}
