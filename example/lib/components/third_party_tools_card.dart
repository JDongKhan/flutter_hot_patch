import 'package:flutter/material.dart';
import 'package:dynamic_flutter_annotations/dynamic_flutter_annotations.dart';

import '../base/dev_server.dart';
import '../base/host_http.dart';
import '../base/platform_tools.dart';

/// 常用三方库 → 工具类封装 demo（左原生 / 右 JS 热更）。
///
/// path_provider / package_info_plus / permission_handler 都只提供「平台能力
/// 取值」，dio 的网络栈又过重，没必要在 JS 侧重新实现：统一收口到
/// [PlatformTools] / [HostHttp] 的 `@HostInjected` 静态方法，宿主执行真实
/// 调用，JS 产物里只剩通道调用。两侧代码完全一致，差别只在「谁执行」。
@PatchEntry('ThirdPartyToolsCard')
class ThirdPartyToolsCard extends StatefulWidget {
  const ThirdPartyToolsCard({super.key});

  @override
  State<ThirdPartyToolsCard> createState() => _ThirdPartyToolsCardState();
}

class _ThirdPartyToolsCardState extends State<ThirdPartyToolsCard> {
  String _temp = '未读取';
  String _docs = '未读取';
  String _version = '未读取';
  String _permission = '未查询';
  String _http = '尚未请求';

  Future<void> _load() async {
    final temp = await PlatformTools.tempPath();
    final docs = await PlatformTools.documentsPath();
    final version = await PlatformTools.appVersion();
    setState(() {
      _temp = temp;
      _docs = docs;
      _version = version;
    });
  }

  Future<void> _checkPermission() async {
    final status = await PlatformTools.photoPermissionStatus();
    setState(() => _permission = status);
  }

  Future<void> _requestPermission() async {
    final status = await PlatformTools.requestPhotoPermission();
    setState(() => _permission = status);
  }

  Future<void> _callHttp() async {
    try {
      final res = await HostHttp.get('$devServerBaseUrl/hello');
      setState(() {
        _http = 'HTTP ${res['statusCode']} · ${res['statusMessage'] ?? ''}';
      });
    } catch (e) {
      setState(() => _http = '请求失败：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PlatformTools / HostHttp（@HostInjected）',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            _Line(label: '临时目录', value: _temp),
            _Line(label: '文档目录', value: _docs),
            _Line(label: '应用版本', value: _version),
            _Line(label: '相册权限', value: _permission),
            _Line(label: 'HTTP（dio）', value: _http),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _load,
                  child: const Text('读取路径/版本'),
                ),
                ElevatedButton(
                  onPressed: _checkPermission,
                  child: const Text('查询权限'),
                ),
                ElevatedButton(
                  onPressed: _requestPermission,
                  child: const Text('申请权限'),
                ),
                ElevatedButton(
                  onPressed: _callHttp,
                  child: const Text('dio 请求 mock'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'path_provider / package_info_plus / permission_handler / dio 全部由宿主执行，'
              'JS 侧不翻译这些库',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text('$label：$value', style: const TextStyle(fontSize: 13)),
    );
  }
}
