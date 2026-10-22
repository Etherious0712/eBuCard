package com.ebucard.ebucard

import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.ebucard/hce")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isSupported" -> result.success(
                        packageManager.hasSystemFeature(PackageManager.FEATURE_NFC_HOST_CARD_EMULATION)
                    )
                    "setCard" -> {
                        CardEmulationService.setCard(
                            this,
                            call.argument<String>("url"),
                            call.argument<Boolean>("sharing") ?: false,
                        )
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
