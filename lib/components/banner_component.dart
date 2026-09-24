import 'package:flutter/material.dart';
import 'package:ui_component/ui_component.dart';

/// components/ 目录下多文件多组件演示：
/// BannerCard 独立于 hello_component.dart，单独产出：
///   banner_component.component.js
/// 运行时与 HelloCard/HelloPanel 共享同一个 __components 注册表。
@UIComponent('BannerCard')
class BannerCard extends StatefulWidget {
  const BannerCard({super.key});

  @override
  State<BannerCard> createState() => _BannerCardState();
}

class _BannerCardState extends State<BannerCard> {
  // 全量生成：_views → JS 属性 `_views`
  int _views = 0;

  // 生命周期方法也全量生成（initState/dispose/... 不再跳过），
  // HotPatchWidget 在对应生命周期回调同名 JS 方法。
  // 这里演示：JS 版首帧会是 views = 5，证明 JS initState 被回调。
  @override
  void initState() {
    super.initState();
    _views = 5;
  }

  // 全量生成：bump → JS 方法 `bump`
  void bump() {
    setState(() => _views++);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Banner from another file',
          style: const TextStyle(fontSize: 20, color: Colors.teal),
        ),
        Text('views = $_views'),
        ElevatedButton(
          onPressed: bump,
          child: const Text('Bump'),
        ),
      ],
    );
  }
}
