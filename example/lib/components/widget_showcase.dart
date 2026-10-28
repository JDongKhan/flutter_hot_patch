import 'package:flutter/material.dart';
import 'package:hot_patch/hot_patch.dart';
import 'animated_list_detail.dart';
import 'automatic_keep_alive_detail.dart';
import 'color_filtered_detail.dart';
import 'dismissible_detail.dart';
import 'fade_in_image_detail.dart';
import 'focus_detail.dart';
import 'hero_detail.dart';
import 'explicit_animation_detail.dart';
import 'implicit_animation_detail.dart';
import 'rich_text_detail.dart';
import 'widget_details.dart';

/// 常用组件导航列表页（普通页面，无 @PatchEntry 注解）：
/// 分组列出 Flutter 常用组件，点击条目进入对应详情页。
/// 详情页是 @PatchEntry 注解组件（widget_details.dart），同一份代码
/// 原生可直接用、也可由 JsUiWidget 加载 JS 产物热更（原生 vs JS 同屏）。
class WidgetShowcase extends StatelessWidget {
  const WidgetShowcase({super.key});

  static const List<_Group> groups = [
    _Group('文本展示', [
      _Entry('Text', '文案 / TextStyle / 截断 / 对齐 / 装饰', 'TextDetail'),
      _Entry('RichText', 'TextSpan 树：嵌套子串、不同样式、maxLines + ellipsis', 'RichTextDetail'),
    ]),
    _Group('按钮操作', [_Entry('Button', 'Elevated / Text / Outlined + ButtonStyle 全属性', 'ButtonDetail')]),
    _Group('布局', [
      _Entry(
        'Row / Column / Stack',
        'Expanded / Flexible / Wrap / Align / Padding / Center / SizedBox',
        'LayoutDetail',
      ),
    ]),
    _Group('图片图标', [
      _Entry('Image / Icon / CircleAvatar', '网络图片、图标、圆形头像', 'ImageDetail'),
      _Entry('FadeInImage', '占位图 → 目标图淡入（assetNetwork / 普通构造）', 'FadeInImageDetail'),
    ]),
    _Group('容器装饰', [
      _Entry('Container / Card / Divider', '颜色、圆角、Padding、卡片、分割线', 'ContainerDetail'),
      _Entry('ColorFiltered', '颜色滤镜：mode(multiply/modulate) 与 20 项矩阵灰度', 'ColorFilteredDetail'),
    ]),
    _Group('列表滚动', [
      _Entry('ListView / SingleChildScrollView', '滚动列表与长内容滚动', 'ScrollDetail'),
      _Entry('AnimatedList', '增删补间：GlobalKey.currentState 的 insertItem / removeItem', 'AnimatedListDetail'),
      _Entry('Dismissible', '滑动删除：background / secondaryBackground + confirmDismiss 方向确认', 'DismissibleDetail'),
      _Entry('ReorderableListView', '长按拖拽重排：onReorder 双参事件，重排 / 添加列表项', 'ReorderListDetail'),
    ]),
    _Group('Key 家族', [
      _Entry(
        'Key / ValueKey / ObjectKey / UniqueKey / PageStorageKey / GlobalKey',
        '列表匹配 / 对象身份 / 强制重建 / 滚动位置持久化 / 宿主端量测（仅 JS 热更版）',
        'KeyDetail',
      ),
    ]),
    _Group('Sliver 滚动', [
      _Entry('CustomScrollView', 'Sliver 全家桶整页（仅 JS 热更版）', 'SliverDetail'),
      _Entry('GridView', 'GridView 懒加载验证（仅 JS 热更版）', 'GridDetail'),
    ]),
    _Group('页面骨架', [
      _Entry('Scaffold / AppBar / Center', '页面级组件（仅 JS 热更版）', 'ScaffoldDetail'),
      _Entry('Drawer / endDrawer', '抽屉 + AppBar 汉堡按钮（仅 JS 热更版）', 'DrawerDetail'),
    ]),
    _Group('Tab 切换', [
      _Entry('TabBar / TabBarView', 'DefaultTabController + 显式 TabController 驱动切页', 'TabDetail'),
    ]),
    _Group('分页视图', [_Entry('PageView', '分页切换 + 页码回传', 'PageViewDetail')]),
    _Group('表单输入', [_Entry('TextField / Radio / Dropdown', '输入框、单选、下拉、开关、勾选、滑块', 'InputDetail')]),
    _Group('焦点交互', [
      _Entry('Focus / FocusNode', 'requestFocus / unfocus、onFocusChange、hasFocus、canRequestFocus', 'FocusDetail'),
      _Entry('Hero', '跨路由共享元素：点卡片飞向目标页，返回时飞回', 'HeroDetail'),
    ]),
    _Group('进度指示', [_Entry('ProgressIndicator', '圆形 / 线性进度条', 'ProgressDetail')]),
    _Group('状态管理', [
      _Entry('ChangeNotifier', 'ListenableBuilder 局部重建（跨文件模型 + dispose）', 'NotifierCard'),
      _Entry('AutomaticKeepAlive', '切页保活：wantKeepAlive 声明决定离屏 State 是否销毁', 'AutomaticKeepAliveDetail'),
    ]),
    _Group('无状态组件', [_Entry('StatelessWidget', '无 State，build 在 widget 类自身，props 走构造参数', 'StatelessCard')]),
    _Group('动画', [
      _Entry('隐式动画', 'AnimatedContainer / Opacity / Scale / Rotation / Slide / CrossFade / Size / Switcher（宿主插值）', 'ImplicitAnimationDetail'),
      _Entry('显式动画', 'AnimationController + AnimatedBuilder + *Transition（宿主 Ticker 驱动）', 'ExplicitAnimationDetail'),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        for (final g in groups) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              g.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
          ),
          for (final e in g.entries)
            ListTile(
              leading: const Icon(Icons.widgets_outlined),
              title: Text(e.title),
              subtitle: Text(e.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => WidgetDetailPage(
                    component: e.component,
                    fullPage: e.component == 'ScaffoldDetail' ||
                        e.component == 'SliverDetail' ||
                        e.component == 'GridDetail' ||
                        e.component == 'KeyDetail' ||
                        e.component == 'DrawerDetail',
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _Group {
  final String title;
  final List<_Entry> entries;
  const _Group(this.title, this.entries);
}

class _Entry {
  final String title;
  final String subtitle;
  final String component;
  const _Entry(this.title, this.subtitle, this.component);
}

/// 详情容器页：原生组件 ↔ JS 热更版本同屏对比。
/// 页面级组件（fullPage=true）无法同屏，直接展示 JS 热更版。
class WidgetDetailPage extends StatelessWidget {
  const WidgetDetailPage({super.key, required this.component, this.fullPage = false});

  /// 详情组件名（widget_details.dart 里的 @PatchEntry 类名）。
  final String component;

  /// 页面级组件（Scaffold 等）不比对，直接 JS 热更版全屏展示。
  final bool fullPage;

  static const String _jsZip = 'http://127.0.0.1:8765/patch/patch.zip';

  /// 组件名 → 产物入口（`patch/<源文件镜像路径>.js`）。
  ///
  /// 动画 demo 按类拆在独立源文件里，因此入口不再固定为 widget_details.js：
  /// 产物路径由 build_runner 镜像源码路径生成（见 build.yaml 的 patch_entry）。
  static const Map<String, String> _jsEntries = {
    'AnimatedListDetail': 'components/animated_list_detail.js',
    'AutomaticKeepAliveDetail': 'components/automatic_keep_alive_detail.js',
    'ColorFilteredDetail': 'components/color_filtered_detail.js',
    'DismissibleDetail': 'components/dismissible_detail.js',
    'FadeInImageDetail': 'components/fade_in_image_detail.js',
    'FocusDetail': 'components/focus_detail.js',
    'HeroDetail': 'components/hero_detail.js',
    'RichTextDetail': 'components/rich_text_detail.js',
    'ImplicitAnimationDetail': 'components/implicit_animation_detail.js',
    'ExplicitAnimationDetail': 'components/explicit_animation_detail.js',
  };

  String get _jsEntry => _jsEntries[component] ?? 'components/widget_details.js';

  /// 拼接补丁 URL：component 动态、entry 按源文件，走 query 参数。
  String get _jsAsset => '$_jsZip?component=$component&entry=${Uri.encodeComponent(_jsEntry)}';

  Widget _native() {
    return switch (component) {
      'TextDetail' => const TextDetail(),
      'RichTextDetail' => const RichTextDetail(),
      'ButtonDetail' => const ButtonDetail(),
      'LayoutDetail' => const LayoutDetail(),
      'ImageDetail' => const ImageDetail(),
      'ContainerDetail' => const ContainerDetail(),
      'ScrollDetail' => const ScrollDetail(),
      'AnimatedListDetail' => const AnimatedListDetail(),
      'AutomaticKeepAliveDetail' => const AutomaticKeepAliveDetail(),
      'ColorFilteredDetail' => const ColorFilteredDetail(),
      'DismissibleDetail' => const DismissibleDetail(),
      'FadeInImageDetail' => const FadeInImageDetail(),
      'FocusDetail' => const FocusDetail(),
      'HeroDetail' => const HeroDetail(),
      'ReorderListDetail' => const ReorderListDetail(),
      'SliverDetail' => const SliverDetail(),
      'GridDetail' => const GridDetail(),
      'KeyDetail' => const KeyDetail(),
      'ScaffoldDetail' => const ScaffoldDetail(),
      'DrawerDetail' => const DrawerDetail(),
      'TabDetail' => const TabDetail(),
      'PageViewDetail' => const PageViewDetail(),
      'InputDetail' => const InputDetail(),
      'ProgressDetail' => const ProgressDetail(),
      'NotifierCard' => const NotifierCard(),
      'StatelessCard' => const StatelessCard(title: 'Hello Stateless', subtitle: '原生直接渲染，无需 State', badge: 'FLUTTER'),
      'ImplicitAnimationDetail' => const ImplicitAnimationDetail(),
      'ExplicitAnimationDetail' => const ExplicitAnimationDetail(),
      _ => const Text('未知组件'),
    };
  }

  /// JS 热更侧构造参数：只有依赖构造参数的组件（如 StatelessCard 的
  /// title/subtitle/badge）需要在此传入；StatefulWidget 的初始状态
  /// 硬编码在 JS 构造函数里，不需要传 props。
  Map<String, dynamic> _jsProps() {
    return switch (component) {
      'StatelessCard' => const {'title': 'Hello Stateless', 'subtitle': '原生直接渲染，无需 State', 'badge': 'FLUTTER'},
      // Hero 两侧必须在同一路由里用**不同 tag**（同 tag 会触发重复 Hero 断言）。
      'HeroDetail' => const {'tag': 'hero-js', 'label': 'JS 热更 Hero'},
      _ => const {},
    };
  }

  @override
  Widget build(BuildContext context) {
    final js = JsUiWidget(
      jsAsset: _jsAsset,
      props: _jsProps(),
    );
    if (fullPage) return js;

    // 大屏（宽度 ≥ 700，桌面/iPad/横屏）左右并排对比；小屏上下堆叠。
    Column side(String title, Widget child) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: child),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('$component · 原生 vs JS 热更')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 700;
          final nativeSide = SingleChildScrollView(child: side('原生组件', _native()));
          final jsSide = SingleChildScrollView(child: side('JS 热更（JsUiWidget）', js));
          if (wide) {
            // 左右对比：两列各自独立滚动
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: nativeSide),
                const VerticalDivider(width: 1),
                Expanded(child: jsSide),
              ],
            );
          }
          // 上下堆叠
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [nativeSide, const SizedBox(height: 12), jsSide, const SizedBox(height: 24)],
            ),
          );
        },
      ),
    );
  }
}
