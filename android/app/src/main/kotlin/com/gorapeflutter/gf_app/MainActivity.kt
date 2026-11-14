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
 * GF-00005 creates attested keys; GF-00006 signs server challenges.
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

    // GF-01139 — Installs the Flutter-to-Keystore method channel.
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler /* GF-01155 — Handles a native method-channel call. */ { call, result ->
                executor.execute /* GF-01156 — Runs Keystore work off the UI thread. */ {
                    val outcome = runCatching /* GF-01160 — Captures native operation success or failure. */ { dispatch(call) }
                    mainHandler.post /* GF-01157 — Returns the result on the UI thread. */ {
                        outcome.fold(
                            /* GF-01158 — Delivers a successful native result. */ { value -> result.success(value) },
                            /* GF-01159 — Converts native failures into channel errors. */ { error ->
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

    // GF-01140 — Routes method-channel commands to the matching Keystore operation.
    private fun dispatch(call: MethodCall): Any? {
        // GF-02082 — Select the operation and validate its required arguments.
        return when (call.method) {
            "availability" -> availability()
            "generateKey" -> {
                // GF-02083 — Decode the registration challenge before key creation.
                val alias = requireArgument(call, "keyIdentifier")
                val challenge = decodeBase64Url(requireArgument(call, "challenge"))
                generateKey(alias, challenge)
            }
            "sign" -> {
                // GF-02084 — Decode proof bytes before asking Keystore to sign.
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

    // GF-01141 — Reports Android Keystore and hardware-attestation capabilities.
    private fun availability(): Map<String, Any?> {
        // GF-02085 — Detect StrongBox and hardware-backed Keystore availability.
        val hasStrongBox = Build.VERSION.SDK_INT >= Build.VERSION_CODES.P &&
            packageManager.hasSystemFeature(strongBoxKeystoreFeature)
        val hardwareBacked = packageManager.hasSystemFeature(hardwareKeystoreFeature)
        // GF-02086 — Return the supported status and effective security level.
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

    // GF-01142 — Creates an attested EC key and returns its public evidence.
    private fun generateKey(alias: String, challenge: ByteArray): Map<String, Any?> {
        // GF-02087 — Remove a stale alias before generating a replacement key.
        val keyStore = loadKeyStore()
        deleteAliasQuietly(keyStore, alias)

        val strongBoxRequested = Build.VERSION.SDK_INT >= Build.VERSION_CODES.P &&
            packageManager.hasSystemFeature(strongBoxKeystoreFeature)

        // GF-02088 — Prefer StrongBox and fall back to the device TEE if needed.
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

        // GF-02089 — Require a certificate chain from Android Key Attestation.
        val keyPair = generated.first
        val chain = keyStore.getCertificateChain(alias)
        if (chain.isNullOrEmpty()) {
            deleteAliasQuietly(keyStore, alias)
            throw IllegalStateException(
                "Android Key Attestation did not return a certificate chain. " +
                    "Use a device with a hardware-backed Keystore.",
            )
        }

        // GF-02090 — Package the public key, evidence chain, and security level.
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

    // GF-01143 — Configures and generates an EC P-256 Keystore key pair.
    private fun generateKeyPair(
        alias: String,
        challenge: ByteArray,
        strongBox: Boolean,
    ): KeyPair {
        // GF-02091 — Bind signing, SHA-256, and the server challenge to the key.
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

        // GF-02092 — Generate the key pair inside Android Keystore.
        val generator = KeyPairGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_EC,
            keyStoreName,
        )
        generator.initialize(builder.build())
        return generator.generateKeyPair()
    }

    // GF-01144 — Signs challenge bytes without exporting the private key.
    private fun sign(alias: String, data: ByteArray): String {
        // GF-02093 — Load the private-key entry by its local Keystore alias.
        val keyStore = loadKeyStore()
        val entry = keyStore.getEntry(alias, null) as? KeyStore.PrivateKeyEntry
            ?: throw IllegalStateException(
                "No Android Keystore private key exists for this device.",
            )
        // GF-02094 — Sign the raw challenge using SHA256withECDSA.
        val signature = Signature.getInstance("SHA256withECDSA")
        signature.initSign(entry.privateKey)
        signature.update(data)
        // GF-02095 — Return the ASN.1/DER signature as unpadded Base64url.
        return encodeBase64Url(signature.sign())
    }

    // GF-01145 — Checks whether the requested Keystore alias exists.
    private fun hasKey(alias: String): Boolean = loadKeyStore().containsAlias(alias)

    // GF-01146 — Deletes the requested Keystore alias.
    private fun deleteKey(alias: String) {
        deleteAliasQuietly(loadKeyStore(), alias)
    }

    // GF-01147 — Opens the Android Keystore provider.
    private fun loadKeyStore(): KeyStore {
        return KeyStore.getInstance(keyStoreName).apply { load(null) }
    }

    // GF-01148 — Removes an alias while tolerating best-effort cleanup failures.
    private fun deleteAliasQuietly(keyStore: KeyStore, alias: String) {
        try {
            if (keyStore.containsAlias(alias)) {
                keyStore.deleteEntry(alias)
            }
        } catch (_: Exception) {
            // Best-effort cleanup before regenerating or deleting a key.
        }
    }

    // GF-01149 — Reads a required string argument from a method-channel call.
    private fun requireArgument(call: MethodCall, name: String): String {
        return call.argument<String>(name)
            ?: throw IllegalArgumentException("Missing argument: $name")
    }

    // GF-01150 — Decodes unpadded Base64url input into raw bytes.
    private fun decodeBase64Url(value: String): ByteArray {
        return Base64.decode(
            value,
            Base64.URL_SAFE or Base64.NO_WRAP or Base64.NO_PADDING,
        )
    }

    // GF-01151 — Encodes bytes as unpadded Base64url.
    private fun encodeBase64Url(value: ByteArray): String {
        return Base64.encodeToString(
            value,
            Base64.URL_SAFE or Base64.NO_WRAP or Base64.NO_PADDING,
        )
    }

    // GF-01152 — Serializes a public key using the PEM envelope.
    private fun publicKeyPem(keyPair: KeyPair): String {
        return pem("PUBLIC KEY", keyPair.public.encoded)
    }

    // GF-01153 — Serializes one attestation certificate using the PEM envelope.
    private fun certificatePem(encoded: ByteArray): String {
        return pem("CERTIFICATE", encoded)
    }

    // GF-01154 — Wraps DER bytes in a 64-column PEM document.
    private fun pem(label: String, der: ByteArray): String {
        val body = Base64.encodeToString(der, Base64.NO_WRAP)
            .chunked(64)
            .joinToString("\n")
        return "-----BEGIN $label-----\n$body\n-----END $label-----"
    }
}
