// ===== 能力：LayoutBuilder（父约束 → JS builder 句柄）=====
//
// Flutter 的 `LayoutBuilder` 在**布局阶段**执行 builder 来决定子树，而 builder
// 闭包只存在于 JS。这里用真实 `LayoutBuilder` 承载 JS 结点：
//
//   - JS 类 `LayoutBuilder`（生成器 widget_module_builder）在 build 里把 builder
//     登记成跨语言句柄，props 为 `{builder: {__fn: id}, child: 已展开的子树}`；
//   - 本文件在 Flutter 的 `LayoutBuilder.builder(ctx, constraints)` 里调用该句柄
//     （实参是约束 JSON），JS 侧执行 builder 后以 patch 下发新子树 `child`；
//   - 约束按值去重：每次布局只在与上次不同时回调 JS（JS 侧还有一层同值判断）。
//
// 首帧（未收到约束前）`child` 为空，与 Flutter `LayoutBuilder` 自身首帧一致。
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/widgets.dart';

import '../../js_widget_registry.dart';

/// 登记 LayoutBuilder 的宿主承载（真实 `LayoutBuilder` + builder 句柄回调）。
void registerLayoutBuilderWidgets(JsWidgetRegistry r) {
  r.register(
    'LayoutBuilder',
    (c) => _JsLayoutBuilder(
      builder: c.props['builder'],
      child: c.children['child'] as Widget?,
    ),
  );
}

/// 承载 LayoutBuilder：布局阶段把父约束交给 JS 的 builder 句柄。
class _JsLayoutBuilder extends StatefulWidget {
  const _JsLayoutBuilder({
    required this.builder,
    required this.child,
  });

  /// JS 侧登记的 builder 句柄（`{__fn: id}`）。
  final Object? builder;

  /// JS 侧按上次约束展开的子树（首帧为空）。
  final Widget? child;

  @override
  State<_JsLayoutBuilder> createState() => _JsLayoutBuilderState();
}

class _JsLayoutBuilderState extends State<_JsLayoutBuilder> {
  /// 上次下发的约束（无界维度已折成 null，便于直接比较）。
  List<double?>? _last;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sig = <double?>[
          _edge(constraints.minWidth),
          _edge(constraints.maxWidth),
          _edge(constraints.minHeight),
          _edge(constraints.maxHeight),
        ];
        if (!listEquals(sig, _last)) {
          _last = sig;
          invokeJsHandler(widget.builder, [
            <String, double?>{
              'minWidth': sig[0],
              'maxWidth': sig[1],
              'minHeight': sig[2],
              'maxHeight': sig[3],
            },
          ]);
        }
        return widget.child ?? const SizedBox.shrink();
      },
    );
  }
}

/// 无界维度（`double.infinity`）不能 JSON 编码（`jsonEncode` 会抛错），
/// 统一下发 null，JS 侧还原成 +∞（见运行时【18.8】的 `__jsuiBoxConstraints`）。
double? _edge(double v) => v.isFinite ? v : null;
