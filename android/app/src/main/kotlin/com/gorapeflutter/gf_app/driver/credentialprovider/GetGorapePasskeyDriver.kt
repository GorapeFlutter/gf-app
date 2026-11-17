package com.gorapeflutter.gf_app.driver.credentialprovider

import android.app.Activity
import androidx.credentials.CredentialOption
import androidx.credentials.GetCredentialResponse
import androidx.credentials.GetPublicKeyCredentialOption
import androidx.credentials.PublicKeyCredential
import androidx.credentials.provider.PendingIntentHandler
import com.gorapeflutter.gf_app.GorapeCredentialProviderActivity
import com.gorapeflutter.gf_app.entity.credential.GorapePasskeyConfiguration
import com.gorapeflutter.gf_app.entity.credential.GorapePasskeyRecord
import com.gorapeflutter.gf_app.entity.credential.CredentialProviderGetRequest
import com.gorapeflutter.gf_app.entity.credential.PasskeyAssertionContext
import com.gorapeflutter.gf_app.entity.credential.PasskeyAssertionSignatureContext
import com.gorapeflutter.gf_app.driver.webauthn.WebAuthnCredentialDriver
import com.gorapeflutter.gf_app.share.Base64UrlCodec
import com.gorapeflutter.gf_app.share.NativeLogger
import com.gorapeflutter.gf_app.entity.webauthn.WebAuthnAuthenticatorDataInput
import com.gorapeflutter.gf_app.entity.webauthn.WebAuthnClientDataInput
import java.security.PrivateKey
import java.security.Signature
import org.json.JSONObject

/** Executes a Credential Manager get-passkey request for Gorape RP. */
    // GF-01329 — Create the Credential Manager assertion Driver for the Gorape RP.
