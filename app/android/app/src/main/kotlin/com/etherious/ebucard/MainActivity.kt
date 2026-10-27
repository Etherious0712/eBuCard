package com.etherious.ebucard

import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.nfc.NfcAdapter
import android.nfc.cardemulation.CardEmulation
import android.provider.Settings
import com.etherious.ebucard.nfc.CardHostApduService
import com.etherious.ebucard.nfc.CardShareState
import com.etherious.ebucard.nfc.Type4Tag
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * The Flutter host activity. Also answers the `ebucard/nfc` channel used by
 * `lib/src/data/nfc_service.dart` to share a card over NFC:
 *
 * * `status` → `{"nfc": "unsupported" | "off" | "on", "hce": Boolean}`
 * * `startSharing(bytes)` → serve these NDEF bytes from [CardHostApduService]
 * * `stopSharing` → stop serving
 * * `openSettings` → open the system NFC settings screen
 *
 * Sharing always stops when the activity is paused, so the card is never
 * sent while eBuCard is in the background; the Flutter screen starts it again
 * when the app comes back.
 */
class MainActivity : FlutterActivity() {

    /** Whether the Flutter app asked to share and the activity is in front. */
    private var sharing = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler(::onMethodCall)
    }

    /** Dispatches one call from the Flutter side. */
    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "status" -> result.success(status())
            "startSharing" -> {
                val bytes = call.arguments as? ByteArray
                if (bytes == null || bytes.size > Type4Tag.MAX_MESSAGE_SIZE) {
                    result.error("bad_message", "Missing or too large NDEF message", null)
                    return
                }
                CardShareState.ndefMessage = bytes
                sharing = true
                preferOurService(true)
                result.success(null)
            }
            "stopSharing" -> {
                stopSharing()
                result.success(null)
            }
            "openSettings" -> {
                openNfcSettings()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    /** NFC hardware state and whether card emulation (HCE) is available. */
    private fun status(): Map<String, Any> {
        val adapter = NfcAdapter.getDefaultAdapter(this)
        val nfc = when {
            adapter == null -> "unsupported"
            !adapter.isEnabled -> "off"
            else -> "on"
        }
        val hce = packageManager.hasSystemFeature(PackageManager.FEATURE_NFC_HOST_CARD_EMULATION)
        return mapOf("nfc" to nfc, "hce" to hce)
    }

    /** Clears the shared card and gives up priority for our tag service. */
    private fun stopSharing() {
        CardShareState.ndefMessage = null
        sharing = false
        preferOurService(false)
    }

    /**
     * While sharing, asks Android to route the NDEF AID to us even if another
     * app registered the same AID. Android only honours this for the
     * foreground activity, so it is undone in [onPause].
     */
    private fun preferOurService(prefer: Boolean) {
        val adapter = NfcAdapter.getDefaultAdapter(this) ?: return
        if (!packageManager.hasSystemFeature(PackageManager.FEATURE_NFC_HOST_CARD_EMULATION)) return
        val emulation = CardEmulation.getInstance(adapter)
        try {
            if (prefer) {
                emulation.setPreferredService(this, ComponentName(this, CardHostApduService::class.java))
            } else {
                emulation.unsetPreferredService(this)
            }
        } catch (e: IllegalArgumentException) {
            // Not in the foreground or service not registered; the default
            // routing still reaches our service in most cases.
        }
    }

    /** Opens the NFC settings screen, or general wireless settings if absent. */
    private fun openNfcSettings() {
        try {
            startActivity(Intent(Settings.ACTION_NFC_SETTINGS))
        } catch (e: android.content.ActivityNotFoundException) {
            startActivity(Intent(Settings.ACTION_WIRELESS_SETTINGS))
        }
    }

    override fun onPause() {
        if (sharing) stopSharing()
        super.onPause()
    }

    private companion object {
        const val CHANNEL = "ebucard/nfc"
    }
}
