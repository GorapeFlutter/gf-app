package com.gorapeflutter.gf_app.driver.webauthn

import android.app.Activity
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.util.Base64
import androidx.credentials.provider.CallingAppInfo
import com.gorapeflutter.gf_app.entity.credential.GorapePasskeyConfiguration
import com.gorapeflutter.gf_app.entity.webauthn.AttestedCredentialData
import com.gorapeflutter.gf_app.entity.webauthn.WebAuthnAuthenticatorDataInput
import com.gorapeflutter.gf_app.entity.webauthn.WebAuthnAttestationInput
import com.gorapeflutter.gf_app.entity.webauthn.WebAuthnClientDataInput
import java.io.ByteArrayOutputStream
import java.math.BigInteger
import java.security.MessageDigest
import java.security.interfaces.ECPublicKey
import org.json.JSONArray
import org.json.JSONObject

/** WebAuthn origin, client-data, and authenticator-data utilities. */
    // GF-01274 — Create the WebAuthn Driver for origin and credential-data operations.
internal class WebAuthnCredentialDriver(private val activity: Activity) {
    // GF-01216 — W3C WebAuthn Level 3: serialize clientDataJSON for the RP origin.
    fun makeClientData(input: WebAuthnClientDataInput): ByteArray {
        val data = JSONObject()
            .put("type", input.type)
            .put("challenge", input.challenge)
            .put("origin", input.origin)
        addOriginMetadata(data, input)
        return data.toString().toByteArray(Charsets.UTF_8)
    }

    // GF-01273 — Add Android package name or Web cross-origin metadata to client data.
    private fun addOriginMetadata(data: JSONObject, input: WebAuthnClientDataInput) {
        if (input.origin.startsWith(ANDROID_ORIGIN_PREFIX)) {
            data.put("androidPackageName", input.packageName)
        } else {
            data.put("crossOrigin", false)
        }
    }

    // GF-01217 — Checks that Credential Manager supplied the matching client-data hash.
    fun checkedClientDataHash(clientData: ByteArray, suppliedHash: ByteArray?): ByteArray? {
        val computedHash = MessageDigest.getInstance(SHA_256).digest(clientData)
        if (suppliedHash != null && !MessageDigest.isEqual(suppliedHash, computedHash)) {
            return null
        }
        return suppliedHash ?: computedHash
    }

    // GF-01218 — Resolves the verified Android application or web origin.
    fun resolveOrigin(info: CallingAppInfo): String? {
        if (info.packageName == activity.packageName) {
            return resolveOwnAppOrigin()
        }
        return try {
            info.getOrigin(PRIVILEGED_CALLERS)
        } catch (_: Exception) {
            null
        }
    }

