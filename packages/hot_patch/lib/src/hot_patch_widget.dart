import 'dart:convert';

import 'package:flutter/material.dart';

import 'widgets/builtin_renderers.dart';
import 'services/builtin_services.dart';
import 'services/js_runtime_manager.dart';
import 'services/native_service.dart';
import 'widgets/widget_renderer.dart';
import 'utils/hot_patch_log.dart';

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
    this.componentArgs = const {},
    this.rendererRegistry,
    this.nativeServices,
    this.nativeComponents = const {},
    this.sharedManager,
  });

  /// JS 补丁模块的来源。本 demo 用 assets；生产环境换成远端 URL。
  final String jsAsset;

  /// 组件构造参数（如 `_LabeledDivider(text: 'x')` 的 {text: 'x'}）：
  /// 实例化 JS 组件时传给构造函数（生成器 ctorArgs 逐个取用，缺省回退默认值）。
  final Map<String, dynamic> componentArgs;

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
  /// 在 initState 提前赋值（而非 late 延迟到首次访问）：确保 _boot 里
  /// register 服务时 manager 已创建，_wireChannel 才能接到本 manager。
  late JsRuntimeManager _manager;

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
    // 先创建/取得 manager：register 服务的 _wireChannel 遍历 _instances
    // 需要本 manager 已存在（否则通道接不到本 manager 的 runtime）。
    _manager = widget.sharedManager ?? JsRuntimeManager.instance;
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
    _internalServices
      ..add(_SetStateService())
      ..add(_LbNotifyService());
    _boot();
  }

  Future<void> _boot() async {
    try {
      // 1. 加载补丁模块：JsRuntimeManager 模块加载器递归加载 import 依赖
      //    （先依赖后自身），把产物预处理成脚本模式（export class →
      //    class + __modules 注册；import → __modules 解构），同一 jsAsset
      //    只执行一次（多组件/多实例共享同一个模块与模型类）。
      await _manager.loadModule(widget.jsAsset);
      HotPatchLog.log('module loaded: ${widget.jsAsset}');

      // 1.1 服务注册：统一收 NativeService。
      //     - 页面级：内部实现（setState 等）+ 业务方注入的服务 →
      //       register(页面key, service)，按页面 key 隔离、随 dispose 清理；
      //     - 全局级：内置服务（toast/log）与页面无关 → registerGlobal，
      //       全局一份。
      final injected = widget.nativeServices ?? const <NativeService>[];
      final injectedChannels = injected.map((s) => s.channel).toSet();
      for (final svc in _internalServices) {
        _registerPageService(svc);
        HotPatchLog.log('page internal service "${svc.channel}" registered');
      }
      for (final svc in injected) {
        if (svc is InstanceNativeService) {
          _registerPageService(svc);
        } else {
          JsRuntimeManager.registerGlobal(svc);
        }
        HotPatchLog.log('${svc is InstanceNativeService ? "page" : "global"} service "${svc.channel}" registered');
      }
      for (final channel in _services.channels) {
        if (injectedChannels.contains(channel)) continue;
        final service = _services.lookup(channel)!;
        JsRuntimeManager.registerGlobal(service);
        HotPatchLog.log('global service "$channel" registered');
      }

      // 1.2 本实例的 setState 重建回调：重新取 JS 实例的最新树并 setState。
      //     宿主只在这里 setState 更新节点树；事件回调本身不直接 setState。
      // （setState 已由 _internalServices 里的 _SetStateService 注册，
      //   在 _bootWithLifecycle 之前完成——见 1.1）


      // 2. 实例化组件：`new __modules['<jsAsset>'].<组件名>(args)`。
      //    __modules 是 JS 侧全局模块表（模块加载器注册）；class 实例天然
      //    独立（状态互不共享），可重复实例化。
      //    嵌套组件（Component 节点带 import）由渲染层递归创建嵌套
      //    HotPatchWidget 自行加载，使用方无需声明依赖。
      final moduleExpr = '__modules[${jsonEncode(widget.jsAsset)}]';
      final instResult = _manager.evaluate(
        '__instances["$_instanceKey"] = new $moduleExpr.${widget.component}'
        '(${jsonEncode(widget.componentArgs)}); '
        '__instances["$_instanceKey"]._key = "$_instanceKey";',
      );
      HotPatchLog.log('inst eval result: $instResult');
      final instDbg = _manager.evaluate(
        'JSON.stringify({ m: typeof __modules, '
        'i: typeof __instances, '
        'mod: typeof __modules[${jsonEncode(widget.jsAsset)}], '
        'v: typeof __instances["$_instanceKey"] })',
      );
      HotPatchLog.log('inst dbg: $instDbg');
      // 2.3.1 给 JS 实例挂载 setState：执行回调（更新 JS 状态）+ sendMessage 通知宿主重建。
      // HotPatchWidget 不直接 setState；重建由 JS 侧 setState 驱动（与 Dart 语义一致）。
      _manager.evaluate(
        '''(function() {
  __instances["$_instanceKey"].setState = function(fn) {
    fn.call(this);
    sendMessage("setState", JSON.stringify({ key: "$_instanceKey" }));
  };
})()''',
      );
      HotPatchLog.log('instance created: $_instanceKey');

      // 3. 生命周期 + 首帧：调 initState（若存在）再 build 首帧
      _tree = _bootWithLifecycle('initState');
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      HotPatchLog.log('boot error: $e');
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
    HotPatchLog.log('js setState rebuild: $_instanceKey');
    if (!mounted) return;
    try {
      final r = _manager.evaluate(
        'JSON.stringify(__instances["$_instanceKey"].build())',
      );
      final newTree = jsonDecode(r.stringResult);
      setState(() => _tree = newTree);
    } catch (e) {
      HotPatchLog.log('setState rebuild error: $e');
    }
  }

  /// 调生命周期方法（若 JS 实例导出该方法）并返回最新节点树。
  Object? _bootWithLifecycle(String lifecycle) {
    HotPatchLog.log('boot lifecycle begin: $lifecycle');
    final r = _manager.evaluate(
      '''(function() {
  var i = __instances["$_instanceKey"];
  if (i && typeof i.$lifecycle === "function") {
    i.$lifecycle();
  }
  return JSON.stringify(i ? i.build() : null);
})()''',
    );
    HotPatchLog.log(
        'boot lifecycle raw head: ${r.stringResult.substring(0, 80)}');
    return jsonDecode(r.stringResult);
  }

  /// 调用 JS 生命周期（无返回值场景，如 dispose/deactivate）。
  void _callLifecycle(String lifecycle) {
    final r = _manager.evaluate(
      '''(function() {
  var i = __instances["$_instanceKey"];
  if (i && typeof i.$lifecycle === "function") {
    i.$lifecycle();
  }
  return true;
})()''',
    );
    HotPatchLog.log('lifecycle $lifecycle called: ${r.stringResult}');
  }

  void _onEvent(String event) {
    HotPatchLog.log('onEvent: $event');
    // 事件名 = 组件方法名（一比一）：直接调用同名方法。
    // UI 重建由方法体内的 setState()（挂载在 JS 实例上）驱动，
    // 宿主不直接 setState；方法体未调 setState 则 UI 不刷新（与 Dart 一致）。
    _manager.evaluate('''(function(){ __instances["$_instanceKey"].$event(); })()''');
  }

  /// 带值事件（Switch/Slider 等 onChanged）：把新值传给 JS 方法同名参数。
  void _onEventValue(String event, Object? value) {
    HotPatchLog.log('onEventValue: $event = $value');
    _manager.evaluate(
      '''(function(){ __instances["$_instanceKey"].$event(${_jsArg(value)}); })()''',
    );
  }

  /// Dart 值 → JS 实参字面量（bool/num 原样，String 加引号）。
  static String _jsArg(Object? v) {
    if (v == null) return 'null';
    if (v is bool) return v ? 'true' : 'false';
    if (v is num) return '$v';
    if (v is String) {
      final escaped = v
          .replaceAll(r'\', r'\\')
          .replaceAll('"', r'"');
      return '"$escaped"';
    }
    return '"$v"';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text('加载失败: $_error', style: const TextStyle(color: Colors.red)),
      );
    }
    // 当前 jsAsset 的目录：Component 节点的相对 import 以此为基准解析
    final slash = widget.jsAsset.lastIndexOf('/');
    final baseUri =
        slash >= 0 ? widget.jsAsset.substring(0, slash + 1) : '';
    final ctx = WidgetRenderContext(
      registry: _registry,
      onEvent: _onEvent,
      onEventValue: _onEventValue,
      baseUri: baseUri,
      nativeComponents: widget.nativeComponents,
      nestedRendererRegistry: widget.rendererRegistry,
      nativeServices: widget.nativeServices,
      sharedManager: widget.sharedManager,
      instanceKey: _instanceKey,
    );
    final w = ctx.render(_tree);
    return w;
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

/// ListenableBuilder 局部重建服务：JS 模型 notifyListeners →
/// sendMessage('lbNotify', {key, builder}) → 查 lbRefreshCallbacks 表调用
/// 对应 _JsListenableBuilderState._refresh（重取 builder 子树 + setState）。
/// 仅重建该 ListenableBuilder 自身子树，不全量 rebuild。
class _LbNotifyService extends InstanceNativeService {
  @override
  String get channel => 'lbNotify';

  @override
  void handle(BuildContext context, dynamic payload) {
    Map payloadMap;
    if (payload is Map) {
      payloadMap = payload.cast<String, dynamic>();
    } else if (payload is String) {
      try {
        final decoded = jsonDecode(payload);
        if (decoded is! Map) return;
        payloadMap = decoded.cast<String, dynamic>();
      } catch (_) {
        return;
      }
    } else {
      return;
    }
    final key = payloadMap['key']?.toString() ?? '';
    final builder = payloadMap['builder']?.toString() ?? '';
    lbRefreshCallbacks['$key::$builder']?.call();
  }
}

