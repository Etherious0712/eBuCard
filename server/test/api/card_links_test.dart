// API responses are checked as plain decoded JSON.
// ignore_for_file: avoid_dynamic_calls

import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:ebucard_models/ebucard_models.dart';
import 'package:ebucard_server/src/config.dart';
import 'package:ebucard_server/src/web/app_links.dart';
import 'package:test/test.dart';

import '../../routes/c/[slug].dart' as card_link;
import '../../routes/v1/account/index.dart' as account;
import '../../routes/v1/auth/register.dart' as register;
import '../../routes/v1/cards/[id]/index.dart' as card_route;
import '../../routes/v1/cards/[id]/share_link.dart' as share_link;
import '../../routes/v1/cards/index.dart' as cards;
import '../../routes/v1/received/[id].dart' as received_route;
import '../support/test_server.dart';

const _cardId = '0b6c6a43-5a1e-4c1e-9d8c-3f3a3a0e0001';
const _entryId = '0b6c6a43-5a1e-4c1e-9d8c-3f3a3a0e0002';

/// A valid card changed at [updatedAt].
BusinessCard _card(
  DateTime updatedAt, {
  String name = 'Tai Man Chan',
  List<String> websites = const [],
  String? photoUrl,
}) => BusinessCard(
  id: _cardId,
  cardName: 'Work',
  fullName: name,
  jobTitle: 'Director',
  company: 'Acme',
  phones: const [
    LabeledValue(label: ContactLabel.mobile, value: '+852 9123 4567'),
  ],
  emails: const [
    LabeledValue(label: ContactLabel.work, value: 'tm@example.com'),
  ],
  websites: websites,
  photoUrl: photoUrl,
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

  /// A confirmed account (unless [confirm] is false); returns its token.
  Future<String> user(String email, {bool confirm = true}) async {
    final r = await server.call(
      register.onRequest,
      jsonRequest(
        HttpMethod.post,
        '/v1/auth/register',
        body: {'email': email, 'password': 'a good password'},
        ip: email,
      ),
    );
    final body = await jsonBody(r);
    if (confirm) {
      await server.services.accounts.verifyEmail(
        server.email.lastToken(email),
      );
    }
    return body['accessToken'] as String;
  }

  /// Starts a server with [appLinks] and Alice signed in.
  Future<void> start([
    AppLinksConfig appLinks = const AppLinksConfig(),
  ]) async {
    server = await TestServer.start(appLinks: appLinks);
    alice = await user('alice@example.com');
  }

  tearDown(() => server.close());

  final t1 = DateTime.utc(2026, 10, 3);
  final t2 = DateTime.utc(2026, 10, 4);

  /// PUTs [card] as [token]; returns the stored record.
  Future<Map<String, dynamic>> put(BusinessCard card, [String? token]) async =>
      jsonBody(
        await server.call(
          (c) => card_route.onRequest(c, card.id),
          jsonRequest(
            HttpMethod.put,
            '/v1/cards/${card.id}',
            body: card.toJson(),
            accessToken: token ?? alice,
          ),
        ),
      );

  /// Calls share_link with [method] as [token].
  Future<Response> link(HttpMethod method, [String? token]) => server.call(
    (c) => share_link.onRequest(c, _cardId),
    jsonRequest(
      method,
      '/v1/cards/$_cardId/share_link',
      accessToken: token ?? alice,
    ),
  );

  /// Opens `/c/<slug>` like a browser (or with [accept] / [query]).
  Future<Response> open(
    String slug, {
    String accept = 'text/html,application/xhtml+xml,*/*;q=0.8',
    String query = '',
    String? language,
  }) => server.call(
    (c) => card_link.onRequest(c, slug),
    jsonRequest(
      HttpMethod.get,
      '/c/$slug$query',
      accept: accept,
      acceptLanguage: language,
    ),
  );

  String slugOf(Map<String, dynamic> record) =>
      record['data']['shareSlug'] as String;

  group('links are made on sync', () {
    setUp(start);

    test('a synced card gets a random link that later syncs keep', () async {
      final first = await put(_card(t1));
      final slug = slugOf(first);
      expect(slug, matches(RegExp(r'^[0-9A-Za-z]{22}$')));
      expect(slugOf(await put(_card(t2))), slug);

      final page = await jsonBody(
        await server.call(
          cards.onRequest,
          jsonRequest(HttpMethod.get, '/v1/cards?since=0', accessToken: alice),
        ),
      );
      expect((page['changes'] as List).single['data']['shareSlug'], slug);
    });

    test('a slug chosen by the phone is ignored', () async {
      final card = _card(t1);
      final json = card.toJson()..['shareSlug'] = 'aaaaaaaaaaaaaaaaaaaaaa';
      final stored = await put(BusinessCard.fromJson(json));
      expect(slugOf(stored), isNot('aaaaaaaaaaaaaaaaaaaaaa'));
    });
  });

  group('the web card', () {
    setUp(start);

    test('shows the card, escaped, with Save contact', () async {
      final stored = await put(
        _card(
          t1,
          name: '<script>alert(1)</script> Chan',
          websites: ['example.com', 'javascript:alert(1)'],
          photoUrl: 'https://api.example.com/images/photo-1',
        ),
      );
      final r = await open(slugOf(stored));
      expect(r.statusCode, HttpStatus.ok);
      expect(r.headers['content-type'], startsWith('text/html'));
      expect(r.headers['x-robots-tag'], contains('noindex'));
      final html = await r.body();
      expect(html, isNot(contains('<script>')));
      expect(html, contains('&lt;script&gt;alert(1)&lt;/script&gt; Chan'));
      expect(html, contains('Director · Acme'));
      expect(html, contains('href="?format=vcf"'));
      expect(html, contains('Save contact'));
      expect(html, contains('href="tel:+85291234567"'));
      expect(html, contains('href="mailto:tm@example.com"'));
      expect(html, contains('href="https://example.com"'));
      expect(html, isNot(contains('href="javascript')));
      expect(html, contains('src="/images/photo-1"'));
      // No store listings yet, so no store buttons.
      expect(html, isNot(contains('Google Play')));
    });

    test('speaks the visitor language', () async {
      final slug = slugOf(await put(_card(t1)));
      final hant = await (await open(slug, language: 'zh-HK')).body();
      expect(hant, contains('lang="zh-Hant"'));
      expect(hant, contains('儲存聯絡人'));
      final hans = await (await open(slug, language: 'zh-CN,zh')).body();
      expect(hans, contains('保存联系人'));
    });

    test('downloads as vCard and reads as JSON for the app', () async {
      final slug = slugOf(await put(_card(t1)));
      final vcf = await open(slug, query: '?format=vcf');
      expect(vcf.headers['content-type'], startsWith('text/vcard'));
      expect(vcf.headers['content-disposition'], contains('attachment'));
      expect(await vcf.body(), contains('FN:Tai Man Chan'));
      expect(
        await (await open(slug, accept: 'text/vcard')).body(),
        contains('BEGIN:VCARD'),
      );

      final json = await jsonBody(
        await open(slug, accept: 'application/json'),
      );
      final card = BusinessCard.fromJson(
        json['card'] as Map<String, Object?>,
      );
      expect(card.fullName, 'Tai Man Chan');
      expect(card.shareSlug, slug);
    });

    test('unknown and malformed links are 404', () async {
      final r = await open('aaaaaaaaaaaaaaaaaaaaaa');
      expect(r.statusCode, HttpStatus.notFound);
      expect(await r.body(), contains('no longer active'));
      expect((await open('../etc')).statusCode, HttpStatus.notFound);
      final json = await open('nope', accept: 'application/json');
      expect(json.statusCode, HttpStatus.notFound);
      expect((await jsonBody(json))['error'], 'not_found');
    });

    test('opening links is rate limited per address', () async {
      for (var i = 0; i < 120; i++) {
        await open('aaaaaaaaaaaaaaaaaaaaaa');
      }
      expect(
        (await open('aaaaaaaaaaaaaaaaaaaaaa')).statusCode,
        HttpStatus.tooManyRequests,
      );
    });
  });

  test('store buttons show once their settings exist', () async {
    await start(
      AppLinksConfig(
        playStoreUrl: Uri.parse('https://play.google.com/store/apps/x'),
        appStoreUrl: Uri.parse('https://apps.apple.com/app/id1'),
      ),
    );
    final html = await (await open(slugOf(await put(_card(t1))))).body();
    expect(html, contains('href="https://play.google.com/store/apps/x"'));
    expect(html, contains('Download on the App Store'));
  });

  group('the owner controls the link', () {
    setUp(start);

    test('a new link replaces the old one, on every phone', () async {
      final old = slugOf(await put(_card(t1)));
      final cursor =
          (await jsonBody(
                await server.call(
                  cards.onRequest,
                  jsonRequest(
                    HttpMethod.get,
                    '/v1/cards?since=0',
                    accessToken: alice,
                  ),
                ),
              ))['cursor']
              as int;

      final r = await link(HttpMethod.post);
      expect(r.statusCode, HttpStatus.ok);
      final fresh = slugOf(await jsonBody(r));
      expect(fresh, isNot(old));
      expect((await open(old)).statusCode, HttpStatus.notFound);
      expect((await open(fresh)).statusCode, HttpStatus.ok);

      // Other phones learn about it on their next sync.
      final page = await jsonBody(
        await server.call(
          cards.onRequest,
          jsonRequest(
            HttpMethod.get,
            '/v1/cards?since=$cursor',
            accessToken: alice,
          ),
        ),
      );
      expect((page['changes'] as List).single['data']['shareSlug'], fresh);
    });

    test('a revoked link stays off until the owner asks again', () async {
      final old = slugOf(await put(_card(t1)));
      final r = await jsonBody(await link(HttpMethod.delete));
      expect(r['data']['shareSlug'], isNull);
      expect((await open(old)).statusCode, HttpStatus.notFound);
      expect((await put(_card(t2)))['data']['shareSlug'], isNull);

      final again = slugOf(await jsonBody(await link(HttpMethod.post)));
      expect((await open(again)).statusCode, HttpStatus.ok);
    });

    test('deleting the card ends its link', () async {
      final slug = slugOf(await put(_card(t1)));
      await server.call(
        (c) => card_route.onRequest(c, _cardId),
        jsonRequest(
          HttpMethod.delete,
          '/v1/cards/$_cardId',
          body: {'updatedAt': t2.toIso8601String()},
          accessToken: alice,
        ),
      );
      expect((await open(slug)).statusCode, HttpStatus.notFound);
      expect((await link(HttpMethod.post)).statusCode, HttpStatus.notFound);
    });

    test('links stop when the owner asks to delete the account', () async {
      final slug = slugOf(await put(_card(t1)));
      await server.call(
        account.onRequest,
        jsonRequest(HttpMethod.delete, '/v1/account', accessToken: alice),
      );
      expect((await open(slug)).statusCode, HttpStatus.notFound);
    });

    test("other people can't change the link", () async {
      await put(_card(t1));
      final bob = await user('bob@example.com');
      expect((await link(HttpMethod.post, bob)).statusCode, 404);
      final carol = await user('carol@example.com', confirm: false);
      expect((await link(HttpMethod.post, carol)).statusCode, 403);
      expect(
        (await server.call(
          (c) => share_link.onRequest(c, 'not-a-uuid'),
          jsonRequest(
            HttpMethod.post,
            '/v1/cards/not-a-uuid/share_link',
            accessToken: alice,
          ),
        )).statusCode,
        404,
      );
    });
  });

  test('Inbox entries keep only images from this server', () async {
    await start();
    final entry = ReceivedCard(
      id: _entryId,
      card: BusinessCard(
        id: 'x',
        cardName: '',
        fullName: 'Someone',
        emails: const [LabeledValue(label: ContactLabel.work, value: 'a@b.c')],
        photoUrl: 'https://api.example.com/images/p1',
        logoUrl: 'https://elsewhere.example/logo.png',
        updatedAt: t1,
      ),
      receivedVia: ReceivedVia.link,
      receivedAt: t1,
      updatedAt: t1,
      sourceSlug: 'aaaaaaaaaaaaaaaaaaaaaa',
    );
    final stored = await jsonBody(
      await server.call(
        (c) => received_route.onRequest(c, _entryId),
        jsonRequest(
          HttpMethod.put,
          '/v1/received/$_entryId',
          body: entry.toJson(),
          accessToken: alice,
        ),
      ),
    );
    final data = stored['data'] as Map<String, dynamic>;
    expect(data['card']['photoUrl'], 'https://api.example.com/images/p1');
    expect(data['card']['logoUrl'], isNull);
    expect(data['sourceSlug'], 'aaaaaaaaaaaaaaaaaaaaaa');
  });

  group('app-link files', () {
    /// Fetches [path] through the app-link middleware.
    Future<Response> wellKnown(String path) => server.call(
      (c) async => appLinkFiles()((_) => Response(statusCode: 418))(c),
      jsonRequest(HttpMethod.get, path),
    );

    test('are off until configured', () async {
      await start();
      expect(
        (await wellKnown('/.well-known/assetlinks.json')).statusCode,
        404,
      );
      expect(
        (await wellKnown('/.well-known/apple-app-site-association')).statusCode,
        404,
      );
      // Other paths go to the routes.
      expect((await wellKnown('/health')).statusCode, 418);
    });

    test('describe the app once configured', () async {
      await start(
        const AppLinksConfig(
          appleTeamId: 'TEAM123456',
          androidCertSha256: ['AB:CD'],
        ),
      );
      final android = await wellKnown('/.well-known/assetlinks.json');
      expect(android.headers['content-type'], 'application/json');
      expect(
        await android.body(),
        contains('"package_name":"com.etherious.ebucard"'),
      );
      expect(await android.body(), contains('"AB:CD"'));
      final apple = await (await wellKnown(
        '/.well-known/apple-app-site-association',
      )).body();
      expect(apple, contains('TEAM123456.com.etherious.ebucard'));
      expect(apple, contains('/c/*'));
    });
  });
}
