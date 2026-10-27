// API responses are checked as plain decoded JSON.
// ignore_for_file: avoid_dynamic_calls

import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_models/ebucard_models.dart';
import 'package:test/test.dart';

import '../../routes/images/[id].dart' as public_image;
import '../../routes/v1/auth/register.dart' as register;
import '../../routes/v1/cards/[id]/index.dart' as card_route;
import '../../routes/v1/cards/index.dart' as cards;
import '../../routes/v1/images/[id].dart' as image_route;
import '../../routes/v1/images/index.dart' as images;
import '../../routes/v1/received/[id].dart' as received_route;
import '../../routes/v1/received/index.dart' as received;
import '../support/test_server.dart';

const _cardId = '0b6c6a43-5a1e-4c1e-9d8c-3f3a3a0e0001';

/// A valid card with [title], changed at [updatedAt].
BusinessCard _card(
  DateTime updatedAt, {
  String id = _cardId,
  String title = 'Director',
  String? photoUrl,
}) => BusinessCard(
  id: id,
  cardName: 'Work',
  fullName: 'Tai Man Chan',
  jobTitle: title,
  emails: const [
    LabeledValue(label: ContactLabel.work, value: 'tm@example.com'),
  ],
  photoUrl: photoUrl,
  shareSlug: 'chosen-by-phone',
  updatedAt: updatedAt,
);

