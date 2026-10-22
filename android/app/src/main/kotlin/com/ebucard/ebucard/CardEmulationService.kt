package com.ebucard.ebucard

import android.content.Context
import android.nfc.NdefMessage
import android.nfc.NdefRecord
import android.nfc.cardemulation.HostApduService
import android.os.Bundle

/**
 * Makes this phone look like an NFC Forum Type 4 tag that holds one NDEF URI
 * record: the user's card link. Any NFC phone that reads NDEF tags (Android
 * or iPhone) can read it.
 *
 * Flow a reader follows: SELECT the NDEF application, SELECT the capability
 * container (CC) file and read it, SELECT the NDEF file and read it.
 */
class CardEmulationService : HostApduService() {

    private enum class SelectedFile { NONE, CC, NDEF }

    private var selected = SelectedFile.NONE
    private var appSelected = false
    private var ndefFile: ByteArray = ByteArray(0)

    override fun processCommandApdu(apdu: ByteArray, extras: Bundle?): ByteArray {
        if (apdu.size < 4) return SW_WRONG_LENGTH
        val ins = apdu[1]
        val p1 = apdu[2]
        val p2 = apdu[3]

        return when {
            ins == INS_SELECT && p1 == 0x04.toByte() -> selectApplication(apdu)
            ins == INS_SELECT && p1 == 0x00.toByte() -> selectFile(apdu)
            ins == INS_READ_BINARY -> readBinary(p1, p2, apdu)
            else -> SW_INS_NOT_SUPPORTED
        }
    }

    override fun onDeactivated(reason: Int) {
        selected = SelectedFile.NONE
        appSelected = false
    }

    private fun selectApplication(apdu: ByteArray): ByteArray {
        if (apdu.size < 5 + NDEF_AID.size) return SW_FILE_NOT_FOUND
        val aid = apdu.copyOfRange(5, 5 + apdu[4].toInt())
        if (!aid.contentEquals(NDEF_AID)) return SW_FILE_NOT_FOUND

        val url = cardUrl(this)
        if (url == null) {
            // Not sharing right now: behave like there is no tag here.
            appSelected = false
            return SW_FILE_NOT_FOUND
        }
        ndefFile = buildNdefFile(url)
        appSelected = true
        selected = SelectedFile.NONE
        return SW_OK
    }

    private fun selectFile(apdu: ByteArray): ByteArray {
        if (!appSelected || apdu.size < 7) return SW_FILE_NOT_FOUND
        val fileId = apdu.copyOfRange(5, 7)
        selected = when {
            fileId.contentEquals(CC_FILE_ID) -> SelectedFile.CC
            fileId.contentEquals(NDEF_FILE_ID) -> SelectedFile.NDEF
            else -> return SW_FILE_NOT_FOUND
        }
        return SW_OK
    }

    private fun readBinary(p1: Byte, p2: Byte, apdu: ByteArray): ByteArray {
        val file = when (selected) {
            SelectedFile.CC -> capabilityContainer(ndefFile.size)
            SelectedFile.NDEF -> ndefFile
            SelectedFile.NONE -> return SW_FILE_NOT_FOUND
        }
        val offset = ((p1.toInt() and 0x7F) shl 8) or (p2.toInt() and 0xFF)
        if (offset > file.size) return SW_WRONG_P1P2
        // Le of 0 means 256 bytes in short APDUs.
        val le = if (apdu.size >= 5) (apdu[4].toInt() and 0xFF).let { if (it == 0) 256 else it } else 256
        val end = minOf(file.size, offset + le, offset + MAX_READ)
        return file.copyOfRange(offset, end) + SW_OK
    }

    companion object {
        private const val PREFS = "ebucard_hce"
        private const val KEY_URL = "card_url"
        private const val KEY_SHARING = "sharing"

        // Largest chunk we answer per READ BINARY; also advertised as MLe.
        private const val MAX_READ = 0xF6

        private const val INS_SELECT: Byte = 0xA4.toByte()
        private const val INS_READ_BINARY: Byte = 0xB0.toByte()

        private val NDEF_AID = byteArrayOf(0xD2.toByte(), 0x76, 0x00, 0x00, 0x85.toByte(), 0x01, 0x01)
        private val CC_FILE_ID = byteArrayOf(0xE1.toByte(), 0x03)
        private val NDEF_FILE_ID = byteArrayOf(0xE1.toByte(), 0x04)

        private val SW_OK = byteArrayOf(0x90.toByte(), 0x00)
        private val SW_FILE_NOT_FOUND = byteArrayOf(0x6A, 0x82.toByte())
        private val SW_WRONG_P1P2 = byteArrayOf(0x6B, 0x00)
        private val SW_WRONG_LENGTH = byteArrayOf(0x67, 0x00)
        private val SW_INS_NOT_SUPPORTED = byteArrayOf(0x6D, 0x00)

        fun setCard(context: Context, url: String?, sharing: Boolean) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .putString(KEY_URL, url)
                .putBoolean(KEY_SHARING, sharing)
                .apply()
        }

        private fun cardUrl(context: Context): String? {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            if (!prefs.getBoolean(KEY_SHARING, false)) return null
            return prefs.getString(KEY_URL, null)
        }

        /** NDEF file = 2-byte length (NLEN) followed by the NDEF message. */
        private fun buildNdefFile(url: String): ByteArray {
            val message = NdefMessage(NdefRecord.createUri(url)).toByteArray()
            return byteArrayOf((message.size shr 8).toByte(), message.size.toByte()) + message
        }

        /** 15-byte capability container describing one read-only NDEF file. */
        private fun capabilityContainer(ndefFileSize: Int): ByteArray {
            val maxSize = maxOf(ndefFileSize, 0x0100)
            return byteArrayOf(
                0x00, 0x0F, // CC length
                0x20, // mapping version 2.0
                0x00, MAX_READ.toByte(), // MLe: max bytes per READ BINARY
                0x00, 0xFF.toByte(), // MLc: max bytes per UPDATE BINARY (unused)
                0x04, 0x06, // NDEF File Control TLV
                0xE1.toByte(), 0x04, // NDEF file id
                (maxSize shr 8).toByte(), maxSize.toByte(), // max NDEF file size
                0x00, // read access: granted
                0xFF.toByte(), // write access: denied
            )
        }
    }
}
