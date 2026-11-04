import 'package:flutter/material.dart';

/// 楼层级 loading：与整页 loading 区分，只占本楼层的高度。
class FloorLoadingView extends StatelessWidget {
  const FloorLoadingView({super.key, this.height = 120});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

/// 楼层级失败态：展示原因并提供重试入口。
class FloorErrorView extends StatelessWidget {
  const FloorErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.height = 120,
  });

  final String message;
  final VoidCallback onRetry;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  '楼层加载失败：$message',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A909E),
                  ),
                ),
              ),
              TextButton(onPressed: onRetry, child: const Text('重试')),
            ],
          ),
        ),
      ),
    );
  }
}
