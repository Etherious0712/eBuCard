import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';
import '../placeholder_body.dart';

/// Lists the user's own cards (a user may have several, e.g. Work/Personal).
class MyCardsScreen extends StatelessWidget {
  const MyCardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navMyCards),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: l10n.signIn,
            onPressed: () => context.push('/sign-in'),
          ),
        ],
      ),
      body: PlaceholderBody(
        icon: Icons.badge_outlined,
        message: l10n.myCardsEmpty,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/cards/new/edit'),
        icon: const Icon(Icons.add),
        label: Text(l10n.newCard),
      ),
    );
  }
}
