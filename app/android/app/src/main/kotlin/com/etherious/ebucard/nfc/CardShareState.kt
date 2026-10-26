package com.etherious.ebucard.nfc

/**
 * The card currently being shared over NFC, set by the Flutter app through
 * the `ebucard/nfc` channel (see `MainActivity`).
 *
 * Null means "not sharing": the tag then answers every command with "not
 * found", so nothing is sent. It lives only in memory, so a closed or killed
 * app never shares.
 */
object CardShareState {
    /** The NDEF message to serve, or null when not sharing. */
    @Volatile
    var ndefMessage: ByteArray? = null
}
