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
}

/// 首页轮播 banner。
class HomeBanner {
  final String img;
  final String title;
  final String sub;

  const HomeBanner({required this.img, required this.title, required this.sub});
}

/// 首页九宫格入口。
class GridEntry {
  final String emoji;
  final String title;

  const GridEntry({required this.emoji, required this.title});
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

  const Post({
    required this.id,
    required this.title,
    required this.sub,
    required this.type,
    required this.author,
    required this.time,
    required this.img,
    required this.like,
  });
}

/// 社区横向资源推荐卡。
class Resource {
  final String id;
  final String title;
  final String sub;
  final String img;

  const Resource({
    required this.id,
    required this.title,
    required this.sub,
    required this.img,
  });
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
}
