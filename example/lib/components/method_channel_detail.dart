import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';
import 'package:hot_plugin_counter/hot_plugin_counter.dart';
import 'package:hot_plugin_device_info/hot_plugin_device_info.dart';

/// 两个「三方库」插件各自持有独立 channel：
///
/// - `hot_plugin_device_info` → `hot_patch/demo/device_info`
/// - `hot_plugin_counter`     → `hot_patch/demo/counter`
///
/// 原生模式：插件 Dart → Flutter MethodChannel → 原生。
/// JS 热更模式：翻译产物 → `flutter.js` 的 MethodChannel 镜像 → 宿主
/// `methodChannel` 通道 → Flutter MethodChannel → 原生。两条路径最终落到
/// 同一份原生实现。
@PatchEntry('MethodChannelDetail')
class MethodChannelDetail extends StatefulWidget {
  const MethodChannelDetail({super.key});

  @override
  State<MethodChannelDetail> createState() => _MethodChannelDetailState();
}

class _MethodChannelDetailState extends State<MethodChannelDetail> {
  String _deviceInfo = '未调用';
  String _counter = '未调用';
  String _handlerResult = '未调用';
  bool _busy = false;

  Future<void> _readDeviceInfo() async {
    setState(() {
      _busy = true;
      _deviceInfo = '调用中…';
    });
    try {
      final version = await HotPluginDeviceInfo.platformVersion();
      final name = await HotPluginDeviceInfo.deviceName();
      if (!mounted) return;
      setState(() {
        _deviceInfo = version + ' · ' + name;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _deviceInfo = '调用失败：' + e.toString();
        _busy = false;
      });
    }
  }

  Future<void> _increment(int step) async {
    setState(() {
      _busy = true;
    });
    try {
      final value = await HotPluginCounter.increment(step);
      if (!mounted) return;
      setState(() {
        _counter = '原生计数：' + value.toString();
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _counter = '调用失败：' + e.toString();
        _busy = false;
      });
    }
  }

  Future<void> _resetCounter() async {
    setState(() {
      _busy = true;
    });
    try {
      final value = await HotPluginCounter.reset();
      if (!mounted) return;
      setState(() {
        _counter = '原生计数：' + value.toString();
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _counter = '调用失败：' + e.toString();
        _busy = false;
      });
    }
  }

  Future<void> _pingFromNative() async {
    setState(() {
      _busy = true;
      _handlerResult = '调用中…';
    });
    try {
      final value = await HotPluginCounter.pingFromNative();
      if (!mounted) return;
      setState(() {
        _handlerResult = value;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _handlerResult = '调用失败：' + e.toString();
        _busy = false;
      });
    }
  }

  Widget _card({
    required String title,
    required String channel,
    required String result,
    required List<Widget> actions,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'channel: ' + channel,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Text(result),
            const SizedBox(height: 10),
            Wrap(spacing: 8, children: actions),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 详情页由 showcase 包在 SingleChildScrollView 里，这里只能用 Column，
    // 不能再嵌 ListView（无界高度会触发布局断言）。
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '同一页面同时调用两个独立三方库的 channel；'
            '原生模式与 JS 热更模式会分别走各自链路，结果一致。',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          _card(
            title: '插件 A · hot_plugin_device_info',
            channel: 'hot_patch/demo/device_info',
            result: _deviceInfo,
            actions: [
              ElevatedButton(
                onPressed: () {
                  if (_busy) return;
                  _readDeviceInfo();
                },
                child: const Text('读取设备信息'),
              ),
            ],
          ),
          _card(
            title: '插件 B · hot_plugin_counter',
            channel: 'hot_patch/demo/counter',
            result: _counter,
            actions: [
              ElevatedButton(
                onPressed: () {
                  if (_busy) return;
                  _increment(1);
                },
                child: const Text('+1'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_busy) return;
                  _increment(5);
                },
                child: const Text('+5'),
              ),
              OutlinedButton(
                onPressed: () {
                  if (_busy) return;
                  _resetCounter();
                },
                child: const Text('重置'),
              ),
            ],
          ),
          _card(
            title: '插件 B · setMethodCallHandler',
            channel: '原生 → Flutter → JS（同一 channel 反向调用）',
            result: _handlerResult,
            actions: [
              ElevatedButton(
                onPressed: () {
                  if (_busy) return;
                  _pingFromNative();
                },
                child: const Text('原生回调 JS'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
