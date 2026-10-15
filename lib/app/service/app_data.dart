/// App 全量示例数据（与 docs/app-prototype.html 同一套）——**模拟后端的数据源**。
///
/// 相当于真实项目里的「假接口返回体」：业务页面**不直接读它**，一律经
/// [AppService]（lib/app/service/app_service.dart）以「模拟网络请求」的方式取。
/// 唯一例外是 `kAvatarImg` / `kBanners` 这类**纯展示用图片地址**：它们被
/// detail_pages.dart 的评论头像、WebView 演示页直接引用（那些页面不走接口、
/// 也不参与翻译），不属于「业务数据」。
///
/// 以 **顶层 const** 存放：翻译器会把本文件产成 `app_data.js`，
/// `app_service.js` 跨文件 `import` 复用（组件/普通类共用同一套 import 规则）。
library;

import '../model/app_models.dart';

const String _img = 'https://trae-api-cn.mchost.guru/api/ide/v1/text_to_image';

const String kAvatarImg =
    '$_img?prompt=portrait%20of%20a%20smiling%20young%20woman%20traveler%20avatar&image_size=square';

const String kAdImg =
    '$_img?prompt=hot%20air%20balloons%20over%20cappadocia%20at%20sunrise%20wide%20travel%20banner&image_size=landscape_4_3';

const List<HomeBanner> kBanners = [
  HomeBanner(
    img:
        '$_img?prompt=aerial%20view%20of%20tropical%20island%20beach%20turquoise%20water%20travel%20photography&image_size=landscape_16_9',
    title: '海岛季 · 早鸟立减 300',
    sub: '10月出行专属优惠',
  ),
  HomeBanner(
    img:
        '$_img?prompt=snowy%20mountain%20lake%20at%20sunrise%20mirror%20reflection%20travel%20photography&image_size=landscape_16_9',
    title: '雪山湖泊 6 日环线',
    sub: '含全程住宿与向导',
  ),
  HomeBanner(
    img:
        '$_img?prompt=ancient%20chinese%20water%20town%20with%20lanterns%20at%20dusk&image_size=landscape_16_9',
    title: '江南水乡夜游船票',
    sub: '限时 8 折，可随时退',
  ),
];

const List<GridEntry> kGrid = [
  GridEntry(emoji: '🎫', title: '门票'),
  GridEntry(emoji: '🏨', title: '酒店'),
  GridEntry(emoji: '✈️', title: '机票'),
  GridEntry(emoji: '📖', title: '攻略'),
  GridEntry(emoji: '🚗', title: '租车'),
  GridEntry(emoji: '🍜', title: '美食'),
  GridEntry(emoji: '🎭', title: '演出'),
  GridEntry(emoji: '⋯', title: '更多'),
];

const List<Spot> kSpots = [
  Spot(
    id: 's1',
    title: '海岛三日游',
    sub: '含往返机票 · 4星海景房',
    sold: '2.3k 人已订',
    tag: '热销',
    img:
        '$_img?prompt=tropical%20island%20resort%20beach%20wooden%20bungalow%20clear%20sea&image_size=landscape_4_3',
    desc: '湛蓝海水与细软白沙滩，行程含出海浮潜、日落巡航与海鲜大餐，适合情侣与家庭出行。',
    price: 1280,
    tags: ['含机票', '含2晚酒店', '中文导游', '免费退改'],
  ),
  Spot(
    id: 's2',
    title: '古镇自由行',
    sub: '慢游水乡 · 精品民宿',
    sold: '1.1k 人已订',
    tag: '慢游',
    img:
        '$_img?prompt=chinese%20ancient%20town%20canal%20stone%20bridge%20old%20houses&image_size=landscape_4_3',
    desc: '青石板路、枕水人家。清晨的薄雾与傍晚的灯笼，是这座古镇最好的两个时刻。',
    price: 860,
    tags: ['含1晚民宿', '含早餐', '可选接驳', '自由行程'],
  ),
  Spot(
    id: 's3',
    title: '草原自驾',
    sub: '越野穿越 · 5日行程',
    sold: '860 人已订',
    tag: '自驾',
    img:
        '$_img?prompt=vast%20green%20grassland%20winding%20road%20blue%20sky%20road%20trip&image_size=landscape_4_3',
    desc: '沿草原天路一路向北，途经牧场、湖泊与白桦林，5天4晚深度穿越。',
    price: 1520,
    tags: ['含租车', '含油费', '车队领航', '含保险'],
  ),
  Spot(
    id: 's4',
    title: '雪乡温泉',
    sub: '雪景温泉 · 亲子首选',
    sold: '640 人已订',
    tag: '温泉',
    img:
        '$_img?prompt=snow%20village%20wooden%20houses%20winter%20warm%20lights&image_size=landscape_4_3',
    desc: '雪蘑菇屋顶与露天温泉的组合，夜里零下二十度泡汤看星空，是冬天的限定体验。',
    price: 1980,
    tags: ['含温泉', '含门票', '亲子房', '含接送'],
  ),
];

