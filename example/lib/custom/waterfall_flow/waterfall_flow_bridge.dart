// ===== 自定义能力：WaterfallFlow 瀑布流（三方包 waterfall_flow）=====
//
// 三方包不是运行时内建能力：宿主桥接放在本工程 `lib/custom/` 下，由
// `main()` 里的 `initJsUi(libraries: customJsUiLibraries)` 统一装配，dynamic_flutter 包零改动。
// JS 侧类（WaterfallFlow / 两个布局 delegate）见工程根
// `js/waterfall_flow.js`，构建时拷贝为 `patch/packages/waterfall_flow.js`。
//
// 只做「值对象还原 + 同名 widget 渲染」两件事：
//   - 布局 delegate 是 Dart 侧 const 构造的**值对象**，跨桥只剩字段，
//     由 `kind` 判别（见 JS 模块里的说明），这里还原成真实 delegate；
//   - 容器本身按同名 `WaterfallFlow` 渲染（children / shrinkWrap / physics /
//     padding / scrollDirection 与 Dart 构造同名对齐）。
import 'package:flutter/widgets.dart';
import 'package:dynamic_flutter/dynamic_flutter.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

/// `gridDelegate` 跨桥形态 → 真实 delegate。
///
/// JS 侧只有两个值类（见 `js/waterfall_flow.js`），字段名与 Dart 构造同名；
/// 间距缺省（null）时按包内默认 0，不做其它兜底。形态不认识时告警并退回
/// 「固定 2 列」——瀑布流没有布局 delegate 就无法排版，不能静默丢弃。
SliverWaterfallFlowDelegate _delegateFromJson(Object? value) {
  if (value is Map) {
    final kind = value['kind']?.toString() ?? '';
    final mainAxisSpacing = (value['mainAxisSpacing'] as num?)?.toDouble() ?? 0;
    final crossAxisSpacing =
        (value['crossAxisSpacing'] as num?)?.toDouble() ?? 0;
    final closeToTrailing = value['closeToTrailing'] == true;
    if (kind == 'fixedCrossAxisCount') {
      final count = (value['crossAxisCount'] as num?)?.toInt() ?? 2;
      return SliverWaterfallFlowDelegateWithFixedCrossAxisCount(
        crossAxisCount: count < 1 ? 2 : count,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        closeToTrailing: closeToTrailing,
      );
    }
    if (kind == 'maxCrossAxisExtent') {
      final extent = (value['maxCrossAxisExtent'] as num?)?.toDouble() ?? 300;
      return SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: extent,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        closeToTrailing: closeToTrailing,
      );
    }
  }
  JsLog.warn('[WaterfallFlow] 无法识别的 gridDelegate（已退回固定 2 列）：$value');
  return const SliverWaterfallFlowDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
  );
}

/// `children:` 槽位（普通构造的子项列表）。
List<Widget> _childrenOf(JsRenderContext c) {
  final own = c.children['children'];
  return own is List<Widget> ? own : const <Widget>[];
}

/// WaterfallFlow 能力域组件注册。
void registerWaterfallFlowWidgets(JsWidgetRegistry r) {
  r.register('WaterfallFlow', (c) {
    // controller 句柄桥暂不接（业务只做「可滚动的瀑布流列表」时用不到）：
    // 传了就明确告警，避免控制器静默失效。
    if (JsObjectBridge.idOf(c.props['controller']) != null) {
      JsLog.warn('[WaterfallFlow] controller 实参未支持（已忽略）');
    }
    return WaterfallFlow(
      key: c.key,
      gridDelegate: _delegateFromJson(c.props['gridDelegate']),
      scrollDirection: c.axis('scrollDirection') ?? Axis.vertical,
      padding: c.edgeInsets('padding'),
      physics: c.scrollPhysics('physics'),
      shrinkWrap: c.bool_('shrinkWrap') ?? false,
      children: _childrenOf(c),
    );
  });
}
