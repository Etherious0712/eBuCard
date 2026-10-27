import 'dart:typed_data';

import 'package:ebucard/src/account/account_providers.dart';
import 'package:ebucard/src/account/session_store.dart';
import 'package:ebucard/src/data/app_database.dart';
import 'package:ebucard/src/data/card_repository.dart';
import 'package:ebucard/src/data/providers.dart';
import 'package:ebucard/src/data/received_card_repository.dart';
import 'package:ebucard/src/sync/sync_controller.dart';
import 'package:ebucard_models/ebucard_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_server.dart';
import 'support/test_app.dart';

/// A valid own card.
BusinessCard _card(
  String id, {
  String title = 'Director',
  DateTime? at,
  String? photoUrl,
}) => BusinessCard(
  id: id,
  cardName: 'Work',
  fullName: 'Tai Man Chan',
  jobTitle: title,
  emails: const [LabeledValue(label: ContactLabel.work, value: 'tm@x.com')],
  photoUrl: photoUrl,
  updatedAt: at ?? DateTime.utc(2026, 10, 1),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FakeServer server;
  late MemorySessionStore sessions;
  late FakeCardImageService images;
  late ProviderContainer container;

  setUp(() async {
    db = memoryDatabase();
    server = FakeServer();
    sessions = MemorySessionStore();
    images = FakeCardImageService();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        httpClientProvider.overrideWithValue(server.client),
        sessionStoreProvider.overrideWithValue(sessions),
        cardImageServiceProvider.overrideWithValue(images),
        identitySignInProvider.overrideWithValue(FakeIdentitySignIn()),
      ],
    );
    await container.read(authProvider.future);
    // Keep the sync controller alive, as the home screen does.
    container.listen(syncControllerProvider, (_, _) {});
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  CardRepository cards() => container.read(cardRepositoryProvider);
  ReceivedCardRepository inbox() =>
      container.read(receivedCardRepositoryProvider);
  Future<void> sync() =>
      container.read(syncControllerProvider.notifier).syncNow();
  SyncStatus status() => container.read(syncControllerProvider);
  Future<void> signIn(String email, [String password = 'password!']) =>
      container.read(authProvider.notifier).signIn(email, password);

  test(
    'first sign-in merges this phone\'s cards and Inbox into the account',
    () async {
      await cards().save(_card('c1'));
      await inbox().save(
        ReceivedCard(
          id: 'r1',
          card: _card('x'),
          receivedVia: ReceivedVia.qr,
          receivedAt: DateTime.utc(2026),
          note: 'Met at Expo',
          updatedAt: DateTime.utc(2026),
        ),
      );
      final user = server.addUser('a@x.com', 'password!');
      await signIn('a@x.com');
      await sync();

      expect(server.live(user, 'cards').keys, ['c1']);
      expect(server.live(user, 'received')['r1']!['note'], 'Met at Expo');
      expect(await cards().dirty(), isEmpty);
      expect(status().errorCode, isNull);
      expect(status().lastSuccess, isNotNull);
    },
  );

  test('cards from another phone arrive, in pages', () async {
    final user = server.addUser('a@x.com', 'password!');
    server.pageSize = 2;
    for (var i = 0; i < 5; i++) {
      server.putFromOtherPhone(
        user,
        'cards',
        'c$i',
        _card('c$i').toJson(),
        DateTime.utc(2026, 10, 1),
      );
    }
    await signIn('a@x.com');
    await sync();
    expect((await cards().watchAll().first).length, 5);
    expect(
      await cards().dirty(),
      isEmpty,
      reason: 'pulled cards are not re-sent',
    );
  });

  test('the newest edit wins, whichever phone made it', () async {
    final user = server.addUser('a@x.com', 'password!');
    await signIn('a@x.com');
    await cards().save(
      _card('c1', title: 'Phone v1', at: DateTime.utc(2026, 10, 2)),
    );
    await sync();

    // Another phone edits later: it wins here.
    server.putFromOtherPhone(
      user,
      'cards',
      'c1',
      _card('c1', title: 'Other phone', at: DateTime.utc(2026, 10, 3)).toJson(),
      DateTime.utc(2026, 10, 3),
    );
    await sync();
    expect((await cards().find('c1'))!.jobTitle, 'Other phone');

    // This phone edits even later: it wins on the server.
    await cards().save(
      _card('c1', title: 'Phone v2', at: DateTime.utc(2026, 10, 4)),
    );
    await sync();
    expect(server.live(user, 'cards')['c1']!['jobTitle'], 'Phone v2');
  });

  test('deletions travel both ways', () async {
    final user = server.addUser('a@x.com', 'password!');
    await signIn('a@x.com');
    await cards().save(_card('c1'));
    await cards().save(_card('c2'));
    await sync();

    await cards().delete('c1');
    server.putFromOtherPhone(
      user,
      'cards',
      'c2',
      null,
      DateTime.utc(2026, 10, 5),
    );
    await sync();

    expect(server.live(user, 'cards'), isEmpty);
    expect(await cards().watchAll().first, isEmpty);
  });

  test(
    'photos only on this phone are uploaded and the cards point to them',
    () async {
      final user = server.addUser('a@x.com', 'password!');
      images.files['file:///photo.jpg'] = Uint8List.fromList([
        0xFF,
        0xD8,
        0xFF,
        1,
      ]);
      await cards().save(_card('c1', photoUrl: 'file:///photo.jpg'));
      await signIn('a@x.com');
      await sync();

      final url = server.live(user, 'cards')['c1']!['photoUrl']! as String;
      expect(url, startsWith('https://api.example.com/images/'));
      expect(server.images.values.single, [0xFF, 0xD8, 0xFF, 1]);
      expect((await cards().find('c1'))!.photoUrl, url);
      expect(images.deleted, ['file:///photo.jpg']);
    },
  );

  test('offline: changes wait on the phone and go out later', () async {
    final user = server.addUser('a@x.com', 'password!');
    await signIn('a@x.com');
    await sync();
    server.online = false;
    await cards().save(_card('c1'));
    await sync();
    expect(status().errorCode, 'network');
    expect((await cards().dirty()).length, 1);

    server.online = true;
    await sync();
    expect(server.live(user, 'cards').keys, ['c1']);
    expect(status().errorCode, isNull);
  });

  test('a new account syncs only after its email is confirmed', () async {
    await cards().save(_card('c1'));
    await container
        .read(authProvider.notifier)
        .register('new@x.com', 'password!');
    await sync();
    expect(status().errorCode, 'email_not_verified');
    expect(server.requests.where((r) => r.contains('/v1/cards')), isEmpty);

    server.users['new@x.com']!.verified = true;
    await sync();
    expect(status().errorCode, isNull);
    expect(server.live(server.users['new@x.com']!, 'cards').keys, ['c1']);
  });

  test(
    'an expired access token is renewed without the user noticing',
    () async {
      server.addUser('a@x.com', 'password!');
      await signIn('a@x.com');
      server.expireAccessTokens();
      await sync();
      expect(status().errorCode, isNull);
      expect(server.requests, contains('POST /v1/auth/refresh'));
      expect(container.read(authProvider).value, isNotNull);
    },
  );

  test('an ended session signs out but keeps the data on the phone', () async {
    server.addUser('a@x.com', 'password!');
    await signIn('a@x.com');
    await cards().save(_card('c1'));
    await sync();
    server.expireSessions();
    await sync();

    expect(container.read(authProvider).value, isNull);
    expect(container.read(authProvider.notifier).sessionWasExpired, isTrue);
    expect(await cards().find('c1'), isNotNull);
  });

  test("another account never sees the previous account's data", () async {
    server.addUser('a@x.com', 'password!');
    final b = server.addUser('b@x.com', 'password!');
    await signIn('a@x.com');
    await cards().save(_card('c1'));
    await sync();
    server.expireSessions();
    await sync(); // A is now signed out; A's card is still on the phone.

    await signIn('b@x.com');
    await sync();
    expect(await cards().watchAll().first, isEmpty);
    expect(server.live(b, 'cards'), isEmpty);
  });

  test('the same account signing in again keeps its data', () async {
    final a = server.addUser('a@x.com', 'password!');
    await signIn('a@x.com');
    await cards().save(_card('c1'));
    await sync();
    server.expireSessions();
    await sync();
    await cards().save(_card('c2')); // Made while signed out.

    await signIn('a@x.com');
    await sync();
    expect(server.live(a, 'cards').keys.toSet(), {'c1', 'c2'});
  });

  test('signing out removes the account data from this phone', () async {
    final a = server.addUser('a@x.com', 'password!');
    await signIn('a@x.com');
    await cards().save(_card('c1'));
    await sync();
    await container.read(authProvider.notifier).signOut();

    expect(container.read(authProvider).value, isNull);
    expect(sessions.session, isNull);
    expect(await cards().watchAll().first, isEmpty);
    expect(images.deletedAll, isTrue);
    expect(server.requests, contains('POST /v1/auth/logout'));
    expect(server.live(a, 'cards').keys, [
      'c1',
    ], reason: 'still in the account');
  });

  test('deleting the account signs out and clears the phone', () async {
    final a = server.addUser('a@x.com', 'password!');
    await signIn('a@x.com');
    await cards().save(_card('c1'));
    await sync();
    await container.read(authProvider.notifier).deleteAccount();

    expect(a.deleted, isTrue);
    expect(container.read(authProvider).value, isNull);
    expect(await cards().watchAll().first, isEmpty);
  });

  test('changes on the phone start a sync by themselves', () async {
    final a = server.addUser('a@x.com', 'password!');
    await signIn('a@x.com');
    await sync();
    await cards().save(_card('c1'));
    await Future<void>.delayed(
      SyncController.debounce + const Duration(milliseconds: 500),
    );
    await sync(); // Waits for the automatic run to finish.
    expect(server.live(a, 'cards').keys, ['c1']);
  });
}
