// Which of the user's cards is being shared. The QR and NFC screens use the
// same choice, so switching cards on one also switches it on the other.

import 'package:ebucard_models/ebucard_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../placeholder_body.dart';

/// The card the user picked on a share screen this session; null means
/// "the default card". Not saved: the next app start begins at the default.
class ShareCardChoice extends Notifier<String?> {
  @override
  String? build() => null;

  /// Shares the card with [cardId] from now on.
  void select(String cardId) => state = cardId;
}

/// See [ShareCardChoice].
final shareCardChoiceProvider = NotifierProvider<ShareCardChoice, String?>(
  ShareCardChoice.new,
);

/// The card to share: the picked card if it still exists, otherwise the
/// default card; null when the user has no cards.
final shareCardProvider = Provider<AsyncValue<BusinessCard?>>((ref) {
  final cards = ref.watch(ownCardsProvider).value ?? const <BusinessCard>[];
  final chosenId = ref.watch(shareCardChoiceProvider);
  return ref.watch(defaultCardProvider).whenData((fallback) {
    if (fallback == null) return null;
    return cards.firstWhere((c) => c.id == chosenId, orElse: () => fallback);
  });
});

/// Dropdown for switching the shared card; shown only with two or more cards.
class ShareCardDropdown extends ConsumerWidget {
  /// Shows the dropdown with [selected] chosen.
  const ShareCardDropdown({super.key, required this.selected});

  /// The card currently shared.
  final BusinessCard selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(ownCardsProvider).value ?? const <BusinessCard>[];
    if (cards.length < 2) return const SizedBox.shrink();
    return DropdownButtonFormField<String>(
      initialValue: selected.id,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context).showingCard,
      ),
      items: [
        for (final c in cards)
          DropdownMenuItem(
            value: c.id,
            child: Text('${c.cardName} · ${c.fullName}'),
          ),
      ],
      onChanged: (id) {
        if (id != null) ref.read(shareCardChoiceProvider.notifier).select(id);
      },
    );
  }
}

/// Shown on a share screen when the user has no cards yet.
class NoCardsToShare extends StatelessWidget {
  /// Shows [icon] with a "create a card first" message and button.
  const NoCardsToShare({super.key, required this.icon});

  /// Icon for the kind of sharing (QR or NFC).
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PlaceholderBody(
          icon: icon,
          message: l10n.showQrNoCards,
          comingSoon: false,
        ),
        FilledButton(
          onPressed: () => context.go('/cards/new/edit'),
          child: Text(l10n.createCard),
        ),
      ],
    );
  }
}
