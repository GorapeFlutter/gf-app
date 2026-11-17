package com.gorapeflutter.gf_app

import android.app.Activity
import android.content.Intent
import android.os.Build
import android.os.Bundle
import androidx.credentials.CreatePublicKeyCredentialResponse
import androidx.credentials.GetCredentialResponse
import androidx.credentials.exceptions.CreateCredentialUnknownException
import androidx.credentials.exceptions.GetCredentialUnknownException
import androidx.credentials.provider.PendingIntentHandler
import com.gorapeflutter.gf_app.driver.credentialprovider.CreateGorapePasskeyDriver
import com.gorapeflutter.gf_app.driver.credentialprovider.CredentialProviderResultHandler
import com.gorapeflutter.gf_app.driver.credentialprovider.GetGorapePasskeyDriver

/** Android Activity adapter for Credential Manager passkey ceremonies. */
class GorapeCredentialProviderActivity : Activity(), CredentialProviderResultHandler {
    // GF-01207 — Dispatches Credential Manager create/get callbacks.
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (!isCredentialProviderSupported()) {
            failCreate(ANDROID_VERSION_REQUIRED)
            return
        }
        dispatchCredentialRequest()
    }

    // GF-01390 — Check whether the Android Credential Provider API level is supported.
    private fun isCredentialProviderSupported(): Boolean {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE
    }

    // GF-01389 — Dispatch the incoming create or get credential action to its Driver.
    private fun dispatchCredentialRequest() {
        when (intent.action) {
            ACTION_CREATE -> createPasskey()
            ACTION_GET -> getPasskey()
            else -> finish()
        }
    }

    // GF-01388 — Delegate passkey creation to the create-passkey Driver.
    private fun createPasskey() {
        CreateGorapePasskeyDriver(this, this).create()
    }

    // GF-01387 — Delegate passkey assertion to the get-passkey Driver.
    private fun getPasskey() {
        GetGorapePasskeyDriver(this, this).get()
    }

    // GF-01225 — Returns the completed create response to Credential Manager.
    override fun completeCreate(response: CreatePublicKeyCredentialResponse) {
        val data = Intent()
        PendingIntentHandler.setCreateCredentialResponse(data, response)
        finishWithResult(data)
    }

    // GF-01226 — Returns the completed assertion response to Credential Manager.
    override fun completeGet(response: GetCredentialResponse) {
        val data = Intent()
        PendingIntentHandler.setGetCredentialResponse(data, response)
        finishWithResult(data)
    }

    // GF-01227 — Returns a create-ceremony error to Credential Manager.
    override fun failCreate(message: String) {
        val data = Intent()
        PendingIntentHandler.setCreateCredentialException(
            data,
            CreateCredentialUnknownException(message),
        )
        finishWithResult(data)
    }

    // GF-01228 — Returns a get-ceremony error to Credential Manager.
    override fun failGet(message: String) {
        val data = Intent()
        PendingIntentHandler.setGetCredentialException(
            data,
            GetCredentialUnknownException(message),
        )
        finishWithResult(data)
    }

    // GF-01229 — Serializes a typed Credential Manager response and finishes the activity.
    private fun finishWithResult(data: Intent) {
        setResult(RESULT_OK, data)
        finish()
    }

    companion object {
        const val ACTION_CREATE = "com.gorapeflutter.gf_app.CREDENTIAL_CREATE"
        const val ACTION_GET = "com.gorapeflutter.gf_app.CREDENTIAL_GET"
        const val EXTRA_CREDENTIAL_ID = "credential_id"
        private const val ANDROID_VERSION_REQUIRED = "GF Passkeys requires Android 14 or newer."
    }
}
