// 冒烟测试：
// 1. 注解可携带组件元信息
// 2. 宿主补丁应用层：JsUiStore 按 op 改写结点表（create/insert/move/props/
//    propsChild/remove/root），只重建被触碰结点
// 3. 宿主翻译层：JsWidgetRegistry 把结点译成真实 Flutter widget（Text/Column/Button）
// 4. 宿主注入：@HostInjected 通道回填（位置/具名实参按 Dart 语义还原）
//
// 注意：JsUiWidget 的 JS 引擎加载依赖原生 JS 运行时（flutter_js 在测试环境会
// 创建轮询 Timer），widget 级渲染验证留到真机集成测试。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hot_patch/hot_patch.dart';
import 'package:ui_component/ui_component.dart';

void main() {
  test('注解可携带组件元信息（name 可省略，缺省取类名）', () {
    const component = UIComponent('HelloCard');
    expect(component.name, 'HelloCard');
    // 不传 name：等价于用类名作组件名（JS 类名与 Dart 类名一致）。
    const unnamed = UIComponent();
    expect(unnamed.name, isNull);
  });

  test('宿主注入：位置/具名实参按 Dart 调用语义还原', () {
    // 直接驱动处理器表（不建 runtime）：registerHostMethod 只写 static 表，
    // 桥通道在那里按 ch 分发，故这里手动喂 JS 侧载荷即可。
    // 载荷按实参形态有三种编码（生成器产出，见 hostArgsJs）：
    //   纯位置 → 数组、纯具名 → 对象、混合 → 对象 + "@args" 装位置实参。

    // ① 纯具名：`Network.post(params: {...})` 曾被扁平化成位置实参，
    //    Function.apply 因「函数只接受具名参数 params」抛异常 → 被 catch 吞成
    //    null（这就是 userMap 为 null 的根因）。
    Object? namedArg;
    JsRuntimeManager.registerHostMethod('tNamed', ({dynamic params}) {
      namedArg = params;
      return null;
    });
    JsRuntimeManager.globalMessageHandlers['tNamed']!({
      'id': '',
      'args': {
        'params': {'name': '22'},
      },
    });
    expect(namedArg, {'name': '22'});

    // ② 纯位置：载荷就是数组
    List<dynamic>? posArg;
    JsRuntimeManager.registerHostMethod('tPos', (dynamic a, dynamic b) {
      posArg = [a, b];
      return null;
    });
    JsRuntimeManager.globalMessageHandlers['tPos']!({
      'id': '',
      'args': [1, 2],
    });
    expect(posArg, [1, 2]);

    // ③ 混合 + 多参数 + 默认值：3 位置 + 3 具名（只传 2 个具名，c1 走默认值）
    List<dynamic>? all;
    JsRuntimeManager.registerHostMethod('tMixed',
        (String a, String b, String c, {int times = 1, int c1 = 2, int c2 = 3}) {
      all = [a, b, c, times, c1, c2];
      return null;
    });
    JsRuntimeManager.globalMessageHandlers['tMixed']!({
      'id': '',
      'args': {
        '@args': ['a1', 'b1', 'c1'],
        'times': 2,
        'c2': 9,
      },
    });
    expect(all, ['a1', 'b1', 'c1', 2, 2, 9]);
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
    childContexts: const [],
    propChildren: propChildren,
    nativeComponents: const {},
    invoke: invoke ?? (_, [_]) {},
  ));
}