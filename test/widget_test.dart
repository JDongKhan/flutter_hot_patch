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

  group('provider 下沉 Dart（宿主映射）', () {
    // 句柄通道的宿主入口：与 JS 侧 `host('jsHandle', [body])` 的下发载荷同形。
    void handle(Map<String, Object?> body) {
      ensureJsUiCapabilities();
      JsRuntimeManager.globalMessageHandlers['jsHandle']!({
        'id': '',
        'args': [body],
      });
    }

    test('VM 通用镜像：create 记 JS 类型 / notify 转通知 / release 销毁', () {
      const id = 'js:vm/ChangeNotifier#1';
      handle({
        'id': id,
        'op': 'create',
        'kind': 'vm/ChangeNotifier',
        'meta': {'type': 'CounterVm'},
      });
      final vm = jsVmOf(id)!;
      // P1：Dart 通用 VM 记下 JS 端的类名（context.watch<T>() 的 T）
      expect(vm.jsType, 'CounterVm');

      var notified = 0;
      vm.addListener(() => notified++);
      // JS 侧 notifyListeners 的第二路：镜像转发给 Dart 侧订阅者
      handle({'id': id, 'op': 'notify'});
      expect(notified, 1);

      handle({'id': id, 'op': 'release'});
      expect(jsVmOf(id), isNull);
    });

    testWidgets('ChangeNotifierProvider 映射为 Dart 侧 provider 子树', (tester) async {
      const id = 'js:vm/ChangeNotifier#2';
      handle({
        'id': id,
        'op': 'create',
        'kind': 'vm/ChangeNotifier',
        'meta': {'type': 'CounterVm'},
      });
      final registry = JsWidgetRegistry();
      registerAllJsWidgets(registry);

      var dartBuilds = 0;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (_) => _ctx(
            registry,
            'ChangeNotifierProvider',
            {
              'model': 'CounterVm',
              'vm': {'__handle': id},
            },
            children: [
              Builder(builder: (c) {
                dartBuilds++;
                final vm = JsVmProvider.maybeOf(c);
                return Text('vm=${vm?.jsType}',
                    textDirection: TextDirection.ltr);
              }),
            ],
          ),
        ),
      ));
      expect(dartBuilds, 1);
      expect(find.text('vm=CounterVm'), findsOneWidget);

      // JS 侧 notify → Dart 侧依赖者重建（P2：provider 子树粒度）
      handle({'id': id, 'op': 'notify'});
      await tester.pump();
      expect(dartBuilds, 2);

      // Consumer / ListenableBuilder 同样映射成监听边界（同一 VM 实例）
      final consumer = _ctx(
        registry,
        'Consumer',
        {
          'model': 'CounterVm',
          'vm': {'__handle': id},
        },
        children: const [Text('x')],
      );
      expect(consumer, isA<ListenableBuilder>());
      expect((consumer as ListenableBuilder).listenable, same(jsVmOf(id)));

      handle({'id': id, 'op': 'release'});
    });

    testWidgets('BuildContext 代理：按结点 id / 句柄 id 反查宿主真值', (tester) async {
      late BuildContext nodeCtx;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (c) {
          nodeCtx = c;
          return const SizedBox.shrink();
        }),
      ));
      // 宿主结点 build 期间登记（_JsNodeState 的真实行为）
      registerJsBuildContext('n1', nodeCtx);

      const id = 'js:ctx/BuildContext#1';
      handle({
        'id': id,
        'op': 'create',
        'kind': 'ctx/BuildContext',
        'meta': {'node': 'n1'},
      });
      expect(jsBuildContextOfNode('n1'), same(nodeCtx));
      expect(jsBuildContextOf(id), same(nodeCtx));

      handle({'id': id, 'op': 'release'});
      expect(jsBuildContextOf(id), isNull);
      unregisterJsBuildContext('n1');
      expect(jsBuildContextOfNode('n1'), isNull);
    });

    testWidgets('context.watch op：Dart 按「指定 type」订阅，不订最近的 provider',
        (tester) async {
      const idA = 'js:vm/ChangeNotifier#wA';
      const idB = 'js:vm/ChangeNotifier#wB';
      handle({
        'id': idA,
        'op': 'create',
        'kind': 'vm/ChangeNotifier',
        'meta': {'type': 'VmA'},
      });
      handle({
        'id': idB,
        'op': 'create',
        'kind': 'vm/ChangeNotifier',
        'meta': {'type': 'VmB'},
      });
      final registry = JsWidgetRegistry();
      registerAllJsWidgets(registry);

      var builds = 0;
      late BuildContext nodeCtx;
      // 外层 VmA、内层 VmB，消费点在最内层：**最近的** provider 是 VmB，
      // 而 watch 的是 VmA —— 订阅必须按 `jsType == T` 过滤，不能顺手订最近的。
      await tester.pumpWidget(MaterialApp(
        home: _ctx(
          registry,
          'ChangeNotifierProvider',
          {
            'model': 'VmA',
            'vm': {'__handle': idA},
          },
          children: [
            _ctx(
              registry,
              'ChangeNotifierProvider',
              {
                'model': 'VmB',
                'vm': {'__handle': idB},
              },
              children: [
                Builder(builder: (c) {
                  nodeCtx = c;
                  builds++;
                  return const SizedBox.shrink();
                }),
              ],
            ),
          ],
        ),
      ));
      registerJsBuildContext('w1', nodeCtx);

      const ctxId = 'js:ctx/BuildContext#w1';
      handle({
        'id': ctxId,
        'op': 'create',
        'kind': 'ctx/BuildContext',
        'meta': {'node': 'w1'},
      });
      builds = 0;
      // JS 侧 context.watch<VmA>()：Dart 侧按类型解析到 VmA 的镜像并订阅。
      handle({'id': ctxId, 'op': 'watch', 'type': 'VmA'});

      // 最近的 provider（VmB）notify：订的不是它 → 不重建。
      handle({'id': idB, 'op': 'notify'});
      await tester.pump();
      expect(builds, 0);

      // 被 watch 的 VmA notify → 该结点重建。
      handle({'id': idA, 'op': 'notify'});
      await tester.pump();
      expect(builds, 1);

      // 句柄释放 → 订阅摘除（不再随 notify 重建）。
      handle({'id': ctxId, 'op': 'release'});
      handle({'id': idA, 'op': 'notify'});
      await tester.pump();
      expect(builds, 1);

      // read 只取值、不建依赖（对齐 Dart/provider 语义）：新句柄 read 后 notify
      // 仍不重建（此时已无任何 watch 订阅）。
      const ctx2 = 'js:ctx/BuildContext#w2';
      handle({
        'id': ctx2,
        'op': 'create',
        'kind': 'ctx/BuildContext',
        'meta': {'node': 'w1'},
      });
      handle({'id': ctx2, 'op': 'read', 'type': 'VmA'});
      handle({'id': idA, 'op': 'notify'});
      await tester.pump();
      expect(builds, 1);
      handle({'id': ctx2, 'op': 'release'});

      handle({'id': idA, 'op': 'release'});
      handle({'id': idB, 'op': 'release'});
      unregisterJsBuildContext('w1');
    });

    // 能力模板的自证：把「新引入一个能力（内建等价物或 provider/GetX/… 三方库）」
    // 压缩成「写一个 JsUiLibrary 子类 + register」——核心三个聚合入口
    // （jsUiRuntimeSource / ensureJsUiCapabilities / registerAllJsWidgets）
    // 与类型解析入口（resolveWatchTarget）**不改一行**就把它接上。
    group('能力模板：继承 + register 即被核心消费（核心零改动）', () {
      // 句柄通道的宿主入口（与 provider group 同形）。
      void handle(Map<String, Object?> body) {
        ensureJsUiCapabilities();
        JsRuntimeManager.globalMessageHandlers['jsHandle']!({
          'id': '',
          'args': [body],
        });
      }

      test('内建能力全部经模板注册（防漏注册哨兵）', () {
        ensureJsUiCapabilities();
        // 内建能力（Flutter 等价物 + provider）都在同一张注册表里 ——
        // 聚合文件不再逐个列出能力名，故用哨兵钉住「一个都不能漏」。
        expect(jsUiLibraries.map((l) => l.id), containsAll(<String>[
          'change-notifier',
          'scroll-controller',
          'text-editing-controller',
          'tab-drawer',
          'key',
          'build-context',
          'notification-listener',
          'provider',
        ]));

        // 五类能力的组件映射都经「遍历注册表」到达，外加核心地基的基础组件。
        final registry = JsWidgetRegistry();
        registerAllJsWidgets(registry);
        for (final type in const [
          'TextField', // text_editing_controller
          'ListView', // scroll_controller
          'TabBarView', // tab_drawer
          'NotificationListener', // notification_listener
          'ChangeNotifierProvider', // provider
          'Text', // 核心地基 registerBuiltinJsWidgets
        ]) {
          expect(registry.has(type), isTrue, reason: '缺失组件映射: $type');
        }
      });

      test('四个钩子被核心聚合入口消费：片段 / 通道 / 组件', () {
        // 注册表是全局的（测试间累积），故每个 Fake 用**独有**的提供类型，
        // 避免先注册者抢先命中 `resolveWatchTarget`（见下个用例）。
        final fake = _FakeLibrary('fakeHooks', watchType: 'HooksOnlyModel');
        registerJsUiLibrary(fake);
        // 幂等：同 id 重复注册只保留首个（第二份不被驱动）。
        final duplicate = _FakeLibrary('fakeHooks', watchType: 'HooksOnlyModel');
        registerJsUiLibrary(duplicate);
        expect(jsUiLibraries.where((l) => l.id == 'fakeHooks'), hasLength(1));

        // ② ensureChannels ← ensureJsUiCapabilities 聚合（核心文件不改）
        ensureJsUiCapabilities();
        expect(fake.channelsEnsured, isTrue);

        // ③ registerWidgets ← registerAllJsWidgets 聚合（核心文件不改）
        final registry = JsWidgetRegistry();
        registerAllJsWidgets(registry);
        expect(fake.widgetsRegistered, isTrue);
        expect(registry.has('FakeBox'), isTrue);

        // ① jsFragments ← jsUiRuntimeSource 拼接（核心文件不改）
        expect(fake.jsFragments, isNotEmpty);
        expect(jsUiRuntimeSource(), contains('__fakeLibraryMarker'));
        // 真实案例：内建 provider 库的片段走的是同一条缝。
        expect(jsUiRuntimeSource(),
            contains("registerScope('ChangeNotifierProvider'"));

        // 未注册的副本什么都没被触发（证明 id 去重 + 只驱动注册表）
        expect(duplicate.channelsEnsured, isFalse);
        expect(duplicate.widgetsRegistered, isFalse);
      });

      testWidgets('④ resolveWatchTarget：核心按类型解析并订阅（不经过 provider 的知识）',
          (tester) async {
        final fake = _FakeLibrary('fakeWatch');
        registerJsUiLibrary(fake);
        ensureJsUiCapabilities();

        var builds = 0;
        late BuildContext nodeCtx;
        await tester.pumpWidget(MaterialApp(
          home: Builder(builder: (c) {
            nodeCtx = c;
            builds++;
            return const SizedBox.shrink();
          }),
        ));
        registerJsBuildContext('f1', nodeCtx);

        const ctxId = 'js:ctx/BuildContext#fake1';
        handle({
          'id': ctxId,
          'op': 'create',
          'kind': 'ctx/BuildContext',
          'meta': {'node': 'f1'},
        });
        builds = 0;
        // JS 侧 context.watch<FakeModel>()：核心遍历各库解析，命中模板子类。
        handle({'id': ctxId, 'op': 'watch', 'type': 'FakeModel'});
        expect(fake.notifier.addCount, 1,
            reason: '核心应已按类型解析并订阅模板子类提供的对象');

        // 模板子类解析出的 Listenable notify → 该结点重建（核心不认识 FakeModel）。
        fake.notifier.notifyListeners();
        await tester.pump();
        expect(builds, 1);

        handle({'id': ctxId, 'op': 'release'});
        unregisterJsBuildContext('f1');
      });
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
      invoke: (h, [args = const []]) => events.add(h),
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
  void Function(Object? handler, [List<Object?> args])? invoke,
}) {
  final builder = registry.lookup(type)!;
  return builder(JsRenderContext(
    props: props,
    children: children,
    childTypes: childTypes,
    childContexts: const [],
    propChildren: propChildren,
    nativeComponents: const {},
    invoke: invoke ?? (_, [args = const []]) {},
  ));
}

