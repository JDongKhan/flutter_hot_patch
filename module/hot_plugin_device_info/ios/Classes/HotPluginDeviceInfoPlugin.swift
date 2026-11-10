import Flutter
import UIKit

/// 示例三方库 A 的 iOS 原生实现。
public class HotPluginDeviceInfoPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "hot_patch/demo/device_info",
      binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(HotPluginDeviceInfoPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "platformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "deviceName":
      result(UIDevice.current.name)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
