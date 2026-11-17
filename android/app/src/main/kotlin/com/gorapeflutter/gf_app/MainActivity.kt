package com.gorapeflutter.gf_app

import com.gorapeflutter.gf_app.driver.flutter.CredentialProviderChannelDriver
import com.gorapeflutter.gf_app.driver.flutter.FlutterDeviceKeyChannelDriver
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/** Android application entry point; native integrations are installed by drivers. */
class MainActivity : FlutterActivity() {
    // GF-01386 — Install Android Drivers after the Flutter engine is configured.
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        installDeviceKeyDriver(flutterEngine)
        installCredentialProviderDriver(flutterEngine)
    }

    // GF-01385 — Install the Flutter channel for Android device-key operations.
    private fun installDeviceKeyDriver(engine: FlutterEngine) {
        FlutterDeviceKeyChannelDriver(this).install(engine)
    }

    // GF-01384 — Install the Flutter channel for Credential Provider settings.
    private fun installCredentialProviderDriver(engine: FlutterEngine) {
        CredentialProviderChannelDriver(this).install(engine)
    }
}
