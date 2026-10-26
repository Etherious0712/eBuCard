// Reads and writes the Inbox: cards other people gave the user.

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:ebucard_models/ebucard_models.dart';

import 'app_database.dart';

/// Stores received cards on the device.
class ReceivedCardRepository {
  /// Creates a repository backed by [_db].
  ReceivedCardRepository(this._db);

  final AppDatabase _db;

  /// Inbox entries, newest first, updating on every change.
  ///
  /// With a non-empty [query], only entries whose name, company or email
  /// contains it (ignoring case) are returned.
  Stream<List<ReceivedCard>> watchAll({String query = ''}) {
    final q = query.trim().toLowerCase();
    final select = _db.select(_db.receivedCards)
      ..orderBy([(c) => OrderingTerm.desc(c.receivedAt)]);
    if (q.isNotEmpty) {
      select.where((c) => c.searchText.contains(q));
    }
    return select.watch().map((rows) => rows.map(_decode).toList());
  }

  /// The entry with [id], or null if it was deleted.
  Future<ReceivedCard?> find(String id) async {
    final row = await (_db.select(
      _db.receivedCards,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
    return row == null ? null : _decode(row);
  }

  /// An existing entry for the same person as [card] (see `isSamePerson`),
  /// or null. Used to offer "update or keep both" after a scan.
  Future<ReceivedCard?> findSamePerson(BusinessCard card) async {
    final rows = await _db.select(_db.receivedCards).get();
    for (final row in rows) {
      final entry = _decode(row);
      if (isSamePerson(entry.card, card)) return entry;
    }
    return null;
  }

  /// Inserts [entry], or replaces the stored entry with the same id.
  Future<void> save(ReceivedCard entry) => _db
      .into(_db.receivedCards)
      .insertOnConflictUpdate(
        ReceivedCardsCompanion.insert(
          id: entry.id,
          json: jsonEncode(entry.toJson()),
          searchText: _searchText(entry.card),
          receivedAt: entry.receivedAt,
          updatedAt: entry.updatedAt,
        ),
      );

  /// Deletes the entry with [id].
  Future<void> delete(String id) =>
      (_db.delete(_db.receivedCards)..where((c) => c.id.equals(id))).go();

  /// What Inbox search matches against.
  static String _searchText(BusinessCard card) => [
    card.fullName,
    card.company,
    for (final e in card.emails) e.value,
  ].join('\n').toLowerCase();

  /// Turns a database row back into a [ReceivedCard].
  static ReceivedCard _decode(ReceivedCardRow row) =>
      ReceivedCard.fromJson(jsonDecode(row.json) as Map<String, Object?>);
}
