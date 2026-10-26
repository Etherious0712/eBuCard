import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// Body used by screens that are scaffolded but not yet implemented.
class PlaceholderBody extends StatelessWidget {
  const PlaceholderBody({
    super.key,
    required this.icon,
    required this.message,
    this.comingSoon = true,
  });

  final IconData icon;
  final String message;
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
