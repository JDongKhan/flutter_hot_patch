/// package 模块 builder：把**每个 package** 的全部已注册 widget 类型产出为
/// 一个共享 JS 模块 `patch/<package>.js`（工厂函数 + 逻辑组件类，全局唯一
/// 一份，消除各组件产物里内联同类工厂函数造成的重复与文件爆炸）。
library;

import 'dart:async';

import 'package:build/build.dart';

import '../../translator/builtin_translators.dart';
import '../../translator/widget2js.dart';

import '../js_widget_defs.dart';
import '../product_path.dart';

/// widget 模块 builder 的**种子输入默认路径**（构建期固定文件，不含运行时代码）。
///
/// build_runner 的输出名必须在 buildExtensions 里静态声明，无法按构建期发现
/// 的类型动态命名，因此把「全部 package 模块产物」挂在本文件下，包清单由
/// [registeredWidgetPackages] 静态推导。
///
/// 该路径可由使用方 `build.yaml` 的 `options: { seed_file: ... }` 覆盖
/// （见 [seedPathFrom]）；使用方**必须**在包内提供该种子文件。
const String defaultSeedPath = 'lib/js_widgets.dart';

/// 从 builder options 读取种子输入路径：`options: { seed_file: <path> }`，
/// 缺省或非法值回退 [defaultSeedPath]。
String seedPathFrom(BuilderOptions options) {
  final value = options.config['seed_file'];
  if (value is String && value.isNotEmpty) return value;
  return defaultSeedPath;
}

/// 已注册 widget 类型 → (package → {type})：由 translator 注册表推导，
/// 作为 package 模块产物清单（每个包一个文件）的唯一来源。
Map<String, Set<String>> registeredWidgetPackages() {
  final registry = WidgetTranslatorRegistry();
  registerBuiltinTranslators(registry);
  final out = <String, Set<String>>{};
  for (final t in registry.registeredTypes) {
    final tr = registry.lookup(t);
    if (tr == null) continue;
    (out[tr.packageName] ??= <String>{}).addAll(tr.jsonTypes);
  }
  return out;
}

/// widget 模块 builder：把**每个 package** 的全部已注册 widget 类型产出为
/// 一个共享 JS 模块 `assets/<package>.js`（工厂函数 + 逻辑组件类，全局唯一
/// 一份，消除各组件产物里内联同类工厂函数造成的重复与文件爆炸）。
///
/// 输出挂在种子输入 [seedPath] 下（默认 [defaultSeedPath]，可由使用方
/// `build.yaml` 的 `options: { seed_file: ... }` 覆盖）；输出名从
/// [registeredWidgetPackages] 静态推导，构建时按包名渲染整包即可。
///
/// **使用方必须提供该种子文件**——本 builder 无降级路径，缺少种子输入即
/// 不产出任何 package 模块，组件产物的 import 会因此悬空。
class WidgetModuleBuilder implements Builder {
  const WidgetModuleBuilder({this.seedPath = defaultSeedPath});

  /// 种子输入路径（见 [defaultSeedPath]），可由 builder options 覆盖。
  final String seedPath;

  @override
  Map<String, List<String>> get buildExtensions {
    final pkgs = <String>{
      // `__h` 宿主（基础包 flutter）即使未注册任何 flutter widget 也要产出。
      nodeHelperPackage,
      ...registeredWidgetPackages().keys,
    }.toList()
      ..sort();
    return {
      '^$seedPath': [for (final p in pkgs) packageModulePath(p)],
    };
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    final packages = registeredWidgetPackages();
    for (final out in buildStep.allowedOutputs) {
      // 输出路径形如 patch/<package>.js → 反推 package
      final segs = out.path.split('/');
      if (segs.length != 2 || segs[0] != 'patch' || !segs[1].endsWith('.js')) {
        continue;
      }
      final pkg = segs[1].substring(0, segs[1].length - '.js'.length);
      await buildStep.writeAsString(
        out,
        renderPackageModule(pkg, packages[pkg] ?? const <String>{}),
      );
    }
  }
}

/// package 模块产物：把该 package 里**有 JS 类**的 widget 类型导出为 JS 类
/// （逻辑组件：provider 状态处理 / Builder 委托；sliver builder 代理）。
///
/// 宿主 widget（Text/Column/...）**不产出任何代码**：它们的元素 type 就是类型名
/// 字符串（`__h('Text', {...}, [...])`），由宿主注册表映射成 Flutter widget；
/// 本模块只在有 JS 逻辑时才有存在意义。
///
/// 一个 package 一个文件（文件名即包名）。共用元素工厂 `__h` 只在其宿主包
/// （[nodeHelperPackage]）里定义一次，其它包从 `<host>.js` 相对 import。
/// 产物自包含（不依赖运行时 `__jsui`），宿主既有渲染路径与 JS 运行时都能
/// 消费同一份产物。
String renderPackageModule(String package, Set<String> types) {
  final sorted = types.toList()..sort();
  final b = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT EDIT')
    ..writeln('// package 模块（package: $package）：由 ui_component_generator 生成')
    ..writeln('// 本包内有 JS 类的 widget（逻辑组件 / sliver 代理）集中于此文件')
    ..writeln();
  if (package == nodeHelperPackage) {
    b
      ..writeln(jsNodeHelperSource)
      ..writeln();
  } else {
    final nodeRel =
        relativeProduct(packageModulePath(package), packageModulePath(nodeHelperPackage));
    b
      ..writeln("import { __h } from '$nodeRel';")
      ..writeln();
  }
  for (final t in sorted) {
    // 逻辑 widget（provider 状态处理 / Builder 委托）：状态与订阅逻辑全部在
    // JS 侧，本包导出普通类，元素 type 即该类，宿主零感知。
    final logic = logicWidgetSources[t];
    if (logic != null) {
      b
        ..writeln()
        ..writeln(logic);
      continue;
    }
    // Sliver builder 代理：`SliverList({delegateBuilder, childCount})` 形态
    // 走本类（build 时循环调用拥有者方法收集子树）；普通形态由渲染层直接
    // 产出宿主节点（`__h('SliverList', ...)`），不经过本类。
    if (sliverBuilderTypes.contains(t)) {
      b
        ..writeln()
        ..writeln(sliverBuilderSource(t));
    }
  }
  return b.toString();
}