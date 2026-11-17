package com.gorapeflutter.gf_app.driver.webauthn

import java.io.ByteArrayOutputStream

/** Deterministic CBOR encoder for WebAuthn authenticator structures. */
internal object WebAuthnCbor {
    // GF-01238 — RFC 8949: encode WebAuthn values using deterministic CBOR.
    fun encode(value: Any?): ByteArray {
        val output = ByteArrayOutputStream()
        writeValue(output, value)
        return output.toByteArray()
    }

    // GF-01239 — RFC 8949: recursively encode primitive, byte, array, and map values.
    private fun writeValue(output: ByteArrayOutputStream, value: Any?) {
        when (value) {
            null -> output.write(CBOR_NULL)
            is Boolean -> writeBoolean(output, value)
            is ByteArray -> writeByteString(output, value)
            is String -> writeTextString(output, value)
            is Byte, is Short, is Int, is Long -> writeInteger(output, (value as Number).toLong())
            is List<*> -> writeList(output, value)
            is Map<*, *> -> writeMap(output, value)
            else -> error("Unsupported CBOR value: ${value.javaClass.name}")
        }
    }

    // GF-01284 — Encode a CBOR Boolean using RFC 8949 simple values.
    private fun writeBoolean(output: ByteArrayOutputStream, value: Boolean) {
        if (value) {
            output.write(CBOR_TRUE)
        } else {
            output.write(CBOR_FALSE)
        }
    }

    // GF-01283 — Encode a CBOR byte string according to RFC 8949.
    private fun writeByteString(output: ByteArrayOutputStream, value: ByteArray) {
        writeHead(output, CBOR_BYTE_STRING, value.size.toLong())
        output.write(value)
    }

    // GF-01282 — Encode UTF-8 CBOR text according to RFC 8949.
    private fun writeTextString(output: ByteArrayOutputStream, value: String) {
        val bytes = value.toByteArray(Charsets.UTF_8)
        writeHead(output, CBOR_TEXT_STRING, bytes.size.toLong())
        output.write(bytes)
    }

    // GF-01281 — Encode a positive or negative CBOR integer according to RFC 8949.
    private fun writeInteger(output: ByteArrayOutputStream, value: Long) {
        if (value >= 0) {
            writeHead(output, CBOR_UNSIGNED, value)
        } else {
            writeHead(output, CBOR_NEGATIVE, -1L - value)
        }
    }

    // GF-01280 — Encode a CBOR array recursively according to RFC 8949.
    private fun writeList(output: ByteArrayOutputStream, values: List<*>) {
        writeHead(output, CBOR_ARRAY, values.size.toLong())
        for (value in values) writeValue(output, value)
    }

    // GF-01279 — Encode a CBOR map recursively according to RFC 8949.
    private fun writeMap(output: ByteArrayOutputStream, values: Map<*, *>) {
        writeHead(output, CBOR_MAP, values.size.toLong())
        for ((key, value) in values) {
            writeValue(output, key)
            writeValue(output, value)
        }
    }

    // GF-01240 — RFC 8949: encode a CBOR major-type header and argument.
    private fun writeHead(output: ByteArrayOutputStream, major: Int, value: Long) {
        require(value >= 0)
        when {
            value < 24 -> output.write((major shl 5) or value.toInt())
            value <= BYTE_MAX -> writeByteArgument(output, major, value)
            value <= SHORT_MAX -> writeShortArgument(output, major, value)
            value <= INT_MAX -> writeIntArgument(output, major, value)
            else -> writeLongArgument(output, major, value)
        }
    }

    // GF-01278 — Encode an 8-bit CBOR argument.
    private fun writeByteArgument(output: ByteArrayOutputStream, major: Int, value: Long) {
        output.write((major shl 5) or ADDITIONAL_BYTE)
        output.write(value.toInt())
    }

    // GF-01277 — Encode a 16-bit CBOR argument.
    private fun writeShortArgument(output: ByteArrayOutputStream, major: Int, value: Long) {
        output.write((major shl 5) or ADDITIONAL_SHORT)
        output.write((value.toInt() ushr 8) and BYTE_MASK)
        output.write(value.toInt() and BYTE_MASK)
    }

    // GF-01276 — Encode a 32-bit CBOR argument.
    private fun writeIntArgument(output: ByteArrayOutputStream, major: Int, value: Long) {
        output.write((major shl 5) or ADDITIONAL_INT)
        for (shift in 24 downTo 0 step 8) {
            output.write(((value ushr shift) and BYTE_MASK.toLong()).toInt())
        }
    }

    // GF-01275 — Encode a 64-bit CBOR argument.
    private fun writeLongArgument(output: ByteArrayOutputStream, major: Int, value: Long) {
        output.write((major shl 5) or ADDITIONAL_LONG)
        for (shift in 56 downTo 0 step 8) {
            output.write(((value ushr shift) and BYTE_MASK.toLong()).toInt())
        }
    }

    private const val CBOR_NULL = 0xf6
    private const val CBOR_TRUE = 0xf5
    private const val CBOR_FALSE = 0xf4
    private const val CBOR_UNSIGNED = 0
    private const val CBOR_NEGATIVE = 1
    private const val CBOR_BYTE_STRING = 2
    private const val CBOR_TEXT_STRING = 3
    private const val CBOR_ARRAY = 4
    private const val CBOR_MAP = 5
    private const val ADDITIONAL_BYTE = 24
    private const val ADDITIONAL_SHORT = 25
    private const val ADDITIONAL_INT = 26
    private const val ADDITIONAL_LONG = 27
    private const val BYTE_MAX = 0xffL
    private const val SHORT_MAX = 0xffffL
    private const val INT_MAX = 0xffffffffL
    private const val BYTE_MASK = 0xff
}
