package com.gorapeflutter.gf_app

import java.io.ByteArrayOutputStream

/** Minimal deterministic CBOR encoder for WebAuthn authenticator structures. */
internal object WebAuthnCbor {
    fun encode(value: Any?): ByteArray = ByteArrayOutputStream().apply { writeValue(value) }.toByteArray()

    private fun ByteArrayOutputStream.writeValue(value: Any?) {
        when (value) {
            null -> write(0xf6)
            is Boolean -> write(if (value) 0xf5 else 0xf4)
            is ByteArray -> {
                writeHead(2, value.size.toLong())
                write(value)
            }
            is String -> {
                val bytes = value.toByteArray(Charsets.UTF_8)
                writeHead(3, bytes.size.toLong())
                write(bytes)
            }
            is Byte, is Short, is Int, is Long -> {
                val number = (value as Number).toLong()
                if (number >= 0) writeHead(0, number) else writeHead(1, -1L - number)
            }
            is List<*> -> {
                writeHead(4, value.size.toLong())
                value.forEach { writeValue(it) }
            }
            is Map<*, *> -> {
                writeHead(5, value.size.toLong())
                value.forEach { (key, item) ->
                    writeValue(key)
                    writeValue(item)
                }
            }
            else -> error("Unsupported CBOR value: ${value.javaClass.name}")
        }
    }

    private fun ByteArrayOutputStream.writeHead(major: Int, value: Long) {
        require(value >= 0)
        when {
            value < 24 -> write((major shl 5) or value.toInt())
            value <= 0xff -> {
                write((major shl 5) or 24)
                write(value.toInt())
            }
            value <= 0xffff -> {
                write((major shl 5) or 25)
                write((value.toInt() ushr 8) and 0xff)
                write(value.toInt() and 0xff)
            }
            value <= 0xffffffffL -> {
                write((major shl 5) or 26)
                for (shift in 24 downTo 0 step 8) write(((value ushr shift) and 0xff).toInt())
            }
            else -> {
                write((major shl 5) or 27)
                for (shift in 56 downTo 0 step 8) write(((value ushr shift) and 0xff).toInt())
            }
        }
    }
}
