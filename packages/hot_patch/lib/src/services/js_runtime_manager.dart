import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode, kReleaseMode, defaultTargetPlatform;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_js/flutter_js.dart';

import '../utils/js_asset_resolver.dart';
import '../js_ui/runtime_source.dart';
import 'native_service.dart';
import '../utils/hot_patch_log.dart';

/// JS 运行时管理器：与底层 [JavascriptRuntime] **一对一**。
///
/// [debugMode] 控制 JS 侧 `kDebugMode` 标志（console.debug 是否输出）：
/// 默认跟随 Dart `kDebugMode`，测试/灰度可显式覆盖。
///
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
/// ## 消息通道：单一桥通道 `_app_bridge_` + 两套处理器表
///
/// JS → Flutter 的所有消息都打到**唯一的桥通道** `_app_bridge_`，消息体里
/// 用 `ch` 字段标示目标逻辑通道：
///
///   sendMessage('_app_bridge_', JSON.stringify({ ch: 'jsuiCommit', key, data }))
///
/// 本类在**构造时**用 `_runtime.onMessage('_app_bridge_', _dispatch)` 订阅一次，
/// [_dispatch] 再按 `ch` 二次分发到 [globalMessageHandlers] /
/// [pageMessageHandlers]。因此**注册与订阅完全解耦**：处理器可以在任何时机
/// 注册（包括第一个 manager 出现之前，如 main() 里直接调用），不需要「补接线」，
/// 也不会出现「channel 未接线 → No channel xxx registered」。
/// [evaluate] 是纯求值入口，不掺注册副作用。
///
/// **对外扩展只有三种能力：实现 [NativeService]（channel + handle）用
/// [registerGlobal]（全局级）注册；用 [registerRawPageHandler] 注册一个
/// 与页面 key 绑定、不需要 BuildContext 的裸通道处理器（如 js_ui 的 commit）；
/// 或用 [registerHostMethod] 注册一个 @HostInjected 宿主注入方法（全局级，
/// JS 侧 `__jsui.host` 调用、宿主实现并回填结果）。**
///
/// ### 页面级 [pageMessageHandlers]（跟页面 key 绑定）
///
/// 例：js_ui 的 commit（把 JS 算好的增量补丁交给宿主应用）。
/// 消息**必须携带页面 key**：`ch: 'jsuiCommit', key: 'jsui_1'`。
/// 分发：`pageMessageHandlers[key]?[channel]`；key 形如 `主key::组件`
/// （嵌套实例）时 miss 回退主 key。页面销毁用 [dispose] 一次性移除
/// 该 key 下的全部注册。
///
/// ### 全局级 [globalMessageHandlers]（与页面无关）
///
/// 例：日志、toast。全局一份处理器，不需要页面 key 隔离。
/// 消息不带 key，或页面级查不到时回退到这里。
/// 全局 handler 的 context 由 [navigatorKey] 提供。
///
/// ### 分发规则（统一）
///
/// 1. 消息带 key → 先查页面级（`key`，miss 回退 `key.split('::').first`）；
/// 2. 页面级查不到或消息不带 key → 查全局级。
///
/// [pageMessageHandlers] / [globalMessageHandlers] 必须是 static 全局唯一：
/// flutter_js 0.8.7（iOS/JavaScriptCore）的消息桥是库级全局的，
/// `sendMessage` 的 Dart 回调是 static 字段（由最后创建的 runtime 覆盖
/// 赋值），通道表也是 static Map（key=engineId）。若处理器表是实例级的，
/// 消息到达某个 manager 的通道回调后查不到属于另一个 manager 的页面
/// key，就会串台/丢消息。
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
  /// 协议常量：由生成器 `ui_component_generator` 产出（其 `hostPositionalKey`
  /// 是同一个值），运行时在这里解析。`@` 不是合法的 Dart 标识符字符，故不会
  /// 与任何具名形参重名，判定无歧义。
  static const String hostPositionalKey = '@args';

  /// 所有活跃 manager（static 跟踪）：[registerHostMethod] 的返回值回填
  /// （`__jsui.resolve`）需要对每个 runtime 求值一次。
  static final Set<JsRuntimeManager> _instances = {};

  /// JS 侧 `kDebugMode` 标志（console.debug 是否输出）：
  /// 默认跟随 Dart [kDebugMode]，可显式覆盖（如灰度环境强制关闭调试日志）。
  bool debugMode = kDebugMode;

  // ---------------------------------------------------------------------
  // 全局共享（static）：两套消息处理器表
  // ---------------------------------------------------------------------

  /// 页面级处理器表（全局唯一）：页面 key → (方法 → 处理器)。
  /// [registerRawPageHandler] 注册的处理器在这里；页面销毁时 [dispose] 移除。
  static final Map<String, Map<String, void Function(dynamic args)>>
      pageMessageHandlers = {};

  /// 全局级处理器表（全局唯一）：方法 → 处理器。
  /// [registerGlobal] 注册的服务在这里，全局一份。
  static final Map<String, void Function(dynamic args)> globalMessageHandlers =
      {};

  /// 注册一个**全局级** [NativeService]（与页面无关，全局一份）。
  ///
  /// 例：日志、toast。JS 经桥通道发 `ch` = [NativeService.channel] 触发；
  /// handle 的 context 由框架取 [navigatorKey] 提供。
  /// 只写处理器表——桥通道在 manager 构造时已订阅，无需接线。
  static void registerGlobal(NativeService service) {
    globalMessageHandlers[service.channel] = (dynamic args) {
      final ctx = navigatorKey?.currentContext;
      if (ctx == null || !ctx.mounted) {
          HotPatchLog.log('${service.channel} ignored: '
            'navigatorKey not configured / context not ready');
        return;
      }
      service.handle(ctx, args);
    };
  }

  /// 注册一个页面级**裸通道处理器**（不走 [NativeService]）。
  ///
  /// 供不需要 BuildContext 的运行时装使用（如 js_ui 的 `jsuiCommit`：只把
  /// JS 下发的补丁交给宿主应用，与页面上下文无关）。
  /// JS 经桥通道发 `ch` = [channel] + 页面 key 触发。
  /// 只写处理器表——桥通道在 manager 构造时已订阅，无需接线。
  static void registerRawPageHandler(
    String pageKey,
    String channel,
    void Function(dynamic args) handler,
  ) {
    (pageMessageHandlers[pageKey] ??= {})[channel] = handler;
  }

  /// 注册一个**宿主注入方法**（@HostInjected 通道）。
  ///
  /// 生成器把 Dart 的 static 方法调用（`AccountCenter.getUserName(a)`）在
  /// 调用点翻译为 JS 侧 `__jsui.host("通道名", 参数载荷)`（返回 Promise，可
  /// await；载荷按实参形态给数组/对象，见 [_hostCallArgs]）。本方法把该通道接到
  /// 宿主实现 [impl]：收到 JS 的 `{id, key, args}` 后按
  /// `Function.apply(impl, 位置实参, 具名实参)` 调用——Dart 调用语义完整还原，
  /// 位置/具名实参**个数不限**，未传的参数走实现自身的默认值，返回值类型也不限。
  /// 之后把返回值经 `__jsui.resolve(id, value)` 回填 JS 的 Promise。
  ///
  /// 与页面无关（全局一份）；通道名即 @HostInjected 注解里的名称
  /// （缺省为方法名）。只写处理器表——桥通道在 manager 构造时已订阅。
  /// 通道名需唯一：debug 下重复注册会触发断言失败。
  static void registerHostMethod(String channel, Function impl) {
    // debug 阶段消灭重复：同一通道注册两次（如两个方法用了同一个 @HostInjected
    // 通道名）会静默覆盖前一个实现，JS 侧调到的实现与预期不符且无从察觉。
    // 断言让问题在启动时立刻暴露。通道名与 registerGlobal 的 service.channel
    // 共用一张全局表，故本条同时拦住这两类撞名。
    assert(
      !globalMessageHandlers.containsKey(channel),
      'registerHostMethod: 通道 "$channel" 已被注册——'
      '通道名必须唯一（重复注册会静默覆盖前一个实现）',
    );
    globalMessageHandlers[channel] = (dynamic args) async {
      final map = args is Map ? args : const {};
      final id = map['id']?.toString();
      final (positional, named) = _hostCallArgs(map['args']);
      Object? value;
      try {
        value = await Function.apply(impl, positional, named);
      } catch (e, s) {
        // 不静默：实现调用失败若悄悄回填 null，JS 侧只看到「结果是 null」，
        // 完全不知道宿主侧压根没调成功（具名参数不匹配就是这样被吞掉的）。
        HotPatchLog.log(
          'registerHostMethod("$channel") 调用宿主实现失败: $e\n$s',
        );
        value = null;
      }
      if (id == null || id.isEmpty) return;
      // resolve 挂在 JS 全局（__jsui），对每个活跃 runtime 求值一次：
      // 持有该 id 的 runtime 回填 Promise，其余为 no-op。
      final code = '__jsui.resolve("$id", ${jsonEncode(value)});';
      for (final m in _instances.toList()) {
        m._eval(code, '__jsui.resolve');
      }
    };
  }

  /// JS 宿主调用的参数载荷 → (`位置实参`, `具名实参`)。
  ///
  /// 生成器（见 `__jsui.host`）按实参形态给三种编码，这里对称解析：
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

  /// 移除页面 key 下的**全部**页面级注册（页面销毁时调用）。
  ///
  /// JS 侧的根（结点树 / provider / 订阅）由 JsUiWidget 先调
  /// `__jsui.dispose(pageKey)` 释放，本方法只负责回收 Dart 侧 handler 表。
  static void dispose(String pageKey) {
    pageMessageHandlers.remove(pageKey);
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
      HotPatchLog.log(
        'JS eval failed [$where]: ${result.stringResult} | code: $brief',
      );
    }
    return result;
  }

  /// 确保 js_ui 运行时骨架就位（幂等）。
  ///
  /// 注入两块**框架代码**（均在 `js_ui/runtime_source.dart` 集中维护）：
  ///   - `jsUiRuntimeSource`：element/component/reconciler/context + commit 协议；
  ///   - `jsRuntimeEnvSource`：模块表 `__modules`、编译/平台标志、console 桥、
  ///     ChangeNotifier 基类。
  /// 与具体组件无关；组件/模型/按 package 生成的 widget 模块仍走 [loadModule]。
  void ensureJsUiRuntime() {
    if (!_jsUiInited) {
      _eval(jsUiRuntimeSource, 'jsUiRuntimeSource');
      _jsUiInited = true;
    }
    _ensureRuntimeEnv();
    // 模块表初始化可能新建 __modules：每次确保 core 指向同一个 api。
    _eval(
      "typeof __jsui !== 'undefined' && typeof __modules !== 'undefined' "
      "&& (__modules['js_ui/core'] = __jsui);",
      'js_ui/core',
    );
  }

  /// 注入运行时环境全局（模块表 / 标志 / console / ChangeNotifier），幂等。
  /// 依赖 Dart 侧标志，故由 [jsRuntimeEnvSource] 生成；[loadModule] 与
  /// [ensureJsUiRuntime] 都会调用它，保证模块产物求值前全局已就位。
  void _ensureRuntimeEnv() {
    if (_envInited) {
      return;
    }
    _eval(
      jsRuntimeEnvSource(
        debugMode: debugMode,
        releaseMode: kReleaseMode,
        platform: defaultTargetPlatform,
      ),
      'jsRuntimeEnvSource',
    );
    _envInited = true;
  }

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
    // 加载中（防依赖环 + 防并发竞争）→ 等待首个加载完成后再继续。
    // 同屏多个 JsUiWidget 用同一 manager 时，会并发调用 loadModule，
    // 若直接 return，后续 widget 的 __jsui.mount 在模块注册前执行 →
    // 找不到组件 → _rootId 为 null → 一直显示进度条。
    if (_loadingModules.contains(jsAsset)) {
      return _loadingCompleters[jsAsset]!.future;
    }
    _loadingModules.add(jsAsset);
    _loadingCompleters[jsAsset] = Completer<void>();
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

    // 2) 模块产物求值前确保运行时环境全局（__modules / 标志 / console /
    //    ChangeNotifier）已注入 —— 与 js_ui 骨架同源维护，幂等。
    _ensureRuntimeEnv();

    // 3) 预处理（export class -> class + 尾部注册；import -> __modules 解构）后求值
    try {
      final processed = _preprocessModule(source, jsAsset, base);
      final evalResult = _runtime.evaluate(processed);
      // 模块被包进 IIFE，完成值恒为 undefined（真正的作用是 __modules
      // 注册这一副作用），因此返回值只在**出错**时有诊断价值——正常路径
      // 不再打印，成功由下面的 `module loaded` 体现。
      final text = evalResult.stringResult;
      if (evalResult.isError ||
          text.startsWith('ERROR:') ||
          text.contains('\nERROR:')) {
        HotPatchLog.log('module eval failed: $jsAsset: $text');
        // evaluate 把异常序列化进返回值 → 视为加载失败，不进
        // _loadedModules，下次可重试。
        throw StateError('module evaluate failed: $text');
      }
      _loadedModules.add(jsAsset);
      HotPatchLog.log('module loaded: $jsAsset');
      _loadingCompleters[jsAsset]!.complete();
    } catch (e) {
      _loadingCompleters[jsAsset]!.completeError(e);
      rethrow;
    } finally {
      _loadingModules.remove(jsAsset);
      _loadingCompleters.remove(jsAsset);
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
  final Set<String> _loadingModules = {};
  /// 并发加载等待表：同 jsAsset 正在加载时，后续调用者 await 对应
  /// Completer，等首个加载完成后再继续（防 mount 在模块加载前执行）。
  final Map<String, Completer<void>> _loadingCompleters = {};

  /// 运行时环境全局（__modules / 标志 / console / ChangeNotifier）是否已注入。
  bool _envInited = false;

  /// 桥通道回调：解出消息体 `ch` 字段，二次分发到两套 static 全局表。
  ///
  /// 信封格式（JS 侧 `__appSend` 产出）：
  ///   `{ ch: <逻辑通道名>, data: <原有消息体>, key?: <页面key> }`
  ///
  /// 分发规则（见类注释）：`key` 定位页面层（miss 回退主 key），`ch`
  /// 定位方法层；页面级查不到或无 key 时回退全局级。因为处理器表是 static
  /// 全局唯一的，无论消息路由到哪个 manager 的 runtime，都能找到正确处理器。
  void _dispatch(dynamic raw) {
    if (raw is! Map) return;
    final channel = raw['ch']?.toString() ?? '';
    if (channel.isEmpty) return;
    final data = raw['data'];
    var key = raw['key']?.toString() ?? '';
    // 兼容：页面 key 也可能放在消息体内（生成器产出的 native 通道）。
    if (key.isEmpty && data is Map && data['key'] != null) {
      key = data['key'].toString();
    }
    void Function(dynamic args)? handler;
    if (key.isNotEmpty) {
      final mainKey = key.split('::').first;
      handler =
          (pageMessageHandlers[key] ?? pageMessageHandlers[mainKey])?[channel];
    }
    handler ??= globalMessageHandlers[channel];
    handler?.call(data);
  }
}
