import 'package:flutter/material.dart';

/// Hero 飞行目标页（普通原生页面，不参与翻译）。
///
/// 与来源页（原生 / JS 热更两侧）**同 tag** 的 Hero 会从来源位置飞到这里；
/// 返回时反向飞回。tag 由来源页传入，两侧各用独立 tag，避免同一路由里
/// 出现两个同名 Hero（Flutter 会断言重复 tag）。
class HeroTargetPage extends StatelessWidget {
  const HeroTargetPage({super.key, required this.tag, required this.label});

  /// 与来源页配对用的 Hero tag。
  final String tag;

  /// 卡片上的文字（区分「原生」/「JS 热更」来源）。
  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hero 目标页')),
      body: Center(
        child: Hero(
          tag: tag,
          transitionOnUserGestures: true,
          child: Material(
            color: Colors.deepPurple,
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            child: SizedBox(
              width: 280,
              height: 180,
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
