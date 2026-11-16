import 'package:flutter/material.dart';

/// 接口加载失败的占位视图：展示异常信息并提供重试入口。
///
/// 与 loading 互斥使用：请求失败后页面不再停在 CircularProgressIndicator，
/// 由调用方在「数据为空 + 已失败」时挂上本视图。异常信息原样展示，
/// 方便直接看出是哪个接口 / 哪类网络问题。
class LoadErrorView extends StatelessWidget {
  const LoadErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  /// 失败原因（异常文本，原样展示）。
  final String message;

  /// 重试回调（一般直接传页面的加载方法）。
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 40,
              color: Color(0xFF9AA0AC),
            ),
            const SizedBox(height: 10),
            const Text(
              '加载失败',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4D5462),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Color(0xFF8A909E),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
