import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// InheritedWidget 数据共享示例（原生与 JS 热更同一份源码）。
///
/// 祖先 `_DemoScope` 通过 `InheritedWidget` 下发数据，子孙用
/// `context.dependOnInheritedWidgetOfExactType<_DemoScope>()` 同步取值并建立
/// 依赖：数据变化时只重建依赖者（`updateShouldNotify` 返回 true 的位置），
/// 与 Flutter 原生语义一致。
@PatchEntry('InheritedCard')
class InheritedCard extends StatefulWidget {
  const InheritedCard({super.key});

  @override
  State<InheritedCard> createState() => _InheritedCardState();
}

class _InheritedCardState extends State<InheritedCard> {
  int _count = 0;
  String _mode = 'A';
  int _lastRead = -1;

  @override
  Widget build(BuildContext context) {
    return _DemoScope(
      count: _count,
      mode: _mode,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('InheritedWidget · 祖先数据共享'),
              _CountLabel(),
              _ModeLabel(),
              Text('read 快照 = $_lastRead'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => setState(() => _count += 1),
                    child: const Text('count +1'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => setState(() => _mode = _mode == 'A' ? 'B' : 'A'),
                    child: const Text('切换 mode'),
                  ),
                  const SizedBox(width: 12),
                  // Builder 的 context 是 _DemoScope 的子孙：get 只取值、不登记依赖。
                  Builder(
                    builder: (context) => ElevatedButton(
                      onPressed: () => setState(
                        () => _lastRead = _DemoScope.read(context)?.count ?? -1,
                      ),
                      child: const Text('read'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 数据提供者：`updateShouldNotify` 语义与 Flutter 原生一致。
class _DemoScope extends InheritedWidget {
  const _DemoScope({
    required this.count,
    required this.mode,
    required super.child,
  });

  final int count;
  final String mode;

  /// `dependOnInheritedWidgetOfExactType`：取值并登记依赖（数据变化时该位置重建）。
  static _DemoScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_DemoScope>();
    return scope!;
  }

  /// `getInheritedWidgetOfExactType`：只取值，不登记依赖（事件回调里的合法用法）。
  static _DemoScope? read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_DemoScope>();

  @override
  bool updateShouldNotify(_DemoScope oldWidget) =>
      count != oldWidget.count || mode != oldWidget.mode;
}

/// `count` 的消费者：只读 count；scope 变化时按依赖重建。
class _CountLabel extends StatelessWidget {
  const _CountLabel();

  @override
  Widget build(BuildContext context) {
    final scope = _DemoScope.of(context);
    return Text('count = ${scope.count}');
  }
}

/// `mode` 的消费者：与 _CountLabel 同一作用域，各自独立重建。
class _ModeLabel extends StatelessWidget {
  const _ModeLabel();

  @override
  Widget build(BuildContext context) {
    final scope = _DemoScope.of(context);
    return Text('mode = ${scope.mode}');
  }
}
