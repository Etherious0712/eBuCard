// Feature: Inbox. Cards other people gave the user, newest first, with
// search. Tap a card to see it (received_card_screen.dart).

import 'package:ebucard_models/ebucard_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../placeholder_body.dart';

/// List of received cards with a search box.
class InboxScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

/// Holds the current search text.
class _InboxScreenState extends ConsumerState<InboxScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entries = ref.watch(receivedCardsProvider(_query));
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navInbox),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              onChanged: (q) => setState(() => _query = q),
              decoration: InputDecoration(
                hintText: l10n.searchInbox,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
        ),
      ),
      body: entries.when(
        // Keep showing the previous results while a new search runs.
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (entries) => entries.isEmpty
            ? PlaceholderBody(
                icon: Icons.inbox_outlined,
                message: _query.trim().isEmpty
                    ? l10n.inboxEmpty
                    : l10n.inboxNoMatches,
                comingSoon: false,
              )
            : ListView.builder(
                itemCount: entries.length,
                itemBuilder: (_, i) => _InboxTile(entry: entries[i]),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/exchange/scan'),
        icon: const Icon(Icons.qr_code_scanner),
        label: Text(l10n.scanQr),
      ),
    );
  }
}

/// One received card: initial, name, title · company, and when it arrived.
class _InboxTile extends StatelessWidget {
  const _InboxTile({required this.entry});

  /// The Inbox entry to show.
  final ReceivedCard entry;

  @override
  Widget build(BuildContext context) {
    final card = entry.card;
    final subtitle = [
      card.jobTitle,
      card.company,
    ].where((s) => s.isNotEmpty).join(' · ');
    final date = MaterialLocalizations.of(
      context,
    ).formatMediumDate(entry.receivedAt.toLocal());
    return ListTile(
      leading: CircleAvatar(
        child: Text(card.fullName.characters.first.toUpperCase()),
      ),
      title: Text(card.fullName),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      trailing: Text(date, style: Theme.of(context).textTheme.labelSmall),
      onTap: () => context.go('/inbox/${entry.id}'),
    );
  }
}
