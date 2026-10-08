import 'package:flutter/material.dart';
import 'package:ui_component/ui_component.dart';

/// 常用组件详情页集合（widget_showcase 列表页点击进入）。
///
/// 每个详情组件都是 @UIComponent 注解组件：同一份代码
///   - 原生：直接当正常 StatefulWidget 用（widget_showcase 里 new 使用）；
///   - JS 热更：build_runner 翻译成 widget_details.component.js，
///     WidgetDetailPage 用 JsUiWidget 加载，原生 vs JS 同屏对比。
/// 单文件多组件：所有详情类在同一个产物里，运行时按组件名实例化。
///
/// 覆盖的 Flutter 常用组件与属性：
///   Text / TextStyle（maxLines、overflow、textAlign、decoration…）
///   ElevatedButton / TextButton / OutlinedButton + ButtonStyle 全属性
///   Row / Column / Expanded / Flexible / Stack / Positioned / Wrap
///   Align / Padding / Center / SizedBox
///   Image / Icon / CircleAvatar
///   Container / Card / Divider
///   ListView / SingleChildScrollView
///   Scaffold / AppBar

// ---------------------------------------------------------------------------
// Text 详情
// ---------------------------------------------------------------------------

@UIComponent('TextDetail')
class TextDetail extends StatefulWidget {
  const TextDetail({super.key});

  @override
  State<TextDetail> createState() => _TextDetailState();
}

class _TextDetailState extends State<TextDetail> {
  int _count = 0;

