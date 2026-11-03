import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

@PatchEntry('InputDetail')
class InputDetail extends StatefulWidget {
  const InputDetail({super.key});

  @override
  State<InputDetail> createState() => _InputDetailState();
}

class _InputDetailState extends State<InputDetail> {
  // TextEditingController 走 id-bridge（JS 代理类 ↔ 宿主真实实例）：
  // 输入经 textFn 回传镜像触发 listeners，JS 侧 _controller.text 可读、
  // _controller.clear() 可写，与 ScrollController 同款设计。
  final TextEditingController _controller = TextEditingController();
  String _text = '';
  String _choice = 'A';
  String _dropdown = '苹果';
  bool _switchOn = false;
  bool? _checked = false;
  double _slider = 0.4;

  @override
  void initState() {
    super.initState();
    // controller 监听：输入回传（__onHostText）与 clear() 都会触发，
    // 从 controller.text 镜像取值驱动 _text 显示（与 Dart 写法一致）。
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) setState(() => _text = _controller.text);
  }

  void _onTextChanged(String v) {
    setState(() => _text = v);
  }

  void _onChoiceChanged(Object? v) {
    setState(() => _choice = '$v');
  }

  void _onDropdownChanged(Object? v) {
    setState(() => _dropdown = '$v');
  }

  void _onSwitchChanged(bool? v) {
    setState(() => _switchOn = v ?? false);
  }

  void _onCheckChanged(bool? v) {
    setState(() => _checked = v);
  }

  void _onSliderChanged(double v) {
    setState(() => _slider = v);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'TextField',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        TextField(
          controller: _controller,
          onChanged: _onTextChanged,
          decoration: const InputDecoration(
            hintText: '请输入文本',
            labelText: '用户名',
          ),
          maxLines: 1,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),
        // InputDecoration 是值对象：icon / prefixIcon / suffixIcon / label 都是
        // 它的 Widget 字段，JS 侧作为元素描述随 decoration 一起下发，宿主取用
        // 时就地还原（不进结点树、不参与 diff）。
        TextField(
          decoration: InputDecoration(
            hintText: '搜索目的地',
            prefixIcon: Icon(Icons.search),
            suffixIcon: Icon(Icons.close),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            icon: Icon(Icons.phone),
            label: Text('手机号'),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '输入内容：$_text',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        // 验证 JS 侧读 controller.text 镜像（经 __onHostText 回传），
        // 插值写法与 Dart 侧源码一比一。
        Text(
          'controller.text：${_controller.text}',
          style: const TextStyle(fontSize: 14, color: Colors.deepPurple),
        ),
        const SizedBox(height: 8),
        // 验证 JS 侧写 controller（clear() → host 通道清空宿主真实 controller）。
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: () => _controller.clear(),
            child: const Text('清空输入'),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Radio 单选',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            // Radio groupValue/onChanged 已废弃（RadioGroup 暂未支持），
            // demo 先用旧 API 验证协议。
            // ignore: deprecated_member_use
            Radio(
              value: 'A',
              groupValue: _choice,
              onChanged: _onChoiceChanged,
              activeColor: Colors.deepPurple,
            ),
            const Text('选项 A'),
            // ignore: deprecated_member_use
            Radio(
              value: 'B',
              groupValue: _choice,
              onChanged: _onChoiceChanged,
              activeColor: Colors.deepPurple,
            ),
            const Text('选项 B'),
          ],
        ),
        Text(
          '当前选择：$_choice',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        const Text(
          'DropdownButton',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        DropdownButton(
          value: _dropdown,
          isExpanded: true,
          onChanged: _onDropdownChanged,
          items: const [
            DropdownMenuItem(value: '苹果', child: Text('苹果')),
            DropdownMenuItem(value: '香蕉', child: Text('香蕉')),
            DropdownMenuItem(value: '橙子', child: Text('橙子')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Switch(
              value: _switchOn,
              onChanged: _onSwitchChanged,
              // 协议键为 activeColor（生成器按此名提取），运行时映射到 activeThumbColor
              // ignore: deprecated_member_use
              activeColor: Colors.white,
              activeTrackColor: Colors.deepPurple,
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: Colors.grey.shade300,
            ),
            const SizedBox(width: 8),
            Text('Switch：${_switchOn ? "开" : "关"}'),
          ],
        ),
        Row(
          children: [
            Checkbox(
              value: _checked,
              onChanged: _onCheckChanged,
              activeColor: Colors.deepPurple,
              checkColor: Colors.white,
            ),
            const SizedBox(width: 8),
            Text('Checkbox：${_checked ?? false}'),
          ],
        ),
        const SizedBox(height: 8),
        Text('Slider 值：$_slider', style: const TextStyle(fontSize: 14)),
        Slider(
          value: _slider,
          min: 0,
          max: 1,
          divisions: 10,
          label: '${(_slider * 100).round()}%',
          activeColor: Colors.deepPurple,
          inactiveColor: Colors.grey.shade300,
          onChanged: _onSliderChanged,
        ),
      ],
    );
  }
}
