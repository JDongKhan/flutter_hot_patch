import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dynamic_flutter_annotations/dynamic_flutter_annotations.dart';

/// 大图长列表 · 性能探针（`@PatchEntry` → 产物 patch/components/perf_list_page.js）。
///
/// 页面本体只做一件事：一个 [ListView.builder]（没有其它列表、没有分栏对比）。
/// 用来观察 JS 运行时在「大量条目 + 大图 + 每项都在跑动画」下的表现：
///
///   - 200 条数据，懒加载：只有进入视口（含 cacheExtent）的项才会被构建；
///   - 每条是一张通栏大图（210 高，`BoxFit.cover`）+ 标题 / 副标题 / 作者行 /
///     描述 / 标签 / 互动数，信息量按真实内容流来；
///   - 每条自带一个 [Timer] 驱动的隐式动画（HOT 徽标透明度、播放按钮缩放、
///     热度胶囊配色），插值在宿主侧完成，不逐帧过桥；
///   - 条目底部显示自身 build 次数，可直接看出「只重建自己」而不是整表重建。
@PatchEntry('PerfListPage')
class PerfListPage extends StatefulWidget {
  const PerfListPage({super.key});

  @override
  State<PerfListPage> createState() => _PerfListPageState();
}

/// 单条内容的数据载体（字段全部是可翻译的基础类型）。
class PerfEntry {
  /// 序号（从 0 开始，展示时 +1）。
  final int seq;
  final String img;
  final String title;
  final String sub;
  final String emoji;
  final String author;
  final String time;
  final String desc;
  final List<String> tags;
  final String likes;
  final String comments;
  final String views;

  const PerfEntry({
    required this.seq,
    required this.img,
    required this.title,
    required this.sub,
    required this.emoji,
    required this.author,
    required this.time,
    required this.desc,
    required this.tags,
    required this.likes,
    required this.comments,
    required this.views,
  });
}

class _PerfListPageState extends State<PerfListPage> {
  /// 条目总数：数据量够大才能看出滚动时按需构建的差别。
  static const int _total = 200;

  static const List<String> _imgs = [
    'assets/images/photo-1448375240586-882707db888b.jpg',
    'assets/images/photo-1449965408869-eaa3f722e40d.jpg',
    'assets/images/photo-1464822759023-fed622ff2c3b.jpg',
    'assets/images/photo-1470004914212-05527e49370b.jpg',
    'assets/images/photo-1470071459604-3b5ec3a7fe05.jpg',
    'assets/images/photo-1470770841072-f978cf4d019e.jpg',
    'assets/images/photo-1478131143081-80f7f84ca84d.jpg',
    'assets/images/photo-1483664852095-d6cc6870702d.jpg',
    'assets/images/photo-1500375592092-40eb2168fd21.jpg',
    'assets/images/photo-1500530855697-b586d89ba3ee.jpg',
    'assets/images/photo-1501785888041-af3ef285b470.jpg',
    'assets/images/photo-1507525428034-b723cf961d3e.jpg',
  ];

  static const List<String> _titles = [
    '川西雪山 · 日照金山机位',
    '海边公路 · 一场说走就走的自驾',
    '古镇夜色 · 灯影里的石板路',
    '草原深处 · 无人区露营日记',
    '高原湖泊 · 风吹过的两个下午',
    '雪山脚下 · 一碗热汤面',
    '海岛清晨 · 第一缕光落在礁石上',
    '峡谷徒步 · 走了 18 公里之后',
    '沙漠星空 · 银河肉眼可见',
    '林间小屋 · 关掉手机的一晚',
    '温泉小镇 · 雪天泡汤指南',
    '城市天际线 · 天台看落日',
  ];

