// Shared empty-state body: a big icon and a message.

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// Body for empty lists and for screens that are not built yet.
class PlaceholderBody extends StatelessWidget {
  /// Shows [icon] and [message]; adds "Coming soon" when [comingSoon].
  const PlaceholderBody({
    super.key,
    required this.icon,
    required this.message,
    this.comingSoon = true,
  });

  /// Large icon above the message.
  final IconData icon;

  /// Main text, centred.
  final String message;

  /// Whether to add a "Coming soon" line for unbuilt features.
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (comingSoon) ...[
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).comingSoon,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
