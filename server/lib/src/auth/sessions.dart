// Refresh tokens: what keeps a phone signed in.
//
// Each sign-in gets a random refresh token (only its hash is stored). The
// app trades it for a new access token, and every trade also replaces the
// refresh token ("rotation") and pushes its expiry 90 days ahead. So a phone
// stays signed in until sign-out, unless the app isn't opened for 90 days.
//
// If an old, already-replaced refresh token is used again, someone may have
// copied it, so every session of that user is ended (reuse detection).

import 'package:ebucard_server/src/auth/passwords.dart';
import 'package:ebucard_server/src/http/api_error.dart';
import 'package:postgres/postgres.dart';

/// A refresh token that was traded in: whose it is and its replacement.
class RotatedSession {
  /// Creates the result.
  const RotatedSession(this.userId, this.refreshToken);

  /// The signed-in user.
  final String userId;

  /// The new refresh token; the old one no longer works.
  final String refreshToken;
}

/// Issues, rotates and revokes refresh tokens.
class Sessions {
  /// Creates the store over [_db]. [now] can be replaced in tests.
  Sessions(this._db, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  final Pool<void> _db;
  final DateTime Function() _now;

  /// Unused sessions end after this long.
  static const idleLimit = Duration(days: 90);

  /// Starts a session for [userId]; returns the new refresh token.
  Future<String> issue(String userId, {Session? tx}) async {
    final token = newOpaqueToken();
    await (tx ?? _db).execute(
      Sql.named(
        'INSERT INTO refresh_tokens (id, user_id, token_hash, expires_at) '
        'VALUES (gen_random_uuid(), @user, @hash, @expires)',
      ),
      parameters: {
        'user': userId,
        'hash': hashToken(token),
        'expires': _now().add(idleLimit).toUtc(),
      },
    );
    return token;
  }

  /// Trades [refreshToken] for a new one. Throws a 401 if it is unknown,
  /// expired or revoked (and in the last case ends all the user's sessions).
  Future<RotatedSession> rotate(String refreshToken) async {
    const invalid = ApiException.unauthorized('invalid_refresh_token');
    // The transaction returns null for "reused token: revoke everything".
    // That revocation runs after it, because throwing inside the
    // transaction would roll the revocation back.
    String? reusedBy;
    final rotated = await _db.runTx<RotatedSession?>((tx) async {
      final rows = await tx.execute(
        Sql.named(
          'SELECT id, user_id::text, expires_at, revoked_at '
          'FROM refresh_tokens WHERE token_hash = @hash FOR UPDATE',
        ),
        parameters: {'hash': hashToken(refreshToken)},
      );
      if (rows.isEmpty) throw invalid;
      final row = rows.first.toColumnMap();
      final userId = row['user_id']! as String;
      if (row['revoked_at'] != null) {
        reusedBy = userId;
        return null;
      }
      if ((row['expires_at']! as DateTime).isBefore(_now())) throw invalid;
      await tx.execute(
        Sql.named('UPDATE refresh_tokens SET revoked_at = @now WHERE id = @id'),
        parameters: {'id': row['id'], 'now': _now().toUtc()},
      );
      return RotatedSession(userId, await issue(userId, tx: tx));
    });
    if (rotated != null) return rotated;
    await revokeAll(reusedBy!);
    throw invalid;
  }

  /// Ends the session of [refreshToken] (sign-out). Unknown tokens are
  /// ignored.
  Future<void> revoke(String refreshToken) => _db.execute(
    Sql.named(
      'UPDATE refresh_tokens SET revoked_at = @now '
      'WHERE token_hash = @hash AND revoked_at IS NULL',
    ),
    parameters: {'hash': hashToken(refreshToken), 'now': _now().toUtc()},
  );

  /// Ends every session of [userId] (password change, account deletion,
  /// suspected token theft).
  Future<void> revokeAll(String userId, {Session? tx}) => (tx ?? _db).execute(
    Sql.named(
      'UPDATE refresh_tokens SET revoked_at = @now '
      'WHERE user_id = @user AND revoked_at IS NULL',
    ),
    parameters: {'user': userId, 'now': _now().toUtc()},
  );
}
