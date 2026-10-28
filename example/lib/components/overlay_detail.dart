import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// Overlay / OverlayEntry：声明式 initialEntries + 命令式 insert / remove。
///
/// 与 Dart 语义一致：
///   - `initialEntries` 的条目直接进表；
///   - `Overlay.of(context)` 沿祖先取**最近的** Overlay（不是整个 App 的 Overlay），
///     所以浮层只叠在下面那块灰底区域内；
///   - `entry.remove()` 移除后条目立刻退出渲染，可重新 insert 复用。
///
/// 按钮放在 `Builder` 里是为了拿**Overlay 后代**的 context：`Overlay.of` 找的是
/// 祖先最近的那个 Overlay，用页面自身（Overlay 的祖先）的 context 是找不到本实例的。
@PatchEntry('OverlayDetail')
class OverlayDetail extends StatefulWidget {
  const OverlayDetail({super.key});

  @override
  State<OverlayDetail> createState() => _OverlayDetailState();
}

class _OverlayDetailState extends State<OverlayDetail> {
  int _count = 0;
  String _log = '（暂无操作）';
  OverlayEntry? _last;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Overlay', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text(
          '灰底区域就是 Overlay：第 1 条由 initialEntries 声明，'
          '按钮通过 Overlay.of(context).insert / entry.remove 增删浮层',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => Container(
                  color: Colors.grey.shade100,
                  child: Builder(
                    builder: (context) => Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(10),
                          child: Text(
                            '第 1 条：initialEntries（声明式，铺满整个 Overlay）',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _count = _count + 1;
                                });
                                // 命令式条目：builder 是 JS 闭包，在 JS 侧执行。
                                final entry = OverlayEntry(
                                  builder: (context) => Positioned(
                                    left: 12,
                                    right: 12,
                                    bottom: 12,
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        '浮层 #$_count：叠在内容之上的 OverlayEntry',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                                _last = entry;
                                final overlay = Overlay.of(context);
                                overlay.insert(entry);
                                setState(() {
                                  _log = '插入第 $_count 条浮层';
                                });
                              },
                              child: const Text('插入浮层'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () {
                                final entry = _last;
                                if (entry != null) {
                                  entry.remove();
                                }
                                setState(() {
                                  _log = '移除最近插入的浮层';
                                });
                              },
                              child: const Text('移除浮层'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '操作日志：$_log',
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }
}
