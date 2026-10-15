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
/// 2. **一页一个接口**：模拟请求有固定延时（1s），按字段拆接口会让首屏串行
///    等上好几秒，故每个接口返回一个聚合对象（见 app_models.dart 的 *Feed）。
///
/// 服务只负责「取数据」，排序 / 截断等展示细节留在页面里。
library;

import '../../base/network.dart';
import '../model/app_models.dart';
import 'app_data.dart';

class AppService {
  const AppService();

  /// 模拟一次网络往返：宿主侧延时后回一个 200 响应体（响应内容这里用不上）。
  Future<void> _request(String api) async {
    await Network.post(params: {'api': api});
  }

  /// 首页：banner + 九宫格 + 景点推荐 + 广告位。
  Future<HomeFeed> fetchHome() async {
    await _request('/app/home');
    return const HomeFeed(
      banners: kBanners,
      grid: kGrid,
      spots: kSpots,
      adImg: kAdImg,
    );
  }

  /// 社区：双 tab + 筛选项配置 + 横向资源 + 帖子列表。
  Future<CommunityFeed> fetchCommunity() async {
    await _request('/app/community');
    return const CommunityFeed(
      tabs: kCommunityTabs,
      sorts: kSorts,
      postTypes: kPostTypes,
      dists: kDists,
      priceRanges: kPriceRanges,
      resources: kResources,
      posts: kPosts,
    );
  }

  /// 订单：状态筛选条 + 订单列表。
  Future<OrderFeed> fetchOrders() async {
    await _request('/app/orders');
    return const OrderFeed(statuses: kOrderStatus, orders: kOrders);
  }

  /// 我的：头像 + 订单统计 + 功能菜单。
  Future<MineFeed> fetchMine() async {
    await _request('/app/mine');
    return const MineFeed(
      avatar: kAvatarImg,
      stats: kMineStats,
      menu: kMineMenu,
    );
  }

  /// 搜索页：热搜词 + 猜你想去。
  Future<SearchFeed> fetchSearch() async {
    await _request('/app/search');
    return const SearchFeed(hot: kHotSearch, guesses: kSpots);
  }

  /// 资源专题页：专题本身 + 相关推荐。
  ///
  /// 只被宿主路由 [AppRouter.openResource]（原生侧）调用，不走 JS。
  Future<ResourceFeed> fetchResource(String id) async {
    await _request('/app/resource');
    return ResourceFeed(resource: _resourceOf(id), related: kPosts);
  }

  /// 详情页按 id 取数据（宿主路由用，不走 JS）。
  Future<Spot> fetchSpot(String id) async {
    await _request('/app/spot');
    return _spotOf(id);
  }

  Future<Post> fetchPost(String id) async {
    await _request('/app/post');
    return _postOf(id);
  }

  Future<Order> fetchOrder(String no) async {
    await _request('/app/order');
    return _orderOf(no);
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
