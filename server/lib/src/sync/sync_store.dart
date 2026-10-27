// Server side of sync for the user's own cards and their Inbox.
//
// Every write gets the next number from one sequence (`seq`). A phone asks
// "what changed after seq N?" and gets each changed record (or a tombstone
// for a deleted one) plus the new N to ask from next time.
//
// Conflicts are settled per record by `updatedAt`: a write only replaces
// the stored record if it is newer (last writer wins, DESIGN.md §6).

import 'dart:convert';

import 'package:ebucard_server/src/http/api_error.dart';
import 'package:postgres/postgres.dart';

/// Which kind of record is synced.
enum SyncKind {
  /// The user's own cards (`BusinessCard` JSON).
  cards('cards'),

  /// Cards the user received (`ReceivedCard` JSON).
  received('received_cards');

  const SyncKind(this.table);

  /// Database table.
  final String table;
}

/// One record as stored on the server.
class SyncRecord {
  /// Creates a record.
  const SyncRecord({
    required this.id,
    required this.data,
    required this.updatedAt,
    required this.deleted,
    required this.seq,
  });

  /// Reads a row selected with [columns].
  factory SyncRecord.fromRow(Map<String, dynamic> row) => SyncRecord(
    id: row['id'] as String,
    data: row['data'] == null
        ? null
        : Map<String, Object?>.from(row['data'] as Map),
    updatedAt: row['updated_at'] as DateTime,
    deleted: row['deleted'] as bool,
    seq: row['seq'] as int,
  );

  /// Columns to select for [SyncRecord.fromRow] from [kind]'s table. Own
  /// cards get the server-owned `shareSlug` merged into their JSON.
  static String columns(SyncKind kind) => switch (kind) {
    SyncKind.cards =>
      'id::text AS id, '
          "data || jsonb_build_object('shareSlug', share_slug) AS data, "
          'updated_at, deleted, seq',
    SyncKind.received => 'id::text AS id, data, updated_at, deleted, seq',
  };

  /// Record id (the card's / entry's UUID).
  final String id;

  /// The JSON, or null for a deleted record.
  final Map<String, Object?>? data;

  /// When the record last changed on a phone (UTC).
  final DateTime updatedAt;

  /// Whether it was deleted (a tombstone).
  final bool deleted;

  /// Position in the change sequence.
  final int seq;

  /// JSON sent to the app.
  Map<String, Object?> toJson() => {
    'id': id,
    'deleted': deleted,
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    if (!deleted) 'data': data,
  };
}

/// Changes since a cursor, as returned by [SyncStore.changesSince].
class SyncPage {
  /// Creates a page.
  const SyncPage(this.records, this.cursor, {required this.hasMore});

  /// Changed records, oldest change first.
  final List<SyncRecord> records;

  /// Cursor for the next request.
  final int cursor;

  /// More changes are waiting; ask again with [cursor].
  final bool hasMore;

  /// JSON response body.
  Map<String, Object?> toJson() => {
    'changes': [for (final r in records) r.toJson()],
    'cursor': cursor,
    'hasMore': hasMore,
  };
}

/// Reads and writes synced records.
class SyncStore {
  /// Creates the store over [_db].
  SyncStore(this._db);

  final Pool<void> _db;

  /// Records of [userId] changed after [since], at most [limit] at a time.
  Future<SyncPage> changesSince(
    String userId,
    SyncKind kind,
    int since, {
    int limit = 200,
  }) async {
    final rows = await _db.execute(
      Sql.named(
        'SELECT ${SyncRecord.columns(kind)} FROM ${kind.table} '
        'WHERE user_id = @user::uuid AND seq > @since '
        'ORDER BY seq LIMIT @limit',
      ),
      parameters: {'user': userId, 'since': since, 'limit': limit + 1},
    );
    final records = [
      for (final row in rows.take(limit)) SyncRecord.fromRow(row.toColumnMap()),
    ];
    return SyncPage(
      records,
      records.isEmpty ? since : records.last.seq,
      hasMore: rows.length > limit,
    );
  }

  /// Stores [data] for record [id] if it is newer than what is stored.
  /// Returns the record now stored (the winner). A [data] of null deletes.
  ///
  /// For own cards, [newSlug] becomes the card's link if it has none yet
  /// and the owner hasn't revoked it; deleting a card ends its link.
  ///
  /// Throws a 404 if [id] belongs to another user.
  Future<SyncRecord> write(
    String userId,
    SyncKind kind,
    String id,
    Map<String, Object?>? data,
    DateTime updatedAt, {
    String? newSlug,
  }) async {
    final table = kind.table;
    final cards = kind == SyncKind.cards;
    final rows = await _db.execute(
      Sql.named(
        'INSERT INTO $table (id, user_id, data, updated_at, deleted, seq'
        '${cards ? ', share_slug' : ''}) '
        'VALUES (@id::uuid, @user::uuid, @data::jsonb, @ts, @deleted, '
        "nextval('sync_seq')"
        '${cards ? _newSlug : ''}) '
        'ON CONFLICT (id) DO UPDATE SET data = EXCLUDED.data, '
        'updated_at = EXCLUDED.updated_at, deleted = EXCLUDED.deleted, '
        'seq = EXCLUDED.seq '
        '${cards ? _keepSlug : ''}'
        'WHERE $table.user_id = EXCLUDED.user_id '
        'AND EXCLUDED.updated_at > $table.updated_at '
        'RETURNING ${SyncRecord.columns(kind)}',
      ),
      parameters: {
        'id': id,
        'user': userId,
        'data': data == null ? null : jsonEncode(data),
        'ts': updatedAt.toUtc(),
        'deleted': data == null,
        if (cards) 'slug': newSlug,
      },
    );
    if (rows.isNotEmpty) return SyncRecord.fromRow(rows.first.toColumnMap());

    // Not written: either an older version, or someone else's id.
    final current = await find(userId, kind, id);
    if (current == null) throw const ApiException.notFound();
    return current;
  }

  /// The share slug of a newly stored card (none for a tombstone).
  static const _newSlug = ', CASE WHEN @deleted THEN NULL ELSE @slug::text END';

  /// Keeps an existing link, gives a linkless card the new slug unless the
  /// owner revoked its link, and ends the link of a deleted card.
  static const _keepSlug =
      ', share_slug = CASE WHEN EXCLUDED.deleted THEN NULL '
      'ELSE COALESCE(cards.share_slug, CASE WHEN cards.link_revoked '
      'THEN NULL ELSE EXCLUDED.share_slug END) END ';

  /// The stored record [id] of [userId], or null.
  Future<SyncRecord?> find(String userId, SyncKind kind, String id) async {
    final rows = await _db.execute(
      Sql.named(
        'SELECT ${SyncRecord.columns(kind)} FROM ${kind.table} '
        'WHERE id = @id::uuid AND user_id = @user::uuid',
      ),
      parameters: {'id': id, 'user': userId},
    );
    return rows.isEmpty ? null : SyncRecord.fromRow(rows.first.toColumnMap());
  }
}
