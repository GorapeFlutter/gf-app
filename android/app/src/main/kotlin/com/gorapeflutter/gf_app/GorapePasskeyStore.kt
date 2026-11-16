package com.gorapeflutter.gf_app

import android.content.Context
import android.util.Base64
import org.json.JSONArray
import org.json.JSONObject

internal data class GorapePasskeyRecord(
    val credentialId: String,
    val rpId: String,
    val userHandle: String,
    val userName: String,
    val displayName: String,
    val keyAlias: String,
    val signCount: Long,
)

/** Stores metadata only; private keys stay in Android Keystore under keyAlias. */
internal class GorapePasskeyStore(context: Context) {
    private val preferences = context.getSharedPreferences(STORE_NAME, Context.MODE_PRIVATE)

    @Synchronized
    fun forRp(rpId: String): List<GorapePasskeyRecord> = readAll().filter { it.rpId == rpId }

    @Synchronized
    fun find(credentialId: String): GorapePasskeyRecord? =
        readAll().firstOrNull { it.credentialId == credentialId }

    @Synchronized
    fun insert(record: GorapePasskeyRecord) {
        val records = readAll().filterNot { it.credentialId == record.credentialId }
        writeAll(records + record)
    }

    @Synchronized
    fun incrementSignCount(credentialId: String): GorapePasskeyRecord? {
        val records = readAll()
        val index = records.indexOfFirst { it.credentialId == credentialId }
        if (index < 0) return null
        val current = records[index]
        val updated = current.copy(signCount = current.signCount + 1)
        writeAll(records.toMutableList().also { it[index] = updated })
        return updated
    }

    private fun readAll(): List<GorapePasskeyRecord> {
        val array = runCatching {
            JSONArray(preferences.getString(RECORDS_KEY, "[]"))
        }.getOrElse { JSONArray() }
        return buildList {
            for (index in 0 until array.length()) {
                val item = array.optJSONObject(index) ?: continue
                val id = item.optString("credentialId")
                val rpId = item.optString("rpId")
                val handle = item.optString("userHandle")
                val alias = item.optString("keyAlias")
                if (id.isBlank() || rpId.isBlank() || handle.isBlank() || alias.isBlank()) continue
                add(
                    GorapePasskeyRecord(
                        credentialId = id,
                        rpId = rpId,
                        userHandle = handle,
                        userName = item.optString("userName"),
                        displayName = item.optString("displayName"),
                        keyAlias = alias,
                        signCount = item.optLong("signCount", 0),
                    ),
                )
            }
        }
    }

    private fun writeAll(records: List<GorapePasskeyRecord>) {
        val array = JSONArray()
        records.forEach { record ->
            array.put(
                JSONObject()
                    .put("credentialId", record.credentialId)
                    .put("rpId", record.rpId)
                    .put("userHandle", record.userHandle)
                    .put("userName", record.userName)
                    .put("displayName", record.displayName)
                    .put("keyAlias", record.keyAlias)
                    .put("signCount", record.signCount),
            )
        }
        check(preferences.edit().putString(RECORDS_KEY, array.toString()).commit()) {
            "Could not persist the local passkey metadata."
        }
    }

    companion object {
        private const val STORE_NAME = "gf_android_credential_provider"
        private const val RECORDS_KEY = "passkeys"
    }
}

internal object GorapePasskeyProvider {
    const val RP_ID = "gorapeflutter.site"
    const val TRANSPORT_INTERNAL = "internal"

    fun encodeBase64Url(value: ByteArray): String =
        Base64.encodeToString(value, Base64.URL_SAFE or Base64.NO_WRAP or Base64.NO_PADDING)

    fun decodeBase64Url(value: String): ByteArray =
        Base64.decode(value, Base64.URL_SAFE or Base64.NO_WRAP or Base64.NO_PADDING)
}
