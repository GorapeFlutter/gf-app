package com.gorapeflutter.gf_app.entity.device

    // GF-01257 — Describe Android device-key and attestation capabilities.
internal data class AndroidDeviceKeyAvailability(
    val supported: Boolean,
    val hardwareBacked: Boolean,
    val attestationSupported: Boolean,
    val securityLevel: String,
    val reason: String?,
) {
    // GF-01256 — Serialize Android device-key availability or generated-key evidence for Flutter.
    fun toMethodChannelMap(): Map<String, Any?> {
        val result = HashMap<String, Any?>(5)
        result["supported"] = supported
        result["hardwareBacked"] = hardwareBacked
        result["attestationSupported"] = attestationSupported
        result["securityLevel"] = securityLevel
        result["reason"] = reason
        return result
    }
}

    // GF-01255 — Carry the generated public key and Android attestation chain.
internal data class AndroidGeneratedDeviceKey(
    val keyIdentifier: String,
    val publicKeyPem: String,
    val algorithm: String,
    val securityLevel: String,
    val certificateChain: List<String>,
) {
    // GF-01254 — Serialize Android device-key availability or generated-key evidence for Flutter.
    fun toMethodChannelMap(): Map<String, Any> {
        val result = HashMap<String, Any>(6)
        result["keyIdentifier"] = keyIdentifier
        result["publicKeyPem"] = publicKeyPem
        result["algorithm"] = algorithm
        result["securityLevel"] = securityLevel
        result["certificateChain"] = certificateChain
        result["attestationEvidence"] = mapOf("type" to "android-key")
        return result
    }
}
