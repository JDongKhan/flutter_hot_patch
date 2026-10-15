import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

import '../../base/app_router.dart';
import '../model/app_models.dart';
import '../service/app_service.dart';
import 'detail_pages.dart';

/// 订单 tab（`@PatchEntry` → 连带翻译，产物 patch/app/pages/orders_page.js）。
///
/// 对应 docs/app-prototype.html 的「订单」：顶部状态条（全部/待付款/待发货/
/// 待收货/已完成）+ 订单卡列表（订单号 / 状态 / 商品 / 合计 / 操作按钮）。
///
/// 数据走两个模拟接口：状态条由 [AppService.fetchOrders] 取，订单列表由
/// [AppService.fetchOrderList] 取。首屏两个请求**并行**发出（列表先用空状态
/// 参数请求，等价「全部」），此后点状态即按该状态重新请求一次列表。
///
/// 本页纳入连带翻译（`@PatchEntry`）：`.where().toList()` 过滤、集合 for 循环、
/// ListView.separated 的 itemBuilder 局部变量、switch 表达式返回 Color 均已支持。
@PatchEntry()
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key, this.initialStatus});

  /// 初始选中的状态（「我的」页统计项跳进来时指定）。
  final String? initialStatus;

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final AppService _service = AppService();

  /// 配置（状态条）；null = 加载中。
  OrderFeed? _feed;

  /// 列表接口返回；null = 列表加载中。
  List<Order>? _orders;

  /// 列表请求进行中（切状态后重新请求时贴进度条）。
  bool _listLoading = false;

  /// 当前选中的状态；空串 = 还没定（等价首项「全部」）。
  String _status = '';

  @override
  void initState() {
    super.initState();
    // 配置与列表并行发，首屏只等一个往返（1s），不串行等两次。
    _load();
    _loadOrders();
  }

  Future<void> _load() async {
    final OrderFeed feed = await _service.fetchOrders();
    setState(() {
      _feed = feed;
      _status = widget.initialStatus ?? feed.statuses.first;
    });
    // 带具体状态跳进来时，首屏那次「空参数（=全部）」的结果不对口，按状态重发。
    if (widget.initialStatus != null) {
      await _loadOrders();
    }
  }

  /// 列表接口：按当前状态取回订单列表。
  Future<void> _loadOrders() async {
    setState(() => _listLoading = true);
    final List<Order> orders = await _service.fetchOrderList(_status);
    setState(() {
      _orders = orders;
      _listLoading = false;
    });
  }

  /// 点状态：先切高亮，再按新状态请求列表。
  void _pickStatus(String status) {
    setState(() => _status = status);
    _loadOrders();
  }

  Color _statusColor(String status) => switch (status) {
    '待付款' => kPrice,
    '已完成' => const Color(0xFF8B909A),
    _ => kBrand,
  };

  @override
  Widget build(BuildContext context) {
    if (_feed == null) {
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
                    for (final s in _feed!.statuses)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () => _pickStatus(s),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _status == s
                                  ? const Color(0xFFE8F2FF)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              s,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _status == s
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: _status == s
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
        if (_listLoading) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: _orders == null
              ? const Center(child: CircularProgressIndicator())
              : _orders!.isEmpty
              ? const Center(
                  child: Text(
                    '该状态下暂无订单',
                    style: TextStyle(fontSize: 13, color: Color(0xFF98A0AC)),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                  itemCount: _orders!.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final o = _orders![i];
                    return _OrderCard(
                      order: o,
                      statusColor: _statusColor(o.status),
                      onOpen: () => AppRouter.openOrder(o.no),
                    );
                  },
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
                    child: Image.network(
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
