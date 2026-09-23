import 'package:flutter/material.dart';

import 'components/hello_component.dart';
import 'js_widget.dart';

void main() => runApp(const HotDemoApp());

/// 演示「正常组件 ↔ JS 热更版本」两种形态：
///
/// - 原生模式：直接使用 [HelloCard]，组件 100% 正常可用（与注解无关）。
/// - JS 模式：运行时切换为 [JsWidget]，加载 build_runner 从 HelloCard
///   静态翻译生成的 hello_component.component.js，由 JS 驱动渲染与逻辑。
///
/// 这就是热修复场景：线上出 bug → 下发新 JS → 运行时切换，无需发版。
class HotDemoApp extends StatelessWidget {
  const HotDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Hot Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '注解组件 → JS 热修复',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'HelloCard 是正常 StatefulWidget；build_runner 基于注解静态翻译出 '
                    '.component.js + .component.schema.json。\n'
                    '原生模式走正常组件；JS 模式由 JS 驱动渲染与逻辑（事件回流 JS）。',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  SizedBox(height: 16),
                  _HotSwitch(),
                  SizedBox(height: 16),
                  _Card(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 全局模式控制器（demo 简化用）：原生组件 / JS 热更
class HotModeController {
  static final HotModeController instance = HotModeController();
  bool useJs = false;
  final _listeners = <VoidCallback>[];

  void set(bool v) {
    useJs = v;
    for (final l in List.of(_listeners)) {
      l();
    }
  }

  void addListener(VoidCallback l) => _listeners.add(l);
}

/// 原生 / JS 切换开关
class _HotSwitch extends StatefulWidget {
  const _HotSwitch();

  @override
  State<_HotSwitch> createState() => _HotSwitchState();
}

class _HotSwitchState extends State<_HotSwitch> {
  bool _useJs = false;

  @override
  void initState() {
    super.initState();
    HotModeController.instance.addListener(() {
      if (mounted) {
        setState(() => _useJs = HotModeController.instance.useJs);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.indigo.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('原生组件'),
          Switch(
            value: _useJs,
            onChanged: (v) => HotModeController.instance.set(v),
          ),
          const Text('JS 热更'),
        ],
      ),
    );
  }
}

class _Card extends StatefulWidget {
  const _Card();

  @override
  State<_Card> createState() => _CardState();
}

class _CardState extends State<_Card> {
  @override
  void initState() {
    super.initState();
    HotModeController.instance.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final useJs = HotModeController.instance.useJs;
    return Container(
      width: 340,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: useJs
          ? const JsWidget(
              jsAsset: 'assets/components/hello_component.component.js',
              component: 'HelloCard',
            )
          : const HelloCard(),
    );
  }
}
