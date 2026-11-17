package com.gorapeflutter.gf_app.entity.credential

import java.security.KeyPair
import java.security.Signature
import java.security.cert.Certificate

// GF-01267 — Carry the generated P-256 key pair and leaf-first attestation chain.
internal data class AttestedAndroidKey(
    val keyPair: KeyPair,
    val certificateChain: List<Certificate>,
)

// GF-01266 — Carry the WebAuthn credential ID and authenticator data.
internal data class PasskeyCreationMaterial(
    val credentialId: ByteArray,
    val authenticatorData: ByteArray,
)

// GF-01265 — Carry the WebAuthn user handle, user name, and display name.
internal data class PasskeyUserIdentity(
    val userHandle: ByteArray,
    val userName: String,
    val displayName: String,
)

// GF-01264 — Carry all data needed to finish an attested passkey signature.
internal data class PasskeyCreationSignatureContext(
    val clientData: ByteArray,
    val clientDataHash: ByteArray,
    val material: PasskeyCreationMaterial,
    val attestedKey: AttestedAndroidKey,
    val keyAlias: String,
    val userIdentity: PasskeyUserIdentity,
)

// GF-01263 — Carry validated client data and identity for credential creation.
internal data class PasskeyCreationContext(
    val clientData: ByteArray,
    val clientDataHash: ByteArray,
    val userIdentity: PasskeyUserIdentity,
)

// GF-01262 — Carry the stored credential and validated assertion client data.
internal data class PasskeyAssertionContext(
    val record: GorapePasskeyRecord,
    val clientData: ByteArray,
    val clientDataHash: ByteArray,
)

// GF-01261 — Carry authenticator data and signature state for an assertion.
internal data class PasskeyAssertionSignatureContext(
    val record: GorapePasskeyRecord,
    val clientData: ByteArray,
    val clientDataHash: ByteArray,
    val authenticatorData: ByteArray,
    val signature: Signature,
)
