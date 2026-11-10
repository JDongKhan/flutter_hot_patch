package com.example.hot_plugin_device_info

import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BasicMessageChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.StandardMessageCodec

/// 示例三方库 A 的 Android 原生实现（MethodChannel + BasicMessageChannel）。
class HotPluginDeviceInfoPlugin :
    FlutterPlugin,
    MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var messageChannel: BasicMessageChannel<Any?>

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "hot_patch/demo/device_info")
        channel.setMethodCallHandler(this)

        messageChannel = BasicMessageChannel(
            binding.binaryMessenger,
            "hot_patch/demo/device_info_msg",
            StandardMessageCodec.INSTANCE)
        messageChannel.setMessageHandler { message, reply ->
            val text = message as? String
            when {
                text == null -> reply.reply(null)
                text.startsWith("echo:") ->
                    reply.reply("Android:" + text.removePrefix("echo:"))
                text == "reverse" ->
                    // 原生 → Flutter → JS：反向 send，把 handler 的 reply 带回本次调用。
                    messageChannel.send("ping") { response ->
                        reply.reply("native:" + ((response as? String) ?: "nil"))
                    }
                else -> reply.reply(null)
            }
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "platformVersion" -> result.success("Android " + Build.VERSION.RELEASE)
            "deviceName" -> result.success(Build.MANUFACTURER + " " + Build.MODEL)
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        messageChannel.setMessageHandler(null)
    }
}
