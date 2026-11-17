package com.gorapeflutter.gf_app.driver.credentialprovider

import android.app.Activity
import androidx.credentials.CreatePublicKeyCredentialRequest
import androidx.credentials.CreatePublicKeyCredentialResponse
import androidx.credentials.provider.CallingAppInfo
import androidx.credentials.provider.PendingIntentHandler
import com.gorapeflutter.gf_app.GorapeCredentialProviderActivity
import com.gorapeflutter.gf_app.entity.credential.AttestedAndroidKey
import com.gorapeflutter.gf_app.entity.credential.CredentialProviderCreateRequest
import com.gorapeflutter.gf_app.entity.credential.PasskeyCreationContext
import com.gorapeflutter.gf_app.entity.credential.GorapePasskeyConfiguration
import com.gorapeflutter.gf_app.entity.credential.GorapePasskeyRecord
import com.gorapeflutter.gf_app.entity.credential.PasskeyCreationSignatureContext
import com.gorapeflutter.gf_app.entity.credential.PasskeyCreationMaterial
import com.gorapeflutter.gf_app.entity.credential.PasskeyUserIdentity
import com.gorapeflutter.gf_app.driver.webauthn.WebAuthnCredentialDriver
import com.gorapeflutter.gf_app.entity.webauthn.AttestedCredentialData
import com.gorapeflutter.gf_app.entity.webauthn.WebAuthnAuthenticatorDataInput
import com.gorapeflutter.gf_app.entity.webauthn.WebAuthnClientDataInput
import com.gorapeflutter.gf_app.entity.webauthn.WebAuthnAttestationInput
import com.gorapeflutter.gf_app.share.Base64UrlCodec
import com.gorapeflutter.gf_app.share.NativeLogger
import java.security.SecureRandom
import java.security.Signature
import java.util.UUID
import org.json.JSONArray
import org.json.JSONObject

/** Executes the Credential Manager create-passkey request for Gorape RP. */
    // GF-01369 — Create the Credential Manager registration Driver for the Gorape RP.
