package com.mohager.yaanieh

import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Google's test devices (Firebase Test Lab, which runs Play's
        // pre-launch report): no crash reports, no analytics there.
        // lib/core/device/test_device.dart
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "yaanieh/device")
            .setMethodCallHandler { call, result ->
                if (call.method == "isTestLab") {
                    val value = Settings.System.getString(contentResolver, "firebase.test.lab")
                    result.success("true" == value)
                } else {
                    result.notImplemented()
                }
            }
    }
}
