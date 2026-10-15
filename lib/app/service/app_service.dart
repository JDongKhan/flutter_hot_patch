/// App 数据服务：**app 目录下所有数据的唯一出口**。
///
/// 每个接口都先走一遍 [Network] 的模拟网络通道（lib/base/network.dart，
/// `@HostInjected` → 原生是 Dart 直调、JS 是宿主 `_app_host_.invoke('post')`），
/// 拿到「响应」后再返回 [app_data.dart] 里的模拟数据——页面因此和真实 App
/// 一样，先 loading 再出数据。
///
/// 两条硬约束（都来自热更翻译器的能力边界，改这里前先读一遍）：
/// 1. **必须是实例方法**：翻译器不翻译公开 static 方法（JS 侧无等价物），
///    而本类会被首页/社区/订单/我的四个 `@PatchEntry` 页连带翻译进 JS 产物，
///    所以页面持 `AppService()` 实例调用；
/// 2. **首屏的两个接口并行发**：模拟请求有固定延时（1s），列表页拆成
///    「配置接口（tabs / 筛选项 / 状态条）」+「列表接口（帖子 / 订单）」两个，
///    首屏**同时**发出（当初串行拆接口会让首屏空等好几秒）；之后列表接口
///    只在筛选条件变化时按新参数重发一次。
///
/// 服务负责「取数据」（含按筛选参数过滤 / 排序，模拟后端行为），页面只负责展示。
library;

import '../../base/network.dart';
import '../model/app_models.dart';
import 'app_data.dart';

class AppService {
  const AppService();

  /// 模拟一次网络往返：宿主侧延时后回一个 200 响应体（响应内容这里用不上）。
  Future<void> _request(String url, String api) async {
    await Network.post(url: url, params: {'api': api});
  }

  /// 带查询参数的模拟请求：列表接口把筛选条件一起发给「后端」。
  Future<void> _requestQuery(String api, Map<String, String> query) async {
    await Network.post(url: api, params: {'api': api, 'query': query});
  }

  /// 首页：banner + 九宫格 + 景点推荐 + 广告位。
  Future<HomeFeed> fetchHome() async {
    await _request('/app/home','/app/home');
    return const HomeFeed(banners: kBanners, grid: kGrid, spots: kSpots, adImg: kAdImg);
  }

  /// 社区：双 tab + 筛选项配置 + 横向资源推荐（列表见 [fetchPostList]）。
  Future<CommunityFeed> fetchCommunity() async {
    await _request('/app/community','/app/community');
    return const CommunityFeed(
      tabs: kCommunityTabs,
      sorts: kSorts,
      postTypes: kPostTypes,
      dists: kDists,
      priceRanges: kPriceRanges,
      resources: kResources,
    );
  }

  /// 社区帖子列表：**列表自己的接口**，筛选条件随请求参数一并下发。
  ///
  /// 首项（`sorts.first` = 综合 / `postTypes.first` = 全部）与空串等价，
  /// 所以首屏配置还没回来时也能用空参数先发这个请求（见页面的并行首屏）。
  /// `tab` / `dist` / `price` 原样收下，模拟数据里没有对应字段，不参与过滤
  /// （与原型一致：它们只是可选条件）。
  Future<List<Post>> fetchPostList(String tab, String sort, String type, String dist, String price) async {
    await _requestQuery('/app/posts', {'tab': tab, 'sort': sort, 'type': type, 'dist': dist, 'price': price});
    return _postListOf(sort, type);
  }

  /// 订单：状态筛选条（列表见 [fetchOrderList]）。
  Future<OrderFeed> fetchOrders() async {
    await _request('/app/orders','/app/orders');
    return const OrderFeed(statuses: kOrderStatus);
  }

  /// 订单列表：**列表自己的接口**，状态随请求参数下发（空串 / 首项「全部」= 不过滤）。
  Future<List<Order>> fetchOrderList(String status) async {
    await _requestQuery('/app/orders/list', {'status': status});
    return _orderListOf(status);
  }

  /// 我的：头像 + 订单统计 + 功能菜单。
  Future<MineFeed> fetchMine() async {
    await _request('/app/mine','/app/mine');
    return const MineFeed(avatar: kAvatarImg, stats: kMineStats, menu: kMineMenu);
  }

  /// 搜索页：热搜词 + 猜你想去。
  Future<SearchFeed> fetchSearch() async {
    await _request('/app/search','/app/search');
    return const SearchFeed(hot: kHotSearch, guesses: kSpots);
  }

  /// 资源专题页：专题本身 + 相关推荐。
  ///
  /// 只被宿主路由 [AppRouter.openResource]（原生侧）调用，不走 JS。
  Future<ResourceFeed> fetchResource(String id) async {
    await _request('/app/resource','/app/resource');
    return ResourceFeed(resource: _resourceOf(id), related: kPosts);
  }

  /// 详情页按 id 取数据（宿主路由用，不走 JS）。
  Future<Spot> fetchSpot(String id) async {
    await _request('/app/spot','/app/spot');
    return _spotOf(id);
  }

  Future<Post> fetchPost(String id) async {
    await _request('/app/post','/app/post');
    return _postOf(id);
  }

  Future<Order> fetchOrder(String no) async {
    await _request('/app/order','/app/order');
    return _orderOf(no);
  }

  // ---------------------------------------------------------------------
  // 模拟后端：按筛选参数返回列表（过滤 / 排序在「服务端」做，页面不碰数据）
  // ---------------------------------------------------------------------

  /// 帖子列表：按内容类型过滤 + 按排序方式排序。
  ///
  /// 空串与各自首项（`postTypes.first` = 全部 / `sorts.first` = 综合）等价。
  List<Post> _postListOf(String sort, String type) {
    var list = type.isEmpty || type == kPostTypes.first ? kPosts : kPosts.where((p) => p.type == type).toList();
    switch (sort) {
      case '最新':
        list = list.reversed.toList();
      case '最热':
        list = list.toList()..sort((a, b) => b.like.compareTo(a.like));
    }
    return list;
  }

  /// 订单列表：按状态过滤（空串 / 首项「全部」= 不过滤）。
  List<Order> _orderListOf(String status) {
    if (status.isEmpty || status == kOrderStatus.first) return kOrders;
    return kOrders.where((o) => o.status == status).toList();
  }

  // ---------------------------------------------------------------------
  // 按 id 定位（找不到时回退首个，与页面跳转的容错口径一致）
  // ---------------------------------------------------------------------

  Spot _spotOf(String id) {
    for (final s in kSpots) {
      if (s.id == id) return s;
    }
    return kSpots.first;
  }

  Post _postOf(String id) {
    for (final p in kPosts) {
      if (p.id == id) return p;
    }
    return kPosts.first;
  }

  Order _orderOf(String no) {
    for (final o in kOrders) {
      if (o.no == no) return o;
    }
    return kOrders.first;
  }

  Resource _resourceOf(String id) {
    for (final r in kResources) {
      if (r.id == id) return r;
    }
    return kResources.first;
  }
}
