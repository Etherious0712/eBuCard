import 'dart:convert';
import 'dart:typed_data';

import 'package:ebucard_models/ebucard_models.dart';
import 'package:ndef_record/ndef_record.dart';
import 'package:test/test.dart';

final _card = BusinessCard(
  id: 'c1',
  cardName: 'Work',
  fullName: '陳大文',
  company: 'Example Ltd',
  phones: const [LabeledValue(label: ContactLabel.mobile, value: '91234567')],
  photoUrl: 'https://cdn.example.com/p.jpg',
  updatedAt: DateTime.utc(2026),
);

/// A record with the given format, ASCII [type] and [payload].
NdefRecord _record(TypeNameFormat tnf, String type, List<int> payload) =>
    NdefRecord(
      typeNameFormat: tnf,
      type: Uint8List.fromList(ascii.encode(type)),
      identifier: Uint8List(0),
      payload: Uint8List.fromList(payload),
    );

void main() {
  test('card message is a vCard record without images', () {
    final message = cardNdefMessage(_card);
    expect(message.records, hasLength(1));
    final record = message.records.single;
    expect(record.typeNameFormat, TypeNameFormat.media);
    expect(ascii.decode(record.type), 'text/vcard');
    final text = utf8.decode(record.payload);
    expect(text, contains('FN:陳大文'));
    expect(text, isNot(contains('PHOTO')));
  });

  test('with a card URL, a URI record comes first', () {
    final message = cardNdefMessage(
      _card,
      cardUrl: Uri.parse('https://card.example.com/c/abc'),
    );
    final uri = message.records.first;
    expect(ascii.decode(uri.type), 'U');
    expect(uri.payload.first, 0x04, reason: 'https:// prefix code');
    expect(utf8.decode(uri.payload.sublist(1)), 'card.example.com/c/abc');
  });

  test('bytes decode back to the same contact', () {
    final bytes = cardNdefBytes(_card);
    final text = contactTextFromNdef(NdefMessage.decode(bytes))!;
    final decoded = const ContactDecoder().decode(
      text,
      id: 'r',
      now: DateTime.utc(2026),
    )!;
    expect(decoded.fullName, '陳大文');
    expect(decoded.company, 'Example Ltd');
    expect(decoded.phones.single.value, '91234567');
  });

  test('reads text/x-vcard and vCard/MECARD text records', () {
    const vcard = 'BEGIN:VCARD\nFN:A\nEND:VCARD';
    expect(
      contactTextFromNdef(
        NdefMessage(
          records: [
            _record(TypeNameFormat.media, 'text/x-vcard', utf8.encode(vcard)),
          ],
        ),
      ),
      vcard,
    );

    // Text record: status byte 0x02 = UTF-8, 2-byte language code "en".
    final mecard = 'MECARD:N:Doe,John;;';
    expect(
      contactTextFromNdef(
        NdefMessage(
          records: [
            _record(TypeNameFormat.wellKnown, 'T', [
              0x02,
              ...ascii.encode('en'),
              ...utf8.encode(mecard),
            ]),
          ],
        ),
      ),
      mecard,
    );
  });

  test('messages without contact data give null', () {
    expect(
      contactTextFromNdef(
        NdefMessage(
          records: [
            _record(TypeNameFormat.wellKnown, 'U', [
              0x04,
              ...ascii.encode('example.com'),
            ]),
            _record(TypeNameFormat.wellKnown, 'T', [
              0x02,
              ...ascii.encode('en'),
              ...utf8.encode('hello'),
            ]),
          ],
        ),
      ),
      isNull,
    );
  });
}