const List<Post> kPosts = [
  Post(
    id: 'p1',
    title: '京郊露营全攻略',
    sub: '装备清单、营地选择与避坑指南，新手一次看懂。',
    type: '攻略',
    author: '山野派',
    time: '2 天前',
    img:
        '$_img?prompt=camping%20gear%20flat%20lay%20on%20grass%20outdoor%20equipment&image_size=square',
    like: 2300,
  ),
  Post(
    id: 'p2',
    title: '小众古镇自驾路线',
    sub: '避开人潮，3 天 2 晚串联 4 个安静的江南小镇。',
    type: '游记',
    author: '慢行记',
    time: '4 天前',
    img:
        '$_img?prompt=narrow%20old%20town%20alley%20stone%20steps%20traditional%20houses&image_size=square',
    like: 1800,
  ),
  Post(
    id: 'p3',
    title: '深秋赏叶地图',
    sub: '江浙沪最适合看红叶的 12 个地方，附最佳观赏期。',
    type: '榜单',
    author: '旅拍君',
    time: '1 周前',
    img:
        '$_img?prompt=autumn%20forest%20path%20with%20red%20leaves&image_size=square',
    like: 960,
  ),
  Post(
    id: 'p4',
    title: '城市周边露营地测评',
    sub: '实测 8 个露营地：水电、厕所、风景与性价比。',
    type: '攻略',
    author: '露营实验室',
    time: '3 天前',
    img:
        '$_img?prompt=lakeside%20campsite%20tents%20mountains%20morning%20mist&image_size=square',
    like: 1420,
  ),
  Post(
    id: 'p5',
    title: '周末两天一夜怎么玩',
    sub: '不用请假也能出发的 6 条短线行程，人均 500 起。',
    type: '游记',
    author: '周末出发',
    time: '5 天前',
    img:
        '$_img?prompt=weekend%20road%20trip%20car%20on%20country%20road%20sunny&image_size=square',
    like: 1180,
  ),
  Post(
    id: 'p6',
    title: '江浙沪古镇榜单',
    sub: '按人气、美食与夜景综合排名，第一名出人意料。',
    type: '榜单',
    author: '江南笔记',
    time: '6 天前',
    img:
        '$_img?prompt=jiangnan%20water%20town%20boat%20at%20dusk%20lanterns&image_size=square',
    like: 2040,
  ),
];

const List<Resource> kResources = [
  Resource(
    id: 'r1',
    title: '露营地推荐',
    sub: '12 个营地',
    img:
        '$_img?prompt=camping%20tent%20in%20forest%20at%20dusk%20warm%20light&image_size=landscape_4_3',
  ),
  Resource(
    id: 'r2',
    title: '城市漫步路线',
    sub: '秋日限定',
    img:
        '$_img?prompt=autumn%20city%20street%20walk%20golden%20leaves%20sunlight&image_size=landscape_4_3',
  ),
  Resource(
    id: 'r3',
    title: '海边日落机位',
    sub: '拍照攻略',
    img:
        '$_img?prompt=seaside%20lighthouse%20at%20sunset%20waves%20rocks&image_size=landscape_4_3',
  ),
];

const List<Order> kOrders = [
  Order(
    no: '20261013001',
    status: '待付款',
    title: '海岛三日游 · 2 人',
    spec: '2026-10-20 出发 · 含机酒',
    img:
        '$_img?prompt=happy%20couple%20on%20tropical%20beach%20vacation&image_size=square',
    price: 2560,
    step: 0,
  ),
  Order(
    no: '20261012007',
    status: '已完成',
    title: '古镇自由行 · 1 人',
    spec: '2026-09-28 出发 · 含民宿',
    img:
        '$_img?prompt=traveler%20walking%20in%20chinese%20ancient%20town%20alley&image_size=square',
    price: 860,
    step: 3,
  ),
  Order(
    no: '20261011033',
    status: '待收货',
    title: '草原自驾套餐',
    spec: '2026-10-15 出发 · 含租车',
    img:
        '$_img?prompt=car%20road%20trip%20on%20grassland%20highway&image_size=square',
    price: 1520,
    step: 2,
  ),
  Order(
    no: '20261010022',
    status: '待发货',
    title: '雪乡温泉 · 2 人',
    spec: '2026-11-02 出发 · 含温泉',
    img:
        '$_img?prompt=snow%20village%20wooden%20houses%20winter%20warm%20lights&image_size=square',
    price: 3960,
    step: 1,
  ),
];

const List<String> kOrderStatus = ['全部', '待付款', '待发货', '待收货', '已完成'];

const List<String> kCommunityTabs = ['广场', '推荐'];
const List<String> kSorts = ['综合', '最新', '最热'];
const List<String> kPostTypes = ['全部', '攻略', '游记', '榜单'];
const List<String> kDists = ['不限', '1km 内', '5km 内', '20km 内'];
const List<String> kPriceRanges = ['不限', '免费', '¥100 以下', '¥100 以上'];
const List<String> kHotSearch = [
  '海岛',
  '古镇',
  '露营',
  '温泉',
  '赏秋',
  '自驾',
  '亲子',
  '美食',
];

/// 我的页统计项（标题 + 数值）。
const List<List<String>> kMineStats = [
  ['待付款', '1'],
  ['待收货', '1'],
  ['收藏', '12'],
  ['优惠券', '3'],
];

const List<MenuEntry> kMineMenu = [
  MenuEntry(emoji: '📦', title: '我的订单', screen: 'orders'),
  MenuEntry(emoji: '⭐', title: '我的收藏', screen: 'webview', arg: '我的收藏'),
  MenuEntry(emoji: '⚙️', title: '设置', screen: 'webview', arg: '设置'),
  MenuEntry(emoji: '❓', title: '帮助与关于', screen: 'webview', arg: '帮助与关于'),
];
