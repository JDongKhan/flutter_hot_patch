/// App 数据服务：**app 目录下所有数据的唯一出口**。
///
/// 每个接口都直接请求本地 mock 服务（`tool/patch_server.dart`）：
/// `Network.post` 走 `@HostInjected` 通道，原生侧发真实 http 请求，
/// JS 侧由宿主代为请求，服务端按 URL 路径返回 `tool/mock/<路径>.json`。
/// 页面因此和真实 App 一样，先 loading 再出数据。
///
/// 两条硬约束（都来自热更翻译器的能力边界，改这里前先读一遍）：
/// 1. **必须是实例方法**：翻译器不翻译公开 static 方法（JS 侧无等价物），
///    而本类会被首页/社区/订单/我的四个 `@PatchEntry` 页连带翻译进 JS 产物，
///    所以页面持 `AppService()` 实例调用；
/// 2. **首屏的两个接口并行发**：列表页拆成「配置接口（tabs / 筛选项 / 状态条）」
///    +「列表接口（帖子 / 订单）」两个，首屏**同时**发出；之后列表接口只在
///    筛选条件变化时按新参数重发一次。
///
/// 过滤 / 排序仍在本类内完成（页面不碰数据）；服务端只负责按路径返回 json。
library;

import '../../base/network.dart';
import '../model/app_models.dart';

class AppService {
  const AppService();

  /// 请求一个接口，返回响应 json（根节点是对象）。
  Future<Map> _request(String url) async {
    return await Network.post(url: url, params: {'api': url});
  }

  /// 带查询参数的请求：列表接口把筛选条件一起发给本地服务。
  Future<Map> _requestQuery(String url, Map<String, String> query) async {
    return await Network.post(url: url, params: {'api': url, 'query': query});
  }

  /// 首页：banner + 九宫格 + 景点推荐 + 广告位。
  Future<HomeFeed> fetchHome() async {
    final data = await _request('/app/home');
    final banners = <HomeBanner>[];
    for (final e in data['banners']) {
      banners.add(_banner(e));
    }
    final grid = <GridEntry>[];
    for (final e in data['grid']) {
      grid.add(_grid(e));
    }
    final spots = <Spot>[];
    for (final e in data['spots']) {
      spots.add(_spot(e));
    }
    return HomeFeed(banners: banners, grid: grid, spots: spots, adImg: data['adImg']);
  }

  /// 社区：双 tab + 筛选项配置 + 横向资源推荐（列表见 [fetchPostList]）。
  Future<CommunityFeed> fetchCommunity() async {
    final data = await _request('/app/community');
    final resources = <Resource>[];
    for (final e in data['resources']) {
      resources.add(_resource(e));
    }
    return CommunityFeed(
      tabs: _strings(data['tabs']),
      sorts: _strings(data['sorts']),
      postTypes: _strings(data['postTypes']),
      dists: _strings(data['dists']),
      priceRanges: _strings(data['priceRanges']),
      resources: resources,
    );
  }

  /// 社区帖子列表：**列表自己的接口**，筛选条件随请求参数一并下发。
  ///
  /// 首项（`sorts.first` = 综合 / `postTypes.first` = 全部）与空串等价，
  /// 所以首屏配置还没回来时也能用空参数先发这个请求（见页面的并行首屏）。
  /// `tab` / `dist` / `price` 原样收下，数据里没有对应字段，不参与过滤。
  Future<List<Post>> fetchPostList(String tab, String sort, String type, String dist, String price) async {
    final data = await _requestQuery('/app/posts', {'tab': tab, 'sort': sort, 'type': type, 'dist': dist, 'price': price});
    return _postListOf(_posts(data['list']), tab, sort, type);
  }

  /// 消息中心：通知列表（未读项在页面里高亮）。
  Future<List<AppNotice>> fetchNotifications() async {
    final data = await _request('/app/notifications');
    final list = <AppNotice>[];
    for (final e in data['list']) {
      list.add(_notice(e));
    }
    return list;
  }

  /// 订单：状态筛选条（列表见 [fetchOrderList]）。
  Future<OrderFeed> fetchOrders() async {
    final data = await _request('/app/orders');
    return OrderFeed(statuses: _strings(data['statuses']));
  }

  /// 订单列表：**列表自己的接口**，状态随请求参数下发（空串 / 首项「全部」= 不过滤）。
  Future<List<Order>> fetchOrderList(String status) async {
    final data = await _requestQuery('/app/orders/list', {'status': status});
    return _orderListOf(_orders(data['list']), status);
  }

  /// 我的：头像 + 订单统计 + 功能菜单。
  Future<MineFeed> fetchMine() async {
    final data = await _request('/app/mine');
    final stats = <List<String>>[];
    for (final row in data['stats']) {
      stats.add(_strings(row));
    }
    final menu = <MenuEntry>[];
    for (final e in data['menu']) {
      menu.add(_menu(e));
    }
    return MineFeed(avatar: data['avatar'], stats: stats, menu: menu);
  }

  /// 搜索页：热搜词 + 猜你想去（猜你想去复用首页景点）。
  Future<SearchFeed> fetchSearch() async {
    final data = await _request('/app/search');
    final home = await _request('/app/home');
    return SearchFeed(hot: _strings(data['hot']), guesses: _spots(home['spots']));
  }

  /// 资源专题页：专题本身（社区接口）+ 相关推荐（帖子接口）。
  ///
  /// 只被宿主路由 [AppRouter.openResource]（原生侧）调用，不走 JS。
  Future<ResourceFeed> fetchResource(String id) async {
    final community = await _request('/app/community');
    final posts = await _request('/app/posts');
    return ResourceFeed(
      resource: _resourceOf(_resources(community['resources']), id),
      related: _posts(posts['list']),
    );
  }

