import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart'
    show kDebugMode, kReleaseMode, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_js/flutter_js.dart';

import '../utils/js_asset_resolver.dart';
import '../utils/remote_asset_loader.dart';
import '../js_ui/capabilities/js_ui_library.dart';
import '../utils/hot_patch_log.dart';

/// JS 运行时管理器：与底层 [JavascriptRuntime] **一对一**。
/// 每个 [JsRuntimeManager] 内部持有一个 [JavascriptRuntime]，所有与
/// JavascriptRuntime 相关的操作（创建、求值、通道注册、生命周期）都在
/// 本类内部消化；JsUiWidget 等使用方只接触 [JsRuntimeManager]，
/// 完全不感知底层运行时对象。
///
/// - **默认实例**：使用 [instance]（全局唯一，static 共享）。大多数场景
///   直接用默认实例即可，多个 JsUiWidget 共享同一个 JS 环境。
/// - **分组隔离**：业务方可以 `JsRuntimeManager()` 自行创建实例，把同一
///   个实例传给一组 JsUiWidget（共享该组的 JS 状态），与其他组的
///   状态互不影响。
/// - **生命周期**：默认实例由本类持有（app 生命周期内常驻）；
///   业务方自建的实例由业务方管理（不再需要时置空引用即可，
///   不要 dispose 底层 runtime，避免其他仍在使用该 runtime 的组件失效）。
///
/// ## 消息通道：单一桥通道 `_app_bridge_` + 单一处理器表
///
/// JS → Flutter 的所有消息都打到**唯一的桥通道** `_app_bridge_`，消息体里
/// 用 `ch` 字段标示目标逻辑通道：
///
///   sendMessage('_app_bridge_', JSON.stringify({ ch: 'jsuiCommit', data }))
///
/// 其中 `data` 固定为 `{id, args}`。JS 侧对外只有**一个**出口
///   `_app_host_.invoke(channel, args)`：它把 `{id, args}` 交给宿主，宿主实现后用
/// `_app_host_.resolve(id, value)` 回填 Promise、实现抛错用
/// `_app_host_.reject(id, message)` 把异常抛回调用者（**宿主必定结算**：
/// 通道未注册也在 [_dispatch] 里回填 null，不留下永久悬空的 Promise）。框架内建通道（增量补丁
/// `jsuiCommit`、日志 `log`、native 通道）与业务 @HostInjected 方法
/// 共用这一张表。
///
/// 本类在**构造时**用 `_runtime.onMessage('_app_bridge_', _dispatch)` 订阅一次，
/// [_dispatch] 再按 `ch` 二次分发到 [globalMessageHandlers]。因此**注册与订阅
/// 完全解耦**：处理器可以在任何时机注册（包括第一个 manager 出现之前，如
/// main() 里直接调用），不需要「补接线」，也不会出现「channel 未接线 →
/// No channel xxx registered」。 [evaluate] 是纯求值入口，不掺注册副作用。
///
/// **对外扩展只有一个能力：[registerHostMethod] 注册一个宿主方法
/// （@HostInjected 方法，或框架内建通道），JS 侧 `_app_host_.invoke` 调用、
/// 宿主实现并回填结果。**
///
/// 页面隔离（多 JsUiWidget 共用单 runtime）由处理器**内部**按参数里的
/// 页面 key 自行路由（如 js_ui 的 `jsuiCommit`：payload 带 key，路由到
/// 对应 JsUiStore），分发层不再区分页面级/全局级。
///
/// [globalMessageHandlers] 必须是 static 全局唯一：
/// flutter_js 0.8.7（iOS/JavaScriptCore）的消息桥是库级全局的，
/// `sendMessage` 的 Dart 回调是 static 字段（由最后创建的 runtime 覆盖
/// 赋值），通道表也是 static Map（key=engineId）。若处理器表是实例级的，
/// 消息到达某个 manager 的通道回调后查不到属于另一个 manager 的处理器，
/// 就会串台/丢消息。
class JsRuntimeManager {
  /// 全局默认实例（static 共享）：大多数场景直接用这个。
  static final JsRuntimeManager instance = JsRuntimeManager();

  /// 全局导航 key（可选）：全局级服务（如 toast 弹 SnackBar）用它定位
  /// ScaffoldMessenger。业务方在 MaterialApp.navigatorKey 传入。
  static GlobalKey<NavigatorState>? navigatorKey;

  /// JS 侧单桥通道名：所有 JS→宿主消息都打到这里，再按消息体 `ch` 分发。
  static const String _bridgeChannel = '_app_bridge_';

