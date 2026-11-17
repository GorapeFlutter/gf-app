package com.gorapeflutter.gf_app.entity.credential

import androidx.credentials.provider.CallingAppInfo

// GF-01260 — Carry WebAuthn create options, client-data hash, and caller identity.
internal data class CredentialProviderCreateRequest(
    val requestJson: String,
    val clientDataHash: ByteArray?,
    val callingAppInfo: CallingAppInfo,
)

// GF-01259 — Carry WebAuthn get options, caller identity, and selected credential.
internal data class CredentialProviderGetRequest(
    val requestJson: String,
    val clientDataHash: ByteArray?,
    val callingAppInfo: CallingAppInfo,
    val callingPackage: String,
    val credentialId: String,
)
