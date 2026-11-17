package com.gorapeflutter.gf_app.driver.credentialprovider

import androidx.credentials.CreatePublicKeyCredentialResponse
import androidx.credentials.GetCredentialResponse

internal interface CredentialProviderResultHandler {
    // GF-01333 — Return a successful WebAuthn creation response to Credential Manager.
    fun completeCreate(response: CreatePublicKeyCredentialResponse)
    // GF-01332 — Return a successful WebAuthn assertion response to Credential Manager.
    fun completeGet(response: GetCredentialResponse)
    // GF-01331 — Return a typed WebAuthn creation error to Credential Manager.
    fun failCreate(message: String)
    // GF-01330 — Return a typed WebAuthn assertion error to Credential Manager.
    fun failGet(message: String)
}
