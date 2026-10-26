// The bottom navigation bar (My Cards / Exchange / Inbox) wrapped around the
// three tab branches defined in app.dart.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'l10n/generated/app_localizations.dart';

/// Scaffold with the bottom navigation bar; the current tab is the body.
class HomeShell extends StatelessWidget {
  /// Wraps [shell], which go_router builds from the tab branches.
  const HomeShell({super.key, required this.shell});

  /// The tab branches and which one is active.
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
