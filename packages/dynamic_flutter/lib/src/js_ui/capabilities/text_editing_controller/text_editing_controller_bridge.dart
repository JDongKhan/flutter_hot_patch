// ===== 能力：TextEditingController 句柄桥 + TextField 注册 =====
//
// 一个能力 = 描述符 + 通道 + 桥接组件 + 组件注册，全部内聚在本文件。
//
// 句柄桥（通用层，见 capabilities/core/object_bridge.dart）：
//   JS 侧 `new TextEditingController()` 经 `reg(obj, 'ctrl/Text', {meta:{fn}})`
//   登记，通用通道 `jsHandle` 的 create 落到本桥的 `ctrl/Text` 描述符 →
//   创建宿主真实 controller 并登记输入回传句柄；TextField(controller:
//   {__handle: id}) 渲染时宿主按 id 取真实 controller 作为受控输入，用户输入经
//   textFn 回传 JS 实例镜像（更新 text + 触发其 listeners）。
//   setText/setSelection/clear 走通用 op（set/call）；dispose 走通用 release。
//   TextField 的注册（含受控/非受控分流）随能力内聚于此。
import 'package:flutter/material.dart';

import '../../js_widget_registry.dart';
import '../base_widget/text_from_json.dart';
import '../core/from_json/input_decoration_from_json.dart';
import '../core/object_bridge.dart';

/// TextEditingController 句柄桥：创建/回传句柄登记/释放全走通用层，这里
/// 只留 set text / clear / setSelection 的 op 分派。
final JsObjectBridge<TextEditingController> _textBridge =
    JsObjectBridge<TextEditingController>(
      kind: 'ctrl/Text',
      // 初始文本随 create 的 meta 下发（JS 构造参数 `TextEditingController(text)`
      // 在 JS 构造时就落到真实 controller，不再等第一次 set op）。
      create: (_, meta) {
        final m = meta is Map ? meta : const {};
        final text = m['text'];
        return TextEditingController(text: text == null ? '' : '$text');
      },
      onOp: (c, op, payload) {
        if (op == 'set') {
          if (payload['name'] == 'text') {
            c.text = payload['value']?.toString() ?? '';
          }
        } else if (op == 'call') {
          final method = payload['method']?.toString() ?? '';
          final args = payload['args'] is List
              ? payload['args'] as List
              : const [];
          if (method == 'clear') {
            c.clear();
          } else if (method == 'setSelection') {
            final b = args.isNotEmpty && args[0] is num
                ? (args[0] as num).toInt()
                : 0;
            final e = args.length > 1 && args[1] is num
                ? (args[1] as num).toInt()
                : b;
            c.selection = TextSelection(baseOffset: b, extentOffset: e);
          }
        }
        return null;
      },
    );

/// 幂等注册 TextEditingController 句柄 kind（由 js_ui_capabilities.ensureJsUiCapabilities
/// 聚合调用，与 ensureScrollControllerChannels 并列）。
void ensureTextEditingControllerChannels() => _textBridge.ensure();

/// 文本能力域组件注册。
void registerTextWidgets(JsWidgetRegistry r) {
  r.register('TextField', (c) {
    // 形参与 Flutter `TextField` 完全一致：受控态由 `controller` 句柄承担
    // （桥接表里的真实 controller），`controller` 缺省时传 null ——
    // `TextField` 自己创建并释放内部 controller，宿主不额外持有。
    final tecId = JsObjectBridge.idOf(c.props['controller']);
    final external = tecId != null ? _textBridge.controllerAt(tecId) : null;
    final onChanged = c.on1<String>('onChanged');
    // 用户输入回传 JS 实例镜像（更新 text + 触发其 listeners）只在受控模式
    // 需要：JS 侧把 controller 句柄给过来了才有镜像对象可回传。
    final mirrorBack = tecId != null;
    final obscureText = c.bool_('obscureText') ?? false;
    final maxLines = c.int_('maxLines') ?? 1;
    return TextField(
      key: c.key,
      controller: external,
      onChanged: (onChanged == null && !mirrorBack)
          ? null
          : (v) {
              onChanged?.call(v);
              if (mirrorBack) {
                final h = _textBridge.fnHandleOf(tecId);
                if (h != null) c.invoke(h, [v]);
              }
            },
      // 整个 InputDecoration 由 from_json 一次还原（边框 / 填充 / 内边距 /
      // 图标都在里面），这里只做输入与事件回传。
      // 未下发时传 null，`TextField` 自身按 Flutter 默认装饰渲染。
      decoration: inputDecorationFromJson(c, c.map('decoration')),
      obscureText: obscureText,
      enabled: c.bool_('enabled'),
      keyboardType: c.textInputType('keyboardType'),
      // obscureText 时 Flutter 要求 maxLines == 1。
      maxLines: obscureText ? 1 : maxLines,
      style: c.textStyle('style'),
      // `TextField.textAlign` 非空（Flutter 默认 TextAlign.start），
      // 未下发时取同一个默认值。
      textAlign: c.textAlign('textAlign') ?? TextAlign.start,
    );
  });
}
