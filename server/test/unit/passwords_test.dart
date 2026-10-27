import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:ebucard_server/src/auth/passwords.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

/// Lower-case hex of [bytes].
String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

void main() {
  group('Argon2id', () {
    test('matches the RFC 9106 test vector', () {
      final tag = PasswordHasher.argon2id(
        List.filled(32, 0x01),
        List.filled(16, 0x02),
        32,
        3,
        4,
        32,
        List.filled(8, 0x03),
        List.filled(12, 0x04),
      );
      expect(
        _hex(tag),
        '0d640df58d78766c08c037a34a8b53c9d01ef0452d75b65eb52520e96b01e659',
      );
    });

    const hasher = PasswordHasher(memoryKiB: 64, iterations: 1);

    test('hash verifies the right password only', () async {
      final hash = await hasher.hash('correct horse');
      expect(hash, startsWith(r'$argon2id$v=19$m=64,t=1,p=1$'));
      expect(await hasher.verify('correct horse', hash), isTrue);
      expect(await hasher.verify('wrong horse', hash), isFalse);
    });

    test('same password gives different hashes (random salt)', () async {
      expect(await hasher.hash('x'), isNot(await hasher.hash('x')));
    });

    test('a hash made with other settings still verifies', () async {
      final strong = await const PasswordHasher().hash('pw');
      expect(await hasher.verify('pw', strong), isTrue);
    });

    test('malformed hashes never verify', () async {
      for (final bad in ['', 'plain', r'$argon2i$v=19$m=1,t=1,p=1$a$b']) {
        expect(await hasher.verify('pw', bad), isFalse);
      }
    });
  });

  group('password rules', () {
    test('length and breach checks', () async {
      const none = NoBreachChecker();
      expect(await checkNewPassword('1234567', none), PasswordProblem.tooShort);
      expect(await checkNewPassword('12345678', none), isNull);
      expect(await checkNewPassword('密碼密碼密碼密碼', none), isNull);
      expect(
        await checkNewPassword('a' * 129, none),
        PasswordProblem.tooLong,
      );
    });
  });

  group('HibpBreachChecker', () {
    const password = 'P@ssw0rd-example';
    final sha = sha1.convert(utf8.encode(password)).toString().toUpperCase();

    test('sends only the 5-character prefix and finds the suffix', () async {
      Uri? asked;
      final checker = HibpBreachChecker(
        MockClient((request) async {
          asked = request.url;
          expect(request.headers['Add-Padding'], 'true');
          return http.Response(
            '0000000000000000000000000000000000A:3\r\n'
            '${sha.substring(5)}:42\r\n',
            200,
          );
        }),
      );
      expect(await checker.isBreached(password), isTrue);
      expect(asked!.path, '/range/${sha.substring(0, 5)}');
      expect(asked.toString(), isNot(contains(sha.substring(5))));
    });

    test('padding entries with count 0 are not breaches', () async {
      final checker = HibpBreachChecker(
        MockClient(
          (_) async => http.Response('${sha.substring(5)}:0\r\n', 200),
        ),
      );
      expect(await checker.isBreached(password), isFalse);
    });

    test('service errors do not block sign-up', () async {
      final down = HibpBreachChecker(
        MockClient((_) async => throw http.ClientException('offline')),
      );
      expect(await down.isBreached(password), isFalse);
    });
  });

  test('opaque tokens are random, URL-safe and hashed for storage', () {
    final a = newOpaqueToken();
    expect(a, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
    expect(newOpaqueToken(), isNot(a));
    expect(hashToken(a), hasLength(64));
    expect(hashToken(a), isNot(contains(a)));
  });
}
