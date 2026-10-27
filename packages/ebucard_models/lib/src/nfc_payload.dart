// The NDEF message an Android phone serves over NFC, and how a receiving
// phone gets contact text back out of whatever NDEF message it reads.

import 'dart:convert';
import 'dart:typed_data';

import 'package:ndef_record/ndef_record.dart';

import 'business_card.dart';
import 'vcard_encoder.dart';

/// MIME types of vCard records. `text/x-vcard` is the older spelling that
/// some phones still write.
const _vcardMimeTypes = {'text/vcard', 'text/x-vcard', 'text/directory'};

/// NDEF well-known type "U" (URI record).
final _uriType = Uint8List.fromList([0x55]);

/// NDEF well-known type "T" (text record).
final _textType = Uint8List.fromList([0x54]);

/// Builds the NDEF message for sharing [card] over NFC (DESIGN.md §4.2):
///
/// 1. A URI record with [cardUrl], when the card has a public link.
/// 2. A `text/vcard` record with the full vCard without images, so the
///    exchange also works offline and with phones that don't have eBuCard.
NdefMessage cardNdefMessage(
  BusinessCard card, {
  Uri? cardUrl,
  VCardEncoder encoder = const VCardEncoder(),
}) => NdefMessage(
  records: [
    if (cardUrl != null) _uriRecord(cardUrl),
    NdefRecord(
      typeNameFormat: TypeNameFormat.media,
      type: Uint8List.fromList(ascii.encode('text/vcard')),
      identifier: Uint8List(0),
      payload: Uint8List.fromList(
        utf8.encode(encoder.encode(card, includeImages: false)),
      ),
    ),
  ],
);

/// The bytes of [cardNdefMessage], as stored in the emulated tag's NDEF file.
Uint8List cardNdefBytes(BusinessCard card, {Uri? cardUrl}) =>
    cardNdefMessage(card, cardUrl: cardUrl).encode();

/// Finds contact text (a vCard or MECARD) in [message], for `ContactDecoder`.
///
/// Looks at vCard MIME records first, then text records that contain a
/// vCard or MECARD. Returns null if the message has no contact data (e.g. a
/// tag that only holds a web link).
String? contactTextFromNdef(NdefMessage message) {
  for (final record in message.records) {
    if (record.typeNameFormat == TypeNameFormat.media &&
        _vcardMimeTypes.contains(ascii.decode(record.type).toLowerCase())) {
      return utf8.decode(record.payload, allowMalformed: true);
    }
  }
  for (final record in message.records) {
    if (record.typeNameFormat == TypeNameFormat.wellKnown &&
        _sameBytes(record.type, _textType) &&
        record.payload.isNotEmpty) {
      // Text record: status byte (bit 7 = UTF-16, bits 0–5 = language
      // code length), language code, then the text.
      final status = record.payload.first;
      final start = 1 + (status & 0x3F);
      if (start > record.payload.length) continue;
      final bytes = record.payload.sublist(start);
      final text = (status & 0x80) != 0
          ? String.fromCharCodes(_utf16be(bytes))
          : utf8.decode(bytes, allowMalformed: true);
      final upper = text.trimLeft().toUpperCase();
      if (upper.startsWith('BEGIN:VCARD') || upper.startsWith('MECARD:')) {
        return text;
      }
    }
  }
  return null;
}

/// A URI record for [uri], using the `https://` / `http://` prefix codes
/// from the NFC Forum URI record spec to save space.
NdefRecord _uriRecord(Uri uri) {
  final text = uri.toString();
  var code = 0x00;
  var rest = text;
  if (text.startsWith('https://')) {
    code = 0x04;
    rest = text.substring(8);
  } else if (text.startsWith('http://')) {
    code = 0x03;
    rest = text.substring(7);
  }
  return NdefRecord(
    typeNameFormat: TypeNameFormat.wellKnown,
    type: _uriType,
    identifier: Uint8List(0),
    payload: Uint8List.fromList([code, ...utf8.encode(rest)]),
  );
}

/// Byte-for-byte equality.
bool _sameBytes(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Big-endian UTF-16 code units from [bytes], skipping a byte-order mark.
List<int> _utf16be(List<int> bytes) {
  final units = <int>[
    for (var i = 0; i + 1 < bytes.length; i += 2)
      (bytes[i] << 8) | bytes[i + 1],
  ];
  return units.isNotEmpty && units.first == 0xFEFF ? units.sublist(1) : units;
}
