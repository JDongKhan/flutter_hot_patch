import FlutterMacOS
import Foundation

/// 示例三方库 B 的 macOS 原生实现：实例内维护计数。
public class HotPluginCounterPlugin: NSObject, FlutterPlugin {
  private var count = 0

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "hot_patch/demo/counter",
      binaryMessenger: registrar.messenger)
    registrar.addMethodCallDelegate(HotPluginCounterPlugin(), channel: channel)
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
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
