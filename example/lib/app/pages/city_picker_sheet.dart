import 'package:flutter/material.dart';

/// 城市选择面板：由 `AppRouter.openCityPicker` 用 `showModalBottomSheet` 弹出，
/// 点击任一城市即 `pop(城市名)` 返回给调用方（首页据此更新左上角并重新取数）。
///
/// 城市列表是宿主侧的静态配置（选择器不走接口，进入即可选）。
///
/// **为什么单独成文件**：它唯一的引用方是宿主动能入口 `AppRouter`
/// （`base/app_router.dart`），而 `AppRouter` 的产物 `base/app_router.js` 必须
/// 不依赖页面产物 —— 页面本来就 import `AppRouter`，反向依赖会构成模块环，
/// 加载时两边互等、页面永远拿不到首帧（运行时现在会把环抛出来，见
/// `JsRuntimeManager._loadModule`）。
class CityPickerSheet extends StatelessWidget {
  const CityPickerSheet({super.key, required this.current});

  /// 当前城市名（面板里做高亮）。
  final String current;

  static const List<String> _cities = ['上海', '北京', '成都', '杭州', '西安', '三亚'];

  void _pick(BuildContext context, String city) {
    Navigator.of(context).pop(city);
  }

  @override
  Widget build(BuildContext context) {
    // 品牌蓝与 App 主题 seed 同色（`0xFF0E7AFB`），走主题取色而不是引用页面
    // 文件里的常量，避免本文件反向依赖 detail_pages.dart。
    final brand = Theme.of(context).colorScheme.primary;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Text(
                  '选择城市',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                Spacer(),
                Icon(Icons.close, size: 20, color: Color(0xFF8B909A)),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              '当前定位',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8B909A),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _pick(context, current),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.my_location, size: 15, color: brand),
                    const SizedBox(width: 5),
                    Text(
                      current,
                      style: TextStyle(
                        fontSize: 13,
                        color: brand,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '热门城市',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8B909A),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final c in _cities)
                  GestureDetector(
                    onTap: () => _pick(context, c),
                    child: Container(
                      width: 76,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c == current
                            ? const Color(0xFFEAF3FF)
                            : const Color(0xFFF3F5F8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        c,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: c == current
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: c == current ? brand : const Color(0xFF4D5462),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
