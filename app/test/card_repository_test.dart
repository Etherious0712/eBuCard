import 'package:ebucard/src/data/app_database.dart';
import 'package:ebucard/src/data/card_repository.dart';
import 'package:ebucard_models/ebucard_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_app.dart';

BusinessCard _card(String id, {String name = 'Tai Man Chan'}) => BusinessCard(
  id: id,
  cardName: 'Work',
  fullName: name,
  phones: const [LabeledValue(label: ContactLabel.mobile, value: '123')],
  updatedAt: DateTime.utc(2026, 1, 1),
);

void main() {
  late AppDatabase db;
  late CardRepository repo;

  setUp(() {
    db = memoryDatabase();
    repo = CardRepository(db);
  });
  tearDown(() => db.close());

  test('save and find round-trips the full card', () async {
    final card = _card('a');
    await repo.save(card);
    final found = await repo.find('a');
    expect(found!.toJson(), card.toJson());
    expect(await repo.find('missing'), isNull);
  });

  test('new cards are appended; updates keep their position', () async {
    await repo.save(_card('a', name: 'A'));
    await repo.save(_card('b', name: 'B'));
    await repo.save(_card('a', name: 'A2'));
    final cards = await repo.watchAll().first;
    expect(cards.map((c) => c.fullName), ['A2', 'B']);
  });

  test('delete removes the card', () async {
    await repo.save(_card('a'));
    await repo.delete('a');
    expect(await repo.watchAll().first, isEmpty);
  });
}
