import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// FadeInImage 演示：占位图先显示，目标图加载完成后淡入。
///
/// 两种构造形态都用：
///   - `FadeInImage.assetNetwork`：placeholder 是**本地资源**、image 是网址
///     （最常用）；点「重新加载」换 seed → 新 URL 重新加载，淡入可反复观察；
///   - `FadeInImage(...)`：placeholder / image 都是 ImageProvider。
///
/// 一比一翻译说明：ImageProvider 是**值对象**，产物里由翻译层归一化成
/// 路径/网址字符串（`AssetImage('a.jpg')` → `'a.jpg'`；`NetworkImage(url)` →
/// `url`），宿主按 `factory` / `http` 前缀还原成原生 provider 再交给
/// FadeInImage；`fadeInDuration` / `fadeOutDuration` 按 Duration JSON 还原。
@PatchEntry('FadeInImageDetail')
class FadeInImageDetail extends StatefulWidget {
  const FadeInImageDetail({super.key});

  @override
  State<FadeInImageDetail> createState() => _FadeInImageDetailState();
}

class _FadeInImageDetailState extends State<FadeInImageDetail> {
  int _seed = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('FadeInImage', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text(
          '占位图 → 目标图淡入；点「重新加载」可反复观察',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 12),
        const Text('① assetNetwork（资源占位 + 网络图）', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          child: FadeInImage.assetNetwork(
            placeholder: 'assets/images/photo-1448375240586-882707db888b.jpg',
            image: 'https://picsum.photos/seed/fade$_seed/600/300',
            width: 600,
            height: 150,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 900),
            fadeOutDuration: const Duration(milliseconds: 300),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            onPressed: () => setState(() => _seed++),
            child: const Text('重新加载'),
          ),
        ),
        const SizedBox(height: 8),
        const Text('② 普通构造（AssetImage 占位 + NetworkImage）', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          child: FadeInImage(
            placeholder: const AssetImage('assets/images/photo-1448375240586-882707db888b.jpg'),
            image: const NetworkImage('https://picsum.photos/seed/fadeplain/600/300'),
            width: 600,
            height: 120,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 600),
          ),
        ),
      ],
    );
  }
}
