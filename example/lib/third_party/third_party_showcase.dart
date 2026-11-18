import 'package:flutter/material.dart';
import 'package:dynamic_flutter/dynamic_flutter.dart';

import '../base/patch_config.dart';
import '../components/compare_pane.dart';
import '../components/construct_only_card.dart';
import '../components/dio_card.dart';
import '../components/getx_component.dart';
import '../components/note_object_card.dart';
import '../components/provider_component.dart';
import '../components/third_party_tools_card.dart';

/// 三方库导航列表页（普通页面，无 @PatchEntry 注解）：
/// 按「能不能封装成工具类」分三组，点击条目进入原生 vs JS 热更对比页。
///
/// - 状态管理：provider / GetX —— 语义在 JS 侧整套实现（js/provider.js、js/get.js）；
/// - 工具类：path_provider / package_info_plus / permission_handler —— 收口到
///   [PlatformTools] 的 `@HostInjected` 静态方法，JS 侧不翻译这些库；
/// - 必须构造的类：uuid / dio —— JS 侧提供同名类（js/uuid.js、js/dio.js）。
///   dio 的 API 面可构造、可读字段，`Dio()` / `dio.get(…, queryParameters: …)` /
///   `res.statusCode` 与 Dart 一比一，底层请求由宿主用真实 dio 执行。
class ThirdPartyShowcase extends StatelessWidget {
  const ThirdPartyShowcase({super.key});

  static final List<_Group> _groups = [
    _Group('状态管理（JS 侧整套实现）', [
      _Entry(
        'Provider',
        'MultiProvider / Consumer / Selector / context.watch·read：订阅局部重建',
        ProviderCard(),
        'ProviderCard',
        'components/provider_component.js',
      ),
      _Entry(
        'GetX',
        'Get.put/find + GetBuilder.update + Obx/Rx：手动通知与自动追踪',
        GetXCard(),
        'GetXCard',
        'components/getx_component.js',
      ),
    ]),
    _Group('常用库 · 工具类封装（@HostInjected）', [
      _Entry(
        'path_provider / package_info_plus / permission_handler',
        'PlatformTools：宿主执行真实调用，JS 侧只走通道，不翻译这些库',
        ThirdPartyToolsCard(),
        'ThirdPartyToolsCard',
        'components/third_party_tools_card.js',
      ),
    ]),
    _Group('自定义类 · JS 同名类（实例对象绑定）', [
      _Entry(
        'NoteObject',
        'new NoteObject({title: …}) → js/classes/NoteObject.js → obj/NoteObject：'
            '方法 / 读字段 / 写字段全部打到宿主真实实例',
        NoteObjectCard(),
        'NoteObjectCard',
        'components/note_object_card.js',
      ),
    ]),
    _Group('必须构造的类 · JS 同名实现', [
      _Entry(
        'dio',
        'final Dio _dio = Dio(); await _dio.get(url, queryParameters: …)：'
            'API 与 Dart 一致，底层由宿主真实 dio 执行',
        DioCard(),
        'DioCard',
        'components/dio_card.js',
      ),
      _Entry(
        'uuid',
        'final id = Uuid(); id.v4()：构造与方法调用和 Dart 一比一',
        ConstructOnlyCard(),
        'ConstructOnlyCard',
        'components/construct_only_card.js',
      ),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        for (final group in _groups) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              group.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          for (final entry in group.entries)
            ListTile(
              leading: const Icon(Icons.extension_outlined),
              title: Text(entry.title),
              subtitle: Text(entry.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _ComparePage(entry: entry),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _Group {
  const _Group(this.title, this.entries);

  final String title;
  final List<_Entry> entries;
}

class _Entry {
  const _Entry(
    this.title,
    this.subtitle,
    this.native,
    this.component,
    this.jsEntry,
  );

  final String title;
  final String subtitle;
  final Widget native;
  final String component;
  final String jsEntry;
}

class _ComparePage extends StatelessWidget {
  const _ComparePage({required this.entry});

  final _Entry entry;

  @override
  Widget build(BuildContext context) {
    final jsAsset = patchUrl(entry.component, entry.jsEntry);
    // 统一对比外壳：宽屏左右分栏，窄屏单栏 + 标题栏切换（与列表页入口一致）。
    return ComparePane(
      title: entry.title,
      left: entry.native,
      right: JsUiWidget(jsAsset: jsAsset),
    );
  }
}
