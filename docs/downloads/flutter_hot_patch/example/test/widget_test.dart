import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 最小冒烟测试：保证 `flutter test` 有可运行的基线（此前该文件为空，
/// 缺少 `main()` 会让整个测试命令直接报错）。
void main() {
  testWidgets('渲染一个 Text 并检查文案', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Text('hot_patch')));
    expect(find.text('hot_patch'), findsOneWidget);
  });
}
