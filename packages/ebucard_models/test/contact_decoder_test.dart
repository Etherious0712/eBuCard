import 'package:ebucard_models/ebucard_models.dart';
import 'package:test/test.dart';

const _decoder = ContactDecoder();
final _now = DateTime.utc(2026, 10, 26);

/// Decodes [text] with a fixed id and time.
BusinessCard? _decode(String text) =>
    _decoder.decode(text, id: 'r1', now: _now);

void main() {
  test('round-trips a full card written by VCardEncoder', () {
    final card = BusinessCard(
      id: 'own',
      cardName: 'Work',
      fullName: '陳大文 Tai Man Chan',
      jobTitle: 'Director, Sales',
      company: 'Example; Ltd',
      phones: const [
        LabeledValue(label: ContactLabel.mobile, value: '+852 9123 4567'),
        LabeledValue(label: ContactLabel.fax, value: '+852 2123 0000'),
      ],
      emails: const [
        LabeledValue(label: ContactLabel.work, value: 'tm@example.com'),
      ],
      websites: const ['https://example.com'],
      addresses: const [
        PostalAddress(
          street: "1 Queen's Road",
          city: 'Hong Kong',
          country: 'HK',
        ),
      ],
      socialLinks: const [
        SocialLink(
          network: SocialNetwork.linkedin,
          handleOrUrl: 'https://linkedin.com/in/tm',
        ),
      ],
      updatedAt: DateTime.utc(2026),
    );
    final text = const VCardEncoder().encode(card, includeImages: false);
    final decoded = _decode(text)!;

    expect(decoded.id, 'r1');
    expect(decoded.cardName, isEmpty, reason: 'card names are never shared');
    expect(decoded.fullName, card.fullName);
    expect(decoded.jobTitle, card.jobTitle);
    expect(decoded.company, card.company);
    expect(decoded.phones, card.phones);
    expect(decoded.emails, card.emails);
    expect(decoded.websites, card.websites);
    expect(decoded.addresses, card.addresses);
    expect(decoded.socialLinks, card.socialLinks);
  });

  test('reads vCard 2.1 with bare types and quoted-printable UTF-8', () {
    const text =
        'BEGIN:VCARD\r\n'
        'VERSION:2.1\r\n'
        'N;CHARSET=UTF-8;ENCODING=QUOTED-PRINTABLE:=E9=99=B3;=E5=A4=A7=E6=96=87\r\n'
        'TEL;WORK;VOICE:2123 4567\r\n'
        'TEL;CELL:9123 4567\r\n'
        'EMAIL;INTERNET:a@b.com\r\n'
        'END:VCARD';
    final card = _decode(text)!;
    expect(card.fullName, '大文 陳');
    expect(card.phones, const [
      LabeledValue(label: ContactLabel.work, value: '2123 4567'),
      LabeledValue(label: ContactLabel.mobile, value: '9123 4567'),
    ]);
    expect(card.emails.single.label, ContactLabel.other);
  });

  test('reads vCard 4.0 with tel: URIs, groups and folded lines', () {
    const text =
        'BEGIN:VCARD\n'
        'VERSION:4.0\n'
        'FN:Jane\n'
        '  Doe\n'
        'item1.TEL;TYPE="cell,voice";VALUE=uri:tel:+1-555-0100\n'
        'PHOTO:https://tracker.example/p.jpg\n'
        'END:VCARD\n';
    final card = _decode(text)!;
    expect(card.fullName, 'Jane Doe');
    expect(
      card.phones.single,
      const LabeledValue(label: ContactLabel.mobile, value: '+1-555-0100'),
    );
    expect(card.photoUrl, isNull, reason: 'received images are ignored');
  });

  test('reads MECARD', () {
    final card = _decode(
      r'MECARD:N:Doe,John;ORG:Acme\; Inc;TEL:+15550100;EMAIL:john@acme.com;URL:https://acme.com;ADR:1 Main St;;',
    )!;
    expect(card.fullName, 'John Doe');
    expect(card.company, 'Acme; Inc');
    expect(card.phones.single.value, '+15550100');
    expect(card.emails.single.value, 'john@acme.com');
    expect(card.websites, ['https://acme.com']);
    expect(card.addresses.single.street, '1 Main St');
  });

  test('falls back to company or email when there is no name', () {
    expect(_decode('BEGIN:VCARD\nORG:Acme\nEND:VCARD')!.fullName, 'Acme');
    expect(
      _decode('BEGIN:VCARD\nEMAIL:a@b.com\nEND:VCARD')!.fullName,
      'a@b.com',
    );
  });

  test('rejects text that is not a contact', () {
    expect(_decode('https://example.com'), isNull);
    expect(_decode('hello'), isNull);
    expect(_decode('BEGIN:VCARD\nFN:Cut off'), isNull, reason: 'no END');
    expect(_decode('BEGIN:VCARD\nNOTE:nothing\nEND:VCARD'), isNull);
    expect(_decode('MECARD:NOTE:hi;;'), isNull);
  });
}
