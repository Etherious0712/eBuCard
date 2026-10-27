// What the NFC screens show when NFC can't be used: off (with a button to
// the settings) or not available, always offering the QR code instead.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/nfc_service.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';

/// Explains why NFC can't be used and offers the QR code instead.
class NfcUnavailable extends ConsumerWidget {
  /// Shows the message for [state]. [message] overrides the default text
  /// (e.g. "can't share" on a phone that can only read).
  const NfcUnavailable({
    super.key,
    required this.state,
    required this.qrRoute,
    this.message,
  });

  /// Why NFC can't be used.
  final NfcState state;

  /// The QR screen to offer instead (show or scan).
  final String qrRoute;

  /// Optional replacement for the default explanation.
  final String? message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isOff = state == NfcState.off;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.nfc, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            if (isOff) Text(l10n.nfcOff, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message ?? (isOff ? l10n.nfcOffMessage : l10n.nfcUnsupported),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Only Android can open the NFC settings page directly.
            if (isOff && defaultTargetPlatform == TargetPlatform.android)
              FilledButton.icon(
                onPressed: () => ref.read(nfcServiceProvider).openSettings(),
                icon: const Icon(Icons.settings),
                label: Text(l10n.openNfcSettings),
              ),
            TextButton.icon(
              onPressed: () => context.go(qrRoute),
              icon: const Icon(Icons.qr_code_2),
              label: Text(l10n.useQrInstead),
            ),
          ],
        ),
      ),
    );
  }
}
