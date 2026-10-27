// Short-lived access tokens: signed JWTs the app sends as
// `Authorization: Bearer <token>`. They expire after 15 minutes; the app
// then uses its refresh token to get a new one.

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:ebucard_server/src/auth/jwt_header.dart';

/// Creates and checks access tokens (HS256).
class AccessTokens {
  /// Creates the service with the signing [secret].
  AccessTokens(String secret, {DateTime Function()? now})
    : _key = SecretKey(secret),
      _now = now ?? DateTime.now;

  final SecretKey _key;
  final DateTime Function() _now;

  /// How long an access token is valid.
  static const lifetime = Duration(minutes: 15);

  static const _issuer = 'ebucard';

  /// A new access token for [userId].
  String issue(String userId) {
    final now = _now();
    return JWT(
      {
        'iat': now.millisecondsSinceEpoch ~/ 1000,
        'exp': now.add(lifetime).millisecondsSinceEpoch ~/ 1000,
      },
      subject: userId,
      issuer: _issuer,
    ).sign(_key, noIssueAt: true); // HS256, the library's default.
  }

  /// The user id in [token], or null if it is invalid or expired.
  String? verify(String token) {
    // Only accept tokens signed the way this server signs them.
    if (jwtHeader(token)?['alg'] != 'HS256') return null;
    try {
      final jwt = JWT.verify(
        token,
        _key,
        issuer: _issuer,
        checkExpiresIn: false,
      );
      final payload = jwt.payload as Map<String, dynamic>;
      final exp = payload['exp'];
      if (exp is! int || _now().millisecondsSinceEpoch ~/ 1000 >= exp) {
        return null;
      }
      return jwt.subject;
    } on Object {
      // Malformed tokens can raise other errors than JWTException.
      return null;
    }
  }
}
