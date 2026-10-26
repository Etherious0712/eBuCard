import 'package:ebucard_models/ebucard_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'card_image_service.dart';
import 'card_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final cardRepositoryProvider = Provider<CardRepository>(
  (ref) => CardRepository(ref.watch(appDatabaseProvider)),
);

final ownCardsProvider = StreamProvider<List<BusinessCard>>(
  (ref) => ref.watch(cardRepositoryProvider).watchAll(),
);

final cardImageServiceProvider = Provider<CardImageService>(
  (ref) => DeviceCardImageService(),
);
