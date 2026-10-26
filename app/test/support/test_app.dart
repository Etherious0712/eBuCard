// Shared helpers for app tests: an in-memory database, fakes for everything
// that needs real hardware or other apps (camera, image picker, Contacts,
// phone/email/browser), and pumpApp() which starts the full app with them.

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:ebucard/src/app.dart';
import 'package:ebucard/src/data/app_database.dart';
import 'package:ebucard/src/data/card_image_service.dart';
import 'package:ebucard/src/data/contacts_service.dart';
import 'package:ebucard/src/data/link_launcher.dart';
import 'package:ebucard/src/data/providers.dart';
import 'package:ebucard/src/features/exchange/scan_screen.dart';
import 'package:ebucard_models/ebucard_models.dart';
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

/// Records cards sent to "Save to Contacts" instead of opening Contacts.
class FakeContactsService implements ContactsService {
  /// Cards passed to [addToContacts], in order.
  final added = <BusinessCard>[];

  @override
  Future<void> addToContacts(BusinessCard card) async => added.add(card);
}

/// Records opened links instead of launching other apps.
class FakeLinkLauncher implements LinkLauncher {
  /// URIs passed to [open], in order.
  final opened = <Uri>[];

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return true;
  }
}

/// Stands in for the camera: call [scan] to "read" a QR code.
class FakeScanner {
  ValueChanged<String>? _onScanned;

  /// Builder for `scannerBuilderProvider`; shows an empty box.
  Widget build(BuildContext context, ValueChanged<String> onScanned) {
    _onScanned = onScanned;
    return const SizedBox.expand();
  }

  /// Reports [text] as a scanned QR code. The scan screen must be open.
  void scan(String text) => _onScanned!(text);
}

/// Runs real database work outside the widget test's fake-async zone, where
/// it would otherwise never complete.
Future<T> dbCall<T>(WidgetTester tester, Future<T> Function() body) async =>
    (await tester.runAsync(body)) as T;

/// Pumps the whole app on a tall screen so long forms are fully built.
Future<void> pumpApp(
  WidgetTester tester, {
  required AppDatabase db,
  CardImageService? images,
  ContactsService? contacts,
  LinkLauncher? links,
  FakeScanner? scanner,
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
        contactsServiceProvider.overrideWithValue(
          contacts ?? FakeContactsService(),
        ),
        linkLauncherProvider.overrideWithValue(links ?? FakeLinkLauncher()),
        scannerBuilderProvider.overrideWithValue(
          (scanner ?? FakeScanner()).build,
        ),
      ],
      child: const EBuCardApp(),
    ),
  );
  await tester.pumpAndSettle();
}
