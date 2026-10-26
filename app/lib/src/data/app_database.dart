// Local SQLite database (drift). Generated code is in app_database.g.dart.

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:ebucard_models/ebucard_models.dart' show BusinessCard;

part 'app_database.g.dart';

/// The user's own cards. The full card is kept as JSON (the same format the
/// server uses, see `ebucard_models`); the other columns support ordering.
class OwnCards extends Table {
  /// The card's UUID ([BusinessCard.id]).
  TextColumn get id => text()();

  /// The whole card as `BusinessCard.toJson()` text.
  TextColumn get json => text()();

  /// Position in the My Cards list; new cards go last.
  IntColumn get sortOrder => integer()();

  /// Copy of [BusinessCard.updatedAt], for future sync queries.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The app's SQLite database, file `ebucard` in the app's data folder.
///
/// After changing a table, run `dart run build_runner build` to regenerate
/// `app_database.g.dart`, bump [schemaVersion] and add a migration.
@DriftDatabase(tables: [OwnCards])
class AppDatabase extends _$AppDatabase {
  /// Opens the on-device database, or uses [executor] if given (tests pass
  /// an in-memory database).
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'ebucard'));

  /// Version 1: `own_cards` table.
  @override
  int get schemaVersion => 1;
}
