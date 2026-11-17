package com.gorapeflutter.gf_app.share

import android.util.Base64

internal object Base64UrlCodec {
    // GF-01151 — RFC 4648 §5: encode device-key bytes as unpadded Base64url.
    // GF-01236 — RFC 4648 §5: encode passkey bytes as unpadded Base64url.
    fun encode(value: ByteArray): String {
        val flags = Base64.URL_SAFE or Base64.NO_WRAP or Base64.NO_PADDING
        return Base64.encodeToString(value, flags)
    }

    // GF-01150 — RFC 4648 §5: decode device-key Base64url bytes.
    // GF-01237 — RFC 4648 §5: decode passkey Base64url bytes.
    fun decode(value: String): ByteArray {
        val flags = Base64.URL_SAFE or Base64.NO_WRAP or Base64.NO_PADDING
        return Base64.decode(value, flags)
    }
}
