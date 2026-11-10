import FlutterMacOS
import Foundation

/// 示例三方库 A 的 macOS 原生实现。
public class HotPluginDeviceInfoPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "hot_patch/demo/device_info",
      binaryMessenger: registrar.messenger)
    registrar.addMethodCallDelegate(HotPluginDeviceInfoPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "platformVersion":
      let v = ProcessInfo.processInfo.operatingSystemVersion
      result("macOS \(v.majorVersion).\(v.minorVersion).\(v.patchVersion)")
    case "deviceName":
      result(Host.current().localizedName ?? "macOS")
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