  /// 宿主注入「位置 + 具名」混合调用时，承载**位置实参**的哨兵键。
  ///
  /// 协议常量：由生成器 `hot_patch_generator` 产出（其 `hostPositionalKey`
  /// 是同一个值），运行时在这里解析。`@` 不是合法的 Dart 标识符字符，故不会
  /// 与任何具名形参重名，判定无歧义。
  static const String hostPositionalKey = '@args';

  /// 所有活跃 manager（static 跟踪）：宿主对 JS 侧 pending 的结算
  /// （`_app_host_.resolve` / `reject`，见 [_settleHost]）需要对每个 runtime
  /// 求值一次。
  static final Set<JsRuntimeManager> _instances = {};

  // ---------------------------------------------------------------------
  // 全局共享（static）：唯一消息处理器表
  // ---------------------------------------------------------------------

  /// 唯一处理器表（全局唯一）：通道名 → 处理器。
  /// [registerHostMethod] 注册的宿主方法在这里，全局一份；框架内建通道
  /// （`jsuiCommit` / `log` / native 通道）也走同一张表。
  static final Map<String, void Function(dynamic args)> globalMessageHandlers =
      {};

  /// 注册一个**宿主方法**（@HostInjected 通道；框架内建通道同用此入口）。
  ///
  /// 生成器把 Dart 的 static 方法调用（`AccountCenter.getUserName(a)`）在
  /// 调用点翻译为 JS 侧 `_app_host_.invoke("通道名", 参数载荷)`（返回 Promise，可
  /// await；载荷按实参形态给数组/对象，见 [_hostCallArgs]）。本方法把该通道接到
  /// 宿主实现 [impl]：收到 JS 的 `{id, args}` 后按
  /// `Function.apply(impl, 位置实参, 具名实参)` 调用——Dart 调用语义完整还原，
  /// 位置/具名实参**个数不限**，未传的参数走实现自身的默认值，返回值类型也不限。
  /// 之后把返回值经 `_app_host_.resolve(id, value)` 回填 JS 的 Promise；
  /// 实现抛错则经 `_app_host_.reject(id, message)` 把异常抛回 JS 调用者。
  ///
  /// 全局一份；通道名即 @HostInjected 注解里的名称（缺省为方法名），或框架
  /// 内建通道名。只写处理器表——桥通道在 manager 构造时已订阅。
  /// 通道名需唯一：debug 下重复注册会触发断言失败。
  static void registerHostMethod(String channel, Function impl) {
    // debug 阶段消灭重复：同一通道注册两次会静默覆盖前一个实现，JS 侧调到的
    // 实现与预期不符且无从察觉。断言让问题在启动时立刻暴露。
    assert(
      !globalMessageHandlers.containsKey(channel),
      'registerHostMethod: 通道 "$channel" 已被注册——'
      '通道名必须唯一（重复注册会静默覆盖前一个实现）',
    );
    globalMessageHandlers[channel] = (dynamic args) async {
      final map = args is Map ? args : const {};
      final id = map['id']?.toString();
      final (positional, named) = _hostCallArgs(map['args']);
      try {
        final value = await Function.apply(impl, positional, named);
        _settleHost(id, value: value);
      } catch (e, s) {
        // 不静默：实现调用失败若悄悄回填 null，JS 侧只看到「结果是 null」，
        // 完全不知道宿主侧压根没调成功（具名参数不匹配就是这样被吞掉的）。
        // 现在把异常原样抛回 JS 调用者（reject → await 处抛出，可被 JS 自己的
        // try/catch 接住）；完整堆栈仍留在宿主日志里。
        HotPatchLog.error(
          'registerHostMethod("$channel") 调用宿主实现失败: $e',
          error: e,
          stackTrace: s,
        );
        _settleHost(id, error: '$e');
      }
    };
  }

  /// 帧级 flush：宿主 begin frame 阶段驱动所有活跃 runtime 执行 JS 侧待处理
  /// 重建（`__jsui.flushPending`）。JS 的 setState 只标脏，宿主每帧统一执行一次，
  /// 同一帧内多次 setState 合并为一次 build（与 Flutter 的 setState 语义一致）。
  /// 请求入口见 builtin_host_methods 的 `jsuiRequestFrame`。
  static void flushJsUiPending() {
    for (final m in _instances.toList()) {
      m.evaluate(
        'if (typeof __jsui !== "undefined" && __jsui.flushPending) '
        '__jsui.flushPending();',
      );
    }
  }