  /// 详情页按 id 取数据（宿主路由用，不走 JS）。
  Future<Spot> fetchSpot(String id) async {
    final data = await _request('/app/home');
    return _spotOf(_spots(data['spots']), id);
  }

  Future<Post> fetchPost(String id) async {
    final data = await _request('/app/posts');
    return _postOf(_posts(data['list']), id);
  }

  Future<Order> fetchOrder(String no) async {
    final data = await _request('/app/orders/list');
    return _orderOf(_orders(data['list']), no);
  }

  // ---------------------------------------------------------------------
  // json → 模型（响应字段与服务端 json 一一对应）
  //
  // 刻意逐条构造带类型的 List：动态 json 的 `List<dynamic>` 直接赋给
  // `List<X>` 会在运行时抛类型错误，所以统一经这些辅助方法转换。
  // ---------------------------------------------------------------------

  List<String> _strings(dynamic raw) {
    final list = <String>[];
    for (final v in raw) {
      list.add(v);
    }
    return list;
  }

  List<Spot> _spots(dynamic raw) {
    final list = <Spot>[];
    for (final e in raw) {
      list.add(_spot(e));
    }
    return list;
  }

  List<Post> _posts(dynamic raw) {
    final list = <Post>[];
    for (final e in raw) {
      list.add(_post(e));
    }
    return list;
  }

  List<Order> _orders(dynamic raw) {
    final list = <Order>[];
    for (final e in raw) {
      list.add(_order(e));
    }
    return list;
  }

  List<Resource> _resources(dynamic raw) {
    final list = <Resource>[];
    for (final e in raw) {
      list.add(_resource(e));
    }
    return list;
  }

  HomeBanner _banner(dynamic e) {
    return HomeBanner(img: e['img'], title: e['title'], sub: e['sub']);
  }

  GridEntry _grid(dynamic e) {
    return GridEntry(emoji: e['emoji'], title: e['title']);
  }

  Spot _spot(dynamic e) {
    return Spot(
      id: e['id'],
      title: e['title'],
      sub: e['sub'],
      sold: e['sold'],
      tag: e['tag'],
      img: e['img'],
      desc: e['desc'],
      price: e['price'],
      tags: _strings(e['tags']),
    );
  }

  Post _post(dynamic e) {
    return Post(
      id: e['id'],
      title: e['title'],
      sub: e['sub'],
      type: e['type'],
      author: e['author'],
      time: e['time'],
      img: e['img'],
      like: e['like'],
      tab: e['tab'],
    );
  }

  AppNotice _notice(dynamic e) {
    return AppNotice(
      id: e['id'],
      title: e['title'],
      content: e['content'],
      time: e['time'],
      type: e['type'],
      unread: e['unread'],
    );
  }

  Resource _resource(dynamic e) {
    return Resource(
      id: e['id'],
      title: e['title'],
      sub: e['sub'],
      img: e['img'],
    );
  }

  Order _order(dynamic e) {
    return Order(
      no: e['no'],
      status: e['status'],
      title: e['title'],
      spec: e['spec'],
      img: e['img'],
      price: e['price'],
      step: e['step'],
    );
  }

  MenuEntry _menu(dynamic e) {
    return MenuEntry(
      emoji: e['emoji'],
      title: e['title'],
      screen: e['screen'],
      arg: e['arg'],
    );
  }

  // ---------------------------------------------------------------------
  // 模拟后端：按筛选参数返回列表（过滤 / 排序在 service 做，页面不碰数据）
  // ---------------------------------------------------------------------

  /// 帖子列表：按 tab 归属过滤 + 按内容类型过滤 + 按排序方式排序。
  ///
  /// 「广场」是全部内容的聚合（空串与它等价，首屏并行请求时 tab 还没回来），
  /// 「推荐」只取接口里标了该 tab 的精选内容——两个 tab 数据不同。
  List<Post> _postListOf(List<Post> posts, String tab, String sort, String type) {
    var result = tab.isEmpty || tab == '广场' ? posts : posts.where((p) => p.tab == tab).toList();
    result = type.isEmpty || type == '全部' ? result : result.where((p) => p.type == type).toList();
    switch (sort) {
      case '最新':
        result = result.reversed.toList();
      case '最热':
        result = result.toList()..sort((a, b) => b.like.compareTo(a.like));
    }
    return result;
  }

  /// 订单列表：按状态过滤（空串 / 首项「全部」= 不过滤）。
  List<Order> _orderListOf(List<Order> orders, String status) {
    if (status.isEmpty || status == '全部') return orders;
    return orders.where((o) => o.status == status).toList();
  }

  // ---------------------------------------------------------------------
  // 按 id 定位（找不到时回退首个，与页面跳转的容错口径一致）
  // ---------------------------------------------------------------------

  Spot _spotOf(List<Spot> spots, String id) {
    for (final s in spots) {
      if (s.id == id) return s;
    }
    return spots.first;
  }

  Post _postOf(List<Post> posts, String id) {
    for (final p in posts) {
      if (p.id == id) return p;
    }
    return posts.first;
  }

  Order _orderOf(List<Order> orders, String no) {
    for (final o in orders) {
      if (o.no == no) return o;
    }
    return orders.first;
  }

  Resource _resourceOf(List<Resource> resources, String id) {
    for (final r in resources) {
      if (r.id == id) return r;
    }
    return resources.first;
  }
}
