package com.gorapeflutter.gf_app.driver.flutter

import android.app.Activity
import android.os.Handler
import android.os.Looper
import com.gorapeflutter.gf_app.driver.devicekey.AndroidDeviceKeyDriver
import com.gorapeflutter.gf_app.entity.device.DeviceKeyChannelResponse
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/** Adapts Flutter method-channel calls to the Android Keystore driver. */
    // GF-01291 — Create the Flutter MethodChannel Driver for Android device keys.
internal class FlutterDeviceKeyChannelDriver(private val activity: Activity) :
    MethodChannel.MethodCallHandler {
    private val keyDriver = AndroidDeviceKeyDriver(activity)
    private val backgroundExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    // GF-01139 — Installs the Flutter-to-Keystore method channel.
    fun install(engine: FlutterEngine) {
        val channel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    // GF-01155 — Handles a native method-channel call.
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        backgroundExecutor.execute(DeviceKeyCall(this, call, result))
    }

    // GF-01140 — Routes method-channel commands to the matching Keystore operation.
    private fun dispatch(call: MethodCall): Any? {
        // GF-02082 — Selects the operation and validates its required arguments.
        return when (call.method) {
            "availability" -> keyDriver.availability().toMethodChannelMap()
            "generateKey" -> generateKey(call)
            "sign" -> sign(call)
            "hasKey" -> keyDriver.hasKey(requiredArgument(call, "keyIdentifier"))
            "deleteKey" -> deleteKey(call)
            else -> throw IllegalArgumentException("Unknown method: ${call.method}")
        }
    }

    // GF-01290 — Decode create-key input and call the Android device-key Driver.
    private fun generateKey(call: MethodCall): Map<String, Any> {
        // GF-02083 — Decodes the registration challenge before key creation.
        val alias = requiredArgument(call, "keyIdentifier")
        val challenge = decodeBase64Url(requiredArgument(call, "challenge"))
        return keyDriver.generateKey(alias, challenge).toMethodChannelMap()
    }

    // GF-01289 — Decode challenge bytes and call the Android device-key signing Driver.
    private fun sign(call: MethodCall): String {
        // GF-02084 — Decodes proof bytes before asking Keystore to sign.
        val alias = requiredArgument(call, "keyIdentifier")
        val data = decodeBase64Url(requiredArgument(call, "data"))
        return keyDriver.sign(alias, data)
    }

    // GF-01288 — Delete the requested Android device-key alias.
    private fun deleteKey(call: MethodCall): Nothing? {
        keyDriver.deleteKey(requiredArgument(call, "keyIdentifier"))
        return null
    }

    // GF-01149 — Reads a required string argument from a method-channel call.
    private fun requiredArgument(call: MethodCall, name: String): String {
        return call.argument<String>(name)
            ?: throw IllegalArgumentException("Missing argument: $name")
    }

    // GF-01287 — Decode an unpadded Base64url channel argument.
    private fun decodeBase64Url(value: String): ByteArray =
        com.gorapeflutter.gf_app.share.Base64UrlCodec.decode(value)

    // GF-01286 — Capture a device-key channel request for background execution.
    private class DeviceKeyCall(
        private val driver: FlutterDeviceKeyChannelDriver,
        private val call: MethodCall,
        private val result: MethodChannel.Result,
    ) : Runnable {
        // GF-01156 — Runs Keystore work off the UI thread.
        override fun run() {
            val response = executeCall()
            driver.mainHandler.post(ChannelResultDelivery(result, response))
        }

        // GF-01160 — Captures native operation success or failure.
        private fun executeCall(): DeviceKeyChannelResponse {
            return try {
                DeviceKeyChannelResponse.Success(driver.dispatch(call))
            } catch (error: Exception) {
                DeviceKeyChannelResponse.Failure(error.message ?: "Android Keystore operation failed.")
            }
        }
    }

    // GF-01285 — Capture a channel result for main-thread delivery.
    private class ChannelResultDelivery(
        private val result: MethodChannel.Result,
        private val response: DeviceKeyChannelResponse,
    ) : Runnable {
        // GF-01157 — Returns the result on the UI thread.
        override fun run() {
            when (response) {
                is DeviceKeyChannelResponse.Success -> deliverSuccess(response.value)
                is DeviceKeyChannelResponse.Failure -> deliverFailure(response.message)
            }
        }

        // GF-01158 — Delivers a successful native result.
        private fun deliverSuccess(value: Any?) {
            result.success(value)
        }

        // GF-01159 — Converts native failures into channel errors.
        private fun deliverFailure(message: String) {
            result.error("keystore_error", message, null)
        }
    }

    private companion object {
        const val CHANNEL_NAME = "com.gorapeflutter.gf_app/device_key"
    }
}
