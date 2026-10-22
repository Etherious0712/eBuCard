import 'package:ebucard/src/business_card.dart';
import 'package:ebucard/src/nfc_receive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndef_record/ndef_record.dart';

import 'dart:convert';
import 'dart:typed_data';

void main() {
  const card = BusinessCard(
    name: 'Zoë Tanaka',
    title: 'Head of Sales',
    company: 'Acme',
    phone: '+1 555 0100',
    email: 'zoe@example.com',
  );

  test('card survives a round trip through its link', () {
    final link = card.toLink();
    expect(link, startsWith('$cardLinkBase#'));
    expect(link, isNot(contains('=')));

    final back = BusinessCard.fromLink(link)!;
    expect(back.name, card.name);
    expect(back.title, card.title);
    expect(back.company, card.company);
    expect(back.phone, card.phone);
    expect(back.email, card.email);
    expect(back.website, '');
  });

  test('foreign or broken links are rejected', () {
    expect(BusinessCard.fromLink('https://example.org/x#abc'), isNull);
    expect(BusinessCard.fromLink('$cardLinkBase#!!!notbase64'), isNull);
    expect(BusinessCard.fromLink(cardLinkBase), isNull);
  });

  test('link fits comfortably in one NFC read', () {
    // Android answers up to 246 bytes per read; a typical card should not
    // need many round trips.
    expect(card.toLink().length, lessThan(400));
  });

  test('URI records decode with their prefix', () {
    final record = NdefRecord(
      typeNameFormat: TypeNameFormat.wellKnown,
      type: Uint8List.fromList([0x55]),
      identifier: Uint8List(0),
      payload: Uint8List.fromList([
        0x04,
        ...utf8.encode('example.com/ebucard/c#e30'),
      ]),
    );
    expect(decodeUriRecord(record), 'https://example.com/ebucard/c#e30');
  });
}
