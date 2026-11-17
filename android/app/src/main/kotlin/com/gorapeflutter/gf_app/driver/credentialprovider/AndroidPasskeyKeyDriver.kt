package com.gorapeflutter.gf_app.driver.credentialprovider

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyInfo
import android.security.keystore.KeyProperties
import com.gorapeflutter.gf_app.entity.credential.AttestedAndroidKey
import java.security.KeyFactory
import java.security.KeyPair
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.PrivateKey
import java.security.spec.ECGenParameterSpec

/** Android Keystore operations used only by the Credential Provider driver. */
    // GF-01383 — Create the Android Keystore Driver for Credential Provider passkeys.
internal class AndroidPasskeyKeyDriver(private val context: Context) {
    // GF-01211 — Android Key Attestation: prefer StrongBox and fall back to a hardware TEE.
    fun generateAttestedKey(alias: String, challenge: ByteArray): AttestedAndroidKey {
        val keyStore = loadKeyStore()
        val strongBoxPair = tryGenerateStrongBoxKey(alias, challenge, keyStore)
        if (strongBoxPair != null) {
            val attestedKey = tryValidateKey(keyStore, alias, strongBoxPair)
            if (attestedKey != null) {
                return attestedKey
            }
            deleteKey(keyStore, alias)
        }

        val teePair = generateKeyPair(alias, challenge, useStrongBox = false)
        return validateGeneratedKey(keyStore, alias, teePair)
    }

    // GF-01214 — Loads the non-exportable private key by Keystore alias.
    fun loadPrivateKey(alias: String): PrivateKey {
        val keyStore = loadKeyStore()
        val entry = keyStore.getEntry(alias, null) as? KeyStore.PrivateKeyEntry
        return entry?.privateKey
            ?: throw IllegalStateException("Android Keystore passkey key is unavailable.")
    }

    // GF-01215 — Deletes a failed or revoked local Keystore key.
    fun deleteKey(alias: String) {
        val keyStore = loadKeyStore()
        deleteKey(keyStore, alias)
    }

    // GF-01382 — Try StrongBox key generation before using the hardware TEE fallback.
    private fun tryGenerateStrongBoxKey(alias: String, challenge: ByteArray, keyStore: KeyStore): KeyPair? {
        if (!isStrongBoxAvailable()) {
            return null
        }
        return try {
            generateKeyPair(alias, challenge, useStrongBox = true)
        } catch (_: Exception) {
            deleteKey(keyStore, alias)
            null
        }
    }

    // GF-01381 — Validate the generated StrongBox key and keep fallback available.
    private fun tryValidateKey(keyStore: KeyStore, alias: String, pair: KeyPair): AttestedAndroidKey? {
        return try {
            validateGeneratedKey(keyStore, alias, pair)
        } catch (_: Exception) {
            null
        }
    }

    // GF-01212 — Android Key Attestation: generate a challenge-bound P-256 Keystore key.
    private fun generateKeyPair(alias: String, challenge: ByteArray, useStrongBox: Boolean): KeyPair {
        val spec = createKeySpec(alias, challenge, useStrongBox)
        val generator = KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_EC, ANDROID_KEYSTORE)
        generator.initialize(spec)
        return generator.generateKeyPair()
    }

    // GF-01380 — Configure P-256 signing, user verification, and Android Key Attestation.
    private fun createKeySpec(alias: String, challenge: ByteArray, useStrongBox: Boolean): KeyGenParameterSpec {
        val builder = KeyGenParameterSpec.Builder(
            alias,
            KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY,
        )
            .setAlgorithmParameterSpec(ECGenParameterSpec("secp256r1"))
            .setDigests(KeyProperties.DIGEST_SHA256)
            .setAttestationChallenge(challenge)
            .setUserAuthenticationRequired(true)
            .setUserAuthenticationParameters(
                0,
                android.hardware.biometrics.BiometricManager.Authenticators.BIOMETRIC_STRONG,
            )
        if (useStrongBox) {
            builder.setIsStrongBoxBacked(true)
        }
        return builder.build()
    }

    // GF-01213 — Android Key Attestation: reject software keys and missing certificate chains.
    private fun validateGeneratedKey(keyStore: KeyStore, alias: String, pair: KeyPair): AttestedAndroidKey {
        val entry = keyStore.getEntry(alias, null) as? KeyStore.PrivateKeyEntry
            ?: throw IllegalStateException("Android Keystore did not retain the private key.")
        val keyInfo = KeyFactory.getInstance(entry.privateKey.algorithm, ANDROID_KEYSTORE)
            .getKeySpec(entry.privateKey, KeyInfo::class.java)
        if (!keyInfo.isInsideSecureHardware) {
            deleteKey(keyStore, alias)
            throw IllegalStateException("Software-backed passkeys are not permitted.")
        }
        val chain = keyStore.getCertificateChain(alias)?.toList().orEmpty()
        if (chain.size < MIN_ATTESTATION_CHAIN_LENGTH) {
            deleteKey(keyStore, alias)
            throw IllegalStateException("Android Key Attestation returned no certificate chain.")
        }
        return AttestedAndroidKey(pair, chain)
    }

    // GF-01379 — Open the Android Keystore used by the Credential Provider.
    private fun loadKeyStore(): KeyStore {
        val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE)
        keyStore.load(null)
        return keyStore
    }

    // GF-01378 — Delete a Credential Provider key alias without masking the original error.
    private fun deleteKey(keyStore: KeyStore, alias: String) {
        try {
            if (keyStore.containsAlias(alias)) {
                keyStore.deleteEntry(alias)
            }
        } catch (_: Exception) {
            // Key cleanup should not replace the original operation failure.
        }
    }

    // GF-01377 — Check whether this device advertises StrongBox Keystore support.
    private fun isStrongBoxAvailable(): Boolean {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.P &&
            context.packageManager.hasSystemFeature(PackageManager.FEATURE_STRONGBOX_KEYSTORE)
    }

    private companion object {
        const val ANDROID_KEYSTORE = "AndroidKeyStore"
        const val MIN_ATTESTATION_CHAIN_LENGTH = 2
    }
}
