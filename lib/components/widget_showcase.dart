import 'package:flutter/material.dart';
import 'package:ui_component/ui_component.dart';

/// 常用基础组件展示（demo list 页面）：
/// text / image / container / listview / icon / divider / card / center /
/// padding / align / stack / positioned / wrap / circleavatar / gesture /
/// switch / checkbox / slider / expanded 等。
///
/// 同一份代码两个身份：
///   - 原生：直接当正常 StatefulWidget 用；
///   - JS 热更：@UIComponent 注解 → build_runner 翻译成
///     widget_showcase.component.js，HotPatchWidget 加载后由 JS 驱动渲染与逻辑。
@UIComponent('WidgetShowcase')
class WidgetShowcase extends StatefulWidget {
  const WidgetShowcase({super.key});

  @override
  State<WidgetShowcase> createState() => _WidgetShowcaseState();
}

class _WidgetShowcaseState extends State<WidgetShowcase> {
  // 全量生成：字段 → JS 属性（一比一，无 __state 包装）
  int _bumps = 0;
  bool _on = false;
  double _slider = 0.3;
  int _taps = 0;

  // 全量生成：方法 → JS 方法（一比一，方法体原封翻译）
  void bump() {
    setState(() => _bumps++);
  }

  void onSwitch(bool v) {
    setState(() => _on = v);
  }

  void onSlider(double v) {
    setState(() => _slider = v);
  }

  void tap() {
    setState(() => _taps++);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'WidgetShowcase · 常用基础组件',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('来自 JS 热更：bumps = 0 是静态文案，下面用状态插值'),
        const Divider(),
        // Text + TextStyle + 状态插值 + 按钮
        const Text('Text · 文案与 TextStyle'),
        Text(
          'Hello 热更组件，bumps = $_bumps',
          style: const TextStyle(color: Colors.blue, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          'taps = $_taps（GestureDetector 累计）',
          style: const TextStyle(color: Colors.green),
        ),
        TextButton(onPressed: bump, child: const Text('Bump')),
        const Divider(),
        // Image：网络图
        const Text('Image · 网络图片'),
        const SizedBox(height: 4),
        Image.network(
          'https://picsum.photos/300/120',
          width: 300,
          height: 120,
          fit: BoxFit.cover,
        ),
        const Divider(),
        // Icon / CircleAvatar
        const Text('Icon / CircleAvatar'),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 28),
            const SizedBox(width: 12),
            const Icon(Icons.home, size: 28),
            const SizedBox(width: 12),
            const Icon(Icons.favorite, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            const CircleAvatar(
              radius: 24,
              backgroundColor: Colors.orange,
              child: Icon(Icons.person, color: Colors.white),
            ),
          ],
        ),
        const Divider(),
        // Container：颜色/圆角/Padding
        const Text('Container · 颜色/圆角/Padding'),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.teal,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            '容器内容（teal 圆角）',
            style: TextStyle(color: Colors.white),
          ),
        ),
        const Divider(),
        // Card
        const Text('Card'),
        const SizedBox(height: 4),
        const Card(
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text('卡片内容（elevation=2）'),
          ),
        ),
        const Divider(),
        // Row + Expanded/Flexible
        const Text('Row + Expanded / Flexible'),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: Container(
                color: Colors.red,
                padding: const EdgeInsets.all(8),
                child: const Text('A', textAlign: TextAlign.center),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 2,
              child: Container(
                color: Colors.blue,
                padding: const EdgeInsets.all(8),
                child: const Text('B（flex=2）', textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
        const Divider(),
        // Center / Align
        const Text('Center / Align'),
        const SizedBox(height: 4),
        Center(
          child: Container(
            color: Colors.grey,
            padding: const EdgeInsets.all(8),
            child: const Text('Center 居中'),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            color: Colors.blueGrey,
            padding: const EdgeInsets.all(8),
            child: const Text('Align centerLeft'),
          ),
        ),
        const Divider(),
        // Stack + Positioned
        const Text('Stack + Positioned'),
        const SizedBox(height: 4),
        Stack(
          children: [
            Container(width: 120, height: 80, color: Colors.grey),
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                color: Colors.deepPurple,
                padding: const EdgeInsets.all(4),
                child: const Text(
                  'TL',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                color: Colors.deepOrange,
                padding: const EdgeInsets.all(4),
                child: const Text(
                  'BR',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
        const Divider(),
        // Wrap
        const Text('Wrap · 自动换行'),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.indigo,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'chip 1',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.indigo,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'chip 2',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.indigo,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'chip 3',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.indigo,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'chip 4',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
        const Divider(),
        // GestureDetector
        const Text('GestureDetector · 点击'),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: tap,
          child: Container(
            color: Colors.lightGreen,
            padding: const EdgeInsets.all(12),
            child: const Text('点我（累计到 taps）'),
          ),
        ),
        const Divider(),
        // Switch / Checkbox / Slider：带值事件（onChanged → JS 方法带参调用）
        const Text('Switch / Slider · 带值事件'),
        const SizedBox(height: 4),
        Row(
          children: [
            Switch(value: _on, onChanged: onSwitch),
            const SizedBox(width: 12),
            const Text('开关'),
            const SizedBox(width: 12),
            Expanded(
              child: Slider(value: _slider, min: 0, max: 1, onChanged: onSlider),
            ),
          ],
        ),
        Text('switch=$_on  slider=$_slider'),
        const Divider(),
        // ListView（shrinkWrap 内嵌）
        const Text('ListView · 列表'),
        const SizedBox(height: 4),
        ListView(
          shrinkWrap: true,
          children: [
            Container(
              color: Colors.grey,
              padding: const EdgeInsets.all(6),
              child: const Row(
                children: [
                  Icon(Icons.list, size: 20),
                  SizedBox(width: 8),
                  Text('item A'),
                ],
              ),
            ),
            Container(
              color: Colors.grey,
              padding: const EdgeInsets.all(6),
              child: const Row(
                children: [
                  Icon(Icons.list, size: 20),
                  SizedBox(width: 8),
                  Text('item B'),
                ],
              ),
            ),
            Container(
              color: Colors.grey,
              padding: const EdgeInsets.all(6),
              child: const Row(
                children: [
                  Icon(Icons.list, size: 20),
                  SizedBox(width: 8),
                  Text('item C'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
