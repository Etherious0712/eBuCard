// Feature: show my QR code. Shares the card chosen in share_card.dart (the
// default card unless the user switched; the NFC screen shares the same
// one). Once the card has a link, the QR code holds the link (short, easy
// to scan, always the latest card); "Offline QR" switches to the full
// vCard without images, which works without internet (DESIGN.md §4.3).

import 'package:ebucard_models/ebucard_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../sync/card_links.dart';
import 'card_link_section.dart';
import 'share_card.dart';

/// Shows one of the user's cards as a QR code.
class ShowQrScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const ShowQrScreen({super.key});

  @override
  ConsumerState<ShowQrScreen> createState() => _ShowQrScreenState();
}

/// Holds the "Offline QR" choice for this visit.
class _ShowQrScreenState extends ConsumerState<ShowQrScreen> {
  bool _offline = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final payload = ref.watch(sharePayloadProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.showQrTitle)),
      body: ref
          .watch(shareCardProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('$error')),
            data: (card) {
              if (card == null) {
                return const NoCardsToShare(icon: Icons.qr_code_2);
              }
              final hasLink = payload.cardUrl(card) != null;
              final showsLink = hasLink && !_offline;
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  ShareCardDropdown(selected: card),
                  const SizedBox(height: 24),
                  _CardQr(
                    card: card,
                    text: payload.qrText(card, offline: _offline),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    card.fullName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    showsLink ? l10n.showQrLinkHint : l10n.showQrHint,
                    textAlign: TextAlign.center,
                  ),
                  if (hasLink)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.offlineQr),
                      subtitle: Text(l10n.offlineQrHint),
                      value: _offline,
                      onChanged: (value) => setState(() => _offline = value),
                    ),
                  CardLinkSection(card: card),
                ],
              );
            },
          ),
    );
  }
}

/// The QR code holding [text] for [card], or a message if it is too big.
class _CardQr extends StatelessWidget {
  const _CardQr({required this.card, required this.text});

  /// The card shown (for the screen-reader label).
  final BusinessCard card;

  /// What the code holds: the card link or the vCard.
  final String text;

  @override
  Widget build(BuildContext context) {
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
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
