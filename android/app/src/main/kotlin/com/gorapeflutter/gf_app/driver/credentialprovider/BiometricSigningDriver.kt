package com.gorapeflutter.gf_app.driver.credentialprovider

import android.app.Activity
import android.hardware.biometrics.BiometricPrompt
import android.os.CancellationSignal
import java.security.Signature

internal interface BiometricSignatureCallback {
    // GF-01376 — Receive the signature authorized by Android biometric verification.
    fun onAuthenticated(signature: Signature)
    // GF-01375 — Receive an Android biometric verification failure.
    fun onAuthenticationError(message: String)
}

/** Requests user verification before the selected Keystore key signs data. */
    // GF-01374 — Create a Driver that authorizes private-key use with biometrics.
internal class BiometricSigningDriver(private val activity: Activity) {
    // GF-01210 — Requires biometric user verification before hardware signing.
    fun authenticate(signature: Signature, title: String, callback: BiometricSignatureCallback) {
        val prompt = createPrompt(title)
        prompt.authenticate(
            BiometricPrompt.CryptoObject(signature),
            CancellationSignal(),
            activity.mainExecutor,
            PromptCallback(callback),
        )
    }

    // GF-01373 — Build the Android BiometricPrompt for a passkey signing request.
    private fun createPrompt(title: String): BiometricPrompt {
        return BiometricPrompt.Builder(activity)
            .setTitle(title)
            .setSubtitle("Verify with your device biometric")
            .setAllowedAuthenticators(BIOMETRIC_AUTHENTICATORS)
            .build()
    }

    // GF-01372 — Bind Android BiometricPrompt callbacks to the signing completion.
    private class PromptCallback(
        private val completion: BiometricSignatureCallback,
    ) : BiometricPrompt.AuthenticationCallback() {
    // GF-01371 — Receive an Android biometric verification failure.
        override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
            super.onAuthenticationError(errorCode, errString)
            completion.onAuthenticationError("User verification failed: $errString")
        }

    // GF-01370 — Return the authenticated signature or report a missing CryptoObject.
        override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
            super.onAuthenticationSucceeded(result)
            val signature = result.cryptoObject?.signature
            if (signature == null) {
                completion.onAuthenticationError("The hardware signing operation was not authorized.")
                return
            }
            completion.onAuthenticated(signature)
        }
    }

    private companion object {
        const val BIOMETRIC_AUTHENTICATORS =
            android.hardware.biometrics.BiometricManager.Authenticators.BIOMETRIC_STRONG
    }
}
