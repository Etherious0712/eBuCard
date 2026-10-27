// What happens after a QR code (or, later, an NFC tag) is read: decode it,
// ask about duplicates, and store it in the Inbox.

import 'package:ebucard_models/ebucard_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';

/// The user's answer when a scanned person is already in the Inbox.
enum DuplicateChoice {
  /// Replace the saved card's details; keep its note and received date.
  update,

  /// Add the scan as a separate Inbox entry.
  keepBoth,
}

/// Stores the contact in [text] in the Inbox and returns the entry's id.
///
/// Returns null, after telling the user why, if [text] isn't a contact. If
/// the same person is already in the Inbox (see `isSamePerson`), asks
/// whether to update that entry or keep both; returns null if the user
/// cancels.
Future<String?> receiveContactText(
  BuildContext context,
  WidgetRef ref,
  String text, {
  required ReceivedVia via,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final repo = ref.read(receivedCardRepositoryProvider);
  final now = DateTime.now().toUtc();

  final card = const ContactDecoder().decode(
    text,
    id: const Uuid().v4(),
    now: now,
  );
  if (card == null) {
    final message = via == ReceivedVia.nfc ? l10n.nfcNotACard : l10n.notACard;
    messenger.showSnackBar(SnackBar(content: Text(message)));
    return null;
  }

  final existing = await repo.findSamePerson(card);
  if (existing != null) {
    if (!context.mounted) return null;
    final choice = await _askAboutDuplicate(context, existing.card.fullName);
    if (choice == null) return null;
    if (choice == DuplicateChoice.update) {
      await repo.save(
        existing.copyWith(card: card, receivedVia: via, updatedAt: now),
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
