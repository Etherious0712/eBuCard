import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:ebucard_server/src/auth/access_tokens.dart';
import 'package:test/test.dart';

const _secret = 'test-secret-that-is-long-enough-for-hs256!';

void main() {
  var now = DateTime.utc(2026, 10, 27, 9);
  final tokens = AccessTokens(_secret, now: () => now);

  setUp(() => now = DateTime.utc(2026, 10, 27, 9));

  test('a fresh token gives back its user', () {
    expect(tokens.verify(tokens.issue('user-1')), 'user-1');
  });

  test('tokens expire after 15 minutes', () {
    final token = tokens.issue('user-1');
    now = now.add(const Duration(minutes: 14, seconds: 59));
    expect(tokens.verify(token), 'user-1');
    now = now.add(const Duration(seconds: 1));
    expect(tokens.verify(token), isNull);
  });

  test('tokens signed with another secret are rejected', () {
    final other = AccessTokens(
      'another-secret-that-is-long-enough!!',
      now: () => now,
    );
    expect(tokens.verify(other.issue('user-1')), isNull);
  });

  test('tampered or unsigned tokens are rejected', () {
    final parts = tokens.issue('user-1').split('.');
    String b64(Object json) =>
        base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
    final forgedPayload = b64({
      'sub': 'admin',
      'iss': 'ebucard',
      'exp': now.millisecondsSinceEpoch ~/ 1000 + 600,
    });
    expect(tokens.verify('${parts[0]}.$forgedPayload.${parts[2]}'), isNull);
    final noneHeader = b64({'alg': 'none', 'typ': 'JWT'});
    expect(tokens.verify('$noneHeader.$forgedPayload.'), isNull);
    expect(tokens.verify('garbage'), isNull);
  });

  test('other HMAC algorithms are rejected even with the right secret', () {
    final hs512 = JWT(
      {'exp': now.millisecondsSinceEpoch ~/ 1000 + 600},
      subject: 'user-1',
      issuer: 'ebucard',
    ).sign(SecretKey(_secret), algorithm: JWTAlgorithm.HS512);
    expect(tokens.verify(hs512), isNull);
  });
}