  static const List<String> _subs = [
    '海拔 4200 米 · 6 小时徒步 · 含向导',
    '全程 320 公里 · 3 晚住宿 · 油费参考',
    '19:30 亮灯 · 最佳机位在石桥西侧',
    '露营 2 晚 · 夜间 0℃ · 需自带睡袋',
    '日出 06:12 · 建议提前 40 分钟到',
    '人均 45 元 · 排队约 20 分钟',
    '潮汐表显示 05:40 退潮',
    '累计爬升 860 米 · 补给点 2 处',
    '无光污染 · 建议带三脚架',
    '木屋 6 间 · 需提前两周预订',
    '室外 42℃ · 室内 39℃ · 含浴衣',
    '日落 18:26 · 天台 27 层',
  ];

  static const List<String> _emojis = ['🏔', '🚗', '🏮', '⛺', '🌊', '🍜', '🌅', '🥾', '🌌', '🏡', '♨️', '🌇'];

  static const List<String> _authors = [
    '山野慢行', '一只旅行箱', '半日闲', '去看海吧', '徒步日记',
    '深夜食堂', '风光记录者', '北纬三十度', '追星的人', '小院生活',
  ];

  static const List<String> _times = [
    '3 分钟前', '28 分钟前', '1 小时前', '今天 09:12', '昨天 21:40',
    '昨天 18:05', '2 天前', '3 天前', '上周', '10 月 28 日',
  ];

  static const List<String> _descs = [
    '这条线路走了三年，每次来都能遇到不一样的云。整理了一份详细的机位和补给点清单，'
        '需要的朋友可以直接收藏。',
    '一路都是沿海公路，弯道很多，注意控制车速。中途有两个观景平台可以停车拍照，'
        '建议留出半天时间慢慢走。',
    '亮灯之后人非常多，想拍空镜建议在 18:00 前占位。石桥西侧的倒影最完整，'
        '带上小光圈和三脚架。',
    '夜里的风比想象中大，帐篷地钉一定要打牢。营地有简易热水，但信号几乎没有，'
        '提前下载好离线地图。',
    '清晨的湖面基本没有风，倒影非常清楚。太阳出来后半小时光线就变硬了，'
        '想拍柔和的画面要早起。',
    '下山之后第一件事就是找吃的，这家面馆的汤头很浓，加了一份牛肉才 12 块，'
        '老板娘人很好。',
    '退潮之后的礁石上会露出很多小水洼，逆光拍剪影效果不错。注意不要踩到贝类，'
        '鞋底容易打滑。',
    '全程 18 公里，累计爬升 860 米，正常体力 7 小时左右。中途两个补给点只卖水，'
        '干粮要自己带够。',
    '十一点之后银河升到头顶，肉眼可以清楚看到一条光带。拍星轨的话建议 30 秒曝光，'
        '每张间隔 2 秒。',
    '木屋没有空调，但夜里很凉快。屋里只有一盏灯和一个插座，'
        '想办公的话建议自带插排。',
    '雪天泡汤是这趟行程最值的一段时间。室外池的温度在 42℃ 左右，'
        '从池子里出来要马上裹上浴衣。',
    '天台的落日会被高楼挡掉一部分，18:20 之后光线反而更好，'
        '蓝调时刻持续大约 15 分钟。',
  ];

  static const List<String> _tagPool = [
    '攻略', '自驾', '露营', '徒步', '摄影', '美食', '日出', '小众', '亲子', '避坑',
  ];

  /// 列表数据：第一次 build 时一次性生成（不请求接口），保证滚动压力集中在渲染上。
  ///
  /// 在 build 里生成而不是 initState：产物只认识「build 局部变量」，
  /// initState 里的循环变量进不了组件数据作用域，构造参数会整条翻译不出来。
  List<PerfEntry> _entries = [];

