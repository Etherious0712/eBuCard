// The users table: accounts and how they sign in.

import 'package:postgres/postgres.dart';

/// One account.
class User {
  /// Creates a user from its fields.
  const User({
    required this.id,
    this.email,
    this.emailVerifiedAt,
    this.passwordHash,
    this.appleSub,
    this.googleSub,
    this.deactivatedAt,
    this.deleteAfter,
  });

  /// Reads a `users` row selected with [User.columns].
  factory User.fromRow(Map<String, dynamic> row) => User(
    id: row['id'] as String,
    email: row['email'] as String?,
    emailVerifiedAt: row['email_verified_at'] as DateTime?,
    passwordHash: row['password_hash'] as String?,
    appleSub: row['apple_sub'] as String?,
    googleSub: row['google_sub'] as String?,
    deactivatedAt: row['deactivated_at'] as DateTime?,
    deleteAfter: row['delete_after'] as DateTime?,
  );

  /// Columns to select for [User.fromRow].
  static const columns =
      'id::text AS id, email, email_verified_at, password_hash, apple_sub, '
      'google_sub, deactivated_at, delete_after';

  /// Account id (UUID).
  final String id;

  /// Lower-case email address, if known.
  final String? email;

  /// When the email was confirmed; null if not yet.
  final DateTime? emailVerifiedAt;

  /// Argon2id hash, for accounts with a password.
  final String? passwordHash;

  /// Sign in with Apple user id.
  final String? appleSub;

  /// Google user id.
  final String? googleSub;

  /// When deletion was requested; null for active accounts.
  final DateTime? deactivatedAt;

  /// When the account will be erased (30 days after deletion was asked).
  final DateTime? deleteAfter;

  /// Sync needs a confirmed email, or an Apple/Google account (the provider
  /// has already confirmed who the person is).
  bool get canSync =>
      emailVerifiedAt != null || appleSub != null || googleSub != null;

  /// JSON for `GET /v1/account` and sign-in responses.
  Map<String, Object?> toJson() => {
    'id': id,
    'email': email,
    'emailVerified': emailVerifiedAt != null,
    'canSync': canSync,
    'hasPassword': passwordHash != null,
    'apple': appleSub != null,
    'google': googleSub != null,
  };
}

/// Reads and writes `users`.
class Users {
  /// Creates the store over [_db].
  Users(this._db);

  final Pool<void> _db;

  /// The user with [id], or null.
  Future<User?> byId(String id, {Session? tx}) =>
      _one('id = @v::uuid', id, tx: tx);

  /// The user with [email] (any case), or null.
  Future<User?> byEmail(String email, {Session? tx}) =>
      _one('email = @v', email.trim().toLowerCase(), tx: tx);

  /// The user with Apple id [sub], or null.
  Future<User?> byAppleSub(String sub, {Session? tx}) =>
      _one('apple_sub = @v', sub, tx: tx);

  /// The user with Google id [sub], or null.
  Future<User?> byGoogleSub(String sub, {Session? tx}) =>
      _one('google_sub = @v', sub, tx: tx);

  /// Creates a user; returns it.
  Future<User> create({
    String? email,
    String? passwordHash,
    String? appleSub,
    String? googleSub,
    DateTime? emailVerifiedAt,
    Session? tx,
  }) async {
    final rows = await (tx ?? _db).execute(
      Sql.named(
        'INSERT INTO users (id, email, password_hash, apple_sub, google_sub, '
        'email_verified_at) VALUES (gen_random_uuid(), @email, @hash, '
        '@apple, @google, @verified) RETURNING ${User.columns}',
      ),
      parameters: {
        'email': email?.trim().toLowerCase(),
        'hash': passwordHash,
        'apple': appleSub,
        'google': googleSub,
        'verified': emailVerifiedAt?.toUtc(),
      },
    );
    return User.fromRow(rows.first.toColumnMap());
  }

  /// Updates the given fields of user [id]. Pass [clearPassword] to remove
  /// the password.
  Future<void> update(
    String id, {
    String? passwordHash,
    bool clearPassword = false,
    String? appleSub,
    String? googleSub,
    DateTime? emailVerifiedAt,
    Session? tx,
  }) async {
    final sets = <String>[];
    final params = <String, Object?>{'id': id};
    if (passwordHash != null || clearPassword) {
      sets.add('password_hash = @hash');
      params['hash'] = passwordHash;
    }
    if (appleSub != null) {
      sets.add('apple_sub = @apple');
      params['apple'] = appleSub;
    }
    if (googleSub != null) {
      sets.add('google_sub = @google');
      params['google'] = googleSub;
    }
    if (emailVerifiedAt != null) {
      sets.add('email_verified_at = COALESCE(email_verified_at, @verified)');
      params['verified'] = emailVerifiedAt.toUtc();
    }
    if (sets.isEmpty) return;
    await (tx ?? _db).execute(
      Sql.named('UPDATE users SET ${sets.join(', ')} WHERE id = @id::uuid'),
      parameters: params,
    );
  }

  /// Starts the 30-day deletion grace period for [id].
  Future<void> deactivate(String id, DateTime now, Duration grace) =>
      _db.execute(
        Sql.named(
          'UPDATE users SET deactivated_at = @now, delete_after = @after '
          'WHERE id = @id::uuid',
        ),
        parameters: {
          'id': id,
          'now': now.toUtc(),
          'after': now.add(grace).toUtc(),
        },
      );

  /// Cancels a pending deletion of [id].
  Future<void> reactivate(String id, {Session? tx}) => (tx ?? _db).execute(
    Sql.named(
      'UPDATE users SET deactivated_at = NULL, delete_after = NULL '
      'WHERE id = @id::uuid',
    ),
    parameters: {'id': id},
  );

  /// Erases users whose grace period ended before [now] (cascading to all
  /// their data). Returns the ids of their images, to delete from storage.
  Future<List<String>> purgeExpired(DateTime now) => _db.runTx((tx) async {
    final images = await tx.execute(
      Sql.named(
        'SELECT i.id::text FROM images i JOIN users u ON u.id = i.user_id '
        'WHERE u.delete_after < @now',
      ),
      parameters: {'now': now.toUtc()},
    );
    await tx.execute(
      Sql.named('DELETE FROM users WHERE delete_after < @now'),
      parameters: {'now': now.toUtc()},
    );
    return [for (final row in images) row.first! as String];
  });

  /// Selects one user matching [where] with parameter `@v`.
  Future<User?> _one(String where, Object value, {Session? tx}) async {
    final rows = await (tx ?? _db).execute(
      Sql.named('SELECT ${User.columns} FROM users WHERE $where'),
      parameters: {'v': value},
    );
    return rows.isEmpty ? null : User.fromRow(rows.first.toColumnMap());
  }
}
