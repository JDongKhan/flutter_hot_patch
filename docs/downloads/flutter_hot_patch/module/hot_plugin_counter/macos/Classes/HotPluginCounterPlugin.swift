import FlutterMacOS
import Foundation

/// 示例三方库 B 的 macOS 原生实现：实例内维护计数，并支持反向回调。
public class HotPluginCounterPlugin: NSObject, FlutterPlugin {
  private var count = 0
  private var channel: FlutterMethodChannel?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "hot_patch/demo/counter",
      binaryMessenger: registrar.messenger)
    let instance = HotPluginCounterPlugin()
    instance.channel = channel
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "increment":
      let args = call.arguments as? [String: Any]
      count += (args?["step"] as? Int) ?? 1
      result(count)
    case "reset":
      count = 0
      result(count)
    case "pingFromNative":
      // 原生 → Flutter → JS：同一个 channel 反向调用，把 handler 的返回值
      // 作为本次调用的结果回给 Dart/JS。
      channel?.invokeMethod("onNativeEvent", arguments: "macOS-ping") { response in
        if let ack = response as? String {
          result("native → " + ack)
        } else {
          result(FlutterError(
            code: "no_handler",
            message: "Flutter/JS 未响应 onNativeEvent",
            details: nil))
        }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
