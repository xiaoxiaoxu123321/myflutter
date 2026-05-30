package com.example.dimensional

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "dimensional/native_video"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            if (call.method != "openVideo") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val url = call.argument<String>("url")
            if (url.isNullOrBlank()) {
                result.error("INVALID_URL", "Video url is empty", null)
                return@setMethodCallHandler
            }

            try {
                val intent = Intent(this, NativeVideoActivity::class.java).apply {
                    putExtra(NativeVideoActivity.EXTRA_URL, url)
                    putExtra(NativeVideoActivity.EXTRA_TITLE, call.argument<String>("title") ?: "视频")
                }
                startActivity(intent)
                result.success(true)
            } catch (error: Exception) {
                result.error("OPEN_FAILED", error.message, null)
            }
        }
    }
}
