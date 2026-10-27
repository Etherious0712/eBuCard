// Reads and writes the user's own cards in the local database. Screens go
// through this class (via cardRepositoryProvider), never the database.

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:ebucard_models/ebucard_models.dart';

import 'app_database.dart';

/// Stores the user's own cards on the device.
class CardRepository {
  /// Creates a repository backed by [_db].
  CardRepository(this._db);

  final AppDatabase _db;

  /// All cards, oldest first, updating whenever a card changes.
  Stream<List<BusinessCard>> watchAll() {
    final query = _db.select(_db.ownCards)
      ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]);
    return query.watch().map((rows) => rows.map(_decode).toList());
  }

  /// The card with [id], or null if it doesn't exist (e.g. was deleted).
  Future<BusinessCard?> find(String id) async {
    final row = await (_db.select(
      _db.ownCards,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
    return row == null ? null : _decode(row);
  }

  /// Inserts a new card at the end of the list, or updates an existing one in
  /// place. Edits made on this phone are marked for sync; [fromSync] marks
  /// a card that just came from (or was accepted by) the account.
  Future<void> save(BusinessCard card, {bool fromSync = false}) {
    return _db.transaction(() async {
      final existing = await (_db.select(
        _db.ownCards,
      )..where((c) => c.id.equals(card.id))).getSingleOrNull();
      final sortOrder = existing?.sortOrder ?? await _nextSortOrder();
      await _db
          .into(_db.ownCards)
          .insertOnConflictUpdate(
            OwnCardsCompanion.insert(
              id: card.id,
              json: jsonEncode(card.toJson()),
              sortOrder: sortOrder,
              updatedAt: card.updatedAt,
              dirty: Value(!fromSync),
            ),
          );
    });
  }

  /// Deletes the card with [id] and remembers the deletion for sync (unless
  /// it came [fromSync]). Its image files are not touched; callers delete
  /// them with `CardImageService.delete`.
  Future<void> delete(String id, {bool fromSync = false}) =>
      _db.transaction(() async {
        await (_db.delete(_db.ownCards)..where((c) => c.id.equals(id))).go();
        if (!fromSync) await _db.rememberDeletion('cards', id);
      });

  /// Cards changed on this phone that the account doesn't have yet.
  Future<List<BusinessCard>> dirty() async {
    final rows = await (_db.select(
      _db.ownCards,
    )..where((c) => c.dirty.equals(true))).get();
    return rows.map(_decode).toList();
  }

  /// One more than the largest sort order in use, or 0 for the first card.
  Future<int> _nextSortOrder() async {
    final max = _db.ownCards.sortOrder.max();
    final row = await (_db.selectOnly(
      _db.ownCards,
    )..addColumns([max])).getSingle();
    return (row.read(max) ?? -1) + 1;
  }

  /// Turns a database row back into a [BusinessCard].
  static BusinessCard _decode(OwnCard row) =>
      BusinessCard.fromJson(jsonDecode(row.json) as Map<String, Object?>);
}
