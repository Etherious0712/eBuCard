import 'dart:io';

import 'package:flutter/services.dart';

/// Talks to the Android tag emulation service (CardEmulationService.kt).
/// While sharing is on, another phone that taps this one reads [url].
/// iPhones can't emulate a tag, so this is a no-op there.
class NfcShare {
  static const _channel = MethodChannel('com.ebucard/hce');

  Future<bool> isSupported() async {
    if (!Platform.isAndroid) return false;
    return await _channel.invokeMethod<bool>('isSupported') ?? false;
  }

  Future<void> setCard(String? url, {required bool sharing}) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod('setCard', {'url': url, 'sharing': sharing});
  }
}
