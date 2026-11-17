package com.gorapeflutter.gf_app.driver.credentialprovider

import android.content.Context
import com.gorapeflutter.gf_app.entity.credential.GorapePasskeyRecord
import org.json.JSONArray
import org.json.JSONObject

/** Stores metadata only; private keys stay in Android Keystore under keyAlias. */
// GF-01242 — Initializes local metadata storage for RP-bound credentials.
internal class GorapePasskeyStore(context: Context) {
    private val preferences = context.getSharedPreferences(STORE_NAME, Context.MODE_PRIVATE)

    @Synchronized
    // GF-01230 — Lists metadata records scoped to one relying party.
    fun forRp(rpId: String): List<GorapePasskeyRecord> {
        val matches = ArrayList<GorapePasskeyRecord>()
        for (record in readAll()) {
            if (record.rpId == rpId) {
                matches.add(record)
            }
        }
        return matches
    }

    @Synchronized
    // GF-01231 — Finds local credential metadata by credential ID.
    fun find(credentialId: String): GorapePasskeyRecord? {
        for (record in readAll()) {
            if (record.credentialId == credentialId) {
                return record
            }
        }
        return null
    }

    @Synchronized
    // GF-01232 — Stores credential metadata without exporting private keys.
    fun insert(record: GorapePasskeyRecord) {
        val records = ArrayList<GorapePasskeyRecord>()
        for (storedRecord in readAll()) {
            if (storedRecord.credentialId != record.credentialId) {
                records.add(storedRecord)
            }
        }
        writeAll(records + record)
    }

    @Synchronized
    // GF-01233 — Increments and persists an assertion signature counter.
    fun incrementSignCount(credentialId: String): GorapePasskeyRecord? {
        val records = readAll()
        val index = findIndex(records, credentialId)
        if (index < 0) {
            return null
        }
        val current = records[index]
        val updated = current.copy(signCount = current.signCount + 1)
        val updatedRecords = records.toMutableList()
        updatedRecords[index] = updated
        writeAll(updatedRecords)
        return updated
    }

    // GF-01309 — Find the stored passkey record index by credential ID.
    private fun findIndex(records: List<GorapePasskeyRecord>, credentialId: String): Int {
        for (index in records.indices) {
            if (records[index].credentialId == credentialId) {
                return index
            }
        }
        return -1
    }

    // GF-01234 — Reads valid credential metadata records from app preferences.
    private fun readAll(): List<GorapePasskeyRecord> {
        val array = try {
            JSONArray(preferences.getString(RECORDS_KEY, "[]"))
        } catch (_: Exception) {
            JSONArray()
        }
        val records = ArrayList<GorapePasskeyRecord>()
        for (index in 0 until array.length()) {
            val item = array.optJSONObject(index) ?: continue
            val record = recordFromJson(item) ?: continue
            records.add(record)
        }
        return records
    }

    // GF-01308 — Decode a valid passkey metadata record from JSON.
    private fun recordFromJson(item: JSONObject): GorapePasskeyRecord? {
        val credentialId = item.optString("credentialId")
        val rpId = item.optString("rpId")
        val userHandle = item.optString("userHandle")
        val keyAlias = item.optString("keyAlias")
        if (credentialId.isBlank() || rpId.isBlank() || userHandle.isBlank() || keyAlias.isBlank()) {
            return null
        }
        return GorapePasskeyRecord(
            credentialId = credentialId,
            rpId = rpId,
            userHandle = userHandle,
            userName = item.optString("userName"),
            displayName = item.optString("displayName"),
            keyAlias = keyAlias,
            signCount = item.optLong("signCount", 0),
        )
    }

    // GF-01235 — Atomically persists credential metadata records.
    private fun writeAll(records: List<GorapePasskeyRecord>) {
        val array = JSONArray()
        for (record in records) {
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
        val saved = preferences.edit().putString(RECORDS_KEY, array.toString()).commit()
        if (!saved) {
            throw IllegalStateException("Could not persist the local passkey metadata.")
        }
    }

    companion object {
        private const val STORE_NAME = "gf_android_credential_provider"
        private const val RECORDS_KEY = "passkeys"
    }
}
