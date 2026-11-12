import 'dart:async';

import 'package:flutter/material.dart';

/// 倒计时文案组件：**自己持有 1s 定时器，只重建自己这一行文字**。
///
/// 之前是「页面持秒表 + 每秒 setState」的写法，100 条订单时每秒会把整页
/// （状态条 / 条数行 / 列表可见项）重建一遍；改成组件自持定时器后，
/// 页面只在数据变化时重建，倒计时只刷新自己。
///
/// 为什么入参是绝对截止时间而不是「剩余秒数」：
/// - ListView.builder 的项滚出屏幕会被销毁、滚回来会重新挂载，如果按剩余
///   秒数起算，每次重新进屏都会从头倒数（越滚越新）；
/// - 用绝对时间做基准，任意时刻重新挂载都算出同一剩余值，且不会因定时器
///   漂移而累积误差。
///
/// 使用约定：
/// - `deadlineMillis` = 截止时刻的 epoch 毫秒（模型解析时由 remainSec 折算）；
/// - 倒数到 0 即停表，不会越界成负数，显示 `zeroText`；
/// - 卡片滚出屏幕被 dispose 时定时器随之取消，列表不会累积空转定时器。
class CountdownText extends StatefulWidget {
  const CountdownText({
    super.key,
    required this.deadlineMillis,
    required this.color,
    this.fontSize = 13.5,
    this.zeroText = '00:00',
  });

  /// 截止时刻（epoch 毫秒）。
  final int deadlineMillis;

  /// 文字颜色（由调用方按业务给，组件不判断状态）。
  final Color color;

  final double fontSize;

  /// 倒数到 0 后显示的文案。
  final String zeroText;

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  Timer? _timer;

  /// 当前显示的剩余秒数（每拍由绝对时间重算，不做自减，避免漂移）。
  int _left = 0;

  @override
  void initState() {
    super.initState();
    _left = _remainSeconds();
    _start();
  }

  /// 同一位置的元素被复用到另一张订单（切状态 / 列表刷新）时，按新截止时间重新计时。
  @override
  void didUpdateWidget(covariant CountdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deadlineMillis != widget.deadlineMillis) {
      _left = _remainSeconds();
      _start();
    }
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  void _start() {
    _stop();
    if (_left <= 0) return;
    // 显式闭包 + 具名方法（与 BannerCarousel 一致）：回调里 this 绑回组件实例。
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _tick(timer));
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _tick(Timer timer) {
    if (_timer == null) return;
    final int left = _remainSeconds();
    if (left <= 0) {
      _stop();
      setState(() => _left = 0);
      return;
    }
    setState(() {
      _left = left;
    });
  }

  /// 距截止还有几秒（向上取整：还剩 0.4s 也显示 1 秒，到 0 才停）。
  int _remainSeconds() {
    final int diff = widget.deadlineMillis - DateTime.now().millisecondsSinceEpoch;
    if (diff <= 0) return 0;
    return (diff + 999) ~/ 1000;
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _left <= 0 ? widget.zeroText : _countdownText(_left),
      style: TextStyle(
        fontSize: widget.fontSize,
        fontWeight: FontWeight.w700,
        color: widget.color,
      ),
    );
  }
}

/// 秒数 → `hh:mm:ss`（不足 1 小时只显示 `mm:ss`）。
String _countdownText(int sec) {
  final int safe = sec < 0 ? 0 : sec;
  final int h = safe ~/ 3600;
  final int m = (safe % 3600) ~/ 60;
  final int s = safe % 60;
  final String mm = m < 10 ? '0$m' : '$m';
  final String ss = s < 10 ? '0$s' : '$s';
  if (h > 0) {
    final String hh = h < 10 ? '0$h' : '$h';
    return '$hh:$mm:$ss';
  }
  return '$mm:$ss';
}