/// 「新引入一个三方库」的最小样板：一个 [JsUiLibrary] 子类，四个钩子各留一个
/// 可观测的痕迹，用来证明核心**不改一行**就能把它接上（对标 GetX 之类的接入）。
class _FakeLibrary extends JsUiLibrary {
  _FakeLibrary(this.id, {this.watchType = 'FakeModel'});

  @override
  final String id;

  /// 本库负责解析的提供类型（`context.watch<T>` 的 T）。
  final String watchType;

  bool channelsEnsured = false;
  bool widgetsRegistered = false;

  /// 本库对外提供的作用域对象（模拟 VM/Store）。
  final FakeListenable notifier = FakeListenable();

  @override
  List<String> get jsFragments => const ['var __fakeLibraryMarker = 1;'];

  @override
  void ensureChannels() => channelsEnsured = true;

  @override
  void registerWidgets(JsWidgetRegistry r) {
    widgetsRegistered = true;
    r.register('FakeBox', (c) => const SizedBox.shrink());
  }

  @override
  Listenable? resolveWatchTarget(BuildContext context, String type) =>
      type == watchType ? notifier : null;
}

/// 模板子类解析出的「可订阅对象」（核心只当它是 Listenable）。
class FakeListenable extends ChangeNotifier {
  /// 被订阅次数（`hasListeners` 是 protected，测试里用公开计数替代）。
  int addCount = 0;

  @override
  void addListener(VoidCallback listener) {
    addCount++;
    super.addListener(listener);
  }
}