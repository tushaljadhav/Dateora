package com.dateora.dateora

import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.media.ToneGenerator
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.sin

class MainActivity: FlutterActivity() {
    private val channelName = "com.dateora.dateora/sound"
    private var scannerBeepTrack: AudioTrack? = null
    private var fallbackToneGenerator: ToneGenerator? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        prepareDeepScannerBeep()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            if (call.method == "playBarcodeBeep") {
                try {
                    playDeepScannerBeep()
                    result.success(true)
                } catch (_: Exception) {
                    result.success(false)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun prepareDeepScannerBeep() {
        try {
            val sampleRate = 44100
            val durationMs = 110 // punchy scanner duration
            val numSamples = (sampleRate * durationMs) / 1000
            val samples = ShortArray(numSamples)
            val freq = 980.0 // 980Hz - Authentic deep, rich supermarket scanner tone

            for (i in 0 until numSamples) {
                // Smooth envelope (attack and decay) to prevent audio clicks and give a rounded, deep punch
                val envelope = when {
                    i < 80 -> i / 80.0
                    i > numSamples - 160 -> (numSamples - i) / 160.0
                    else -> 1.0
                }
                val angle = 2.0 * Math.PI * i * freq / sampleRate
                samples[i] = (sin(angle) * 32767.0 * envelope * 0.95).toInt().toShort()
            }

            val bufferSize = samples.size * 2
            @Suppress("DEPRECATION")
            val track = AudioTrack(
                AudioManager.STREAM_MUSIC,
                sampleRate,
                AudioFormat.CHANNEL_OUT_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                bufferSize,
                AudioTrack.MODE_STATIC
            )
            track.write(samples, 0, samples.size)
            scannerBeepTrack = track
        } catch (_: Exception) {
            scannerBeepTrack = null
            try {
                fallbackToneGenerator = ToneGenerator(AudioManager.STREAM_MUSIC, 100)
            } catch (_: Exception) {
                fallbackToneGenerator = null
            }
        }
    }

    private fun playDeepScannerBeep() {
        try {
            val track = scannerBeepTrack
            if (track != null) {
                track.stop()
                track.reloadStaticData()
                track.play()
                return
            }
        } catch (_: Exception) {
        }

        try {
            if (fallbackToneGenerator == null) {
                fallbackToneGenerator = ToneGenerator(AudioManager.STREAM_MUSIC, 100)
            }
            fallbackToneGenerator?.startTone(ToneGenerator.TONE_PROP_ACK, 120)
        } catch (_: Exception) {
        }
    }

    override fun onDestroy() {
        try {
            scannerBeepTrack?.release()
        } catch (_: Exception) {
        }
        scannerBeepTrack = null

        try {
            fallbackToneGenerator?.release()
        } catch (_: Exception) {
        }
        fallbackToneGenerator = null

        super.onDestroy()
    }
}