    // GF-01272 — Compute the Android APK signing-certificate hash origin.
    private fun resolveOwnAppOrigin(): String? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
            return null
        }
        val packageInfo = activity.packageManager.getPackageInfo(
            activity.packageName,
            PackageManager.GET_SIGNING_CERTIFICATES,
        )
        val signer = packageInfo.signingInfo?.apkContentsSigners?.firstOrNull()?.toByteArray()
            ?: return null
        val hash = MessageDigest.getInstance(SHA_256).digest(signer)
        return ANDROID_ORIGIN_PREFIX + Base64.encodeToString(
            hash,
            Base64.URL_SAFE or Base64.NO_WRAP or Base64.NO_PADDING,
        )
    }

    // GF-01219 — W3C WebAuthn Level 3: enforce exact RP-origin matching.
    fun originAllowed(origin: String): Boolean {
        if (origin.startsWith(ANDROID_ORIGIN_PREFIX)) {
            return true
        }
        val uri = Uri.parse(origin)
        val host = uri.host?.lowercase() ?: return false
        if (uri.scheme != "https") {
            return false
        }
        val rpId = GorapePasskeyConfiguration.RP_ID
        return host == rpId || host.endsWith(".$rpId")
    }

    // GF-01220 — W3C WebAuthn Level 3: require the supported ES256 public-key algorithm.
    fun supportsEs256(params: JSONArray?): Boolean {
        if (params == null) {
            return false
        }
        for (index in 0 until params.length()) {
            val item = params.optJSONObject(index) ?: continue
            if (item.optString("type") == PUBLIC_KEY_TYPE && item.optInt("alg") == COSE_ES256) {
                return true
            }
        }
        return false
    }

    // GF-01221 — W3C WebAuthn Level 3 §6.1: encode RP hash, flags, counter, and credential data.
    fun buildAuthenticatorData(input: WebAuthnAuthenticatorDataInput): ByteArray {
        val output = ByteArrayOutputStream()
        writeRpIdHash(output, input.rpId)
        output.write(input.flags)
        writeSignCount(output, input.signCount)
        if (input.flags and FLAG_AT != 0) {
            val attestedCredential = input.attestedCredential
            if (attestedCredential == null) {
                throw IllegalArgumentException("Attested authenticator data requires credential data.")
            }
            writeAttestedCredentialData(output, attestedCredential)
        }
        return output.toByteArray()
    }

    // GF-01271 — Write the SHA-256 RP ID hash required by WebAuthn authenticator data.
    private fun writeRpIdHash(output: ByteArrayOutputStream, rpId: String) {
        val rpIdHash = MessageDigest.getInstance(SHA_256).digest(rpId.toByteArray(Charsets.UTF_8))
        output.write(rpIdHash)
    }

    // GF-01270 — Write the authenticator signature counter as a 32-bit big-endian value.
    private fun writeSignCount(output: ByteArrayOutputStream, signCount: Long) {
        output.write(
            byteArrayOf(
                (signCount ushr 24).toByte(),
                (signCount ushr 16).toByte(),
                (signCount ushr 8).toByte(),
                signCount.toByte(),
            ),
        )
    }

    // GF-01269 — Encode the AAGUID, credential ID, and COSE key per WebAuthn.
    private fun writeAttestedCredentialData(output: ByteArrayOutputStream, data: AttestedCredentialData) {
        require(data.aaguid.size == AAGUID_LENGTH && data.credentialId.size <= MAX_CREDENTIAL_ID_LENGTH)
        output.write(data.aaguid)
        output.write((data.credentialId.size ushr 8) and BYTE_MASK)
        output.write(data.credentialId.size and BYTE_MASK)
        output.write(data.credentialId)
        output.write(data.credentialPublicKey)
    }

    // GF-01222 — RFC 9052/9053: encode the P-256 public key as a COSE EC2 key.
    fun encodeCoseEc2(key: ECPublicKey): ByteArray {
        val coseKey = linkedMapOf<Any, Any>(
            1 to COSE_KEY_TYPE_EC2,
            3 to COSE_ES256,
            -1 to COSE_CURVE_P256,
            -2 to toFixedBytes(key.w.affineX, COORDINATE_LENGTH),
            -3 to toFixedBytes(key.w.affineY, COORDINATE_LENGTH),
        )
        return WebAuthnCbor.encode(coseKey)
    }

    // GF-01223 — W3C WebAuthn Level 3: build the android-key attestation object and x5c chain.
    fun makeAttestationObject(input: WebAuthnAttestationInput): ByteArray {
        val encodedCertificates = ArrayList<ByteArray>(input.certificateChain.size)
        for (certificate in input.certificateChain) {
            encodedCertificates.add(certificate.encoded)
        }
        val attestationStatement = linkedMapOf<String, Any>(
            "alg" to COSE_ES256,
            "sig" to input.signature,
            "x5c" to encodedCertificates,
        )
        val attestationObject = linkedMapOf<String, Any>(
            "fmt" to ANDROID_KEY_FORMAT,
            "attStmt" to attestationStatement,
            "authData" to input.authenticatorData,
        )
        return WebAuthnCbor.encode(attestationObject)
    }

    // GF-01224 — Serializes an EC coordinate to its fixed-width representation.
    private fun toFixedBytes(value: BigInteger, length: Int): ByteArray {
        val encoded = value.toByteArray()
        val raw = removeSignPadding(encoded, length)
        require(raw.size <= length)
        val result = ByteArray(length)
        System.arraycopy(raw, 0, result, length - raw.size, raw.size)
        return result
    }

    // GF-01268 — Remove a positive EC-coordinate sign byte before fixed-width encoding.
    private fun removeSignPadding(value: ByteArray, length: Int): ByteArray {
        if (value.size == length + 1 && value[0] == 0.toByte()) {
            return value.copyOfRange(1, value.size)
        }
        return value
    }

    private companion object {
        const val SHA_256 = "SHA-256"
        const val ANDROID_ORIGIN_PREFIX = "android:apk-key-hash:"
        const val PUBLIC_KEY_TYPE = "public-key"
        const val ANDROID_KEY_FORMAT = "android-key"
        const val COSE_ES256 = -7
        const val COSE_KEY_TYPE_EC2 = 2
        const val COSE_CURVE_P256 = 1
        const val FLAG_AT = 0x40
        const val AAGUID_LENGTH = 16
        const val MAX_CREDENTIAL_ID_LENGTH = 0xffff
        const val COORDINATE_LENGTH = 32
        const val BYTE_MASK = 0xff
        val PRIVILEGED_CALLERS = """
            {
              "apps": [
                {
                  "type": "android",
                  "info": {
                    "package_name": "com.android.chrome",
                    "signatures": [
                      {
                        "build": "release",
                        "cert_fingerprint_sha256":
                      "F0:FD:6C:5B:41:0F:25:CB:25:C3:B5:33:46:C8:97:2F:AE:30:F8:EE:74:11:DF:91:04:80:AD:6B:2D:60:DB:83"
                      }
                    ]
                  }
                },
                {
                  "type": "android",
                  "info": {
                    "package_name": "com.google.android.gms",
                    "signatures": [
                      {
                        "build": "release",
                        "cert_fingerprint_sha256":
                      "7C:E8:3C:1B:71:F3:D5:72:FE:D0:4C:8D:40:C5:CB:10:FF:75:E6:D8:7D:9D:F6:FB:D5:3F:04:68:C2:90:50:53"
                      },
                      {
                        "build": "release",
                        "cert_fingerprint_sha256":
                      "D2:2C:C5:00:29:9F:B2:28:73:A0:1A:01:0D:E1:C8:2F:BE:4D:06:11:19:B9:48:14:DD:30:1D:AB:50:CB:76:78"
                      },
                      {
                        "build": "release",
                        "cert_fingerprint_sha256":
                      "F0:FD:6C:5B:41:0F:25:CB:25:C3:B5:33:46:C8:97:2F:AE:30:F8:EE:74:11:DF:91:04:80:AD:6B:2D:60:DB:83"
                      }
                    ]
                  }
                }
              ]
            }
        """.trimIndent()
    }
}
