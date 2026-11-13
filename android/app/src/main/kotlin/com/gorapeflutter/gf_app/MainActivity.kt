package com.gorapeflutter.gf_app

import android.os.Build
import android.os.Handler
import android.os.Looper
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.security.KeyPair
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.Signature
import java.security.spec.ECGenParameterSpec
import java.util.concurrent.Executors

/**
 * Android Keystore + Key Attestation bridge.
 *
 * The private key never leaves Android Keystore. Keys are EC P-256 keys with
 * the Gorape registration challenge bound through
 * [KeyGenParameterSpec.setAttestationChallenge]. Certificate chains are
 * returned leaf-first as PEM, which is what Gorape's Android verifier expects.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "com.gorapeflutter.gf_app/device_key"
    private val keyStoreName = "AndroidKeyStore"
    private val hardwareKeystoreFeature = "android.hardware.hardware_keystore"
    private val strongBoxKeystoreFeature = "android.hardware.strongbox_keystore"
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                executor.execute {
                    val outcome = runCatching { dispatch(call) }
                    mainHandler.post {
                        outcome.fold(
                            { value -> result.success(value) },
                            { error ->
                                result.error(
                                    "keystore_error",
                                    error.message ?: "Android Keystore operation failed.",
                                    null,
                                )
                            },
                        )
                    }
                }
            }
    }

    private fun dispatch(call: MethodCall): Any? {
        return when (call.method) {
            "availability" -> availability()
            "generateKey" -> {
                val alias = requireArgument(call, "keyIdentifier")
                val challenge = decodeBase64Url(requireArgument(call, "challenge"))
                generateKey(alias, challenge)
            }
            "sign" -> {
                val alias = requireArgument(call, "keyIdentifier")
                val data = decodeBase64Url(requireArgument(call, "data"))
                sign(alias, data)
            }
            "hasKey" -> hasKey(requireArgument(call, "keyIdentifier"))
            "deleteKey" -> {
                deleteKey(requireArgument(call, "keyIdentifier"))
                null
            }
            else -> throw IllegalArgumentException("Unknown method: ${call.method}")
        }
    }

    private fun availability(): Map<String, Any?> {
        val hasStrongBox = Build.VERSION.SDK_INT >= Build.VERSION_CODES.P &&
            packageManager.hasSystemFeature(strongBoxKeystoreFeature)
        val hardwareBacked = packageManager.hasSystemFeature(hardwareKeystoreFeature)
        return mapOf(
            "supported" to (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N),
            "hardwareBacked" to hardwareBacked,
            "attestationSupported" to (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N),
            "securityLevel" to when {
                hasStrongBox -> "strongbox"
                hardwareBacked -> "trusted_environment"
                else -> "software"
            },
            "reason" to if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
                "Android 7.0 (API 24) or newer is required for key attestation."
            } else {
                null
            },
        )
    }

    private fun generateKey(alias: String, challenge: ByteArray): Map<String, Any?> {
        val keyStore = loadKeyStore()
        deleteAliasQuietly(keyStore, alias)

        val strongBoxRequested = Build.VERSION.SDK_INT >= Build.VERSION_CODES.P &&
            packageManager.hasSystemFeature(strongBoxKeystoreFeature)

        val generated = if (strongBoxRequested) {
            try {
                generateKeyPair(alias, challenge, strongBox = true) to true
            } catch (_: Exception) {
                // StrongBox is optional; fall back to the TEE-backed Keystore.
                deleteAliasQuietly(keyStore, alias)
                generateKeyPair(alias, challenge, strongBox = false) to false
            }
        } else {
            generateKeyPair(alias, challenge, strongBox = false) to false
        }

        val keyPair = generated.first
        val chain = keyStore.getCertificateChain(alias)
        if (chain.isNullOrEmpty()) {
            deleteAliasQuietly(keyStore, alias)
            throw IllegalStateException(
                "Android Key Attestation did not return a certificate chain. " +
                    "Use a device with a hardware-backed Keystore.",
            )
        }

        val hardwareBacked =
            packageManager.hasSystemFeature(hardwareKeystoreFeature)
        return mapOf(
            "keyIdentifier" to alias,
            "publicKeyPem" to publicKeyPem(keyPair),
            "algorithm" to "ES256",
            "securityLevel" to when {
                generated.second -> "strongbox"
                hardwareBacked -> "trusted_environment"
                else -> "software"
            },
            "certificateChain" to chain.map { certificatePem(it.encoded) },
        )
    }

    private fun generateKeyPair(
        alias: String,
        challenge: ByteArray,
        strongBox: Boolean,
    ): KeyPair {
        val builder = KeyGenParameterSpec.Builder(
            alias,
            KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY,
        )
            .setAlgorithmParameterSpec(ECGenParameterSpec("secp256r1"))
            .setDigests(KeyProperties.DIGEST_SHA256)
            .setAttestationChallenge(challenge)
            .setUserAuthenticationRequired(false)

        if (strongBox) {
            builder.setIsStrongBoxBacked(true)
        }

        val generator = KeyPairGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_EC,
            keyStoreName,
        )
        generator.initialize(builder.build())
        return generator.generateKeyPair()
    }

    private fun sign(alias: String, data: ByteArray): String {
        val keyStore = loadKeyStore()
        val entry = keyStore.getEntry(alias, null) as? KeyStore.PrivateKeyEntry
            ?: throw IllegalStateException(
                "No Android Keystore private key exists for this device.",
            )
        val signature = Signature.getInstance("SHA256withECDSA")
        signature.initSign(entry.privateKey)
        signature.update(data)
        return encodeBase64Url(signature.sign())
    }

    private fun hasKey(alias: String): Boolean = loadKeyStore().containsAlias(alias)

    private fun deleteKey(alias: String) {
        deleteAliasQuietly(loadKeyStore(), alias)
    }

    private fun loadKeyStore(): KeyStore {
        return KeyStore.getInstance(keyStoreName).apply { load(null) }
    }

    private fun deleteAliasQuietly(keyStore: KeyStore, alias: String) {
        try {
            if (keyStore.containsAlias(alias)) {
                keyStore.deleteEntry(alias)
            }
        } catch (_: Exception) {
            // Best-effort cleanup before regenerating or deleting a key.
        }
    }

    private fun requireArgument(call: MethodCall, name: String): String {
        return call.argument<String>(name)
            ?: throw IllegalArgumentException("Missing argument: $name")
    }

    private fun decodeBase64Url(value: String): ByteArray {
        return Base64.decode(
            value,
            Base64.URL_SAFE or Base64.NO_WRAP or Base64.NO_PADDING,
        )
    }

    private fun encodeBase64Url(value: ByteArray): String {
        return Base64.encodeToString(
            value,
            Base64.URL_SAFE or Base64.NO_WRAP or Base64.NO_PADDING,
        )
    }

    private fun publicKeyPem(keyPair: KeyPair): String {
        return pem("PUBLIC KEY", keyPair.public.encoded)
    }

    private fun certificatePem(encoded: ByteArray): String {
        return pem("CERTIFICATE", encoded)
    }

    private fun pem(label: String, der: ByteArray): String {
        val body = Base64.encodeToString(der, Base64.NO_WRAP)
            .chunked(64)
            .joinToString("\n")
        return "-----BEGIN $label-----\n$body\n-----END $label-----"
    }
}
