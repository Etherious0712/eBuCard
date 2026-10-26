import 'package:ebucard_models/ebucard_models.dart';
import 'package:test/test.dart';

void main() {
  final card = BusinessCard(
    id: 'c1',
    cardName: 'Work',
    fullName: 'Tai Man Chan',
    jobTitle: 'Director, Sales',
    company: 'Example; Ltd',
    phones: const [
      LabeledValue(label: ContactLabel.mobile, value: '+852 9123 4567'),
      LabeledValue(label: ContactLabel.work, value: '+852 2123 4567'),
    ],
    emails: const [
      LabeledValue(label: ContactLabel.work, value: 'tm@example.com'),
    ],
    websites: const ['https://example.com'],
    addresses: const [
      PostalAddress(street: '1 Queen\'s Road', city: 'Hong Kong'),
    ],
    socialLinks: const [
      SocialLink(network: SocialNetwork.wechat, handleOrUrl: 'taiman'),
    ],
    shareSlug: 'abc123',
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  group('BusinessCard', () {
    test('JSON round-trip preserves all fields', () {
      final copy = BusinessCard.fromJson(card.toJson());
      expect(copy.toJson(), card.toJson());
    });
  });

  group('VCardEncoder', () {
    const encoder = VCardEncoder();

    test('encodes required properties and escapes special characters', () {
      final v = encoder.encode(card);
      expect(v, startsWith('BEGIN:VCARD\r\nVERSION:3.0\r\n'));
      expect(v, endsWith('END:VCARD\r\n'));
      expect(v, contains('FN:Tai Man Chan'));
      expect(v, contains('N:Chan;Tai Man;;;'));
      expect(v, contains(r'ORG:Example\; Ltd'));
      expect(v, contains(r'TITLE:Director\, Sales'));
      expect(v, contains('TEL;TYPE=CELL:+852 9123 4567'));
      expect(v, contains('EMAIL;TYPE=INTERNET,WORK:tm@example.com'));
      expect(v, contains('X-SOCIALPROFILE;TYPE=wechat:taiman'));
    });

    test('compact form keeps only first phone/email and adds card URL', () {
      final v = encoder.encodeCompact(
        card,
        cardUrl: Uri.parse('https://card.example.com/c/abc123'),
      );
      expect('TEL'.allMatches(v).length, 1);
      expect(v, contains('URL:https://card.example.com/c/abc123'));
      expect(v, isNot(contains('ADR')));
      expect(v, isNot(contains('X-SOCIALPROFILE')));
    });

    test('folds long lines at 75 octets without splitting UTF-8 chars', () {
      final long = BusinessCard(
        id: 'c2',
        cardName: 'Work',
        fullName: '陳' * 40,
        updatedAt: DateTime.utc(2026),
      );
      final v = encoder.encode(long);
      for (final line in v.split('\r\n')) {
        expect(_utf8Length(line), lessThanOrEqualTo(75));
      }
      final unfolded = v.replaceAll('\r\n ', '');
      expect(unfolded, contains('FN:${'陳' * 40}'));
    });
  });

  group('SharePayload', () {
    final payload = SharePayload(
      baseUrl: Uri.parse('https://card.example.com'),
    );

    test('builds and parses card URL', () {
      final url = payload.cardUrl(card)!;
      expect(url.toString(), 'https://card.example.com/c/abc123');
      expect(payload.slugFromUrl(url), 'abc123');
      expect(
        payload.slugFromUrl(Uri.parse('https://evil.example/c/abc123')),
        isNull,
      );
    });

    test('QR uses URL online and vCard offline or when unsynced', () {
      expect(payload.qrText(card), 'https://card.example.com/c/abc123');
      final offline = payload.qrText(card, offline: true);
      expect(offline, startsWith('BEGIN:VCARD'));
      expect(offline, contains('ADR'), reason: 'QR carries the full vCard');
      final unsynced = BusinessCard.fromJson({
        ...card.toJson(),
        'shareSlug': null,
      });
      expect(payload.qrText(unsynced), startsWith('BEGIN:VCARD'));
    });
  });
}

/// Byte length of [s] in UTF-8, to check vCard line folding.
int _utf8Length(String s) => s.runes.fold(
  0,
  (n, r) =>
      n +
      (r < 0x80
          ? 1
          : r < 0x800
          ? 2
          : r < 0x10000
          ? 3
          : 4),
);
