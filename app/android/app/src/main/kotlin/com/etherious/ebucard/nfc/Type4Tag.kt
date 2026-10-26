package com.etherious.ebucard.nfc

/**
 * A read-only NFC Forum Type 4 Tag (mapping version 2.0) holding one NDEF
 * message: the card being shared.
 *
 * A reader (another Android phone, or an iPhone) talks to it with ISO 7816-4
 * APDUs in this order:
 *  1. SELECT the NDEF Tag Application (AID `D2760000850101`).
 *  2. SELECT the Capability Container file (`E103`) and READ BINARY it to
 *     learn where the NDEF file is and how big it may be.
 *  3. SELECT the NDEF file (`E104`) and READ BINARY: two length bytes, then
 *     the NDEF message.
 *
 * This class has no Android dependencies so it can be unit tested on a plain
 * JVM (see `Type4TagTest`). One instance serves one tap: create a new one
 * when the reader goes away.
 */
class Type4Tag(ndefMessage: ByteArray) {

    init {
        require(ndefMessage.size <= MAX_MESSAGE_SIZE) {
            "NDEF message is ${ndefMessage.size} bytes; the limit is $MAX_MESSAGE_SIZE"
        }
    }

    /** NDEF file: 2-byte big-endian length (NLEN) followed by the message. */
    private val ndefFile: ByteArray =
        byteArrayOf((ndefMessage.size shr 8).toByte(), ndefMessage.size.toByte()) + ndefMessage

    /** Capability Container: tells the reader where the NDEF file is. */
    private val ccFile: ByteArray = byteArrayOf(
        0x00, 0x0F, // CCLEN: 15 bytes
        0x20, // mapping version 2.0
        0x00, MAX_RESPONSE_DATA.toByte(), // MLe: max bytes per READ BINARY
        0x00, 0xFF.toByte(), // MLc: max bytes per write (writes are refused)
        0x04, 0x06, // NDEF File Control TLV, 6 bytes
        NDEF_FILE_ID[0], NDEF_FILE_ID[1],
        (ndefFile.size shr 8).toByte(), ndefFile.size.toByte(), // max NDEF file size
        0x00, // read access: allowed
        0xFF.toByte(), // write access: none (read-only tag)
    )

    /** Whether the reader has selected the NDEF Tag Application yet. */
    private var applicationSelected = false

    /** The file the next READ BINARY reads, or null if none is selected. */
    private var selectedFile: ByteArray? = null

    /** Handles one command APDU and returns the response APDU. */
    fun process(apdu: ByteArray): ByteArray {
        if (apdu.size < 4) return SW_WRONG_LENGTH
        if (apdu[0] != 0x00.toByte()) return SW_CLA_NOT_SUPPORTED
        return when (apdu[1]) {
            INS_SELECT -> select(apdu)
            INS_READ_BINARY -> readBinary(apdu)
            INS_UPDATE_BINARY -> SW_SECURITY_NOT_SATISFIED
            else -> SW_INS_NOT_SUPPORTED
        }
    }

    /** SELECT by application name (P1 = 04) or by file id (P1 = 00). */
    private fun select(apdu: ByteArray): ByteArray {
        val data = commandData(apdu) ?: return SW_WRONG_LENGTH
        return when (apdu[2]) {
            0x04.toByte() -> {
                if (!data.contentEquals(NDEF_APPLICATION_ID)) {
                    applicationSelected = false
                    selectedFile = null
                    return SW_FILE_NOT_FOUND
                }
                applicationSelected = true
                selectedFile = null
                SW_OK
            }
            0x00.toByte() -> {
                selectedFile = when {
                    !applicationSelected -> null
                    data.contentEquals(CC_FILE_ID) -> ccFile
                    data.contentEquals(NDEF_FILE_ID) -> ndefFile
                    else -> null
                }
                if (selectedFile == null) SW_FILE_NOT_FOUND else SW_OK
            }
            else -> SW_WRONG_P1P2
        }
    }

    /** READ BINARY: P1P2 is the offset, Le the number of bytes wanted. */
    private fun readBinary(apdu: ByteArray): ByteArray {
        val file = selectedFile ?: return SW_FILE_NOT_FOUND
        val offset = ((apdu[2].toInt() and 0x7F) shl 8) or (apdu[3].toInt() and 0xFF)
        if (offset > file.size) return SW_WRONG_P1P2
        // Le = 0 means "up to 256"; a missing Le means the same.
        val requested = if (apdu.size >= 5) (apdu[4].toInt() and 0xFF).let { if (it == 0) 256 else it } else 256
        val length = minOf(requested, MAX_RESPONSE_DATA, file.size - offset)
        return file.copyOfRange(offset, offset + length) + SW_OK
    }

    /** The data field of a command with Lc, or null if the lengths don't add up. */
    private fun commandData(apdu: ByteArray): ByteArray? {
        if (apdu.size < 5) return null
        val lc = apdu[4].toInt() and 0xFF
        if (apdu.size < 5 + lc) return null
        return apdu.copyOfRange(5, 5 + lc)
    }

    companion object {
        /** NFC Forum NDEF Tag Application, as registered in `apduservice.xml`. */
        val NDEF_APPLICATION_ID = byteArrayOf(0xD2.toByte(), 0x76, 0x00, 0x00, 0x85.toByte(), 0x01, 0x01)

        /** Capability Container file id. */
        val CC_FILE_ID = byteArrayOf(0xE1.toByte(), 0x03)

        /** NDEF file id. */
        val NDEF_FILE_ID = byteArrayOf(0xE1.toByte(), 0x04)

        /** Most data bytes sent in one READ BINARY response (MLe). */
        const val MAX_RESPONSE_DATA = 0xFF

        /** Largest NDEF message this tag can hold (NDEF file ≤ 0x7FFF). */
        const val MAX_MESSAGE_SIZE = 0x7FFF - 2

        private const val INS_SELECT: Byte = 0xA4.toByte()
        private const val INS_READ_BINARY: Byte = 0xB0.toByte()
        private const val INS_UPDATE_BINARY: Byte = 0xD6.toByte()

        /** Success. */
        val SW_OK = byteArrayOf(0x90.toByte(), 0x00)

        /** Application or file not found; also sent when nothing is shared. */
        val SW_FILE_NOT_FOUND = byteArrayOf(0x6A, 0x82.toByte())

        /** Wrong P1/P2 (e.g. offset past the end of the file). */
        val SW_WRONG_P1P2 = byteArrayOf(0x6B, 0x00)

        /** Wrong length. */
        val SW_WRONG_LENGTH = byteArrayOf(0x67, 0x00)

        /** Instruction not supported. */
        val SW_INS_NOT_SUPPORTED = byteArrayOf(0x6D, 0x00)

        /** Class not supported. */
        val SW_CLA_NOT_SUPPORTED = byteArrayOf(0x6E, 0x00)

        /** Writes are refused: this tag is read-only. */
        val SW_SECURITY_NOT_SATISFIED = byteArrayOf(0x69, 0x82.toByte())
    }
}
