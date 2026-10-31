import 'dart:convert';
import 'dart:io';

import 'package:ebucard_models/ebucard_models.dart';
import 'package:test/test.dart';

final _links = OfflineCardLink(
  Uri.parse('https://etherious0712.github.io/eBuCard/c/'),
);
final _now = DateTime.utc(2026, 10, 31);

/// The shared vectors; web/test reads the same file.
final _vectors =
    jsonDecode(File('test/fixtures/offline_links.json').readAsStringSync())
        as List;

void main() {
  test('every shared vector decodes to its card and vCard', () {
    for (final v in _vectors.cast<Map<String, Object?>>()) {
      final card = OfflineCardLink.decodeData(
        v['data']! as String,
        id: 'x',
        now: _now,
      )!;
      expect(OfflineCardLink.compactJson(card), v['card']);
      // The web card's Save contact must produce the same vCard.
      expect(
        const VCardEncoder().encode(card, includeImages: false),
        v['vcard'],
      );
    }
  });

  test(
    'a card survives the round trip, without id, name of card or images',
    () {
      final card = BusinessCard(
        id: 'mine',
        cardName: 'Work',
        fullName: '陳大文',
        jobTitle: '董事',
        company: 'Acme',
        phones: const [
          LabeledValue(label: ContactLabel.mobile, value: '91234567'),
        ],
        emails: const [LabeledValue(label: ContactLabel.work, value: 'a@b.c')],
        websites: const ['acme.example'],
        addresses: const [
          PostalAddress(label: ContactLabel.work, street: '1 Road', city: 'HK'),
        ],
        socialLinks: const [
          SocialLink(network: SocialNetwork.wechat, handleOrUrl: 'dawen'),
        ],
        photoUrl: 'https://x/p.jpg',
        updatedAt: DateTime.utc(2026),
      );
      final link = _links.linkFor(card);
      expect(
        link.toString(),
        startsWith('https://etherious0712.github.io/eBuCard/c/#1'),
      );
      final back = _links.decode(link.toString(), id: 'new', now: _now)!;
      expect(back.id, 'new');
      expect(back.cardName, isEmpty);
      expect(back.photoUrl, isNull);
      expect(back.updatedAt, _now);
      expect(
        OfflineCardLink.compactJson(back),
        OfflineCardLink.compactJson(card),
      );
    },
  );

  test('app links carry the same data', () {
    final card = BusinessCard(
      id: 'a',
      cardName: '',
      fullName: 'Jane',
      updatedAt: DateTime.utc(2026),
    );
    final app = OfflineCardLink.appLinkFor(card);
    expect(app.scheme, 'ebucard');
    expect(_links.decode(app.toString(), id: 'x', now: _now)!.fullName, 'Jane');
  });

  test('other links, broken data and oversized data are not cards', () {
    String? read(String s) => _links.decode(s, id: 'x', now: _now)?.fullName;
    final good = _vectors.first['data'] as String;
    expect(
      read('https://etherious0712.github.io/eBuCard/c#$good'),
      'Jane Chan',
    );
    expect(read('https://evil.example/eBuCard/c/#$good'), isNull);
    expect(read('https://etherious0712.github.io/other/#$good'), isNull);
    expect(read('https://etherious0712.github.io/eBuCard/c/'), isNull);
    expect(read('https://etherious0712.github.io/eBuCard/c/#2abc'), isNull);
    expect(read('https://etherious0712.github.io/eBuCard/c/#1!!!'), isNull);
    expect(read('BEGIN:VCARD'), isNull);
    expect(
      OfflineCardLink.decodeData('1${'A' * 9000}', id: 'x', now: _now),
      isNull,
    );
    // A card without a name is not a card.
    final noName = BusinessCard(
      id: 'a',
      cardName: '',
      fullName: '',
      updatedAt: _now,
    );
    expect(
      OfflineCardLink.decodeData(
        OfflineCardLink.encodeData(noName),
        id: 'x',
        now: _now,
      ),
      isNull,
    );
  });

  test('unknown labels become other; malformed rows are skipped', () {
    final card = OfflineCardLink.fromCompactJson(
      {
        'n': 'A',
        'p': [
          ['satellite', '123'],
          'not a row',
          ['mobile'],
        ],
        's': [
          ['myspace', 'a'],
        ],
      },
      id: 'x',
      now: _now,
    )!;
    expect(card.phones.single.label, ContactLabel.other);
    expect(card.socialLinks.single.network, SocialNetwork.other);
  });
}