  /// 对所有活跃 runtime 求值一次（宿主侧主动推送，如动画帧回传 value）。
  ///
  /// 与 [_settleHost] 同口径：持有目标句柄的 runtime 生效，其余按 id 查不到即
  /// no-op（见 JS 侧 `__jsui.invoke`），因此调用方无需知道句柄归属哪个 runtime。
  static void evaluateAll(String code) {
    for (final m in _instances.toList()) {
      m.evaluate(code);
    }
  }

  /// 调试用：清除本地补丁缓存并重置模块缓存。
  ///
  ///   - 磁盘：删除 `<document>/hot_patch/` 下**全部** URL 的解压产物（含
  ///     协商缓存记录），下次加载重新下载 zip（见 [RemoteAssetLoader.clearCache]）；
  ///   - 内存：清空所有活跃 runtime 的已加载模块表与 JS 侧 `__modules`
  ///     （见 [invalidateModules]），强制重新 evaluate 最新产物。
  ///
  /// 清除后重新进入热更页面即拉取最新产物；已在屏上的 JS 页面需重进才刷新。
  static Future<void> clearCache() async {
    await RemoteAssetLoader.clearCache();
    for (final m in _instances.toList()) {
      m.invalidateModules();
    }
  }

  /// 结算 JS 侧 Promise（`_app_host_.resolve` / `_app_host_.reject`）。
  ///
  /// 对每个活跃 runtime 求值一次：持有该 id 的 runtime 生效，其余为 no-op
  /// （JS 侧按 id 查不到 pending 即直接返回）。
  ///
  /// 宿主**必须**二选一结算——`invoke` 一次就在 JS 侧建了一条 pending，
  /// 既不 resolve 也不 reject 会让 Promise 永久悬空、条目永久滞留（见 [host]）。
  /// [error] 非空即走 reject 路径；[id] 缺失（如内建 `send` 通道带 `args`
  /// 不带 id）时无事可做，直接返回。
  static void _settleHost(String? id, {Object? value, String? error}) {
    if (id == null || id.isEmpty) return;
    final reject = error != null;
    final code = reject
        ? '_app_host_.reject("$id", ${jsonEncode(error)});'
        : '_app_host_.resolve("$id", ${jsonEncode(value)});';
    final where = reject ? '_app_host_.reject' : '_app_host_.resolve';
    for (final m in _instances.toList()) {
      m._eval(code, where);
    }
  }

  /// JS 宿主调用的参数载荷 → (`位置实参`, `具名实参`)。
  ///
  /// 生成器（见 `_app_host_.invoke`）按实参形态给三种编码，这里对称解析：
  ///   - 数组 `[a, b]`            → 全是位置实参
  ///   - 对象 `{"times": 2}`      → 全是具名实参
  ///   - 对象带 [hostPositionalKey] → 混合（该键是位置实参，其余键是具名）
  ///
  /// 位置实参与具名实参的**个数都不设限**；具名键转成 [Symbol]
  /// （`Function.apply` 的具名表要求 `Map<Symbol, dynamic>`，`Symbol('times')`
  /// 等价于 `#times`）。未传的参数由实现自身的默认值兜底。
  static (List<dynamic>, Map<Symbol, dynamic>) _hostCallArgs(dynamic raw) {
    if (raw is List) return (raw, const {});
    if (raw is Map) {
      final pos = raw[hostPositionalKey];
      final named = <Symbol, dynamic>{};
      for (final e in raw.entries) {
        final key = e.key.toString();
        if (key == hostPositionalKey) continue;
        named[Symbol(key)] = e.value;
      }
      return (pos is List ? pos : const <dynamic>[], named);
    }
    return (const <dynamic>[], const <Symbol, dynamic>{});
  }

  // ---------------------------------------------------------------------
  // 实例状态：与 JavascriptRuntime 一对一
  // ---------------------------------------------------------------------

  /// 本 manager 独占的底层运行时（对外不可见，全部内部消化）。
  final JavascriptRuntime _runtime = getJavascriptRuntime();

  bool _jsUiInited = false;

  JsRuntimeManager() {
    _instances.add(this);
    // 只订阅**一个**桥通道：所有 JS→宿主消息都打到这里，本类再按消息体
    // `ch` 字段二次分发（[_dispatch]）。订阅只发生这一次，与处理器注册
    // 时机完全解耦——不需要任何「补接线 / 防重」逻辑。
    _runtime.onMessage(_bridgeChannel, _dispatch);
  }

