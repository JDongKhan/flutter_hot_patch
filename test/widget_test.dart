// 冒烟测试：
// 1. 注解可携带组件元信息
// 2. 服务策略层：NativeService 注册/分发
// 3. 宿主补丁应用层：JsUiStore 按 op 改写结点表（create/insert/move/props/
//    propsChild/remove/root），只重建被触碰结点
// 4. 宿主翻译层：JsWidgetRegistry 把结点译成真实 Flutter widget（Text/Column/Button）
//
// 注意：JsUiWidget 的 JS 引擎加载依赖原生 JS 运行时（flutter_js 在测试环境会
// 创建轮询 Timer），widget 级渲染验证留到真机集成测试。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hot_patch/hot_patch.dart';
import 'package:ui_component/ui_component.dart';

void main() {
  test('注解可携带组件元信息', () {
    const component = UIComponent('HelloCard');
    expect(component.name, 'HelloCard');
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

  group('JsUiStore 补丁应用', () {
    test('root/create/insert/props：结点表与重建回调', () {
      final store = JsUiStore();
      String? root;
      store.onRoot = (id) => root = id;
      final rebuilt = <String>[];
      store.bind('n0', () => rebuilt.add('n0'));
      store.bind('n1', () => rebuilt.add('n1'));

      store.apply([
        {'op': 'root', 'id': 'n0'},
        {'op': 'create', 'id': 'n0', 'type': 'Column', 'props': <String, dynamic>{}},
        {'op': 'create', 'id': 'n1', 'type': 'Text', 'props': {'data': 'hi'}},
        {'op': 'insert', 'parent': 'n0', 'id': 'n1', 'index': 0},
      ]);

      expect(root, 'n0');
      expect(store.nodes['n0']!.childIds, ['n1']);
      expect(store.nodes['n1']!.type, 'Text');
      expect(store.nodes['n1']!.props['data'], 'hi');
      // create n0/n1 与 insert n0 都被触碰 → n0 重建两次、n1 一次
      expect(rebuilt, contains('n0'));
      expect(rebuilt, contains('n1'));

      // props：原位更新，不新建结点
      store.apply([
        {'op': 'props', 'id': 'n1', 'props': {'data': 'bye'}},
      ]);
      expect(store.nodes['n1']!.props['data'], 'bye');
    });

    test('insert/move：childIds 顺序按 index 调整', () {
      final store = JsUiStore();
      store.apply([
        {'op': 'root', 'id': 'p'},
        {'op': 'create', 'id': 'p', 'type': 'Column', 'props': <String, dynamic>{}},
        {'op': 'create', 'id': 'a', 'type': 'Text', 'props': <String, dynamic>{}},
        {'op': 'create', 'id': 'b', 'type': 'Text', 'props': <String, dynamic>{}},
        {'op': 'insert', 'parent': 'p', 'id': 'a', 'index': 0},
        {'op': 'insert', 'parent': 'p', 'id': 'b', 'index': 1},
      ]);
      expect(store.nodes['p']!.childIds, ['a', 'b']);

      store.apply([
        {'op': 'move', 'parent': 'p', 'id': 'b', 'index': 0},
      ]);
      expect(store.nodes['p']!.childIds, ['b', 'a']);
      // 重复 insert 同一 id 不产生重复项
      store.apply([
        {'op': 'insert', 'parent': 'p', 'id': 'b', 'index': 0},
      ]);
      expect(store.nodes['p']!.childIds, ['b', 'a']);
    });

    test('propsChild / propsChildRemove：值为 element 的 props', () {
      final store = JsUiStore();
      store.apply([
        {'op': 'create', 'id': 'tile', 'type': 'ListTile', 'props': <String, dynamic>{}},
        {'op': 'create', 'id': 'lead', 'type': 'Icon', 'props': <String, dynamic>{}},
        {'op': 'propsChild', 'parent': 'tile', 'key': 'leading', 'childId': 'lead'},
      ]);
      expect(store.nodes['tile']!.propChildIds['leading'], 'lead');
      // prop 子结点同属这棵树，删父时一并回收
      store.apply([
        {'op': 'propsChildRemove', 'parent': 'tile', 'key': 'leading'},
      ]);
      expect(store.nodes['tile']!.propChildIds, isEmpty);
    });

    test('remove：unlink + 递归回收子树', () {
      final store = JsUiStore();
      store.apply([
        {'op': 'create', 'id': 'p', 'type': 'Column', 'props': <String, dynamic>{}},
        {'op': 'create', 'id': 'c', 'type': 'Text', 'props': <String, dynamic>{}},
        {'op': 'create', 'id': 'lc', 'type': 'Icon', 'props': <String, dynamic>{}},
        {'op': 'insert', 'parent': 'p', 'id': 'c', 'index': 0},
        {'op': 'propsChild', 'parent': 'c', 'key': 'leading', 'childId': 'lc'},
      ]);
      store.apply([
        {'op': 'remove', 'id': 'c'},
      ]);
      expect(store.nodes.containsKey('c'), isFalse);
      expect(store.nodes.containsKey('lc'), isFalse);
      expect(store.nodes['p']!.childIds, isEmpty);
    });
  });

  test('宿主翻译层：JsWidgetRegistry 构造 Text/Column/Button', () {
    final registry = JsWidgetRegistry();
    registerBuiltinJsWidgets(registry);

    // Text
    final text = _ctx(registry, 'Text', {'data': 'hello'});
    expect(text, isA<Text>());
    expect((text as Text).data, 'hello');

    // Column：children 按顺序进入
    final column = _ctx(
      registry,
      'Column',
      <String, dynamic>{},
      children: [const Text('a'), const Text('b')],
      childTypes: ['Text', 'Text'],
    );
    expect(column, isA<Column>());
    expect((column as Column).children, hasLength(2));

    // Button：event 是运行时句柄 → 点击经 invoke 原样回传
    final events = <Object?>[];
    final handle = {'__fn': 'fn1', '__ev': 'inc'};
    final button = _ctx(
      registry,
      'Button',
      {'label': '+1', 'event': handle},
      invoke: (h, [p]) => events.add(h),
    );
    expect(button, isA<ElevatedButton>());
    (button as ElevatedButton).onPressed!();
    expect(events, [handle]);
  });
}

Widget _ctx(
  JsWidgetRegistry registry,
  String type,
  Map<String, dynamic> props, {
  List<Widget> children = const [],
  List<String> childTypes = const [],
  Map<String, Widget> propChildren = const {},
  void Function(Object? handler, [Object? payload])? invoke,
}) {
  final builder = registry.lookup(type)!;
  return builder(JsBuildContext(
    props: props,
    children: children,
    childTypes: childTypes,
    propChildren: propChildren,
    nativeComponents: const {},
    invoke: invoke ?? (_, [_]) {},
  ));
}

class _FakeService extends NativeService {
  const _FakeService();
  @override
  String get channel => 'nativeToast';
  @override
  void handle(BuildContext context, dynamic payload) {}
}