package com.etherious.ebucard.nfc

import android.nfc.cardemulation.HostApduService
import android.os.Bundle

/**
 * Lets another phone read this user's card by holding the phones together.
 *
 * Android routes APDUs for the NDEF Tag Application AID (`apduservice.xml`)
 * here. The phone then behaves like an NFC Type 4 tag ([Type4Tag]) holding
 * the card's NDEF message. It only answers while the Flutter app is on the
 * "Tap phones (NFC)" screen, i.e. while [CardShareState.ndefMessage] is set.
 */
class CardHostApduService : HostApduService() {

    /** Tag state for the current tap; reset when the reader leaves. */
    private var tag: Type4Tag? = null

    /** The message [tag] was built from, to notice a card switch mid-session. */
    private var tagMessage: ByteArray? = null

    override fun processCommandApdu(commandApdu: ByteArray, extras: Bundle?): ByteArray {
        val message = CardShareState.ndefMessage ?: return Type4Tag.SW_FILE_NOT_FOUND
        val current = tag
        val active = if (current != null && tagMessage === message) {
            current
        } else {
            Type4Tag(message).also {
                tag = it
                tagMessage = message
            }
        }
        return active.process(commandApdu)
    }

    override fun onDeactivated(reason: Int) {
        tag = null
        tagMessage = null
    }
}
