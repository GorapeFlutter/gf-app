package com.gorapeflutter.gf_app.entity.device

internal sealed interface DeviceKeyChannelResponse {
    // GF-01253 — Represent a successful Flutter device-key channel result.
    data class Success(val value: Any?) : DeviceKeyChannelResponse
    // GF-01252 — Represent a failed Flutter device-key channel result.
    data class Failure(val message: String) : DeviceKeyChannelResponse
}
