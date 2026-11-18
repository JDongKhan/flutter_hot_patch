import 'package:flutter/material.dart';
import 'package:dynamic_flutter_annotations/dynamic_flutter_annotations.dart';
import 'package:provider/provider.dart';

import '../../base/app_router.dart';
import '../model/app_models.dart';
import '../vm/orders_vm.dart';
import '../widgets/countdown_text.dart';
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
  // 倒计时不在页面里：`CountdownText` 自己持定时器、自己 setState，
  // 页面只在 VM 数据变化时重建，避免 100 条时每秒整页刷一遍。

  Color _statusColor(String status) => switch (status) {
    '待付款' => kPrice,
    '待发货' => const Color(0xFFF08A00),
    '待收货' => kBrand,
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
        // 本状态下的订单条数（数据一多先看清楚总量）
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
          child: Text(
            vm.orders == null ? '订单加载中…' : '共 ${vm.orders!.length} 笔订单',
            style: const TextStyle(fontSize: 12, color: Color(0xFF8B909A)),
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
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                  itemCount: vm.orders!.length,
                  itemBuilder: _buildOrderItem,
                ),
        ),
      ],
    );
  }
}

/// 订单卡：店铺行 / 商品行 / 进度步骤 / 倒计时（或时间文案）/ 地址备注 / 底栏。
/// 倒计时那行由 [CountdownText] 自己刷新，卡片本身不参与每秒重建。
///
/// 一张卡里刻意堆足信息量（店铺、状态、标签、进度、倒计时、地址、优惠、备注、
/// 合计、操作按钮），用来观察 JS 侧复杂 item 的构建与滚动表现。
class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.statusColor,
    required this.onOpen,
  });

  final Order order;

  /// 状态色（由页面按状态映射，卡片不判断业务）。
  final Color statusColor;

  final VoidCallback onOpen;

  /// 流程步骤文案（下标的含义与模型 `step` 一致）。
  static const List<String> _stageLabels = [
    '提交订单',
    '支付成功',
    '商家发货',
    '已完成',
  ];

  @override
  Widget build(BuildContext context) {
    final pending = order.status == '待付款';
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 店铺行：店铺 + 状态胶囊
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.storefront,
                    size: 15,
                    color: Color(0xFF5C6270),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      order.store,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2A2F3A),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      order.status,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0F2F6)),
            // 商品行：图 + 标题 / 规格 / 标签
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      order.img,
                      width: 82,
                      height: 82,
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, s) => Container(
                        width: 82,
                        height: 82,
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
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
                        const SizedBox(height: 7),
                        Wrap(
                          spacing: 5,
                          runSpacing: 4,
                          children: [
                            for (final tag in order.tags)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF2E8),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  tag,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFFC8621E),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 流程进度：四个节点 + 连线
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  for (var i = 0; i < _stageLabels.length; i++) ...[
                    if (i > 0)
                      Expanded(
                        child: Container(
                          height: 1.5,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          color: i <= order.step
                              ? kBrand
                              : const Color(0xFFE3E7EF),
                        ),
                      ),
                    _StageNode(
                      label: _stageLabels[i],
                      active: i <= order.step,
                    ),
                  ],
                ],
              ),
            ),
            // 倒计时（待付款）/ 时间文案（其它状态）
            if (pending)
              Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 15,
                      color: kPrice,
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      '剩余支付时间',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF8B5A4A),
                      ),
                    ),
                    const SizedBox(width: 6),
                    CountdownText(
                      deadlineMillis: order.deadlineMs,
                      color: kPrice,
                    ),
                    const Spacer(),
                    const Text(
                      '超时自动取消',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFFA89089),
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 14,
                      color: Color(0xFF8B909A),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        order.deadline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF8B909A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // 地址 / 优惠 / 备注
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Color(0xFF8B909A),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          order.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF5C6270),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '优惠：${order.discount} · 备注：${order.remark} · 共 ${order.count} 件',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9AA0AC),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0F2F6)),
            // 底栏：合计 + 操作
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
                  const SizedBox(width: 6),
                  Text(
                    '（${order.count} 件）',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF9AA0AC),
                    ),
                  ),
                  const Spacer(),
                  ..._actions(pending),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 底栏操作按钮：按状态给不同组合（演示用 toast，点击卡片本身进详情）。
  List<Widget> _actions(bool pending) {
    if (pending) {
      return [
        MiniButton(
          label: '取消订单',
          onTap: () => AppRouter.toast('已取消订单 ${order.no}（演示）'),
        ),
        const SizedBox(width: 8),
        MiniButton(label: '去支付', primary: true, onTap: onOpen),
      ];
    }
    if (order.status == '待发货') {
      return [
        MiniButton(label: '申请退款', onTap: () => AppRouter.toast('已提交退款申请（演示）')),
        const SizedBox(width: 8),
        MiniButton(
          label: '提醒发货',
          primary: true,
          onTap: () => AppRouter.toast('已提醒商家发货（演示）'),
        ),
      ];
    }
    if (order.status == '待收货') {
      return [
        MiniButton(label: '查看物流', onTap: () => AppRouter.toast('包裹运输中（演示）')),
        const SizedBox(width: 8),
        MiniButton(label: '确认收货', primary: true, onTap: onOpen),
      ];
    }
    return [
      MiniButton(label: '删除订单', onTap: () => AppRouter.toast('已删除订单（演示）')),
      const SizedBox(width: 8),
      MiniButton(label: '再次购买', primary: true, onTap: onOpen),
    ];
  }
}

/// 进度节点：圆点 + 步骤文案（当前及之前的节点高亮）。
class _StageNode extends StatelessWidget {
  const _StageNode({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: active ? kBrand : const Color(0xFFE3E7EF),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: active ? kBrand : const Color(0xFFA3A9B4),
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
