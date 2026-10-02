package com.example.scripture_sermon_studio

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "scripture_sermon_studio/platform"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "share" -> {
                    val text = call.argument<String>("text") ?: ""
                    val subject = call.argument<String>("subject") ?: ""
                    try {
                        val send = Intent(Intent.ACTION_SEND).apply {
                            type = "text/plain"
                            putExtra(Intent.EXTRA_TEXT, text)
                            if (subject.isNotEmpty()) putExtra(Intent.EXTRA_SUBJECT, subject)
                        }
                        startActivity(Intent.createChooser(send, null))
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("share_failed", e.message, null)
                    }
                }
                "openStore" -> {
                    val id = call.argument<String>("id") ?: packageName
                    val url = call.argument<String>("url")
                        ?: "https://play.google.com/store/apps/details?id=$id"
                    try {
                        try {
                            startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=$id")))
                        } catch (e: ActivityNotFoundException) {
                            startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
                        }
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("store_failed", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
