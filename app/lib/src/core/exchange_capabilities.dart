import 'package:flutter/foundation.dart';

/// Ways this device can hand its card to another phone.
enum SendMethod { nfcHce, qrCode }

/// Ways this device can receive a card from another phone.
enum ReceiveMethod { nfcRead, qrScan }

/// Which exchange methods are available, per docs/DESIGN.md §3.
///
/// * Android sends by NFC using Host Card Emulation (the phone acts as an NFC
///   Forum Type 4 tag), and can always fall back to showing a QR code.
/// * iPhone sends by showing a QR code only. iOS card emulation is limited by
///   region and Apple entitlement, so it is not used.
/// * Both platforms can read NFC (Android reader mode, iOS Core NFC) and scan
///   QR codes.
class ExchangeCapabilities {
  const ExchangeCapabilities({required this.send, required this.receive});

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

  final Set<SendMethod> send;
  final Set<ReceiveMethod> receive;
}
