import 'package:ebucard/src/data/app_database.dart';
import 'package:ebucard/src/data/card_repository.dart';
import 'package:ebucard_models/ebucard_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_app.dart';

/// The text field whose label is [label].
Finder _field(String label) => find.widgetWithText(TextField, label);

/// Taps "New card" on My Cards.
Future<void> _openNewCard(WidgetTester tester) async {
  await tester.tap(find.text('New card'));
  await tester.pumpAndSettle();
}

/// Runs real database work outside the widget test's fake-async zone, where
/// it would otherwise never complete.
Future<T> _db<T>(WidgetTester tester, Future<T> Function() body) async =>
    (await tester.runAsync(body)) as T;

/// Every card currently stored in [db].
Future<List<BusinessCard>> _allCards(WidgetTester tester, AppDatabase db) =>
    _db(tester, () => CardRepository(db).watchAll().first);

/// Taps Save in the editor's app bar.
Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDatabase());
  tearDown(() => db.close());

  testWidgets('saving an empty card shows the required-field errors', (
    tester,
  ) async {
    await pumpApp(tester, db: db);
    await _openNewCard(tester);
    await _save(tester);

    expect(find.text('Enter a full name'), findsOneWidget);
    expect(
      find.text('Add at least one phone number or email address'),
      findsOneWidget,
    );
    expect(await _allCards(tester, db), isEmpty);
  });

  testWidgets('a malformed email blocks saving', (tester) async {
    await pumpApp(tester, db: db);
    await _openNewCard(tester);
    await tester.enterText(_field('Full name *'), 'Tai Man Chan');
    await tester.enterText(_field('Email'), 'tm@');
    await _save(tester);

    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(await _allCards(tester, db), isEmpty);
  });

  testWidgets('a valid card is saved and listed', (tester) async {
    await pumpApp(tester, db: db);
    await _openNewCard(tester);
    await tester.enterText(_field('Card name'), 'Work');
    await tester.enterText(_field('Full name *'), 'Tai Man Chan');
    await tester.enterText(_field('Job title'), 'Director');
    await tester.enterText(_field('Company'), 'Example Ltd');
    await tester.enterText(_field('Phone'), '+852 9123 4567');
    await tester.tap(find.text('Add website'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Website'), 'https://example.com');
    await _save(tester);

    expect(find.text('Tai Man Chan'), findsOneWidget);
    expect(find.text('Director · Example Ltd'), findsOneWidget);

    final saved = (await _allCards(tester, db)).single;
    expect(saved.cardName, 'Work');
    expect(saved.phones.single.value, '+852 9123 4567');
    expect(saved.phones.single.label, ContactLabel.mobile);
    expect(saved.emails, isEmpty, reason: 'blank email row is dropped');
    expect(saved.websites, ['https://example.com']);
  });

  testWidgets('blank card name falls back to the default name', (tester) async {
    await pumpApp(tester, db: db);
    await _openNewCard(tester);
    await tester.enterText(_field('Full name *'), 'Tai Man Chan');
    await tester.enterText(_field('Email'), 'tm@example.com');
    await _save(tester);

    final saved = (await _allCards(tester, db)).single;
    expect(saved.cardName, 'My card');
  });

  testWidgets('editing keeps the id and updates fields', (tester) async {
    await _db(
      tester,
      () => CardRepository(db).save(
        BusinessCard(
          id: 'c1',
          cardName: 'Work',
          fullName: 'Tai Man Chan',
          emails: const [
            LabeledValue(label: ContactLabel.work, value: 'tm@example.com'),
          ],
          updatedAt: DateTime.utc(2026),
        ),
      ),
    );
    await pumpApp(tester, db: db);
    await tester.tap(find.text('Tai Man Chan'));
    await tester.pumpAndSettle();
    expect(find.text('Edit card'), findsOneWidget);

    await tester.enterText(_field('Job title'), 'CEO');
    await _save(tester);

    final saved = await _db(tester, () => CardRepository(db).find('c1'));
    expect(saved!.jobTitle, 'CEO');
    expect(saved.emails.single.value, 'tm@example.com');
  });

  testWidgets('deleting asks for confirmation and removes the card', (
    tester,
  ) async {
    final images = FakeCardImageService();
    await _db(
      tester,
      () => CardRepository(db).save(
        BusinessCard(
          id: 'c1',
          cardName: 'Work',
          fullName: 'Tai Man Chan',
          emails: const [
            LabeledValue(label: ContactLabel.work, value: 'tm@example.com'),
          ],
          photoUrl: 'file:///photo.jpg',
          updatedAt: DateTime.utc(2026),
        ),
      ),
    );
    await pumpApp(tester, db: db, images: images);
    await tester.tap(find.text('Tai Man Chan'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this card?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(await _db(tester, () => CardRepository(db).find('c1')), isNull);
    expect(images.deleted, contains('file:///photo.jpg'));
    expect(
      find.text('You have no cards yet. Create your first business card.'),
      findsOneWidget,
    );
  });

  testWidgets('a picked photo is saved with the card', (tester) async {
    final images = FakeCardImageService()..nextImage = 'file:///new.jpg';
    await pumpApp(tester, db: db, images: images);
    await _openNewCard(tester);
    await tester.tap(find.text('Photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from library'));
    await tester.pumpAndSettle();

    await tester.enterText(_field('Full name *'), 'Tai Man Chan');
    await tester.enterText(_field('Phone'), '123');
    await _save(tester);

    final saved = (await _allCards(tester, db)).single;
    expect(saved.photoUrl, 'file:///new.jpg');
    expect(images.deleted, isEmpty);
  });
}
