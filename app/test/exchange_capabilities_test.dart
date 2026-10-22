import 'package:ebucard/src/core/exchange_capabilities.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android with NFC + HCE can send by NFC and QR', () {
    final caps = ExchangeCapabilities.resolve(
      platform: TargetPlatform.android,
      nfcAvailable: true,
      hceSupported: true,
    );
    expect(caps.send, {SendMethod.nfcHce, SendMethod.qrCode});
    expect(caps.receive, {ReceiveMethod.nfcRead, ReceiveMethod.qrScan});
  });

  test('Android without HCE falls back to QR for sending', () {
    final caps = ExchangeCapabilities.resolve(
      platform: TargetPlatform.android,
      nfcAvailable: true,
      hceSupported: false,
    );
    expect(caps.send, {SendMethod.qrCode});
  });

  test('iPhone sends by QR only but can read NFC', () {
    final caps = ExchangeCapabilities.resolve(
      platform: TargetPlatform.iOS,
      nfcAvailable: true,
      hceSupported: true,
    );
    expect(caps.send, {SendMethod.qrCode});
    expect(caps.receive, {ReceiveMethod.nfcRead, ReceiveMethod.qrScan});
  });

  test('no NFC hardware means QR only', () {
    final caps = ExchangeCapabilities.resolve(
      platform: TargetPlatform.android,
      nfcAvailable: false,
      hceSupported: false,
    );
    expect(caps.send, {SendMethod.qrCode});
    expect(caps.receive, {ReceiveMethod.qrScan});
  });
}
