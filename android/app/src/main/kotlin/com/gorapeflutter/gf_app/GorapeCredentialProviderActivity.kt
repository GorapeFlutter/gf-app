package com.gorapeflutter.gf_app

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.hardware.biometrics.BiometricPrompt
import android.os.Build
import android.os.Bundle
import android.os.CancellationSignal
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyInfo
import android.security.keystore.KeyProperties
import android.util.Base64
import androidx.credentials.CreatePublicKeyCredentialRequest
import androidx.credentials.CreatePublicKeyCredentialResponse
import androidx.credentials.GetCredentialResponse
import androidx.credentials.GetPublicKeyCredentialOption
import androidx.credentials.PublicKeyCredential
import androidx.credentials.exceptions.CreateCredentialUnknownException
import androidx.credentials.exceptions.GetCredentialUnknownException
import androidx.credentials.provider.CallingAppInfo
import androidx.credentials.provider.PendingIntentHandler
import java.io.ByteArrayOutputStream
import java.math.BigInteger
import java.security.KeyFactory
import java.security.KeyPair
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.MessageDigest
import java.security.Signature
import java.security.interfaces.ECPublicKey
import java.security.spec.ECGenParameterSpec
import java.util.UUID
import org.json.JSONArray
import org.json.JSONObject

/** Android Credential Provider POC; private keys are generated and retained in Keystore. */
class GorapeCredentialProviderActivity : Activity() {
    // GF-01207 — Dispatches Credential Manager create/get callbacks.
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            finishWithError("GF Passkeys requires Android 14 or newer.")
            return
        }
        when (intent.action) {
            ACTION_CREATE -> createPasskey()
            ACTION_GET -> getPasskey()
            else -> finish()
        }
    }

    // GF-01208 — Creates a Gorape RP credential and its Android Key attestation.
    private fun createPasskey() {
        val provider = PendingIntentHandler.retrieveProviderCreateCredentialRequest(intent)
        val request = provider?.callingRequest as? CreatePublicKeyCredentialRequest
        if (provider == null || request == null) {
            finishCreateError("Credential Manager did not provide a public-key create request.")
            return
        }
        val options = runCatching { JSONObject(request.requestJson) }.getOrElse {
            finishCreateError("Invalid WebAuthn create options.")
            return
        }
        val rp = options.optJSONObject("rp")
        val user = options.optJSONObject("user")
        val challenge = options.optString("challenge")
        if (rp?.optString("id") != GorapePasskeyProvider.RP_ID || user == null || challenge.isBlank()) {
            finishCreateError("GF Passkeys only accepts the configured Gorape RP.")
            return
        }
        if (!supportsEs256(options.optJSONArray("pubKeyCredParams"))) {
            finishCreateError("The WebAuthn request did not offer ES256.")
            return
        }
        val origin = resolveOrigin(provider.callingAppInfo)
        if (origin == null || !originAllowed(origin)) {
            finishCreateError("The calling application or Web origin is not trusted.")
            return
        }
        val clientData = makeClientData("webauthn.create", challenge, origin, provider.callingAppInfo.packageName)
        val clientDataHash = checkedClientDataHash(clientData, request.clientDataHash)
        if (clientDataHash == null) {
            finishCreateError("Credential Provider clientDataHash did not match the serialized client data.")
            return
        }
        val userHandle = runCatching { GorapePasskeyProvider.decodeBase64Url(user.getString("id")) }.getOrNull()
        if (userHandle == null || userHandle.isEmpty() || userHandle.size > 64) {
            finishCreateError("WebAuthn user handle must be 1 to 64 bytes.")
            return
        }
        val credentialId = ByteArray(32).also(java.security.SecureRandom()::nextBytes)
        val keyAlias = "gf-passkey-${UUID.randomUUID()}"
        val generated = runCatching { generateAttestedKey(keyAlias, clientDataHash) }.getOrElse {
            finishCreateError(it.message ?: "Android hardware key generation failed.")
            return
        }
        val coseKey = runCatching { encodeCoseEc2(generated.keyPair.public as ECPublicKey) }.getOrElse {
            deleteKey(keyAlias)
            finishCreateError("Could not encode the P-256 public key.")
            return
        }
        val authData = buildAuthenticatorData(
            GorapePasskeyProvider.RP_ID, FLAG_UP or FLAG_UV or FLAG_AT, 0,
            ByteArray(16), credentialId, coseKey,
        )
        val signature = runCatching {
            Signature.getInstance("SHA256withECDSA").apply { initSign(generated.keyPair.private) }
        }.getOrElse {
            deleteKey(keyAlias)
            finishCreateError("Android Keystore could not initialize the attestation signature.")
            return
        }
        authenticateAndSign(signature, "Create a Gorape device-bound passkey") { authorizedSignature ->
            val attestationSignature = runCatching {
                authorizedSignature.update(authData + clientDataHash)
                authorizedSignature.sign()
            }.getOrElse {
                deleteKey(keyAlias)
                finishCreateError("Android Keystore could not sign the attestation statement.")
                return@authenticateAndSign
            }
            val attestationObject = makeAttestationObject(authData, attestationSignature, generated.chain)
            val id = GorapePasskeyProvider.encodeBase64Url(credentialId)
            val name = user.optString("name").ifBlank {
                userHandle.joinToString("") { byte -> "%02x".format(byte) }
            }
            val displayName = user.optString("displayName").ifBlank { name }
            GorapePasskeyStore(this).insert(
                GorapePasskeyRecord(
                    credentialId = id,
                    rpId = GorapePasskeyProvider.RP_ID,
                    userHandle = GorapePasskeyProvider.encodeBase64Url(userHandle),
                    userName = name,
                    displayName = displayName,
                    keyAlias = keyAlias,
                    signCount = 0,
                ),
            )
            val response = JSONObject()
                .put("clientDataJSON", GorapePasskeyProvider.encodeBase64Url(clientData))
                .put("attestationObject", GorapePasskeyProvider.encodeBase64Url(attestationObject))
                // Hybrid is not reported until the Android CDA test proves it.
                .put("transports", JSONArray().put("internal"))
            val credential = JSONObject()
                .put("id", id)
                .put("rawId", id)
                .put("type", "public-key")
                .put("authenticatorAttachment", "platform")
                .put("response", response)
                .put("clientExtensionResults", JSONObject())
            finishCreateResponse(CreatePublicKeyCredentialResponse(credential.toString()))
        }
    }

    // GF-01209 — Signs a Gorape RP assertion with the Keystore private key.
    private fun getPasskey() {
        val provider = PendingIntentHandler.retrieveProviderGetCredentialRequest(intent)
        val option = provider?.credentialOptions?.filterIsInstance<GetPublicKeyCredentialOption>()?.firstOrNull()
        val credentialId = intent.getStringExtra(GorapeCredentialProviderActivity.EXTRA_CREDENTIAL_ID)
        if (provider == null || option == null || credentialId.isNullOrBlank()) {
            finishGetError("Credential Manager did not provide a public-key get request.")
            return
        }
        val options = runCatching { JSONObject(option.requestJson) }.getOrElse {
            finishGetError("Invalid WebAuthn get options.")
            return
        }
        if (options.optString("rpId") != GorapePasskeyProvider.RP_ID) {
            finishGetError("GF Passkeys only accepts the configured Gorape RP.")
            return
        }
        val record = GorapePasskeyStore(this).find(credentialId)
        if (record == null || record.rpId != GorapePasskeyProvider.RP_ID) {
            finishGetError("The selected local passkey is no longer available.")
            return
        }
        val origin = resolveOrigin(provider.callingAppInfo)
        if (origin == null || !originAllowed(origin)) {
            finishGetError("The calling application or Web origin is not trusted.")
            return
        }
        val clientData = makeClientData("webauthn.get", options.optString("challenge"), origin, provider.callingAppInfo.packageName)
        val clientDataHash = checkedClientDataHash(clientData, option.clientDataHash)
        if (clientDataHash == null) {
            finishGetError("Credential Provider clientDataHash did not match the serialized client data.")
            return
        }
        val updated = GorapePasskeyStore(this).incrementSignCount(record.credentialId) ?: run {
            finishGetError("The selected local passkey is no longer available.")
            return
        }
        val authData = buildAuthenticatorData(updated.rpId, FLAG_UP or FLAG_UV, updated.signCount)
        val privateKey = runCatching { loadPrivateKey(updated.keyAlias) }.getOrElse {
            finishGetError("Android Keystore passkey key is unavailable.")
            return
        }
        val signature = runCatching {
            Signature.getInstance("SHA256withECDSA").apply { initSign(privateKey) }
        }.getOrElse {
            finishGetError("Android Keystore could not initialize the assertion signature.")
            return
        }
        authenticateAndSign(signature, "Use your Gorape device-bound passkey") { authorizedSignature ->
            val signed = runCatching {
                authorizedSignature.update(authData + clientDataHash)
                authorizedSignature.sign()
            }.getOrElse {
                finishGetError("Android Keystore could not sign the assertion.")
                return@authenticateAndSign
            }
            val response = JSONObject()
                .put("clientDataJSON", GorapePasskeyProvider.encodeBase64Url(clientData))
                .put("authenticatorData", GorapePasskeyProvider.encodeBase64Url(authData))
                .put("signature", GorapePasskeyProvider.encodeBase64Url(signed))
                .put("userHandle", updated.userHandle)
            val credential = JSONObject()
                .put("id", updated.credentialId)
                .put("rawId", updated.credentialId)
                .put("type", "public-key")
                .put("authenticatorAttachment", "platform")
                .put("response", response)
                .put("clientExtensionResults", JSONObject())
            finishGetResponse(GetCredentialResponse(PublicKeyCredential(credential.toString())))
        }
    }

    companion object {
        const val ACTION_CREATE = "com.gorapeflutter.gf_app.CREDENTIAL_CREATE"
        const val ACTION_GET = "com.gorapeflutter.gf_app.CREDENTIAL_GET"
        const val EXTRA_CREDENTIAL_ID = "credential_id"
        private const val ANDROID_KEYSTORE = "AndroidKeyStore"
        private const val FLAG_UP = 0x01
        private const val FLAG_UV = 0x04
        private const val FLAG_AT = 0x40
        private const val COSE_ES256 = -7
        private const val BIOMETRIC_AUTHENTICATORS = android.hardware.biometrics.BiometricManager.Authenticators.BIOMETRIC_STRONG
        private const val PRIVILEGED_CALLERS = """{"apps":[{"type":"android","info":{"package_name":"com.android.chrome","signatures":[{"build":"release","cert_fingerprint_sha256":"F0:FD:6C:5B:41:0F:25:CB:25:C3:B5:33:46:C8:97:2F:AE:30:F8:EE:74:11:DF:91:04:80:AD:6B:2D:60:DB:83"}]}},{"type":"android","info":{"package_name":"com.google.android.gms","signatures":[{"build":"release","cert_fingerprint_sha256":"7C:E8:3C:1B:71:F3:D5:72:FE:D0:4C:8D:40:C5:CB:10:FF:75:E6:D8:7D:9D:F6:FB:D5:3F:04:68:C2:90:50:53"},{"build":"release","cert_fingerprint_sha256":"D2:2C:C5:00:29:9F:B2:28:73:A0:1A:01:0D:E1:C8:2F:BE:4D:06:11:19:B9:48:14:DD:30:1D:AB:50:CB:76:78"},{"build":"release","cert_fingerprint_sha256":"F0:FD:6C:5B:41:0F:25:CB:25:C3:B5:33:46:C8:97:2F:AE:30:F8:EE:74:11:DF:91:04:80:AD:6B:2D:60:DB:83"}]}}]}"""
    }

    private data class AttestedKey(val keyPair: KeyPair, val chain: List<java.security.cert.Certificate>)

    // GF-01210 — Requires biometric user verification before hardware signing.
    private fun authenticateAndSign(signature: Signature, title: String, complete: (Signature) -> Unit) {
        val prompt = BiometricPrompt.Builder(this)
            .setTitle(title)
            .setSubtitle("Verify with your device biometric")
            .setAllowedAuthenticators(BIOMETRIC_AUTHENTICATORS)
            .build()
        prompt.authenticate(
            BiometricPrompt.CryptoObject(signature),
            CancellationSignal(),
            mainExecutor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    super.onAuthenticationError(errorCode, errString)
                    finishWithError("User verification failed: $errString")
                }

                override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                    super.onAuthenticationSucceeded(result)
                    val authenticatedSignature = result.cryptoObject?.signature
                    if (authenticatedSignature == null) {
                        finishWithError("The hardware signing operation was not authorized.")
                    } else {
                        complete(authenticatedSignature)
                    }
                }
            },
        )
    }

    // GF-01211 — Prefers StrongBox and falls back to hardware TEE.
    private fun generateAttestedKey(alias: String, challenge: ByteArray): AttestedKey {
        val keyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
        val hasStrongBox = Build.VERSION.SDK_INT >= Build.VERSION_CODES.P &&
            packageManager.hasSystemFeature("android.hardware.strongbox_keystore")
        if (hasStrongBox) {
            val strongBoxPair = runCatching { generateKeyPair(alias, challenge, true) }.getOrNull()
            if (strongBoxPair != null) {
                val strongBoxResult = runCatching { validateGeneratedKey(keyStore, alias, strongBoxPair) }
                if (strongBoxResult.isSuccess) return strongBoxResult.getOrThrow()
                runCatching { keyStore.deleteEntry(alias) }
            }
        }
        val teePair = generateKeyPair(alias, challenge, false)
        return validateGeneratedKey(keyStore, alias, teePair)
    }

    // GF-01212 — Generates an attested P-256 signing key in Android Keystore.
    private fun generateKeyPair(alias: String, challenge: ByteArray, strongBox: Boolean): KeyPair {
        val spec = KeyGenParameterSpec.Builder(
            alias,
            KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY,
        )
            .setAlgorithmParameterSpec(ECGenParameterSpec("secp256r1"))
            .setDigests(KeyProperties.DIGEST_SHA256)
            .setAttestationChallenge(challenge)
            .setUserAuthenticationRequired(true)
            .setUserAuthenticationParameters(0, BIOMETRIC_AUTHENTICATORS)
        if (strongBox) spec.setIsStrongBoxBacked(true)
        return KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_EC, ANDROID_KEYSTORE)
            .apply { initialize(spec.build()) }
            .generateKeyPair()
    }

    // GF-01213 — Rejects software keys or missing Android attestation chains.
    private fun validateGeneratedKey(store: KeyStore, alias: String, pair: KeyPair): AttestedKey {
        val entry = store.getEntry(alias, null) as? KeyStore.PrivateKeyEntry
            ?: throw IllegalStateException("Android Keystore did not retain the private key.")
        val keyInfo = KeyFactory.getInstance(entry.privateKey.algorithm, ANDROID_KEYSTORE)
            .getKeySpec(entry.privateKey, KeyInfo::class.java)
        if (!keyInfo.isInsideSecureHardware) {
            store.deleteEntry(alias)
            throw IllegalStateException("Software-backed passkeys are not permitted.")
        }
        val chain = store.getCertificateChain(alias)?.toList().orEmpty()
        if (chain.size < 2) {
            store.deleteEntry(alias)
            throw IllegalStateException("Android Key Attestation returned no certificate chain.")
        }
        return AttestedKey(pair, chain)
    }

    // GF-01214 — Loads the non-exportable private key by Keystore alias.
    private fun loadPrivateKey(alias: String): java.security.PrivateKey {
        val store = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
        return (store.getEntry(alias, null) as? KeyStore.PrivateKeyEntry)?.privateKey
            ?: throw IllegalStateException("Android Keystore private key is unavailable.")
    }

    // GF-01215 — Deletes a failed or revoked local Keystore key.
    private fun deleteKey(alias: String) {
        runCatching { KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }.deleteEntry(alias) }
    }

    // GF-01216 — Serializes WebAuthn client data for the calling RP origin.
    private fun makeClientData(type: String, challenge: String, origin: String, packageName: String): ByteArray {
        val data = JSONObject()
            .put("type", type)
            .put("challenge", challenge)
            .put("origin", origin)
        if (origin.startsWith("android:apk-key-hash:")) data.put("androidPackageName", packageName)
        else data.put("crossOrigin", false)
        return data.toString().toByteArray(Charsets.UTF_8)
    }

    // GF-01217 — Checks that Credential Manager supplied the matching client-data hash.
    private fun checkedClientDataHash(clientData: ByteArray, supplied: ByteArray?): ByteArray? {
        val computed = MessageDigest.getInstance("SHA-256").digest(clientData)
        if (supplied != null && !MessageDigest.isEqual(supplied, computed)) return null
        return supplied ?: computed
    }

    // GF-01218 — Resolves the verified Android application or web origin.
    private fun resolveOrigin(info: CallingAppInfo): String? {
        if (info.packageName == packageName) {
            val signingInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES).signingInfo
            } else null
            val signer = signingInfo?.apkContentsSigners?.firstOrNull()?.toByteArray() ?: return null
            val hash = MessageDigest.getInstance("SHA-256").digest(signer)
            return "android:apk-key-hash:${Base64.encodeToString(hash, Base64.URL_SAFE or Base64.NO_WRAP or Base64.NO_PADDING)}"
        }
        return runCatching { info.getOrigin(PRIVILEGED_CALLERS) }.getOrNull()
    }

    // GF-01219 — Restricts requests to the configured Gorape RP origins.
    private fun originAllowed(origin: String): Boolean {
        if (origin.startsWith("android:apk-key-hash:")) return true
        val uri = runCatching { android.net.Uri.parse(origin) }.getOrNull() ?: return false
        val host = uri.host?.lowercase() ?: return false
        return uri.scheme == "https" && (host == GorapePasskeyProvider.RP_ID || host.endsWith(".${GorapePasskeyProvider.RP_ID}"))
    }

    // GF-01220 — Confirms that the RP offered the supported ES256 algorithm.
    private fun supportsEs256(params: JSONArray?): Boolean {
        if (params == null) return false
        return (0 until params.length()).any { index ->
            val item = params.optJSONObject(index)
            item?.optString("type") == "public-key" && item.optInt("alg") == -7
        }
    }

    // GF-01221 — Encodes RP hash, UV flags, counter, and attested credential data.
    private fun buildAuthenticatorData(
        rpId: String,
        flags: Int,
        signCount: Long,
        aaguid: ByteArray? = null,
        credentialId: ByteArray? = null,
        credentialPublicKey: ByteArray? = null,
    ): ByteArray {
        val output = ByteArrayOutputStream()
        output.write(MessageDigest.getInstance("SHA-256").digest(rpId.toByteArray(Charsets.UTF_8)))
        output.write(flags)
        output.write(byteArrayOf((signCount ushr 24).toByte(), (signCount ushr 16).toByte(), (signCount ushr 8).toByte(), signCount.toByte()))
        if (flags and FLAG_AT != 0) {
            val id = requireNotNull(credentialId)
            val guid = requireNotNull(aaguid)
            require(guid.size == 16 && id.size <= 0xffff)
            output.write(guid)
            output.write(byteArrayOf((id.size ushr 8).toByte(), id.size.toByte()))
            output.write(id)
            output.write(requireNotNull(credentialPublicKey))
        }
        return output.toByteArray()
    }

    // GF-01222 — Encodes the P-256 credential public key as COSE EC2.
    private fun encodeCoseEc2(key: ECPublicKey): ByteArray = WebAuthnCbor.encode(
        linkedMapOf<Any, Any>(
            1 to 2,
            3 to COSE_ES256,
            -1 to 1,
            -2 to key.w.affineX.toFixedBytes(32),
            -3 to key.w.affineY.toFixedBytes(32),
        ),
    )

    // GF-01223 — Builds an android-key attestation object with the x5c chain.
    private fun makeAttestationObject(
        authData: ByteArray,
        signature: ByteArray,
        chain: List<java.security.cert.Certificate>,
    ): ByteArray = WebAuthnCbor.encode(
        linkedMapOf(
            "fmt" to "android-key",
            "attStmt" to linkedMapOf(
                "alg" to COSE_ES256,
                "sig" to signature,
                "x5c" to chain.map { it.encoded },
            ),
            "authData" to authData,
        ),
    )

    // GF-01224 — Serializes an EC coordinate to its fixed-width representation.
    private fun BigInteger.toFixedBytes(length: Int): ByteArray {
        val raw = toByteArray().let { if (it.size > length && it[0] == 0.toByte()) it.copyOfRange(1, it.size) else it }
        require(raw.size <= length)
        return ByteArray(length - raw.size) + raw
    }

    // GF-01225 — Returns the completed create response to Credential Manager.
    private fun finishCreateResponse(response: CreatePublicKeyCredentialResponse) {
        val data = Intent()
        PendingIntentHandler.setCreateCredentialResponse(data, response)
        setResult(RESULT_OK, data)
        finish()
    }

    // GF-01226 — Returns the completed assertion response to Credential Manager.
    private fun finishGetResponse(response: GetCredentialResponse) {
        val data = Intent()
        PendingIntentHandler.setGetCredentialResponse(data, response)
        setResult(RESULT_OK, data)
        finish()
    }

    // GF-01227 — Returns a create-ceremony error to Credential Manager.
    private fun finishCreateError(message: String) = finishWithError(message, ACTION_CREATE)

    // GF-01228 — Returns a get-ceremony error to Credential Manager.
    private fun finishGetError(message: String) = finishWithError(message, ACTION_GET)

    // GF-01229 — Serializes a typed Credential Manager exception response.
    private fun finishWithError(message: String, action: String = intent.action ?: ACTION_GET) {
        val data = Intent()
        if (action == ACTION_CREATE) {
            PendingIntentHandler.setCreateCredentialException(data, CreateCredentialUnknownException(message))
        } else {
            PendingIntentHandler.setGetCredentialException(data, GetCredentialUnknownException(message))
        }
        setResult(RESULT_OK, data)
        finish()
    }
}
