import 'package:flutter/widgets.dart';

import 'hot_patch_widget.dart';

// ===========================================================================
// 原生服务策略扩展点：JS sendMessage(channel, ...) → 原生能力
//
// 与渲染层（WidgetRenderer/WidgetRendererRegistry）设计对称：
// JS 补丁里调 sendMessage('nativeToast', ...)，运行时按 channel 分发到
// 对应的 NativeService 实现。
//
// 扩展一个原生服务只需要两步：
//   1. 实现 NativeService 的子类（channel + handle）
//      - 与页面无关（日志/toast）→ 继承 GlobalNativeService
//      - 与页面相关（需要访问页面实例）→ 继承 InstanceNativeService
//   2. 注入：HotPatchWidget(nativeServices: [...])（实例级）
//      或 JsRuntimeManager.registerGlobal(...)（全局级）
//
// 稳定类（JsRuntimeManager / HotPatchWidget）无需改动。
// ===========================================================================

/// ===========================================================================
/// 策略抽象类：一个 JS→原生 服务通道
///
/// - [channel]：JS 侧 sendMessage(channel, ...) 使用的通道名
/// - [handle]：收到 JS 消息时执行的原生行为（用 [context] 做 UI 交互）
/// ===========================================================================
abstract class NativeService {
  const NativeService();

  /// JS→原生 通道名（与 JS 侧 sendMessage 的第一个参数一致）。
  String get channel;

  /// 处理 JS 发来的消息。
  void handle(BuildContext context, dynamic payload);
}

/// ===========================================================================
/// 全局服务基类：与页面无关（日志、toast 等）。
///
/// 注册：`JsRuntimeManager.registerGlobal(service)`；
/// handle 的 context 由框架取 `JsRuntimeManager.navigatorKey` 提供，
/// 全局一份，多个页面共享同一个处理器。
/// ===========================================================================
abstract class GlobalNativeService extends NativeService {
  const GlobalNativeService();
}

/// ===========================================================================
/// 实例（页面）服务基类：与具体页面相关，需要访问页面实例。
///
/// 注册：`JsRuntimeManager.register(pageKey, service)`；
/// 页面挂载时框架调用 [build]，注入 [HotPatchWidgetState]（页面实例），
/// 服务据此做页面级处理（如 setState 重建、读取页面 key/manager）。
///
/// 示例：页面级内部实现 setState 就是普通 InstanceNativeService。
/// ===========================================================================
abstract class InstanceNativeService extends NativeService {
  InstanceNativeService();

  HotPatchWidgetState? _state;

  /// 页面挂载时由框架调用：注入页面 state（多一个 HotPatchWidgetState
  /// 的构建钩子），之后可通过 [state] 访问页面实例。
  void build(HotPatchWidgetState state) {
    _state = state;
  }

  /// 当前绑定的页面 state（[build] 之后可用）。
  HotPatchWidgetState? get state => _state;
}

/// ===========================================================================
/// 管理类：注册 / 分发原生服务
///
/// HotPatchWidget 默认注册内置服务（SnackBarService 等）；业务方可通过
/// HotPatchWidget(nativeServices: ...) 注入自定义服务实现。
/// ===========================================================================
class NativeServiceRegistry {
  final Map<String, NativeService> _services = {};

  /// 注册一个服务（同 channel 覆盖旧的，后注册者优先）。
  void register(NativeService service) {
    _services[service.channel] = service;
  }

  /// 按通道名查找服务；未注册返回 null。
  NativeService? lookup(String channel) => _services[channel];

  /// 当前已注册的通道名。
  Set<String> get channels => _services.keys.toSet();
}
