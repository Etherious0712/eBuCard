import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:ebucard_models/ebucard_models.dart';

import 'app_database.dart';

/// Stores the user's own cards on the device.
class CardRepository {
  CardRepository(this._db);

  final AppDatabase _db;

  /// All cards, oldest first, updating whenever a card changes.
  Stream<List<BusinessCard>> watchAll() {
    final query = _db.select(_db.ownCards)
      ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]);
    return query.watch().map((rows) => rows.map(_decode).toList());
  }

  Future<BusinessCard?> find(String id) async {
    final row = await (_db.select(
      _db.ownCards,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
    return row == null ? null : _decode(row);
  }

  /// Inserts a new card at the end of the list, or updates an existing one in
  /// place.
  Future<void> save(BusinessCard card) {
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
            ),
          );
    });
  }

  Future<void> delete(String id) =>
      (_db.delete(_db.ownCards)..where((c) => c.id.equals(id))).go();

  Future<int> _nextSortOrder() async {
    final max = _db.ownCards.sortOrder.max();
    final row = await (_db.selectOnly(
      _db.ownCards,
    )..addColumns([max])).getSingle();
    return (row.read(max) ?? -1) + 1;
  }

  static BusinessCard _decode(OwnCard row) =>
      BusinessCard.fromJson(jsonDecode(row.json) as Map<String, Object?>);
}
