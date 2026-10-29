/// App 数据模型。
///
/// 全部模型只使用 **可翻译的基础类型**（String / int / bool / List<String>），
/// 不含 Color / DateTime 等无 JS 等价物的对象字段——这些模型会被首页
/// `@PatchEntry` 组件依赖，随组件一起翻译进 JS 产物
/// （lib/app/pages/home_page.dart → patch/app/pages/home_page.js）。
///
/// 颜色、装饰等纯展示常量留在 widget 代码里以字面量书写，不进模型。
library;

/// 景点 / 线路（首页「景点推荐」宫格 + 景点详情页）。
class Spot {
  final String id;
  final String title;
  final String sub;
  final String sold;
  final String tag;
  final String img;
  final String desc;
  final int price;
  final List<String> tags;

  const Spot({
    required this.id,
    required this.title,
    required this.sub,
    required this.sold,
    required this.tag,
    required this.img,
    required this.desc,
    required this.price,
    required this.tags,
  });

  /// json → 模型（一个 json 对象一个模型，字段名与接口一一对应）。
  ///
  /// 刻意逐条构造带类型的 List：动态 json 的 `List<dynamic>` 直接赋给
  /// `List<String>` 在 Dart 运行时会抛类型错误，所以列表字段一律循环收窄。
  static Spot fromJson(Map<String, dynamic> e) {
    final tags = <String>[];
    for (final t in e['tags']) {
      tags.add(t);
    }
    return Spot(
      id: e['id'],
      title: e['title'],
      sub: e['sub'],
      sold: e['sold'],
      tag: e['tag'],
      img: e['img'],
      desc: e['desc'],
      price: e['price'],
      tags: tags,
    );
  }
}

/// 首页轮播 banner。
class HomeBanner {
  final String img;
  final String title;
  final String sub;

  const HomeBanner({required this.img, required this.title, required this.sub});

  static HomeBanner fromJson(Map<String, dynamic> e) {
    return HomeBanner(img: e['img'], title: e['title'], sub: e['sub']);
  }
}

/// 首页九宫格入口。
class GridEntry {
  final String emoji;
  final String title;

  const GridEntry({required this.emoji, required this.title});

  static GridEntry fromJson(Map<String, dynamic> e) {
    return GridEntry(emoji: e['emoji'], title: e['title']);
  }
}

/// 社区帖子。
class Post {
  final String id;
  final String title;
  final String sub;
  final String type;
  final String author;
  final String time;
  final String img;
  final int like;

  /// 归属 tab（广场 / 推荐）：列表接口按 tab 过滤时使用。
  final String tab;

  const Post({
    required this.id,
    required this.title,
    required this.sub,
    required this.type,
    required this.author,
    required this.time,
    required this.img,
    required this.like,
    required this.tab,
  });

  static Post fromJson(Map<String, dynamic> e) {
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
}

/// 通知消息（消息中心列表项）。
class AppNotice {
  final String id;
  final String title;
  final String content;
  final String time;

  /// 消息分类（订单 / 活动 / 系统 …），列表里以标签展示。
  final String type;

  /// 是否未读（未读项标题前带红点）。
  final bool unread;

  const AppNotice({
    required this.id,
    required this.title,
    required this.content,
    required this.time,
    required this.type,
    required this.unread,
  });

  static AppNotice fromJson(Map<String, dynamic> e) {
    return AppNotice(
      id: e['id'],
      title: e['title'],
      content: e['content'],
      time: e['time'],
      type: e['type'],
      unread: e['unread'],
    );
  }
}

/// 社区横向资源推荐卡。
class Resource {
  final String id;
  final String title;
  final String sub;
  final String img;

  /// 归属 tab（广场 / 推荐）：切换 tab 时横幅列表跟着换。
  final String tab;

  const Resource({
    required this.id,
    required this.title,
    required this.sub,
    required this.img,
    required this.tab,
  });

  static Resource fromJson(Map<String, dynamic> e) {
    return Resource(
      id: e['id'],
      title: e['title'],
      sub: e['sub'],
      img: e['img'],
      tab: e['tab'],
    );
  }
}

/// 订单。
class Order {
  final String no;
  final String status;
  final String title;
  final String spec;
  final String img;
  final int price;

  /// 流程进度（0=提交订单 1=支付成功 2=商家发货 3=已完成）。
  final int step;

  const Order({
    required this.no,
    required this.status,
    required this.title,
    required this.spec,
    required this.img,
    required this.price,
    required this.step,
  });

  static Order fromJson(Map<String, dynamic> e) {
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
}

/// 首页接口返回：banner + 九宫格 + 景点推荐 + 广告位（一次请求拿全，见 AppService）。
class HomeFeed {
  final List<HomeBanner> banners;
  final List<GridEntry> grid;
  final List<Spot> spots;
  final String adImg;

  const HomeFeed({
    required this.banners,
    required this.grid,
    required this.spots,
    required this.adImg,
  });

