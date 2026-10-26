import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:ebucard/src/app.dart';
import 'package:ebucard/src/data/app_database.dart';
import 'package:ebucard/src/data/card_image_service.dart';
import 'package:ebucard/src/data/providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase memoryDatabase() => AppDatabase(
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
);

class FakeCardImageService implements CardImageService {
  String? nextImage;
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
