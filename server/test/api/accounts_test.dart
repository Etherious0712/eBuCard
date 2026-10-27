// API responses are checked as plain decoded JSON.
// ignore_for_file: avoid_dynamic_calls

import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:test/test.dart';

import '../../routes/email/verify.dart' as verify_page;
import '../../routes/password/reset.dart' as reset_page;
import '../../routes/v1/account/index.dart' as account;
import '../../routes/v1/auth/apple.dart' as apple;
import '../../routes/v1/auth/login.dart' as login;
import '../../routes/v1/auth/logout.dart' as logout;
import '../../routes/v1/auth/password_reset.dart' as password_reset;
import '../../routes/v1/auth/refresh.dart' as refresh;
import '../../routes/v1/auth/register.dart' as register;
import '../../routes/v1/auth/resend_verification.dart' as resend;
import '../../routes/v1/cards/index.dart' as cards;
import '../support/test_rsa.dart';
import '../support/test_server.dart';

Future<void> main() async {
  final skip = await skipWithoutDatabase();
  if (skip != null) {
    test('database tests', () {}, skip: skip);
    return;
  }
  final appleKey = TestRsaKey.generate('apple-1');
  late TestServer server;

  setUp(() async {
    server = await TestServer.start(
      jwks: {
        'keys': [appleKey.publicJwk],
      },
    );
  });
  tearDown(() => server.close());

  /// Registers [email]; returns the response body.
  Future<Map<String, dynamic>> registerUser(
    String email, {
    String password = 'a good password',
    String? language,
  }) async {
    final response = await server.call(
      register.onRequest,
      jsonRequest(
        HttpMethod.post,
        '/v1/auth/register',
        body: {'email': email, 'password': password},
        acceptLanguage: language,
      ),
    );
    expect(
      response.statusCode,
      HttpStatus.created,
      reason: await response.body(),
    );
    return jsonBody(response);
  }

  /// Opens the confirmation link emailed to [email].
  Future<Response> confirmEmail(String email) => server.call(
    verify_page.onRequest,
    jsonRequest(
      HttpMethod.get,
      '/email/verify?token=${server.email.lastToken(email)}',
    ),
  );

  /// Signs in; returns the response.
  Future<Response> signIn(String email, String password) => server.call(
    login.onRequest,
    jsonRequest(
      HttpMethod.post,
      '/v1/auth/login',
      body: {'email': email, 'password': password},
    ),
  );

  /// Lists cards with [accessToken] (to check sync access).
  Future<Response> listCards(String accessToken) => server.call(
    cards.onRequest,
    jsonRequest(HttpMethod.get, '/v1/cards', accessToken: accessToken),
  );

  /// Trades a refresh token.
  Future<Response> refreshWith(String token) => server.call(
    refresh.onRequest,
    jsonRequest(
      HttpMethod.post,
      '/v1/auth/refresh',
      body: {'refreshToken': token},
    ),
  );

  /// A Sign in with Apple identity token for [sub].
  String appleToken(String sub, {String? email}) => JWT(
    {
      'iss': 'https://appleid.apple.com',
      'aud': 'com.etherious.ebucard',
      'sub': sub,
      'email': ?email,
      if (email != null) 'email_verified': 'true',
      'exp': server.now.millisecondsSinceEpoch ~/ 1000 + 600,
    },
    header: {'kid': 'apple-1'},
  ).sign(appleKey.privateKey, algorithm: JWTAlgorithm.RS256);

  group('register and confirm email', () {
    test('signs in at once, but sync waits for the confirmed email', () async {
      final body = await registerUser('Jane@Example.com');
      expect(body['account']['email'], 'jane@example.com');
      expect(body['account']['canSync'], isFalse);
      final access = body['accessToken'] as String;

      final blocked = await listCards(access);
      expect(blocked.statusCode, HttpStatus.forbidden);
      expect((await jsonBody(blocked))['error'], 'email_not_verified');

      final page = await confirmEmail('jane@example.com');
      expect(page.statusCode, HttpStatus.ok);
      expect(await page.body(), contains('Email confirmed'));
      expect((await listCards(access)).statusCode, HttpStatus.ok);
    });

    test('the email is in the language of the request', () async {
      await registerUser('a@example.com', language: 'zh-HK');
      expect(server.email.sent.single.subject, '確認你的 eBuCard 電郵地址');
      expect(
        server.email.sent.single.body,
        contains('https://api.example.com/email/verify?token='),
      );
    });

    test('a confirmation link works once', () async {
      await registerUser('a@example.com');
      final token = server.email.lastToken('a@example.com');
      Future<Response> open() => server.call(
        verify_page.onRequest,
        jsonRequest(HttpMethod.get, '/email/verify?token=$token'),
      );
      expect((await open()).statusCode, HttpStatus.ok);
      final again = await open();
      expect(again.statusCode, HttpStatus.badRequest);
      expect(await again.body(), contains('This link no longer works'));
    });

    test('confirmation links expire after 24 hours', () async {
      await registerUser('a@example.com');
      server.now = server.now.add(const Duration(hours: 25));
      expect(
        (await confirmEmail('a@example.com')).statusCode,
        HttpStatus.badRequest,
      );
    });

    test('resending cancels the previous link', () async {
      final body = await registerUser('a@example.com');
      final first = server.email.lastToken('a@example.com');
      final response = await server.call(
        resend.onRequest,
        jsonRequest(
          HttpMethod.post,
          '/v1/auth/resend_verification',
          accessToken: body['accessToken'] as String,
        ),
      );
      expect(response.statusCode, HttpStatus.noContent);
      expect(server.email.lastToken('a@example.com'), isNot(first));
      final old = await server.call(
        verify_page.onRequest,
        jsonRequest(HttpMethod.get, '/email/verify?token=$first'),
      );
      expect(old.statusCode, HttpStatus.badRequest);
    });

    test('rejects taken emails and weak or breached passwords', () async {
      await registerUser('a@example.com');
      Future<(int, String?)> attempt(String email, String password) async {
        final r = await server.call(
          register.onRequest,
          jsonRequest(
            HttpMethod.post,
            '/v1/auth/register',
            body: {'email': email, 'password': password},
          ),
        );
        return (r.statusCode, (await jsonBody(r))['error'] as String?);
      }

      expect(await attempt('A@example.com', 'a good password'), (
        409,
        'email_taken',
      ));
      expect(await attempt('b@example.com', 'short'), (
        400,
        'password_too_short',
      ));
      expect(await attempt('b@example.com', 'password123'), (
        400,
        'password_breached',
      ));
      expect(await attempt('not-an-email', 'a good password'), (
        400,
        'invalid_email',
      ));
    });
  });

  group('sign in and sessions', () {
    test('wrong password and unknown email look the same', () async {
      await registerUser('a@example.com');
      final wrong = await signIn('a@example.com', 'wrong password');
      final unknown = await signIn('nobody@example.com', 'whatever pw');
      expect(wrong.statusCode, HttpStatus.unauthorized);
      expect(await wrong.body(), await unknown.body());
      expect(
        (await signIn('A@Example.com', 'a good password')).statusCode,
        200,
      );
    });

    test(
      'refresh tokens rotate; reusing an old one ends the session',
      () async {
        final first =
            (await registerUser('a@example.com'))['refreshToken'] as String;

        final rotated = await refreshWith(first);
        expect(rotated.statusCode, HttpStatus.ok);
        final second = (await jsonBody(rotated))['refreshToken'] as String;
        expect(second, isNot(first));

        // Someone replays the first token: refused, and the real one dies too.
        expect((await refreshWith(first)).statusCode, HttpStatus.unauthorized);
        expect((await refreshWith(second)).statusCode, HttpStatus.unauthorized);
      },
    );

    test('sessions end after 90 days without use, not before', () async {
      var token =
          (await registerUser('a@example.com'))['refreshToken'] as String;
      // Used every 80 days: stays signed in.
      for (var i = 0; i < 3; i++) {
        server.now = server.now.add(const Duration(days: 80));
        final r = await refreshWith(token);
        expect(r.statusCode, HttpStatus.ok);
        token = (await jsonBody(r))['refreshToken'] as String;
      }
      server.now = server.now.add(const Duration(days: 91));
      expect((await refreshWith(token)).statusCode, HttpStatus.unauthorized);
    });

    test('logout ends that session', () async {
      final token =
          (await registerUser('a@example.com'))['refreshToken'] as String;
      final r = await server.call(
        logout.onRequest,
        jsonRequest(
          HttpMethod.post,
          '/v1/auth/logout',
          body: {'refreshToken': token},
        ),
      );
      expect(r.statusCode, HttpStatus.noContent);
      expect((await refreshWith(token)).statusCode, HttpStatus.unauthorized);
    });

    test('too many attempts from one address are slowed down', () async {
      var limited = false;
      for (var i = 0; i < 25 && !limited; i++) {
        limited =
            (await signIn('a@example.com', 'wrong password')).statusCode ==
            HttpStatus.tooManyRequests;
      }
      expect(limited, isTrue);
    });
  });

  group('password reset', () {
    test('full flow: email, form, new password, other sessions end', () async {
      final session = await registerUser('a@example.com');
      final requested = await server.call(
        password_reset.onRequest,
        jsonRequest(
          HttpMethod.post,
          '/v1/auth/password_reset',
          body: {'email': 'a@example.com'},
        ),
      );
      expect(requested.statusCode, HttpStatus.accepted);
      final token = server.email.lastToken('a@example.com');

      final form = await server.call(
        reset_page.onRequest,
        jsonRequest(HttpMethod.get, '/password/reset?token=$token'),
      );
      expect(await form.body(), contains('name="token" value="$token"'));

      Future<Response> submit(String pw, String repeat) => server.call(
        reset_page.onRequest,
        Request(
          'POST',
          Uri.parse('https://api.example.com/password/reset'),
          body: Uri(
            queryParameters: {'token': token, 'password': pw, 'repeat': repeat},
          ).query,
          headers: {'content-type': 'application/x-www-form-urlencoded'},
        ),
      );
      expect(
        await (await submit('new password!', 'different')).body(),
        contains('The two passwords are different.'),
      );
      expect(
        await (await submit('password123', 'password123')).body(),
        contains('data breach'),
      );
      final done = await submit('new password!', 'new password!');
      expect(await done.body(), contains('Password changed'));

      expect(
        (await signIn('a@example.com', 'a good password')).statusCode,
        401,
      );
      expect((await signIn('a@example.com', 'new password!')).statusCode, 200);
      expect(
        (await refreshWith(session['refreshToken'] as String)).statusCode,
        HttpStatus.unauthorized,
      );
      // Resetting by email also confirms the address.
      final me = await server.call(
        account.onRequest,
        jsonRequest(
          HttpMethod.get,
          '/v1/account',
          accessToken:
              (await jsonBody(
                    await signIn('a@example.com', 'new password!'),
                  ))['accessToken']
                  as String,
        ),
      );
      expect((await jsonBody(me))['emailVerified'], isTrue);
    });

    test('unknown emails get the same answer and no email', () async {
      final r = await server.call(
        password_reset.onRequest,
        jsonRequest(
          HttpMethod.post,
          '/v1/auth/password_reset',
          body: {'email': 'nobody@example.com'},
        ),
      );
      expect(r.statusCode, HttpStatus.accepted);
      expect(server.email.sent, isEmpty);
    });
  });

  group('Sign in with Apple', () {
    Future<Map<String, dynamic>> signInApple(
      String sub, {
      String? email,
    }) async {
      final r = await server.call(
        apple.onRequest,
        jsonRequest(
          HttpMethod.post,
          '/v1/auth/apple',
          body: {'identityToken': appleToken(sub, email: email)},
        ),
      );
      expect(r.statusCode, HttpStatus.ok, reason: await r.body());
      return jsonBody(r);
    }

    test(
      'creates an account that can sync at once, then finds it again',
      () async {
        final first = await signInApple(
          'apple-1',
          email: 'x@privaterelay.appleid.com',
        );
        expect(first['account']['canSync'], isTrue);
        expect(first['account']['apple'], isTrue);
        final again = await signInApple('apple-1');
        expect(again['account']['id'], first['account']['id']);
      },
    );

    test('links to a confirmed account with the same email', () async {
      final mine = await registerUser('jane@example.com');
      await confirmEmail('jane@example.com');
      final viaApple = await signInApple('apple-1', email: 'jane@example.com');
      expect(viaApple['account']['id'], mine['account']['id']);
      expect(viaApple['account']['hasPassword'], isTrue);
    });

    test('takes over an unconfirmed account with the same email', () async {
      // Someone registered Jane's email without being able to confirm it.
      final squatter = await registerUser(
        'jane@example.com',
        password: 'squatter pw!',
      );
      final viaApple = await signInApple('apple-1', email: 'jane@example.com');
      expect(viaApple['account']['id'], squatter['account']['id']);
      expect(viaApple['account']['hasPassword'], isFalse);
      expect(
        (await signIn('jane@example.com', 'squatter pw!')).statusCode,
        401,
      );
      expect(
        (await refreshWith(squatter['refreshToken'] as String)).statusCode,
        HttpStatus.unauthorized,
      );
    });
  });

  group('account deletion', () {
    test('signs out now; signing in within 30 days cancels it', () async {
      final body = await registerUser('a@example.com');
      final r = await server.call(
        account.onRequest,
        jsonRequest(
          HttpMethod.delete,
          '/v1/account',
          accessToken: body['accessToken'] as String,
        ),
      );
      expect(r.statusCode, HttpStatus.accepted);
      expect((await jsonBody(r))['deleteAfter'], startsWith('2026-11-26'));
      expect(
        (await refreshWith(body['refreshToken'] as String)).statusCode,
        HttpStatus.unauthorized,
      );
      expect(
        (await listCards(body['accessToken'] as String)).statusCode,
        HttpStatus.unauthorized,
      );

      server.now = server.now.add(const Duration(days: 29));
      final back = await signIn('a@example.com', 'a good password');
      expect(back.statusCode, HttpStatus.ok);
      expect(
        await server.services.purgeDeletedAccounts(
          server.now.add(const Duration(days: 60)),
        ),
        0,
      );
      expect(
        await server.services.accounts.users.byEmail('a@example.com'),
        isNotNull,
      );
    });

    test('after 30 days the account and its images are erased', () async {
      final body = await registerUser('a@example.com');
      await confirmEmail('a@example.com');
      final userId = body['account']['id'] as String;
      final image = await server.services.images.upload(
        userId,
        // Minimal JPEG header bytes.
        Uint8ListHelper.jpeg,
      );
      await server.services.accounts.requestDeletion(userId);

      expect(
        await server.services.purgeDeletedAccounts(
          server.now.add(const Duration(days: 29)),
        ),
        0,
      );
      await server.services.purgeDeletedAccounts(
        server.now.add(const Duration(days: 31)),
      );
      expect(await server.services.accounts.users.byId(userId), isNull);
      expect(server.storage.objects, isNot(contains('images/${image['id']}')));
      expect(
        (await signIn('a@example.com', 'a good password')).statusCode,
        401,
      );
    });
  });
}
