// The default build has no server (DESIGN.md §2, "Serverless mode"): no
// account or sync, no network use, and cards travel as offline links that
// carry the card itself.

import 'package:ebucard/src/core/config.dart';
import 'package:ebucard/src/data/app_database.dart';
import 'package:ebucard/src/data/card_repository.dart';
import 'package:ebucard/src/data/received_card_repository.dart';
import 'package:ebucard_models/ebucard_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ndef_record/ndef_record.dart';

import 'support/fake_server.dart';
import 'support/test_app.dart';

/// The user's own card.
BusinessCard _myCard() => BusinessCard(
  id: 'my-card',
  cardName: 'Work',
  fullName: 'Me Myself',
  jobTitle: 'Founder',
  emails: const [LabeledValue(label: ContactLabel.work, value: 'me@x.com')],
  updatedAt: DateTime.utc(2026, 10),
);

/// Someone else's card.
final _theirs = BusinessCard(
  id: 'theirs',
  cardName: 'Work',
  fullName: 'Jane Doe',
  jobTitle: 'CEO',
  phones: const [
    LabeledValue(label: ContactLabel.mobile, value: '+852 9123 4567'),
  ],
  updatedAt: DateTime.utc(2026, 10),
);

final _links = OfflineCardLink(AppConfig.webCardUrl);

void main() {
  late AppDatabase db;
  late FakeServer server;
  late FakeScanner scanner;
  late FakeNfcService nfc;

  setUp(() {
    db = memoryDatabase();
    server = FakeServer();
    scanner = FakeScanner();
    nfc = FakeNfcService();
  });
  tearDown(() => db.close());

  /// Lets database work finish.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
    }
  }

  Future<void> start(WidgetTester tester) async {
    await pumpApp(tester, db: db, server: server, scanner: scanner, nfc: nfc);
    await settle(tester);
  }

  Future<void> openExchange(WidgetTester tester, String entry) async {
    await tester.tap(find.text('Exchange'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(entry));
    await settle(tester);
  }

  Future<List<ReceivedCard>> inbox(WidgetTester tester) =>
      dbCall(tester, () => ReceivedCardRepository(db).watchAll().first);

  testWidgets('no account, no sync, no network', (tester) async {
    await dbCall(tester, () => CardRepository(db).save(_myCard()));
    await start(tester);
    expect(find.byTooltip('Account'), findsNothing);
    expect(find.byType(RefreshIndicator), findsNothing);
    await tester.tap(find.text('Inbox'));
    await settle(tester);
    expect(find.byType(RefreshIndicator), findsNothing);
    expect(server.requests, isEmpty);
  });

  testWidgets('the QR code is an offline link; the switch shows a vCard', (
    tester,
  ) async {
    await dbCall(tester, () => CardRepository(db).save(_myCard()));
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    await start(tester);
    await openExchange(tester, 'Show QR code');
    expect(find.textContaining('even without eBuCard'), findsOneWidget);
    expect(find.text('Card link'), findsOneWidget);

    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();
    expect(copied, startsWith(AppConfig.webCardUrl.toString()));
    final card = _links.decode(copied!, id: 'x', now: DateTime.now())!;
    expect(card.fullName, 'Me Myself');
    expect(card.jobTitle, 'Founder');

    await tester.tap(find.text('Full vCard in the code'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        "Ask the other person to scan this with eBuCard or their phone's "
        'camera.',
      ),
      findsOneWidget,
    );
    expect(server.requests, isEmpty);
  });

  testWidgets('scanning an offline link saves the card without internet', (
    tester,
  ) async {
    server.online = false;
    await start(tester);
    await openExchange(tester, 'Scan QR code');
    scanner.scan(_links.linkFor(_theirs).toString());
    await settle(tester);
    expect(find.text('Jane Doe'), findsOneWidget);
    final entry = (await inbox(tester)).single;
    expect(entry.receivedVia, ReceivedVia.qr);
    expect(entry.sourceSlug, isNull);
    expect(entry.card.phones.single.value, '+852 9123 4567');
    // No server: nothing to check for updates.
    expect(find.text('Check for updates'), findsNothing);
  });

  testWidgets('server links are not used without the cloud features', (
    tester,
  ) async {
    await start(tester);
    await openExchange(tester, 'Scan QR code');
    scanner.scan('http://localhost:8080/c/some-slug');
    await settle(tester);
    expect(find.textContaining("isn't a business card"), findsOneWidget);
    expect(server.requests, isEmpty);
  });

  testWidgets('NFC shares the offline link first, then the vCard', (
    tester,
  ) async {
    await dbCall(tester, () => CardRepository(db).save(_myCard()));
    await start(tester);
    await openExchange(tester, 'Tap phones (NFC)');
    final message = NdefMessage.decode(nfc.sharing!);
    final link = uriFromNdef(message)!;
    expect(
      _links.decode(link.toString(), id: 'x', now: DateTime.now())!.fullName,
      'Me Myself',
    );
    expect(contactTextFromNdef(message), contains('FN:Me Myself'));
  });

  testWidgets('NFC reads an offline link without internet', (tester) async {
    server.online = false;
    await start(tester);
    await openExchange(tester, 'Read by NFC');
    nfc.deliver(cardNdefMessage(_theirs, cardUrl: _links.linkFor(_theirs)));
    await settle(tester);
    expect((await inbox(tester)).single.card.fullName, 'Jane Doe');
  });

  testWidgets('"Open in eBuCard" on the web card saves the card', (
    tester,
  ) async {
    await start(tester);
    final data = OfflineCardLink.encodeData(_theirs);
    // What ebucard://card/receive/<data> hands to the router.
    GoRouter.of(
      tester.element(find.byType(Scaffold).first),
    ).go('/receive/$data');
    await settle(tester);
    final entry = (await inbox(tester)).single;
    expect(entry.receivedVia, ReceivedVia.link);
    expect(find.text('Jane Doe'), findsOneWidget);
    expect(server.requests, isEmpty);
  });
}
