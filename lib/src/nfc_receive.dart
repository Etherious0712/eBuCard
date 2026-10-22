import 'dart:convert';

import 'package:ndef_record/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';

/// Reads a card link from a tapped phone (or NFC tag).
class NfcReceive {
  Future<bool> isAvailable() async =>
      await NfcManager.instance.checkAvailability() == NfcAvailability.enabled;

  /// Starts listening. [onLink] gets the first URI found on each tap;
  /// [onError] gets a short message when a tap can't be read.
  Future<void> start({
    required void Function(String link) onLink,
    required void Function(String message) onError,
  }) {
    return NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443},
      alertMessageIos: 'Hold your iPhone near the other phone',
      onDiscovered: (tag) async {
        final ndef = Ndef.from(tag);
        if (ndef == null) {
          onError('That phone or tag has no card on it.');
          return;
        }
        final message = ndef.cachedMessage ?? await ndef.read();
        final link = message == null ? null : _firstUri(message);
        if (link == null) {
          onError('No card link found.');
          return;
        }
        onLink(link);
      },
      onSessionErrorIos: (error) {
        // Closing the sheet or reading successfully also ends the session.
        const quiet = {
          NfcReaderErrorCodeIos.readerSessionInvalidationErrorUserCanceled,
          NfcReaderErrorCodeIos.readerSessionInvalidationErrorFirstNDEFTagRead,
        };
        if (!quiet.contains(error.code)) onError(error.message);
      },
    );
  }

  Future<void> stop() => NfcManager.instance.stopSession();

  static String? _firstUri(NdefMessage message) {
    for (final record in message.records) {
      final uri = decodeUriRecord(record);
      if (uri != null) return uri;
    }
    return null;
  }
}

const _uriPrefixes = [
  '',
  'http://www.',
  'https://www.',
  'http://',
  'https://',
  'tel:',
  'mailto:',
  'ftp://anonymous:anonymous@',
  'ftp://ftp.',
  'ftps://',
  'sftp://',
  'smb://',
  'nfs://',
  'ftp://',
  'dav://',
  'news:',
  'telnet://',
  'imap:',
  'rtsp://',
  'urn:',
  'pop:',
  'sip:',
  'sips:',
  'tftp:',
  'btspp://',
  'btl2cap://',
  'btgoep://',
  'tcpobex://',
  'irdaobex://',
  'file://',
  'urn:epc:id:',
  'urn:epc:tag:',
  'urn:epc:pat:',
  'urn:epc:raw:',
  'urn:epc:',
  'urn:nfc:',
];

/// Decodes an NFC Forum well-known URI record ("U"), or returns null.
String? decodeUriRecord(NdefRecord record) {
  if (record.typeNameFormat != TypeNameFormat.wellKnown) return null;
  if (record.type.length != 1 || record.type[0] != 0x55) return null;
  if (record.payload.isEmpty) return null;
  final code = record.payload[0];
  final prefix = code < _uriPrefixes.length ? _uriPrefixes[code] : '';
  return prefix + utf8.decode(record.payload.sublist(1), allowMalformed: true);
}
