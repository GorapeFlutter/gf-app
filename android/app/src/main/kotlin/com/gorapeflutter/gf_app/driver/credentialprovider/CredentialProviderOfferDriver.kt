package com.gorapeflutter.gf_app.driver.credentialprovider

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.OutcomeReceiver
import com.gorapeflutter.gf_app.GorapeCredentialProviderActivity
import com.gorapeflutter.gf_app.entity.credential.GorapePasskeyConfiguration
import com.gorapeflutter.gf_app.share.NativeLogger
import androidx.credentials.exceptions.CreateCredentialException
import androidx.credentials.exceptions.CreateCredentialUnknownException
import androidx.credentials.exceptions.GetCredentialException
import androidx.credentials.provider.BeginCreateCredentialRequest
import androidx.credentials.provider.BeginCreateCredentialResponse
import androidx.credentials.provider.BeginCreatePublicKeyCredentialRequest
import androidx.credentials.provider.BeginGetCredentialRequest
import androidx.credentials.provider.BeginGetCredentialResponse
import androidx.credentials.provider.BeginGetPublicKeyCredentialOption
import androidx.credentials.provider.CreateEntry
import androidx.credentials.provider.CredentialEntry
import androidx.credentials.provider.PublicKeyCredentialEntry
import com.gorapeflutter.gf_app.entity.credential.GorapePasskeyRecord
import org.json.JSONArray
import org.json.JSONObject

private typealias CreateOfferCallback = OutcomeReceiver<BeginCreateCredentialResponse, CreateCredentialException>
private typealias GetOfferCallback = OutcomeReceiver<BeginGetCredentialResponse, GetCredentialException>
private typealias CredentialEntryList = MutableList<CredentialEntry>

/** Builds the Credential Manager entries offered by the local Gorape provider. */
    // GF-01345 — Create the Driver that offers local Gorape passkeys to Credential Manager.
internal class CredentialProviderOfferDriver(private val context: Context) {
    private val logger = NativeLogger(TAG)
    private val passkeyStore = GorapePasskeyStore(context)

    // GF-01344 — Offer a create entry only for the configured Gorape RP.
    fun offerCreateCredential(request: BeginCreateCredentialRequest, callback: CreateOfferCallback) {
        logger.info("Create request type=${request.type}")
        val publicKeyRequest = request as? BeginCreatePublicKeyCredentialRequest
        if (publicKeyRequest == null) {
            callback.onError(CreateCredentialUnknownException(PASSKEYS_ONLY_MESSAGE))
            return
        }

        val rpId = readCreateRpId(publicKeyRequest.requestJson)
        if (rpId != GorapePasskeyConfiguration.RP_ID) {
            logger.info("Ignoring create request for rpId=$rpId")
            callback.onResult(BeginCreateCredentialResponse())
            return
        }

        logger.info("Offering local passkey for rpId=$rpId")
        callback.onResult(createCredentialResponse())
    }

    // GF-01343 — Return matching local credentials for a WebAuthn get request.
    fun offerGetCredential(request: BeginGetCredentialRequest, callback: GetOfferCallback) {
        logger.info("Get request option count=${request.beginGetCredentialOptions.size}")
        val entries = findCredentialEntries(request)
        callback.onResult(BeginGetCredentialResponse(entries))
    }

    // GF-01342 — Wrap the local passkey entry in a Credential Manager response.
    private fun createCredentialResponse(): BeginCreateCredentialResponse {
        return BeginCreateCredentialResponse(
            listOf(createCredentialEntry()),
        )
    }