internal class GetGorapePasskeyDriver(
    private val activity: Activity,
    private val resultHandler: CredentialProviderResultHandler,
) {
    private val keyDriver = AndroidPasskeyKeyDriver(activity)
    private val webAuthnDriver = WebAuthnCredentialDriver(activity)
    private val biometricDriver = BiometricSigningDriver(activity)
    private val logger = NativeLogger(TAG)

    // GF-01209 — W3C WebAuthn Level 3: sign a Gorape RP assertion with the Keystore key.
    fun get() {
        logger.info("Starting local WebAuthn assertion")
        val context = readAssertionContext() ?: return
        val assertion = prepareAssertion(context) ?: return
        requestBiometricVerification(assertion)
    }

    // GF-01328 — Validate the assertion request and prepare its RP-bound context.
    private fun readAssertionContext(): PasskeyAssertionContext? {
        val request = readRequest() ?: return null
        val options = readOptions(request.requestJson) ?: return null
        if (!validateRp(options)) {
            return null
        }
        val record = readCredential(request.credentialId) ?: return null
        val origin = readTrustedOrigin(request) ?: return null
        val clientDataInput = WebAuthnClientDataInput(
            type = GET_TYPE,
            challenge = options.optString("challenge"),
            origin = origin,
            packageName = request.callingPackage,
        )
        val clientData = webAuthnDriver.makeClientData(clientDataInput)
        val clientDataHash = readClientDataHash(request, clientData) ?: return null
        return PasskeyAssertionContext(
            record = record,
            clientData = clientData,
            clientDataHash = clientDataHash,
        )
    }

    // GF-01327 — Validate Credential Manager clientDataHash against serialized client data.
    private fun readClientDataHash(request: CredentialProviderGetRequest, clientData: ByteArray): ByteArray? {
        val hash = webAuthnDriver.checkedClientDataHash(clientData, request.clientDataHash)
        if (hash != null) {
            return hash
        }
        resultHandler.failGet(CLIENT_DATA_HASH_MISMATCH)
        return null
    }

    // GF-01326 — Increment the counter and prepare key signing for the assertion.
    private fun prepareAssertion(context: PasskeyAssertionContext): PasskeyAssertionSignatureContext? {
        val updatedRecord = incrementSignCount(context.record) ?: return null
        val authData = buildAssertionAuthenticatorData(updatedRecord)
        val privateKey = loadPrivateKey(updatedRecord.keyAlias) ?: return null
        val signature = newAssertionSignature(privateKey) ?: return null
        return PasskeyAssertionSignatureContext(
            record = updatedRecord,
            clientData = context.clientData,
            clientDataHash = context.clientDataHash,
            authenticatorData = authData,
            signature = signature,
        )
    }

    // GF-01325 — Build WebAuthn authenticator data for a passkey assertion.
    private fun buildAssertionAuthenticatorData(record: GorapePasskeyRecord): ByteArray {
        return webAuthnDriver.buildAuthenticatorData(
            WebAuthnAuthenticatorDataInput(
                rpId = record.rpId,
                flags = FLAG_UP or FLAG_UV,
                signCount = record.signCount,
            ),
        )
    }

    // GF-01324 — Require biometric verification before signing the assertion.
    private fun requestBiometricVerification(assertion: PasskeyAssertionSignatureContext) {
        val completion = GetSignatureCompletion(assertion)
        biometricDriver.authenticate(assertion.signature, GET_PROMPT_TITLE, completion)
    }

    // GF-01323 — Read a public-key get request and selected local credential ID.
    private fun readRequest(): CredentialProviderGetRequest? {
        val providerRequest = PendingIntentHandler.retrieveProviderGetCredentialRequest(activity.intent)
        if (providerRequest == null) {
            resultHandler.failGet(GET_REQUEST_MISSING)
            return null
        }
        val option = findPublicKeyOption(providerRequest.credentialOptions)
        if (option == null) {
            resultHandler.failGet(GET_REQUEST_MISSING)
            return null
        }
        val credentialId = activity.intent.getStringExtra(GorapeCredentialProviderActivity.EXTRA_CREDENTIAL_ID)
        if (credentialId.isNullOrBlank()) {
            resultHandler.failGet(GET_REQUEST_MISSING)
            return null
        }
        return CredentialProviderGetRequest(
            requestJson = option.requestJson,
            clientDataHash = option.clientDataHash,
            callingAppInfo = providerRequest.callingAppInfo,
            callingPackage = providerRequest.callingAppInfo.packageName,
            credentialId = credentialId,
        )
    }

    // GF-01322 — Select the public-key option from Credential Manager get options.
    private fun findPublicKeyOption(options: List<CredentialOption>): GetPublicKeyCredentialOption? {
        for (option in options) {
            if (option is GetPublicKeyCredentialOption) {
                return option
            }
        }
        return null
    }

    // GF-01321 — Parse WebAuthn assertion options from their JSON representation.
    private fun readOptions(requestJson: String): JSONObject? {
        return try {
            JSONObject(requestJson)
        } catch (_: Exception) {
            resultHandler.failGet(INVALID_GET_OPTIONS)
            null
        }
    }

    // GF-01320 — Require the configured Gorape RP ID for the assertion.
    private fun validateRp(options: JSONObject): Boolean {
        if (options.optString("rpId") == GorapePasskeyConfiguration.RP_ID) {
            return true
        }
        resultHandler.failGet(UNSUPPORTED_RP)
        return false
    }

    // GF-01319 — Load an active local credential belonging to the Gorape RP.
    private fun readCredential(credentialId: String): GorapePasskeyRecord? {
        val record = GorapePasskeyStore(activity).find(credentialId)
        if (record != null && record.rpId == GorapePasskeyConfiguration.RP_ID) {
            return record
        }
        resultHandler.failGet(CREDENTIAL_UNAVAILABLE)
        return null
    }

    // GF-01318 — Resolve and validate the assertion caller origin.
    private fun readTrustedOrigin(request: CredentialProviderGetRequest): String? {
        val origin = webAuthnDriver.resolveOrigin(request.callingAppInfo)
        if (origin != null && webAuthnDriver.originAllowed(origin)) {
            return origin
        }
        resultHandler.failGet(CALLER_NOT_TRUSTED)
        return null
    }

    // GF-01317 — Increment and persist the selected credential counter.
    private fun incrementSignCount(record: GorapePasskeyRecord): GorapePasskeyRecord? {
        val updated = GorapePasskeyStore(activity).incrementSignCount(record.credentialId)
        if (updated != null) {
            return updated
        }
        resultHandler.failGet(CREDENTIAL_UNAVAILABLE)
        return null
    }

    // GF-01316 — Load the non-exportable assertion key from Android Keystore.
    private fun loadPrivateKey(alias: String): PrivateKey? {
        return try {
            keyDriver.loadPrivateKey(alias)
        } catch (_: Exception) {
            resultHandler.failGet(KEY_UNAVAILABLE)
            null
        }
    }

    // GF-01315 — Initialize SHA256withECDSA with the selected passkey key.
    private fun newAssertionSignature(privateKey: PrivateKey): Signature? {
        return try {
            val signature = Signature.getInstance(SIGNATURE_ALGORITHM)
            signature.initSign(privateKey)
            signature
        } catch (_: Exception) {
            resultHandler.failGet(ASSERTION_SIGNATURE_INIT_FAILED)
            null
        }
    }

    // GF-01314 — Retain the assertion state needed by the biometric callback.
    private inner class GetSignatureCompletion(
        private val context: PasskeyAssertionSignatureContext,
    ) : BiometricSignatureCallback {
    // GF-01313 — Sign WebAuthn authenticator data after biometric authorization.
        override fun onAuthenticated(signature: Signature) {
            val signed = signAssertion(signature)
            if (signed == null) {
                return
            }
            resultHandler.completeGet(createGetCredentialResponse(signed))
        }

    // GF-01312 — Return biometric verification failure to Credential Manager.
        override fun onAuthenticationError(message: String) {
            resultHandler.failGet(message)
        }

    // GF-01311 — Sign authenticator data and client-data hash with the passkey.
        private fun signAssertion(signature: Signature): ByteArray? {
            return try {
                signature.update(context.authenticatorData + context.clientDataHash)
                signature.sign()
            } catch (_: Exception) {
                resultHandler.failGet(ASSERTION_SIGN_FAILED)
                null
            }
        }

    // GF-01310 — Serialize the standard WebAuthn PublicKeyCredential assertion response.
        private fun createGetCredentialResponse(signature: ByteArray): GetCredentialResponse {
            val response = JSONObject()
                .put("clientDataJSON", Base64UrlCodec.encode(context.clientData))
                .put("authenticatorData", Base64UrlCodec.encode(context.authenticatorData))
                .put("signature", Base64UrlCodec.encode(signature))
                .put("userHandle", context.record.userHandle)
            val credential = JSONObject()
                .put("id", context.record.credentialId)
                .put("rawId", context.record.credentialId)
                .put("type", PUBLIC_KEY_TYPE)
                .put("authenticatorAttachment", "platform")
                .put("response", response)
                .put("clientExtensionResults", JSONObject())
            return GetCredentialResponse(PublicKeyCredential(credential.toString()))
        }
    }

    private companion object {
        const val TAG = "GorapePasskeyGet"
        const val GET_TYPE = "webauthn.get"
        const val PUBLIC_KEY_TYPE = "public-key"
        const val SIGNATURE_ALGORITHM = "SHA256withECDSA"
        const val FLAG_UP = 0x01
        const val FLAG_UV = 0x04
        const val GET_PROMPT_TITLE = "Use your Gorape device-bound passkey"
        const val GET_REQUEST_MISSING = "Credential Manager did not provide a public-key get request."
        const val INVALID_GET_OPTIONS = "Invalid WebAuthn get options."
        const val UNSUPPORTED_RP = "GF Passkeys only accepts the configured Gorape RP."
        const val CREDENTIAL_UNAVAILABLE = "The selected local passkey is no longer available."
        const val CALLER_NOT_TRUSTED = "The calling application or Web origin is not trusted."
        const val CLIENT_DATA_HASH_MISMATCH =
            "Credential Provider clientDataHash did not match the serialized client data."
        const val KEY_UNAVAILABLE = "Android Keystore passkey key is unavailable."
        const val ASSERTION_SIGNATURE_INIT_FAILED =
            "Android Keystore could not initialize the assertion signature."
        const val ASSERTION_SIGN_FAILED = "Android Keystore could not sign the assertion."
    }
}
