// 临时探针入口：把指定 JS 产物挂成整页并把真实渲染结果落盘，用于核对
// 「九宫格固定高度/动态列数、景点格固定高度、订单白底铺满」三项改动在实机
// 上的效果。核对完即删除（不属于正式代码）。
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hot_patch/hot_patch.dart';

import 'generated/host_methods.dart';

const String _zip = 'http://127.0.0.1:8765/patch/patch.zip';

String _url(String component, String entry) =>
    '$_zip?component=$component&entry=${Uri.encodeComponent(entry)}';

final GlobalKey _rootKey = GlobalKey();
final GlobalKey _hostKey = GlobalKey();

void main() {
  registerHostMethods();
  runApp(const _ProbeApp());
}

class _ProbeApp extends StatefulWidget {
  const _ProbeApp();

  @override
  State<_ProbeApp> createState() => _ProbeAppState();
}

class _ProbeAppState extends State<_ProbeApp> {
  /// 页面整页高度给足，让内部 CustomScrollView 一次性完成布局；
  /// 由外层滚动控制器的便宜驱动"看上半 / 看下半"。
  static const double _pageHeight = 1500;

  final ScrollController _scroll = ScrollController();
  int _page = 0;
  bool _orderPage = false;

  static const List<(String, String)> _pages = [
    ('HomePage', 'app/pages/home_page.js'),
    ('OrdersPage', 'app/pages/orders_page.js'),
  ];

  @override
  void initState() {
    super.initState();
    unawaited(_drive());
  }

  Future<void> _drive() async {
    // 首页：先截上半（含九宫格），再滚下去截景点格。
    await Future<void>.delayed(const Duration(seconds: 9));
    await _shot('js_home_top');
    if (_scroll.hasClients) _scroll.jumpTo(560);
    await Future<void>.delayed(const Duration(seconds: 2));
    await _shot('js_home_bottom');

    // 订单页：看状态条白底是否铺满。
    if (_scroll.hasClients) _scroll.jumpTo(0);
    setState(() {
      _page = 1;
      _orderPage = true;
    });
    await Future<void>.delayed(const Duration(seconds: 9));
    await _shot('js_orders_top');
    debugPrint('PROBE done');
  }

  Future<void> _shot(String name) async {
    try {
      final boundary =
          _hostKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      final render = boundary ?? _rootKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (render == null) {
        debugPrint('PROBE $name: no boundary');
        return;
      }
      final img = await render.toImage(pixelRatio: 1.0);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) {
        debugPrint('PROBE $name: no data');
        return;
      }
      final file = File('${Directory.systemTemp.path}/$name.png');
      file.writeAsBytesSync(data.buffer.asUint8List());
      debugPrint('PROBE wrote ${file.path}');
    } catch (e) {
      debugPrint('PROBE $name failed: $e');
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (component, entry) = _pages[_page];
    return RepaintBoundary(
      key: _rootKey,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: JsRuntimeManager.navigatorKey = GlobalKey<NavigatorState>(),
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: SingleChildScrollView(
            controller: _scroll,
            child: Column(
              children: [
                // 订单页在正式 App 里是贴在 tab 容器里的，这里给它一个手机宽度
                // 的视口，模拟真实观感。
                Center(
                  child: SizedBox(
                    width: _orderPage ? 420 : null,
                    height: _pageHeight,
                    child: RepaintBoundary(
                      key: _hostKey,
                      child: JsUiWidget(
                        jsAsset: _url(component, entry),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
