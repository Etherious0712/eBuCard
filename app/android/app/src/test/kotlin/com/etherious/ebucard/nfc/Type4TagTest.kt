package com.etherious.ebucard.nfc

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * Walks through the APDU exchange a real reader (Android or iPhone) performs
 * against [Type4Tag], and checks the error cases.
 */
class Type4TagTest {

    /** Builds an APDU from hex like "00A4040007D2760000850101". */
    private fun apdu(hex: String): ByteArray =
        hex.chunked(2).map { it.toInt(16).toByte() }.toByteArray()

    private val selectApp = apdu("00A4040007D276000085010100")
    private val selectCc = apdu("00A4000C02E103")
    private val selectNdef = apdu("00A4000C02E104")

    /** READ BINARY of [length] bytes at [offset]. */
    private fun read(offset: Int, length: Int) =
        byteArrayOf(0x00, 0xB0.toByte(), (offset shr 8).toByte(), offset.toByte(), length.toByte())

    /** Response data without the trailing status word. */
    private fun data(response: ByteArray) = response.copyOfRange(0, response.size - 2)

    /** The trailing two status bytes. */
    private fun status(response: ByteArray) = response.copyOfRange(response.size - 2, response.size)

    @Test
    fun readsTheWholeMessageLikeAReader() {
        val message = ByteArray(600) { (it % 251).toByte() }
        val tag = Type4Tag(message)

        assertArrayEquals(Type4Tag.SW_OK, tag.process(selectApp))
        assertArrayEquals(Type4Tag.SW_OK, tag.process(selectCc))
        val cc = data(tag.process(read(0, 15)))
        assertEquals(15, cc.size)
        assertEquals(0x20, cc[2].toInt()) // mapping version 2.0
        assertArrayEquals(Type4Tag.NDEF_FILE_ID, cc.copyOfRange(9, 11))
        assertEquals(0xFF, cc[14].toInt() and 0xFF) // read-only

        assertArrayEquals(Type4Tag.SW_OK, tag.process(selectNdef))
        val nlen = data(tag.process(read(0, 2)))
        assertEquals(600, ((nlen[0].toInt() and 0xFF) shl 8) or (nlen[1].toInt() and 0xFF))

        // Read the message in MLe-sized chunks, as readers do.
        val out = mutableListOf<Byte>()
        var offset = 2
        while (offset < 602) {
            val response = tag.process(read(offset, Type4Tag.MAX_RESPONSE_DATA))
            assertArrayEquals(Type4Tag.SW_OK, status(response))
            val chunk = data(response)
            out += chunk.toList()
            offset += chunk.size
        }
        assertArrayEquals(message, out.toByteArray())
    }

    @Test
    fun filesCannotBeSelectedBeforeTheApplication() {
        val tag = Type4Tag(byteArrayOf(1, 2, 3))
        assertArrayEquals(Type4Tag.SW_FILE_NOT_FOUND, tag.process(selectNdef))
        assertArrayEquals(Type4Tag.SW_FILE_NOT_FOUND, tag.process(read(0, 2)))
    }

    @Test
    fun otherApplicationsAndFilesAreNotFound() {
        val tag = Type4Tag(byteArrayOf(1, 2, 3))
        assertArrayEquals(Type4Tag.SW_FILE_NOT_FOUND, tag.process(apdu("00A4040007A000000003101000")))
        tag.process(selectApp)
        assertArrayEquals(Type4Tag.SW_FILE_NOT_FOUND, tag.process(apdu("00A4000C02E105")))
    }

    @Test
    fun rejectsWritesBadOffsetsAndUnknownCommands() {
        val tag = Type4Tag(byteArrayOf(1, 2, 3))
        tag.process(selectApp)
        tag.process(selectNdef)
        assertArrayEquals(Type4Tag.SW_SECURITY_NOT_SATISFIED, tag.process(apdu("00D6000001FF")))
        assertArrayEquals(Type4Tag.SW_WRONG_P1P2, tag.process(read(100, 1)))
        assertArrayEquals(Type4Tag.SW_INS_NOT_SUPPORTED, tag.process(apdu("00CA000000")))
        assertArrayEquals(Type4Tag.SW_CLA_NOT_SUPPORTED, tag.process(apdu("80A4040000")))
        assertArrayEquals(Type4Tag.SW_WRONG_LENGTH, tag.process(apdu("00A4")))
    }

    @Test(expected = IllegalArgumentException::class)
    fun refusesMessagesTooLargeForTheTag() {
        Type4Tag(ByteArray(Type4Tag.MAX_MESSAGE_SIZE + 1))
    }
}
