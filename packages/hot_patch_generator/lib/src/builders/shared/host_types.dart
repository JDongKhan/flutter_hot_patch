/// 宿主类型清单：**从运行时源码自动抽取**，是生成器唯一的类型来源。
///
/// 生成器只在构建期读取这份清单，用来决定：
///   - `patch/flutter.js` 为哪些类型生成同名包装类（`new Text(props)` →
///     `__h('Text', props)`）；
///   - 组件产物 import 哪些类名（宿主包装类在 flutter.js，全局注入类不 import）。
///
/// 抽取目标 = `hot_patch` 包的 `lib/src/js_ui/**`：
///   - `r.register('X', …)` → 宿主 widget 类型（运行时 `JsWidgetRegistry` 的键）；
///   - `_dataCarrierTypes` 字面量 / `registerJsDataCarrierType('X')` → 数据载体。
///
/// 因此新增宿主组件**只改运行时注册那一行**，生成器不需要登记任何类型名，
/// 两端也不存在需要人工同步的表。
library;

import 'dart:io';

import 'ctor_signatures.dart';

/// 宿主已注册的 widget 类型（运行时注册表的镜像，构建期从源码抽取）。
Set<String> hostWidgetTypes() => _HostTypes.instance.widgets;

/// 宿主登记的非 Widget 数据载体类型（`BottomNavigationBarItem` 等）。
Set<String> hostDataCarrierTypes() => _HostTypes.instance.carriers;

/// 进程内只扫描一次（build_runner 的多个 builder 共用）。
class _HostTypes {
  const _HostTypes(this.widgets, this.carriers);

  final Set<String> widgets;
  final Set<String> carriers;

  static final _HostTypes instance = _scan();

  /// 宿主注册调用：`r.register('Text', (c) => …)`。
  static final _register = RegExp(
    r'''\br\.register\(\s*['"]([A-Za-z_$][\w$]*)['"]''',
  );

  /// 运行时公开扩展点：`registerJsDataCarrierType('X')`。
  static final _carrierRegister = RegExp(
    r'''\bregisterJsDataCarrierType\(\s*['"]([A-Za-z_$][\w$]*)['"]''',
  );

  /// 数据载体内置字面量：`_dataCarrierTypes = <String>{ … }`（配平花括号后取名字）。
  static final _carrierBlock = RegExp(r'_dataCarrierTypes\s*=\s*<String>\{');

  /// 花括号块内的字符串字面量。
  static final _quoted = RegExp(r'''['"]([A-Za-z_$][\w$]*)['"]''');

  static _HostTypes _scan() {
    final dir = _jsUiDir();
    if (dir == null) {
      // ignore: avoid_print - 构建期日志
      print(
        '[hot_patch_generator] 未能定位 hot_patch 的 lib/src/js_ui，'
        '宿主类型清单为空（flutter.js 不会生成任何包装类）',
      );
      return const _HostTypes(<String>{}, <String>{});
    }
    final widgets = <String>{};
    final carriers = <String>{};
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final src = entity.readAsStringSync();
      for (final m in _register.allMatches(src)) {
        widgets.add(m.group(1)!);
      }
      for (final m in _carrierRegister.allMatches(src)) {
        carriers.add(m.group(1)!);
      }
      final block = _carrierBlock.firstMatch(src);
      if (block != null) {
        final text = _braceBody(src, block.end - 1);
        for (final m in _quoted.allMatches(text)) {
          carriers.add(m.group(1)!);
        }
      }
    }
    return _HostTypes(widgets, carriers);
  }

  /// 从开括号下标处取配平的块内容（含代码注释时不作严格语法分析，只数括号）。
  static String _braceBody(String src, int openIndex) {
    var depth = 0;
    for (var i = openIndex; i < src.length; i++) {
      final ch = src.codeUnitAt(i);
      if (ch == 0x7B) {
        depth++;
      } else if (ch == 0x7D) {
        depth--;
        if (depth == 0) return src.substring(openIndex + 1, i);
      }
    }
    return src.substring(openIndex + 1);
  }

  static Directory? _jsUiDir() {
    final sources = PackageSources.locate();
    if (sources == null) return null;
    for (final p in sources.packages) {
      if (p.name != 'hot_patch') continue;
      final sep = Platform.pathSeparator;
      final dir = Directory('${p.libDir}${sep}src${sep}js_ui');
      return dir.existsSync() ? dir : null;
    }
    return null;
  }
}
