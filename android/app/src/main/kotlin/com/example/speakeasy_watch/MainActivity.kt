package com.example.speakeasy_watch

import android.content.Context
import android.media.AudioManager
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.speakeasy_watch/volume"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Keep screen on for the entire session — Wear OS aggressive power management
        // would otherwise dim and send to watch face mid-playback
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager

                when (call.method) {
                    "setMaxVolume" -> {
                        val max = audio.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                        audio.setStreamVolume(
                            AudioManager.STREAM_MUSIC,
                            max,
                            0 // no UI flag — silent set
                        )
                        result.success(max)
                    }
                    "setVolume" -> {
                        val percent = call.argument<Double>("percent") ?: 1.0
                        val max = audio.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                        val target = (max * percent).toInt().coerceIn(0, max)
                        audio.setStreamVolume(AudioManager.STREAM_MUSIC, target, 0)
                        result.success(target)
                    }
                    "getVolume" -> {
                        val current = audio.getStreamVolume(AudioManager.STREAM_MUSIC)
                        val max = audio.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                        result.success(if (max > 0) current.toDouble() / max.toDouble() else 0.0)
                    }
                    "getMaxVolume" -> {
                        result.success(audio.getStreamMaxVolume(AudioManager.STREAM_MUSIC))
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
