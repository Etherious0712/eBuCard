// Local SQLite database (drift). Generated code is in app_database.g.dart.

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:ebucard_models/ebucard_models.dart'
    show BusinessCard, ReceivedCard;

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

/// Cards other people gave the user (the Inbox).
@DataClassName('ReceivedCardRow')
class ReceivedCards extends Table {
  /// The Inbox entry's UUID ([ReceivedCard.id]).
  TextColumn get id => text()();

  /// The whole entry as `ReceivedCard.toJson()` text.
  TextColumn get json => text()();

  /// Lower-case name, company and emails, for Inbox search.
  TextColumn get searchText => text()();

  /// Copy of [ReceivedCard.receivedAt]; the Inbox is sorted newest first.
  DateTimeColumn get receivedAt => dateTime()();

  /// Copy of [ReceivedCard.updatedAt], for future sync queries.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Small key/value app preferences, e.g. which own card is the default.
@DataClassName('SettingRow')
class Settings extends Table {
  /// Setting name; see the constants in `settings_repository.dart`.
  TextColumn get key => text()();

  /// Setting value as text.
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// The app's SQLite database, file `ebucard` in the app's data folder.
///
/// After changing a table, run `dart run build_runner build` to regenerate
/// `app_database.g.dart`, bump [schemaVersion] and add a migration.
@DriftDatabase(tables: [OwnCards, ReceivedCards, Settings])
class AppDatabase extends _$AppDatabase {
  /// Opens the on-device database, or uses [executor] if given (tests pass
  /// an in-memory database).
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'ebucard'));

  /// Version 1: `own_cards`.
  /// Version 2: adds `received_cards` (Inbox) and `settings`.
  @override
  int get schemaVersion => 2;

  /// Creates all tables on first launch, and adds new tables when an older
  /// database is opened by a newer app.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(receivedCards);
        await m.createTable(settings);
      }
    },
  );
}
