// What the phone remembers about syncing: how far it has read each change
// list (cursors), deletions still to send, and which account the local data
// belongs to.

import 'package:drift/drift.dart';

import '../data/app_database.dart';

/// The two kinds of synced records, named as in the API paths.
enum SyncKind {
  /// The user's own cards: `/v1/cards`.
  cards('cards'),

  /// The Inbox: `/v1/received`.
  received('received');

  const SyncKind(this.path);

  /// API path segment, also used as the `kind` in pending deletions.
  final String path;
}

/// A deletion waiting to be sent.
class PendingDeletion {
  /// Creates one.
  const PendingDeletion(this.id, this.deletedAt);

  /// The deleted record's id.
  final String id;

  /// When it was deleted.
  final DateTime deletedAt;
}

/// Reads and writes sync bookkeeping in the local database.
class LocalSyncState {
  /// Creates the store over [_db].
  LocalSyncState(this._db);

  final AppDatabase _db;

  /// Settings key holding the account id the local data belongs to.
  static const accountKey = 'sync_account_id';

  /// The change-list cursor for [kind]; 0 before the first sync.
  Future<int> cursor(SyncKind kind) async =>
      int.tryParse(await _get('sync_cursor_${kind.path}') ?? '') ?? 0;

  /// Saves the cursor for [kind].
  Future<void> setCursor(SyncKind kind, int cursor) =>
      _set('sync_cursor_${kind.path}', '$cursor');

  /// Deletions of [kind] not yet sent.
  Future<List<PendingDeletion>> pendingDeletions(SyncKind kind) async {
    final rows = await (_db.select(
      _db.pendingDeletions,
    )..where((d) => d.kind.equals(kind.path))).get();
    return [for (final r in rows) PendingDeletion(r.id, r.deletedAt)];
  }

  /// Forgets a deletion once the account has it.
  Future<void> forgetDeletion(SyncKind kind, String id) => (_db.delete(
    _db.pendingDeletions,
  )..where((d) => d.kind.equals(kind.path) & d.id.equals(id))).go();

  /// Whether [kind] record [id] was deleted here and not yet sent.
  Future<bool> isPendingDeletion(SyncKind kind, String id) async =>
      (await (_db.select(_db.pendingDeletions)
            ..where((d) => d.kind.equals(kind.path) & d.id.equals(id)))
          .getSingleOrNull()) !=
      null;

  /// How many local changes (edited records and deletions) are waiting to
  /// be sent; updates live, so sync can start soon after each change.
  Stream<int> watchPendingChanges() => _db
      .customSelect(
        'SELECT (SELECT COUNT(*) FROM own_cards WHERE dirty) '
        '+ (SELECT COUNT(*) FROM received_cards WHERE dirty) '
        '+ (SELECT COUNT(*) FROM pending_deletions) AS n',
        readsFrom: {_db.ownCards, _db.receivedCards, _db.pendingDeletions},
      )
      .watchSingle()
      .map((row) => row.read<int>('n'));

  /// The account the local data was last synced with; null if the phone
  /// has never been signed in (its data is then merged on first sign-in).
  Future<String?> accountId() => _get(accountKey);

  /// Records that the local data now belongs to [accountId].
  Future<void> setAccountId(String accountId) => _set(accountKey, accountId);

  /// Reads a settings value.
  Future<String?> _get(String key) async => (await (_db.select(
    _db.settings,
  )..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  /// Writes a settings value.
  Future<void> _set(String key, String value) => _db
      .into(_db.settings)
      .insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));
}
