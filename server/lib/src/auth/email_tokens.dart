// One-time tokens sent by email: "confirm your email" (24 hours) and
// "reset your password" (1 hour). Only hashes are stored; a token works
// once, and asking for a new one cancels the previous one.

import 'package:ebucard_server/src/auth/passwords.dart';
import 'package:postgres/postgres.dart';

/// What an email token is for.
enum EmailTokenPurpose {
  /// Confirm the email address.
  verify,

  /// Choose a new password.
  reset,
}

/// Creates and redeems email tokens.
class EmailTokens {
  /// Creates the store over [_db]. [now] can be replaced in tests.
  EmailTokens(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final Pool<void> _db;
  final DateTime Function() _now;

  /// How long each kind of token works.
  static Duration lifetime(EmailTokenPurpose purpose) => switch (purpose) {
    EmailTokenPurpose.verify => const Duration(hours: 24),
    EmailTokenPurpose.reset => const Duration(hours: 1),
  };

  /// A new token for [userId], replacing earlier unused ones.
  Future<String> create(String userId, EmailTokenPurpose purpose) => _db.runTx((
    tx,
  ) async {
    final now = _now().toUtc();
    await tx.execute(
      Sql.named(
        'UPDATE email_tokens SET used_at = @now '
        'WHERE user_id = @user AND purpose = @purpose AND used_at IS NULL',
      ),
      parameters: {'user': userId, 'purpose': purpose.name, 'now': now},
    );
    final token = newOpaqueToken();
    await tx.execute(
      Sql.named(
        'INSERT INTO email_tokens '
        '(id, user_id, purpose, token_hash, expires_at) '
        'VALUES (gen_random_uuid(), @user, @purpose, @hash, @expires)',
      ),
      parameters: {
        'user': userId,
        'purpose': purpose.name,
        'hash': hashToken(token),
        'expires': now.add(lifetime(purpose)),
      },
    );
    return token;
  });

  /// Uses up [token]; returns its user id, or null if it is unknown,
  /// expired, already used, or for another purpose.
  Future<String?> redeem(String token, EmailTokenPurpose purpose) async {
    final now = _now().toUtc();
    final rows = await _db.execute(
      Sql.named(
        'UPDATE email_tokens SET used_at = @now '
        'WHERE token_hash = @hash AND purpose = @purpose '
        'AND used_at IS NULL AND expires_at > @now '
        'RETURNING user_id::text',
      ),
      parameters: {
        'hash': hashToken(token),
        'purpose': purpose.name,
        'now': now,
      },
    );
    return rows.isEmpty ? null : rows.first.first! as String;
  }
}
