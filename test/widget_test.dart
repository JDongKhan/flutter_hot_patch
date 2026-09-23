// 冒烟测试：
// 1. 注解可携带组件元信息
// 2. 渲染策略层：JSON 节点树 → 真实 Flutter Widget（Column/Text/Button 递归）
// 3. 服务策略层：NativeService 注册/分发
// 4. HotPatchWidget 可构造
//
// 注意：HotPatchWidget 的 JS 引擎加载依赖原生 JS 运行时（flutter_js 在
// 测试环境会创建轮询 Timer），widget 级渲染验证留到真机集成测试。
import 'dart:convert';

import 'package:flutter/material.dart';
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

  test('渲染策略层：节点树渲染为 Column/Text/Button', () {
    final registry = WidgetRendererRegistry();
    registerBuiltinRenderers(registry);
    final events = <String>[];
    final ctx = WidgetRenderContext(registry: registry, onEvent: events.add);

    final tree = jsonDecode('''
    {
      "type": "Column",
      "children": [
        {"type": "Text", "props": {"data": "Hello from JS logic", "style": "title"}},
        {"type": "Text", "props": {"data": "count = 0", "style": "body"}},
        {"type": "Row", "children": [
          {"type": "Button", "props": {"label": "+1", "event": "inc"}},
          {"type": "Button", "props": {"label": "Native", "event": "native"}}
        ]}
      ]
    }
    ''');

    final w = ctx.render(tree);
    expect(w, isA<Column>());
    final column = w as Column;
    expect(column.children, hasLength(3));
    expect(column.children[0], isA<Text>());
    expect((column.children[0] as Text).data, 'Hello from JS logic');
    expect(column.children[2], isA<Row>());

    // 事件回流：点 Button 触发 onEvent('inc')
    final row = column.children[2] as Row;
    final button = row.children[0] as ElevatedButton;
    button.onPressed!();
    expect(events, ['inc']);
  });

  test('服务策略层：NativeService 注册/查找/分发', () {
    final registry = NativeServiceRegistry();
    registerBuiltinNativeServices(registry);
    expect(registry.lookup('nativeToast'), isA<SnackBarService>());
    expect(registry.lookup('log'), isA<LogService>());
    expect(registry.channels, containsAll(['nativeToast', 'log']));

    // 业务方可覆盖同 channel 实现；覆盖不影响其他内置服务
    registry.register(_FakeService());
    expect(registry.lookup('nativeToast'), isA<_FakeService>());
    expect(registry.lookup('log'), isA<LogService>());
  });

  test('HotPatchWidget 可构造', () {
    const w = HotPatchWidget(
      jsAsset: 'assets/components/components/hello_component.component.js',
      component: 'HelloCard',
    );
    expect(w.jsAsset, 'assets/components/components/hello_component.component.js');
    expect(w.component, 'HelloCard');
  });
}

class _FakeService extends NativeService {
  const _FakeService();
  @override
  String get channel => 'nativeToast';
  @override
  void handle(BuildContext context, dynamic payload) {}
}
