// Shared helpers for app tests: an in-memory database, fakes for everything
// that needs real hardware or other apps (camera, NFC, image picker,
// Contacts, phone/email/browser), and pumpApp() which starts the full app
// with them.

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:ebucard/src/account/account_providers.dart';
import 'package:ebucard/src/account/identity_sign_in.dart';
import 'package:ebucard/src/account/session_store.dart';
import 'package:ebucard/src/app.dart';
import 'package:ebucard/src/data/app_database.dart';
import 'package:ebucard/src/data/card_image_service.dart';
import 'package:ebucard/src/data/contacts_service.dart';
import 'package:ebucard/src/data/link_launcher.dart';
import 'package:ebucard/src/data/nfc_service.dart';
import 'package:ebucard/src/data/providers.dart';
import 'package:ebucard/src/features/exchange/scan_screen.dart';
import 'package:ebucard_models/ebucard_models.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndef_record/ndef_record.dart';

import 'fake_server.dart';

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

  /// Bytes returned by [readLocal], by URI.
  final files = <String, Uint8List>{};

  /// Whether [deleteAll] was called.
  bool deletedAll = false;

  @override
  Future<Uint8List?> readLocal(String uri) async => files[uri];

  @override
  Future<void> deleteAll() async {
    deletedAll = true;
    files.clear();
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

/// Stands in for NFC: set [current] for the status, inspect what is being
/// shared, and call [deliver] to "hold a phone" against this one.
class FakeNfcService implements NfcService {
  /// What [status] reports. Defaults to NFC on, able to share.
  NfcStatus current = const NfcStatus(state: NfcState.on, canShare: true);

  /// The NDEF bytes being shared, or null when not sharing.
  Uint8List? sharing;

  /// How many times the NFC settings were opened.
  int settingsOpened = 0;

  /// Whether a reading session is running.
  bool reading = false;

  void Function(NdefMessage?)? _onMessage;
  VoidCallback? _onCancelledIos;

  @override
  Future<NfcStatus> status() async => current;

  @override
  Future<void> startSharing(Uint8List ndefMessage) async =>
      sharing = ndefMessage;

  @override
  Future<void> stopSharing() async => sharing = null;

  @override
  Future<void> openSettings() async => settingsOpened++;

  @override
  Future<void> startReading({
    required void Function(NdefMessage? message) onMessage,
    required String iosAlertMessage,
    VoidCallback? onCancelledIos,
  }) async {
    reading = true;
    _onMessage = onMessage;
    _onCancelledIos = onCancelledIos;
  }

  @override
  Future<void> stopReading({
    String? iosSuccessMessage,
    String? iosErrorMessage,
  }) async => reading = false;

  /// Simulates reading [message] from another phone.
  void deliver(NdefMessage? message) => _onMessage!(message);

  /// Simulates the user closing the iPhone scan sheet.
  void cancelIos() {
    reading = false;
    _onCancelledIos?.call();
  }
}

/// Apple/Google sign-in that returns [token] (null = cancelled) for
/// whichever providers are in [available].
class FakeIdentitySignIn implements IdentitySignIn {
  @override
  Set<IdentityProviderKind> available = {};

  /// The identity token to "receive" from the provider.
  String? token = 'fake-identity-token';

  @override
  Future<String?> identityToken(IdentityProviderKind provider) async => token;
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
  FakeNfcService? nfc,
  FakeServer? server,
  SessionStore? sessions,
  IdentitySignIn? identity,
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
        nfcServiceProvider.overrideWithValue(nfc ?? FakeNfcService()),
        httpClientProvider.overrideWithValue((server ?? FakeServer()).client),
        sessionStoreProvider.overrideWithValue(
          sessions ?? MemorySessionStore(),
        ),
        identitySignInProvider.overrideWithValue(
          identity ?? FakeIdentitySignIn(),
        ),
        scannerBuilderProvider.overrideWithValue(
          (scanner ?? FakeScanner()).build,
        ),
      ],
      child: const EBuCardApp(),
    ),
  );
  await tester.pumpAndSettle();
}