  /// 所有 JS 求值的统一入口（纯求值，无注册副作用）。
  /// code 内部按需寻址，如 `__jsui.invoke(...)` / `__jsui.mount(...)`。
  ///
  /// 求值失败经 [_eval] 打日志（flutter_js 的 evaluate 不抛异常，
  /// 不查返回值就会静默失败）。
  JsEvalResult evaluate(String code) => _eval(code, 'evaluate');

  /// 求值 + **失败即抛**：给「失败必须让上层感知」的调用点用（典型是
  /// JsUiWidget 挂载组件——组件名在包里不存在时必须进错误态，而不是因为
  /// `isError` 只被记了日志、`root` 永远不下发而一直转圈）。
  ///
  /// 事件回传 / dispose 这类「失败只该记日志、不影响界面」的调用点仍用
  /// [evaluate]（在 UI 回调里抛异常会把一次点击变成崩溃）。
  JsEvalResult evaluateOrThrow(String code, {String where = 'evaluate'}) {
    final result = _eval(code, where);
    if (result.isError) {
      throw JsEvalException('JS eval failed [$where]: ${result.stringResult}');
    }
    return result;
  }

  /// 求值 + 错误检查：本类内所有 `_runtime.evaluate` 的统一出口。
  ///
  /// flutter_js 的 `evaluate` **不会抛异常**：JS 侧的语法/运行错误以
  /// [JsEvalResult.isError] + [JsEvalResult.stringResult]（JSC 下形如
  /// `ERROR: ...`）返回。所以每次求值都必须查 `isError` 并打日志，否则
  /// 注入失败会被静默吞掉——之后所有调用都是 undefined，却看不到任何报错。
  /// [where] 标明出错的是哪段注入/调用，便于定位。
  JsEvalResult _eval(String code, String where) {
    final result = _runtime.evaluate(code);
    if (result.isError) {
      final preview = code.replaceAll('\n', ' ').trim();
      final brief =
          preview.length > 80 ? '${preview.substring(0, 80)}…' : preview;
      HotPatchLog.error(
        'JS eval failed [$where]: ${result.stringResult} | code: $brief',
      );
    }
    return result;
  }

  /// 确保 js_ui 运行时骨架就位（幂等）。
  ///
  /// 注入 JS 运行时：`patch/runtime.js`（**构建期产物**，与组件产物同生命
  /// 周期）——运行环境全局（模块表 `__modules` / console 桥）+ element/
  /// component/reconciler/context + 能力桥 + ChangeNotifier 基类 + 各能力
  /// 片段 + commit 协议。与具体组件无关；组件/模型/按 package 生成的 widget
  /// 模块仍走 [loadModule]。
  ///
  /// JS 源码全部在 `hot_patch_generator`（`builders/runtime/js/**`），由
  /// `ui_runtime` builder 写成 `patch/runtime.js`：**JS 侧修复重出产物即可，
  /// 不需要发版 App**。
  ///
  /// 幂等：每个 manager 只初始化一次。`runtime.js` 内部另有 `G.__jsui` 守卫，
  /// 同一 JS 环境（默认实例被多个 manager 共享）重复求值直接返回，不会产生
  /// 两份运行时状态。
  Future<void> ensureJsUiRuntime({String? localRoot, String? moduleAsset}) async {
    if (_jsUiInited) return;
    // 编译模式 / 平台标志只有 Dart 侧知道（构建期无从得知），故在求值
    // runtime.js 之前以顶层全局注入，产物里裸引用 `kDebugMode` / `Platform`
    // 与 Dart 一比一。
    _eval(_jsUiEnvSource(), 'jsUiEnv');
    final asset = _runtimeAssetNear(moduleAsset);
    final source = await _readModule(asset, localRoot);
    // runtime.js 也是补丁资源，同样登记其自身携带的协议版本。
    _recordResourceProtocol(asset, source);
    final result = _eval(source, asset);
    final text = result.stringResult;
    if (result.isError ||
        text.startsWith('ERROR:') ||
        text.contains('\nERROR:')) {
      throw StateError('$asset evaluate failed: $text');
    }
    _jsUiInited = true;
    _evalExternalLibraryFragments();
  }

  /// 运行时产物在补丁根目录下的文件名（与 `patch/<package>.js` 同级）。
  static const String runtimeJsAsset = 'runtime.js';

  /// 运行时产物路径：优先跟随**当前模块所在补丁根目录**。
  ///
  /// 组件的入口可能是 `assets/patch/components/x.js`（asset 场景），也可能是
  /// 网络包解压后的 `components/x.js`（localRoot 场景）。两者向上找到 `patch/`
  /// 这一层，再把文件名换成 [runtimeJsAsset]——不需要任何配置或映射表。
  static String _runtimeAssetNear(String? moduleAsset) {
    if (moduleAsset == null) return runtimeJsAsset;
    const marker = 'patch/';
    final i = moduleAsset.lastIndexOf(marker);
    if (i < 0) return runtimeJsAsset;
    return '${moduleAsset.substring(0, i + marker.length)}$runtimeJsAsset';
  }

