// Feature: show my QR code. Opens on the default card; the user can switch
// to another of their cards. The QR code holds the full vCard without
// images (DESIGN.md §4.3), so any phone camera can read it.

import 'package:ebucard_models/ebucard_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/config.dart';
import '../../data/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../placeholder_body.dart';

/// Shows one of the user's cards as a QR code.
class ShowQrScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const ShowQrScreen({super.key});

  @override
  ConsumerState<ShowQrScreen> createState() => _ShowQrScreenState();
}

/// Remembers which card is shown if the user switches away from the default.
class _ShowQrScreenState extends ConsumerState<ShowQrScreen> {
  /// Card picked in the switcher; null means "the default card".
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cards = ref.watch(ownCardsProvider).value ?? const [];
    final defaultCard = ref.watch(defaultCardProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.showQrTitle)),
      body: defaultCard.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (fallback) {
          if (fallback == null) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PlaceholderBody(
                  icon: Icons.qr_code_2,
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
          final card = cards.firstWhere(
            (c) => c.id == _selectedId,
            orElse: () => fallback,
          );
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (cards.length > 1)
                DropdownButtonFormField<String>(
                  initialValue: card.id,
                  decoration: InputDecoration(labelText: l10n.showingCard),
                  items: [
                    for (final c in cards)
                      DropdownMenuItem(
                        value: c.id,
                        child: Text('${c.cardName} · ${c.fullName}'),
                      ),
                  ],
                  onChanged: (id) => setState(() => _selectedId = id),
                ),
              const SizedBox(height: 24),
              _CardQr(card: card),
              const SizedBox(height: 16),
              Text(
                card.fullName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(l10n.showQrHint, textAlign: TextAlign.center),
            ],
          );
        },
      ),
    );
  }
}

/// The QR code for [card], or a message if the card is too big to fit.
class _CardQr extends StatelessWidget {
  const _CardQr({required this.card});

  /// The card to encode.
  final BusinessCard card;

  @override
  Widget build(BuildContext context) {
    final text = SharePayload(baseUrl: AppConfig.apiBaseUrl).qrText(card);
    // Low error correction leaves the most room for data; the code is shown
    // on a bright screen, not printed, so it rarely gets damaged.
    final validation = QrValidator.validate(
      data: text,
      errorCorrectionLevel: QrErrorCorrectLevel.L,
    );
    if (validation.status != QrValidationStatus.valid) {
      return Text(
        AppLocalizations.of(context).qrTooLarge,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
    }
    return Center(
      child: Container(
        // Always dark-on-white with a quiet zone, even in dark mode, so
        // every scanner can read it.
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: QrImageView.withQr(
          qr: validation.qrCode!,
          size: 280,
          semanticsLabel: card.fullName,
        ),
      ),
    );
  }
}
