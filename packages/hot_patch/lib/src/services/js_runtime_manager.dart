import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_js/flutter_js.dart';

import '../utils/js_asset_resolver.dart';
import 'native_service.dart';

/// JS 运行时管理器：与底层 [JavascriptRuntime] **一对一**。
///
/// 每个 [JsRuntimeManager] 内部持有一个 [JavascriptRuntime]，所有与
/// JavascriptRuntime 相关的操作（创建、求值、通道注册、生命周期）都在
/// 本类内部消化；HotPatchWidget 等使用方只接触 [JsRuntimeManager]，
/// 完全不感知底层运行时对象。
///
/// - **默认实例**：使用 [instance]（全局唯一，static 共享）。大多数场景
///   直接用默认实例即可，多个 HotPatchWidget 共享同一个 JS 环境。
/// - **分组隔离**：业务方可以 `JsRuntimeManager()` 自行创建实例，把同一
///   个实例传给一组 HotPatchWidget（共享该组的 JS 状态），与其他组的
///   状态互不影响。
/// - **生命周期**：默认实例由本类持有（app 生命周期内常驻）；
///   业务方自建的实例由业务方管理（不再需要时置空引用即可，
///   不要 dispose 底层 runtime，避免其他仍在使用该 runtime 的组件失效）。
///
/// ## 消息通道：统一由 [NativeService] 注册
///
/// JS → Flutter 的所有消息统一走「通道注册 + 两套处理器表」。
/// **对外扩展只有一种能力：实现 [NativeService]（channel + handle），
/// 用 [register]（页面级）或 [registerGlobal]（全局级）注册。**
/// 框架内部机制（如 setState）同样实现为 NativeService，由
/// HotPatchWidget 的页面级内部实现列表统一 [register]，不设特例方法。
///
/// **通道接线只由注册动作驱动**：每次 [register] / [registerGlobal] 都会把
/// 对应 channel 注册到**所有活跃 manager** 的 runtime 上（幂等）——
/// 注册的处理器一定有回调可路由，不会出现「通道没注册 → 消息黑洞」。
/// 新建 manager 无需补历史通道：它的第一次 register 就把自己接上线。
/// 不在构造/求值时单独接线：没有 handler 的接线毫无意义。
/// [evaluate] 是纯求值入口，不掺注册副作用。
///
/// ### 页面级 [pageMessageHandlers]（跟页面 key 绑定）
///
/// 例：setState、绑定页面状态的内部实现、页面隔离的服务。
/// 消息**必须携带页面 key**：`sendMessage(channel, { key: 'hp_123', ... })`。
/// 分发：`pageMessageHandlers[key]?[channel]`；key 形如 `主key::组件`
/// （嵌套实例）时 miss 回退主 key。页面销毁用 [dispose] 一次性移除
/// 该 key 下的全部注册。
/// 页面级 handler 的 context 由 InstanceNativeService 自持
/// （[InstanceNativeService.state] 的 context），本类不持有 BuildContext。
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

  /// 所有活跃 manager（static 跟踪）：注册处理器时对所有实例接线通道。
  static final Set<JsRuntimeManager> _instances = {};

  // ---------------------------------------------------------------------
  // 全局共享（static）：两套消息处理器表
  // ---------------------------------------------------------------------

  /// 页面级处理器表（全局唯一）：页面 key → (方法 → 处理器)。
  /// [register] 注册的服务在这里；页面销毁时 [dispose] 移除。
  static final Map<String, Map<String, void Function(dynamic args)>>
      pageMessageHandlers = {};

  /// 全局级处理器表（全局唯一）：方法 → 处理器。
  /// [registerGlobal] 注册的服务在这里，全局一份。
  static final Map<String, void Function(dynamic args)> globalMessageHandlers =
      {};

  /// 为页面 key 注册一个**页面级** [NativeService]。
  ///
  /// 消息 `sendMessage(channel, { key: 页面key, ... })` 触发；
  /// handle 的 context 由服务自身提供：InstanceNativeService 经
  /// [InstanceNativeService.build] 注入页面 state 后取 `state.context`。
  /// **本类不持有任何 BuildContext**（避免页面销毁后的泄漏）。
  /// 注册即接线通道：所有活跃 manager 的 runtime 上都注册该 channel。
  static void register(String pageKey, NativeService service) {
    (pageMessageHandlers[pageKey] ??= {})[service.channel] = (dynamic args) {
      final ctx = service is InstanceNativeService
          ? service.state?.context
          : null;
      if (ctx == null || !ctx.mounted) return;
      service.handle(ctx, args);
    };
    _wireChannel(service.channel);
  }

  /// 注册一个**全局级** [NativeService]（与页面无关，全局一份）。
  ///
  /// 例：日志、toast。消息 `sendMessage(channel, { ... })` 触发；
  /// handle 的 context 由框架取 [navigatorKey] 提供。
  static void registerGlobal(NativeService service) {
    globalMessageHandlers[service.channel] = (dynamic args) {
      final ctx = navigatorKey?.currentContext;
      if (ctx == null || !ctx.mounted) {
        // ignore: avoid_print
        print('[js_runtime_manager] ${service.channel} ignored: '
            'navigatorKey not configured / context not ready');
        return;
      }
      service.handle(ctx, args);
    };
    _wireChannel(service.channel);
  }

  /// 移除页面 key 下的**全部**页面级注册（页面/组件销毁时调用）。
  static void dispose(String pageKey) {
    pageMessageHandlers.remove(pageKey);
  }

  /// 内部：把 channel 接线到**所有活跃 manager** 的 runtime。
  ///
  /// 只接本次注册的 channel（per-manager 幂等）。新 manager 不需要补
  /// 历史通道——它自己的第一次 register 就会把自己接上线；
  /// 只 evaluate 不注册时本就不该有接线（没有 handler 的接线是浪费）。
  static void _wireChannel(String channel) {
    for (final m in _instances) {
      m._ensureChannels([channel]);
    }
  }

  // ---------------------------------------------------------------------
  // 实例状态：与 JavascriptRuntime 一对一
  // ---------------------------------------------------------------------

  /// 本 manager 独占的底层运行时（对外不可见，全部内部消化）。
  final JavascriptRuntime _runtime = getJavascriptRuntime();

  /// 本 manager 已注册的通道（per-manager × channel 一次）。
  final Set<String> _wiredChannels = {};

  JsRuntimeManager() {
    _instances.add(this);
    // 注意：不在构造时接线。通道接线完全由 register/registerGlobal 驱动
    // （_wireChannel 接到所有活跃 manager）——新 manager 的第一次 register
    // 就把自己接上线；只 evaluate 不注册时不接线（没有 handler 的接线是浪费）。
  }

  /// 所有 JS 求值的统一入口（纯求值，无注册副作用）。
  /// code 内部应带实例 key 寻址，如 `__instances["hp_x"].method()`。
  JsEvalResult evaluate(String code) => _runtime.evaluate(code);

  // ---------------------------------------------------------------------
  // 模块加载器（ES module 支持）
  // ---------------------------------------------------------------------
  //
  // flutter_js 0.8.7 只有 evaluate（无原生 import/export 求值），因此这里
  // 做文本级模块加载：把产物的 import/export 预处理成脚本模式——
  //   - `export class X {...}`   -> `class X {...}`（收集导出名）
  //   - `import { A } from 'rel'` -> `const { A } = __modules['<abs>'];`
  //   - 模块尾部注册 `__modules['<jsAsset>'] = { X };`（JS 侧全局表，
  //     跨 evaluate 共享，与旧 __components 同一机制）
  // 依赖按相对路径递归加载（JsAssetResolver），同一 jsAsset 只执行一次。

  /// 模块加载：递归加载 import 依赖（先依赖后自身），再把自身预处理后
  /// evaluate 进 JS 全局（__modules 注册）。幂等：同 jsAsset 只执行一次。
  Future<void> loadModule(String jsAsset) async {
    if (jsAsset.isEmpty) {
      return;
    }
    // 已加载成功 / 加载中（防依赖环）→ 短路。注意：只有**完整成功**才进
    // _loadedModules，失败（asset 缺失 / evaluate 出错）可再次重试。
    if (_loadedModules.contains(jsAsset) || _loadingModules.contains(jsAsset)) {
      return;
    }
    _loadingModules.add(jsAsset);
    final source = await rootBundle.loadString(jsAsset);
    final base = jsAsset.substring(0, jsAsset.lastIndexOf('/') + 1);

    // 1) 递归加载 import 依赖（相对路径，以当前模块目录为基准）
    for (final (_, rel) in _parseImports(source)) {
      final dep = JsAssetResolver.resolve(base, rel);
      await loadModule(dep);
    }

    // 2) 首次加载前初始化 JS 侧全局表（幂等 var 声明）：
    //    __modules = 模块注册表（export class 收集）；__instances = 实例句柄表
    //    （HotPatchWidget 按实例 key 寻址，key 隔离状态互不共享）。
    //    __components 已随 class + import/export 化删除（组件类在模块表里）。
    if (!_moduleTableInited) {
      // typeof 判空（读未声明标识符在部分引擎抛 ReferenceError，
      // 不能直接 `x || {}`）；var 提升保证同脚本内后续语句可见。
      _runtime.evaluate(
        "if (typeof __modules === 'undefined') { var __modules = {}; } "
        "if (typeof __instances === 'undefined') { var __instances = {}; }",
      );
      _moduleTableInited = true;
    }

    // 3) 预处理（export class -> class + 尾部注册；import -> __modules 解构）后求值
    try {
      final processed = _preprocessModule(source, jsAsset, base);
      final evalResult = _runtime.evaluate(processed.code);
      // 组件索引：导出类名 → jsAsset（跨文件组件 / 同文件组件都通过
      // export class 注册进模块表；渲染层 Component 节点按组件名反查，
      // 递归嵌套 HotPatchWidget 不再依赖 JSON 里的 import 字段）。
      for (final name in processed.exports) {
        _componentIndex[name] = jsAsset;
      }
      // ignore: avoid_print
      print('[js_runtime_manager] eval result for $jsAsset: $evalResult');
      // evaluate 返回错误文本（JS 引擎把异常序列化进返回值）→ 视为加载失败，
      // 不进 _loadedModules，下次可重试。
      final text = evalResult.toString();
      if (text.startsWith('ERROR:') || text.contains('\nERROR:')) {
        throw StateError('module evaluate failed: $text');
      }
      _loadedModules.add(jsAsset);
      // ignore: avoid_print
      print('[js_runtime_manager] module loaded: $jsAsset');
    } finally {
      _loadingModules.remove(jsAsset);
    }
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
  /// 模块注册 key 与实例化寻址都用**绝对资产路径**（assets/components/...），
  /// 与 HotPatchWidget 的 jsAsset 一致。
  static ({String code, List<String> exports}) _preprocessModule(
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
    // 只有 var 全局表（__modules/__instances）跨 evaluate 可见。
    return (code: '(function() {\n$out\n})();', exports: exportNames);
  }

  /// 宿主侧已加载模块缓存（防重复加载/递归环）。
  final Set<String> _loadedModules = {};
  final Set<String> _loadingModules = {};

  /// 组件索引：导出类名 → 所在产物 jsAsset。模块加载成功后登记，
  /// 渲染层 Component 节点（无 import 字段）按名反查以递归嵌套渲染。
  final Map<String, String> _componentIndex = {};

  /// 按组件名查它所在产物的 jsAsset（渲染层递归嵌套 HotPatchWidget 用）。
  String? resolveComponentAsset(String component) => _componentIndex[component];

  /// JS 侧模块表是否已初始化。
  bool _moduleTableInited = false;

  /// 注册消息通道（每个 manager × channel 一次，幂等）。
  ///
  /// 通道回调统一查两套 static 全局表分发（规则见类注释）：
  /// 消息 args 的 `key` 定位页面层，通道名定位方法层；页面级 miss 或
  /// 无 key 时回退全局级。因此无论消息路由到哪个 manager 的通道，
  /// 都能找到正确处理器。
  ///
  /// **仅供 register/registerGlobal 内部调用**（经 [_wireChannel]）：
  /// 没有 handler 的通道接线没有意义，外部不得单独调用。
  void _ensureChannels(Iterable<String> channels) {
    for (final channel in channels) {
      if (!_wiredChannels.add(channel)) continue;
      _runtime.onMessage(channel, (dynamic args) {
        final key =
            (args is Map && args['key'] != null) ? args['key'].toString() : '';
        void Function(dynamic args)? handler;
        if (key.isNotEmpty) {
          final mainKey = key.split('::').first;
          handler = (pageMessageHandlers[key] ??
                  pageMessageHandlers[mainKey])?[channel];
        }
        handler ??= globalMessageHandlers[channel];
        if (handler != null) handler(args);
      });
      // ignore: avoid_print
      print('[js_runtime_manager] channel wired: $channel (${_runtime.hashCode})');
    }
  }
}