  /// App 在 `runApp` 前 `registerJsUiLibrary(...)` 注册的**外部能力**片段。
  ///
  /// 内建能力的 JS 已随 `runtime.js` 发布（其 `jsFragments` 为空），这里只处理
  /// 外部库新增的片段。它们无法再访问核心 IIFE 的闭包内部函数（`registerScope`
  /// 等），只能使用全局出口 `__jsui` / `_app_host_`；需要内核能力的库应改为随
  /// 补丁发布（写进 `runtime.js`）。
  void _evalExternalLibraryFragments() {
    for (final library in jsUiLibraries) {
      for (final fragment in library.jsFragments) {
        _eval('(function () {\n$fragment\n})();', 'library:${library.id}');
      }
    }
  }

  /// 编译期标志：`kDebugMode` / `kReleaseMode` / `Platform.isXxx`，与 Dart
  /// 产物里的裸引用同名（`globalThis` 属性即全局变量）。
  String _jsUiEnvSource() => '''
(function () {
  var G = typeof globalThis !== 'undefined' ? globalThis : this;
  G.kDebugMode = $kDebugMode;
  G.kReleaseMode = $kReleaseMode;
  G.Platform = {
    isAndroid: ${defaultTargetPlatform == TargetPlatform.android},
    isIOS: ${defaultTargetPlatform == TargetPlatform.iOS},
    isMacOS: ${defaultTargetPlatform == TargetPlatform.macOS},
    isWindows: ${defaultTargetPlatform == TargetPlatform.windows},
    isLinux: ${defaultTargetPlatform == TargetPlatform.linux},
    isFuchsia: ${defaultTargetPlatform == TargetPlatform.fuchsia}
  };
})();
''';

  // ---------------------------------------------------------------------
  // 模块加载器（ES module 支持）
  // ---------------------------------------------------------------------
  //
  // flutter_js 0.8.7 只有 evaluate（无原生 import/export 求值），因此这里
  // 做文本级模块加载：把产物的 import/export 预处理成脚本模式——
  //   - `export class X {...}`   -> `class X {...}`（收集导出名）
  //   - `import { A } from 'rel'` -> `const { A } = __modules['<abs>'];`
  //   - 模块尾部注册 `__modules['<jsAsset>'] = { X };`（JS 侧全局表，
  //     跨 evaluate 共享）
  // 依赖按相对路径递归加载（JsAssetResolver），同一 jsAsset 只执行一次。

