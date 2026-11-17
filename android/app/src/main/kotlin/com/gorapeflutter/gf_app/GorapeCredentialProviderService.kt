package com.gorapeflutter.gf_app

import android.os.Build
import android.os.CancellationSignal
import android.os.OutcomeReceiver
import androidx.annotation.RequiresApi
import androidx.credentials.exceptions.ClearCredentialException
import androidx.credentials.exceptions.CreateCredentialException
import androidx.credentials.exceptions.GetCredentialException
import androidx.credentials.provider.BeginCreateCredentialRequest
import androidx.credentials.provider.BeginCreateCredentialResponse
import androidx.credentials.provider.BeginGetCredentialRequest
import androidx.credentials.provider.BeginGetCredentialResponse
import androidx.credentials.provider.CredentialProviderService
import androidx.credentials.provider.ProviderClearCredentialStateRequest
import com.gorapeflutter.gf_app.driver.credentialprovider.CredentialProviderOfferDriver

private typealias CancelSignal = CancellationSignal
private typealias CreateRequest = BeginCreateCredentialRequest
private typealias GetRequest = BeginGetCredentialRequest
private typealias ClearStateRequest = ProviderClearCredentialStateRequest
private typealias CreateCallback = OutcomeReceiver<BeginCreateCredentialResponse, CreateCredentialException>
private typealias GetCallback = OutcomeReceiver<BeginGetCredentialResponse, GetCredentialException>
private typealias ClearCallback = OutcomeReceiver<Void?, ClearCredentialException>

/** Android Credential Manager service adapter. Request policy lives in its driver. */
@RequiresApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
class GorapeCredentialProviderService : CredentialProviderService() {
    private lateinit var offerDriver: CredentialProviderOfferDriver

    // GF-01518 — Initialize the Credential Provider Driver after Android attaches the service context.
    override fun onCreate() {
        super.onCreate()
        initializeOfferDriver()
    }

    // GF-01519 — Create the provider-offer Driver with an initialized service context.
    private fun initializeOfferDriver() {
        offerDriver = CredentialProviderOfferDriver(this)
    }

    // GF-01203 — Offers the local provider for Gorape RP credential creation.
    override fun onBeginCreateCredentialRequest(request: CreateRequest, cancel: CancelSignal, cb: CreateCallback) {
        offerDriver.offerCreateCredential(request, cb)
    }

    // GF-01204 — Returns locally stored credentials matching Gorape get options.
    override fun onBeginGetCredentialRequest(request: GetRequest, cancel: CancelSignal, cb: GetCallback) {
        offerDriver.offerGetCredential(request, cb)
    }

    // GF-01205 — Clears chooser state without deleting stored credentials.
    override fun onClearCredentialStateRequest(request: ClearStateRequest, cancel: CancelSignal, cb: ClearCallback) {
        cb.onResult(null)
    }
}
