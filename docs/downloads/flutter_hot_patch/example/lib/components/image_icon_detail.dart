import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// ImageIcon 演示：把**图片**当图标画（`ImageProvider` + size / color / semanticLabel）。
///
/// 与 Icon 的区别：Icon 画的是字体字形（IconData），ImageIcon 画的是图片，并按
/// 图标的方式处理——尺寸固定为方形、颜色按 `BlendMode.srcIn` 染色（所以照片会
/// 变成同色剪影），未传 color 时继承 IconTheme 的颜色。
///
/// 一比一翻译说明：`image` 是 ImageProvider **值对象**，翻译层归一化成路径/网址
/// 字符串（`AssetImage('a.jpg')` → `'a.jpg'`、`NetworkImage(url)` → `url`）；
/// 宿主按前缀还原成原生 provider 再交给 ImageIcon。size / color / semanticLabel
/// 与 Dart 同名同义。
@PatchEntry('ImageIconDetail')
class ImageIconDetail extends StatelessWidget {
  const ImageIconDetail({super.key});

  /// 一格：图标 + 说明文字（图标本体由参数传入，便于同一套排版比对）。
  Widget _cell(String label, Widget icon) {
    return SizedBox(
      width: 96,
      child: Column(
        children: [
          SizedBox(height: 64, child: Center(child: icon)),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 6),
          content,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ImageIcon', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text(
          '图片作为图标：尺寸 / 颜色（srcIn 染色）/ 与 Icon 对照',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 12),
        _section(
          '① size：24 / 36 / 48（颜色继承 IconTheme）',
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _cell(
                'size 24',
                const ImageIcon(
                  AssetImage('assets/images/photo-1494790108377-be9c29b29330.jpg'),
                  size: 24,
                ),
              ),
              _cell(
                'size 36',
                const ImageIcon(
                  AssetImage('assets/images/photo-1494790108377-be9c29b29330.jpg'),
                  size: 36,
                ),
              ),
              _cell(
                'size 48',
                const ImageIcon(
                  AssetImage('assets/images/photo-1494790108377-be9c29b29330.jpg'),
                  size: 48,
                ),
              ),
            ],
          ),
        ),
        _section(
          '② color：srcIn 染色（同一张图 → 同色剪影）',
          Row(
            children: [
              _cell(
                'teal',
                const ImageIcon(
                  AssetImage('assets/images/photo-1494790108377-be9c29b29330.jpg'),
                  size: 40,
                  color: Colors.teal,
                ),
              ),
              _cell(
                'deepOrange',
                const ImageIcon(
                  AssetImage('assets/images/photo-1494790108377-be9c29b29330.jpg'),
                  size: 40,
                  color: Colors.deepOrange,
                ),
              ),
              _cell(
                'indigo',
                const ImageIcon(
                  AssetImage('assets/images/photo-1494790108377-be9c29b29330.jpg'),
                  size: 40,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
        ),
        _section(
          '③ 与 Icon 并排（同尺寸同色，字形 vs 图片）',
          Row(
            children: [
              _cell(
                'ImageIcon',
                const ImageIcon(
                  AssetImage('assets/images/photo-1448375240586-882707db888b.jpg'),
                  size: 40,
                  color: Colors.deepPurple,
                ),
              ),
              _cell('Icon', const Icon(Icons.park, size: 40, color: Colors.deepPurple)),
            ],
          ),
        ),
        _section(
          '④ 实际用法：徽标 + 文案（semanticLabel 只影响无障碍朗读）',
          Row(
            children: [
              const ImageIcon(
                AssetImage('assets/images/photo-1501785888041-af3ef285b470.jpg'),
                size: 28,
                color: Colors.teal,
                semanticLabel: '风景徽标',
              ),
              const SizedBox(width: 8),
              const Text('图片图标可直接用在 Row / ListTile.leading 里'),
            ],
          ),
        ),
      ],
    );
  }
}
