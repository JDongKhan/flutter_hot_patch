/// 宿主类型清单：**从运行时源码自动抽取**，是生成器唯一的类型来源。
///
/// 生成器只在构建期读取这份清单，用来决定：
///   - `patch/flutter.js` 为哪些类型生成同名包装类（`new Text(props)` 构造即
///     宿主元素，props 由 `Component.__splitHost` 拆分）；
///   - 组件产物 import 哪些类名（宿主包装类在 flutter.js，全局注入类不 import）。
///
/// 抽取目标 = `dynamic_flutter` 包的 `lib/src/js_ui/**`：
///   - `r.register('X', …)` → 宿主 widget 类型（运行时 `JsWidgetRegistry` 的键）。
///
/// 因此新增**内建**宿主组件只改运行时注册那一行，生成器不需要登记任何类型名。
/// 三方库 / 业务自定义的宿主组件不走这里：其 JS 类由业务方在工程根
/// `js/<package>.js` 里维护（与 provider / getx 等三方模块同一机制），运行时
/// 再由业务在 `main()` 里 `registerJsUiLibrary(...)` 注册 renderer。
/// 值对象（`InputDecoration` / `BottomNavigationBarItem` / `DropdownMenuItem`
/// 等）不是宿主 widget：它们在 `flutter.js` 值类区由 `style_values_js` 直接
/// 导出，不参与本清单。
library;

import 'dart:io';

import 'package_sources.dart';

/// 宿主已注册的 widget 类型（运行时注册表的镜像，构建期从源码抽取）。
Set<String> hostWidgetTypes() => _HostTypes.instance.widgets;

/// 进程内只扫描一次（build_runner 的多个 builder 共用）。
class _HostTypes {
  const _HostTypes(this.widgets);

  final Set<String> widgets;

  static final _HostTypes instance = _scan();

  /// 宿主注册调用：`r.register('Text', (c) => …)`。
  static final _register = RegExp(
    r'''\br\.register\(\s*['"]([A-Za-z_$][\w$]*)['"]''',
  );

  static _HostTypes _scan() {
    final dir = _jsUiDir();
    if (dir == null) {
      // ignore: avoid_print - 构建期日志
      print(
        '[dynamic_flutter_generator] 未能定位 dynamic_flutter 的 lib/src/js_ui，'
        '宿主类型清单为空（flutter.js 不会生成任何包装类）',
      );
      return const _HostTypes(<String>{});
    }
    final widgets = <String>{};
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final src = entity.readAsStringSync();
      for (final m in _register.allMatches(src)) {
        widgets.add(m.group(1)!);
      }
    }
    return _HostTypes(widgets);
  }

  static Directory? _jsUiDir() {
    final sources = PackageSources.locate();
    if (sources == null) return null;
    for (final p in sources.packages) {
      if (p.name != 'dynamic_flutter') continue;
      final sep = Platform.pathSeparator;
      final dir = Directory('${p.libDir}${sep}src${sep}js_ui');
      return dir.existsSync() ? dir : null;
    }
    return null;
  }
}
