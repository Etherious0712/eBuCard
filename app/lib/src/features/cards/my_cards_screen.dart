// Feature: My Cards. Lists the user's own cards; tap one to edit it, or
// "New card" to create one. The default card (shown first on the QR screen)
// is marked with a star. The list updates live from the database.

import 'package:ebucard_models/ebucard_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/card_image_service.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../sync/sync_refresh.dart';
import '../placeholder_body.dart';

/// Lists the user's own cards (a user may have several, e.g. Work/Personal).
class MyCardsScreen extends ConsumerWidget {
  /// Creates the screen.
  const MyCardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cards = ref.watch(ownCardsProvider);
    final defaultId = ref.watch(defaultCardProvider).value?.id;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navMyCards),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: l10n.account,
            onPressed: () => context.push('/account'),
          ),
        ],
      ),
      body: cards.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (cards) => cards.isEmpty
            ? PlaceholderBody(
                icon: Icons.badge_outlined,
                message: l10n.myCardsEmpty,
                comingSoon: false,
              )
            : SyncRefresh(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: cards.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _CardTile(
                    card: cards[i],
                    isDefault: cards[i].id == defaultId,
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/cards/new/edit'),
        icon: const Icon(Icons.add),
        label: Text(l10n.newCard),
      ),
    );
  }
}

/// One card in the list: photo (or initial), name, title · company, and the
/// card's own name on the right.
class _CardTile extends StatelessWidget {
  /// Shows [card].
  const _CardTile({required this.card, required this.isDefault});

  /// The card to show.
  final BusinessCard card;

  /// Whether this is the default card, marked with a star.
  final bool isDefault;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = [
      card.jobTitle,
      card.company,
    ].where((s) => s.isNotEmpty).join(' · ');
    final initials = card.fullName.trim().isEmpty
        ? '?'
        : card.fullName.trim().characters.first.toUpperCase();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          child: ClipOval(
            child: SizedBox.square(
              dimension: 48,
              child: CardImage(
                uri: card.photoUrl,
                fallback: Center(child: Text(initials)),
              ),
            ),
          ),
        ),
        title: Text(card.fullName),
        subtitle: subtitle.isEmpty ? null : Text(subtitle),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(card.cardName, style: theme.textTheme.labelMedium),
            if (isDefault)
              Icon(
                Icons.star,
                size: 18,
                color: theme.colorScheme.primary,
                semanticLabel: AppLocalizations.of(context).isDefaultCard,
              ),
          ],
        ),
        onTap: () => context.go('/cards/${card.id}/edit'),
      ),
    );
  }
}