  /// 入参是「拼好的一个 feed 对象」：banners / spots / adImg 来自按城市选中的
  /// 那一份、grid 来自根节点（见 AppService.fetchHome）。
  static HomeFeed fromJson(Map<String, dynamic> e) {
    final banners = <HomeBanner>[];
    for (final b in e['banners']) {
      banners.add(HomeBanner.fromJson(b));
    }
    final grid = <GridEntry>[];
    for (final g in e['grid']) {
      grid.add(GridEntry.fromJson(g));
    }
    final spots = <Spot>[];
    for (final s in e['spots']) {
      spots.add(Spot.fromJson(s));
    }
    return HomeFeed(banners: banners, grid: grid, spots: spots, adImg: e['adImg']);
  }
}

/// 社区「配置」接口返回：双 tab + 筛选项配置。
///
/// 帖子列表**不在**这里——它是列表自己的接口（[AppService.fetchPostList]），
/// 横向资源横幅同理（[AppService.fetchCommunityResources]），随 tab 变化重发。
class CommunityFeed {
  final List<String> tabs;
  final List<String> sorts;
  final List<String> postTypes;
  final List<String> dists;
  final List<String> priceRanges;

  const CommunityFeed({
    required this.tabs,
    required this.sorts,
    required this.postTypes,
    required this.dists,
    required this.priceRanges,
  });

  static CommunityFeed fromJson(Map<String, dynamic> e) {
    final tabs = <String>[];
    for (final v in e['tabs']) {
      tabs.add(v);
    }
    final sorts = <String>[];
    for (final v in e['sorts']) {
      sorts.add(v);
    }
    final postTypes = <String>[];
    for (final v in e['postTypes']) {
      postTypes.add(v);
    }
    final dists = <String>[];
    for (final v in e['dists']) {
      dists.add(v);
    }
    final priceRanges = <String>[];
    for (final v in e['priceRanges']) {
      priceRanges.add(v);
    }
    return CommunityFeed(
      tabs: tabs,
      sorts: sorts,
      postTypes: postTypes,
      dists: dists,
      priceRanges: priceRanges,
    );
  }
}

/// 订单「配置」接口返回：状态筛选条。
///
/// 订单列表同样是列表自己的接口（[AppService.fetchOrderList]），切状态时重新请求。
class OrderFeed {
  final List<String> statuses;

  const OrderFeed({required this.statuses});

  static OrderFeed fromJson(Map<String, dynamic> e) {
    final statuses = <String>[];
    for (final v in e['statuses']) {
      statuses.add(v);
    }
    return OrderFeed(statuses: statuses);
  }
}

/// 我的接口返回：头像 + 订单统计 + 功能菜单。
class MineFeed {
  final String avatar;
  final List<List<String>> stats;
  final List<MenuEntry> menu;

  const MineFeed({
    required this.avatar,
    required this.stats,
    required this.menu,
  });

  static MineFeed fromJson(Map<String, dynamic> e) {
    final stats = <List<String>>[];
    for (final row in e['stats']) {
      final cells = <String>[];
      for (final v in row) {
        cells.add(v);
      }
      stats.add(cells);
    }
    final menu = <MenuEntry>[];
    for (final m in e['menu']) {
      menu.add(MenuEntry.fromJson(m));
    }
    return MineFeed(avatar: e['avatar'], stats: stats, menu: menu);
  }
}

/// 搜索接口返回：热搜词 + 猜你想去。
class SearchFeed {
  final List<String> hot;
  final List<Spot> guesses;

  const SearchFeed({required this.hot, required this.guesses});

  static SearchFeed fromJson(Map<String, dynamic> e) {
    final hot = <String>[];
    for (final v in e['hot']) {
      hot.add(v);
    }
    final guesses = <Spot>[];
    for (final s in e['guesses']) {
      guesses.add(Spot.fromJson(s));
    }
    return SearchFeed(hot: hot, guesses: guesses);
  }
}

/// 资源专题接口返回：专题本身 + 相关推荐。
class ResourceFeed {
  final Resource resource;
  final List<Post> related;

  const ResourceFeed({required this.resource, required this.related});

  static ResourceFeed fromJson(Map<String, dynamic> e) {
    final related = <Post>[];
    for (final p in e['related']) {
      related.add(Post.fromJson(p));
    }
    return ResourceFeed(
      resource: Resource.fromJson(e['resource']),
      related: related,
    );
  }
}

/// 我的页菜单项。
class MenuEntry {
  final String emoji;
  final String title;

  /// 点击后跳转的页面类型：orders / webview / showcase。
  final String screen;
  final String arg;

  const MenuEntry({
    required this.emoji,
    required this.title,
    required this.screen,
    this.arg = '',
  });

  static MenuEntry fromJson(Map<String, dynamic> e) {
    return MenuEntry(
      emoji: e['emoji'],
      title: e['title'],
      screen: e['screen'],
      arg: e['arg'],
    );
  }
}
