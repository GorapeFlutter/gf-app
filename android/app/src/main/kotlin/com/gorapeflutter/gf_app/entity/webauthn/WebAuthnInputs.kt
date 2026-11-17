package com.gorapeflutter.gf_app.entity.webauthn

import java.security.cert.Certificate

// GF-01250 — Carry the WebAuthn client-data type, challenge, origin, and caller package.
internal data class WebAuthnClientDataInput(
    val type: String,
    val challenge: String,
    val origin: String,
    val packageName: String,
)

// GF-01249 — Carry the AAGUID, credential ID, and credential public key.
internal data class AttestedCredentialData(
    val aaguid: ByteArray,
    val credentialId: ByteArray,
    val credentialPublicKey: ByteArray,
)

// GF-01248 — Carry the RP ID, flags, counter, and optional attested credential data.
internal data class WebAuthnAuthenticatorDataInput(
    val rpId: String,
    val flags: Int,
    val signCount: Long,
    val attestedCredential: AttestedCredentialData? = null,
)

// GF-01247 — Carry authenticator data, signature, and attestation certificates.
internal data class WebAuthnAttestationInput(
    val authenticatorData: ByteArray,
    val signature: ByteArray,
    val certificateChain: List<Certificate>,
)
