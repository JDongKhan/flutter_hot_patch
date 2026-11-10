package com.example.hot_plugin_counter

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/// 示例三方库 B 的 Android 原生实现：实例内维护计数，并支持反向回调。
class HotPluginCounterPlugin :
    FlutterPlugin,
    MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var count = 0

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "hot_patch/demo/counter")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "increment" -> {
                count += call.argument<Int>("step") ?: 1
                result.success(count)
            }
            "reset" -> {
                count = 0
                result.success(count)
            }
            "pingFromNative" -> {
                // 原生 → Flutter → JS：同一个 channel 反向调用，把 handler 的
                // 返回值作为本次调用的结果回给 Dart/JS。
                channel.invokeMethod("onNativeEvent", "Android-ping", object : Result {
                    override fun success(value: Any?) {
                        result.success("native → " + (value?.toString() ?: ""))
                    }

                    override fun error(code: String, message: String?, details: Any?) {
                        result.error(code, message, details)
                    }

                    override fun notImplemented() {
                        result.error("no_handler", "Flutter/JS 未响应 onNativeEvent", null)
                    }
                })
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