  void bump() {
    setState(() => _count++);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('基础文案 + TextStyle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text('普通文本，count = $_count（状态插值）', style: const TextStyle(color: Colors.blue, fontSize: 16)),
        const SizedBox(height: 6),
        Text(
          'maxLines+overflow 测试：这是一段很长的文字会被截断成省略号显示',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Text(
          'textScaler.linear(1.6) 放大',
          textScaler: TextScaler.linear(1.6),
        ),
        const SizedBox(height: 6),
        Text(
          'textAlign 居中',
          textAlign: TextAlign.center,
          style: const TextStyle(
            decoration: TextDecoration.underline,
            decorationColor: Colors.orange,
            decorationStyle: TextDecorationStyle.wavy,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'softWrap=false 不换行测试',
          softWrap: false,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            wordSpacing: 2,
            letterSpacing: 1,
            backgroundColor: Color(0xFFFFE082),
          ),
        ),
        const SizedBox(height: 6),
        TextButton(onPressed: bump, child: const Text('Bump count')),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Button 详情
// ---------------------------------------------------------------------------

@UIComponent('ButtonDetail')
class ButtonDetail extends StatefulWidget {
  const ButtonDetail({super.key});

  @override
  State<ButtonDetail> createState() => _ButtonDetailState();
}

class _ButtonDetailState extends State<ButtonDetail> {
  int _pressed = 0;

  void onTap() {
    setState(() => _pressed++);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('点击次数 = $_pressed', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(180, 48),
            maximumSize: const Size(240, 56),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            elevation: 6,
            shadowColor: Colors.deepPurple,
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
          child: const Text('Elevated · Styled'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            minimumSize: const Size(120, 40),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            textStyle: const TextStyle(fontSize: 14, letterSpacing: 1),
            foregroundColor: Colors.indigo,
          ),
          child: const Text('TextButton'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.orange, width: 2),
            minimumSize: const Size(120, 40),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
            foregroundColor: Colors.deepOrange,
          ),
          child: const Text('OutlinedButton'),
        ),
        const SizedBox(height: 8),
        // 无 onPressed：禁用态
        const ElevatedButton(onPressed: null, child: Text('Disabled')),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Layout 详情
// ---------------------------------------------------------------------------

@UIComponent('LayoutDetail')
class LayoutDetail extends StatefulWidget {
  const LayoutDetail({super.key});

  @override
  State<LayoutDetail> createState() => _LayoutDetailState();
}

class _LayoutDetailState extends State<LayoutDetail> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Row + Expanded / Flexible', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: Container(
                color: Colors.blue.shade100,
                padding: const EdgeInsets.all(8),
                child: const Text('A', textAlign: TextAlign.center),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 2,
              child: Container(
                color: Colors.green.shade100,
                padding: const EdgeInsets.all(8),
                child: const Text('B（flex=2）', textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text('Center / Align / Padding / SizedBox', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Center(
          child: Container(
            color: Colors.amber.shade100,
            padding: const EdgeInsets.all(12),
            child: const Text('Center 居中'),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            color: Colors.purple.shade50,
            padding: const EdgeInsets.all(8),
            child: const Text('Align centerLeft'),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: const Text('Padding 包裹文案'),
        ),
        const SizedBox(height: 12),
        const Text('Stack + Positioned', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(
          height: 100,
          child: Stack(
            children: [
              Container(color: Colors.grey.shade200),
              Positioned.fill(
                child: Center(
                  child: Text(
                    'FILL',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const Positioned(left: 12, top: 12, child: Text('TL')),
              const Positioned(right: 12, bottom: 12, child: Text('BR')),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text('Wrap · 自动换行', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 1; i <= 5; i++)
              Chip(
                label: Text('chip $i'),
                backgroundColor: Colors.teal.shade50,
              ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Image / Icon 详情
// ---------------------------------------------------------------------------

@UIComponent('ImageDetail')
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
        const Text('Image · 网络图片', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            'https://picsum.photos/seed/hotpatch/400/160',
            height: 120,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 12),
        const Text('Icon / CircleAvatar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

// ---------------------------------------------------------------------------
// Container 详情
// ---------------------------------------------------------------------------

@UIComponent('ContainerDetail')
class ContainerDetail extends StatefulWidget {
  const ContainerDetail({super.key});

  @override
  State<ContainerDetail> createState() => _ContainerDetailState();
}

class _ContainerDetailState extends State<ContainerDetail> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Container · 颜色/圆角/Padding', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.teal,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: const Text('容器内容（teal 圆角）', style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(height: 12),
        const Text('Card', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: const Text('卡片内容（elevation=2）'),
          ),
        ),
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 12),
        const Text('SizedBox · 尺寸约束', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Container(
          width: 120,
          height: 48,
          alignment: Alignment.center,
          color: Colors.blueGrey.shade100,
          child: const Text('固定 120×48'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Scroll 详情
// ---------------------------------------------------------------------------

@UIComponent('ScrollDetail')
class ScrollDetail extends StatefulWidget {
  const ScrollDetail({super.key});

  @override
  State<ScrollDetail> createState() => _ScrollDetailState();
}

class _ScrollDetailState extends State<ScrollDetail> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('ListView · 列表', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(
          height: 160,
          child: ListView(
            children: const [
              ListTile(leading: Icon(Icons.list), title: Text('item A')),
              ListTile(leading: Icon(Icons.list), title: Text('item B')),
              ListTile(leading: Icon(Icons.list), title: Text('item C')),
              ListTile(leading: Icon(Icons.list), title: Text('item D')),
              ListTile(leading: Icon(Icons.list), title: Text('item E')),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text('SingleChildScrollView · 长内容滚动', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 1; i <= 8; i++)
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Chip(label: Text('横向 $i')),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Scaffold 详情（页面级，仅 JS 热更版展示）
// ---------------------------------------------------------------------------

@UIComponent('ScaffoldDetail')
class ScaffoldDetail extends StatefulWidget {
  const ScaffoldDetail({super.key});

  @override
  State<ScaffoldDetail> createState() => _ScaffoldDetailState();
}

class _ScaffoldDetailState extends State<ScaffoldDetail> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scaffold / AppBar / Center'),
        backgroundColor: Colors.deepPurple,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.extension, size: 48, color: Colors.deepPurple),
            SizedBox(height: 12),
            Text('页面骨架组件演示'),
            Text('Scaffold + AppBar + Center + SingleChildScrollView'),
          ],
        ),
      ),
    );
  }
}
