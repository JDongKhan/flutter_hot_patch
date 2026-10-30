import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

@PatchEntry('ScaffoldDetail')
class ScaffoldDetail extends StatefulWidget {
  const ScaffoldDetail({super.key});

  @override
  State<ScaffoldDetail> createState() => _ScaffoldDetailState();
}

class _ScaffoldDetailState extends State<ScaffoldDetail> {
  int _navIndex = 0;

  void _onNavTap(int index) {
    setState(() => _navIndex = index);
  }

  void _onFab() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        leading: const Icon(Icons.menu),
        title: const Text('Scaffold / AppBar / FAB / BottomNav'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
        toolbarHeight: 56,
        actions: const [
          Icon(Icons.search, color: Colors.white),
          SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.extension, size: 48, color: Colors.deepPurple),
              const SizedBox(height: 12),
              const Text('页面骨架组件演示'),
              Text('BottomNav 选中：$_navIndex'),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onFab,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        tooltip: '添加',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: _onNavTap,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: '搜索'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}