  /// 模块加载：递归加载 import 依赖（先依赖后自身），再把自身预处理后
  /// evaluate 进 JS 全局（__modules 注册）。幂等：同 jsAsset 只执行一次。
  Future<void> loadModule(String jsAsset, {String? localRoot}) async {
    if (jsAsset.isEmpty) {
      return;
    }
    // 已加载成功 → 短路。注意：只有**完整成功**才进 _loadedModules，
    // 失败（asset 缺失 / evaluate 出错）可再次重试。
    if (_loadedModules.contains(jsAsset)) {
      return;
    }
    // 加载中（防依赖环 + 防并发竞争）→ 复用首个加载的 completer，等它完成
    // 后再继续。同屏多个 JsUiWidget 用同一 manager 时，会并发调用 loadModule，
    // 若直接 return，后续 widget 的 __jsui.mount 会在模块注册前执行 →
    // 找不到组件 → _rootId 为 null → 一直显示进度条。
    //
    // 「加载中」只由 [_loadingCompleters] 是否含该 key 表达；owner 用**本地
    // 变量**持有自己的 completer，结算前用 identical 校验仍归自己所有。
    // **不能**复读 `_loadingCompleters[jsAsset]!`：远程包 fresh 时双实例各自
    // 调一次 invalidateModules、同 key 也会被另一个 owner 覆盖，复读 + 空断言
    // 会在并发首屏炸「Null check operator used on a null value」。
    final inflight = _loadingCompleters[jsAsset];
    if (inflight != null) {
      return inflight.future;
    }
    final completer = Completer<void>();
    _loadingCompleters[jsAsset] = completer;
    // 无等待者时带错误的 Future 会报「未捕获异常」；挂忽略监听消除该噪声，
    // 各等待者仍从自己拿到的 `inflight.future` 收到同一错误。
    completer.future.ignore();
    try {
      // 网络补丁包：localRoot（URL 哈希本地唯一根目录）+ 虚拟路径拼出本地
      // 文件，存在即读本地，不存在回退内置 asset（rootBundle）。不维护任何
      // 映射表——文件系统即索引，与 asset 场景共用同一套相对 import 逻辑。
      final source = await _readModule(jsAsset, localRoot);
      final base = jsAsset.substring(0, jsAsset.lastIndexOf('/') + 1);

      // 1) 递归加载 import 依赖（相对路径，以当前模块目录为基准）
      for (final (_, rel) in _parseImports(source)) {
        final dep = JsAssetResolver.resolve(base, rel);
        await loadModule(dep, localRoot: localRoot);
      }

      // 2) 模块产物求值前确保运行时骨架（runtime.js：环境全局 __modules /
      //    标志 / console / reconciler）已加载 —— 幂等。
      await ensureJsUiRuntime(localRoot: localRoot, moduleAsset: jsAsset);

      // 3) 预处理（export class -> class + 尾部注册；import -> __modules 解构）
      //    后求值
      final processed = _preprocessModule(source, jsAsset, base);
      final evalResult = _runtime.evaluate(processed);
      // 模块被包进 IIFE，完成值恒为 undefined（真正的作用是 __modules
      // 注册这一副作用），因此返回值只在**出错**时有诊断价值——正常路径
      // 不再打印，成功由下面的 `module loaded` 体现。
      final text = evalResult.stringResult;
      if (evalResult.isError ||
          text.startsWith('ERROR:') ||
          text.contains('\nERROR:')) {
        HotPatchLog.error('module eval failed: $jsAsset: $text');
        // evaluate 把异常序列化进返回值 → 视为加载失败，不进
        // _loadedModules，下次可重试。
        throw StateError('module evaluate failed: $text');
      }
      _loadedModules.add(jsAsset);
      // 登记该资源自身携带的协议版本（可能与其他资源不同），供上层按资源读取。
      _recordResourceProtocol(jsAsset, source);
      // 不逐条打日志：一个页面连带依赖可能有几十个模块（model/xxx.js、flutter.js…），
      // 逐条会把「进入页面」的日志刷满。只记进本批次清单，由页面加载流程结束时
      // 一次性取走汇总（见 [drainLoadedModules]）。
      _loadedInBatch.add(jsAsset);
      _settleModule(jsAsset, completer);
    } catch (e, s) {
      // 读文件 / 依赖加载 / 求值任一失败：owner 与全部等待者一起拿到该异常
      // （可重试），不把等待者永久悬空。
      _settleModule(jsAsset, completer, error: e, stackTrace: s);
      rethrow;
    }
  }

