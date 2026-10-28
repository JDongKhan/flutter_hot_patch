import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

import '../base/app_router.dart';

/// Hero 演示：跨路由共享元素动画。
///
/// 点卡片 → 宿主路由推入 [HeroTargetPage]（同 tag 的 Hero）→ 卡片从当前位置
/// 「飞」到目标页；系统返回时反向飞回。
///
/// [tag] / [label] 是**构造参数**（与 StatelessCard 同一个模式）：原生侧用默认
/// `hero-native`，JS 侧由宿主 props 传 `hero-js`。两侧必须不同——原生 / JS
/// 两栏同处一个路由，同 tag 会触发 Flutter 的「重复 Hero」断言。
///
/// 一比一翻译说明：
///   - `Hero` 的子结点就是飞行时的 shuttle 本体（两端用同样的 `Material` +
///     圆角，避免素材在飞行途中「跳变」）；
///   - `transitionOnUserGestures: true` 表示 iOS 侧滑返回时也参与飞行；
///   - `AppRouter.openHeroTarget(...)` 是 `@HostInjected` 宿主方法：原生侧直接
///     调用，JS 侧整段替换成 `_app_host_.invoke('openHeroTarget', [...])`。
@PatchEntry('HeroDetail')
class HeroDetail extends StatelessWidget {
  const HeroDetail({
    super.key,
    this.tag = 'hero-native',
    this.label = '原生 Hero',
  });

  /// 与目标页配对的 Hero tag。
  final String tag;

  /// 卡片上的文字。
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Hero', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text(
          '点卡片跳转 → 卡片飞到目标页；返回时飞回',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => AppRouter.openHeroTarget(tag, label),
          child: Hero(
            tag: tag,
            transitionOnUserGestures: true,
            child: Material(
              color: Colors.deepPurple,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              child: SizedBox(
                width: 160,
                height: 90,
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
