package com.gorapeflutter.gf_app.driver.devicekey

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyInfo
import android.security.keystore.KeyProperties
import android.util.Base64
import com.gorapeflutter.gf_app.entity.device.AndroidDeviceKeyAvailability
import com.gorapeflutter.gf_app.entity.device.AndroidGeneratedDeviceKey
import com.gorapeflutter.gf_app.entity.device.GeneratedAndroidKeyPair
import com.gorapeflutter.gf_app.share.Base64UrlCodec
import java.security.KeyFactory
import java.security.KeyPair
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.Signature
import java.security.spec.ECGenParameterSpec

/** Android Keystore driver used by gf-app's Flutter device-key channel. */
    // GF-01307 — Create the Android Keystore Driver for legacy device keys.
internal class AndroidDeviceKeyDriver(private val context: Context) {
    private val keyStoreProvider = "AndroidKeyStore"
    private val strongBoxFeature = "android.hardware.strongbox_keystore"
    private val hardwareKeyStoreFeature = "android.hardware.hardware_keystore"

    // GF-01141 — Reports Android Keystore and hardware-attestation capabilities.
    fun availability(): AndroidDeviceKeyAvailability {
        // GF-02085 — Detects StrongBox and hardware-backed Keystore availability.
        val hardwareBacked = context.packageManager.hasSystemFeature(hardwareKeyStoreFeature)
        val strongBoxAvailable = isStrongBoxAvailable()
        val supported = android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N
        // GF-02086 — Returns support status and the effective security level.
        return AndroidDeviceKeyAvailability(
            supported = supported,
            hardwareBacked = hardwareBacked,
            attestationSupported = supported,
            securityLevel = securityLevel(strongBoxAvailable, hardwareBacked),
            reason = supportReason(supported),
        )
    }

    // GF-01142 — Creates an attested EC key and returns its public evidence.
    fun generateKey(alias: String, challenge: ByteArray): AndroidGeneratedDeviceKey {
        val keyStore = loadKeyStore()
        // GF-02087 — Removes a stale alias before generating its replacement.
        deleteAliasQuietly(keyStore, alias)

        // GF-02088 — Prefers StrongBox and falls back to the device TEE.
        val generated = generatePreferredKeyPair(alias, challenge, keyStore)
        val keyInfo = loadHardwareKeyInfo(keyStore, alias)
        requireHardwareBacked(keyStore, alias, keyInfo)
        // GF-02089 — Requires a certificate chain from Android Key Attestation.
        val chain = loadCertificateChain(keyStore, alias)

        // GF-02090 — Packages the public key, evidence chain, and security level.
        return AndroidGeneratedDeviceKey(
            keyIdentifier = alias,
            publicKeyPem = publicKeyPem(generated.keyPair),
            algorithm = "ES256",
            securityLevel = securityLevel(generated.strongBox, keyInfo.isInsideSecureHardware),
            certificateChain = certificateChainPem(chain),
        )
    }

    // GF-01144 — Signs challenge bytes without exporting the private key.
    fun sign(alias: String, data: ByteArray): String {
        // GF-02093 — Loads the private-key entry by its local Keystore alias.
        val entry = loadPrivateKeyEntry(alias)
        val signature = Signature.getInstance("SHA256withECDSA")
        signature.initSign(entry.privateKey)
        // GF-02094 — Signs the raw challenge using SHA256withECDSA.
        signature.update(data)
        // GF-02095 — Returns the ASN.1/DER signature as unpadded Base64url.
        return Base64UrlCodec.encode(signature.sign())
    }

    // GF-01145 — Checks whether the requested Keystore alias exists.
    fun hasKey(alias: String): Boolean = loadKeyStore().containsAlias(alias)

    // GF-01146 — Deletes the requested Keystore alias.
    fun deleteKey(alias: String) {
        deleteAliasQuietly(loadKeyStore(), alias)
    }

    // GF-01306 — Generate Preferred Key Pair.
    private fun generatePreferredKeyPair(alias: String, bytes: ByteArray, store: KeyStore): GeneratedAndroidKeyPair {
        if (!isStrongBoxAvailable()) {
            return GeneratedAndroidKeyPair(generateKeyPair(alias, bytes, false), false)
        }

        return try {
            GeneratedAndroidKeyPair(generateKeyPair(alias, bytes, true), true)
        } catch (_: Exception) {
            deleteAliasQuietly(store, alias)
            GeneratedAndroidKeyPair(generateKeyPair(alias, bytes, false), false)
        }
    }

