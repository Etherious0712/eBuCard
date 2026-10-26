// Small app preferences kept in the `settings` table.

import 'app_database.dart';

/// Reads and writes app preferences.
class SettingsRepository {
  /// Creates a repository backed by [_db].
  SettingsRepository(this._db);

  final AppDatabase _db;

  /// Key of the own card shown first on the Show QR screen.
  static const defaultCardIdKey = 'default_card_id';

  /// The default card's id as chosen by the user, or null if never set.
  /// The card may since have been deleted; callers fall back to the first
  /// card (see `defaultCardProvider`).
  Stream<String?> watchDefaultCardId() =>
      (_db.select(_db.settings)..where((s) => s.key.equals(defaultCardIdKey)))
          .watchSingleOrNull()
          .map((row) => row?.value);

  /// Makes the card with [cardId] the default.
  Future<void> setDefaultCardId(String cardId) => _db
      .into(_db.settings)
      .insertOnConflictUpdate(
        SettingsCompanion.insert(key: defaultCardIdKey, value: cardId),
      );
}
