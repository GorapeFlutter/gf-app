package com.gorapeflutter.gf_app

import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.os.CancellationSignal
import android.os.OutcomeReceiver
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.credentials.exceptions.ClearCredentialException
import androidx.credentials.exceptions.CreateCredentialException
import androidx.credentials.exceptions.CreateCredentialUnknownException
import androidx.credentials.exceptions.GetCredentialException
import androidx.credentials.exceptions.GetCredentialUnknownException
import androidx.credentials.provider.BeginCreateCredentialRequest
import androidx.credentials.provider.BeginCreateCredentialResponse
import androidx.credentials.provider.BeginCreatePublicKeyCredentialRequest
import androidx.credentials.provider.BeginGetCredentialRequest
import androidx.credentials.provider.BeginGetCredentialResponse
import androidx.credentials.provider.BeginGetPublicKeyCredentialOption
import androidx.credentials.provider.CredentialProviderService
import androidx.credentials.provider.CreateEntry
import androidx.credentials.provider.PendingIntentHandler
import androidx.credentials.provider.PublicKeyCredentialEntry

/**
 * A local Credential Manager provider for Gorape's RP.
 *
 * This is deliberately restricted to gorapeflutter.site. Credentials are
 * generated in Android Keystore by [GorapeCredentialProviderActivity]; this
 * service does not import or export private keys. Cross-device/hybrid support
 * is not advertised until the platform's CDA path is verified on-device.
 */
@RequiresApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
class GorapeCredentialProviderService : CredentialProviderService() {
    private val tag = "GorapeCredProvider"

    override fun onBeginCreateCredentialRequest(
        request: BeginCreateCredentialRequest,
        cancellationSignal: CancellationSignal,
        callback: OutcomeReceiver<BeginCreateCredentialResponse, CreateCredentialException>,
    ) {
        Log.i(tag, "onBeginCreateCredentialRequest type=${request.type}")
        val publicKeyRequest = request as? BeginCreatePublicKeyCredentialRequest
        if (publicKeyRequest == null) {
            callback.onError(CreateCredentialUnknownException("Only WebAuthn passkeys are supported."))
            return
        }

        val rpId = runCatching {
            org.json.JSONObject(publicKeyRequest.requestJson)
                .getJSONObject("rp")
                .getString("id")
        }.getOrNull()
        if (rpId != GorapePasskeyProvider.RP_ID) {
            Log.i(tag, "Ignoring create request for rpId=$rpId")
            callback.onResult(BeginCreateCredentialResponse())
            return
        }
        Log.i(tag, "Offering local Android KeyStore passkey for rpId=$rpId")

        val intent = Intent(this, GorapeCredentialProviderActivity::class.java)
            .setAction(GorapeCredentialProviderActivity.ACTION_CREATE)
            .setPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this,
            System.nanoTime().toInt(),
            intent,
            PendingIntent.FLAG_MUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        callback.onResult(
            BeginCreateCredentialResponse(
                listOf(
                    CreateEntry(
                        "GF Hardware Passkeys",
                        pendingIntent,
                        "Create a device-bound Gorape passkey",
                    ),
                ),
            ),
        )
    }

    override fun onBeginGetCredentialRequest(
        request: BeginGetCredentialRequest,
        cancellationSignal: CancellationSignal,
        callback: OutcomeReceiver<BeginGetCredentialResponse, GetCredentialException>,
    ) {
        Log.i(tag, "onBeginGetCredentialRequest options=${request.beginGetCredentialOptions.size}")
        val entries = mutableListOf<androidx.credentials.provider.CredentialEntry>()
        val store = GorapePasskeyStore(this)
        for (option in request.beginGetCredentialOptions) {
            val publicKeyOption = option as? BeginGetPublicKeyCredentialOption ?: continue
            val parsed = runCatching { org.json.JSONObject(publicKeyOption.requestJson) }.getOrNull() ?: continue
            val rpId = parsed.optString("rpId")
            if (rpId != GorapePasskeyProvider.RP_ID) continue
            Log.i(tag, "Looking up local credentials for rpId=$rpId")

            val allowIds = parseAllowedIds(parsed.optJSONArray("allowCredentials"))
            val matching = store.forRp(rpId).filter { allowIds.isEmpty() || it.credentialId in allowIds }
            for (record in matching) {
                val intent = Intent(this, GorapeCredentialProviderActivity::class.java)
                    .setAction(GorapeCredentialProviderActivity.ACTION_GET)
                    .setPackage(packageName)
                    .putExtra(GorapeCredentialProviderActivity.EXTRA_CREDENTIAL_ID, record.credentialId)
                val pendingIntent = PendingIntent.getActivity(
                    this,
                    (record.credentialId.hashCode() xor System.nanoTime().toInt()),
                    intent,
                    PendingIntent.FLAG_MUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
                )
                entries.add(
                    PublicKeyCredentialEntry(
                        this,
                        record.userName,
                        pendingIntent,
                        publicKeyOption,
                        record.displayName,
                    ),
                )
            }
        }
        callback.onResult(BeginGetCredentialResponse(entries))
    }

    override fun onClearCredentialStateRequest(
        request: androidx.credentials.provider.ProviderClearCredentialStateRequest,
        cancellationSignal: CancellationSignal,
        callback: OutcomeReceiver<Void?, ClearCredentialException>,
    ) {
        // Clearing chooser state does not delete credentials or Keystore keys.
        callback.onResult(null)
    }

    private fun parseAllowedIds(array: org.json.JSONArray?): Set<String> {
        if (array == null) return emptySet()
        return buildSet {
            for (index in 0 until array.length()) {
                val id = array.optJSONObject(index)?.optString("id")
                if (!id.isNullOrBlank()) add(id)
            }
        }
    }
}
