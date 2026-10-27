// The bottom navigation bar (My Cards / Exchange / Inbox) wrapped around the
// three tab branches defined in app.dart.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'account/account_providers.dart';
import 'l10n/generated/app_localizations.dart';
import 'sync/sync_controller.dart';

/// Scaffold with the bottom navigation bar; the current tab is the body.
/// It also keeps automatic sync running and tells the server which
/// language to write emails in.
class HomeShell extends ConsumerWidget {
  /// Wraps [shell], which go_router builds from the tab branches.
  const HomeShell({super.key, required this.shell});

  /// The tab branches and which one is active.
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    ref
      ..watch(syncControllerProvider)
      ..read(apiClientProvider).languageTag = Localizations.localeOf(
        context,
      ).toLanguageTag();
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        // Tapping the active tab again returns to that tab's first screen.
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.badge_outlined),
            label: l10n.navMyCards,
          ),
          NavigationDestination(
            icon: const Icon(Icons.nfc),
            label: l10n.navExchange,
          ),
          NavigationDestination(
            icon: const Icon(Icons.inbox_outlined),
            label: l10n.navInbox,
          ),
        ],
      ),
    );
  }
}
