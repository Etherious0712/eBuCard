import 'package:drift/native.dart';
import 'package:ebucard/src/data/app_database.dart';
import 'package:ebucard/src/data/providers.dart';
import 'package:ebucard/src/data/received_card_repository.dart';
import 'package:ebucard/src/data/settings_repository.dart';
import 'package:ebucard_models/ebucard_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_app.dart';

/// An Inbox entry for [name] received on [day] of January 2026.
ReceivedCard _entry(
  String id,
  String name, {
  int day = 1,
  String company = '',
  String email = '',
}) => ReceivedCard(
  id: id,
  card: BusinessCard(
    id: 'card-$id',
    cardName: '',
    fullName: name,
    company: company,
    emails: [
      if (email.isNotEmpty)
        LabeledValue(label: ContactLabel.work, value: email),
    ],
    updatedAt: DateTime.utc(2026),
  ),
  receivedVia: ReceivedVia.qr,
  receivedAt: DateTime.utc(2026, 1, day),
  updatedAt: DateTime.utc(2026, 1, day),
);

void main() {
  late AppDatabase db;
  late ReceivedCardRepository repo;

  setUp(() {
    db = memoryDatabase();
    repo = ReceivedCardRepository(db);
  });
  tearDown(() => db.close());

  test('lists newest first and round-trips entries', () async {
    await repo.save(_entry('a', 'Older', day: 1));
    await repo.save(_entry('b', 'Newer', day: 2));
    final all = await repo.watchAll().first;
    expect(all.map((e) => e.card.fullName), ['Newer', 'Older']);
    expect((await repo.find('a'))!.toJson(), _entry('a', 'Older').toJson());
  });

  test('search matches name, company or email, ignoring case', () async {
    await repo.save(_entry('a', 'Tai Man Chan'));
    await repo.save(_entry('b', 'Jane Doe', company: 'Acme'));
    await repo.save(_entry('c', 'Sam Lee', email: 'sam@example.com'));
    Future<List<String>> search(String q) async =>
        (await repo.watchAll(query: q).first).map((e) => e.id).toList();
    expect(await search('CHAN'), ['a']);
    expect(await search('acme'), ['b']);
    expect(await search('example.com'), ['c']);
    expect(await search('nobody'), isEmpty);
  });

  test('findSamePerson finds an entry with the same name and email', () async {
    await repo.save(_entry('a', 'Jane Doe', email: 'jane@acme.com'));
    final again = _entry('x', 'Jane Doe', email: 'JANE@acme.com').card;
    expect((await repo.findSamePerson(again))?.id, 'a');
    final other = _entry('y', 'Jane Doe', email: 'other@acme.com').card;
    expect(await repo.findSamePerson(other), isNull);
  });

  test('delete removes the entry', () async {
    await repo.save(_entry('a', 'A'));
    await repo.delete('a');
    expect(await repo.find('a'), isNull);
  });

  test(
    'upgrading a version 1 database keeps own cards and adds the Inbox',
    () async {
      final v1 = AppDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            raw.execute(
              'CREATE TABLE own_cards (id TEXT NOT NULL, json TEXT NOT NULL, '
              'sort_order INTEGER NOT NULL, updated_at INTEGER NOT NULL, '
              'PRIMARY KEY (id))',
            );
            raw.execute("INSERT INTO own_cards VALUES ('c1', '{}', 0, 0)");
            raw.execute('PRAGMA user_version = 1');
          },
        ),
      );
      addTearDown(v1.close);
      expect(await v1.select(v1.ownCards).get(), hasLength(1));
      await ReceivedCardRepository(v1).save(_entry('a', 'A'));
      expect(await ReceivedCardRepository(v1).find('a'), isNotNull);
    },
  );

  test('upgrading a version 2 database adds sync tracking', () async {
    final v2 = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw
            ..execute(
              'CREATE TABLE own_cards (id TEXT NOT NULL, json TEXT NOT NULL, '
              'sort_order INTEGER NOT NULL, updated_at INTEGER NOT NULL, '
              'PRIMARY KEY (id))',
            )
            ..execute(
              'CREATE TABLE received_cards (id TEXT NOT NULL, '
              'json TEXT NOT NULL, search_text TEXT NOT NULL, '
              'received_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, '
              'PRIMARY KEY (id))',
            )
            ..execute(
              'CREATE TABLE settings (key TEXT NOT NULL, value TEXT NOT NULL, '
              'PRIMARY KEY (key))',
            )
            ..execute('PRAGMA user_version = 2');
        },
      ),
    );
    addTearDown(v2.close);
    final repo = ReceivedCardRepository(v2);
    await repo.save(_entry('a', 'A'));
    // Existing and new records count as "not yet in the account".
    expect((await repo.dirty()).single.id, 'a');
    await repo.delete('a');
    expect(await v2.select(v2.pendingDeletions).get(), hasLength(1));
  });

  group('default card', () {
    BusinessCard card(String id) => BusinessCard(
      id: id,
      cardName: id,
      fullName: id,
      updatedAt: DateTime.utc(2026),
    );

    test('falls back to the first card when unset or deleted', () {
      final cards = [card('a'), card('b')];
      expect(resolveDefaultCard(cards, null)?.id, 'a');
      expect(resolveDefaultCard(cards, 'b')?.id, 'b');
      expect(resolveDefaultCard(cards, 'gone')?.id, 'a');
      expect(resolveDefaultCard(const [], 'a'), isNull);
    });

    test('the chosen default is stored', () async {
      final settings = SettingsRepository(db);
      expect(await settings.watchDefaultCardId().first, isNull);
      await settings.setDefaultCardId('b');
      expect(await settings.watchDefaultCardId().first, 'b');
    });
  });
}