Future<void> main() async {
  final skip = await skipWithoutDatabase();
  if (skip != null) {
    test('database tests', () {}, skip: skip);
    return;
  }
  late TestServer server;
  late String alice;
  late String bob;

  /// A confirmed account; returns its access token.
  Future<String> confirmedUser(String email) async {
    final r = await server.call(
      register.onRequest,
      jsonRequest(
        HttpMethod.post,
        '/v1/auth/register',
        body: {'email': email, 'password': 'a good password'},
        ip: email, // Separate rate-limit bucket per user.
      ),
    );
    final body = await jsonBody(r);
    await server.services.accounts.verifyEmail(server.email.lastToken(email));
    return body['accessToken'] as String;
  }

  setUp(() async {
    server = await TestServer.start();
    alice = await confirmedUser('alice@example.com');
    bob = await confirmedUser('bob@example.com');
  });
  tearDown(() => server.close());

  /// PUT a card as [token].
  Future<Response> putCard(String token, BusinessCard card, {String? id}) =>
      server.call(
        (c) => card_route.onRequest(c, id ?? card.id),
        jsonRequest(
          HttpMethod.put,
          '/v1/cards/${id ?? card.id}',
          body: card.toJson(),
          accessToken: token,
        ),
      );

  /// GET card changes since [cursor].
  Future<Map<String, dynamic>> cardChanges(
    String token, [
    int cursor = 0,
  ]) async => jsonBody(
    await server.call(
      cards.onRequest,
      jsonRequest(
        HttpMethod.get,
        '/v1/cards?since=$cursor',
        accessToken: token,
      ),
    ),
  );

  final t1 = DateTime.utc(2026, 10, 3);
  final t2 = DateTime.utc(2026, 10, 4);

  test('a stored card comes back in the change list', () async {
    final r = await putCard(alice, _card(t1));
    expect(r.statusCode, HttpStatus.ok);
    final page = await cardChanges(alice);
    final change = (page['changes'] as List).single as Map<String, dynamic>;
    expect(change['id'], _cardId);
    expect(change['data']['jobTitle'], 'Director');
    expect(page['hasMore'], isFalse);
    // Nothing new after the returned cursor.
    expect(
      (await cardChanges(alice, page['cursor'] as int))['changes'],
      isEmpty,
    );
  });

  test('last writer wins by updatedAt', () async {
    await putCard(alice, _card(t2, title: 'Newer'));
    final older = await putCard(alice, _card(t1, title: 'Older'));
    expect((await jsonBody(older))['data']['jobTitle'], 'Newer');
    final newest = await putCard(
      alice,
      _card(t2.add(const Duration(seconds: 1)), title: 'Newest'),
    );
    expect((await jsonBody(newest))['data']['jobTitle'], 'Newest');
  });

  test('deletes become tombstones, unless the server copy is newer', () async {
    await putCard(alice, _card(t1));
    Future<Map<String, dynamic>> delete(DateTime at) async => jsonBody(
      await server.call(
        (c) => card_route.onRequest(c, _cardId),
        jsonRequest(
          HttpMethod.delete,
          '/v1/cards/$_cardId',
          body: {'updatedAt': at.toIso8601String()},
          accessToken: alice,
        ),
      ),
    );
    expect(
      (await delete(t1.subtract(const Duration(days: 1))))['deleted'],
      isFalse,
    );
    final gone = await delete(t2);
    expect(gone['deleted'], isTrue);
    expect(gone.containsKey('data'), isFalse);
    final change =
        ((await cardChanges(alice))['changes'] as List).single as Map;
    expect(change['deleted'], isTrue);
  });

  test("other people's cards are invisible and untouchable", () async {
    await putCard(alice, _card(t1));
    expect((await cardChanges(bob))['changes'], isEmpty);
    final r = await putCard(bob, _card(t2, title: 'Hijacked'));
    expect(r.statusCode, HttpStatus.notFound);
    final mine = ((await cardChanges(alice))['changes'] as List).single as Map;
    expect(mine['data']['jobTitle'], 'Director');
  });

  test('cards must pass the same rules as in the app', () async {
    final noContact = BusinessCard(
      id: _cardId,
      cardName: 'Work',
      fullName: 'X',
      updatedAt: t1,
    );
    final r = await putCard(alice, noContact);
    expect(r.statusCode, 422);
    expect((await jsonBody(r))['details'], ['phoneOrEmailRequired']);

    final mismatch = await putCard(
      alice,
      _card(t1),
      id: '0b6c6a43-5a1e-4c1e-9d8c-3f3a3a0e0002',
    );
    expect((await jsonBody(mismatch))['error'], 'id_mismatch');

    final badId = await putCard(alice, _card(t1), id: 'not-a-uuid');
    expect(badId.statusCode, HttpStatus.notFound);
  });

  test(
    "only images hosted here are kept; the share link is the server's",
    () async {
      final r = await putCard(
        alice,
        _card(t1, photoUrl: 'https://tracker.example/pixel.jpg'),
      );
      final stored = (await jsonBody(r))['data'] as Map;
      expect(stored['photoUrl'], isNull);
      expect(stored['shareSlug'], isNull);

      final own = await putCard(
        alice,
        _card(t2, photoUrl: 'https://api.example.com/images/abc'),
      );
      expect(
        ((await jsonBody(own))['data'] as Map)['photoUrl'],
        'https://api.example.com/images/abc',
      );
    },
  );

  test('large change lists come in pages', () async {
    for (var i = 0; i < 205; i++) {
      final id =
          '0b6c6a43-5a1e-4c1e-9d8c-${(i + 1).toString().padLeft(12, '0')}';
      await putCard(alice, _card(t1, id: id));
    }
    final first = await cardChanges(alice);
    expect((first['changes'] as List).length, 200);
    expect(first['hasMore'], isTrue);
    final second = await cardChanges(alice, first['cursor'] as int);
    expect((second['changes'] as List).length, 5);
    expect(second['hasMore'], isFalse);
  });

  test('Inbox entries sync too, without images', () async {
    const id = '0b6c6a43-5a1e-4c1e-9d8c-3f3a3a0e0099';
    final entry = ReceivedCard(
      id: id,
      card: _card(t1, id: 'x', photoUrl: 'https://tracker.example/p.jpg'),
      receivedVia: ReceivedVia.qr,
      receivedAt: t1,
      note: 'Met at Expo',
      updatedAt: t1,
    );
    final r = await server.call(
      (c) => received_route.onRequest(c, id),
      jsonRequest(
        HttpMethod.put,
        '/v1/received/$id',
        body: entry.toJson(),
        accessToken: alice,
      ),
    );
    expect(r.statusCode, HttpStatus.ok, reason: await r.body());
    final page = await jsonBody(
      await server.call(
        received.onRequest,
        jsonRequest(HttpMethod.get, '/v1/received', accessToken: alice),
      ),
    );
    final data = ((page['changes'] as List).single as Map)['data'] as Map;
    expect(data['note'], 'Met at Expo');
    expect((data['card'] as Map)['photoUrl'], isNull);
  });

  test('requests without a valid token are refused', () async {
    final r = await server.call(
      cards.onRequest,
      jsonRequest(HttpMethod.get, '/v1/cards', accessToken: 'garbage'),
    );
    expect(r.statusCode, HttpStatus.unauthorized);
  });

  group('images', () {
    Future<Response> upload(String token, List<int> bytes) => server.call(
      images.onRequest,
      Request(
        'POST',
        Uri.parse('https://api.example.com/v1/images'),
        body: bytes,
        headers: {
          'authorization': 'Bearer $token',
          'x-forwarded-for': '1.1.1.1',
        },
      ),
    );

    test('upload, public download, and delete by the owner only', () async {
      final r = await upload(alice, Uint8ListHelper.jpeg);
      expect(r.statusCode, HttpStatus.created);
      final body = await jsonBody(r);
      final id = body['id'] as String;
      expect(body['url'], 'https://api.example.com/images/$id');

      final download = await server.call(
        (c) => public_image.onRequest(c, id),
        jsonRequest(HttpMethod.get, '/images/$id'),
      );
      expect(download.statusCode, HttpStatus.ok);
      expect(download.headers['content-type'], 'image/jpeg');
      expect(
        await download.bytes().expand((b) => b).toList(),
        Uint8ListHelper.jpeg,
      );

      Future<int> deleteAs(String token) async => (await server.call(
        (c) => image_route.onRequest(c, id),
        jsonRequest(HttpMethod.delete, '/v1/images/$id', accessToken: token),
      )).statusCode;
      expect(await deleteAs(bob), HttpStatus.notFound);
      expect(await deleteAs(alice), HttpStatus.noContent);
      expect(server.storage.objects, isEmpty);
    });

    test('only JPEG/PNG up to 2 MB', () async {
      expect(
        (await upload(alice, Uint8ListHelper.png)).statusCode,
        HttpStatus.created,
      );
      expect((await upload(alice, 'GIF89a....'.codeUnits)).statusCode, 415);
      expect(
        (await upload(alice, [
          ...Uint8ListHelper.jpeg,
          ...List.filled(2 * 1024 * 1024, 0),
        ])).statusCode,
        413,
      );
    });

    test('unknown or malformed image ids are 404', () async {
      for (final id in [
        '0b6c6a43-5a1e-4c1e-9d8c-3f3a3a0e0001',
        "1' OR '1'='1",
      ]) {
        final r = await server.call(
          (c) => public_image.onRequest(c, id),
          jsonRequest(HttpMethod.get, '/images/x'),
        );
        expect(r.statusCode, HttpStatus.notFound);
      }
    });
  });
}
