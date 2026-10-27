// NFC access for the app: is NFC available, share a card (Android only),
// and read a card from another phone (Android and iPhone).
//
// Sharing goes through the `ebucard/nfc` method channel to MainActivity.kt,
// which makes the phone act as an NFC tag (CardHostApduService.kt).
// Reading uses the nfc_manager plugin.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ndef_record/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';

/// Whether this phone has NFC and whether it is switched on.
enum NfcState {
  /// No NFC hardware (or not a phone).
  unsupported,

  /// NFC hardware present but switched off in settings.
  off,

  /// NFC is on.
  on,
}

/// What this phone can do with NFC right now.
class NfcStatus {
  /// Creates a status.
  const NfcStatus({required this.state, required this.canShare});

  /// Hardware/settings state.
  final NfcState state;

  /// Whether this phone can act as an NFC tag to share a card (Android with
  /// card emulation). Always false on iPhone.
  final bool canShare;

  /// No NFC at all.
  static const unsupported = NfcStatus(
    state: NfcState.unsupported,
    canShare: false,
  );
}

/// The NFC operations the screens use. Tests replace it with a fake.
abstract class NfcService {
  /// Current NFC state. Check again after the user returns from settings.
  Future<NfcStatus> status();

  /// Starts serving [ndefMessage] to phones held against this one (Android).
  Future<void> startSharing(Uint8List ndefMessage);

  /// Stops serving the card.
  Future<void> stopSharing();

  /// Opens the phone's NFC settings (Android).
  Future<void> openSettings();

  /// Waits for another phone (or a tag) and calls [onMessage] with the NDEF
  /// message it holds, or null if it holds none.
  ///
  /// On iPhone this shows the system "Ready to Scan" sheet with
  /// [iosAlertMessage]; [onCancelledIos] is called if the user closes it or
  /// it times out. On Android the phone keeps listening until
  /// [stopReading].
  Future<void> startReading({
    required void Function(NdefMessage? message) onMessage,
    required String iosAlertMessage,
    VoidCallback? onCancelledIos,
  });

  /// Stops listening. On iPhone the sheet shows [iosSuccessMessage] (or
  /// [iosErrorMessage]) as it closes.
  Future<void> stopReading({
    String? iosSuccessMessage,
    String? iosErrorMessage,
  });
}

/// The real [NfcService].
class DeviceNfcService implements NfcService {
  static const _channel = MethodChannel('ebucard/nfc');

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;
  bool get _isIos => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Future<NfcStatus> status() async {
    if (_isAndroid) {
      final result = await _channel.invokeMapMethod<String, Object?>('status');
      final state = switch (result?['nfc']) {
        'on' => NfcState.on,
        'off' => NfcState.off,
        _ => NfcState.unsupported,
      };
      return NfcStatus(state: state, canShare: result?['hce'] == true);
    }
    if (_isIos) {
      final availability = await NfcManager.instance.checkAvailability();
      return NfcStatus(
        state: switch (availability) {
          NfcAvailability.enabled => NfcState.on,
          NfcAvailability.disabled => NfcState.off,
          NfcAvailability.unsupported => NfcState.unsupported,
        },
        canShare: false,
      );
    }
    return NfcStatus.unsupported;
  }

  @override
  Future<void> startSharing(Uint8List ndefMessage) async {
    if (_isAndroid) await _channel.invokeMethod('startSharing', ndefMessage);
  }

  @override
  Future<void> stopSharing() async {
    if (_isAndroid) await _channel.invokeMethod('stopSharing');
  }

  @override
  Future<void> openSettings() async {
    if (_isAndroid) await _channel.invokeMethod('openSettings');
  }

  @override
  Future<void> startReading({
    required void Function(NdefMessage? message) onMessage,
    required String iosAlertMessage,
    VoidCallback? onCancelledIos,
  }) => NfcManager.instance.startSession(
    // Phones sharing a card look like ISO 14443-4 (Type 4) tags.
    pollingOptions: {NfcPollingOption.iso14443},
    alertMessageIos: iosAlertMessage,
    onSessionErrorIos: (_) => onCancelledIos?.call(),
    onDiscovered: (tag) async {
      final ndef = Ndef.from(tag);
      if (ndef == null) {
        onMessage(null);
        return;
      }
      try {
        onMessage(ndef.cachedMessage ?? await ndef.read());
      } on PlatformException {
        // The phones moved apart mid-read.
        onMessage(null);
      }
    },
  );

  @override
  Future<void> stopReading({
    String? iosSuccessMessage,
    String? iosErrorMessage,
  }) => NfcManager.instance.stopSession(
    alertMessageIos: iosSuccessMessage,
    errorMessageIos: iosErrorMessage,
  );
}
