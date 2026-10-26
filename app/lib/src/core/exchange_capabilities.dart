// Which ways of sending and receiving a card this phone supports. The
// Exchange screen shows only these options.

import 'package:flutter/foundation.dart';

/// Ways this device can hand its card to another phone.
enum SendMethod {
  /// The phone acts as an NFC tag holding the card (Android only).
  nfcHce,

  /// The phone shows a QR code for the other phone to scan.
  qrCode,
}

/// Ways this device can receive a card from another phone.
enum ReceiveMethod {
  /// Read the card from another phone's NFC tag emulation.
  nfcRead,

  /// Scan a QR code shown by another phone.
  qrScan,
}

/// Which exchange methods are available, per docs/DESIGN.md §3.
///
/// * Android sends by NFC using Host Card Emulation (the phone acts as an NFC
///   Forum Type 4 tag), and can always fall back to showing a QR code.
/// * iPhone sends by showing a QR code only. iOS card emulation is limited by
///   region and Apple entitlement, so it is not used.
/// * Both platforms can read NFC (Android reader mode, iOS Core NFC) and scan
///   QR codes.
class ExchangeCapabilities {
  /// Creates a fixed set of capabilities (mainly for tests).
  const ExchangeCapabilities({required this.send, required this.receive});

  /// Works out the capabilities for [platform].
  ///
  /// [nfcAvailable] is whether the phone has NFC and it is switched on;
  /// [hceSupported] is whether Android card emulation is available.
  /// QR is always possible, so every phone can exchange cards.
  factory ExchangeCapabilities.resolve({
    required TargetPlatform platform,
    required bool nfcAvailable,
    required bool hceSupported,
  }) {
    final isAndroid = platform == TargetPlatform.android;
    return ExchangeCapabilities(
      send: {
        if (isAndroid && nfcAvailable && hceSupported) SendMethod.nfcHce,
        SendMethod.qrCode,
      },
      receive: {if (nfcAvailable) ReceiveMethod.nfcRead, ReceiveMethod.qrScan},
    );
  }

  /// Ways this phone can send its card.
  final Set<SendMethod> send;

  /// Ways this phone can receive a card.
  final Set<ReceiveMethod> receive;
}
