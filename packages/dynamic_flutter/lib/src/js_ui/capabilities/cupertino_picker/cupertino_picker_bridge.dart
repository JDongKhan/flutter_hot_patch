// ===== 能力：CupertinoPicker 宿主渲染 + FixedExtentScrollController 句柄桥 =====
//
// 一个能力 = 描述符 + 通道 + 桥接组件 + 组件注册，全部内聚在本文件。
//
// 句柄桥（通用层，见 capabilities/core/object_bridge.dart）：
//   JS 侧 `new FixedExtentScrollController({initialItem})` 经
//   `__bindHandle('ctrl/FixedExtent', …)` 登记，通用通道 `jsHandle` 的 create 落到
//   本桥描述符 → 创建宿主真实 FixedExtentScrollController；渲染 CupertinoPicker
//   （scrollController: {__handle: id}）时按 id 取真实 controller 并挂转发
//   （滚动 → invoke 回传 `selectedItem` → JS 镜像更新 → 触发 listeners）。
//   jumpToItem 走通用 op（call）；dispose 走通用 release。
//
// 组件映射：`CupertinoPicker` 的 `.builder` 形态由生成器代理类展开成子结点
// （`__items`），宿主按 `CupertinoPicker.builder` 还原——itemExtent / 放大与
// squeeze / 选中回调 / 选中框都从 props + children 一对一还原，不做类型特判。
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';

import '../../js_widget_registry.dart';
import '../core/object_bridge.dart';
import '../core/from_json/dart_values_from_json.dart';

/// FixedExtentScrollController 句柄桥：真实 controller 由 onCreate 按 JS 侧下发
/// 的 `initialItem` 创建（构造参数只走 meta，渲染期不再补建）。
final JsObjectBridge<FixedExtentScrollController> _fixedExtentBridge =
    JsObjectBridge<FixedExtentScrollController>(
      kind: 'ctrl/FixedExtent',
      create: (_, meta) => FixedExtentScrollController(
        initialItem: _initialItemOf(meta is Map ? meta : null),
      ),
      // 「当前选中项」是纯镜像：JS 侧 itemBuilder 的选中高亮与上层联动都读它；
      // 宿主滚动（用户拨动 / jumpToItem）→ 回传 selectedItem。尚无 clients 时
      // 返回 null，挂上视图那一帧由 renderer 补一次快照。
      forward: (controller) => controller.hasClients
          ? [
              {'selectedItem': controller.selectedItem},
            ]
          : null,
      onOp: (c, op, payload) {
        if (op == 'call') {
          final method = payload['method']?.toString() ?? '';
          final args = payload['args'] is List
              ? payload['args'] as List
              : const [];
          if (method == 'jumpToItem' && args.isNotEmpty && args[0] is num) {
            c.jumpToItem((args[0] as num).toInt());
          }
        }
        return null;
      },
    );

/// 从 props / 句柄 meta 里取 `initialItem`（缺省 0，与 Flutter 同名参数一致）。
int _initialItemOf(Map<dynamic, dynamic>? json) {
  final v = json?['initialItem'];
  return v is num ? v.toInt() : 0;
}

/// 幂等注册 FixedExtentScrollController 句柄 kind（由 js_ui_capabilities
/// 聚合调用）。
void ensureCupertinoPickerChannels() => _fixedExtentBridge.ensure();

/// 子结点读取：builder 代理展开结果走内部键 `__items`（0 项也是合法展开结果，
/// 不能因为为空就回退到普通 children）；普通构造形态读 Dart 形参名 `children`。
List<Widget> _itemsOf(JsRenderContext c) {
  final expanded = c.children['__items'];
  if (expanded is List<Widget>) return expanded;
  final own = c.children['children'];
  return own is List<Widget> ? own : const <Widget>[];
}

/// CupertinoPicker 宿主渲染。
///
/// `selectionOverlay` 是 widget 实参 → 由构造函数归入 children slot；未传时用
/// Flutter 自己的默认选中框（与 Dart 侧缺省语义一致）。
Widget _cupertinoPicker(JsRenderContext c) {
  final items = _itemsOf(c);
  final overlay = c.children['selectionOverlay'] as Widget?;
  final itemExtent = c.double_('itemExtent') ?? 32.0;
  final onSelected = c.on1<int>('onSelectedItemChanged') ?? (_) {};
  final magnification = c.double_('magnification') ?? 1.0;
  final squeeze = c.double_('squeeze') ?? 1.45;
  final diameterRatio = c.double_('diameterRatio') ?? 1.1;
  final offAxisFraction = c.double_('offAxisFraction') ?? 0.0;
  final useMagnifier = c.bool_('useMagnifier') ?? false;
  final backgroundColor = c.color('backgroundColor');

  Widget build(FixedExtentScrollController? controller, {Key? key}) =>
      CupertinoPicker.builder(
        key: key,
        scrollController: controller,
        itemExtent: itemExtent,
        onSelectedItemChanged: onSelected,
        magnification: magnification,
        squeeze: squeeze,
        diameterRatio: diameterRatio,
        offAxisFraction: offAxisFraction,
        useMagnifier: useMagnifier,
        backgroundColor: backgroundColor,
        selectionOverlay:
            overlay ?? const CupertinoPickerDefaultSelectionOverlay(),
        childCount: items.length,
        itemBuilder: (_, index) => items[index],
      );

  final id = JsObjectBridge.idOf(c.props['scrollController']);
  if (id == null) return build(null, key: c.key);
  // controller 在 JS 构造时已建好（initialItem 随 create 的 meta 下发），
  // 这里只按 id 取；selectedItem 回传由桥的 forward 完成。
  final controller = _fixedExtentBridge.require(id);
  _fixedExtentBridge.forwardOnNextFrame(id);
  return build(controller, key: c.key);
}

/// 注册 CupertinoPicker 宿主组件映射。
void registerCupertinoPickerWidgets(JsWidgetRegistry r) {
  r.register('CupertinoPicker', _cupertinoPicker);
}
