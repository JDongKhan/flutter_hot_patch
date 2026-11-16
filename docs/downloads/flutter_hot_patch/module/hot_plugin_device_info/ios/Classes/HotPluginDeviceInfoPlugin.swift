import Flutter
import UIKit

/// 示例三方库 A 的 iOS 原生实现
/// （MethodChannel + BasicMessageChannel + EventChannel）。
public class HotPluginDeviceInfoPlugin: NSObject, FlutterPlugin {
  private var messageChannel: FlutterBasicMessageChannel?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = HotPluginDeviceInfoPlugin()
    let channel = FlutterMethodChannel(
      name: "hot_patch/demo/device_info",
      binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: channel)

    let messageChannel = FlutterBasicMessageChannel(
      name: "hot_patch/demo/device_info_msg",
      binaryMessenger: registrar.messenger(),
      codec: FlutterStandardMessageCodec.sharedInstance())
    instance.messageChannel = messageChannel
    messageChannel.setMessageHandler { message, reply in
      guard let text = message as? String else {
        reply(nil)
        return
      }
      if text.hasPrefix("echo:") {
        reply("iOS:" + String(text.dropFirst("echo:".count)))
      } else if text == "reverse" {
        messageChannel.sendMessage("ping") { response in
          reply("native:" + ((response as? String) ?? "nil"))
        }
      } else {
        reply(nil)
      }
    }

    // 后缀对应 Dart 侧 `ticks(tag)`：同名平台通道只能有一个活跃流，
    // 原生 / JS 两栏对比各用独立 channel 名。
    for suffix in ["", "_native", "_js"] {
      let eventChannel = FlutterEventChannel(
        name: "hot_patch/demo/device_info_events" + suffix,
        binaryMessenger: registrar.messenger())
      eventChannel.setStreamHandler(DeviceInfoStreamHandler())
    }
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

/// 原生侧事件源：onListen 启动计时器，onCancel 停止。
private final class DeviceInfoStreamHandler: NSObject, FlutterStreamHandler {
  private var timer: Timer?
  private var count = 0

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    count = 0
    timer?.invalidate()
    timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
      self.count += 1
      events(self.count)
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    timer?.invalidate()
    timer = nil
    return nil
  }
}
