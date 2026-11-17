package com.gorapeflutter.gf_app.share

import android.util.Log

    // GF-01246 — Create a native Logger with the Android log tag.
internal class NativeLogger(private val tag: String) {
    // GF-01245 — Write an informational native log entry.
    fun info(message: String) {
        Log.i(tag, message)
    }

    // GF-01244 — Write a warning native log entry and optional exception.
    fun warning(message: String, error: Throwable? = null) {
        if (error == null) {
            Log.w(tag, message)
        } else {
            Log.w(tag, message, error)
        }
    }

    // GF-01243 — Write an error native log entry and optional exception.
    fun error(message: String, error: Throwable? = null) {
        if (error == null) {
            Log.e(tag, message)
        } else {
            Log.e(tag, message, error)
        }
    }
}
