import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';
import 'package:provider/provider.dart';

import '../../base/app_router.dart';
import '../model/app_models.dart';
import '../vm/orders_vm.dart';
import '../widgets/load_error_view.dart';
import 'detail_pages.dart';

/// 订单 tab（`@PatchEntry` → 连带翻译，产物 patch/app/pages/orders_page.js）。
///
/// 对应 docs/app-prototype.html 的「订单」：顶部状态条 + 订单卡列表。
///
/// 页面数据与交互状态收敛到 [OrdersVm]（provider）：配置与列表两个接口
/// 并行发出，切状态时只重发列表。
@PatchEntry()
class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key, this.initialStatus});

  /// 初始选中的状态（「我的」页统计项跳进来时指定）。
  final String? initialStatus;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<OrdersVm>(
      create: (_) => OrdersVm(initialStatus: initialStatus)..load(),
      child: const OrdersView(),
    );
  }
}

/// 订单视图：订阅 [OrdersVm]。
class OrdersView extends StatefulWidget {
  const OrdersView({super.key});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  Color _statusColor(String status) => switch (status) {
    '待付款' => kPrice,
    '已完成' => const Color(0xFF8B909A),
    _ => kBrand,
  };

  /// 订单列表项：懒加载 builder 会抽成实例方法，VM 从当前 context 读取，
  /// 不依赖 build 里的局部变量（否则产物里会成为未定义自由变量）。
  Widget _buildOrderItem(BuildContext context, int i) {
    final List<Order> orders = context.read<OrdersVm>().orders!;
    final o = orders[i];
    return _OrderCard(
      order: o,
      statusColor: _statusColor(o.status),
      onOpen: () => AppRouter.openOrder(o.no),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OrdersVm>();
    final feed = vm.feed;
    // 失败后必须退出 loading 态：给出异常信息与重试入口。
    if (feed == null) {
      final error = vm.feedError;
      if (error != null) {
        return LoadErrorView(message: error, onRetry: vm.retry);
      }
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      // 状态条的白色底必须横贯整屏。Column 默认按子结点自身宽度居中排布，
      // `Container(color: white)` 会缩成状态条那么宽，"白底没铺满"。stretch
      // 让子结点拉满交叉轴，白底占到整行（宽屏同样如此）。
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 状态条
        Container(
          color: Colors.white,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final s in feed.statuses)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () => vm.pickStatus(s),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: vm.status == s
                                  ? const Color(0xFFE8F2FF)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              s,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: vm.status == s
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: vm.status == s
                                    ? kBrand
                                    : const Color(0xFF5C6270),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // 列表请求中：贴一条细进度条（列表接口的加载反馈）
        if (vm.listLoading) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: vm.orders == null
              ? vm.ordersError != null
                    ? LoadErrorView(
                        message: vm.ordersError!,
                        onRetry: vm.retry,
                      )
                    : const Center(child: CircularProgressIndicator())
              : vm.orders!.isEmpty
              ? const Center(
                  child: Text(
                    '该状态下暂无订单',
                    style: TextStyle(fontSize: 13, color: Color(0xFF98A0AC)),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                  itemCount: vm.orders!.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: _buildOrderItem,
                ),
        ),
      ],
    );
  }
}

/// 订单卡：头（订单号 + 状态）/ 商品行 / 底（合计 + 操作）。
class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.statusColor,
    required this.onOpen,
  });

  final Order order;
  final Color statusColor;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final pending = order.status == '待付款';
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Row(
                children: [
                  Text(
                    '订单号 ${order.no}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8B909A),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    order.status,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0F2F6)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      order.img,
                      width: 66,
                      height: 66,
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, s) => Container(
                        width: 66,
                        height: 66,
                        color: const Color(0xFFE8EBF0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          order.spec,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF8B909A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '×1',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFA3A9B4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0F2F6)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 12, 12),
              child: Row(
                children: [
                  const Text(
                    '合计 ',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF5C6270)),
                  ),
                  Text(
                    '￥${order.price}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: kPrice,
                    ),
                  ),
                  const Spacer(),
                  if (pending) ...[
                    MiniButton(
                      label: '取消',
                      onTap: () => AppRouter.toast('已取消订单 ${order.no}（演示）'),
                    ),
                    const SizedBox(width: 8),
                    MiniButton(label: '去支付', primary: true, onTap: onOpen),
                  ] else
                    MiniButton(label: '查看详情', onTap: onOpen),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
