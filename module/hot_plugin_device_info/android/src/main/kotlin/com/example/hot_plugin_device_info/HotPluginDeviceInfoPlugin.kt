package com.example.hot_plugin_device_info

import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BasicMessageChannel
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.StandardMessageCodec
import java.util.Timer
import java.util.TimerTask

/// 示例三方库 A 的 Android 原生实现
/// （MethodChannel + BasicMessageChannel + EventChannel）。
class HotPluginDeviceInfoPlugin :
    FlutterPlugin,
    MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var messageChannel: BasicMessageChannel<Any?>
    private lateinit var eventChannel: EventChannel
    private var timer: Timer? = null
    private var tick = 0

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
                    messageChannel.send("ping") { response ->
                        reply.reply("native:" + ((response as? String) ?: "nil"))
                    }
                else -> reply.reply(null)
            }
        }

        eventChannel = EventChannel(
            binding.binaryMessenger,
            "hot_patch/demo/device_info_events")
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                tick = 0
                timer?.cancel()
                timer = Timer()
                timer?.scheduleAtFixedRate(object : TimerTask() {
                    override fun run() {
                        tick += 1
                        Handler(Looper.getMainLooper()).post { events?.success(tick) }
                    }
                }, 0L, 500L)
            }

            override fun onCancel(arguments: Any?) {
                timer?.cancel()
                timer = null
            }
        })
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
        eventChannel.setStreamHandler(null)
        timer?.cancel()
        timer = null
    }
}