    // GF-01143 — Configures and generates an EC P-256 Keystore key pair.
    private fun generateKeyPair(alias: String, challenge: ByteArray, strongBox: Boolean): KeyPair {
        // GF-02091 — Binds signing, SHA-256, and the server challenge to the key.
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
        val generator = KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_EC, keyStoreProvider)
        generator.initialize(builder.build())
        // GF-02092 — Generates the key pair inside Android Keystore.
        return generator.generateKeyPair()
    }

    // GF-01305 — Read Android Keystore security metadata for the generated key.
    private fun loadHardwareKeyInfo(keyStore: KeyStore, alias: String): KeyInfo {
        try {
            val entry = loadPrivateKeyEntry(keyStore, alias)
            return KeyFactory.getInstance(entry.privateKey.algorithm, keyStoreProvider)
                .getKeySpec(entry.privateKey, KeyInfo::class.java)
        } catch (error: Exception) {
            deleteAliasQuietly(keyStore, alias)
            throw error
        }
    }

    // GF-01304 — Reject device-identity keys that are not protected by secure hardware.
    private fun requireHardwareBacked(keyStore: KeyStore, alias: String, keyInfo: KeyInfo) {
        // GF-02176 — Rejects software-backed device identity keys before returning evidence.
        if (keyInfo.isInsideSecureHardware) {
            return
        }
        deleteAliasQuietly(keyStore, alias)
        throw IllegalStateException("Software-backed device identity keys are not permitted.")
    }

    // GF-01303 — Read the leaf-first Android Key Attestation certificate chain.
    private fun loadCertificateChain(keyStore: KeyStore, alias: String): List<java.security.cert.Certificate> {
        val chain = keyStore.getCertificateChain(alias)?.toList().orEmpty()
        if (chain.isNotEmpty()) {
            return chain
        }
        deleteAliasQuietly(keyStore, alias)
        throw IllegalStateException(
            "Android Key Attestation did not return a certificate chain. " +
                "Use a device with a hardware-backed Keystore.",
        )
    }

    // GF-01302 — Load the private-key entry from Android Keystore.
    private fun loadPrivateKeyEntry(alias: String): KeyStore.PrivateKeyEntry =
        loadPrivateKeyEntry(loadKeyStore(), alias)

    // GF-01301 — Load the private-key entry from Android Keystore.
    private fun loadPrivateKeyEntry(keyStore: KeyStore, alias: String): KeyStore.PrivateKeyEntry =
        keyStore.getEntry(alias, null) as? KeyStore.PrivateKeyEntry
            ?: throw IllegalStateException("No Android Keystore private key exists for this device.")

    // GF-01147 — Opens the Android Keystore provider.
    private fun loadKeyStore(): KeyStore {
        val keyStore = KeyStore.getInstance(keyStoreProvider)
        keyStore.load(null)
        return keyStore
    }

    // GF-01148 — Removes an alias while tolerating best-effort cleanup failures.
    private fun deleteAliasQuietly(keyStore: KeyStore, alias: String) {
        try {
            if (keyStore.containsAlias(alias)) {
                keyStore.deleteEntry(alias)
            }
        } catch (_: Exception) {
            // Cleanup is best-effort; the original operation reports its failure.
        }
    }

    // GF-01300 — Check whether the device advertises StrongBox support.
    private fun isStrongBoxAvailable(): Boolean {
        return android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P &&
            context.packageManager.hasSystemFeature(strongBoxFeature)
    }

    // GF-01299 — Map available hardware protection to a security-level label.
    private fun securityLevel(strongBox: Boolean, hardwareBacked: Boolean): String = when {
        strongBox -> "strongbox"
        hardwareBacked -> "trusted_environment"
        else -> "software"
    }

    // GF-01298 — Explain why the Android key-attestation feature is unavailable.
    private fun supportReason(supported: Boolean): String? {
        if (supported) {
            return null
        }
        return "Android 7.0 (API 24) or newer is required for key attestation."
    }

    // GF-01297 — Serialize the key-attestation chain as leaf-first PEM values.
    private fun certificateChainPem(chain: List<java.security.cert.Certificate>): List<String> {
        val pemCertificates = ArrayList<String>(chain.size)
        for (certificate in chain) pemCertificates.add(certificatePem(certificate.encoded))
        return pemCertificates
    }

    // GF-01152 — Serializes a public key using the PEM envelope.
    private fun publicKeyPem(keyPair: KeyPair): String = pem("PUBLIC KEY", keyPair.public.encoded)

    // GF-01153 — Serializes one attestation certificate using the PEM envelope.
    private fun certificatePem(encoded: ByteArray): String = pem("CERTIFICATE", encoded)

    // GF-01154 — Wraps DER bytes in a 64-column PEM document.
    private fun pem(label: String, der: ByteArray): String {
        val body = Base64.encodeToString(der, Base64.NO_WRAP)
        val output = StringBuilder()
        output.append("-----BEGIN ").append(label).append("-----\n")
        var start = 0
        while (start < body.length) {
            val end = minOf(start + PEM_LINE_LENGTH, body.length)
            output.append(body, start, end).append('\n')
            start = end
        }
        output.append("-----END ").append(label).append("-----")
        return output.toString()
    }

    private companion object {
        const val PEM_LINE_LENGTH = 64
    }
}
