// Shared helpers for app tests: an in-memory database, a fake image service,
// and pumpApp() which starts the full app with those swapped in.

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:ebucard/src/app.dart';
import 'package:ebucard/src/data/app_database.dart';
import 'package:ebucard/src/data/card_image_service.dart';
import 'package:ebucard/src/data/providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fresh, empty database in memory. Close it in `tearDown`.
AppDatabase memoryDatabase() => AppDatabase(
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
);

/// Image service that returns [nextImage] instead of opening the camera or
/// library, and records deletions in [deleted].
class FakeCardImageService implements CardImageService {
  /// What the next pick returns; null simulates the user cancelling.
  String? nextImage;

  /// URIs passed to [delete], in order.
  final deleted = <String>[];

  @override
  Future<String?> pickSquareImage(
    CardImageSource source, {
    required String cropTitle,
  }) async => nextImage;

  @override
  Future<void> delete(String? uri) async {
    if (uri != null) deleted.add(uri);
  }
}

/// Pumps the whole app on a tall screen so long forms are fully built.
Future<void> pumpApp(
  WidgetTester tester, {
  required AppDatabase db,
  CardImageService? images,
}) async {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        cardImageServiceProvider.overrideWithValue(
          images ?? FakeCardImageService(),
        ),
      ],
      child: const EBuCardApp(),
    ),
  );
  await tester.pumpAndSettle();
}
