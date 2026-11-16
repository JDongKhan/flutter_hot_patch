import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

@PatchEntry('ImageDetail')
class ImageDetail extends StatefulWidget {
  const ImageDetail({super.key});

  @override
  State<ImageDetail> createState() => _ImageDetailState();
}

class _ImageDetailState extends State<ImageDetail> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Image · 网络图片',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            'https://picsum.photos/seed/hotpatch/400/160',
            height: 120,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'CachedNetworkImage · 磁盘缓存网络图',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: 'https://picsum.photos/seed/hotpatchcache/400/160',
            height: 120,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Icon / CircleAvatar',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 28),
            const SizedBox(width: 12),
            const Icon(Icons.home, color: Colors.blue, size: 28),
            const SizedBox(width: 12),
            const Icon(Icons.favorite, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.teal,
              child: Text('AV', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ],
    );
  }
}
