import 'package:ebucard/src/data/app_database.dart';
import 'package:ebucard/src/data/card_repository.dart';
import 'package:ebucard/src/data/nfc_service.dart';
import 'package:ebucard/src/data/received_card_repository.dart';
import 'package:ebucard/src/data/settings_repository.dart';
import 'package:ebucard_models/ebucard_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndef_record/ndef_record.dart';

import 'support/test_app.dart';

/// One of the user's own cards.
BusinessCard _ownCard(String id, String name) => BusinessCard(
  id: id,
  cardName: id,
  fullName: name,
  emails: const [LabeledValue(label: ContactLabel.work, value: 'me@x.com')],
  updatedAt: DateTime.utc(2026),
);

/// Someone else's card, as their phone would share it over NFC.
NdefMessage _theirCard(String name) => cardNdefMessage(
  BusinessCard(
    id: 'x',
    cardName: '',
    fullName: name,
    phones: const [LabeledValue(label: ContactLabel.mobile, value: '91234567')],
    updatedAt: DateTime.utc(2026),
  ),
);

/// The full name inside shared NDEF [bytes].
String _sharedName(Uint8List bytes) => const ContactDecoder()
    .decode(
      contactTextFromNdef(NdefMessage.decode(bytes))!,
      id: 'r',
      now: DateTime.utc(2026),
    )!
    .fullName;

