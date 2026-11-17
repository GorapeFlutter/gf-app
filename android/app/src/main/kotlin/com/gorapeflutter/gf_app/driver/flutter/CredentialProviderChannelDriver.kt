package com.gorapeflutter.gf_app.driver.flutter

import android.app.Activity
import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import com.gorapeflutter.gf_app.GorapeCredentialProviderService
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Flutter-facing driver for Android Credential Provider status and settings. */
    // GF-01296 — Create the Flutter Driver for Credential Provider settings.
internal class CredentialProviderChannelDriver(private val activity: Activity) :
    MethodChannel.MethodCallHandler {

    // GF-01295 — Register the Credential Provider status and settings channel.
    fun install(engine: FlutterEngine) {
        val channel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    // GF-01294 — Dispatch Flutter requests to Credential Provider operations.
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "status" -> result.success(status())
            "openSettings" -> openSettings(result)
            else -> result.notImplemented()
        }
    }

    // GF-01195 — Reports OS support and GF Credential Provider registration.
    private fun status(): Map<String, Any> {
        val supported = Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE
        return mapOf(
            "apiLevel" to Build.VERSION.SDK_INT,
            "supported" to supported,
            "serviceRegistered" to isServiceRegistered(supported),
        )
    }

    // GF-01293 — Check whether the local CredentialProviderService is registered.
    private fun isServiceRegistered(supported: Boolean): Boolean {
        if (!supported) {
            return false
        }
        return try {
            activity.packageManager.getServiceInfo(
                ComponentName(activity, GorapeCredentialProviderService::class.java),
                0,
            )
            true
        } catch (_: Exception) {
            false
        }
    }

    // GF-01292 — Return the result of opening Android passkey-provider settings.
    private fun openSettings(result: MethodChannel.Result) {
        try {
            result.success(openCredentialProviderSettings())
        } catch (error: Exception) {
            result.error(
                "credential_provider_settings_unavailable",
                error.message ?: "Could not open Android credential settings.",
                null,
            )
        }
    }

    // GF-01196 — Launches Android's Passwords and Passkeys settings.
    private fun openCredentialProviderSettings(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            return false
        }
        val settingsIntent = Intent(Settings.ACTION_CREDENTIAL_PROVIDER)
        settingsIntent.data = Uri.parse("package:${activity.packageName}")
        if (settingsIntent.resolveActivity(activity.packageManager) == null) {
            return false
        }
        activity.startActivity(settingsIntent)
        return true
    }

    private companion object {
        const val CHANNEL_NAME = "com.gorapeflutter.gf_app/credential_provider"
    }
}
