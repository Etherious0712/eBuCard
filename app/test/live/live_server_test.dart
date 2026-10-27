// End-to-end check against a real eBuCard server (not run by default).
//
// Two "phones" (each with its own database and session) use the same
// account through the real API client and sync engine:
//
//   EBUCARD_LIVE_API=http://127.0.0.1:8099 \
//   EBUCARD_LIVE_EMAIL_LOG=/path/to/server.log \
//   flutter test test/live
//
// The server must run without SMTP settings, so the confirmation email is
// written to its log, which this test reads to confirm the account.

import 'dart:io';
import 'dart:typed_data';

import 'package:ebucard/src/account/api_client.dart';
import 'package:ebucard/src/account/session_store.dart';
import 'package:ebucard/src/data/app_database.dart';
import 'package:ebucard/src/data/card_repository.dart';
import 'package:ebucard/src/data/received_card_repository.dart';
import 'package:ebucard/src/sync/card_links.dart';
import 'package:ebucard/src/sync/local_sync_state.dart';
import 'package:ebucard/src/sync/sync_engine.dart';
import 'package:ebucard_models/ebucard_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../support/test_app.dart';

/// One simulated phone.
class _Phone {
  _Phone(Uri api)
    : db = memoryDatabase(),
      client = ApiClient(baseUrl: api, sessions: MemorySessionStore());

  final AppDatabase db;
  final ApiClient client;
  final images = FakeCardImageService();

  CardRepository get cards => CardRepository(db);
  ReceivedCardRepository get inbox => ReceivedCardRepository(db);

  Future<void> sync() => SyncEngine(
    api: client,
    cards: cards,
    received: inbox,
    state: LocalSyncState(db),
    images: images,
  ).run();
}

void main() {
  final api = Platform.environment['EBUCARD_LIVE_API'];
  final log = Platform.environment['EBUCARD_LIVE_EMAIL_LOG'];
  final skip = api == null || log == null
      ? 'Set EBUCARD_LIVE_API and EBUCARD_LIVE_EMAIL_LOG to run'
      : null;

  test('two phones keep one account in sync through the real server', () async {
    final base = Uri.parse(api!);
    final email = 'live-${DateTime.now().millisecondsSinceEpoch}@example.com';
    final phoneA = _Phone(base);
    final phoneB = _Phone(base);

    // Phone A: create the account, then confirm it from the logged email.
    final signedIn = SignedIn.fromJson(
      await phoneA.client.postPublic('/v1/auth/register', {
        'email': email,
        'password': 'live test password',
      }),
    );
    await phoneA.client.startSession(signedIn);
    expect(signedIn.account.canSync, isFalse);
    await expectLater(phoneA.sync(), throwsA(isA<ApiError>()));

    final link = RegExp(
      r'http\S+/email/verify\?token=\S+',
    ).allMatches(await File(log!).readAsString()).last.group(0)!;
    expect((await http.get(Uri.parse(link))).statusCode, 200);

    // Phone A: a card with a photo, and an Inbox entry.
    phoneA.images.files['file:///p.jpg'] = Uint8List.fromList([
      0xFF,
      0xD8,
      0xFF,
      0xE0,
      ...List.filled(64, 7),
    ]);
    await phoneA.cards.save(
      BusinessCard(
        id: '6b0f2c1e-0000-4000-8000-000000000001',
        cardName: 'Work',
        fullName: '陳大文',
        jobTitle: 'Director',
        emails: const [
          LabeledValue(label: ContactLabel.work, value: 'tm@x.com'),
        ],
        photoUrl: 'file:///p.jpg',
        updatedAt: DateTime.utc(2026, 10, 27, 1),
      ),
    );
    await phoneA.inbox.save(
      ReceivedCard(
        id: '6b0f2c1e-0000-4000-8000-000000000002',
        card: BusinessCard(
          id: 'x',
          cardName: '',
          fullName: 'Jane Doe',
          updatedAt: DateTime.utc(2026),
        ),
        receivedVia: ReceivedVia.nfc,
        receivedAt: DateTime.utc(2026, 10, 27),
        note: 'Met at Expo',
        updatedAt: DateTime.utc(2026, 10, 27),
      ),
    );
    await phoneA.sync();
    expect(await phoneA.cards.dirty(), isEmpty);

    // Phone B: sign in to the same account and receive everything.
    await phoneB.client.startSession(
      SignedIn.fromJson(
        await phoneB.client.postPublic('/v1/auth/login', {
          'email': email,
          'password': 'live test password',
        }),
      ),
    );
    await phoneB.sync();
    final card = (await phoneB.cards.find(
      '6b0f2c1e-0000-4000-8000-000000000001',
    ))!;
    expect(card.fullName, '陳大文');
    expect(card.photoUrl, startsWith('$api/images/'));
    final photo = await http.get(Uri.parse(card.photoUrl!));
    expect(photo.bodyBytes.take(3), [0xFF, 0xD8, 0xFF]);
    final entry = (await phoneB.inbox.watchAll().first).single;
    expect(entry.note, 'Met at Expo');

    // Phone B edits; phone A gets the edit.
    await phoneB.cards.save(
      BusinessCard.fromJson({
        ...card.toJson(),
        'jobTitle': 'CEO',
        'updatedAt': DateTime.utc(2026, 10, 27, 2).toIso8601String(),
      }),
    );
    await phoneB.sync();
    await phoneA.sync();
    expect(
      (await phoneA.cards.find(
        '6b0f2c1e-0000-4000-8000-000000000001',
      ))!.jobTitle,
      'CEO',
    );

    // The card has a public link; anyone can open it, and the web card
    // and vCard download work too.
    const cardId = '6b0f2c1e-0000-4000-8000-000000000001';
    final slug = (await phoneA.cards.find(cardId))!.shareSlug!;
    final stranger = CardLinks(
      ApiClient(baseUrl: base, sessions: MemorySessionStore()),
      CardRepository(phoneA.db),
      SharePayload(baseUrl: base),
    );
    expect(stranger.slugIn('$api/c/$slug'), slug);
    expect((await stranger.fetch(slug)).jobTitle, 'CEO');
    final page = await http.get(Uri.parse('$api/c/$slug'));
    expect(page.body, contains('陳大文'));
    final vcf = await http.get(Uri.parse('$api/c/$slug?format=vcf'));
    expect(vcf.body, contains('BEGIN:VCARD'));

    // Phone A replaces the link; the old one stops, phone B learns the new.
    final linksA = CardLinks(
      phoneA.client,
      phoneA.cards,
      SharePayload(baseUrl: base),
    );
    await linksA.regenerate(cardId);
    final fresh = (await phoneA.cards.find(cardId))!.shareSlug!;
    expect(fresh, isNot(slug));
    await expectLater(
      stranger.fetch(slug),
      throwsA(isA<ApiError>().having((e) => e.code, 'code', 'not_found')),
    );
    await phoneB.sync();
    expect((await phoneB.cards.find(cardId))!.shareSlug, fresh);

    // Phone A deletes; phone B loses it too, and the link stops.
    await phoneA.cards.delete(cardId);
    await phoneA.sync();
    await phoneB.sync();
    expect(await phoneB.cards.watchAll().first, isEmpty);
    expect((await http.get(Uri.parse('$api/c/$fresh'))).statusCode, 404);

    await phoneA.db.close();
    await phoneB.db.close();
  }, skip: skip);
}
