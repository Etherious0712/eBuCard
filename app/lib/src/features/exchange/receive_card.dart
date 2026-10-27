// What happens after a card arrives (QR code, NFC tag or card link): get
// the card, ask about duplicates, and store it in the Inbox.
//
// A card link of this app's server is opened online and saved as a
// snapshot that remembers the link, so "Check for updates" works later
// (DESIGN.md §4.1). Without internet, an NFC tag's vCard is used instead.

import 'package:ebucard_models/ebucard_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../account/api_client.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../sync/card_links.dart';

/// The user's answer when a scanned person is already in the Inbox.
enum DuplicateChoice {
  /// Replace the saved card's details; keep its note and received date.
  update,

  /// Add the scan as a separate Inbox entry.
  keepBoth,
}

/// Stores what a QR code held: a card link of this server is opened
/// online; anything else is read as contact text. See [receiveCard].
Future<String?> receiveScanned(
  BuildContext context,
  WidgetRef ref,
  String text,
) {
  final isLink = ref.read(cardLinksProvider).slugIn(text) != null;
  return receiveCard(
    context,
    ref,
    link: isLink ? text : null,
    contactText: isLink ? null : text,
    via: ReceivedVia.qr,
  );
}

/// Stores a received card in the Inbox and returns the entry's id.
///
/// [link] is a card link (from a QR code, NFC tag or opened URL); if it
/// belongs to this server, the card is downloaded. [contactText] is a
/// vCard or MECARD, used when there is no link or the download fails
/// (an NFC tag carries both).
///
/// Returns null, after telling the user why, if nothing usable arrived.
/// If the same person is already in the Inbox (see `isSamePerson`), asks
/// whether to update that entry or keep both; returns null if the user
/// cancels.
Future<String?> receiveCard(
  BuildContext context,
  WidgetRef ref, {
  String? link,
  String? contactText,
  required ReceivedVia via,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final links = ref.read(cardLinksProvider);
  final now = DateTime.now().toUtc();

  final slug = link == null ? null : links.slugIn(link);
  if (slug != null) {
    try {
      final card = await links.fetch(slug);
      if (!context.mounted) return null;
      return await _store(
        context,
        ref,
        inboxSnapshot(card),
        via,
        now,
        sourceSlug: slug,
      );
    } on ApiError catch (e) {
      if (contactText == null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              e.code == 'not_found' ? l10n.linkInactive : l10n.linkOffline,
            ),
          ),
        );
        return null;
      }
      // Fall back to the vCard that came with it.
    }
    if (!context.mounted) return null;
  }

  final card = const ContactDecoder().decode(
    contactText ?? '',
    id: const Uuid().v4(),
    now: now,
  );
  if (card == null) {
    final message = via == ReceivedVia.nfc ? l10n.nfcNotACard : l10n.notACard;
    messenger.showSnackBar(SnackBar(content: Text(message)));
    return null;
  }
  return _store(context, ref, card, via, now);
}

/// Saves [card], asking first if the same person is already in the Inbox.
Future<String?> _store(
  BuildContext context,
  WidgetRef ref,
  BusinessCard card,
  ReceivedVia via,
  DateTime now, {
  String? sourceSlug,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final repo = ref.read(receivedCardRepositoryProvider);

  final existing = await repo.findSamePerson(card);
  if (existing != null) {
    if (!context.mounted) return null;
    final choice = await _askAboutDuplicate(context, existing.card.fullName);
    if (choice == null) return null;
    if (choice == DuplicateChoice.update) {
      await repo.save(
        existing.copyWith(
          card: card,
          receivedVia: via,
          updatedAt: now,
          sourceSlug: sourceSlug,
        ),
      );
      messenger.showSnackBar(SnackBar(content: Text(l10n.cardUpdated)));
      return existing.id;
    }
  }

  final entry = ReceivedCard(
    id: const Uuid().v4(),
    card: card,
    receivedVia: via,
    receivedAt: now,
    updatedAt: now,
    sourceSlug: sourceSlug,
  );
  await repo.save(entry);
  messenger.showSnackBar(SnackBar(content: Text(l10n.cardReceived)));
  return entry.id;
}

/// Shows "Already in your Inbox: Update / Keep both / Cancel".
Future<DuplicateChoice?> _askAboutDuplicate(BuildContext context, String name) {
  final l10n = AppLocalizations.of(context);
  return showDialog<DuplicateChoice>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.duplicateTitle),
      content: Text(l10n.duplicateMessage(name)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, DuplicateChoice.keepBoth),
          child: Text(l10n.keepBoth),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, DuplicateChoice.update),
          child: Text(l10n.update),
        ),
      ],
    ),
  );
}