    // GF-01341 — Create the PendingIntent entry for local passkey registration.
    private fun createCredentialEntry(): CreateEntry {
        val intent = Intent(context, GorapeCredentialProviderActivity::class.java)
        intent.action = GorapeCredentialProviderActivity.ACTION_CREATE
        intent.setPackage(context.packageName)
        val pendingIntent = PendingIntent.getActivity(
            context,
            System.nanoTime().toInt(),
            intent,
            PendingIntent.FLAG_MUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        return CreateEntry(
            PROVIDER_TITLE,
            pendingIntent,
            CREATE_DESCRIPTION,
        )
    }

    // GF-01340 — Collect local passkeys matching the get-request RP and credential IDs.
    private fun findCredentialEntries(request: BeginGetCredentialRequest): List<CredentialEntry> {
        val entries = ArrayList<CredentialEntry>()
        for (option in request.beginGetCredentialOptions) {
            val publicKeyOption = option as? BeginGetPublicKeyCredentialOption ?: continue
            addEntriesForOption(entries, publicKeyOption)
        }
        return entries
    }

    // GF-01339 — Add allowed local credentials for one public-key get option.
    private fun addEntriesForOption(entries: CredentialEntryList, publicKeyOption: BeginGetPublicKeyCredentialOption) {
        val options = parseOptions(publicKeyOption.requestJson) ?: return
        val rpId = options.optString("rpId")
        if (rpId != GorapePasskeyConfiguration.RP_ID) {
            return
        }
        val allowedIds = readAllowedIds(options.optJSONArray("allowCredentials"))
        for (record in passkeyStore.forRp(rpId)) {
            if (!credentialAllowed(record.credentialId, allowedIds)) {
                continue
            }
            entries.add(credentialEntry(record, publicKeyOption))
        }
    }

    // GF-01338 — Create the system chooser entry for one stored passkey.
    private fun credentialEntry(record: GorapePasskeyRecord, option: BeginGetPublicKeyCredentialOption) =
        PublicKeyCredentialEntry(
            context,
            record.userName,
            credentialPendingIntent(record),
            option,
            record.displayName,
        )

    // GF-01337 — Build a mutable PendingIntent bound to the selected credential ID.
    private fun credentialPendingIntent(record: GorapePasskeyRecord): PendingIntent {
        val intent = Intent(context, GorapeCredentialProviderActivity::class.java)
        intent.action = GorapeCredentialProviderActivity.ACTION_GET
        intent.setPackage(context.packageName)
        intent.putExtra(GorapeCredentialProviderActivity.EXTRA_CREDENTIAL_ID, record.credentialId)
        val requestCode = record.credentialId.hashCode() xor System.nanoTime().toInt()
        val pendingIntent = PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_MUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        return pendingIntent
    }

    // GF-01336 — Read the RP ID from a public-key create request.
    private fun readCreateRpId(requestJson: String): String? {
        val request = parseOptions(requestJson) ?: return null
        return request.optJSONObject("rp")?.optString("id")
    }

    // GF-01335 — Parse Credential Manager request JSON without throwing to the service.
    private fun parseOptions(requestJson: String): JSONObject? {
        return try {
            JSONObject(requestJson)
        } catch (_: Exception) {
            null
        }
    }

    // GF-01206 — Parses credential IDs allowed by the relying party.
    private fun readAllowedIds(array: JSONArray?): Set<String> {
        if (array == null) {
            return emptySet()
        }
        val ids = HashSet<String>()
        for (index in 0 until array.length()) {
            val id = array.optJSONObject(index)?.optString("id")
            if (!id.isNullOrBlank()) {
                ids.add(id)
            }
        }
        return ids
    }

    // GF-01334 — Check whether the relying party allows the credential ID.
    private fun credentialAllowed(credentialId: String, allowedIds: Set<String>): Boolean {
        return allowedIds.isEmpty() || allowedIds.contains(credentialId)
    }

    private companion object {
        const val TAG = "GorapeCredProvider"
        const val PROVIDER_TITLE = "GF Hardware Passkeys"
        const val CREATE_DESCRIPTION = "Create a device-bound Gorape passkey"
        const val PASSKEYS_ONLY_MESSAGE = "Only WebAuthn passkeys are supported."
    }
}
