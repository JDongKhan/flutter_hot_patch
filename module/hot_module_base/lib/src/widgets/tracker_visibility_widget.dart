import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// @author jd
/// 使用于banner
class TrackerVisibilityWidget extends StatefulWidget {
  const TrackerVisibilityWidget({super.key, required this.onExposure, required this.child});
  final VoidCallback onExposure;
  final Widget child;

  @override
  State<TrackerVisibilityWidget> createState() => _TrackerVisibilityWidgetState();
}

class _TrackerVisibilityWidgetState extends State<TrackerVisibilityWidget> {
  ///是否已经曝光
  bool _hasExposure = false;
  final Key _visibilityKey = UniqueKey();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: _visibilityKey,
      onVisibilityChanged: (VisibilityInfo info) {
        if (_hasExposure) {
          return;
        }
        final bool isVisibleOnScreen =
            info.visibleFraction > 0 && info.size.width > 0 && info.size.height > 0;
        if (!isVisibleOnScreen) {
          return;
        }
        _hasExposure = true;
        // 局部别名后调用：语句位置的 `widget.onExposure()` 当前不在翻译覆盖内
        // （会被丢弃并告警），而 `widget.onExposure` 字段读已按 `this.` 归一。
        final VoidCallback onExposure = widget.onExposure;
        onExposure();
      },
      child: widget.child,
    );
  }
}
