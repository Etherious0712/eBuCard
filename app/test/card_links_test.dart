// Server card links in the app (cloud features on, DESIGN.md §4.1): the
// QR code shows the link once the card has synced, the owner can replace
// or turn off the link, links from other people are opened online and
// remembered for "Check for updates", and NFC falls back to the tag's
// vCard without internet.

import 'package:ebucard/src/account/session_store.dart';
import 'package:ebucard/src/data/app_database.dart';
import 'package:ebucard/src/data/card_repository.dart';
import 'package:ebucard/src/data/received_card_repository.dart';
import 'package:ebucard_models/ebucard_models.dart';
import 'package:flutter/material.dart';
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
  emails: const [LabeledValue(label: ContactLabel.work, value: 'me@x.com')],
  updatedAt: DateTime.utc(2026, 10),
);

/// Someone else's card as their phone synced it.
Map<String, Object?> _theirCard({String title = 'CEO'}) => BusinessCard(
  id: 'their-card',
  cardName: 'Work',
  fullName: 'Jane Doe',
  jobTitle: title,
  phones: const [
    LabeledValue(label: ContactLabel.mobile, value: '+852 9123 4567'),
  ],
  updatedAt: DateTime.utc(2026, 10),
).toJson();

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

  /// Lets network and database work finish.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
    }
  }

  /// Settles until [done] is true (sync runs in the background).
  Future<void> waitFor(
    WidgetTester tester,
    Future<bool> Function() done,
  ) async {
    for (var i = 0; i < 40 && !await done(); i++) {
      await settle(tester);
    }
    expect(await done(), isTrue, reason: 'timed out waiting');
  }

  /// Dismisses the current message so the next one shows.
  Future<void> hideMessage(WidgetTester tester) async {
    ScaffoldMessenger.of(
      tester.element(find.byType(Scaffold).last),
    ).hideCurrentSnackBar();
    await tester.pumpAndSettle();
  }

  /// Starts the app, signed in as a confirmed user when [signedIn].
  Future<FakeUser> start(WidgetTester tester, {bool signedIn = true}) async {
    final me = server.addUser('me@x.com', 'a good password');
    final sessions = MemorySessionStore();
    if (signedIn) await sessions.save(server.sessionFor(me));
    await pumpApp(
      tester,
      db: db,
      server: server,
      sessions: sessions,
      scanner: scanner,
      nfc: nfc,
      cloud: true,
    );
    await settle(tester);
    return me;
  }

  /// Puts Jane's card on the server with a link; returns the link.
  String janesLink() {
    final jane = server.addUser('jane@x.com', 'another password');
    server.putFromOtherPhone(
      jane,
      'cards',
      'their-card',
      _theirCard(),
      DateTime.utc(2026, 10),
    );
    final record = server.records[jane.id]!['cards']!['their-card']!;
    record.data = {...record.data!, 'shareSlug': 'jane-slug'};
    server.linkSlug('their-card', 'jane-slug');
    return 'http://localhost:8080/c/jane-slug';
  }

  /// Opens Exchange → [entry].
  Future<void> openExchange(WidgetTester tester, String entry) async {
    await tester.tap(find.text('Exchange'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(entry));
    await settle(tester);
  }

  /// The Inbox, newest first.
  Future<List<ReceivedCard>> inbox(WidgetTester tester) =>
      dbCall(tester, () => ReceivedCardRepository(db).watchAll().first);

  /// The user's card as stored on the phone.
  Future<BusinessCard?> myCard(WidgetTester tester) =>
      dbCall(tester, () => CardRepository(db).find('my-card'));

  group('my link', () {
    testWidgets('after sync the QR code shows the link; offline QR is a '
        'switch away', (tester) async {
      await dbCall(tester, () => CardRepository(db).save(_myCard()));
      await start(tester);
      await waitFor(
        tester,
        () async => (await myCard(tester))?.shareSlug != null,
      );
      final slug = (await myCard(tester))!.shareSlug;

      await openExchange(tester, 'Show QR code');
      expect(find.text('http://localhost:8080/c/$slug'), findsOneWidget);
      expect(find.textContaining('even without eBuCard'), findsOneWidget);

      await tester.tap(find.text('Offline QR'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          "Ask the other person to scan this with eBuCard or their phone's "
          'camera.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('signed out, the QR code is the vCard and sign-in is offered', (
      tester,
    ) async {
      await dbCall(tester, () => CardRepository(db).save(_myCard()));
      await start(tester, signedIn: false);
      await openExchange(tester, 'Show QR code');
      expect(find.text('Offline QR'), findsNothing);
      expect(find.textContaining('Sign in to get a link'), findsOneWidget);
    });

    testWidgets('a new link replaces the old one; turning it off removes it', (
      tester,
    ) async {
      await dbCall(tester, () => CardRepository(db).save(_myCard()));
      await start(tester);
      await waitFor(
        tester,
        () async => (await myCard(tester))?.shareSlug != null,
      );
      final old = (await myCard(tester))!.shareSlug!;
      await openExchange(tester, 'Show QR code');

      await tester.tap(find.text('New link'));
      await tester.pumpAndSettle();
      expect(find.text('Make a new link?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'New link'));
      await settle(tester);
      final fresh = (await myCard(tester))!.shareSlug!;
      expect(fresh, isNot(old));
      expect(server.cardForSlug(old), isNull);
      expect(find.text('http://localhost:8080/c/$fresh'), findsOneWidget);

      await tester.tap(find.text('Turn off'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Turn off'));
      await settle(tester);
      expect((await myCard(tester))!.shareSlug, isNull);
      expect(find.text('This card has no link right now.'), findsOneWidget);
      expect(find.text('Offline QR'), findsNothing);

      await tester.tap(find.text('Make a link'));
      await settle(tester);
      expect((await myCard(tester))!.shareSlug, isNotNull);
    });

    testWidgets('NFC shares the link first, then the vCard', (tester) async {
      await dbCall(tester, () => CardRepository(db).save(_myCard()));
      await start(tester);
      await waitFor(
        tester,
        () async => (await myCard(tester))?.shareSlug != null,
      );
      final slug = (await myCard(tester))!.shareSlug;
      await openExchange(tester, 'Tap phones (NFC)');
      final message = NdefMessage.decode(nfc.sharing!);
      expect(uriFromNdef(message).toString(), 'http://localhost:8080/c/$slug');
      expect(contactTextFromNdef(message), contains('FN:Me Myself'));
    });
  });

  group('their link', () {
    testWidgets('scanning a link saves their card and remembers the link', (
      tester,
    ) async {
      final link = janesLink();
      await start(tester, signedIn: false);
      await openExchange(tester, 'Scan QR code');
      scanner.scan(link);
      await settle(tester);

      expect(find.text('Jane Doe'), findsOneWidget);
      final entry = (await inbox(tester)).single;
      expect(entry.sourceSlug, 'jane-slug');
      expect(entry.receivedVia, ReceivedVia.qr);
      expect(entry.card.cardName, isEmpty);
      expect(entry.card.shareSlug, isNull);
      expect(find.text('Check for updates'), findsOneWidget);
    });

    testWidgets('Check for updates picks up their changes', (tester) async {
      final link = janesLink();
      await start(tester, signedIn: false);
      await openExchange(tester, 'Scan QR code');
      scanner.scan(link);
      await settle(tester);
      await hideMessage(tester);

      await tester.tap(find.text('Check for updates'));
      await settle(tester);
      expect(find.text('This card is up to date'), findsOneWidget);
      await hideMessage(tester);

      final jane = server.users['jane@x.com']!;
      server.records[jane.id]!['cards']!['their-card']!.data = {
        ..._theirCard(title: 'Chair'),
        'shareSlug': 'jane-slug',
      };
      await tester.tap(find.text('Check for updates'));
      await settle(tester);
      expect(find.text('Chair'), findsOneWidget);
      expect((await inbox(tester)).single.card.jobTitle, 'Chair');
      await hideMessage(tester);

      server.unlinkSlug('their-card');
      await tester.tap(find.text('Check for updates'));
      await settle(tester);
      expect(find.textContaining('no longer active'), findsOneWidget);
    });

    testWidgets('a turned-off or unreachable link says why', (tester) async {
      await start(tester, signedIn: false);
      await openExchange(tester, 'Scan QR code');
      scanner.scan('http://localhost:8080/c/gone');
      await settle(tester);
      expect(find.textContaining('no longer active'), findsOneWidget);
      await hideMessage(tester);

      server.online = false;
      scanner.scan('http://localhost:8080/c/other');
      await settle(tester);
      expect(
        find.textContaining("Couldn't open the card link"),
        findsOneWidget,
      );
      expect(await inbox(tester), isEmpty);
    });

    testWidgets('NFC uses the link online and the vCard offline', (
      tester,
    ) async {
      final link = janesLink();
      await start(tester, signedIn: false);
      final tag = cardNdefMessage(
        BusinessCard.fromJson(_theirCard()),
        cardUrl: Uri.parse(link),
      );
      await openExchange(tester, 'Read by NFC');

      nfc.deliver(tag);
      await settle(tester);
      expect((await inbox(tester)).single.sourceSlug, 'jane-slug');

      // Offline: the vCard on the tag still works (no link to check later).
      await dbCall(tester, () => db.delete(db.receivedCards).go());
      server.online = false;
      await openExchange(tester, 'Read by NFC');
      nfc.deliver(tag);
      await settle(tester);
      final entry = (await inbox(tester)).single;
      expect(entry.card.fullName, 'Jane Doe');
      expect(entry.sourceSlug, isNull);
    });

    testWidgets('opening a link from outside the app saves the card', (
      tester,
    ) async {
      janesLink();
      await start(tester, signedIn: false);
      // What Android App Links / iOS Universal Links hand to the router.
      GoRouter.of(
        tester.element(find.byType(Scaffold).first),
      ).go('/c/jane-slug');
      await settle(tester);
      final entry = (await inbox(tester)).single;
      expect(entry.receivedVia, ReceivedVia.link);
      expect(entry.sourceSlug, 'jane-slug');
      expect(find.text('Jane Doe'), findsOneWidget);
    });
  });
}