internal class CreateGorapePasskeyDriver(
    private val activity: Activity,
    private val resultHandler: CredentialProviderResultHandler,
) {
    private val keyDriver = AndroidPasskeyKeyDriver(activity)
    private val webAuthnDriver = WebAuthnCredentialDriver(activity)
    private val biometricDriver = BiometricSigningDriver(activity)
    private val logger = NativeLogger(TAG)

    // GF-01208 — W3C WebAuthn Level 3: create a Gorape RP credential and Android Key attestation.
    fun create() {
        logger.info("Starting local WebAuthn credential creation")
        val creation = prepareCreation() ?: return
        requestBiometricSignature(creation)
    }

    // GF-01368 — Validate the RP request and prepare client data and user identity.
    private fun prepareCreation(): PasskeyCreationContext? {
        val requestContext = readRequest() ?: return null
        val options = readOptions(requestContext.requestJson) ?: return null
        if (!validateRelyingParty(options)) {
            return null
        }
        val origin = readTrustedOrigin(requestContext.callingAppInfo)
        if (origin == null) {
            resultHandler.failCreate(CALLER_NOT_TRUSTED)
            return null
        }
        val clientData = webAuthnDriver.makeClientData(
            WebAuthnClientDataInput(
                type = CREATE_TYPE,
                challenge = options.optString("challenge"),
                origin = origin,
                packageName = requestContext.callingAppInfo.packageName,
            ),
        )
        val clientDataHash = readClientDataHash(requestContext, clientData) ?: return null
        val userIdentity = readUserIdentity(options)
        if (userIdentity == null) {
            resultHandler.failCreate(INVALID_USER_HANDLE)
            return null
        }
        return PasskeyCreationContext(
            clientData = clientData,
            clientDataHash = clientDataHash,
            userIdentity = userIdentity,
        )
    }

    // GF-01367 — Validate Credential Manager clientDataHash against serialized client data.
    private fun readClientDataHash(requestContext: CredentialProviderCreateRequest, clientData: ByteArray): ByteArray? {
        val hash = webAuthnDriver.checkedClientDataHash(
            clientData,
            requestContext.clientDataHash,
        )
        if (hash != null) {
            return hash
        }
        resultHandler.failCreate(CLIENT_DATA_HASH_MISMATCH)
        return null
    }

    // GF-01366 — Generate the attested key and request biometric signature authorization.
    private fun requestBiometricSignature(creation: PasskeyCreationContext) {
        val keyAlias = newKeyAlias()
        val attestedKey = generateAttestedKey(keyAlias, creation.clientDataHash) ?: return
        val material = createAttestedAuthenticatorData(attestedKey, keyAlias) ?: return
        val signature = newAttestationSignature(attestedKey, keyAlias) ?: return
        val context = PasskeyCreationSignatureContext(
            clientData = creation.clientData,
            clientDataHash = creation.clientDataHash,
            material = material,
            attestedKey = attestedKey,
            keyAlias = keyAlias,
            userIdentity = creation.userIdentity,
        )
        val completion = CreateSignatureCompletion(context)
        biometricDriver.authenticate(signature, CREATE_PROMPT_TITLE, completion)
    }

    // GF-01365 — Read a public-key create request from the Credential Manager intent.
    private fun readRequest(): CredentialProviderCreateRequest? {
        val providerRequest = PendingIntentHandler.retrieveProviderCreateCredentialRequest(activity.intent)
        val request = providerRequest?.callingRequest as? CreatePublicKeyCredentialRequest
        if (request != null && providerRequest != null) {
            return CredentialProviderCreateRequest(
                requestJson = request.requestJson,
                clientDataHash = request.clientDataHash,
                callingAppInfo = providerRequest.callingAppInfo,
            )
        }
        resultHandler.failCreate(CREATE_REQUEST_MISSING)
        return null
    }

    // GF-01364 — Parse the WebAuthn creation options from their JSON representation.
    private fun readOptions(requestJson: String): JSONObject? {
        return try {
            JSONObject(requestJson)
        } catch (_: Exception) {
            resultHandler.failCreate(INVALID_CREATE_OPTIONS)
            null
        }
    }

    // GF-01363 — Require the configured Gorape RP ID and ES256 algorithm.
    private fun validateRelyingParty(options: JSONObject): Boolean {
        val rpId = options.optJSONObject("rp")?.optString("id")
        val user = options.optJSONObject("user")
        if (
            rpId != GorapePasskeyConfiguration.RP_ID ||
            user == null ||
            options.optString("challenge").isBlank()
        ) {
            resultHandler.failCreate(UNSUPPORTED_RP)
            return false
        }
        if (!webAuthnDriver.supportsEs256(options.optJSONArray("pubKeyCredParams"))) {
            resultHandler.failCreate(ES256_REQUIRED)
            return false
        }
        return true
    }

    // GF-01362 — Resolve and validate the Credential Manager caller origin.
    private fun readTrustedOrigin(callingAppInfo: CallingAppInfo): String? {
        val origin = webAuthnDriver.resolveOrigin(callingAppInfo) ?: return null
        if (!webAuthnDriver.originAllowed(origin)) {
            return null
        }
        return origin
    }

    // GF-01361 — Decode the WebAuthn user handle and normalize display identity.
    private fun readUserIdentity(options: JSONObject): PasskeyUserIdentity? {
        return try {
            val user = options.getJSONObject("user")
            val encoded = user.getString("id")
            val userHandle = Base64UrlCodec.decode(encoded)
            if (userHandle.isEmpty() || userHandle.size > MAX_USER_HANDLE_LENGTH) {
                return null
            }
            val userName = user.optString("name")
            val effectiveUserName = resolveUserName(userName, userHandle)
            val displayName = user.optString("displayName")
            val effectiveDisplayName = resolveDisplayName(displayName, effectiveUserName)
            PasskeyUserIdentity(
                userHandle = userHandle,
                userName = effectiveUserName,
                displayName = effectiveDisplayName,
            )
        } catch (_: Exception) {
            null
        }
    }

    // GF-01360 — Use the supplied WebAuthn user name or a stable handle representation.
    private fun resolveUserName(userName: String, userHandle: ByteArray): String {
        if (userName.isNotBlank()) {
            return userName
        }
        return hexString(userHandle)
    }

    // GF-01359 — Use the supplied display name or fall back to the user name.
    private fun resolveDisplayName(displayName: String, userName: String): String {
        if (displayName.isNotBlank()) {
            return displayName
        }
        return userName
    }

    // GF-01358 — Encode user-handle bytes as lowercase hexadecimal text.
    private fun hexString(bytes: ByteArray): String {
        val result = StringBuilder(bytes.size * 2)
        for (value in bytes) {
            result.append(String.format("%02x", value))
        }
        return result.toString()
    }

    // GF-01357 — Create a unique Android Keystore alias for the passkey.
    private fun newKeyAlias(): String = KEY_ALIAS_PREFIX + UUID.randomUUID()

    // GF-01356 — Generate a hardware-backed key and report key-attestation failures.
    private fun generateAttestedKey(alias: String, challenge: ByteArray): AttestedAndroidKey? {
        return try {
            keyDriver.generateAttestedKey(alias, challenge)
        } catch (error: Exception) {
            resultHandler.failCreate(error.message ?: KEY_GENERATION_FAILED)
            null
        }
    }

    // GF-01355 — Create a credential ID and WebAuthn authenticator data.
    private fun createAttestedAuthenticatorData(key: AttestedAndroidKey, keyAlias: String): PasskeyCreationMaterial? {
        return try {
            val credentialId = newCredentialId()
            val publicKey = webAuthnDriver.encodeCoseEc2(
                key.keyPair.public as java.security.interfaces.ECPublicKey,
            )
            PasskeyCreationMaterial(
                credentialId = credentialId,
                authenticatorData = webAuthnDriver.buildAuthenticatorData(
                    WebAuthnAuthenticatorDataInput(
                        rpId = GorapePasskeyConfiguration.RP_ID,
                        flags = FLAG_UP or FLAG_UV or FLAG_AT,
                        signCount = 0,
                        attestedCredential = AttestedCredentialData(
                            aaguid = ByteArray(AAGUID_LENGTH),
                            credentialId = credentialId,
                            credentialPublicKey = publicKey,
                        ),
                    ),
                ),
            )
        } catch (error: Exception) {
            keyDriver.deleteKey(keyAlias)
            resultHandler.failCreate(error.message ?: COSE_ENCODING_FAILED)
            null
        }
    }

    // GF-01354 — Generate a random 32-byte WebAuthn credential identifier.
    private fun newCredentialId(): ByteArray {
        val credentialId = ByteArray(CREDENTIAL_ID_LENGTH)
        SecureRandom().nextBytes(credentialId)
        return credentialId
    }

    // GF-01353 — Initialize SHA256withECDSA using the generated attestation key.
    private fun newAttestationSignature(key: AttestedAndroidKey, alias: String): Signature? {
        return try {
            val signature = Signature.getInstance(SIGNATURE_ALGORITHM)
            signature.initSign(key.keyPair.private)
            signature
        } catch (_: Exception) {
            keyDriver.deleteKey(alias)
            resultHandler.failCreate(ATTESTATION_SIGNATURE_INIT_FAILED)
            null
        }
    }

    // GF-01352 — Retain the attested creation state for biometric signing completion.
    private inner class CreateSignatureCompletion(
        private val context: PasskeyCreationSignatureContext,
    ) : BiometricSignatureCallback {
    // GF-01351 — Sign attestation data after biometric authorization succeeds.
        override fun onAuthenticated(signature: Signature) {
            val attestationSignature = signAttestation(signature)
            if (attestationSignature == null) {
                return
            }
            persistCredential()
            returnCredential(attestationSignature)
        }

    // GF-01350 — Remove the uncommitted key and report creation failure.
        override fun onAuthenticationError(message: String) {
            keyDriver.deleteKey(context.keyAlias)
            resultHandler.failCreate(message)
        }

    // GF-01349 — Sign authenticator data and client-data hash with the attested key.
        private fun signAttestation(signature: Signature): ByteArray? {
            return try {
                signature.update(context.material.authenticatorData + context.clientDataHash)
                signature.sign()
            } catch (_: Exception) {
                keyDriver.deleteKey(context.keyAlias)
                resultHandler.failCreate(ATTESTATION_SIGN_FAILED)
                null
            }
        }

    // GF-01348 — Persist passkey metadata while keeping private key material in Keystore.
        private fun persistCredential() {
            val credentialId = Base64UrlCodec.encode(context.material.credentialId)
            GorapePasskeyStore(activity).insert(
                GorapePasskeyRecord(
                    credentialId = credentialId,
                    rpId = GorapePasskeyConfiguration.RP_ID,
                    userHandle = Base64UrlCodec.encode(context.userIdentity.userHandle),
                    userName = context.userIdentity.userName,
                    displayName = context.userIdentity.displayName,
                    keyAlias = context.keyAlias,
                    signCount = 0,
                ),
            )
        }

    // GF-01347 — Return the completed WebAuthn creation response to Credential Manager.
        private fun returnCredential(signature: ByteArray) {
            val credentialId = Base64UrlCodec.encode(context.material.credentialId)
            val credential = createCredentialJson(credentialId, signature)
            resultHandler.completeCreate(CreatePublicKeyCredentialResponse(credential.toString()))
        }

    // GF-01346 — Serialize the standard WebAuthn PublicKeyCredential creation response.
        private fun createCredentialJson(credentialId: String, signature: ByteArray): JSONObject {
            val attestationObject = WebAuthnCredentialDriver(activity)
                .makeAttestationObject(
                    WebAuthnAttestationInput(
                        authenticatorData = context.material.authenticatorData,
                        signature = signature,
                        certificateChain = context.attestedKey.certificateChain,
                    ),
                )
            val response = JSONObject()
                .put("clientDataJSON", Base64UrlCodec.encode(context.clientData))
                .put("attestationObject", Base64UrlCodec.encode(attestationObject))
                .put("transports", JSONArray().put(GorapePasskeyConfiguration.TRANSPORT_INTERNAL))
            return JSONObject()
                .put("id", credentialId)
                .put("rawId", credentialId)
                .put("type", PUBLIC_KEY_TYPE)
                .put("authenticatorAttachment", "platform")
                .put("response", response)
                .put("clientExtensionResults", JSONObject())
        }
    }

    private companion object {
        const val TAG = "GorapePasskeyCreate"
        const val CREATE_TYPE = "webauthn.create"
        const val PUBLIC_KEY_TYPE = "public-key"
        const val SIGNATURE_ALGORITHM = "SHA256withECDSA"
        const val KEY_ALIAS_PREFIX = "gf-passkey-"
        const val CREDENTIAL_ID_LENGTH = 32
        const val MAX_USER_HANDLE_LENGTH = 64
        const val AAGUID_LENGTH = 16
        const val FLAG_UP = 0x01
        const val FLAG_UV = 0x04
        const val FLAG_AT = 0x40
        const val CREATE_PROMPT_TITLE = "Create a Gorape device-bound passkey"
        const val CREATE_REQUEST_MISSING = "Credential Manager did not provide a public-key create request."
        const val INVALID_CREATE_OPTIONS = "Invalid WebAuthn create options."
        const val UNSUPPORTED_RP = "GF Passkeys only accepts the configured Gorape RP."
        const val ES256_REQUIRED = "The WebAuthn request did not offer ES256."
        const val CALLER_NOT_TRUSTED = "The calling application or Web origin is not trusted."
        const val CLIENT_DATA_HASH_MISMATCH =
            "Credential Provider clientDataHash did not match the serialized client data."
        const val INVALID_USER_HANDLE = "WebAuthn user handle must be 1 to 64 bytes."
        const val KEY_GENERATION_FAILED = "Android hardware key generation failed."
        const val COSE_ENCODING_FAILED = "Could not encode the P-256 public key."
        const val ATTESTATION_SIGNATURE_INIT_FAILED =
            "Android Keystore could not initialize the attestation signature."
        const val ATTESTATION_SIGN_FAILED = "Android Keystore could not sign the attestation statement."
    }
}
