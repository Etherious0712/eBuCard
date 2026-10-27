// Password hashing (Argon2id), the password rules, and the data-breach
// check for new passwords.

import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:pointycastle/export.dart';

/// Hashes and verifies passwords with Argon2id.
///
/// Hashes are stored in the standard PHC string format, e.g.
/// `$argon2id$v=19$m=19456,t=2,p=1$<salt>$<hash>`, so the cost settings can
/// be raised later without breaking existing hashes.
class PasswordHasher {
  /// Creates a hasher. The defaults are OWASP's recommended minimum
  /// (19 MiB memory, 2 passes, 1 lane); tests use cheaper settings.
  const PasswordHasher({
    this.memoryKiB = 19456,
    this.iterations = 2,
    this.parallelism = 1,
  });

  /// Memory cost in KiB.
  final int memoryKiB;

  /// Number of passes.
  final int iterations;

  /// Number of lanes.
  final int parallelism;

  /// Hashes [password] with a fresh random salt. Runs on another isolate
  /// so the server keeps answering other requests meanwhile.
  Future<String> hash(String password) {
    final salt = _randomBytes(16);
    final m = memoryKiB;
    final t = iterations;
    final p = parallelism;
    return Isolate.run(() {
      final digest = argon2id(utf8.encode(password), salt, m, t, p);
      return '\$argon2id\$v=19\$m=$m,t=$t,p=$p'
          '\$${_b64(salt)}\$${_b64(digest)}';
    });
  }

  /// Whether [password] matches [phcHash]. False for malformed hashes.
  Future<bool> verify(String password, String phcHash) async {
    final parts = phcHash.split(r'$');
    // ['', 'argon2id', 'v=19', 'm=..,t=..,p=..', salt, hash]
    if (parts.length != 6 || parts[1] != 'argon2id') return false;
    final params = {
      for (final kv in parts[3].split(','))
        kv.split('=').first: int.tryParse(kv.split('=').last),
    };
    final m = params['m'];
    final t = params['t'];
    final p = params['p'];
    if (m == null || t == null || p == null) return false;
    final salt = _unb64(parts[4]);
    final expected = _unb64(parts[5]);
    final actual = await Isolate.run(
      () => argon2id(utf8.encode(password), salt, m, t, p, expected.length),
    );
    return _constantTimeEquals(actual, expected);
  }

  /// Raw Argon2id. Public so tests can check it against RFC 9106.
  static Uint8List argon2id(
    List<int> password,
    List<int> salt,
    int memoryKiB,
    int iterations,
    int parallelism, [
    int length = 32,
    List<int>? secret,
    List<int>? additionalData,
  ]) {
    final generator = Argon2BytesGenerator()
      ..init(
        Argon2Parameters(
          Argon2Parameters.ARGON2_id,
          Uint8List.fromList(salt),
          desiredKeyLength: length,
          iterations: iterations,
          memory: memoryKiB,
          lanes: parallelism,
          secret: secret == null ? null : Uint8List.fromList(secret),
          additional: additionalData == null
              ? null
              : Uint8List.fromList(additionalData),
        ),
      );
    return generator.process(Uint8List.fromList(password));
  }

  /// Compares without returning early, so timing reveals nothing.
  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  /// Unpadded standard base64, as used in PHC strings.
  static String _b64(List<int> bytes) =>
      base64.encode(bytes).replaceAll('=', '');

  /// Decodes unpadded base64.
  static Uint8List _unb64(String s) =>
      base64.decode(s.padRight((s.length + 3) ~/ 4 * 4, '='));
}

/// Cryptographically secure random bytes.
Uint8List _randomBytes(int length) {
  final random = Random.secure();
  return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
}

/// Why a new password was rejected.
enum PasswordProblem {
  /// Fewer than 8 characters.
  tooShort,

  /// Longer than 128 characters (protects the server from huge inputs).
  tooLong,

  /// Found in known data breaches.
  breached,
}

/// Checks the password rules (DESIGN.md §8): 8–128 characters and not in
/// a known breach. Returns null if the password is acceptable.
Future<PasswordProblem?> checkNewPassword(
  String password,
  BreachChecker breaches,
) async {
  final length = password.runes.length;
  if (length < 8) return PasswordProblem.tooShort;
  if (length > 128) return PasswordProblem.tooLong;
  if (await breaches.isBreached(password)) return PasswordProblem.breached;
  return null;
}

/// Tells whether a password appears in known data breaches. An interface
/// so tests and development can swap in [NoBreachChecker].
// ignore: one_member_abstracts
abstract class BreachChecker {
  /// True if [password] is known to be breached.
  Future<bool> isBreached(String password);
}

/// Uses the Have I Been Pwned "range" API with k-anonymity: only the first
/// 5 hex characters of the password's SHA-1 leave the server, never the
/// password or its full hash.
class HibpBreachChecker implements BreachChecker {
  /// Creates a checker using [client].
  HibpBreachChecker(this.client);

  /// HTTP client (replaceable in tests).
  final http.Client client;

  @override
  Future<bool> isBreached(String password) async {
    final sha1Hex = sha1
        .convert(utf8.encode(password))
        .toString()
        .toUpperCase();
    final prefix = sha1Hex.substring(0, 5);
    final suffix = sha1Hex.substring(5);
    try {
      final response = await client
          .get(
            Uri.parse('https://api.pwnedpasswords.com/range/$prefix'),
            headers: {'Add-Padding': 'true', 'User-Agent': 'eBuCard-server'},
          )
          .timeout(const Duration(seconds: 3));
      if (response.statusCode != 200) return false;
      for (final line in const LineSplitter().convert(response.body)) {
        final parts = line.split(':');
        if (parts.length == 2 &&
            parts[0] == suffix &&
            (int.tryParse(parts[1].trim()) ?? 0) > 0) {
          return true;
        }
      }
      return false;
    } on Object {
      // If the service is down, don't block sign-ups.
      return false;
    }
  }
}

/// A checker that never reports breaches (development / tests).
class NoBreachChecker implements BreachChecker {
  /// Creates the checker.
  const NoBreachChecker();

  @override
  Future<bool> isBreached(String password) async => false;
}

/// A random URL-safe token (256 bits) for refresh and email links.
String newOpaqueToken() =>
    base64Url.encode(_randomBytes(32)).replaceAll('=', '');

/// SHA-256 of a token, as stored in the database. Tokens themselves are
/// never stored, so a database leak can't be used to sign in.
String hashToken(String token) => sha256.convert(utf8.encode(token)).toString();
