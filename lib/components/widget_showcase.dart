import 'package:flutter/material.dart';
import 'package:hot_patch/hot_patch.dart';

import 'widget_details.dart';

/// 常用组件导航列表页（普通页面，无 @UIComponent 注解）：
/// 分组列出 Flutter 常用组件，点击条目进入对应详情页。
/// 详情页是 @UIComponent 注解组件（widget_details.dart），同一份代码
/// 原生可直接用、也可由 HotPatchWidget 加载 JS 产物热更（原生 vs JS 同屏）。
class WidgetShowcase extends StatelessWidget {
  const WidgetShowcase({super.key});

  static const List<_Group> groups = [
    _Group('文本展示', [
      _Entry('Text', '文案 / TextStyle / 截断 / 对齐 / 装饰', 'TextDetail'),
    ]),
    _Group('按钮操作', [
      _Entry('Button', 'Elevated / Text / Outlined + ButtonStyle 全属性', 'ButtonDetail'),
    ]),
    _Group('布局', [
      _Entry('Row / Column / Stack', 'Expanded / Flexible / Wrap / Align / Padding / Center / SizedBox', 'LayoutDetail'),
    ]),
    _Group('图片图标', [
      _Entry('Image / Icon / CircleAvatar', '网络图片、图标、圆形头像', 'ImageDetail'),
    ]),
    _Group('容器装饰', [
      _Entry('Container / Card / Divider', '颜色、圆角、Padding、卡片、分割线', 'ContainerDetail'),
    ]),
    _Group('列表滚动', [
      _Entry('ListView / SingleChildScrollView', '滚动列表与长内容滚动', 'ScrollDetail'),
    ]),
    _Group('页面骨架', [
      _Entry('Scaffold / AppBar / Center', '页面级组件（仅 JS 热更版）', 'ScaffoldDetail'),
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
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
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
                    fullPage: e.component == 'ScaffoldDetail',
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

  /// 详情组件名（widget_details.dart 里的 @UIComponent 类名）。
  final String component;

  /// 页面级组件（Scaffold 等）不比对，直接 JS 热更版全屏展示。
  final bool fullPage;

  static const String _jsAsset = 'assets/components/components/widget_details.component.js';

  Widget _native() {
    return switch (component) {
      'TextDetail' => const TextDetail(),
      'ButtonDetail' => const ButtonDetail(),
      'LayoutDetail' => const LayoutDetail(),
      'ImageDetail' => const ImageDetail(),
      'ContainerDetail' => const ContainerDetail(),
      'ScrollDetail' => const ScrollDetail(),
      'ScaffoldDetail' => const ScaffoldDetail(),
      _ => const Text('未知组件'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final js = HotPatchWidget(
      jsAsset: _jsAsset,
      component: component,
    );
    if (fullPage) return js;
    return Scaffold(
      appBar: AppBar(title: Text('$component · 原生 vs JS 热更')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('原生组件', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: _native()),
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 20, 12, 4),
              child: Text('JS 热更（HotPatchWidget）', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: js),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
