import 'package:flutter/material.dart';

import '../widget_showcase.dart';

/// 基础语法导航列表页（普通页面，无 @PatchEntry 注解）：
/// 与「常用组件 · 列表」同级，点击条目进入对应详情页（原生 vs JS 热更）。
///
/// 详情组件在 grammar_details.dart，由 `patch/components/grammar_details.js`
/// 实例化，入口映射见 [WidgetDetailPage] 的 `_jsEntries`。
class GrammarShowcase extends StatelessWidget {
  const GrammarShowcase({super.key});

  static const List<_Entry> _entries = [
    _Entry('Mixin · State 扩展', 'State 混入跨包 StateLogMixin：点击时打印状态日志', 'MixinDetail'),
    _Entry('Extension · String 扩展', 'String 扩展跨包 logText：点击时打印字符串日志', 'ExtensionDetail'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        for (final e in _entries)
          ListTile(
            leading: const Icon(Icons.code),
            title: Text(e.title),
            subtitle: Text(e.subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => WidgetDetailPage(component: e.component)),
            ),
          ),
      ],
    );
  }
}

class _Entry {
  final String title;
  final String subtitle;
  final String component;
  const _Entry(this.title, this.subtitle, this.component);
}
