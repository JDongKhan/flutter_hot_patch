// 冒烟测试：注解可携带元信息、HotPatchWidget 可构造。
// （HotPatchWidget 运行依赖原生 JS 引擎，widget 级测试留到集成测试阶段）
import 'package:flutter_test/flutter_test.dart';
import 'package:hot_patch/hot_patch.dart';
import 'package:ui_component/ui_component.dart';

void main() {
  test('注解可携带组件元信息', () {
    const component = UIComponent('HelloCard');
    const prop = UIProp('count');
    const action = UIAction('native', native: 'nativeToast');
    expect(component.name, 'HelloCard');
    expect(prop.name, 'count');
    expect(action.name, 'native');
    expect(action.native, 'nativeToast');
  });

  testWidgets('HotPatchWidget 可构造并显示加载态', (tester) async {
    await tester.pumpWidget(
      const HotPatchWidget(
        jsAsset: 'assets/components/components/hello_component.component.js',
        component: 'HelloCard',
      ),
    );
    expect(find.byType(HotPatchWidget), findsOneWidget);
  });
}