  @override
  Widget build(BuildContext context) {
    if (_entries.isEmpty) {
      final items = <PerfEntry>[];
      for (var i = 0; i < _total; i++) {
        final int seqNo = i;
        final String img = _imgs[i % _imgs.length];
        final String title = _titles[i % _titles.length];
        final String sub = _subs[i % _subs.length];
        final String emoji = _emojis[i % _emojis.length];
        final String author = _authors[i % _authors.length];
        final String time = _times[i % _times.length];
        final String desc = _descs[i % _descs.length];
        final String tag0 = _tagPool[i % _tagPool.length];
        final String tag1 = _tagPool[(i + 3) % _tagPool.length];
        final String tag2 = _tagPool[(i + 7) % _tagPool.length];
        final int likeCount = (i * 137) % 9000 + 120;
        final int commentCount = (i * 29) % 420 + 8;
        final int viewCount = (i * 173) % 88000 + 900;
        items.add(
          PerfEntry(
            seq: seqNo,
            img: img,
            title: title,
            sub: sub,
            emoji: emoji,
            author: author,
            time: time,
            desc: desc,
            tags: <String>[tag0, tag1, tag2],
            likes: '$likeCount',
            comments: '$commentCount',
            views: '$viewCount',
          ),
        );
      }
      _entries = items;
    }
    // 页面只有一个 ListView.builder：没有外层滚动容器、没有其它列表。
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      itemCount: _entries.length,
      itemBuilder: (context, index) => _PerfCard(entry: _entries[index]),
    );
  }
}

/// 单条内容卡：大图 + 文字区 + 每项自跑一个隐式动画。
class _PerfCard extends StatefulWidget {
  const _PerfCard({required this.entry});

  final PerfEntry entry;

  @override
  State<_PerfCard> createState() => _PerfCardState();
}

class _PerfCardState extends State<_PerfCard> {
  /// 动画开关：每条自己翻转，互不同步，滚动时能看出「每项都在动」。
  bool _pulse = false;

  /// 本卡片 build 次数：只重建自己时它才增长。
  int _builds = 0;

  Timer? _pulseTimer;

  @override
  void initState() {
    super.initState();
    _pulseTimer = Timer.periodic(const Duration(milliseconds: 1400), (timer) {
      if (!mounted) return;
      setState(() => _pulse = !_pulse);
    });
  }

  @override
  void dispose() {
    _pulseTimer?.cancel();
    _pulseTimer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _builds += 1;
    final e = widget.entry;
    final String tag0 = e.tags[0];
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 通栏大图：210 高，封面裁切，底部压一层黑色渐变保证文字可读。
            SizedBox(
              height: 210,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    e.img,
                    fit: BoxFit.cover,
                    errorBuilder: (_, err, stack) =>
                        Container(color: const Color(0xFFDDE3EC)),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0x00000000), Color(0xE6000000)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          e.sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFFD6DCE6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 左上角编号（说明当前是第几条，滚动时便于定位）
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xB3000000),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        'NO.${e.seq + 1}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  // 动画一：HOT 徽标呼吸（透明度插值）
                  Positioned(
                    right: 10,
                    top: 8,
                    child: AnimatedOpacity(
                      opacity: _pulse ? 1.0 : 0.35,
                      duration: const Duration(milliseconds: 1400),
                      curve: Curves.easeInOut,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5A36),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'HOT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 动画二：播放按钮缩放缓动
                  Center(
                    child: AnimatedScale(
                      scale: _pulse ? 1.12 : 1.0,
                      duration: const Duration(milliseconds: 1400),
                      curve: Curves.easeInOut,
                      child: Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0x33FFFFFF),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: const Color(0x66FFFFFF)),
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          size: 26,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 作者行 + 动画三：热度胶囊配色切换
                  Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F2FF),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          e.emoji,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.author,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              e.time,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFFA3A9B4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 1400),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _pulse
                              ? const Color(0xFFFFF0E6)
                              : const Color(0xFFE8F2FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '#$tag0',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFC8621E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    e.desc,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: Color(0xFF4D5462),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 5,
                    children: [
                      for (final t in e.tags)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F5F7),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            '#$t',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF5C6270),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // 互动数 + 本项 build 次数
                  Row(
                    children: [
                      const Icon(
                        Icons.favorite_border,
                        size: 14,
                        color: Color(0xFF98A0AC),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        e.likes,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF98A0AC),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 14,
                        color: Color(0xFF98A0AC),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        e.comments,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF98A0AC),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.visibility_outlined,
                        size: 14,
                        color: Color(0xFF98A0AC),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        e.views,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF98A0AC),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'build $_builds',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFFC3C8D2),
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
    );
  }
}