  /// 结算本 owner 的模块加载（成功 / 失败统一走这里）。
  ///
  /// 只有表里那条**仍是本次登记的 completer** 时才摘除并结算：被
  /// [invalidateModules] 清理、或被另一个 owner 覆盖时静默返回——既不误结算
  /// 他人，也不对已被摘除的条目做空断言。
  void _settleModule(
    String jsAsset,
    Completer<void> completer, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!identical(_loadingCompleters[jsAsset], completer)) return;
    _loadingCompleters.remove(jsAsset);
    if (completer.isCompleted) return;
    if (error != null) {
      completer.completeError(error, stackTrace);
    } else {
      completer.complete();
    }
  }

  /// 读取模块源码：网络补丁（[localRoot] 非空）时用「本地根 + 虚拟路径」
  /// 拼文件路径，判断存在读本地；否则回退内置 asset。
  Future<String> _readModule(String jsAsset, String? localRoot) async {
    if (localRoot != null) {
      final file = File('$localRoot/$jsAsset');
      if (file.existsSync()) return file.readAsString();
    }
    return rootBundle.loadString(jsAsset);
  }

  /// 解析模块源码里的 import 语句：`import { A, B } from 'rel';`
  /// -> [(['A','B'], 'rel')]。只匹配生成器产物的单行 import 形态。
  static List<(List<String>, String)> _parseImports(String source) {
    final re = RegExp(
      r"import\s*\{([^}]+)\}\s*from\s*[\x27\x22]([^\x27\x22]+)[\x27\x22]\s*;",
    );
    return [
      for (final m in re.allMatches(source))
        (
          m.group(1)!
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
          m.group(2)!,
        ),
    ];
  }

  /// 文本级预处理：export class -> class + 尾部 __modules 注册；
  /// import 语句 -> `const { A, B } = __modules['<解析后绝对路径>'];`。
  /// 模块注册 key 与实例化寻址都用**绝对资产路径**（assets/...），
  /// 与 JsUiWidget 的 jsAsset 一致。
  static String _preprocessModule(
    String source,
    String jsAsset,
    String base,
  ) {
    var out = source;

    // export class/const/function -> class/const/function（收集导出名，同名模块去重）。
    // 扩展支持共享单例产物（export const X = {...}，如静态颜色类）与 export function。
    // 分类型替换，避免 'const' 被误换成 'class'。
    final exportReClass = RegExp(r"^export\s+class\s+(\w+)", multiLine: true);
    final exportReVar =
        RegExp(r"^export\s+(const|function)\s+(\w+)", multiLine: true);
    final exportNames = <String>[
      for (final m in exportReClass.allMatches(out)) m.group(1)!,
      for (final m in exportReVar.allMatches(out)) m.group(2)!,
    ];
    out = out.replaceAllMapped(exportReClass, (m) => 'class ${m.group(1)}');
    out = out.replaceAllMapped(
        exportReVar, (m) => '${m.group(1)} ${m.group(2)}');

    // import { A, B } from 'rel' -> const { A, B } = __modules['abs'];
    final importRe = RegExp(
      r"import\s*\{[^}]+\}\s*from\s*[\x27\x22][^\x27\x22]+[\x27\x22]\s*;",
    );
    out = out.replaceAllMapped(importRe, (m) {
      final inner = m.group(0)!;
      final namesMatch = RegExp(r"\{([^}]+)\}").firstMatch(inner)!;
      final relMatch =
          RegExp(r"from\s*[\x27\x22]([^\x27\x22]+)[\x27\x22]").firstMatch(inner)!;
      final names = namesMatch
          .group(1)!
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final abs = JsAssetResolver.resolve(base, relMatch.group(1)!);
      return "const { ${names.join(', ')} } = __modules['$abs'];";
    });

    // 模块尾部注册导出：__modules['jsAsset'] = { A, B };
    if (exportNames.isNotEmpty) {
      out += "\n__modules['$jsAsset'] = { ${exportNames.join(', ')} };";
    }

    // 整体包进 IIFE：class / const 声明局部化。flutter_js（iOS
    // JavaScriptCore）多次 evaluate 共享**全局词法环境**——顶层 class、
    // const 声明跨 evaluate 持久且同名重复声明会抛
    // `Can't create duplicate variable`（如 user 模块的 class User 与
    // 组件模块的 const { User } 冲突）。IIFE 内声明互不干扰，
    // 只有 var 全局表（__modules）跨 evaluate 可见。
    return '''
(function() {
$out
})();''';
  }

  /// 宿主侧已加载模块缓存（防重复加载/递归环）。
  final Set<String> _loadedModules = {};

  /// 各资源自身的产物协议版本（解析自 JS 产物首行协议头 `// @hot_patch
  /// protocol: x.y.z`）。
  ///
  /// 按**资源**登记而不是全局共用一个值：同一页面可能混用不同来源（远端 zip、
  /// 内置 asset 回退）与不同批次打出的产物，版本可以各不相同。这里只负责
  /// 「当前资源对应哪个版本」的读取，兼容判定由上层决定。
  final Map<String, String> _resourceProtocols = {};

  /// 单个资源的产物协议版本；该资源未加载 / 老产物无协议头时为 null。
  String? protocolOf(String jsAsset) => _resourceProtocols[jsAsset];

  /// 已加载资源的协议版本快照（排查「同页混用不同版本资源」用）。
  Map<String, String> get resourceProtocols => Map.unmodifiable(_resourceProtocols);

  /// 资源首行协议头里的版本；无协议头返回 null。
  static final RegExp _protocolHeader = RegExp(
    r'^//\s*@hot_patch\s+protocol:\s*(\S+)\s*$',
  );

  static String? _readProtocolHeader(String source) {
    final end = source.indexOf('\n');
    final firstLine = end < 0 ? source : source.substring(0, end);
    return _protocolHeader.firstMatch(firstLine)?.group(1);
  }

  /// 登记资源自身携带的协议版本；无协议头的老产物清掉可能残留的旧值。
  void _recordResourceProtocol(String jsAsset, String source) {
    final protocol = _readProtocolHeader(source);
    if (protocol == null) {
      _resourceProtocols.remove(jsAsset);
    } else {
      _resourceProtocols[jsAsset] = protocol;
    }
  }

  /// 最近一批新加载成功的模块路径（顺序即加载顺序：依赖先于自身）。
  ///
  /// 只记录、不打印——页面进入时可能连带几十个模块，逐条日志会把其它信息淹没。
  /// 由页面加载流程在结束时 [drainLoadedModules] 取走并汇总成一条；多实例共用同一
  /// manager 时先取走的那个实例会带上全部（模块本身幂等，不会重复计入）。
  final List<String> _loadedInBatch = [];

  /// 取走并清空「本批次已加载模块」清单（调用方负责汇总成一条日志）。
  List<String> drainLoadedModules() {
    final out = List<String>.of(_loadedInBatch);
    _loadedInBatch.clear();
    return out;
  }

  /// 清除所有已加载模块缓存（远程 zip 更新后调用，强制下次重新 evaluate）。
  /// 同时清空 JS 侧 `__modules` 表——依赖模块（flutter.js / provider.js 等）
  /// 下次也会重新加载，避免拿到旧类引用。
  ///
  /// **不清 [_loadingCompleters]**：in-flight 加载各由自己的 owner 用本地
  /// completer 持有，清表会让等待者失去结算对象（旧实现即由此在并发首屏炸
  /// 空断言）；保留后等待者仍等这次加载完成，且不会重复 evaluate 同一产物。
  ///
  /// **重置运行时标记**：新包里可能带**新版 `runtime.js`**（JS 修复随产物发布），
  /// 下一次 [loadModule] 必须重新求值它。runtime.js 内部按内容哈希判断版本，
  /// 哈希不同就原地重建整个 `__jsui`（同一进程内生效），哈希相同则短路
  /// （不重复初始化、不丢状态）。
  void invalidateModules() {
    _loadedModules.clear();
    // 资源协议版本随模块缓存一起作废：重新加载的那批会按新产物重新登记。
    _resourceProtocols.clear();
    _jsUiInited = false;
    // 清单一并清空：清缓存后重新加载的那批，重新累计到下一个批次汇总里。
    _loadedInBatch.clear();
    // 清空 JS 侧模块注册表：下次 import 解构时 __modules['path'] 为空，
    // loadModule 会重新执行该模块代码并重新注册。
    _eval('''
      (function() {
        if (typeof __modules === 'object' && __modules) {
          for (var k in Object.keys(__modules)) { delete __modules[k]; }
        }
      })();
    ''', 'invalidateModules');
  }
  /// 并发加载等待表：同 jsAsset 正在加载时，后续调用者 await 对应
  /// Completer，等首个加载完成后再继续（防 mount 在模块加载前执行）。
  final Map<String, Completer<void>> _loadingCompleters = {};

  /// 桥通道回调：解出消息体 `ch` 字段，二次分发到唯一处理器表。
  ///
  /// 信封格式（JS 侧 `_app_host_.invoke` / 内部 `send` 产出）：
  ///   `{ ch: <逻辑通道名>, data: {id, args} }`
  ///
  /// `ch` 定位通道；`data` 交给对应处理器（[registerHostMethod] 的包装按
  /// `{id, args}` 还原 Dart 调用语义）。因为处理器表是 static 全局唯一的，
  /// 无论消息路由到哪个 manager 的 runtime，都能找到正确处理器。
  ///
  /// **未注册通道必须在这里回填**：JS 侧 `_app_host_.invoke` 已经为该 id 建好
  /// 一条 pending，丢弃相当于既不 resolve 也不 reject——Promise 永久悬空、
  /// 条目永久滞留在 JS 的表里（宿主侧也没有第二处能认领这个 id）。按「方法
  /// 不存在」处理：留一条日志 + 回填 null 收尾。
  void _dispatch(dynamic raw) {
    if (raw is! Map) return;
    final channel = raw['ch']?.toString() ?? '';
    if (channel.isEmpty) return;
    final handler = globalMessageHandlers[channel];
    if (handler == null) {
      final data = raw['data'];
      final id = data is Map ? data['id']?.toString() : null;
      HotPatchLog.warn('未注册的宿主通道 "$channel"（id=${id ?? '-'}）：回填 null 收尾');
      _settleHost(id, value: null);
      return;
    }
    handler(raw['data']);
  }
}

/// JS 求值失败（[JsRuntimeManager.evaluateOrThrow]）。
///
/// [toString] 直接给出可展示的诊断信息——不带 `Bad state:` 之类框架前缀，
/// 因为它会被直接投进 UI 的错误兜底视图。
class JsEvalException implements Exception {
  const JsEvalException(this.message);

  final String message;

  @override
  String toString() => message;
}
