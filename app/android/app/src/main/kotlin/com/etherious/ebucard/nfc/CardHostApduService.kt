package com.etherious.ebucard.nfc

import android.nfc.cardemulation.HostApduService
import android.os.Bundle

/**
 * Emulates an NFC Forum Type 4 tag so another phone can read this user's card
 * as an NDEF message (card URL record + compact vCard record).
 *
 * Scaffold only: every command is answered with "file not found" until the
 * Type 4 tag state machine (SELECT AID, SELECT CC/NDEF file, READ BINARY) and
 * the Flutter platform channel that supplies the NDEF bytes are implemented.
 * See docs/DESIGN.md §4.
 */
class CardHostApduService : HostApduService() {

    override fun processCommandApdu(commandApdu: ByteArray, extras: Bundle?): ByteArray =
        STATUS_FILE_NOT_FOUND

    override fun onDeactivated(reason: Int) = Unit

    private companion object {
        val STATUS_FILE_NOT_FOUND = byteArrayOf(0x6A, 0x82.toByte())
    }
}
