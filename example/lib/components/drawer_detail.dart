import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// Drawer / endDrawer 详情：drawer 接进真实 Scaffold 后 AppBar 左侧自动出现
/// 汉堡按钮，右侧为 endDrawer 入口；点菜单项回写选中项。
@PatchEntry('DrawerDetail')
class DrawerDetail extends StatefulWidget {
  const DrawerDetail({super.key});

  @override
  State<DrawerDetail> createState() => _DrawerDetailState();
}

class _DrawerDetailState extends State<DrawerDetail> {
  /// 当前选中的菜单项（-1 = 未选）。
  int _picked = -1;

  void _pickOrders() {
    setState(() => _picked = 0);
  }

  void _pickFavorites() {
    setState(() => _picked = 1);
  }

  void _pickSettings() {
    setState(() => _picked = 2);
  }

  void _pickHelp() {
    setState(() => _picked = 3);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Drawer / endDrawer'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.indigo),
              child: const Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  '左侧抽屉',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('我的订单'),
              onTap: _pickOrders,
            ),
            ListTile(
              leading: const Icon(Icons.favorite_border),
              title: const Text('我的收藏'),
              onTap: _pickFavorites,
            ),
          ],
        ),
      ),
      endDrawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.teal),
              child: const Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  '右侧抽屉',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('设置'),
              onTap: _pickSettings,
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('帮助与关于'),
              onTap: _pickHelp,
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_open, size: 48, color: Colors.indigo),
            const SizedBox(height: 12),
            const Text('AppBar 左侧为汉堡按钮，右侧为 endDrawer 入口'),
            const SizedBox(height: 8),
            Text(_picked < 0 ? '尚未选择菜单项' : '选中菜单项 #$_picked'),
          ],
        ),
      ),
    );
  }
}
