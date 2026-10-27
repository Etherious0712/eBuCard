// Keeps the refresh token (and the last known account) between app starts,
// in the phone's secure storage: the Keychain on iPhone, encrypted
// preferences on Android.

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'account.dart';

/// What is remembered about the signed-in session.
class StoredSession {
  /// Creates a stored session.
  const StoredSession(this.refreshToken, this.account);

  /// Long-lived token for getting access tokens.
  final String refreshToken;

  /// The account as last seen.
  final Account account;
}

/// Saves and loads the session.
abstract class SessionStore {
  /// The saved session, or null when signed out.
  Future<StoredSession?> load();

  /// Saves [session].
  Future<void> save(StoredSession session);

  /// Forgets the session.
  Future<void> clear();
}

/// [SessionStore] in the phone's secure storage.
class SecureSessionStore implements SessionStore {
  /// Creates the store.
  SecureSessionStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _key = 'ebucard_session';

  @override
  Future<StoredSession?> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, Object?>;
      return StoredSession(
        json['refreshToken']! as String,
        Account.fromJson(json['account']! as Map<String, Object?>),
      );
    } on Object {
      return null; // Unreadable: treat as signed out.
    }
  }

  @override
  Future<void> save(StoredSession session) => _storage.write(
    key: _key,
    value: jsonEncode({
      'refreshToken': session.refreshToken,
      'account': session.account.toJson(),
    }),
  );

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

/// [SessionStore] in memory, for tests.
class MemorySessionStore implements SessionStore {
  /// The saved session.
  StoredSession? session;

  @override
  Future<StoredSession?> load() async => session;

  @override
  Future<void> save(StoredSession value) async => session = value;

  @override
  Future<void> clear() async => session = null;
}
