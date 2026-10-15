// ===== 能力：TextEditingController 句柄桥 + TextField 注册 =====
//
// 一个能力 = 描述符 + 通道 + 桥接组件 + 组件注册，全部内聚在本文件。
//
// 句柄桥（通用层，见 capabilities/handle_registry.dart）：
//   JS 侧 `new TextEditingController()` 经 `reg(obj, 'ctrl/Text', {meta:{fn}})`
//   登记，通用通道 `jsHandle` 的 create 落到本文件的 `ctrl/Text` 描述符 →
//   创建宿主真实 controller 并登记输入回传句柄；TextField(controller:
//   {__handle: id}) 渲染时宿主按 id 取真实 controller 作为受控输入，用户输入经
//   textFn 回传 JS 实例镜像（更新 text + 触发其 listeners）。
//   setText/setSelection/clear 走通用 op（set/call）；dispose 走通用 release。
//   TextField 的注册（含受控/非受控分流）随能力内聚于此。
import 'package:flutter/material.dart';

import '../../../json/flutter_from_json.dart';
import '../../js_widget_registry.dart';
import '../handle_registry.dart';

final Map<String, TextEditingController> _jsTextControllers = {};
final Map<String, Object?> _jsTextHandles = {};

bool _textKindRegistered = false;

/// 幂等注册 TextEditingController 句柄 kind（由 js_ui_capabilities.ensureJsUiCapabilities
/// 聚合调用，与 ensureScrollControllerChannels 并列）。
void ensureTextEditingControllerChannels() {
  if (_textKindRegistered) return;
  _textKindRegistered = true;
  registerHandleKind('ctrl/Text', JsHandleKind(
    onCreate: (id, meta) {
      // putIfAbsent：与 ctrl/Scroll 同款——同一句柄 id 只对应一个真实对象
      // （重复 create 时复用，不产生第二个 controller 泄漏）。
      _jsTextControllers.putIfAbsent(id, () => TextEditingController());
      _jsTextHandles[id] = meta is Map ? meta['fn'] : null;
    },
    onOp: (id, op, payload) {
      final c = _jsTextControllers[id];
      if (c == null) return null;
      if (op == 'set') {
        if (payload['name'] == 'text') c.text = payload['value']?.toString() ?? '';
      } else if (op == 'call') {
        final method = payload['method']?.toString() ?? '';
        final args = payload['args'] is List ? payload['args'] as List : const [];
        if (method == 'clear') {
          c.clear();
        } else if (method == 'setSelection') {
          final b = args.isNotEmpty && args[0] is num ? (args[0] as num).toInt() : 0;
          final e = args.length > 1 && args[1] is num ? (args[1] as num).toInt() : b;
          c.selection = TextSelection(baseOffset: b, extentOffset: e);
        }
      }
      return null;
    },
    onRelease: (id) {
      _jsTextControllers.remove(id)?.dispose();
      _jsTextHandles.remove(id);
    },
  ));
}

/// 从 props 的 controller 取值里解析 JS TextEditingController 句柄 id。
/// JS 侧实例跨桥经 toJSON 序列化为 `{__handle: 'js:ctrl/Text#N'}`。
String? textEditingControllerIdOf(Object? prop) {
  if (prop is Map) {
    final id = prop['__handle'];
    if (id is String) return id;
  }
  return null;
}

/// 文本能力域组件注册。
void registerTextWidgets(JsWidgetRegistry r) {
  r.register('TextField', (c) {
    // controller 是 JS TextEditingController 句柄 → 受控模式：用桥接表中
    // 的真实 controller，用户输入经 textFn 回传 JS 实例镜像（更新 text +
    // 触发其 listeners），同时照常触发 onChanged 事件。
    final tecId = textEditingControllerIdOf(c.props['controller']);
    final external = tecId != null ? _jsTextControllers[tecId] : null;
    return _JsTextField(
      controller: external,
      onControllerText: external == null
          ? null
          : (v) {
              final h = tecId != null ? _jsTextHandles[tecId] : null;
              if (h != null) c.invoke(h, [v]);
            },
      value: c.str('value'),
      onChanged: c.on1<String>('event'),
      hintText: c.str('hintText'),
      labelText: c.str('labelText'),
      obscureText: c.bool_('obscureText') ?? false,
      enabled: c.bool_('enabled'),
      keyboardType: textInputTypeFromJson(c.props['keyboardType']),
      maxLines: c.int_('maxLines') ?? 1,
      style: textStyleFromJson(c.map('style')),
      textAlign: textAlignFromJson(c.props['textAlign']),
    );
  });
}

/// TextField 受控封装：JS 侧只下发 value 字符串与 onChanged 句柄，
/// controller 由宿主持有并在 props.value 变化时同步（光标移到末尾）。
class _JsTextField extends StatefulWidget {
  const _JsTextField({
    this.controller,
    this.onControllerText,
    required this.value,
    required this.onChanged,
    this.hintText,
    this.labelText,
    this.obscureText = false,
    this.enabled,
    this.keyboardType,
    this.maxLines = 1,
    this.style,
    this.textAlign,
  });

  /// 外部受控 controller（JS TextEditingController 桥接实例）；null 时内部
  /// 自建（非受控模式）。
  final TextEditingController? controller;

  /// 受控模式下用户输入回传 JS 镜像的通道（invoke textFn）。
  final ValueChanged<String>? onControllerText;

  final String? value;
  final ValueChanged<String>? onChanged;
  final String? hintText;
  final String? labelText;
  final bool obscureText;
  final bool? enabled;
  final TextInputType? keyboardType;
  final int? maxLines;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  State<_JsTextField> createState() => _JsTextFieldState();
}

class _JsTextFieldState extends State<_JsTextField> {
  late final TextEditingController _controller = widget.controller ??
      TextEditingController(text: widget.value ?? '');

  @override
  void didUpdateWidget(_JsTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 外部受控时 controller 由桥接表持有，不回写；仅自建（非受控）且
    // value 下发变化时同步 controller，避免清空用户输入。
    if (widget.controller != null) return;
    final v = widget.value;
    if (v != null && v != _controller.text) {
      _controller.value = TextEditingValue(
        text: v,
        selection: TextSelection.collapsed(offset: v.length),
      );
    }
  }

  @override
  void dispose() {
    // 外部 controller 由桥接表（jsHandle release → ctrl/Text onRelease）释放。
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onChanged = widget.onChanged;
    final onControllerText = widget.onControllerText;
    return TextField(
      controller: _controller,
      onChanged: onChanged == null
          ? onControllerText
          : (v) {
              onChanged(v);
              onControllerText?.call(v);
            },
      obscureText: widget.obscureText,
      enabled: widget.enabled,
      keyboardType: widget.keyboardType,
      // obscureText 时 Flutter 要求 maxLines == 1
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      style: widget.style,
      textAlign: widget.textAlign ?? TextAlign.start,
      decoration: InputDecoration(
        hintText: widget.hintText,
        labelText: widget.labelText,
      ),
    );
  }
}
