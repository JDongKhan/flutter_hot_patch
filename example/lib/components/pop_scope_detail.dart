import 'package:flutter/material.dart';
import 'package:hot_patch_annotations/hot_patch_annotations.dart';

/// PopScope 演示：拦截路由返回（系统返回 / AppBar 返回箭头）。
///
/// - `canPop: true` → 返回动作正常执行（页面被关闭），回调 didPop = true；
/// - `canPop: false` → 返回动作被拦截（页面留在原地），回调 didPop = false；
/// - 回调是两参事件 `(bool didPop, Object? result)`：result 是
///   `Navigator.pop(result)` 的返回值，返回箭头传 null。
///
/// 一比一翻译说明：
///   - canPop 是普通布尔属性，随状态字段重下发；
///   - onPopInvokedWithResult 形参是函数类型且以 `on` 开头 → 生成器按事件下
///     发句柄，宿主在 PopScope 回调里以 `[didPop, result]` 回传，JS 侧解构到
///     两个形参（与 Dart 同序）。
///
/// 注意：本页里原生侧与 JS 侧**各自**登记了一个 PopScope（同一个路由），
/// 路由能不能被弹出取两者的「与」——任一侧把 canPop 关掉都会拦住返回。
@PatchEntry('PopScopeDetail')
class PopScopeDetail extends StatefulWidget {
  const PopScopeDetail({super.key});

  @override
  State<PopScopeDetail> createState() => _PopScopeDetailState();
}

class _PopScopeDetailState extends State<PopScopeDetail> {
  bool _canPop = true;
  int _invoked = 0;
  bool _lastDidPop = true;
  String _lastResult = '（无）';

  void _onPopInvoked(bool didPop, Object? result) {
    setState(() {
      _invoked += 1;
      _lastDidPop = didPop;
      _lastResult = result == null ? '（无）' : '$result';
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: _onPopInvoked,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PopScope', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
            '点左上角返回箭头：开关打开（canPop=false）时页面不会退出，回调 didPop=false',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('拦截返回（canPop = false）', style: TextStyle(fontSize: 12)),
              Switch(
                value: !_canPop,
                onChanged: (v) => setState(() => _canPop = !v),
              ),
              Text(
                _canPop ? 'canPop: true' : 'canPop: false',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.all(Radius.circular(6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('回调次数：$_invoked', style: const TextStyle(fontSize: 12)),
                Text(
                  '最近 didPop：$_lastDidPop',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  '最近 result：$_lastResult',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
