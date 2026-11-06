import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// dart:core 基础 API demo：`DateTime` / `RegExp` / `StringBuffer`。
///
/// 三类 API 在 JS 侧没有同名可用的内建类型，由 `patch/flutter.js` 的值类区
/// 提供一比一镜像（`new DateTime({...})` / `new RegExp({source})` /
/// `new StringBuffer({})`）。页面把常用成员集中跑一遍：一边看原生结果，
/// 一边看 JS 热更结果。
@PatchEntry('BasicApiDetail')
class BasicApiDetail extends StatefulWidget {
  const BasicApiDetail({super.key});

  @override
  State<BasicApiDetail> createState() => _BasicApiDetailState();
}

class _BasicApiDetailState extends State<BasicApiDetail> {
  DateTime _now = DateTime.now();

  void _refresh() {
    setState(() => _now = DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    // ---- DateTime：构造 / 加减 / 差值 / 比较 / 解析 / 格式化 ----
    final start = DateTime(2024, 3, 1, 9, 30);
    final end = start.add(const Duration(hours: 2, minutes: 45));
    final span = end.difference(start);
    final parsed = DateTime.parse('2024-03-01T09:30:00Z');
    final order = end.isAfter(start) ? 'end 晚于 start' : 'end 不晚于 start';

    // ---- RegExp：hasMatch / firstMatch / allMatches / 捕获分组 ----
    final text = '订单 A1001，金额 128.50 元，数量 3 件';
    final digitRe = RegExp(r'\d+');
    final hasDigits = digitRe.hasMatch(text);
    final firstDigits = digitRe.firstMatch(text);
    final allDigits = digitRe.allMatches(text);
    final priceRe = RegExp(r'(\d+)\.(\d+)');
    final price = priceRe.firstMatch(text);
    final priceText =
        price == null ? '未匹配' : '整数 ${price.group(1)}，小数 ${price.group(2)}';

    // ---- StringBuffer：write / writeln / length / clear ----
    final buffer = StringBuffer();
    buffer.write('匹配到 ');
    buffer.write(allDigits.length);
    buffer.writeln(' 段数字');
    buffer.write('首个片段：');
    buffer.write(firstDigits == null ? '无' : firstDigits.group(0));
    final built = buffer.toString();
    buffer.clear();
    final clearedEmpty = buffer.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'dart:core 基础 API（DateTime / RegExp / StringBuffer）',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          '与 Dart 同名同义的 JS 镜像：构造、成员、静态工厂均一比一。',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 16),
        const Text('DateTime', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('now().toIso8601String() → ${_now.toIso8601String()}'),
        Text('DateTime(2024, 3, 1, 9, 30) → $start'),
        Text('add(Duration(hours: 2, minutes: 45)) → $end'),
        Text('difference(start) → ${span.inMilliseconds} ms'),
        Text('isAfter(start) → $order'),
        Text("parse('2024-03-01T09:30:00Z').toUtc() → ${parsed.toUtc()}"),
        const SizedBox(height: 16),
        const Text('RegExp', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('待匹配文本：$text'),
        Text("RegExp(r'\\d+').hasMatch(text) → $hasDigits"),
        Text(
          'firstMatch(text).group(0) → '
          '${firstDigits == null ? '无' : firstDigits.group(0)}',
        ),
        Text('allMatches(text).length → ${allDigits.length}'),
        Text("RegExp(r'(\\d+)\\.(\\d+)') 分组 → $priceText"),
        const SizedBox(height: 16),
        const Text('StringBuffer', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('write / writeln 拼接 → ${built.replaceAll('\n', ' ⏎ ')}'),
        Text('clear() 后 isEmpty → $clearedEmpty'),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _refresh,
          child: const Text('重新计算 DateTime.now()'),
        ),
      ],
    );
  }
}
