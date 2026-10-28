// ===== 能力：SliverPersistentHeader（delegate.build → JS 句柄）=====
//
// Flutter 的 `SliverPersistentHeaderDelegate.build(context, shrinkOffset,
// overlapsContent)` 在**布局阶段**同步执行，而 delegate 只存在于 JS。与
// LayoutBuilder 同一方案（见 capabilities/layout_builder/）：
//
//   - JS 类 `SliverPersistentHeader`（生成器 widget_module_builder）在 build 里
//     同步读 delegate 的 `minExtent` / `maxExtent`，把 `delegate.build` 登记成
//     跨语言句柄；props = `{minExtent, maxExtent, pinned, floating, builder}`
//     + 上次展开的子树 `child`（首帧为空）；
//   - 本文件的 adapter 在布局阶段把 `{shrinkOffset, overlapsContent}` 交给句柄
//     （按值去重），并同步返回**上一次**的子树；JS 执行 delegate.build 后以
//     patch 下发新子树，宿主随 props 更新重建 adapter、重新布局。
//   - 取舍：滚动过程中内容晚一帧跟随；header 的高度插值（min→max）由 Flutter
//     原生完成，不受影响。
//   - `shouldRebuild`：JS delegate 的实现无法同步调用，adapter 按「子树 / 范围
//     是否变化」判断，保证 patch 到达时一定重排。
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/widgets.dart';

import '../../js_widget_registry.dart';

/// 登记 SliverPersistentHeader 的宿主承载（真实 sliver + delegate.build 句柄）。
void registerSliverPersistentHeaderWidgets(JsWidgetRegistry r) {
  r.register(
    'SliverPersistentHeader',
    (c) => SliverPersistentHeader(
      pinned: c.bool_('pinned') ?? false,
      floating: c.bool_('floating') ?? false,
      delegate: _JsSliverPersistentHeaderDelegate(
        minExtent: c.num_('minExtent') ?? 0,
        maxExtent: c.num_('maxExtent') ?? 0,
        builder: c.props['builder'],
        child: c.children['child'] as Widget?,
      ),
    ),
  );
}

/// 把 JS delegate 适配成真正的 `SliverPersistentHeaderDelegate`。
class _JsSliverPersistentHeaderDelegate extends SliverPersistentHeaderDelegate {
  _JsSliverPersistentHeaderDelegate({
    required this.minExtent,
    required this.maxExtent,
    required this.builder,
    required this.child,
  });

  @override
  final double minExtent;

  @override
  final double maxExtent;

  /// JS 侧登记的 `delegate.build` 句柄（`{__fn: id}`）。
  final Object? builder;

  /// JS 侧按上次 (shrinkOffset, overlapsContent) 展开的子树（首帧为空）。
  final Widget? child;

  /// 上次下发的布局入参（同值不重复回调 JS）。
  List<Object?>? _last;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final sig = <Object?>[shrinkOffset, overlapsContent];
    if (!listEquals(sig, _last)) {
      _last = sig;
      invokeJsHandler(builder, [
        <String, Object?>{
          'shrinkOffset': shrinkOffset,
          'overlapsContent': overlapsContent,
        },
      ]);
    }
    // 兜底占位必须**撑到 maxExtent**：pinned 头的 paintExtent 由子级实际高度
    // 决定（`min(childExtent, remainingPaintExtent)`），零高子级会让
    // 「layoutExtent(=maxExtent - scrollOffset) > paintExtent」断言失败。
    return child ?? SizedBox(width: double.infinity, height: maxExtent);
  }

  @override
  bool shouldRebuild(covariant _JsSliverPersistentHeaderDelegate oldDelegate) =>
      oldDelegate.child != child ||
      oldDelegate.minExtent != minExtent ||
      oldDelegate.maxExtent != maxExtent ||
      oldDelegate.builder != builder;
}
