// Riverpod providers: how screens get the database, repository and services.
// Tests replace these with `overrideWithValue` (see test/support/).

import 'package:ebucard_models/ebucard_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'card_image_service.dart';
import 'card_repository.dart';

/// The single app database, closed when the provider scope is disposed.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Access to the user's own cards.
final cardRepositoryProvider = Provider<CardRepository>(
  (ref) => CardRepository(ref.watch(appDatabaseProvider)),
);

/// Live list of the user's own cards; rebuilds watchers on every change.
final ownCardsProvider = StreamProvider<List<BusinessCard>>(
  (ref) => ref.watch(cardRepositoryProvider).watchAll(),
);

/// Picks, crops and stores card images using the phone's camera/library.
final cardImageServiceProvider = Provider<CardImageService>(
  (ref) => DeviceCardImageService(),
);
