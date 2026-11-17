package com.gorapeflutter.gf_app.entity.credential

// GF-01258 — Store public passkey metadata and the non-exportable Keystore alias.
internal data class GorapePasskeyRecord(
    val credentialId: String,
    val rpId: String,
    val userHandle: String,
    val userName: String,
    val displayName: String,
    val keyAlias: String,
    val signCount: Long,
)
