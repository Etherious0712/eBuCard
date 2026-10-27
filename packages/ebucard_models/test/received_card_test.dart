import 'package:ebucard_models/ebucard_models.dart';
import 'package:test/test.dart';

/// A card for [name] with the given phones and emails.
BusinessCard _card(
  String name, {
  List<String> phones = const [],
  List<String> emails = const [],
}) => BusinessCard(
  id: name,
  cardName: '',
  fullName: name,
  phones: [
    for (final p in phones) LabeledValue(label: ContactLabel.other, value: p),
  ],
  emails: [
    for (final e in emails) LabeledValue(label: ContactLabel.other, value: e),
  ],
  updatedAt: DateTime.utc(2026),
);

void main() {
  group('isSamePerson', () {
    test('same name and a shared email (any case)', () {
      expect(
        isSamePerson(
          _card('Tai Man Chan', emails: ['TM@example.com']),
          _card('tai  man chan', emails: ['tm@example.com']),
        ),
        isTrue,
      );
    });

    test('same phone with and without country code', () {
      expect(
        isSamePerson(
          _card('A', phones: ['+852 9123 4567']),
          _card('A', phones: ['9123-4567']),
        ),
        isTrue,
      );
    });

    test('different name is a different person', () {
      expect(
        isSamePerson(
          _card('A', emails: ['x@y.com']),
          _card('B', emails: ['x@y.com']),
        ),
        isFalse,
      );
    });

    test('same name but nothing shared is a different person', () {
      expect(
        isSamePerson(
          _card('A', phones: ['91234567']),
          _card('A', phones: ['98765432']),
        ),
        isFalse,
      );
    });

    test('short numbers never match', () {
      expect(
        isSamePerson(_card('A', phones: ['123']), _card('A', phones: ['123'])),
        isFalse,
      );
    });
  });

  test('ReceivedCard JSON round-trip and copyWith keep receivedAt', () {
    final entry = ReceivedCard(
      id: 'r1',
      card: _card('A', emails: ['a@b.com']),
      receivedVia: ReceivedVia.qr,
      receivedAt: DateTime.utc(2026, 1, 1),
      note: 'Met at Expo',
      updatedAt: DateTime.utc(2026, 1, 2),
    );
    final copy = ReceivedCard.fromJson(entry.toJson());
    expect(copy.toJson(), entry.toJson());

    final edited = entry.copyWith(note: 'x', updatedAt: DateTime.utc(2026, 2));
    expect(edited.receivedAt, entry.receivedAt);
    expect(edited.note, 'x');
  });

  test('ReceivedCard keeps the source link slug; older JSON has none', () {
    final entry = ReceivedCard(
      id: 'r2',
      card: _card('B', emails: ['b@c.com']),
      receivedVia: ReceivedVia.link,
      receivedAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      sourceSlug: 'abc123',
    );
    expect(ReceivedCard.fromJson(entry.toJson()).sourceSlug, 'abc123');
    final old = entry.toJson()..remove('sourceSlug');
    expect(ReceivedCard.fromJson(old).sourceSlug, isNull);
    expect(entry.copyWith(note: 'n').sourceSlug, 'abc123');
  });
}
