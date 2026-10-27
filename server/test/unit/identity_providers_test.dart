import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:ebucard_server/src/auth/identity_providers.dart';
import 'package:ebucard_server/src/http/api_error.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import '../support/test_rsa.dart';

void main() {
  final key = TestRsaKey.generate('key-1');
  final attacker = TestRsaKey.generate('key-1');
  final now = DateTime.utc(2026, 10, 27, 9);
  var keyFetches = 0;
  final client = MockClient((request) async {
    keyFetches++;
    return http.Response(
      jsonEncode({
        'keys': [key.publicJwk],
      }),
      200,
    );
  });

  /// An Apple-style identity token with [claims] overriding the defaults.
  String token({
    Map<String, Object?> claims = const {},
    TestRsaKey? signer,
    String kid = 'key-1',
    JWTAlgorithm algorithm = JWTAlgorithm.RS256,
  }) {
    final payload = {
      'iss': 'https://appleid.apple.com',
      'aud': 'com.etherious.ebucard',
      'sub': 'apple-user-1',
      'email': 'Jane@Example.com',
      'email_verified': 'true',
      'exp': now.millisecondsSinceEpoch ~/ 1000 + 600,
      ...claims,
    };
    return JWT(
      payload,
      header: {'kid': kid},
    ).sign((signer ?? key).privateKey, algorithm: algorithm);
  }

  IdentityTokenVerifier apple([
    List<String> ids = const ['com.etherious.ebucard'],
  ]) => IdentityTokenVerifier(
    IdentityProvider.apple(ids),
    client,
    now: () => now,
  );

  Matcher rejected(String code) => throwsA(
    isA<ApiException>().having((e) => e.code, 'code', code),
  );

  test('a valid token gives the Apple user', () async {
    final identity = await apple().verify(token());
    expect(identity.subject, 'apple-user-1');
    expect(identity.email, 'jane@example.com');
    expect(identity.emailVerified, isTrue);
  });

  test('keys are cached between sign-ins', () async {
    final verifier = apple();
    keyFetches = 0;
    await verifier.verify(token());
    await verifier.verify(token());
    expect(keyFetches, 1);
  });

  test('wrong audience, issuer or expiry is rejected', () async {
    final verifier = apple();
    for (final claims in [
      {'aud': 'some.other.app'},
      {'iss': 'https://evil.example'},
      {'exp': now.millisecondsSinceEpoch ~/ 1000 - 120},
      {'sub': ''},
    ]) {
      expect(
        verifier.verify(token(claims: claims)),
        rejected('invalid_identity_token'),
        reason: '$claims',
      );
    }
  });

  test('a token signed with a key not published by Apple is rejected', () {
    expect(
      apple().verify(token(signer: attacker)),
      rejected('invalid_identity_token'),
    );
    expect(
      apple().verify(token(kid: 'unknown')),
      rejected('invalid_identity_token'),
    );
  });

  test('HMAC tokens are rejected (algorithm confusion)', () {
    final hs = JWT(
      {'sub': 'x'},
      header: {'kid': 'key-1'},
    ).sign(SecretKey(jsonEncode(key.publicJwk)));
    expect(apple().verify(hs), rejected('invalid_identity_token'));
  });

  test('audience may be a list', () async {
    final identity = await apple().verify(
      token(
        claims: {
          'aud': ['x', 'com.etherious.ebucard'],
        },
      ),
    );
    expect(identity.subject, 'apple-user-1');
  });

  test('a provider without client ids is not configured', () {
    expect(
      apple(const []).verify(token()),
      rejected('provider_not_configured'),
    );
  });

  test(
    'Google accepts both issuer spellings and boolean email_verified',
    () async {
      final google = IdentityTokenVerifier(
        IdentityProvider.google(const ['google-client']),
        client,
        now: () => now,
      );
      final identity = await google.verify(
        token(
          claims: {
            'iss': 'accounts.google.com',
            'aud': 'google-client',
            'email_verified': true,
          },
        ),
      );
      expect(identity.emailVerified, isTrue);
    },
  );
}
