// Riverpod providers: how screens get the database, repositories and
// services. Tests replace these with `overrideWithValue` (see test/support/).

import 'package:ebucard_models/ebucard_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';
import 'card_image_service.dart';
import 'card_repository.dart';
import 'contacts_service.dart';
import 'link_launcher.dart';
import 'received_card_repository.dart';
import 'settings_repository.dart';

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

/// Access to app preferences.
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(appDatabaseProvider)),
);

/// The id of the card the user marked as default, if any.
final defaultCardIdProvider = StreamProvider<String?>(
  (ref) => ref.watch(settingsRepositoryProvider).watchDefaultCardId(),
);

/// The card the Show QR screen opens on: the user's chosen default if it
/// still exists, otherwise their first card; null when they have no cards.
final defaultCardProvider = Provider<AsyncValue<BusinessCard?>>((ref) {
  final cards = ref.watch(ownCardsProvider);
  final defaultId = ref.watch(defaultCardIdProvider);
  if (defaultId.isLoading) return const AsyncLoading();
  return cards.whenData((list) => resolveDefaultCard(list, defaultId.value));
});

/// Picks the default card from [cards]; see [defaultCardProvider].
BusinessCard? resolveDefaultCard(List<BusinessCard> cards, String? defaultId) {
  if (cards.isEmpty) return null;
  return cards.firstWhere((c) => c.id == defaultId, orElse: () => cards.first);
}

/// Access to the Inbox.
final receivedCardRepositoryProvider = Provider<ReceivedCardRepository>(
  (ref) => ReceivedCardRepository(ref.watch(appDatabaseProvider)),
);

/// Inbox entries matching a search query ('' for all), newest first.
final receivedCardsProvider = StreamProvider.family<List<ReceivedCard>, String>(
  (ref, query) =>
      ref.watch(receivedCardRepositoryProvider).watchAll(query: query),
);

/// Picks, crops and stores card images using the phone's camera/library.
final cardImageServiceProvider = Provider<CardImageService>(
  (ref) => DeviceCardImageService(),
);

/// Opens the phone's "new contact" screen for a card.
final contactsServiceProvider = Provider<ContactsService>(
  (ref) => DeviceContactsService(),
);

/// Opens phone numbers, emails and websites in other apps.
final linkLauncherProvider = Provider<LinkLauncher>(
  (ref) => DeviceLinkLauncher(),
);
