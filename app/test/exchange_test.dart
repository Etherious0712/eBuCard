import 'package:ebucard/src/data/app_database.dart';
import 'package:ebucard/src/data/card_repository.dart';
import 'package:ebucard/src/data/received_card_repository.dart';
import 'package:ebucard/src/data/settings_repository.dart';
import 'package:ebucard_models/ebucard_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'support/test_app.dart';

/// A vCard as another eBuCard phone (or any contact app) would show it.
String _vcard(
  String name, {
  String phone = '+852 9123 4567',
  String title = '',
}) => const VCardEncoder().encode(
  BusinessCard(
    id: 'x',
    cardName: '',
    fullName: name,
    jobTitle: title,
    phones: [LabeledValue(label: ContactLabel.mobile, value: phone)],
    updatedAt: DateTime.utc(2026),
  ),
);

/// One of the user's own cards.
BusinessCard _ownCard(String id, String name) => BusinessCard(
  id: id,
  cardName: id,
  fullName: name,
  emails: const [LabeledValue(label: ContactLabel.work, value: 'me@x.com')],
  updatedAt: DateTime.utc(2026),
);

/// Opens Exchange → Scan QR code.
Future<void> _openScanner(WidgetTester tester) async {
  await tester.tap(find.text('Exchange'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Scan QR code'));
  await tester.pumpAndSettle();
}

/// "Scans" [text] and waits for the result.
Future<void> _scan(
  WidgetTester tester,
  FakeScanner scanner,
  String text,
) async {
  scanner.scan(text);
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
}

void main() {
  late AppDatabase db;
  late FakeScanner scanner;

  setUp(() {
    db = memoryDatabase();
    scanner = FakeScanner();
  });
  tearDown(() => db.close());

  /// Everything in the Inbox, newest first.
  Future<List<ReceivedCard>> inbox(WidgetTester tester) =>
      dbCall(tester, () => ReceivedCardRepository(db).watchAll().first);

  group('scan', () {
    testWidgets('a contact QR code is added to the Inbox and opened', (
      tester,
    ) async {
      await pumpApp(tester, db: db, scanner: scanner);
      await _openScanner(tester);
      await _scan(tester, scanner, _vcard('Jane Doe', title: 'CEO'));

      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('CEO'), findsOneWidget);
      expect(find.text('Save to Contacts'), findsOneWidget);
      final entries = await inbox(tester);
      expect(entries.single.card.fullName, 'Jane Doe');
      expect(entries.single.receivedVia, ReceivedVia.qr);
    });

    testWidgets('a QR code that is not a contact is rejected', (tester) async {
      await pumpApp(tester, db: db, scanner: scanner);
      await _openScanner(tester);
      await _scan(tester, scanner, 'https://example.com');

      expect(find.text("This QR code isn't a business card."), findsOneWidget);
      expect(await inbox(tester), isEmpty);
    });

    testWidgets('scanning the same person again can update the entry', (
      tester,
    ) async {
      await pumpApp(tester, db: db, scanner: scanner);
      await _openScanner(tester);
      await _scan(tester, scanner, _vcard('Jane Doe', title: 'CTO'));
      final first = (await inbox(tester)).single;

      await _openScanner(tester);
      await _scan(tester, scanner, _vcard('Jane Doe', title: 'CEO'));
      expect(find.text('Already in your Inbox'), findsOneWidget);
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();

      final entries = await inbox(tester);
      expect(entries, hasLength(1));
      expect(entries.single.id, first.id);
      expect(entries.single.card.jobTitle, 'CEO');
      expect(entries.single.receivedAt, first.receivedAt);
    });

    testWidgets('keep both adds a second entry; cancel adds nothing', (
      tester,
    ) async {
      await pumpApp(tester, db: db, scanner: scanner);
      await _openScanner(tester);
      await _scan(tester, scanner, _vcard('Jane Doe'));

      await _openScanner(tester);
      await _scan(tester, scanner, _vcard('Jane Doe'));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await inbox(tester), hasLength(1));

      // The camera ignores a code the user just dismissed, so scan an
      // updated card for the same person.
      await _scan(tester, scanner, _vcard('Jane Doe', title: 'CEO'));
      await tester.tap(find.text('Keep both'));
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      expect(await inbox(tester), hasLength(2));
    });
  });

  group('show QR', () {
    /// Opens Exchange → Show QR code.
    Future<void> openShowQr(WidgetTester tester) async {
      await tester.tap(find.text('Exchange'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show QR code'));
      await tester.pumpAndSettle();
    }

    testWidgets('without cards it offers to create one', (tester) async {
      await pumpApp(tester, db: db);
      await openShowQr(tester);
      expect(
        find.text('Create a card first, then you can share it here.'),
        findsOneWidget,
      );
      expect(find.byType(QrImageView), findsNothing);
    });

    testWidgets('opens on the default card and can switch cards', (
      tester,
    ) async {
      await dbCall(tester, () async {
        final cards = CardRepository(db);
        await cards.save(_ownCard('work', 'Work Me'));
        await cards.save(_ownCard('home', 'Home Me'));
        await SettingsRepository(db).setDefaultCardId('home');
      });
      await pumpApp(tester, db: db);
      await openShowQr(tester);

      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('Home Me'), findsOneWidget);

      await tester.tap(find.text('home · Home Me'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('work · Work Me').last);
      await tester.pumpAndSettle();
      expect(find.text('Work Me'), findsOneWidget);
    });

    testWidgets('the star in the editor sets the default card', (tester) async {
      await dbCall(tester, () async {
        final cards = CardRepository(db);
        await cards.save(_ownCard('work', 'Work Me'));
        await cards.save(_ownCard('home', 'Home Me'));
      });
      await pumpApp(tester, db: db);
      await tester.tap(find.text('Home Me'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Set as default card'));
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();

      expect(
        await dbCall(
          tester,
          () => SettingsRepository(db).watchDefaultCardId().first,
        ),
        'home',
      );
      expect(find.byTooltip('Default card'), findsOneWidget);
    });
  });
}