void main() {
  late AppDatabase db;
  late FakeNfcService nfc;

  setUp(() {
    db = memoryDatabase();
    nfc = FakeNfcService();
  });
  tearDown(() => db.close());

  /// Lets database work and post-frame callbacks finish.
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  /// Opens the Exchange tab and taps [option].
  Future<void> openExchange(WidgetTester tester, [String? option]) async {
    await tester.tap(find.text('Exchange'));
    await settle(tester);
    if (option != null) {
      await tester.tap(find.text(option));
      await settle(tester);
    }
  }

  group('Exchange screen', () {
    testWidgets('Android with NFC on offers both NFC options', (tester) async {
      await pumpApp(tester, db: db, nfc: nfc);
      await openExchange(tester);
      expect(find.text('Tap phones (NFC)'), findsOneWidget);
      expect(find.text('Read by NFC'), findsOneWidget);
      expect(find.text('NFC is off'), findsNothing);
    });

    testWidgets('NFC off is shown on the NFC options', (tester) async {
      nfc.current = const NfcStatus(state: NfcState.off, canShare: true);
      await pumpApp(tester, db: db, nfc: nfc);
      await openExchange(tester);
      expect(find.text('NFC is off'), findsNWidgets(2));
    });

    testWidgets('phones without NFC only offer QR', (tester) async {
      nfc.current = NfcStatus.unsupported;
      await pumpApp(tester, db: db, nfc: nfc);
      await openExchange(tester);
      expect(find.text('Tap phones (NFC)'), findsNothing);
      expect(find.text('Read by NFC'), findsNothing);
      expect(find.text('Show QR code'), findsOneWidget);
    });

    testWidgets('iPhone can read by NFC but not share', (tester) async {
      nfc.current = const NfcStatus(state: NfcState.on, canShare: false);
      await pumpApp(tester, db: db, nfc: nfc);
      await openExchange(tester);
      expect(find.text('Tap phones (NFC)'), findsNothing);
      expect(find.text('Read by NFC'), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  });

  group('share by NFC', () {
    testWidgets('shares the default card while open, and stops on leave', (
      tester,
    ) async {
      await dbCall(tester, () async {
        await CardRepository(db).save(_ownCard('work', 'Work Me'));
        await CardRepository(db).save(_ownCard('home', 'Home Me'));
        await SettingsRepository(db).setDefaultCardId('home');
      });
      await pumpApp(tester, db: db, nfc: nfc);
      await openExchange(tester, 'Tap phones (NFC)');

      expect(find.text('Ready to share'), findsOneWidget);
      expect(_sharedName(nfc.sharing!), 'Home Me');

      // Switching card shares the new one.
      await tester.tap(find.text('home · Home Me'));
      await settle(tester);
      await tester.tap(find.text('work · Work Me').last);
      await settle(tester);
      expect(_sharedName(nfc.sharing!), 'Work Me');

      // Leaving the screen stops sharing.
      await tester.tap(find.byTooltip('Back'));
      await settle(tester);
      expect(nfc.sharing, isNull);
    });

    testWidgets('the QR screen then shows the card picked for NFC', (
      tester,
    ) async {
      await dbCall(tester, () async {
        await CardRepository(db).save(_ownCard('work', 'Work Me'));
        await CardRepository(db).save(_ownCard('home', 'Home Me'));
      });
      await pumpApp(tester, db: db, nfc: nfc);
      await openExchange(tester, 'Tap phones (NFC)');
      await tester.tap(find.text('work · Work Me'));
      await settle(tester);
      await tester.tap(find.text('home · Home Me').last);
      await settle(tester);

      await tester.tap(find.byTooltip('Back'));
      await settle(tester);
      await tester.tap(find.text('Show QR code'));
      await settle(tester);
      expect(find.text('Home Me'), findsOneWidget);
    });

    testWidgets('NFC off: prompt with settings and QR fallback', (
      tester,
    ) async {
      nfc.current = const NfcStatus(state: NfcState.off, canShare: true);
      await dbCall(
        tester,
        () => CardRepository(db).save(_ownCard('work', 'Work Me')),
      );
      await pumpApp(tester, db: db, nfc: nfc);
      await openExchange(tester, 'Tap phones (NFC)');

      expect(nfc.sharing, isNull);
      await tester.tap(find.text('Open NFC settings'));
      expect(nfc.settingsOpened, 1);

      await tester.tap(find.text('Use QR code instead'));
      await settle(tester);
      expect(find.text('My QR code'), findsOneWidget);
    });

    testWidgets('without cards it offers to create one', (tester) async {
      await pumpApp(tester, db: db, nfc: nfc);
      await openExchange(tester, 'Tap phones (NFC)');
      expect(
        find.text('Create a card first, then you can share it here.'),
        findsOneWidget,
      );
      expect(nfc.sharing, isNull);
    });
  });

  group('read by NFC', () {
    /// Everything in the Inbox.
    Future<List<ReceivedCard>> inbox(WidgetTester tester) =>
        dbCall(tester, () => ReceivedCardRepository(db).watchAll().first);

    testWidgets('a card read by NFC goes to the Inbox and opens', (
      tester,
    ) async {
      await pumpApp(tester, db: db, nfc: nfc);
      await openExchange(tester, 'Read by NFC');
      expect(nfc.reading, isTrue);

      nfc.deliver(_theirCard('Jane Doe'));
      await settle(tester);

      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('Save to Contacts'), findsOneWidget);
      expect(nfc.reading, isFalse);
      expect((await inbox(tester)).single.receivedVia, ReceivedVia.nfc);
    });

    testWidgets('a tag without a card is rejected and listening continues', (
      tester,
    ) async {
      await pumpApp(tester, db: db, nfc: nfc);
      await openExchange(tester, 'Read by NFC');

      nfc.deliver(null);
      await settle(tester);
      expect(
        find.text("The other phone didn't share a business card."),
        findsOneWidget,
      );
      expect(nfc.reading, isTrue);
      expect(await inbox(tester), isEmpty);
    });

    testWidgets('leaving the screen stops listening', (tester) async {
      await pumpApp(tester, db: db, nfc: nfc);
      await openExchange(tester, 'Read by NFC');
      await tester.tap(find.byTooltip('Back'));
      await settle(tester);
      expect(nfc.reading, isFalse);
    });

    testWidgets('iPhone: closing the scan sheet offers Try again', (
      tester,
    ) async {
      nfc.current = const NfcStatus(state: NfcState.on, canShare: false);
      await pumpApp(tester, db: db, nfc: nfc);
      await openExchange(tester, 'Read by NFC');
      expect(nfc.reading, isTrue);

      nfc.cancelIos();
      await settle(tester);
      expect(find.text('Try again'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await settle(tester);
      expect(nfc.reading, isTrue);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  });
}
