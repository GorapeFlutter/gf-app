package com.gorapeflutter.gf_app.entity.device

import java.security.KeyPair

// GF-01251 — Store an Android Keystore key pair and its StrongBox provenance.
internal data class GeneratedAndroidKeyPair(
    val keyPair: KeyPair,
    val strongBox: Boolean,
)
