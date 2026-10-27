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

  /// Copy of [BusinessCard.updatedAt], for sync.
  DateTimeColumn get updatedAt => dateTime()();

  /// Changed on this phone and not yet sent to the account (see sync).
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

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

  /// Copy of [ReceivedCard.updatedAt], for sync.
  DateTimeColumn get updatedAt => dateTime()();

  /// Changed on this phone and not yet sent to the account (see sync).
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Deletions made on this phone that the account hasn't heard about yet.
/// Sync sends them, then removes them from here.
@DataClassName('PendingDeletionRow')
class PendingDeletions extends Table {
  /// Which kind of record: `cards` or `received`.
  TextColumn get kind => text()();

  /// The deleted record's id.
  TextColumn get id => text()();

  /// When it was deleted, so a newer edit elsewhere can win.
  DateTimeColumn get deletedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {kind, id};
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
@DriftDatabase(tables: [OwnCards, ReceivedCards, Settings, PendingDeletions])
class AppDatabase extends _$AppDatabase {
  /// Opens the on-device database, or uses [executor] if given (tests pass
  /// an in-memory database).
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'ebucard'));

  /// Version 1: `own_cards`.
  /// Version 2: adds `received_cards` (Inbox) and `settings`.
  /// Version 3: sync tracking: `dirty` flags and `pending_deletions`.
  @override
  int get schemaVersion => 3;

  /// Remembers that record [id] of [kind] was deleted on this phone, so the
  /// next sync tells the account.
  Future<void> rememberDeletion(String kind, String id) =>
      into(pendingDeletions).insertOnConflictUpdate(
        PendingDeletionsCompanion.insert(
          kind: kind,
          id: id,
          deletedAt: DateTime.now().toUtc(),
        ),
      );

  /// Erases everything stored for an account: cards, Inbox, pending
  /// deletions and settings (sign-out, account deletion).
  Future<void> clearAccountData() => transaction(() async {
    await delete(ownCards).go();
    await delete(receivedCards).go();
    await delete(pendingDeletions).go();
    await delete(settings).go();
  });

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
      if (from < 3) {
        // Tables created just above already have the column.
        if (from >= 2) await m.addColumn(receivedCards, receivedCards.dirty);
        await m.addColumn(ownCards, ownCards.dirty);
        await m.createTable(pendingDeletions);
      }
    },
  );
}
