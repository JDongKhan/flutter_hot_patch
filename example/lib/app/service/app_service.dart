/// App 数据服务：**app 目录下所有数据的唯一出口**。
///
/// 每个接口都直接请求本地 mock 服务（`tool/patch_server.dart`）：
/// `Network.post` 走 `@HostInjected` 通道，原生侧发真实 http 请求，
/// JS 侧由宿主代为请求，服务端按 URL 路径返回 `tool/mock/<路径>.json`。
/// 页面因此和真实 App 一样，先 loading 再出数据。
///
/// 两条约束（改这里前先读一遍）：
/// 1. **模型的 json 转换放在模型自己的 `static fromJson`**：Dart 的 static
///    成员与实例成员同一名字空间，翻译器把静态方法/字段原样发射成 JS 类的
///    静态成员（`Spot.fromJson(e)` → `Spot.fromJson(e)`），本类只负责「发起
///    请求 + json 数组 → 模型 List」；
/// 2. **首屏的两个接口并行发**：列表页拆成「配置接口（tabs / 筛选项 / 状态条）」
///    +「列表接口（帖子 / 订单）」两个，首屏**同时**发出；之后列表接口只在
///    筛选条件变化时按新参数重发一次。
///
/// 过滤 / 排序仍在本类内完成（页面不碰数据）；服务端只负责按路径返回 json。
library;

import 'package:hot_module_base/hot_module_base.dart';

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
  ///
  /// **数据跟着城市走**：接口一次返回所有城市的 banner / 景点 / 广告位，
  /// 这里按 `city` 取对应城市那一份（城市切换后页面用新城市重发本请求）。
  /// 城市不在列表里时回退到第一个城市，避免切换后白屏。
  Future<HomeFeed> fetchHome(String city) async {
    final data = await _request('/app/home');
    final entry = _cityOf(data['cities'], city);
    return HomeFeed.fromJson(<String, dynamic>{
      'banners': entry['banners'],
      'grid': data['grid'],
      'spots': entry['spots'],
      'adImg': entry['adImg'],
    });
  }

  /// 社区：双 tab + 筛选项配置（横向资源见 [fetchCommunityResources]）。
  Future<CommunityFeed> fetchCommunity() async {
    final data = await _request('/app/community');
    return CommunityFeed.fromJson(data);
  }

  /// 社区横向资源横幅：按归属 tab 过滤（广场 = 全部聚合，与帖子列表同口径）。
  Future<List<Resource>> fetchCommunityResources(String tab) async {
    final data = await _request('/app/community');
    final all = _resources(data['resources']);
    if (tab.isEmpty || tab == '广场') return all;
    return all.where((r) => r.tab == tab).toList();
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
      list.add(AppNotice.fromJson(e));
    }
    return list;
  }

  /// 订单：状态筛选条（列表见 [fetchOrderList]）。
  Future<OrderFeed> fetchOrders() async {
    final data = await _request('/app/orders');
    return OrderFeed.fromJson(data);
  }

  /// 订单列表：**列表自己的接口**，状态随请求参数下发（空串 / 首项「全部」= 不过滤）。
  Future<List<Order>> fetchOrderList(String status) async {
    final data = await _requestQuery('/app/orders/list', {'status': status});
    return _orderListOf(_orders(data['list']), status);
  }

  /// 我的：头像 + 订单统计 + 功能菜单。
  Future<MineFeed> fetchMine() async {
    final data = await _request('/app/mine');
    return MineFeed.fromJson(data);
  }

  /// 搜索页：热搜词 + 猜你想去（猜你想去复用首页景点）。
  Future<SearchFeed> fetchSearch() async {
    final data = await _request('/app/search');
    final home = await _request('/app/home');
    final entry = _cityOf(home['cities'], '');
    return SearchFeed.fromJson(<String, dynamic>{
      'hot': data['hot'],
      'guesses': entry['spots'],
    });
  }

  /// 资源专题页：专题本身（社区接口）+ 相关推荐（帖子接口）。
  ///
  /// 只被宿主路由 [AppRouter.openResource]（原生侧）调用，不走 JS。
  Future<ResourceFeed> fetchResource(String id) async {
    final community = await _request('/app/community');
    final posts = await _request('/app/posts');
    return ResourceFeed.fromJson(<String, dynamic>{
      'resource': _resourceJsonOf(community['resources'], id),
      'related': posts['list'],
    });
  }

  /// 详情页按 id 取数据（宿主路由用，不走 JS）。景点分散在各城市下，这里全量找。
  Future<Spot> fetchSpot(String id) async {
    final data = await _request('/app/home');
    final cities = data['cities'];
    final all = <Spot>[];
    for (final c in cities) {
      all.addAll(_spots(c['spots']));
    }
    return _spotOf(all, id);
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
  // json → 模型（转换逻辑在模型自己的 `static fromJson`；这里只做
  // 「json 数组 → 带类型的 List」，页面拿到的始终是模型对象）
  // ---------------------------------------------------------------------

  List<Spot> _spots(dynamic raw) {
    final list = <Spot>[];
    for (final e in raw) {
      list.add(Spot.fromJson(e));
    }
    return list;
  }

  List<Post> _posts(dynamic raw) {
    final list = <Post>[];
    for (final e in raw) {
      list.add(Post.fromJson(e));
    }
    return list;
  }

  List<Order> _orders(dynamic raw) {
    final list = <Order>[];
    for (final e in raw) {
      list.add(Order.fromJson(e));
    }
    return list;
  }

  List<Resource> _resources(dynamic raw) {
    final list = <Resource>[];
    for (final e in raw) {
      list.add(Resource.fromJson(e));
    }
    return list;
  }

  /// 按 id 取资源 json（找不到时回退首个，与页面跳转的容错口径一致）。
  Map _resourceJsonOf(dynamic raw, String id) {
    for (final r in raw) {
      if (r['id'] == id) return r;
    }
    return raw.first;
  }

  /// 按城市名取接口里该城市那一份数据；空串或不认识的城市回退首个城市。
  Map _cityOf(dynamic cities, String city) {
    for (final c in cities) {
      if (c['name'] == city) return c;
    }
    return cities.first;
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
}
